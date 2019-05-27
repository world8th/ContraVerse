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
        // clear some gbuffers images before render-passes
        gl_FragData[0] = vec4(0.f);
        gl_FragData[1] = vec4(0.f);
        gl_FragData[2] = vec4(0.f);
        gl_FragData[3] = vec4(0.f);
    #endif
}
