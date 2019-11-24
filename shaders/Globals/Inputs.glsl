// configs of buffers
const int shadowMapResolution = 8192;

// hdpi depth buffers
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#if defined(FSH) && defined(COMPOSITE)
/*

// Inputs 
const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGBA32F;
const int colortex5Format = RGBA32F;
const int colortex6Format = RGBA32F;
const int colortex7Format = RGBA32F;
const bool colortex0Clear = true;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
const bool shadowcolor0Clear = false;
const bool shadowcolor1Clear = false;

// Depth 
const int depthtex0Format = R32F;
const int depthtex1Format = R32F;

// Shadow
const int shadowtex0Format = R32F;
const int shadowtex1Format = R32F;
const int shadowcolor0Format = RGBA8;
const int shadowcolor1Format = RGBA8;
*/

// reserved and used by composite and some deferred programs (but may be filled from GBuffers)
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

// used by GBuffers, deferred and some sort of composite ()
uniform sampler2D colortex4; // colortex4
uniform sampler2D colortex5; // colortex5
uniform sampler2D colortex6; // colortex6
uniform sampler2D colortex7; // colortex7
#define gbuffers0 colortex4
#define gbuffers1 colortex5
#define gbuffers2 colortex6
#define gbuffers3 colortex7

// shadows
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

// ...
#endif

#ifdef ENABLE_NANO_VRT
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
#endif


// 
#ifdef GBUFFERS
/* GAUX1FORMAT:RGBA32F */
/* GAUX2FORMAT:RGBA32F */
/* GAUX3FORMAT:RGBA32F */
/* GAUX4FORMAT:RGBA32F */

/*
const int gaux1Format = RGBA32F;
const int gaux2Format = RGBA32F;
const int gaux3Format = RGBA32F;
const int gaux4Format = RGBA32F;
*/

uniform sampler2D gaux1; // colortex4
uniform sampler2D gaux2; // colortex5
uniform sampler2D gaux3; // colortex6
uniform sampler2D gaux4; // colortex7
#define gbuffers0 gaux1
#define gbuffers1 gaux2
#define gbuffers2 gaux3
#define gbuffers3 gaux4
#endif


// naming aliasing for these gbuffers
#define GBuffersAlbedoAndLightingBuffer gbuffers0
#define GBuffersPBRAndNormalsBuffer     gbuffers1
#define GBuffersMiscBuffer              gbuffers2
#define GBuffersShadingBuffer           gbuffers3

// naming aliasing for these composite buffers
#define ProcessingColor                 colortex0
#define ReflectionColor                 colortex1



// uniform 
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousModelViewInverse;

uniform float centerDepth;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform int fogMode;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform int worldTime;

//uniform vec3 sunAngle;

const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;



vec4 ScreenSpaceToCameraSpace(in vec4 screenSpace){
    const vec4 cameraSpaceProj = gbufferProjectionInverse * screenSpace;
    return cameraSpaceProj/cameraSpaceProj.w;
}

vec4 CameraSpaceToScreenSpace(in vec4 cameraSpace){
    const vec4 screenSpaceProj = gbufferProjection * cameraSpace;
    return screenSpaceProj/screenSpaceProj.w;
}



vec3 fartu(in vec3 relSpace) {
    return (relSpace.xyz+cameraPosition.xyz)-floor(cameraPosition.xyz);
}

vec3 defartu(in vec3 fartuSpace) {
    return (fartuSpace+floor(cameraPosition.xyz))-cameraPosition.xyz;
}



vec3 to_sRGB(in vec3 linear){
    return pow(linear,1.f/2.2f.xxx);
}

vec3 to_linear(in vec3 sRGB){
    return pow(sRGB,2.2f.xxx);
}

vec4 to_sRGB(in vec4 linear){
    return vec4(to_sRGB(linear.xyz),linear.w);
}

vec4 to_linear(in vec4 sRGB){
    return vec4(to_linear(sRGB.xyz),sRGB.w);
}



const vec4 CameraCenterView = vec4(0.f.xxx,1.f);

vec4 CameraSpaceToModelSpace(in vec4 cameraSpace){
    vec4 modelSpaceProj = gbufferModelViewInverse*cameraSpace;
    modelSpaceProj /= modelSpaceProj.w, modelSpaceProj.xyz *= 0.5f;
    return modelSpaceProj/modelSpaceProj.w;
}

vec4 ModelSpaceToCameraSpace(in vec4 modelSpace){
    vec4 cameraSpaceProj = gbufferModelView*vec4(modelSpace.xyz*2.f,modelSpace.w);
    return cameraSpaceProj/cameraSpaceProj.w;
}


vec4 ShadowSpaceToModelSpace(in vec4 shadowSpace){
    vec4 modelSpaceProj = shadowModelViewInverse*shadowProjectionInverse*shadowSpace;
    return modelSpaceProj/modelSpaceProj.w;
}

vec4 ModelSpaceToShadowSpace(in vec4 modelSpace){
    vec4 shadowSpaceProj = shadowProjection*shadowModelView*modelSpace;
    return shadowSpaceProj/shadowSpaceProj.w;
}

#if defined(FSH) && defined(COMPOSITE)
float linShadow(in vec2 txy) {
    const vec4 txl = textureGather(shadowtex0,txy,0);
    const vec2 ttf = fract(txy*textureSize(shadowtex0,0)-0.5f);
    const vec2 px = vec2(1.f-ttf.x,ttf.x), py = vec2(1.f-ttf.y,ttf.y);
    const mat2x2 i2 = outerProduct(px,py);
    return dot(txl,vec4(i2[0],i2[1]).zwyx); // interpolate
}
#endif
