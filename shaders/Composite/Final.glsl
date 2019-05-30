#include "/Globals/Header.glsl"

gin vec4 texcoord;

void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        vec2 fcoord = texcoord.xy * vec2(0.5f,1.f);
        vec3 cps = texture(colortex0,fcoord.xy).xyz;
        mat2x3 colp = unpack3x2(cps);

        const vec2 shadowsize = textureSize(shadowcolor0,0);
        const vec2 buffersize = textureSize(colortex0,0);

        fcoord *= vec2(2.f,1.f);
        //colp[1] = texture(shadowcolor0,vec2(fcoord)).xyz;
        colp[1] = texture(shadowcolor0,vec2(fcoord*buffersize/shadowsize)).xyz;

        gl_FragColor = vec4(clamp(colp[1].xyz,0.f.xxx,1.f.xxx),1.f);
    #endif
}
