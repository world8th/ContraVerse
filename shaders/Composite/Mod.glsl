#include "/Globals/Header.glsl"

gin vec4 texcoord;



#ifdef FSH
/* DRAWBUFFERS:4567 */
#endif

void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        
    #endif
}
