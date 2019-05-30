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
attribute vec4 at_tangent;
attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;
vec4 correctNormal() {
    vec4 normal = vec4(gl_NormalMatrix*gl_Normal,0.f);
    return normal*gbufferModelView;
}
#endif

// GSO input
#ifdef GSH
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;
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

	// 
	vec2 texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	vec2 midcoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord,0.0f,1.f)).st;
	vec2 texcoordminusmid = texcoord-midcoord;

	// 
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vtexcoord.st    = fma(sign(texcoordminusmid),0.5.xx,0.5.xx);

	//
	vparametric = ivec4(mc_Entity.xy,0.f.xx);
	vlmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	vcolor = gl_Color;

	// 
	vec4 worldSpace = gbufferModelViewInverse * gbufferProjectionInverse * gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
	vec4 viewSpace = gbufferModelView * worldSpace; viewSpace.xyz /= viewSpace.w;

	// 
	vnormal = correctNormal(), vtangent = vec4(at_tangent.xyz, 0.f);
	gl_Position = gbufferProjection * gbufferModelView * worldSpace;
	gl_FogFragCoord = length((gbufferModelView * worldSpace).xyz);

#endif

#ifdef GSH
#include "./Splitter.glsl" // Split-Screen Buffer Processor (for Get Noisy Transparency and Solid Substance)
#endif

#ifdef FSH

	vec2 fcoord = gl_FragCoord.xy/vec2(viewWidth,viewHeight);
    fcoord.x = fma(fcoord.x, 2.f, -float(isSemiTransparent));

	vec4 vpos = vec4(fcoord.xy,gl_FragCoord.z,1.f);
	vpos.xy   = fma(vpos.xy,2.f.xx,-1.f.xx);
	vpos = gbufferProjectionInverse * vpos;
	vpos.xyz /= vpos.w;

	const vec2 adjtx = ftexcoord.xy*ftexcoordam.zw+ftexcoordam.xy;
    const vec4 normal = fnormal;
	const vec4 tangent = ftangent;

#if defined(TERRAIN) || defined(BLOCK) || defined(WATER)
	bool facing = dot(normalize(vpos.xyz),normalize(normal.xyz))<=0.f;
#else
	bool facing = true;
#endif

	if (!facing) discard;


	const vec4 tnormal = normal; // TODO: modify normals for transparents

	float fogFactor = 1.f;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0f - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
	}

	vec4  fcolor = fcolor;
    vec4  color = texture(tex, adjtx.st) * texture(lightmap, flmcoord.st) * fcolor;
    float alpha = color.w, alpas = random(vec4(vpos.xyz,frameTimeCounter))<alpha ? 1.f : 0.f; 
	color.xyz = mix(gl_Fog.color.xyz,color.xyz,fogFactor);
	
    gl_FragDepth = gl_FragCoord.z+2.f;
	gl_FragData[0] = vec4(0.f);
	gl_FragData[1] = vec4(0.f);
	gl_FragData[2] = vec4(0.f);
	gl_FragData[3] = vec4(0.f);
	
    if (all(greaterThanEqual(fcoord.xy,0.f.xx)) && all(lessThan(fcoord.xy,1.f.xx)) && facing && alpas > 0.f) {
		gl_FragDepth = gl_FragCoord.z;
		//gl_FragData[0] = vec4(color.xyz,alpha);
#if defined(BLOCK) || defined(WATER) || defined(TERRAIN)
		const bool deferred = isSemiTransparent == 0;
#else
		const bool deferred = false;
#endif
		if (deferred) {
			fcolor *= texture(lightmap, flmcoord.st); // add lightmap into... 
			gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(adjtx,0.f),fcolor.xyz)),alpas);
			gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(flmcoord.xy,0.f),normal.xyz)),alpas);
			gl_FragData[2] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),tangent.xyz)),alpas);
			gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),alpas);
		} else {
			gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),color.xyz)),alpas);
			gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(flmcoord.xy,0.f),tnormal.xyz)),alpas);
			gl_FragData[2] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),alpas);
			gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),alpas);
		}
    }

#endif
}
