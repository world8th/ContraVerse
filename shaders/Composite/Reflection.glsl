#include "/Globals/Header.glsl"
#include "/Utils/Sky.glsl"


gin vec4 texcoord;

uniform ivec2 atlasSize;

#ifdef FSH
/* DRAWBUFFERS:01 */
#endif


const float nshift = 0.0001f;

#define ENABLE_REFLECTIONS

void main() {
    #ifdef VSH
        texcoord = gl_MultiTexCoord0;
        gl_Position = ftransform();
    #endif
    #ifdef GSH 

    #endif
    #ifdef FSH
        const vec2 fcoord = texcoord.xy;
        const vec3 cps = texture(colortex0,fcoord.xy).xyz;
        mat2x3 colp = unpack3x2(cps);
        mat2x3 enrg = unpack3x2(texture(colortex1,fcoord.xy).xyz);
        mat2x3 ltps = unpack3x2(texture(gbuffers1,fcoord.xy).xyz);
        mat2x3 texp = unpack3x2(texture(gbuffers2,fcoord.xy).xyz);
        //mat2x3 relp = unpack3x2(texture(gbuffers3,fcoord.xy).xyz);


        const float filled = texture(colortex0,fcoord.xy).w;
        const vec2 shadowsize = textureSize(shadowcolor0,0);
        const vec2 buffersize = textureSize(colortex0,0);

        const vec4 screenSpaceCorrect = vec4(fma(fract(fcoord.xy*vec2(2.f,2.f)),2.0f.xx,-1.f.xx), texture(depthtex0,fcoord.xy).x, 1.f);
        const vec4 cameraNormal = vec4(texp[1].xyz*2.f-1.f,0.f);
        const vec4 cameraSPosition = ScreenSpaceToCameraSpace(screenSpaceCorrect);
        const vec4 cameraCenter = CameraCenterView;
        const vec4 cameraVector = vec4(normalize(cameraSPosition.xyz-cameraCenter.xyz),0.f);
        vec3 reflVector = normalize(reflect(cameraVector.xyz,cameraNormal.xyz));
        const vec3 reflOrigin = cameraSPosition.xyz + cameraCenter.xyz + reflVector.xyz;


        //reflVector.xyz = 
        //texp


        vec3 fenergy = 1.f.xxx;//enrg[1];
        vec3 fcolor = colp[1], freflc = 0.f.xxx;//fcolor;
    #ifdef ENABLE_REFLECTIONS
        if (filled >= 0.1f && fcoord.y < 0.5f && dot(colp[1].xyz,1.f.xxx)<=0.01f) {

            // Screen Space Reflection Tracing...
            const vec4 ssrPos = EfficientSSR(cameraSPosition.xyz+normalize(cameraNormal.xyz)*nshift,reflVector);
            const ivec2 ssrTx = ivec2(((ssrPos.xy*0.5f+0.5f)*vec2(0.5f,0.5f))*textureSize(colortex0,0));
            const vec4 cps = texelFetch(colortex0,ssrTx.xy,0).xyzw;

            // Apply Shadow Mapping for SSLR
            const mat2x3 colp = unpack3x2(texelFetch(gbuffers0,ssrTx.xy,0).xyz);
            const mat2x3 ltps = unpack3x2(texelFetch(gbuffers1,ssrTx.xy,0).xyz);
            const mat2x3 texp = unpack3x2(texelFetch(gbuffers2,ssrTx.xy,0).xyz);
            const vec3 fcolor = colp[1], fdiffc = 0.f.xxx;
            const vec4 ssrl = vec4(unpack3x2(cps.xyz)[1],cps.w) * vec4(fcolor,1.f);

            // Voxel Space Reflection Tracing, Sampling and Shading... 
            const vec4 modelNormal = cameraNormal*gbufferModelView;
            const vec4 modelSPosition = CameraSpaceToModelSpace(cameraSPosition);
            const vec4 modelCenter = CameraSpaceToModelSpace(cameraCenter);
            const vec4 modelRefl = CameraSpaceToModelSpace(vec4(reflOrigin,1.f));
            const vec3 modelPosition = modelSPosition.xyz+modelCenter.xyz;

            const vec3 reflV = normalize(modelRefl.xyz-modelPosition.xyz+modelCenter.xyz);
            const vec4 subPos = CameraSpaceToModelSpace(vec4(sunPosition.xyz,1.f));
            const vec4 sbpPos = CameraSpaceToModelSpace(vec4(shadowLightPosition.xyz,1.f));


            freflc.xyz = to_linear(atmosphere(
                reflV.xyz,                                            // normalized ray direction
                modelPosition.xyz+vec3(0.f,6372e3f,0.f),  // planet position
                subPos.xyz,                                                 // position of the sun
                40.0f,                                           // intensity of the sun
                6371e3f,                                         // radius of the planet in meters
                6471e3f,                                         // radius of the atmosphere in meters
                vec3(5.5e-6, 13.0e-6, 22.4e-6),                  // Rayleigh scattering coefficient
                21e-6f,                                          // Mie scattering coefficient
                8e3f,                                            // Rayleigh scale height
                1.2e3f,                                          // Mie scale height
                0.758f                                           // Mie preferred scattering direction
            ).xyz)*fenergy;

            float vxgiDist = 10000.f;

            const float bkheight = fract(modelPosition+fract(cameraPosition.xyz)).y;
            const float waterfix = bkheight>0.5f && bkheight<1.f ? 0.125f : 0.f;
            const vec3 wpf = CameraSpaceToModelSpace(ScreenSpaceToCameraSpace(vec4(ssrPos.xyz,1.f))).xyz;
            const float sslrDist = distance(wpf.xyz,modelPosition)-nshift;
            const vec3 modpos = modelPosition+normalize(modelNormal.xyz)*(nshift+waterfix)+fract(cameraPosition);

            Voxel voxelData = TraceVoxel(modpos,reflV);
            if (any(greaterThan(voxelData.color.xyz,0.f.xxx))) {
                const vec3 bmin = voxelData.position.xyz-(0.0f+nshift), bmax = voxelData.position.xyz+(1.0f+nshift);
                const vec2 tbox = intersect(modpos, normalize(reflV), bmin, bmax);

                if (tbox.y >= tbox.x && tbox.y >= 0.f) {
                    const vec2 tsize = textureSize(colortex3,0);
                    const vec2 atlas = tsize/TEXTURE_SIZE, atlasInv = TEXTURE_SIZE/tsize;
                    const vec2 anch = voxelData.tbase.xy*255.f;

                    // 
                    vec3 bsect = (modpos+normalize(reflV)*max(tbox.x>=0.f?tbox.x:tbox.y,0.f))-bmin;
                    vec3 isect = clamp(bsect/(1.0f+nshift*2.f),0.f,1.f);
                    vec3 nvbox = clamp(bsect/(1.0f+nshift*2.f),0.f,1.f)*2.f-1.f;

                    // top and bottom texcoord 
                    vec2 lcoord = isect.xz; lcoord.x = lcoord.x;

                    // face texcoord 
                    if ( abs(nvbox.x)>0.9999f ) { lcoord = isect.zy; lcoord.y = 1.f-lcoord.y; };
                    if ( abs(nvbox.z)>0.9999f ) { lcoord = isect.xy; lcoord.y = 1.f-lcoord.y; };

                    // 
                    if ( -(nvbox.y) > 0.9999f ) lcoord.y = 1.f-lcoord.y;

                    // Get True Texcoord and Texture For Voxel
                    const vec2 texcoord = (lcoord+anch)/atlas;

                    // Get Voxel Texture 
                    if (any(greaterThan(voxelData.color.xyz,0.f.xxx))) {
                        const vec3 modelNormal = normalize(floor(abs(nvbox)*1.000001f)*sign(nvbox));
                        const vec3 mdk = bsect+bmin-modelNormal*nshift-fract(cameraPosition.xyz);

                        const vec4 shadowPosition = ModelSpaceToShadowSpace(vec4(mdk,1.f));
                        const vec2 shadowTexcoord = (shadowPosition.xy*0.5f+0.5f)*vec2(SHADOW_SIZE_RATE.x,1.f)+vec2(SHADOW_SHIFT.x,0.f);
                        const float shadowTex = linShadow(shadowTexcoord).x*2.f-1.f;
                        const float vibrance = (shadowTex.x-shadowPosition.z)+nshift-0.00001f;

                        const float minShading = voxelData.lmcoord.x>=0.905f ? 16.f : 0.f; //ltps[0].x;
                        const float normalShading = minShading+(dot(modelNormal.xyz,normalize(subPos.xyz-modelPosition.xyz))*0.5f+0.5f)*clamp(2.f-minShading,0.f,2.f);

                        vxgiDist = max(tbox.x>=0.f?tbox.x:tbox.y,0.f), 
                        freflc.xyz = fenergy*voxelData.color.xyz*to_linear(texture(colortex3,texcoord).xyz), //*voxelData.color.xyz;
                        freflc.xyz *= vibrance>=0.00001 ? normalShading : minShading;
                    };
                };
            };

            // Apply SSLR reflection 
            if (length(screenSpaceCorrect.xyz-ssrPos.xyz)>=nshift && sslrDist<=vxgiDist) {
                freflc.xyz = mix(freflc.xyz,ssrl.xyz*fenergy,ssrl.w*ssrPos.w);
            };

            // Finalize Result
            //freflc = colp[1];

            //fcolor.xyz = cameraNormal.xyz*0.5f+0.5f;
        }
    #endif

        gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),fcolor)),texture(gbuffers1,fcoord.xy).w);
        gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),freflc+colp[1].xyz)),1.f); // Shadow Shading + Reflections GI summary... (TODO: Fix Shadows)
    #endif
}
