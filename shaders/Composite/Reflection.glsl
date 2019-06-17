#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:02 */
#endif


void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy;
        const vec3 cps = texture(colortex0,fcoord.xy).xyz;
        mat2x3 colp = unpack3x2(cps);
        mat2x3 ltps = unpack3x2(texture(gbuffers1,fcoord.xy).xyz);

        const float filled = texture(colortex0,fcoord.xy).w;
        const vec2 shadowsize = textureSize(shadowcolor0,0);
        const vec2 buffersize = textureSize(colortex0,0);


        const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,1.f)),2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
        const vec4 cameraNormal = vec4(ltps[1].xyz*2.f-1.f,0.f);
        const vec4 cameraSPosition = ScreenSpaceToCameraSpace(screenSpaceCorrect);
        const vec4 cameraCenter = CameraCenterView;
        const vec4 cameraVector = vec4(normalize(cameraSPosition.xyz-cameraCenter.xyz),0.f);
        const vec3 reflVector = normalize(reflect(cameraVector.xyz,cameraNormal.xyz));
        const vec3 reflOrigin = cameraSPosition.xyz + reflVector.xyz;

        vec3 fcolor = colp[1], freflc = 0.f.xxx;
        if (fcoord.x < 0.5f && filled >= 0.1f) {
            // Screen Space Reflection Tracing...
            const vec4 ssrPos = EfficientSSR(cameraSPosition.xyz,normalize(reflect(cameraVector.xyz,cameraNormal.xyz)));
            
            const vec3 cps = texelFetch(colortex0,ivec2(((ssrPos.xy*0.5f+0.5f)*vec2(0.5f,1.f))*textureSize(colortex0,0)),0).xyz;
            mat2x3 colp = unpack3x2(cps);
            
            // Voxel Space Reflection Tracing, Sampling and Shading... 
            const vec4 modelNormal = cameraNormal*gbufferModelView;
            const vec4 modelPosition = CameraSpaceToModelSpace(cameraSPosition);
            const vec4 modelCenter = CameraSpaceToModelSpace(cameraCenter);
            const vec4 modelRefl = CameraSpaceToModelSpace(vec4(reflOrigin,1.f));
            const vec4 modelVector = vec4(normalize(modelPosition.xyz-modelCenter.xyz),0.f);

/*
            const vec3 reflV = normalize(modelRefl.xyz-modelPosition.xyz);
            Voxel voxelData = TraceVoxel(modelPosition.xyz,reflV);
            //const vec3 reflV = modelVector.xyz;
            //Voxel voxelData = TraceVoxel(modelCenter.xyz,reflV);
            if (fcoord.x < 0.5f && filled >= 0.1f && any(greaterThan(voxelData.color.xyz,0.f.xxx))) {
                vec3 modelPosition = modelPosition.xyz+fract(cameraPosition.xyz);
                const vec2 tbox = intersect(modelPosition, normalize(reflV), voxelData.position.xyz-0.5f, voxelData.position.xyz+0.5f);

                //if (tbox.y >= tbox.x && tbox.y >= 0.f) {
                    const vec3 isect = clamp((modelVector.xyz*max(tbox.x,0.f)+modelPosition.xyz)-(voxelData.position.xyz-0.5f),0.f.xxx,1.f.xxx);

                    // top and bottom texcoord 
                    vec2 lcoord = isect.xz;
                    
                    // face texcoord 
                    if (abs(isect.x) >= 0.9999f) lcoord = isect.yz;
                    if (abs(isect.z) >= 0.9999f) lcoord = isect.xy;

                    // TOOD: texcoord rotation 

                    // Get True Texcoord and Texture For Voxel 
                    const vec2 tsize = textureSize(colortex3,0);
                    const vec2 atlas = tsize/TEXTURE_SIZE, atlasInv = TEXTURE_SIZE/tsize;
                    const vec2 anch = voxelData.tbase.xy;
                    const vec2 texcoord = (lcoord+anch)*atlasInv;

                    // Get Voxel Texture 
                    //colp[1].xyz = texture(colortex3,texcoord).xyz;

                    colp[1].xyz = voxelData.color.xyz;
                //};
            };
*/
            

            // Finalize Result
            freflc = colp[1];
        }
        colp[1] = fcolor;
        gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fcolor)),texture(gbuffers1,fcoord.xy).w);
        gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),freflc)),1.f);
    #endif
}
