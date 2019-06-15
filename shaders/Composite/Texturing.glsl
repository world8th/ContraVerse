#include "/Globals/Header.glsl"
#include "/Utils/Sky.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:4 */
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
        mat2x3 tang = unpack3x2(texture(gbuffers3,fcoord.xy).xyz);
        const int mode = !all(equal(colp[0].xy,0.f.xx)) ? COORDINATED : PRETEXTURED;

        // special edition
        if (mode == COORDINATED) {
            const vec2 tsize = textureSize(colortex3,0);
            const vec2 atlas = tsize/TEXTURE_SIZE, atlasInv = TEXTURE_SIZE/tsize;
            const vec2 anch = floor(colp[0].xy);
            const vec2 texcoord = fma(clamp(colp[0].xy-anch,0.f.xx,1.f.xx)+anch,atlasInv,round(texp[0].xy)*atlasInv);

            //texcoord *= TEXTURE_SIZE;
            //vec2 textile = floor(texcoord);
            //vec2 texofft = fract(texcoord);

            // TODO: Parallax Occlusion Mapping in deferred phase... 
            

            colp[1].xyz *= texture(colortex3,texcoord).xyz;
        } else {
            
        }


        // fill main buffer with sky-color
        float filled = texture(gbuffers0,fcoord.xy).w;
        if (fcoord.x < 0.5f && filled < 0.1f) {
            const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord*vec2(2.f,1.f)),2.0f.xx,-1.f.xx),  0.001f , 1.f);
            const vec4 modelCenter = CameraSpaceToModelSpace(CameraCenterView);
            const vec4 modelPosition = CameraSpaceToModelSpace(ScreenSpaceToCameraSpace(screenSpaceCorrect));
            const vec4 modelVector = vec4(normalize(modelPosition.xyz-modelCenter.xyz),0.f);
            const vec4 subPos = CameraSpaceToModelSpace(vec4(sunPosition.xyz,1.f));

            colp[1] = atmosphere(
                modelVector.xyz,                                            // normalized ray direction
                (modelPosition.xyz-modelCenter.xyz)+vec3(0.f,6372e3f,0.f),  // planet position
                subPos.xyz,                                                 // position of the sun
                40.0f,                                           // intensity of the sun
                6371e3f,                                         // radius of the planet in meters
                6471e3f,                                         // radius of the atmosphere in meters
                vec3(5.5e-6, 13.0e-6, 22.4e-6),                  // Rayleigh scattering coefficient
                21e-6f,                                          // Mie scattering coefficient
                8e3f,                                            // Rayleigh scale height
                1.2e3f,                                          // Mie scale height
                0.758f                                           // Mie preferred scattering direction
            ).xyz, filled = 1.f;

            //colp[1] = SkyBox(normalize(wPositionRelative.xyz)*1.f,normalize(wSunPosition.xyz)).xyz, filled = 1.f;

            //colp[1] = SkyColor(wPosition.xyz, normalize(wSunPosition.xyz)).xyz, filled = 1.f;
        }

        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),filled);
    #endif
}
