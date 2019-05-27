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
        const vec2 fcoord = texcoord.xy * vec2(0.5f,1.f);
        
        const vec3 cps = texture(colortex0,fcoord.xy).xyz;
        const mat2x3 porn32 = unpack3x2(cps);
        //gl_FragColor = vec4(cps,1.f);
        gl_FragColor = vec4(clamp(porn32[1].xyz,0.f.xxx,1.f.xxx),1.f);
    #endif
}
