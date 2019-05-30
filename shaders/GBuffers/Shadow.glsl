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
vec4 correctNormal() {
    vec4 normal = vec4(gl_NormalMatrix*gl_Normal,0.f);
    return normal*gbufferModelView;
}
#endif

#define TEXTURE_SIZE 16 

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
	gl_Position = gl_ProjectionMatrix * gbufferModelView * (worldSpace + vec4(cameraPosition,0.f));
	gl_FogFragCoord = length(viewSpace.xyz);

#endif

#ifdef GSH

    isVoxel = 0;

    // 
    mat3 vertices = mat3(0.f.xxx,0.f.xxx,0.f.xxx);
    vec3 normal = 0.f.xxx;
    for (int i = 0; i < 3; i++) {
        fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];

        // get world space vertex
        vec4 vertex = gl_in[i].gl_Position;
        vertex = gbufferModelViewInverse * gbufferProjectionInverse * vertex;
        vertex.xyz /= vertex.w;
        vertices[i] = vertex.xyz;
        //vertex.xyz += cameraPosition;

        // 
        normal += fnormal.xyz;

        // integrity normal 
        fnormal *= gbufferModelViewInverse, ftangent *= gbufferModelViewInverse;

        // project into screen
        //vertex.xyz -= cameraPosition;

        // 
        vertex = gbufferProjection * gbufferModelView * vertex;
        vertex.xyz /= vertex.w;

        // resolution correction
        vertex.xy = fma(vertex.xy, 0.5f.xx, 0.5f.xx);

        // assign screen space coordinates
        //fscreencoord = vertex;

        // TODO: shadow-space render-side
        vertex.x = fma(vertex.x, SHADOW_SIZE_RATE, SHADOW_SHIFT);

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
    vec3 normalOfTriangle = NormalOfTriangle(vertices);
    vec3 offsetOfVoxel = CalcVoxelOfBlock(centerOfTriangle,normalOfTriangle);
    if (FilterForVoxel(offsetOfVoxel, normalOfTriangle)) validVoxel = true;
    vec3 tileSpaceBlock = VoxelToTileSpace(offsetOfVoxel);

    // 
    if (validVoxel) {
        for (int i = 0; i < 3; i++) {
            fcolor = vcolor[i], ftexcoord = vtexcoord[i], ftexcoordam = vtexcoordam[i], flmcoord = vlmcoord[i], fparametric = vparametric[i], fnormal = vnormal[i], ftangent = vtangent[i];

            // get world space vertex
            vec4 vertex = gl_in[i].gl_Position;
            vertex = gbufferModelViewInverse * gbufferProjectionInverse * vertex;
            vertex.xyz /= vertex.w;

            // convert into voxel and texture space (simple way)
            vertex.xyz -= offsetOfVoxel; // get coordinate relate of voxel 
            vertex.xyz += VoxelToTileSpace(offsetOfVoxel); // get voxel coordinate relate of tile-space
            vertex.xyz = vec3(VoxelToTextureSpace(vertex).xyz); // get voxel re-coordination into texture space

            // integrity normal 
            fnormal *= gbufferModelViewInverse, ftangent *= gbufferModelViewInverse;

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

	vec2 fcoord = gl_FragCoord.xy/vec2(shadowMapResolution); // TODO: better shadow resolution
    fcoord.x = fma(fcoord.x, 1.f/(isVoxel == 1 ? aeraSize.x : SHADOW_SIZE), -(isVoxel == 0 ? SHADOW_SHIFT : 0.f));

	vec4 vpos = vec4(fcoord.xy,gl_FragCoord.z,1.f);
	vpos.xy   = fma(vpos.xy,2.f.xx,-1.f.xx);
	vpos = gbufferProjectionInverse * vpos;
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
    vec4  color = texture(tex, adjtx.st) * texture(lightmap, flmcoord.st) * fcolor;
    float alpha = color.w, alpas = random(vec4(vpos.xyz,frameTimeCounter))<alpha ? 1.f : 0.f; 
	color.xyz = mix(gl_Fog.color.xyz,color.xyz,fogFactor);
	
    // 
    gl_FragDepth = gl_FragCoord.z+2.f;
	gl_FragData[0] = vec4(0.f);
	
    // make shadow or voxel... 
    if (all(greaterThanEqual(fcoord.xy,0.f.xx)) && all(lessThan(fcoord.xy,1.f.xx))) {
		gl_FragDepth = gl_FragCoord.z; // in voxel space, used only fomally 
		//gl_FragData[0] = vec4(color.xyz,alpha);
#if defined(BLOCK) || defined(WATER) || defined(TERRAIN)
		const bool deferred = isSemiTransparent == 0;
#else
		const bool deferred = false;
#endif
		if (isVoxel) {
            // voxel can store only 8-bit color... 
            const vec2 tile = vec2(atlasSize.xy)/TEXTURE_SIZE.xx, ftex = adjtx.xy*tile, ftxt = floor(ftex);
            const float vxcolr = uintBitsToFloat(packUnorm4x8(vec4(fcolor.xyz*texture(lightmap,flmcoord.st).xyz,0.f))); // TODO: better pre-baked emission support
            const float vxmisc = uintBitsToFloat(packUnorm4x8(vec4(0.f.xx,ftxt/tile))); // first 16-bit uint's BROKEN
            const float vxdata = uintBitsToFloat(packUnorm2x16(fparametric.xy/65535.f)); // cheaper packing (for code)
			gl_FragData[0] = vec4(vxcolr,vxmisc,vxdata,1.f); // try to pack into one voxel 
		} else {
			gl_FragData[0] = vec4(color); // packing is useless 
		}
    }

#endif
}
