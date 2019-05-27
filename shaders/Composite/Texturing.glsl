#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:4567 */
#endif

const int PRETEXTURED = 0;
const int COORDINATED = 1;



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
            colp[1].xyz *= texture(colortex3,colp[0].xy).xyz;
        } else {
            
        }
        
        gl_FragData[0] = texture(gbuffers0,fcoord.xy);
        gl_FragData[1] = texture(gbuffers1,fcoord.xy);
        gl_FragData[2] = texture(gbuffers2,fcoord.xy);
        gl_FragData[3] = texture(gbuffers3,fcoord.xy);
        gl_FragData[0] = vec4(pack3x2(colp),texture(colortex0,fcoord.xy).w);//texture(gbuffers0,texcoord.xy);
    #endif
}
