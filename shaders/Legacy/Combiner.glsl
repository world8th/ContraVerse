#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:03 */
#endif


const float temporalSamplingRate = 0.25f;

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
        mat2x3 rtps = unpack3x2(texture(colortex0,fcoord.xy).xyz);
        mat2x3 rtph = unpack3x2(texture(colortex0,hcoord.xy).xyz);

        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        mat2x3 colh = unpack3x2(texture(gbuffers0,hcoord.xy).xyz);
        vec3 fcolor = colp[1], fdiffc = 0.f.xxx;
        float filled = texture(gbuffers0,fcoord.xy).w;

        const float reflc = 1.f;//0.1f; // TODO: unify with reflection shader 

        //colp[1].xyz = modelNormal.xyz*0.5f+0.5f;
        if (fcoord.x < 0.5f && fcoord.y < 0.5f && filled >= 0.1f) {
            //colp[1].xyz += rtps[1].xyz; // reflections apply 
            colp[1].xyz = colp[1].xyz*rtps[1].xyz;
        };

        if (dp >= dh && fcoord.x < 0.5f && fcoord.y < 0.5f && filled >= 0.1f) {
             // reflection in surfaces such as water 
            colh[1].xyz = colh[1].xyz*rtph[1].xyz;
        };

        // 
        if (dot(colh[1].xyz,1.f.xxx) > 0.f && texture(colortex0,hcoord.xy).w > 0.f && dp >= dh && fcoord.x < 0.5f && fcoord.y < 0.5f) {
            colp[1].xyz = mix(colp[1].xyz,colh[1].xyz,texture(colortex0,hcoord.xy).www), filled = 1.f; // transparencies 
        }


        // reproject from... 
        if (filled >= 0.1f) {
            const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,2.f)),2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
            const vec4 worldSpace = CameraSpaceToModelSpace(ScreenSpaceToCameraSpace(screenSpaceCorrect));

            vec4 cameraDiff = vec4(cameraPosition,0.f) - vec4(previousCameraPosition,0.f);

            vec4 clipSpacePrev = gbufferProjection * gbufferPreviousModelView * (worldSpace + cameraDiff);
            clipSpacePrev.xyz /= clipSpacePrev.w;
            clipSpacePrev.xy = clipSpacePrev.xy * 0.5f + 0.5f;

            const vec4 screenSpaceClip = vec4(fma(fract(clipSpacePrev.xy),2.0f.xx,-1.f.xx), texture(colortex2,clipSpacePrev.xy*0.5f).w, 1.f);
            

            vec3 rtps = texture(colortex2,clipSpacePrev.xy*0.5f).xyz;//unpack3x2(texture(colortex2,clipSpacePrev.xy*0.5f).xyz);

            if (frameCounter != 0 && filled >= 0.1f && fcoord.x < 0.5f && 
                clipSpacePrev.x >= 0.f && clipSpacePrev.x < 1.f && 
                clipSpacePrev.y >= 0.f && clipSpacePrev.y < 1.f && 
                abs(screenSpaceClip.z-clipSpacePrev.z) <= 0.1f
                //distance(screenSpaceClip.xyz,clipSpacePrev.xyz*vec3(2.f.xx,1.f)-vec3(-1.f.xx,0.f)) <= 0.1f
            ) {
                //colp[1] = colp[1] * (1.f - max(float(frameCounter-1),0.f)/max(float(frameCounter),1.f)) + rtps[1];
                colp[1] = colp[1] * temporalSamplingRate + max(rtps,0.f.xxx);
                //colp[1] = max(rtps,0.f.xxx);
            };
        }


        // send modified color 
        gl_FragData[0] = vec4(pack3x2(colp),texture(colortex0,fcoord.xy).w);
        gl_FragData[1] = vec4(max(colp[1]*(1.f - temporalSamplingRate),0.f.xxx), dp); // planned more variable slots
        //gl_FragData[1] = vec4(colp[1],1.f - float(frameCounter)/float(frameCounter+1)); // planned more variable slots
    #endif
}
