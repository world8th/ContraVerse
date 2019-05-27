
// virtual render-passes 
for (int r = 0; r < 1; r++) {
    for (int i = 0; i < 3; i++) {
        fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];

        // get world space vertex
        vec4 vertex = gl_in[i].gl_Position;
        vertex = gbufferModelViewInverse * gbufferProjectionInverse * vertex;
        vertex.xyz += cameraPosition;
        
        // integrity normal 
        fnormal *= gbufferModelViewInverse, ftangent *= gbufferModelViewInverse;

        // project into screen
        vertex.xyz -= cameraPosition;

        vertex = gbufferProjection * gbufferModelView * vertex;


        // resolution correction
        vertex.xyz /= vertex.w;
        vertex.xy = fma(vertex.xy, 0.5f.xx, 0.5f.xx);

        // assign screen space coordinates
        //fscreencoord = vertex;

        // is semi-transparent block?
        isSemiTransparent = 0;

        // render-side
        vertex.x = vertex.x * 0.5f + float(isSemiTransparent)*0.5f;
        
        // re-correct screen space coordination for rendering
        vertex.xy = fma(vertex.xy, 2.f.xx, -1.f.xx);

        // finally emit vertex
        vertex.xyz *= vertex.w;
        gl_Position = vertex;
        EmitVertex();
    }
    EndPrimitive();
}
