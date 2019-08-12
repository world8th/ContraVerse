
// virtual render-passes 
for (int r = 0; r < 1; r++) {

    // is semi-transparent block?
    int semiTransparent = 0;
#if defined(TERRAIN) || defined(BLOCK) || defined(WATER)
    if (vparametric[0].x == 95) semiTransparent = 1;
    if (vparametric[0].x == 20) semiTransparent = 1;
    if (vparametric[0].x == 102) semiTransparent = 1;
    if (vparametric[0].x == 160) semiTransparent = 1;
    if (vparametric[0].x == 8) semiTransparent = 1;
    if (vparametric[0].x == 9) semiTransparent = 1;
    if (vparametric[0].x == 79) semiTransparent = 1;
    if (vparametric[0].x == 18) semiTransparent = 1;
    if (vparametric[0].x == 161) semiTransparent = 1;
    if (vparametric[0].x == 165) semiTransparent = 1;
     
#endif

    // 
    const vec4 cameraPosition = gbufferModelViewInverse * vec4(0.f.xxx,1.f);
    for (int i = 0; i < 3; i++) {
        fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];
        
        // 
        isSemiTransparent = semiTransparent;

        // get world space vertex
        vec4 vertex = gl_in[i].gl_Position;

        // integrity normal 
        fnormal *= gbufferModelViewInverse, ftangent *= gbufferModelViewInverse;

        // project into world space 
        vertex = gbufferModelViewInverse * gbufferProjectionInverse * vertex;

        vertex.xyz /= vertex.w;
        vertex.xyz += cameraPosition.xyz;

        //vertex.xyz = floor(vertex.xyz);

        // project into screen space 
        vertex.xyz -= cameraPosition.xyz;
        vertex.xyz *= vertex.w;
        vertex = gbufferProjection * gbufferModelView * vertex;
        vertex.xyz /= vertex.w;

        // resolution correction
        vertex.xy = fma(vertex.xy, 0.5f.xx, 0.5f.xx);

        // assign screen space coordinates
        //fscreencoord = vertex;

        // render-side
        vertex.x = fma(vertex.x, 0.5f, float(semiTransparent)*0.5f);
        vertex.y = fma(vertex.y, 0.5f, 0.0f);
        
        // re-correct screen space coordination for rendering
        vertex.xy = fma(vertex.xy, 2.f.xx, -1.f.xx);

        // finally emit vertex
        vertex.xyz *= vertex.w;
        //vertex.w = 1.f;
        gl_Position = vertex;
        EmitVertex();
    }
    EndPrimitive();


/*
    // 
    for (int i = 0; i < 3; i++) {
        fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];
        
        // 
        isSemiTransparent = semiTransparent;

        // get world space vertex
        vec4 vertex = gl_in[i].gl_Position;

        // integrity normal 
        fnormal *= gbufferModelViewInverse, ftangent *= gbufferModelViewInverse;

        // project into world space 
        vertex = gbufferModelViewInverse * gbufferProjectionInverse * vertex;

        vertex.xyz /= vertex.w;
        vertex.xyz += cameraPosition.xyz;


        const vec4 screenSpaceCorrect = vec4(0.0f.xx, texture(depthtex0,vec2(0.25f,0.25f)).x, 1.f);
        const vec4 wmap = CameraSpaceToModelSpace(ScreenSpaceToCameraSpace(screenSpaceCorrect));
        const float height = wmap.y + cameraPosition.y;


        // reflect on picked height
        vertex.y -= height;
        vertex.y *= -1.f;
        vertex.y += height;


        // project into screen space 
        vertex.xyz -= cameraPosition.xyz;
        vertex.xyz *= vertex.w;
        vertex = gbufferProjection * gbufferModelView * vertex;
        vertex.xyz /= vertex.w;

        // resolution correction
        vertex.xy = fma(vertex.xy, 0.5f.xx, 0.5f.xx);

        // assign screen space coordinates
        //fscreencoord = vertex;

        // render-side
        vertex.x = fma(vertex.x, 0.5f, float(semiTransparent)*0.5f);
        vertex.y = fma(vertex.y, 0.5f, 0.5f);
        
        // re-correct screen space coordination for rendering
        vertex.xy = fma(vertex.xy, 2.f.xx, -1.f.xx);

        // finally emit vertex
        vertex.xyz *= vertex.w;
        //vertex.w = 1.f;
        gl_Position = vertex;
        EmitVertex();
    }
    EndPrimitive();
*/
}
