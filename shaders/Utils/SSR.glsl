#ifdef FSH
#ifdef COMPOSITE

vec4 GetColorSSR(){
    return vec4(0.f);
}

float GetDepthSSR(in vec2 screenSpaceCoord) {
    const vec2 txy = (screenSpaceCoord*0.5f+0.5f)*vec2(0.5f,1.f); // normalize screen space coordinates
    const vec4 txl = textureGather(depthtex0,txy,0);
    const vec2 ttf = fract(txy*textureSize(depthtex0,0)-0.5f);
    const vec2 px = vec2(1.f-ttf.x,ttf.x), py = vec2(1.f-ttf.y,ttf.y);
    const mat2x2 i2 = outerProduct(px,py);
    return dot(txl,vec4(i2[0],i2[1]).zwyx); // interpolate
}

vec3 GetNormalSSR(in vec2 screenSpaceCoord){
    const vec2 txy = (screenSpaceCoord*0.5f+0.5f)*vec2(0.5f,1.f); // normalize screen space coordinates
    const mat2x3 colp = unpack3x2(texelFetch(gbuffers1,ivec2(txy.xy*textureSize(gbuffers1,0)),0).xyz);
    return normalize(colp[1]*2.f-1.f);
}

// almost pixel-perfect screen space reflection 
vec4 EfficientSSR(in vec3 cameraSpaceOrigin, in vec3 cameraSpaceDirection){
    vec4 screenSpaceOrigin = CameraSpaceToScreenSpace(vec4(cameraSpaceOrigin,1.f));
    vec4 screenSpaceOriginNext = CameraSpaceToScreenSpace(vec4(cameraSpaceOrigin+cameraSpaceDirection,1.f));
    vec4 screenSpaceDirection = vec4(normalize(screenSpaceOriginNext.xyz-screenSpaceOrigin.xyz),0.f);
    screenSpaceDirection.xyz = normalize(screenSpaceDirection.xyz);

    // 
    const vec2 screenSpaceDirSize = abs(screenSpaceDirection.xy*vec2(viewWidth*0.5f,viewHeight));
    screenSpaceDirection.xyz /= max(screenSpaceDirSize.x,screenSpaceDirSize.y)*(1.f/16.f); // half of image size

    // 
    vec3 finalOrigin = screenSpaceOrigin.xyz;
    for (int i=0;i<512;i++) { // do precise as possible 
        screenSpaceOrigin.xyz += screenSpaceDirection.xyz;

        // check if origin gone from screen 
        if (any(lessThanEqual(screenSpaceOrigin.xyz,vec3(-1.f.xx,0.f))) || any(greaterThan(screenSpaceOrigin.xyz,vec3(1.f.xx,1.f.x)))) { break; };

        // 
        if (GetDepthSSR(screenSpaceOrigin.xy)<=screenSpaceOrigin.z) {
            vec3 screenSpaceOrigin = screenSpaceOrigin.xyz-screenSpaceDirection.xyz, screenSpaceDirection = screenSpaceDirection.xyz * 0.5f;

            // ray origin refinement
            for (int j=0;j<4;j++) {
                if (GetDepthSSR(screenSpaceOrigin.xy)<=screenSpaceOrigin.z) {
                    screenSpaceOrigin -= screenSpaceDirection, screenSpaceDirection *= 0.5f;
                } else {
                    screenSpaceOrigin += screenSpaceDirection;
                }
            }
            
            // recalculate ray origin by normal 
            const vec3 cameraNormal = GetNormalSSR(screenSpaceOrigin.xy);
            const vec3 inPosition = ScreenSpaceToCameraSpace(vec4(screenSpaceOrigin.xy,GetDepthSSR(screenSpaceOrigin.xy),1.f)).xyz;
            const float dist = dot(inPosition.xyz-cameraSpaceOrigin,cameraNormal)/dot(cameraNormal,cameraSpaceDirection);
            screenSpaceOrigin = CameraSpaceToScreenSpace(vec4(cameraSpaceDirection*dist+cameraSpaceOrigin,1.f)).xyz;
            
            // check ray deviation 
            if (dot(cameraNormal,cameraSpaceDirection)<=0.f && dot(GetNormalSSR(screenSpaceOrigin.xy),cameraNormal)>0.5f && abs(GetDepthSSR(screenSpaceOrigin.xy)-screenSpaceOrigin.z)<0.001f) {
                finalOrigin = screenSpaceOrigin; //break; 
            }; break; // 
        }
    }

    //
    return vec4(finalOrigin,1.f);
}
#endif
#endif