#include "/Globals/Header.glsl"

gin vec4 texcoord;

void main() {
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy * vec2(0.5f,1.f);
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

        const vec4 modelNormal = cameraNormal*gbufferModelView;
        const vec4 modelPosition = CameraSpaceToModelSpace(cameraSPosition);
        const vec4 modelCenter = CameraSpaceToModelSpace(cameraCenter);
        const vec4 modelRefl = CameraSpaceToModelSpace(vec4(reflOrigin,1.f));
        const vec4 modelVector = vec4(normalize(modelPosition.xyz-modelCenter.xyz),0.f);
        const vec3 reflV = normalize(modelRefl.xyz-modelPosition.xyz);
        const vec4 subPos = CameraSpaceToModelSpace(vec4(sunPosition.xyz,1.f));

        const vec4 shadowPosition = ModelSpaceToShadowSpace(vec4((modelPosition.xyz+modelCenter.xyz)*0.5f,1.f));
        const vec2 shadowTexcoord = (shadowPosition.xy*0.5f+0.5f)*vec2(SHADOW_SIZE_RATE.x,1.f)+vec2(SHADOW_SHIFT.x,0.f);
        const float shadowTex = texture(shadowtex0, shadowTexcoord).x*2.f-1.f;
        const float vibrance = (shadowTex.x-shadowPosition.z);

        gl_FragColor = vec4(to_sRGB(clamp(colp[1].xyz,0.f.xxx,1.f.xxx)),1.f);
        
    #endif
}
