//#define ENABLE_NANO_VRT
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
gin vec4 fposition;
flat gin ivec4 fparametric;
flat gin int isSemiTransparent;
flat gin int isPlanarReflection;
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

// 
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
layout(triangle_strip, max_vertices = 12) out;
#endif

// FTU input 
#ifdef FSH
uniform sampler2D tex;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform ivec2 atlasSize;
#ifndef TEXTURE_SIZE
#define TEXTURE_SIZE 16
#endif
/* DRAWBUFFERS:4567 */
#endif


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
	vec4 viewSpace = gbufferProjectionInverse * scrnSpace; viewSpace.xyz /= viewSpace.w;

	// 
	vnormal = correctNormal(), vtangent = vec4(at_tangent.xyz, 0.f);
	gl_Position = scrnSpace;
	gl_FogFragCoord = length(viewSpace.xyz);

#endif

#ifdef GSH // Split-Screen Buffer Processor (for Get Noisy Transparency and Solid Substance)
#include "./Splitter.glsl" 
#endif

#ifdef FSH

	vec2 fcoord = gl_FragCoord.xy/vec2(1.f,1.f);///vec2(viewWidth,viewHeight);

	// is transparency space?
	if (isSemiTransparent == 1) {
		fcoord.x = (fcoord.x-(viewWidth*0.5f))/(viewWidth*0.5f);
	} else {
		fcoord.x = fcoord.x/(viewWidth*0.5f);
	}

	// is reflected space?
	if (isPlanarReflection == 1) {
		fcoord.y = (fcoord.y-(viewHeight*0.5f))/(viewHeight*0.5f);
	} else {
		fcoord.y = fcoord.y/(viewHeight*0.5f);
	}


	vec4 vpos = vec4(fcoord.xy,gl_FragCoord.z,1.f);
	vpos.xy   = fma(vpos.xy,2.f.xx,-1.f.xx);
	vpos = gbufferProjectionInverse * vpos;
	vpos.xyz /= vpos.w;

	const vec2 adjtx = ftexcoord.xy*ftexcoordam.zw+ftexcoordam.xy;
    const vec4 tnormal = fnormal; // TODO: modify normals for transparents
	const vec4 tangent = ftangent;

	// TBN
	const vec3 pbrspc =                texture(specular, adjtx.st).xyz;
	const vec3 hemisphere = randomHemisphereCosine(vec3(fcoord.xy*vec2(viewWidth,viewHeight),frameTimeCounter));

	mat3 tbn = mat3(normalize(tangent.xyz),normalize(cross(tnormal.xyz,tangent.xyz)),normalize(tnormal.xyz));
	vec3 tbnorm = normalize(tbn*(texture(normals , adjtx.st).xyz*2.f-1.f));
	tbn[2] = tbnorm, tbn[1] = normalize(cross(tbn[2],tbn[0]));
	//tbnorm = normalize(tbn*hemisphere);

	// Yob'Apple Face ID
#if defined(TERRAIN) || defined(BLOCK) || defined(WATER)
	const bool facing = dot(normalize(vpos.xyz),normalize(tnormal.xyz))<=0.f;
#else
	const bool facing = true;
#endif
	if (!facing) discard;

	// 
	float fogFactor = 1.f;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0f - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
	}

	// Color: Putler Edition 
	//vec4 emission = 1.f.xxxx;//to_linear(texture(lightmap, flmcoord.st));
	const bool isEmission = flmcoord.x>=0.90f;
	vec4 emission = isEmission ? to_linear(texture(lightmap, flmcoord.st))*2.f : 1.f.xxxx;
	vec4 color = to_linear(texture(tex, adjtx.st)) * emission * fcolor;

	//if (flmcoord.s > 0.0f) emission.xyz *= 1.f + 19.f*(flmcoord.s*(1.f-flmcoord.t));
	//if (flmcoord.s > 0.9f) emission.xyz *= 20.f;

	//color.xyz *= color.w;
	color.w = sqrt(color.w);
	color.xyz *= color.w;
	//color.xyz /= color.w;

	//color.xyz /= color.w; // un-multiply alpha 
	//color.xyz = mix(gl_Fog.color.xyz,color.xyz,fogFactor);

	// Лэпшэ Нэвэльного! Govno Putlera! 
    const float alpha = color.w, alpas = random(vec4(vpos.xyz,frameTimeCounter))<alpha ? 1.f : 0.f;


    gl_FragDepth = gl_FragCoord.z+2.f;
	gl_FragData[0] = vec4(0.f);
	gl_FragData[1] = vec4(0.f);
	gl_FragData[2] = vec4(0.f);
	gl_FragData[3] = vec4(0.f);

	// Russi Hohlo Nazi Swastika Edition!
    if (all(greaterThanEqual(fcoord.xy,0.f.xx)) && all(lessThan(fcoord.xy,1.f.xx)) && facing && alpas > 0.f) {
		gl_FragDepth = gl_FragCoord.z;
		//gl_FragData[0] = vec4(color.xyz,alpha);
#if defined(WATER) || defined(TERRAIN)
		const bool deferred = isSemiTransparent == 0;
#else
		const bool deferred = false;
#endif

		if (isPlanarReflection != 1 || ceil(fposition.y-0.01f) >= ceil(fposition.w-0.01f)+0.01f) {
			if (deferred) {
				const vec2 atlas = vec2(atlasSize)/TEXTURE_SIZE, torig = floor(adjtx.xy*atlas), tcord = fract(adjtx.xy*atlas); // Holy Star Wars!
				gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(tcord.xy,0.f),fcolor.xyz*emission.xyz)),alpas);
				gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(flmcoord.xy,0.f),tnormal.xyz*0.5f+0.5f)),alpas);
				gl_FragData[2] = vec4(pack3x2(mat2x3(vec3(torig.xy/atlas,0.f),tangent.xyz*0.5f+0.5f)),alpas);
				gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),0.f);
				//gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),alpas);
			} else {
				gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),color.xyz)),alpas);
				gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(flmcoord.xy,0.f),tnormal.xyz*0.5f+0.5f)),alpas);
				gl_FragData[2] = vec4(pack3x2(mat2x3(vec3(pbrspc.yz,0.f),tbnorm.xyz*0.5f+0.5f)),alpas);
				gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),0.f);
			};

			//const vec4 wnormal = gbufferModelViewInverse*vec4(tnormal.xyz,0.f);
			//if (dot(normalize(wnormal.xyz),vec3(0.f,1.f,0.f))>0.99f && isPlanarReflection != 1 && isSemiTransparent != 1) {
			//	gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),vec3(fposition.xyz))),alpas);
			//};
		};
    }

#endif
}
