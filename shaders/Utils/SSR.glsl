

vec4 GetColorSSR(){
    return vec4(0.f);
}

float GetDepthSSR(in vec2 screenSpaceCoord){
    return 0.f;
}

vec4 EfficientReflection(in vec3 cameraSpaceOrigin, in vec3 cameraSpaceDirection){
    const vec4 worldSpaceOrigin = gbufferModelView * vec4(cameraSpaceOrigin,1.0f);
    const vec4 worldSpaceDirection = vec4(cameraSpaceDirection,1.f) * gbufferModelViewInverse;
    vec4 screenSpaceDirection = vec4(cameraSpaceDirection,1.f) * gbufferProjectionInverse;
    screenSpaceDirection.xyz /= screenSpaceDirection.w;

    // 
    screenSpaceDirection.xy *= vec2(viewWidth,viewHeight);
    screenSpaceDirection.xy /= max(abs(screenSpaceDirection.x),abs(screenSpaceDirection.y));

    //
    return vec4(0.f);
}
