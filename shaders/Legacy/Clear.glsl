#include "/Globals/Header.glsl"

gin vec4 texcoord;



#ifdef FSH
/* DRAWBUFFERS:456712 */
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
        // clear some gbuffers images before render-passes
        gl_FragDepth = 1.f;
        gl_FragData[0] = vec4(0.f);
        gl_FragData[1] = vec4(0.f);//texture(gbuffers1,fcoord.xy);//vec4(0.f);
        gl_FragData[2] = vec4(0.f);
        gl_FragData[3] = vec4(0.f);
        gl_FragData[4] = texture(gbuffers1,fcoord.xy);
        gl_FragData[5] = texture(colortex3,fcoord.xy);
    #endif
}
