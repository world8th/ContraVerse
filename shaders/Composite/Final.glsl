#include "/Globals/Header.glsl"

gin vec4 texcoord;

void main() {
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        
        const vec2 fcoord = texcoord.xy * vec2(0.5f);
        const vec3 cps = texture(colortex0,fcoord.xy).xyz;
        gl_FragColor = vec4(to_sRGB(cps),1.f);

        //const vec3 hemisphere = randomHemisphereCosine(vec3(fcoord.xy*vec2(viewWidth,viewHeight),frameTimeCounter));
        //gl_FragColor = vec4(hemisphere*0.5f+0.5f,1.f);
    #endif
}
