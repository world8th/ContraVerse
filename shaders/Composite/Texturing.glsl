#include "/Globals/Header.glsl"
#include "/Utils/Sky.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:46 */
#endif

const int PRETEXTURED = 0, COORDINATED = 1;

// TODO: add to definition settings officially 
#ifndef TEXTURE_SIZE
#define TEXTURE_SIZE 16
#endif

void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 

    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy;// * vec2(0.5f,1.f);
        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 ltps = unpack3x2(texture(gbuffers1,fcoord.xy).xyz);
        mat2x3 texp = unpack3x2(texture(gbuffers2,fcoord.xy).xyz);
        //mat2x3 tang = unpack3x2(texture(gbuffers3,fcoord.xy).xyz);
        const int mode = !all(equal(colp[0].xy,0.f.xx)) ? COORDINATED : PRETEXTURED;

        // special edition
        if (mode == COORDINATED) {
            const vec2 tsize = textureSize(colortex3,0);
            const vec2 atlas = tsize/TEXTURE_SIZE, atlasInv = TEXTURE_SIZE/tsize;
            const vec2 anch = floor(colp[0].xy), texcoord = fma(clamp(colp[0].xy-anch,0.f.xx,1.f.xx)+anch,atlasInv,round(texp[0].xy*atlas)*atlasInv);

            //texcoord *= TEXTURE_SIZE;
            //vec2 textile = floor(texcoord);
            //vec2 texofft = fract(texcoord);

            // TODO: Parallax Occlusion Mapping in deferred phase... 
            mat3 tbn = mat3(normalize(texp[1].xyz*2.f-1.f),normalize(cross(ltps[1].xyz*2.f-1.f,texp[1].xyz*2.f-1.f)),normalize(ltps[1].xyz*2.f-1.f));
	        vec3 tbnorm = normalize(tbn*(texture(colortex1, texcoord).xyz*2.f-1.f));

            // hemisphere 
            const vec3 hemisphere = randomHemisphereCosine(vec3(fcoord.xy*vec2(viewWidth,viewHeight),frameTimeCounter));
            tbn[2] = tbnorm, tbn[1] = normalize(cross(tbn[2],tbn[0]));
            tbnorm = normalize(tbn*hemisphere);

	        const vec3 pbrspc = texture(colortex2, texcoord).xyz;

            

            texp[1].xyz = tbnorm.xyz*0.5f+0.5f, texp[0].xy = pbrspc.yz;
            colp[1].xyz *= to_linear(texture(colortex3,texcoord).xyz);
        } else {
            
        }


        // fill main buffer with sky-color
        float filled = texture(gbuffers0,fcoord.xy).w;
        if (fcoord.x < 0.5f && filled < 0.1f) {
            const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,1.f)),2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
            const vec4 cameraNormal = vec4(ltps[1].xyz*2.f-1.f,0.f);
            const vec4 cameraSPosition = ScreenSpaceToCameraSpace(screenSpaceCorrect);
            const vec4 cameraCenter = CameraCenterView;
            const vec4 cameraVector = vec4(normalize(cameraSPosition.xyz-cameraCenter.xyz),0.f);
            const vec3 reflVector = normalize(reflect(cameraVector.xyz,cameraNormal.xyz));
            const vec3 reflOrigin = cameraSPosition.xyz + cameraCenter.xyz + reflVector.xyz;

            const vec4 modelNormal = cameraNormal*gbufferModelView;
            const vec4 modelSPosition = CameraSpaceToModelSpace(cameraSPosition);
            const vec4 modelCenter = CameraSpaceToModelSpace(cameraCenter);
            const vec4 modelRefl = CameraSpaceToModelSpace(vec4(reflOrigin,1.f));
            const vec3 modelPosition = modelSPosition.xyz+modelCenter.xyz;
            const vec4 modelVector = vec4(normalize(modelPosition.xyz-modelCenter.xyz),0.f);

            const vec4 subPos = CameraSpaceToModelSpace(vec4(sunPosition.xyz,1.f));

            colp[1] = to_linear(atmosphere(
                modelVector.xyz,                                            // normalized ray direction
                modelPosition.xyz+vec3(0.f,6372e3f,0.f),  // planet position
                subPos.xyz,                                                 // position of the sun
                40.0f,                                           // intensity of the sun
                6371e3f,                                         // radius of the planet in meters
                6471e3f,                                         // radius of the atmosphere in meters
                vec3(5.5e-6, 13.0e-6, 22.4e-6),                  // Rayleigh scattering coefficient
                21e-6f,                                          // Mie scattering coefficient
                8e3f,                                            // Rayleigh scale height
                1.2e3f,                                          // Mie scale height
                0.758f                                           // Mie preferred scattering direction
            ).xyz);//, filled = 1.f;

            //colp[1] = SkyBox(normalize(wPositionRelative.xyz)*1.f,normalize(wSunPosition.xyz)).xyz, filled = 1.f;

            //colp[1] = SkyColor(wPosition.xyz, normalize(wSunPosition.xyz)).xyz, filled = 1.f;
        }

        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),filled);
        gl_FragData[1] = vec4(pack3x2(texp),texture(gbuffers2,fcoord.xy).w);
    #endif
}
