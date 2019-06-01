#include "/Globals/Header.glsl"

gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:01 */
#endif


void main(){
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 
        
    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy;
        mat2x3 colp = unpack3x2(texture(gbuffers0,fcoord.xy).xyz);
        vec3 fcolor = colp[1], fdiffc = 0.f.xxx;

        const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,1.f)),2.0f.xx,-1.f.xx),texture(depthtex0,fcoord).x,1.f);
        vec4 wPositionView = CameraSpaceToWorldSpace(vec4(0.f.xxx,1.f));
        vec4 wSunPosition = CameraSpaceToWorldSpace(vec4(sunPosition,1.f)) - vec4(wPositionView.xyz,0.f);
        vec4 wPosition = CameraSpaceToWorldSpace(ScreenSpaceToCameraSpace(screenSpaceCorrect));
        vec4 wPositionRelative = wPosition-vec4(wPositionView.xyz,0.f);

//TraceVoxel
        
        {
            //Voxel voxel = TraceVoxel(wPosition.xyz,normalize(wPositionRelative.xyz));
            //if (voxel.color.w > 0.f) fcolor = vec3(voxel.param.xy/65535.f,0.f);

            // Direct Light Phase...


            // Voxel Space Trace Phase...


            // Additional Shadings... (micro-shading)


        }
        colp[1] = fcolor;
        gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fcolor)),texture(gbuffers1,fcoord.xy).w);
        gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fdiffc)),1.f);
    #endif
}
