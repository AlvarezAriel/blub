#include "fluid_render_info.glsl"
#include "per_frame_resources.glsl"
#include "simulation/hybrid_fluid.glsl"
#include "sphere_particles.glsl"
#include "utilities.glsl"

out gl_PerVertex { vec4 gl_Position; };

layout(location = 0) out vec3 out_WorldPosition;
layout(location = 1) out vec3 out_ParticleWorldPosition;
layout(location = 2) out vec3 out_Tint;
layout(location = 3) out float out_Radius;

float computeDivergenceForDirection(ivec3 coord, texture3D velocityVolume, uint oppositeWallType, const uint component) {
    ivec3 neighborCoord = coord;
    neighborCoord[component] -= 1;

    if (oppositeWallType == CELL_FLUID)
        return texelFetch(velocityVolume, coord, 0).x - texelFetch(velocityVolume, neighborCoord, 0).x;
    else if (oppositeWallType == CELL_SOLID)
        return texelFetch(velocityVolume, coord, 0).x;
    else
        return 0.0;
}

void main() {
    ivec3 volumeCoordinate = getVolumeCoordinate(gl_InstanceIndex);
    uint marker = texelFetch(MarkerVolume, volumeCoordinate, 0).x;

#if defined(VISUALIZE_DIVERGENCE)
    float divergence = 0.0;
    if (marker == CELL_FLUID) {
        uint markerX0 = texelFetch(MarkerVolume, volumeCoordinate - ivec3(1, 0, 0), 0).x;
        divergence += computeDivergenceForDirection(volumeCoordinate, VelocityVolumeX, markerX0, 0);
        uint markerY0 = texelFetch(MarkerVolume, volumeCoordinate - ivec3(0, 1, 0), 0).x;
        divergence += computeDivergenceForDirection(volumeCoordinate, VelocityVolumeY, markerY0, 1);
        uint markerZ0 = texelFetch(MarkerVolume, volumeCoordinate - ivec3(0, 0, 1), 0).x;
        divergence += computeDivergenceForDirection(volumeCoordinate, VelocityVolumeZ, markerZ0, 2);
    }

    float scale = clamp(divergence * 10.0 * Rendering.FluidGridToWorldScale, -1.0, 1.0);
    out_Tint = colormapCoolToWarm(scale);
    scale = abs(scale);
#elif defined(VISUALIZE_PRESSURE)
    float pressure = marker == CELL_FLUID ? texelFetch(PressureVolume, volumeCoordinate, 0).x : 0.0;
    float scale = saturate(pressure * pressure * Rendering.FluidGridToWorldScale * 0.01);
    out_Tint = colormapHeat(scale).grb;
#elif defined(VISUALIZE_MARKER)
    float scale = marker == CELL_AIR ? 0.0 : 1.0;

    if (marker == CELL_SOLID)
        out_Tint = vec3(0.0, 0.0, 0.0);
    else if (marker == CELL_FLUID)
        out_Tint = vec3(0.0, 0.0, 1.0);
    // else if (marker == CELL_SOLID_EXTRAPOLATED)
    //     out_Tint = vec3(0.1, 0.1, 0.2);
    // else if (marker == CELL_AIR_EXTRAPOLATED)
    //     out_Tint = vec3(0.5, 0.5, 1.0);
    else
        out_Tint = vec3(0.0);
#endif

    out_ParticleWorldPosition = (volumeCoordinate + vec3(0.5)) * Rendering.FluidGridToWorldScale + Rendering.FluidWorldOrigin;
    out_Radius = scale * 0.5 * Rendering.FluidGridToWorldScale;
    out_WorldPosition = spanParticle(out_ParticleWorldPosition, out_Radius);
    gl_Position = Camera.ViewProjection * vec4(out_WorldPosition, 1.0);
}
