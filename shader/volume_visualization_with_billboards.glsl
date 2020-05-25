#include "per_frame_resources.glsl"
#include "simulation/hybrid_fluid.glsl"
#include "sphere_particles.glsl"
#include "utilities.glsl"
#include "visualization.glsl"

out gl_PerVertex { vec4 gl_Position; };

layout(location = 0) out vec3 out_WorldPosition;
layout(location = 1) out vec3 out_ParticleWorldPosition;
layout(location = 2) out vec3 out_Tint;
layout(location = 3) out float out_Radius;

void main() {
    ivec3 volumeCoordinate = getVolumeCoordinate(gl_InstanceIndex);
    uint marker = texelFetch(MarkerVolume, volumeCoordinate, 0).x;

#if defined(VISUALIZE_DIVERGENCE)
    // uncorrected divergence
    float divergence = texelFetch(DivergenceVolume, volumeCoordinate, 0).x;

    // corrected divergence
    // float divergence = 0.0;
    // vec4 currentCellStaggeredVelocities = texelFetch(VelocityVolume, volumeCoordinate, 0);
    // [[dont_flatten]] if (currentCellStaggeredVelocities.w == CELL_FLUID) {
    //     divergence += currentCellStaggeredVelocities.x - texelFetch(VelocityVolume, volumeCoordinate - ivec3(1, 0, 0), 0).x;
    //     divergence += currentCellStaggeredVelocities.y - texelFetch(VelocityVolume, volumeCoordinate - ivec3(0, 1, 0), 0).y;
    //     divergence += currentCellStaggeredVelocities.z - texelFetch(VelocityVolume, volumeCoordinate - ivec3(0, 0, 1), 0).z;
    // }

    // We don't clear divergence, so if there's not fluid, it has not valid value.
    if (marker != CELL_FLUID)
        divergence = 0.0;

    float scale = clamp(divergence * 10.0, -1.0, 1.0);
    out_Tint = colormapCoolToWarm(scale);
    scale = abs(scale);
#elif defined(VISUALIZE_PRESSURE)
    float pressure = marker == CELL_FLUID ? texelFetch(PressureVolume, volumeCoordinate, 0).x : 0.0;
    float scale = saturate(pressure * pressure * 0.05);
    out_Tint = colormapHeat(scale).grb;
#elif defined(VISUALIZE_MARKER)
    float scale = marker == CELL_AIR ? 0.0 : 1.0;
    out_Tint = marker == CELL_FLUID ? vec3(0.5, 0.5, 1.0) : vec3(0.0);
#endif

    out_ParticleWorldPosition = volumeCoordinate + vec3(0.5);
    out_Radius = scale * 0.5;
    out_WorldPosition = spanParticle(out_ParticleWorldPosition, out_Radius);
    gl_Position = Camera.ViewProjection * vec4(out_WorldPosition, 1.0);
}
