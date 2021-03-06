#include "/Globals/Header.glsl"

// From Vertex shader input
#if (defined(VSH) || defined(FSH))
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

	vec4 scrnSpace = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
	vec4 viewSpace = gbufferModelViewInverse * scrnSpace; viewSpace /= viewSpace.w;

	// 
	vnormal = correctNormal(), vtangent = vec4(at_tangent.xyz, 0.f);
	gl_Position = scrnSpace;
	gl_Position.xyz /= gl_Position.w;
	gl_Position.xy = gl_Position.xy * 0.5f + 0.5f;
	gl_Position.x = gl_Position.x * 0.5f + 0.0f;
	gl_Position.y = gl_Position.y * 0.5f + 0.0f;
	gl_Position.xy = gl_Position.xy * 2.f - 1.f;
	gl_Position.xyz *= gl_Position.w;
	gl_FogFragCoord = length(viewSpace.xyz);

#endif

#ifdef FSH

	//discard;

	vec2 fcoord = gl_FragCoord.xy/vec2(viewWidth*0.5f,viewHeight*0.5f);
	fcoord = fract(fcoord);

	vec4 vpos = vec4(fcoord.xy * 2.f - 1.f,gl_FragCoord.z,1.f);
	vpos.xy = fma(vpos.xy,2.f.xx,-1.f.xx);
	vpos = gbufferProjectionInverse * vpos;
    vpos.xyz /= vpos.w;

	bool facing = true;//dot(normalize(vpos.xyz),normalize(fnormal.xyz))<=0.f;
	//if (!facing) discard;

	const vec2 adjtx = vtexcoord.xy;//vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;


	float fogFactor = 1.f;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0f, 1.0f);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0f - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0f, 1.0f);
	}
    
#ifdef SKYTEXTURED
    vec4 color = texture(tex, adjtx.st) * texture(lightmap, vlmcoord.st) * vcolor;
#else
	vec4 color = vcolor;
#endif
	//color.xyz = mix(gl_Fog.color.xyz,color.xyz,fogFactor);

    gl_FragDepth = gl_FragCoord.z+2.f;
	gl_FragData[0] = vec4(0.f);
	gl_FragData[1] = vec4(0.f);
	gl_FragData[2] = vec4(0.f);
	gl_FragData[3] = vec4(0.f);

    float alpha = color.w, alpas = random(vec4(vpos.xyz,frameTimeCounter))<alpha ? 1.f : 0.f; 
	if ( all(greaterThanEqual(fcoord.xy,0.f.xx)) && all(lessThan(fcoord.xy,1.f.xx)) ) {
		gl_FragDepth = gl_FragCoord.z;
		gl_FragData[0] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),vcolor.xyz)),alpas);
		gl_FragData[1] = vec4(pack3x2(mat2x3(vec3(vlmcoord.xy,0.f),vnormal.xyz)),alpas);
		gl_FragData[2] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),alpas);
		gl_FragData[3] = vec4(pack3x2(mat2x3(vec3(0.f.xx,0.f),0.f.xxx)),alpas);
	}

#endif
}
