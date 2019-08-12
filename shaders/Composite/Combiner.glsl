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
        //mat2x3 colp = unpack3x2(texture(colortex0,fcoord.xy).xyz);
        float dp = texture(depthtex0,fcoord.xy).x, dh = texture(depthtex0,hcoord.xy).x;
        //const float filled = texture(colortex0,fcoord.xy).w;
        mat2x3 rtps = unpack3x2(texture(colortex1,fcoord.xy).xyz);
        mat2x3 rtph = unpack3x2(texture(colortex1,hcoord.xy).xyz);

        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 colh = unpack3x2(texture(gbuffers0,hcoord.xy).xyz);
        vec3 fcolor = colp[1], fdiffc = 0.f.xxx;
        const float filled = texture(gbuffers0,fcoord.xy).w;

        const float reflc = 1.f;//0.1f; // TODO: unify with reflection shader 

        //colp[1].xyz = modelNormal.xyz*0.5f+0.5f;
        if (fcoord.x < 0.5f && fcoord.y < 0.5f && filled >= 0.1f) {
            //colp[1].xyz += rtps[1].xyz; // reflections apply 
            colp[1].xyz = colp[1].xyz*rtps[1].xyz;
        };

        if (dp >= dh && fcoord.x < 0.5f && fcoord.y < 0.5f) {
             // reflection in surfaces such as water 
            colh[1].xyz = colh[1].xyz*rtph[1].xyz;
            colp[1].xyz = mix(colp[1].xyz,colh[1].xyz,texture(colortex0,hcoord.xy).www); // transparencies 
        };

        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),texture(colortex0,fcoord.xy).w);
    #endif
}
