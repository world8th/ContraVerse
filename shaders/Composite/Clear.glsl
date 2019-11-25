
#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:45671 */
#endif


const float nshift = 0.0001f;

#define ENABLE_REFLECTIONS


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
        gl_FragData[4] = vec4(0.f);
        //gl_FragData[5] = texture(colortex3,fcoord.xy);

        const vec2 size = textureSize(colortex3,0);
        if (texcoord.x >= 0.f && texcoord.y >= 0.f && texcoord.x < (1.f/size.x) && texcoord.y < (1.f/size.y)) {
            Voxel vox = TraceVoxel(fract(cameraPosition),normalize(vec3(0.0f,-0.9999f,0.0f)));
            const float height = vox.position.y + cameraPosition.y;
            gl_FragData[3].x = height + 1.f - fract(cameraPosition.y);
            gl_FragData[3].w = 1.f;
        };

    #endif
}
