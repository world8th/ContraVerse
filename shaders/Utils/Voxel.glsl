
const vec3 tileSize = vec3(16.f,1.f,16.f), aeraSize = vec3(128.f,64.f,128.f);
#define SHADOW_SIZE (float(shadowMapResolution)-aeraSize.x) // TODO: better shadow map correction
#define SHADOW_SHIFT (aeraSize.x/float(shadowMapResolution))
#define SHADOW_SIZE_RATE (SHADOW_SIZE/float(shadowMapResolution))

vec3 TileOfVoxel(in vec3 currentVoxel){
    return floor(round(currentVoxel) / tileSize) * tileSize;
}

// convert voxel into rendering space (fetching space)
vec3 VoxelToTextureSpace(in vec3 tileSpace){
#ifdef COMPOSITE
    tileSpace -= TileOfVoxel(cameraPosition); // gather in correct tile
#endif

    // shift into unsigned space 
    tileSpace += aeraSize*0.5f;

    // flatify voxel coordinates
    vec2 flatSpace = vec2(tileSpace.x,tileSpace.y*aeraSize.z+tileSpace.z);
    vec2 textSpaceSize = vec2(aeraSize.x,aeraSize.y*aeraSize.z);

    // shift into unsigned space 
    //flatSpace += textSpaceSize*0.5f;

    // convert into unit coordinate system
    //flatSpace /= textSpaceSize;

    // TODO: better shadow resolution division 
    flatSpace /= float(shadowMapResolution);

    // return pixel corrected
    return vec3(flatSpace,(tileSpace.y+aeraSize.y*0.5f)/aeraSize.y);
}

// get valid surface... 
bool FilterForVoxel(in vec3 voxelPosition, in vec3 normalOfBlock){
    return abs(dot(normalOfBlock,vec3(0.f,1.f,0.f))) > 0.9999f && all(greaterThanEqual(voxelPosition,-aeraSize*0.5f)) && all(lessThan(voxelPosition,aeraSize*0.5f));
}

// needs for make and add offset of voxel 
vec3 CenterOfTriangle(in mat3 vertices){
    //return (vertices[0]+vertices[1]+vertices[2])*0.3333333f;
    return min(vertices[0],min(vertices[1],vertices[2]));
}

// calculate voxel offset by block triangle center 
vec3 CalcVoxelOfBlock(in vec3 centerOfBlockTriangle, in vec3 surfaceNormal){
    return round(centerOfBlockTriangle-surfaceNormal*0.0001f); // correctify
}

// calculate surface normal of blocks
vec3 NormalOfTriangle(in mat3 vertices){
    return normalize(cross(vertices[1]-vertices[0],vertices[2]-vertices[0]));
}
