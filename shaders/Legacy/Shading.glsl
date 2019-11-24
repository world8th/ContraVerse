#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:01 */
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
        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 ltps = unpack3x2(texture(gbuffers1,fcoord.xy).xyz);
        mat2x3 texp = unpack3x2(texture(gbuffers2,fcoord.xy).xyz);
        vec3 fcolor = /*colp[1]*/1.f.xxx, fdiffc = 0.f.xxx;
        const float filled = texture(gbuffers0,fcoord.xy).w;
        

        const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,2.f)),2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
        const vec4 cameraNormal = vec4(texp[1].xyz*2.f-1.f,0.f);
        const vec4 cameraSPosition = ScreenSpaceToCameraSpace(screenSpaceCorrect);
        const vec4 cameraCenter = CameraCenterView;
        const vec4 cameraVector = vec4(normalize(cameraSPosition.xyz-cameraCenter.xyz),0.f);
        const vec3 reflVector = normalize(reflect(cameraVector.xyz,cameraNormal.xyz));
        const vec3 reflOrigin = cameraSPosition.xyz + cameraCenter.xyz + reflVector.xyz;

        const vec4 modelNormal = cameraNormal*gbufferModelView;
        const vec4 modelSPosition = CameraSpaceToModelSpace(cameraSPosition);
        const vec4 modelCenter = CameraSpaceToModelSpace(cameraCenter);
        const vec4 modelRefl = CameraSpaceToModelSpace(vec4(reflOrigin,1.f));
        const vec4 modelVector = vec4(normalize(modelSPosition.xyz-modelCenter.xyz),0.f);
        const vec3 modelPosition = modelSPosition.xyz+modelCenter.xyz;
        
        const vec3 reflV = normalize(modelRefl.xyz-modelPosition.xyz+modelCenter.xyz);
        const vec4 subPos = CameraSpaceToModelSpace(vec4(shadowLightPosition.xyz,1.f));
        
        //(fcoord.x - contraSize.x) / SHADOW_SIZE.x;

        const vec4 shadowPosition = ModelSpaceToShadowSpace(vec4(modelPosition.xyz,1.f));
        const vec2 shadowTexcoord = (shadowPosition.xy*0.5f+0.5f)*vec2(SHADOW_SIZE_RATE.x,1.f)+vec2(SHADOW_SHIFT.x,0.f);
        const float shadowTex = linShadow(shadowTexcoord).x*2.f-1.f;
        const float vibrance = (shadowTex.x-shadowPosition.z)-0.00001f;

        const float minShading = ltps[0].x>=0.905f ? 16.f : 0.f; //ltps[0].x;
        const float normalShading = minShading+(dot(modelNormal.xyz,normalize(subPos.xyz-modelPosition.xyz))*0.5f+0.5f)*clamp(2.f-minShading,0.f,2.f);

        if (filled > 0.1f) {
            fcolor *= vibrance>=0.00001 ? normalShading : minShading;
            // Direct Light Phase...

            // Additional Shadings... (micro-shading)

        }
        
        gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fcolor)),texture(gbuffers1,fcoord.xy).w); // shading color 
        gl_FragData[1] = vec4(texture(gbuffers0,fcoord.xy)); // original color 
        //gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fdiffc)),1.f);
    #endif
}
