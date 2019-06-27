#include "/Globals/Header.glsl"

// From Geometry shader input
#if (defined(FSH) || defined(GSH))
gin vec4 ftangent;
gin vec4 fnormal;
gin vec4 fbitangents;
gin vec4 ftexcoord;
gin vec4 ftexcoordam;
gin vec4 flmcoord;
gin vec4 fcolor;
flat gin ivec4 fparametric;
flat gin int isVoxel;
#endif

// From Vertex shader input
#if (defined(VSH) || defined(GSH))
vin vec4 vtangent gap;
vin vec4 vnormal gap;
vin vec4 vbitangents gap;
vin vec4 vtexcoord gap;
vin vec4 vtexcoordam gap;
vin vec4 vlmcoord gap;
vin vec4 vcolor gap;
flat vin ivec4 vparametric gap;
#endif

#ifdef VSH
attribute vec4 at_tangent;
attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;
vec4 correctNormal() { return vec4(gl_NormalMatrix*gl_Normal,0.f)*shadowModelView; }
#endif

#ifndef TEXTURE_SIZE
#define TEXTURE_SIZE 16
#endif

// GSO input
#ifdef GSH
layout(triangles) in;
layout(triangle_strip, max_vertices = 6) out;
#endif

// FTU input 
#ifdef FSH
uniform sampler2D tex;
uniform sampler2D lightmap;
#endif

uniform ivec2 atlasSize;

// 

void main() {
#ifdef VSH

    // 
	const vec2 texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	const vec2 midcoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord,0.0f,1.f)).st;
	const vec2 texcoordminusmid = texcoord-midcoord;

    // 
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vtexcoord.st    = fma(sign(texcoordminusmid),0.5.xx,0.5.xx);

    // 
    vparametric = ivec4(mc_Entity.xy,0.f.xx);
	vlmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	vcolor = to_linear(gl_Color);

	// 
    vec4 scrnSpace = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
	vec4 viewSpace = shadowProjectionInverse * scrnSpace; viewSpace.xyz /= viewSpace.w;

	// 
	vnormal = correctNormal(), vtangent = vec4(at_tangent.xyz, 0.f);
	gl_Position = scrnSpace;
	gl_FogFragCoord = length(viewSpace.xyz);

#endif

#ifdef GSH

    isVoxel = 0;

    // 
    const vec4 cameraPosition = vec4(cameraPosition,1.f);//gbufferModelViewInverse * vec4(0.f.xxx,1.f);
    mat3 vertices = mat3(0.f.xxx,0.f.xxx,0.f.xxx);
    vec3 normal = 0.f.xxx;
    for (int i = 0; i < 3; i++) {
        fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];

        // get world space vertex
        vec4 vertex = gl_in[i].gl_Position;
        vertex = shadowModelViewInverse * shadowProjectionInverse * vertex;
        vertex.xyz /= vertex.w;
        vertex.xyz = fartu(vertex.xyz);//fract(cameraPosition.xyz);

        // set vertice 
        vertices[i] = vertex.xyz;

        // reproject into shadow space 
        vertex.xyz = defartu(vertex.xyz);
        vertex.xyz *= vertex.w;
        vertex = shadowProjection * shadowModelView * vertex;
        vertex.xyz /= vertex.w;

        // 
        normal += fnormal.xyz;

        // integrity normal 
        fnormal *= shadowModelViewInverse, ftangent *= shadowModelViewInverse;

        // resolution correction
        vertex.xy = fma(vertex.xy, 0.5f.xx, 0.5f.xx);

        // shadow-space render-side
        vertex.x *= (float(shadowMapResolution)-contraSize.x)/float(shadowMapResolution);
        vertex.x += contraSize.x/float(shadowMapResolution); // TODO: better shadow resolution support 

        // re-correct screen space coordination for rendering
        vertex.xy = fma(vertex.xy, 2.f.xx, -1.f.xx);

        // finally emit vertex
        vertex.xyz *= vertex.w;
        gl_Position = vertex;
        EmitVertex();
    }
    EndPrimitive();

    // div by 3 that normal i.e. 1.f/3.f
    { normal *= 0.333333333f, isVoxel = 1; };
    bool validVoxel = false;

    // Pre-Calculate into Voxel-Space 
    vec3 centerOfTriangle = CenterOfTriangle(vertices);
    vec3 normalOfTriangle = normal.xyz;//NormalOfTriangle(vertices);
    vec3 offsetOfVoxel = CalcVoxelOfBlock(centerOfTriangle,normalOfTriangle);
    //vec3 tileOfBlock = TileOfVoxel(offsetOfVoxel);
    //vec3 tileOfCamera = TileOfVoxel(cameraPosition.xyz);

    // 
    if (FilterForVoxel(centerOfTriangle,normalOfTriangle)) validVoxel = true;

    // 
    //if (validVoxel) {

    validVoxel = validVoxel && vparametric[0].x > 0.f;
    validVoxel = validVoxel && vparametric[0].x != 85.f;
    validVoxel = validVoxel && vparametric[0].x != 113.f;
    validVoxel = validVoxel && vparametric[0].x != 102.f;
    validVoxel = validVoxel && vparametric[0].x != 160.f;
    validVoxel = validVoxel && vparametric[0].x != 50.f;
    validVoxel = validVoxel && vparametric[0].x != 76.f;
    validVoxel = validVoxel && vparametric[0].x != 107.f;
    
    validVoxel = validVoxel && vparametric[0].x != 183.f;
    validVoxel = validVoxel && vparametric[0].x != 184.f;
    validVoxel = validVoxel && vparametric[0].x != 185.f;
    validVoxel = validVoxel && vparametric[0].x != 186.f;
    validVoxel = validVoxel && vparametric[0].x != 187.f;
    validVoxel = validVoxel && vparametric[0].x != 188.f;
    validVoxel = validVoxel && vparametric[0].x != 189.f;
    validVoxel = validVoxel && vparametric[0].x != 190.f;
    validVoxel = validVoxel && vparametric[0].x != 191.f;
    validVoxel = validVoxel && vparametric[0].x != 192.f;

    if (validVoxel) {
        for (int i = 0; i < 3; i++) {
            fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];

            // get world space vertex
            vec4 vertex = gl_in[i].gl_Position;
            vertex = shadowModelViewInverse * shadowProjectionInverse * vertex;
            vertex.xyz /= vertex.w;
            vertex.xyz = fartu(vertex.xyz); // shift into world space

            // 
            vec3 fft = round(vertex.xyz - offsetOfVoxel.xyz);
            if (abs(dot(normalOfTriangle,vec3(0.f,1.f,0.f))) > 0.9999f) fft.xyz = fft.zyx;
            if (abs(dot(normalOfTriangle,vec3(1.f,0.f,0.f))) > 0.9999f) fft.xyz = fft.zxy;
            if (abs(dot(normalOfTriangle,vec3(0.f,0.f,1.f))) > 0.9999f) fft.xyz = fft.yzx;

            // 
            const vec3 ntile = vec3(offsetOfVoxel.x+fft.x,offsetOfVoxel.y,offsetOfVoxel.z+fft.z);
            const vec3 ttile = (ntile+32.f)*vec3(2.f,1.f,2.f);
            vertex.xyz = vec3(VoxelToTextureSpace(ttile).xy,(centerOfTriangle.y+32.f)/64.f); // 

            // integrity normal 
            fnormal *= shadowModelViewInverse, ftangent *= shadowModelViewInverse;

            // re-correct screen space coordination for rendering
            vertex.xy = fma(vertex.xy, 2.f.xx, -1.f.xx);

            // finally emit vertex
            vertex.w = 1.f;
            gl_Position = vertex;
            EmitVertex();
        }
        EndPrimitive();
    }
#endif

#ifdef FSH

	vec2 fcoord = gl_FragCoord.xy/vec2(1.f,float(shadowMapResolution)); // TODO: better shadow resolution
    if (isVoxel == 1) {
        fcoord.x = (fcoord.x - 0.f) / contraSize.x;
    } else {
        fcoord.x = (fcoord.x - contraSize.x) / SHADOW_SIZE.x;
    }
    const lowp ivec2 iwep = ivec2(gl_FragCoord.xy)&1;
    const lowp int qwap = iwep.x|(iwep.y<<1);

	vec4 vpos = vec4(fcoord.xy,gl_FragCoord.z,1.f);
	vpos.xy   = fma(vpos.xy,2.f.xx,-1.f.xx);
	vpos = shadowProjectionInverse * vpos;
	vpos.xyz /= vpos.w;

	const vec2 adjtx = ftexcoord.xy*ftexcoordam.zw+ftexcoordam.xy;
    const vec4 tnormal = fnormal; // TODO: modify normals for transparents
	const vec4 tangent = ftangent;

	float fogFactor = 1.f;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0f - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
	}

	//vec4 fcolor = fcolor;
    //vec4 emission = to_linear(texture(lightmap, flmcoord.st));
    const bool isEmission = flmcoord.x>=0.90f;
    vec4 emission = isEmission ? to_linear(texture(lightmap, flmcoord.st))*1.f : 1.f.xxxx;//1.f.xxxx;
    //if (flmcoord.s > 0.9f) emission.xyz *= 20.f;

    vec4  color = to_linear(texture(tex, adjtx.st)) * emission * fcolor;
    float alpha = color.w, alpas = random(vec4(vpos.xyz,frameTimeCounter))<alpha ? 1.f : 0.f; 
	//color.xyz = mix(gl_Fog.color.xyz,color.xyz,fogFactor);

    // 
    gl_FragDepth = gl_FragCoord.z+2.f;
	gl_FragData[0] = vec4(0.f);

    // make shadow or voxel... 
    if (all(greaterThanEqual(fcoord.xy,0.f.xx)) && all(lessThan(fcoord.xy,1.f.xx))) {
		gl_FragDepth = gl_FragCoord.z; // in voxel space, used only fomally 
		//gl_FragData[0] = vec4(color.xyz,alpha);

		if (isVoxel == 1) {
            // voxel can store only 8-bit color... 
            const vec2 atlas = vec2(atlasSize)/TEXTURE_SIZE, torig = floor(adjtx.xy*atlas), tcord = fract(adjtx.xy*atlas);
            //const vec3 ap3cp = pack3x2(mat2x3(vec3(torig/atlas,0.f),vec3(1.f-color.xyz*texture(lightmap,flmcoord.st).xyz)));
			if (qwap == 0) gl_FragData[0] = vec4(1.f-fcolor.xyz*emission.xyz,1.f); // try to pack into one voxel
            if (qwap == 1) gl_FragData[0] = vec4(torig/255.f,0.f,1.f);
            if (qwap == 2) gl_FragData[0] = vec4(flmcoord.st,0.f,1.f);
		} else {
			gl_FragData[0] = vec4(color); // packing is useless 
		}
    }

#endif
}
