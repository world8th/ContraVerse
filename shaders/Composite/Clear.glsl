#include "/Globals/Header.glsl"

gin vec4 texcoord;



#ifdef FSH
/* DRAWBUFFERS:45670 */
#endif

void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        gl_FragData[0] = vec4(0.f);
        gl_FragData[1] = vec4(0.f);//texture(gbuffers1,texcoord.xy);
        gl_FragData[2] = vec4(0.f);//texture(gbuffers2,texcoord.xy);
        gl_FragData[3] = vec4(0.f);//texture(gbuffers3,texcoord.xy);
        gl_FragData[4] = texture(gbuffers0,texcoord.xy);
    #endif
}
