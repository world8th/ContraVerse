#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:4567 */
#endif

void main() {
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy, hcoord = fcoord.xy+vec2(0.5f,0.f);
        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 colh = unpack3x2(texture(gbuffers0,hcoord.xy).xyz);
        float dp = texture(depthtex0,fcoord.xy).x, dh = texture(depthtex0,hcoord.xy).x;
        
        if (dp >= dh) {
            colp[1].xyz = mix(colp[1].xyz,colh[1].xyz,texture(gbuffers0,hcoord.xy).www);
        };

        gl_FragData[0] = texture(gbuffers0,fcoord.xy);
        gl_FragData[1] = texture(gbuffers1,fcoord.xy);
        gl_FragData[2] = texture(gbuffers2,fcoord.xy);
        gl_FragData[3] = texture(gbuffers3,fcoord.xy);

        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),texture(colortex0,fcoord.xy).w);
    #endif
}
