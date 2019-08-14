#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:0 */
#endif

vec3 GetPosition(in vec2 fcoord){
    const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,2.f)),2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
    return ScreenSpaceToCameraSpace(screenSpaceCorrect).xyz;
};

vec3 GetNormal(in vec2 fcoord){
    const vec3 p0 = GetPosition(fcoord);
    const vec3 p1 = GetPosition(fcoord + (1.f / (vec2(viewWidth,viewHeight)*0.5f)) * vec2(1.f,0.f));
    const vec3 p2 = GetPosition(fcoord + (1.f / (vec2(viewWidth,viewHeight)*0.5f)) * vec2(0.f,1.f));
    return normalize(cross(p1-p0,p2-p0));
};

void main() {
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy;
        float dp = texture(depthtex0,fcoord.xy).x;
        mat2x3 colp = unpack3x2(texture(colortex1,fcoord.xy).xyz);
        vec3 conp = GetNormal(fcoord.xy);

        float counter = 1.f;
        for (int i=0;i<64;i++) {
            const highp vec2 shifting = randomH2(vec2(float(i),float(frameCounter)));
            const vec2 pix = 1.f / (vec2(viewWidth,viewHeight));

            // Add Support for GI
            const vec2 cov = fcoord.xy+pix*16.f*shifting;
            const mat2x3 civ = unpack3x2(texture(colortex1,cov.xy).xyz);
            const vec3 cin = GetNormal(cov.xy);

            if (dot(conp,cin) > 0.2f) {
                colp[1] += civ[1];
                counter += 1.f;
            };
        };

        colp[1] /= counter;
        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),texture(colortex1,fcoord.xy).w);
    #endif
}
