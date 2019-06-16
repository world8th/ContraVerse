
const vec3 tileSize = vec3(16.f,1.f,16.f), aeraSize = vec3(64.f,64.f,64.f), contraSize = vec3(128.f,64.f,128.f);

#define SHADOW_SIZE (float(shadowMapResolution)-contraSize.x) // TODO: better shadow map correction
#define SHADOW_SHIFT (contraSize.x/float(shadowMapResolution))
#define SHADOW_SIZE_RATE (SHADOW_SIZE/float(shadowMapResolution))

// 
vec3 TileOfVoxel(in vec3 currentVoxel){
    return floor(floor(currentVoxel + 0.0001f) / tileSize) * tileSize;
}

// convert voxel into rendering space (fetching space)
vec3 VoxelToTextureSpace(in vec3 tileSpace){

    // shift into unsigned space 
#ifndef COMPOSITE
    tileSpace += contraSize*0.5f;
#else
    tileSpace *= vec3(2.f,1.f,2.f);
#endif

    // flatify voxel coordinates
    vec2 flatSpace = vec2(round(tileSpace.x),round(tileSpace.y)*contraSize.z+round(tileSpace.z));
    //vec2 textSpaceSize = vec2(aeraSize.x,aeraSize.y*aeraSize.z);

    // shift into unsigned space 
    //flatSpace += textSpaceSize*0.5f;

    // convert into unit coordinate system
    //flatSpace /= textSpaceSize;

    // TODO: better shadow resolution division 
#ifndef COMPOSITE
    flatSpace /= float(shadowMapResolution);
#endif

    // return pixel corrected
    return vec3(flatSpace,0.f);
}

// get valid surface... 
bool FilterForVoxel(in vec3 voxelPosition, in vec3 normalOfBlock){
    //return abs(dot(normalOfBlock,vec3(0.f,1.f,0.f))) > 0.9999f && all(greaterThanEqual(voxelPosition,-aeraSize*0.5f)) && all(lessThan(voxelPosition,aeraSize*0.5f));
    return 
        (abs(dot(normalOfBlock,vec3(0.f,1.f,0.f))) > 0.9999f || 
         abs(dot(normalOfBlock,vec3(1.f,0.f,0.f))) > 0.9999f || 
         abs(dot(normalOfBlock,vec3(0.f,0.f,1.f))) > 0.9999f) && 
        all(greaterThanEqual(voxelPosition,-aeraSize*0.5f)) && all(lessThan(voxelPosition,aeraSize*0.5f));
}

// needs for make and add offset of voxel 
vec3 CenterOfTriangle(in mat3 vertices){
    return (vertices[0]+vertices[1]+vertices[2])*0.3333333f;
    //return floor(min(vertices[0],min(vertices[1],vertices[2])) + 0.001f);
    //return min(vertices[0],min(vertices[1],vertices[2]));
}

// calculate voxel offset by block triangle center 
vec3 CalcVoxelOfBlock(in vec3 centerOfBlockTriangle, in vec3 surfaceNormal){
    return floor(centerOfBlockTriangle-surfaceNormal*0.5f); // correctify
}

// calculate surface normal of blocks
vec3 NormalOfTriangle(in mat3 vertices){
    return normalize(cross(vertices[1]-vertices[0],vertices[2]-vertices[0]));
}


struct Voxel {
    vec3 position; uint param;
    vec3 color;
    vec2 tbase;
};

#ifndef TEXTURE_SIZE
#define TEXTURE_SIZE 16
#endif

#ifdef COMPOSITE
#ifdef FSH
Voxel VoxelContents(in vec3 tileSpace){
    Voxel voxelData;
    voxelData.color = 0.f.xxx;
    voxelData.tbase = 0.f.xx;
    voxelData.param = 0u;

    if (all(greaterThanEqual(tileSpace,0.f.xxx)) && all(lessThan(tileSpace,aeraSize))) {
        const vec4 voxy = texelFetch(shadowcolor0, ivec2(VoxelToTextureSpace(tileSpace-vec3(1,1,1)).xy), 0);
        //const mat2x3 colp = unpack3x2(voxy.xyz);

        voxelData.position = tileSpace;
        voxelData.color = 1.f-voxy.xyz;//1.f-colp[1].xyz;
        voxelData.tbase = 0.f.xx;//colp[0].xy;
        voxelData.param = 0u;//floatBitsToUint(voxy.w);
        if (voxy.w < 1.f) voxelData.color = 0.f.xxx;
        
        //if (all(lessThanEqual(voxelData.color,0.f.xxx))) {
        //    voxelData.color = 0.f.xxx;
        //};
    };

    return voxelData;
}
#endif
#endif

#ifdef COMPOSITE
#ifdef FSH

vec2 intersect(in vec3 ro, in vec3 dir) {
    const vec3 pmin = 0.f.xxx, pmax = aeraSize.xxx, ird = 1.f/dir;//-aeraSize.xxx*0.5f, pmax = aeraSize.xxx*0.5f, ird = 1.f/dir;
	const vec3 tmin = (pmin - ro) * ird; // [-inf, inf]
	const vec3 tmax = (pmax - ro) * ird; // [-inf, inf]
	const vec3 bmin = min(tmin, tmax), bmax = max(tmin, tmax);
    
	return vec2(max(bmin.x, max(bmin.y, bmin.z)), min(bmax.x, min(bmax.y, bmax.z)));
}


bvec3 and(in bvec3 a, in bvec3 b){
    return bvec3(a.x&&b.x,a.y&&b.y,a.z&&b.z);
}


Voxel TraceVoxel(in vec3 exactStartPos, in vec3 rayDir){
    Voxel finalVoxel;
    finalVoxel.color = 0.f.xxx;
    finalVoxel.tbase = 0.f.xx;
    finalVoxel.param = 0u;

    exactStartPos += aeraSize.xxx*0.5f + fract(cameraPosition);
    const vec2 tbox = intersect(exactStartPos, rayDir);

    if (tbox.y >= tbox.x && tbox.y >= 0.f) {
        const vec3 fbndr = 1.f.xxx;//aeraSize*0.5f;

        const vec3 rayStrt = (exactStartPos + rayDir*max(tbox.x,0.f))/aeraSize.x, rayEnd = (exactStartPos + rayDir*max(tbox.y,0.f))/aeraSize.x, rayDir = rayEnd-rayStrt;
        ivec3 current = ivec3(floor(exactStartPos)), last = ivec3(floor(rayEnd*aeraSize.x));
        const ivec3 stepd = mix(ivec3(-1),ivec3(1),greaterThanEqual(rayDir,0.f.xxx));

        vec3 tmax = mix(10e5f.xxx,(current-exactStartPos)/rayDir,greaterThanEqual(abs(rayDir),1e-5f.xxx));
        vec3 tdelta = mix(10e5f.xxx,          vec3(stepd)/rayDir,greaterThanEqual(abs(rayDir),1e-5f.xxx));
        //current += mix(ivec3(0),ivec3(1),and(notEqual(current,last),lessThan(rayDir,0.f.xxx)));
        current += mix(ivec3(0),ivec3(1),lessThan(rayDir,0.f.xxx));

        bool keepTraversing = true;
        while (keepTraversing) {
            const float minp = min(tmax.x, min(tmax.y, tmax.z));
            const int axis = minp == tmax.y ? 1 : (minp == tmax.z ? 2 : 0);
            current[axis] += stepd[axis], tmax[axis] += tdelta[axis];
            
            if (any(lessThanEqual(current,ivec3(0))) || any(greaterThanEqual(current,ivec3(aeraSize.x)))) {
                keepTraversing = false;
            } else {
                Voxel voxelData = VoxelContents(vec3(current));
                if (any(greaterThan(voxelData.color.xyz,0.f.xxx))) { finalVoxel = voxelData, keepTraversing = false; }
            }
        }
    }

    return finalVoxel;
}
#endif
#endif
