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
        mat2x3 ltps = unpack3x2(texture(colortex1,fcoord.xy).xyz);

        const float filled = texture(colortex0,fcoord.xy).w;
        const vec2 shadowsize = textureSize(shadowcolor0,0);
        const vec2 buffersize = textureSize(colortex0,0);

        

        const vec4 normal = vec4(ltps[1].xyz*2.f-1.f,0.f)*gbufferModelView;


        //colp[1] = texture(shadowcolor0,vec2(fcoord)).xyz;
        //colp[1] = texture(shadowcolor0,vec2(texcoord.xy*vec2(1.f,1.f)*buffersize/shadowsize)).xyz;

        const vec4 screenSpaceCorrect = vec4(fma(texcoord.xy,2.0f.xx,-1.f.xx),filled > 0.f ? texture(depthtex0,fcoord.xy).x : 1.f,1.f);
        const vec4 wPosition = CameraSpaceToWorldSpace(ScreenSpaceToCameraSpace(screenSpaceCorrect));
        const vec4 wView = CameraSpaceToWorldSpace(vec4(0.f.xxx,1.f));
        const vec4 wVector = vec4(normalize(wPosition.xyz-wView.xyz),0.f);

        //Voxel voxel = TraceVoxel(wPosition.xyz-TileOfVoxel(cameraPosition.xyz), wVector.xyz);
        //if (voxel.color.w > 0.f) colp[1] = vec3(voxel.color.xyz);


        gl_FragColor = vec4(clamp(colp[1].xyz,0.f.xxx,1.f.xxx),1.f);
    #endif
}
