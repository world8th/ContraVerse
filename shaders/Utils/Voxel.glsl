
const vec3 tileSize = vec3(16.f,1.f,16.f), aeraSize = vec3(64.f,64.f,64.f);
#define SHADOW_SIZE (float(shadowMapResolution)-aeraSize.x) // TODO: better shadow map correction
#define SHADOW_SHIFT (aeraSize.x/float(shadowMapResolution))
#define SHADOW_SIZE_RATE (SHADOW_SIZE/float(shadowMapResolution))

vec3 TileOfVoxel(in vec3 currentVoxel){
    return floor(floor(currentVoxel + 0.0001f) / tileSize) * tileSize;
}

// convert voxel into rendering space (fetching space)
vec3 VoxelToTextureSpace(in vec3 tileSpace){
#ifdef COMPOSITE
    //tileSpace += fract(cameraPosition.xyz); // gather in correct tile
#endif

    // shift into unsigned space 
    tileSpace += aeraSize*0.5f;

    // flatify voxel coordinates
    vec2 flatSpace = vec2(floor(tileSpace.x + 0.0001f),floor(tileSpace.y + 0.0001f)*aeraSize.z+floor(tileSpace.z + 0.0001f));
    vec2 textSpaceSize = vec2(aeraSize.x,aeraSize.y*aeraSize.z);

    // shift into unsigned space 
    //flatSpace += textSpaceSize*0.5f;

    // convert into unit coordinate system
    //flatSpace /= textSpaceSize;

    // TODO: better shadow resolution division 
#ifndef COMPOSITE
    flatSpace /= float(shadowMapResolution);
#else
    flatSpace += 0.5f;
#endif

    // return pixel corrected
    return vec3(flatSpace,(floor(tileSpace.y + 0.0001f)+aeraSize.y*0.5f)/aeraSize.y);
}

// get valid surface... 
bool FilterForVoxel(in vec3 voxelPosition, in vec3 normalOfBlock){
    return abs(dot(normalOfBlock,vec3(0.f,1.f,0.f))) > 0.9999f && all(greaterThanEqual(voxelPosition,-aeraSize*0.5f)) && all(lessThan(voxelPosition,aeraSize*0.5f));
}

// needs for make and add offset of voxel 
vec3 CenterOfTriangle(in mat3 vertices){
    //return (vertices[0]+vertices[1]+vertices[2])*0.3333333f;
    return floor(min(vertices[0],min(vertices[1],vertices[2])) + 0.0001f);
}

// calculate voxel offset by block triangle center 
vec3 CalcVoxelOfBlock(in vec3 centerOfBlockTriangle, in vec3 surfaceNormal){
    return floor(centerOfBlockTriangle-surfaceNormal*0.0001f); // correctify
}

// calculate surface normal of blocks
vec3 NormalOfTriangle(in mat3 vertices){
    return normalize(cross(vertices[1]-vertices[0],vertices[2]-vertices[0]));
}


struct Voxel {
    vec4 position;
    vec4 color;
    vec2 tbase;
    vec2 param;
};

#ifndef TEXTURE_SIZE
#define TEXTURE_SIZE 16
#endif

#ifdef COMPOSITE
#ifdef FSH
Voxel VoxelContents(in vec3 tileSpace){
    Voxel voxelData;
    voxelData.color = 0.f.xxxx;
    voxelData.tbase = 0.f.xx;
    voxelData.param = 0.f.xx;

    if (all(greaterThanEqual(tileSpace,-aeraSize*0.5f)) && all(lessThan(tileSpace,aeraSize*0.5f))) {
        //const vec2 atlas = vec2(atlasSize)/TEXTURE_SIZE, torig = floor(adjtx.xy*atlas), tcord = fract(adjtx.xy*atlas);
        const vec2 vect = VoxelToTextureSpace(tileSpace).xy;

        const vec4 vcol = texelFetch(shadowcolor0, ivec2(vect), 0);
        const float vxcolr = vcol.x;//uintBitsToFloat(packUnorm4x8(vec4(fcolor.xyz*texture(lightmap,flmcoord.st).xyz,0.f))); // TODO: better pre-baked emission support
        const float vxmisc = vcol.y;//uintBitsToFloat(packUnorm4x8(vec4(0.f.xx,torig/atlas))); // first 16-bit uint's BROKEN
        const float vxdata = vcol.z;//uintBitsToFloat(packUnorm2x16(fparametric.xy/65535.f)); // cheaper packing (for code)

        if (!all(equal(vcol.xyz,1.f.xxx))) {
            voxelData.position = vec4(tileSpace,1.f);
            voxelData.color = vcol;//unpackUnorm4x8(floatBitsToUint(vxcolr));
            voxelData.tbase = unpackUnorm4x8(floatBitsToUint(vxmisc)).zw;
            voxelData.param = unpackUnorm2x16(floatBitsToUint(vxdata))*65535.f;
        };
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
    finalVoxel.color = 0.f.xxxx;
    finalVoxel.tbase = 0.f.xx;
    finalVoxel.param = 0.f.xx;

    exactStartPos += aeraSize.xxx*0.5f;
    const vec2 tbox = intersect(exactStartPos, rayDir);

    if (tbox.y >= tbox.x && tbox.y >= 0.f) {
        const ivec3 bndr = ivec3(aeraSize.x);
        const vec3 fbndr = 1.f.xxx;//aeraSize*0.5f;

        const vec3 rayStrt = (exactStartPos + rayDir*max(tbox.x+0.0001f,0.f))/vec3(bndr), rayEnd = (exactStartPos + rayDir*max(tbox.y-0.0001f,0.f))/vec3(bndr), rayDir = rayEnd-rayStrt;
        ivec3 current = ivec3(floor(rayStrt*vec3(bndr))), last = ivec3(floor(rayEnd*vec3(bndr)));
        const ivec3 stepd = mix(ivec3(-1),ivec3(1),greaterThanEqual(rayDir,0.f.xxx));

        vec3 tmax = mix(10e5f.xxx,(rayStrt-vec3(current+stepd)/vec3(bndr))/rayDir,notEqual(rayDir,0.f.xxx));
        vec3 tdelta = mix(10e5f.xxx,fbndr*vec3(stepd)/rayDir,notEqual(rayDir,0.f.xxx));
        //current += mix(ivec3(0),ivec3(1),and(notEqual(current,last),lessThan(rayDir,0.f.xxx)));
        current += mix(ivec3(0),ivec3(1),lessThan(rayDir,0.f.xxx));

        bool keepTraversing = true;
        while (keepTraversing) {
            const float minp = min(tmax.x, min(tmax.y, tmax.z));
            const int axis = minp == tmax.y ? 1 : (minp == tmax.z ? 2 : 0);
            current[axis] += stepd[axis], tmax[axis] += tdelta[axis];
            
            if (any(lessThan(current,vec3(0))) || any(greaterThanEqual(current,bndr))) {
                keepTraversing = false;
            } else {
                Voxel voxelData = VoxelContents(vec3(current)-aeraSize*0.5f);
                if (voxelData.color.w > 0.0f) { finalVoxel = voxelData, keepTraversing = false; }
            }
        }
    }

    return finalVoxel;
}
#endif
#endif
