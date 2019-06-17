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
        const vec4 cameraPosition = ScreenSpaceToCameraSpace(screenSpaceCorrect);
        const vec4 cameraCenter = CameraCenterView;
        const vec4 cameraVector = vec4(normalize(cameraPosition.xyz-cameraCenter.xyz),0.f);



        vec3 fcolor = colp[1], freflc = 0.f.xxx;
        if (fcoord.x < 0.5f && filled >= 0.1f) {
            // Screen Space Reflection Tracing...
            const vec4 ssrPos = EfficientSSR(cameraPosition.xyz,normalize(reflect(cameraVector.xyz,cameraNormal.xyz)));
            
            const vec3 cps = texelFetch(colortex0,ivec2(((ssrPos.xy*0.5f+0.5f)*vec2(0.5f,1.f))*textureSize(colortex0,0)),0).xyz;
            mat2x3 colp = unpack3x2(cps);
            
            // Voxel Space Reflection Tracing, Sampling and Shading... 


            // Finalize Result
            freflc = colp[1];
        }
        colp[1] = fcolor;
        gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fcolor)),texture(gbuffers1,fcoord.xy).w);
        gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),freflc)),1.f);
    #endif
}
