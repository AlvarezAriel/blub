#include "per_frame_resources.glsl"
#include "utilities.glsl"

layout(set = 1, binding = 0) uniform BackgroundAndLighting {
    vec3 DirectionalLightDirection;
    vec3 DirectionalLightRadiance;
};
layout(set = 1, binding = 1) uniform textureCube CubemapRgbe;

vec3 decodeRGBE(vec4 hdr) { return hdr.rgb * exp2((hdr.a * 255.0) - 128.0); }

vec3 sampleHdrCubemap(vec3 dir) {
    vec4 rgbe = texture(samplerCube(CubemapRgbe, SamplerTrilinearClamp), dir);
    return decodeRGBE(rgbe);
}

// Box filtered lines, by Inigo Quilez via https://www.shadertoy.com/view/XdBGzd
// slightly improved to get lines centered around 0/1 instead of having them next to it
float gridTextureGradBox(in vec2 p, in vec2 ddx, in vec2 ddy, float N) {
    p += vec2(0.5 / N);
    vec2 w = max(abs(ddx), abs(ddy)) + 0.01;
    vec2 a = p + 0.5 * w;
    vec2 b = p - 0.5 * w;
    vec2 i = (floor(a) + min(fract(a) * N, 1.0) - floor(b) - min(fract(b) * N, 1.0)) / (N * w);
    return (1.0 - i.x) * (1.0 - i.y);
}

vec3 sampleBackground(vec3 position, vec3 dir) {
    float d = -(position.y / dir.y);
    if (d > 0.0) {
        vec3 planePos = position + dir * d;
        const float planeSize = 10.0;
        if (planePos.x < planeSize && planePos.x > -planeSize && planePos.z < planeSize && planePos.z > -planeSize) {
            vec3 albedo = vec3(0.8);

#if FRAGMENT_SHADER
            vec2 planePosDdx = dFdx(planePos.xz);
            vec2 planePosDdy = dFdy(planePos.xz);
#else
            vec2 planePosDdx = vec2(0.0);
            vec2 planePosDdy = vec2(0.0);
#endif
            albedo = mix(vec3(0.6), albedo, gridTextureGradBox(planePos.xz * 10, planePosDdx * 10, planePosDdy * 10, 50));
            albedo = mix(vec3(0.2), albedo, gridTextureGradBox(planePos.xz, planePosDdx, planePosDdy, 80));

            return albedo * DirectionalLightRadiance * -DirectionalLightDirection.y;
        }
    }

    return sampleHdrCubemap(dir);
}
