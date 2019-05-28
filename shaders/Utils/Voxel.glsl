
const vec3 tileSize = vec3(16.f,1.f,16.f);
const vec3 aeraSize = vec3(128.f,64.f,128.f);

// tilify voxels
vec3 VoxelToTileSpace(in vec3 voxelPosition){
    vec3 relativePosition = voxelPosition - cameraPosition; //fract(cameraPosition)
    vec3 currentVoxel = round(relativePosition);
    vec3 currentTile = floor(currentVoxel / tileSize);
    vec3 currentTileOffset = currentTile * tileSize;
    vec3 currentBlockInTile = mod(currentVoxel - currentTileOffset, tileSize);
    return currentTileOffset + currentBlockInTile;
}

// convert voxel into rendering space (fetching space)
vec2 VoxelToTextureSpace(in vec3 voxelPosition){
    const vec3 tileSpace = VoxelToTileSpace(voxelPosition);
    const vec2 flatSpace = vec2(tileSpace.x,tileSpace.y*aeraSize.z+tileSpace.z);
    return flatSpace; // TODO: re-correct into pixel space
}

// get correct surface... 
int FilterForVoxel(in vec3 normalOfBlock){
    return dot(normalOfBlock,vec3(0.f,1.f,0.f)) > 0.9999f;
}

// needs for make and add offset of voxel 
vec3 CenterOfTriangle(in mat3 vertices){
    return (vertices[0]+vertices[1]+vertices[2])*0.3333333f;
}

// calculate voxel offset by block triangle center 
vec3 CalcVoxelOfBlock(in vec3 centerOfBlockTriangle){
    centerOfBlockTriangle.y -= 0.0001f; // correctify
    return floor(centerOfBlockTriangle);
}

// calculate surface normal of blocks
vec3 NormalOfTriangle(in mat3 vertices){
    return normalize(cross(vertices[1]-vertices[0],vertices[2]-vertices[0]));
}
