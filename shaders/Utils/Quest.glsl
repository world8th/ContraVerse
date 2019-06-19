// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( in uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

// Compound versions of the hashing algorithm I whipped together.
uint hash( in uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( in uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( in uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }

// Construct a float with half-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( in uint m ) {
    return fract(uintBitsToFloat((m&0x007FFFFFu)|0x3F800000u)-1.0f);
}

highp vec2 halfConstruct ( in uint m ) { return fract(unpackHalf2x16((m & 0x03FF03FFu) | (0x3C003C00u))-1.f); };

// Pseudo-random value in half-open range [0:1].
float random( in float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( in vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( in vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( in vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }


vec3 randomHemisphereCosine(in vec3 seeds) {
    const vec2 hmsm = vec2(halfConstruct(hash(floatBitsToUint(seeds))));
    const float phi = hmsm.x * 2.f * 3.141592f, up = sqrt(1.0f - hmsm.y), over = sqrt(fma(up,-up,1.f));
    return vec3(cos(phi)*over, up, sin(phi)*over);
}
