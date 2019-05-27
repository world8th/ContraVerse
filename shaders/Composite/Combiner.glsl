#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:0 */
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
        mat2x3 colp = unpack3x2(texture(colortex0,fcoord.xy).xyz);
        mat2x3 colh = unpack3x2(texture(colortex0,hcoord.xy).xyz);
        float dp = texture(depthtex0,fcoord.xy).x, dh = texture(depthtex0,hcoord.xy).x;
        
        if (dp >= dh && fcoord.x < 0.5f) {
            colp[1].xyz = mix(colp[1].xyz,colh[1].xyz,texture(colortex0,hcoord.xy).www);
        };

        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),texture(colortex0,fcoord.xy).w);
    #endif
}
