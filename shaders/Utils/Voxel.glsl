
const vec3 tileSize = vec3(16.f,1.f,16.f), aeraSize = vec3(128.f,64.f,128.f);
#define SHADOW_SIZE (float(shadowMapResolution)-aeraSize.x) // TODO: better shadow map correction
#define SHADOW_SHIFT (aeraSize.x/float(shadowMapResolution))
#define SHADOW_SIZE_RATE (SHADOW_SIZE/float(shadowMapResolution))

vec3 TileOfVoxel(in vec3 currentVoxel){
    return floor(floor(currentVoxel + 0.0001f) / tileSize) * tileSize;
}

// convert voxel into rendering space (fetching space)
vec3 VoxelToTextureSpace(in vec3 tileSpace){
#ifdef COMPOSITE
    //tileSpace -= TileOfVoxel(cameraPosition); // gather in correct tile
#endif

    // shift into unsigned space 
    tileSpace += aeraSize*0.5f;

    // flatify voxel coordinates
    vec2 flatSpace = vec2(floor(tileSpace.x + 0.0001f),floor(tileSpace.y)*aeraSize.z+floor(tileSpace.z + 0.0001f));
    vec2 textSpaceSize = vec2(aeraSize.x,aeraSize.y*aeraSize.z);

    // shift into unsigned space 
    //flatSpace += textSpaceSize*0.5f;

    // convert into unit coordinate system
    //flatSpace /= textSpaceSize;

    // TODO: better shadow resolution division 
#ifndef COMPOSITE
    flatSpace /= float(shadowMapResolution);
#endif

    // return pixel corrected
    return vec3(flatSpace,(floor(tileSpace.y)+aeraSize.y*0.5f)/aeraSize.y);
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
        tileSpace.y -= 1.0f;
        const vec2 vect = VoxelToTextureSpace(floor(tileSpace+0.0001f)).xy;

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
    const vec3 pmin = -aeraSize*0.5f, pmax = aeraSize*0.5f, ird = 1.f/dir;
	const vec3 tmin = (pmin - ro) * ird; // [-inf, inf]
	const vec3 tmax = (pmax - ro) * ird; // [-inf, inf]
	const vec3 bmin = min(tmin, tmax), bmax = max(tmin, tmax);
    
	return vec2(min(bmax.x, min(bmax.y, bmax.z)), max(bmin.x, max(bmin.y, bmin.z)));
}

Voxel TraceVoxel(in vec3 exactStartPos, in vec3 rayDir){
    

    Voxel finalVoxel;
    finalVoxel.color = 0.f.xxxx;
    finalVoxel.tbase = 0.f.xx;
    finalVoxel.param = 0.f.xx;

    const vec2 tbox = intersect(exactStartPos, rayDir);
    //if (tbox.y >= tbox.x) {
        const ivec3 bndr = ivec3(128,64,128)/2;
        //exactStartPos += aeraSize*0.5f;

        const vec3 cellMin = exactStartPos + rayDir*max(tbox.x-0.0001f,0.f), cellMax = exactStartPos + rayDir*max(tbox.y+0.0001f,1.f), rayInvDir = 1.f/rayDir;
        //const vec3 cellMin = -aeraSize*0.5f, cellMax = aeraSize*0.5f, rayInvDir = 1.f/rayDir;

        //exactStartPos -= TileOfVoxel(cameraPosition); // re-align world space position 
        vec3 tmaxNeg = (cellMin - exactStartPos) * rayInvDir;
        vec3 tmaxPos = (cellMax - exactStartPos) * rayInvDir;

        vec3 tmax;
        tmax.x = (rayDir.x < 0.0) ? tmaxNeg.x : tmaxPos.x;
        tmax.y = (rayDir.y < 0.0) ? tmaxNeg.y : tmaxPos.y;
        tmax.z = (rayDir.z < 0.0) ? tmaxNeg.z : tmaxPos.z;
        
        ivec3 stepDir;
        stepDir.x = rayDir.x < 0.0f ? -1 : 1;
        stepDir.y = rayDir.y < 0.0f ? -1 : 1;
        stepDir.z = rayDir.z < 0.0f ? -1 : 1;
        vec3 tDelta = abs(rayInvDir);
        
        ivec3 voxelPos = ivec3(cellMin);
        bool keepTraversing = true;
        while (keepTraversing) {
            
            if (tmax.x < tmax.y || tmax.z < tmax.y) {
                if (tmax.x < tmax.z) {
                    voxelPos.x += stepDir.x;
                    tmax.x += tDelta.x;
                } else {
                    voxelPos.z += stepDir.z;
                    tmax.z += tDelta.z;
                }
            } else {
                voxelPos.y += stepDir.y;
                tmax.y += tDelta.y;
            }
            
            
            if (any(lessThanEqual(voxelPos,-bndr)) || any(greaterThanEqual(voxelPos,bndr))) {
                keepTraversing = false;
            } else {
                Voxel voxelData = VoxelContents(voxelPos);
                if (voxelData.color.w > 0.0f) { finalVoxel = voxelData, keepTraversing = false; }
            }
        }
    //}

    return finalVoxel;
}
#endif
#endif
