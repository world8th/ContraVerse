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


        const vec4 screenSpaceCorrect = vec4(fma(texcoord.xy,2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
        const vec4 modelNormal = vec4(ltps[1].xyz*2.f-1.f,0.f)*gbufferModelView;
        const vec4 modelPosition = CameraSpaceToModelSpace(ScreenSpaceToCameraSpace(screenSpaceCorrect));
        const vec4 modelCenter = CameraSpaceToModelSpace(CameraCenterView);
        const vec4 modelVector = vec4(normalize(modelPosition.xyz-modelCenter.xyz),0.f);


        //Voxel voxelData = TraceVoxel(modelCenter.xyz,modelVector.xyz);
        //if (fcoord.x < 0.5f && filled >= 0.1f && any(greaterThan(voxelData.color,0.f.xxx))) { colp[1].xyz = voxelData.color.xyz; }; 

        //colp[1].xyz = modelNormal.xyz*0.5f+0.5f;
        gl_FragColor = vec4(clamp(colp[1].xyz,0.f.xxx,1.f.xxx),1.f);
    #endif
}
