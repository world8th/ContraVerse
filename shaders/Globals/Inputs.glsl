// configs of buffers
const int shadowMapResolution = 4096;

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
const int shadowcolor0Format = RGBA32F;
const int shadowcolor1Format = RGBA32F;
*/

// reserved and used by composite and some deferred programs (but may be filled from GBuffers)
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

// hdpi depth buffers
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

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




const vec4 CameraCenterView = vec4(0.f.xxx,1.f);

vec4 CameraSpaceToModelSpace(in vec4 cameraSpace){
    vec4 modelSpaceProj = gbufferModelViewInverse*cameraSpace;
    //modelSpaceProj.xyz = fartu(modelSpaceProj.xyz);
    return modelSpaceProj/modelSpaceProj.w;
}

vec4 ModelSpaceToCameraSpace(in vec4 modelSpace){
    //modelSpace.xyz = defartu(modelSpace.xyz);
    vec4 cameraSpaceProj = gbufferModelView*modelSpace;
    return cameraSpaceProj/cameraSpaceProj.w;
}


