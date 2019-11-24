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
#ifdef COMPOSITE
    tileSpace *= vec3(2.f,1.f,2.f);
#endif

    // flatify voxel coordinates
    vec2 flatSpace = vec2(round(tileSpace.x),round(tileSpace.y)*contraSize.z+round(tileSpace.z));

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
    vec2 tbase; vec2 lmcoord;
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
        const vec4 voxy = texelFetch(shadowcolor0, ivec2(VoxelToTextureSpace(tileSpace).xy)+ivec2(0,0), 0);
        const vec4 txpl = texelFetch(shadowcolor0, ivec2(VoxelToTextureSpace(tileSpace).xy)+ivec2(1,0), 0);
        const vec4 lxpl = texelFetch(shadowcolor0, ivec2(VoxelToTextureSpace(tileSpace).xy)+ivec2(0,1), 0);
        //const mat2x3 colp = unpack3x2(voxy.xyz);

        voxelData.position = tileSpace-aeraSize.xxx*0.5f;//*0.5f;
        voxelData.color = 1.f-voxy.xyz;//1.f-colp[1].xyz;
        voxelData.tbase = txpl.xy;//colp[0].xy;
        voxelData.param = 0u;//floatBitsToUint(voxy.w);
        voxelData.lmcoord = lxpl.xy;
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

vec2 intersect(in vec3 ro, in vec3 dir, in vec3 pmin, in vec3 pmax) {
    const vec3 ird = 1.f/dir;//-aeraSize.xxx*0.5f, pmax = aeraSize.xxx*0.5f, ird = 1.f/dir;
	const vec3 tmin = (pmin - ro) * ird; // [-inf, inf]
	const vec3 tmax = (pmax - ro) * ird; // [-inf, inf]
	const vec3 bmin = min(tmin, tmax), bmax = max(tmin, tmax);
	return vec2(max(bmin.x, max(bmin.y, bmin.z)), min(bmax.x, min(bmax.y, bmax.z))*1.00001f);
}


bvec3 and(in bvec3 a, in bvec3 b){
    return bvec3(a.x&&b.x,a.y&&b.y,a.z&&b.z);
}


Voxel TraceVoxel(in vec3 p0, in vec3 d){
    Voxel finalVoxel;
    finalVoxel.color = 0.f.xxx;
    finalVoxel.tbase = 0.f.xx;
    finalVoxel.param = 0u;

    //const vec3 op = p0;
    p0 += aeraSize*0.5f;// + fract(cameraPosition);

    const vec2 tbox = intersect(p0, d, 0.f.xxx-0.0001f, aeraSize+0.0001f);
    if (tbox.y >= tbox.x && tbox.y >= 0.f) { p0 += d*max(tbox.x,0.f);
        const ivec3 stepd = mix(ivec3(-1),ivec3( 1),greaterThanEqual(d,0.f.xxx));
        const ivec3 shift = mix(ivec3( 0),ivec3( 1),greaterThan(d,0.f.xxx));
        const vec3 startp = (p0 + tbox.x*d), endp = (p0 + tbox.y*d), dir = endp - startp, p0 = p0+max(tbox.x,0.f)*d;
        const vec3 start = floor(startp/aeraSize), end = floor(endp/aeraSize);

        ivec3 current = ivec3(floor(p0));
        vec3 next = vec3(current)+vec3(shift);
        vec3 tmax = mix(10e5f.xxx, (next-p0)/(dir),greaterThanEqual(abs(dir),1e-5f.xxx));
        vec3 tdelta = mix(10e5f.xxx, (stepd)/(dir),greaterThanEqual(abs(dir),1e-5f.xxx));

        bool keepTraversing = true; //current += 1-shift;
        while (keepTraversing) {
            if (any(lessThanEqual(current,-ivec3(0))) || any(greaterThanEqual(current,ivec3(aeraSize)))) {
                keepTraversing = false;
            } else {
                Voxel voxelData = VoxelContents(vec3(current));
                if (any(greaterThan(voxelData.color.xyz,0.f.xxx))) { finalVoxel = voxelData, keepTraversing = false; }
            }

            const float minp = min(tmax.x, min(tmax.y, tmax.z));
            const int axis = minp == tmax.y ? 1 : (minp == tmax.z ? 2 : 0);
            current[axis] += stepd[axis], tmax[axis] += tdelta[axis];
        }
        
    }

    return finalVoxel;

}
#endif
#endif