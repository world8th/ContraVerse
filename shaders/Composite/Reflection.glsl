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

        const vec2 fcoord = texcoord.xy, hcoord = fcoord.xy+vec2(0.f,0.5f);

        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 ltps = unpack3x2(texture(gbuffers1,fcoord.xy).xyz);
        mat2x3 texp = unpack3x2(texture(gbuffers2,fcoord.xy).xyz);
        mat2x3 dexp = unpack3x2(texture(gbuffers3,fcoord.xy).xyz);
        vec3 fcolor = 1.f.xxx, fdiffc = 0.f.xxx;
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
        
        gl_FragData[0] = vec4(colp[1].xyz,1.f);
        //gl_FragData[0] = vec4(dexp[1].xyz,1.f);


    #endif
}
