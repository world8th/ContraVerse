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
flat gin int isSemiTransparent;
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
in vec4 at_tangent;
in vec4 mc_Entity;
in vec4 mc_midTexCoord;
vec4 correctNormal() {
    vec4 normal = vec4(gl_NormalMatrix*gl_Normal,0.f);
    return normal*gbufferModelView;
}
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
/* DRAWBUFFERS:4567 */
#endif


// 
void main() {
#ifdef VSH

	vtexcoordam = 0.f.xxxx;
	vtexcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	vlmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	vcolor = gl_Color;

	vec4 worldSpace = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec4 viewSpace = gbufferModelView * worldSpace;
	worldSpace.xyz += cameraPosition; // correction into world space 

	// 
	vnormal = correctNormal(), vtangent = vec4(at_tangent.xyz, 0.f);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * (worldSpace - vec4(cameraPosition,0.f));
	gl_FogFragCoord = length(viewSpace.xyz);

#endif

#ifdef GSH
#include "./Splitter.glsl" // Split-Screen Buffer Processor (for Get Noisy Transparency and Solid Substance)
#endif

#ifdef FSH

	discard;

	vec2 fcoord = gl_FragCoord.xy/vec2(viewWidth,viewHeight);
	fcoord.x = fma(fcoord.x, 2.f, 0.f);

	vec4 vpos = vec4(fcoord.xy,gl_FragCoord.z,1.f);
	vpos.xy = fma(vpos.xy,2.f.xx,-1.f.xx);
	vpos = gbufferProjectionInverse * vpos;
    vpos.xyz /= vpos.w;

	bool facing = true;//dot(normalize(vpos.xyz),normalize(fnormal.xyz))<=0.f;
	//if (!facing) discard;

	const vec2 adjtx = ftexcoord.xy;//vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;


	float fogFactor = 1.f;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0f - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
	}
    

	gl_FragDepth = 2.1f;
#ifdef SKYTEXTURED
    vec4 color = texture(tex, adjtx.st) * texture(lightmap, flmcoord.st) * fcolor;
#else
	vec4 color = fcolor;
#endif
	color.xyz = mix(gl_Fog.color.xyz,color.xyz,fogFactor);

    float alpha = color.w, alpas = random(vpos.xyz)<alpha ? 1.f : 0.f; 
	if ( all(greaterThanEqual(fcoord.xy,0.f.xx)) && all(lessThan(fcoord.xy,1.f.xx)) ) {
		gl_FragDepth = gl_FragCoord.z + 1.f;
        gl_FragData[0] = vec4(pack3x2(mat2x3(color.xyz,color.xyz)),alpas);
		gl_FragData[1] = vec4(0.f,0.f.xx,1.f);
		gl_FragData[2] = vec4(fnormal.xyz,1.f);
	}

#endif
}
