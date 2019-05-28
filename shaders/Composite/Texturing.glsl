#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:4 */
#endif

const int PRETEXTURED = 0, COORDINATED = 1;

// TODO: add to definition settings officially 
#define TEXTURE_SIZE 16 

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
            vec2 texcoord = colp[0].xy;

            //texcoord *= TEXTURE_SIZE;
            //vec2 textile = floor(texcoord);
            //vec2 texofft = fract(texcoord);

            // TODO: Parallax Occlusion Mapping in deferred phase... 
            

            colp[1].xyz *= texture(colortex3,texcoord).xyz;
        } else {
            
        }

        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),texture(gbuffers0,fcoord.xy).w);
    #endif
}
