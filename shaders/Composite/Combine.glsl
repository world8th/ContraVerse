#include "/Globals/Header.glsl"
#include "/Utils/Sky.glsl"


gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:01 */
#endif


const float nshift = 0.0001f;

#define ENABLE_REFLECTIONS

void main() {
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH

        const vec2 fcoord = texcoord.xy, hcoord = fcoord.xy+vec2(0.f,0.5f);
    
        //mat2x3 colp = unpack3x2(texture(colortex0,fcoord.xy).xyz);
        
        float alph = texture(gbuffers0,fcoord.xy+vec2(0.0f,0.f)).w;
        float alpt = texture(gbuffers0,fcoord.xy+vec2(0.5f,0.f)).w;

        float dp = texture(depthtex0,fcoord.xy).x, dh = texture(depthtex0,hcoord.xy).x;
        mat2x3 rtps = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 rtph = unpack3x2(texture(gbuffers0,hcoord.xy).xyz);
        mat2x3 sdps = unpack3x2(texture(colortex1,fcoord.xy).xyz);

        float tdp = texture(depthtex0,fcoord.xy+vec2(0.5f,0.f)).x, tdh = texture(depthtex0,hcoord.xy+vec2(0.5f,0.f)).x;
        float fcp = texture(gbuffers0,fcoord.xy+vec2(0.5f,0.f)).w, fch = texture(gbuffers0,hcoord.xy+vec2(0.5f,0.f)).w;
        mat2x3 trps = unpack3x2(texture(gbuffers0,fcoord.xy+vec2(0.5f,0.f)).xyz);
        mat2x3 trph = unpack3x2(texture(gbuffers0,hcoord.xy+vec2(0.5f,0.f)).xyz);
        mat2x3 texp = unpack3x2(texture(gbuffers2,fcoord.xy).xyz);
        //mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        //mat2x3 colh = unpack3x2(texture(gbuffers0,hcoord.xy).xyz);


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
        

        // combine transparents with physical 
        if (fcoord.x < 0.5f && fcoord.y < 0.5f && tdp <= dp && fcp > 0.1f && (alph > 0.1f || alpt > 0.1f)) { rtps[1] = mix(rtps[1],trps[1],1.f); } 
        if (fcoord.x < 0.5f && fcoord.y < 0.5f && tdh <= dh && fch > 0.1f) { rtph[1] = mix(rtph[1],trph[1],1.f); } 

        // add planar reflections 
        if (dp <= dh && dot(modelNormal.xyz,vec3(0.f,1.f,0.f)) > 0.99f && fcoord.x < 0.5f && fcoord.y < 0.5f) { rtps[1].xyz = mix( rtps[1].xyz,rtph[1].xyz,0.25f); };

        // final color 
        gl_FragData[0] = vec4(rtps[1].xyz,1.f);

        //const vec2 fcoord = texcoord.xy; //* vec2(0.5f,0.5f);
        //const vec3 cps = texture(colortex0,fcoord.xy).xyz;
        //gl_FragColor = vec4(to_sRGB(cps),1.f);

        //const vec3 hemisphere = randomHemisphereCosine(vec3(fcoord.xy*vec2(viewWidth,viewHeight),frameTimeCounter));
        //gl_FragColor = vec4(hemisphere*0.5f+0.5f,1.f);
    #endif
}
