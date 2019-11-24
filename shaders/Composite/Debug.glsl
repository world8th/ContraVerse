#include "/Globals/Header.glsl"

gin vec4 texcoord;



#ifdef FSH
/* DRAWBUFFERS:0123 */
#endif

void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        vec2 fcoord = texcoord.xy;
        gl_FragDepth = 1.f;
        gl_FragData[0] = texture(colortex0,texcoord.xy);
    #endif
}
