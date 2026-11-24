shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float melt_progress : hint_range(0.0, 1.0) = 0.0;
uniform bool frost_layer = false;
uniform bool opaque_surface = false;
uniform vec4 uv_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform sampler2D shelf_texture : filter_linear, repeat_disable;
uniform bool shelf_occlusion_enabled = false;
uniform vec3 shelf_uv_x = vec3(0.0);
uniform vec3 shelf_uv_y = vec3(0.0);
uniform vec3 second_shelf_uv_x = vec3(0.0);
uniform vec3 second_shelf_uv_y = vec3(0.0);
uniform float shelf_alpha = 0.0;
uniform float second_shelf_alpha = 0.0;
varying vec4 surface_tint;
varying vec2 world_position;

float hash_value(float seed) {
    return fract(sin(seed * 127.1 + 311.7) * 43758.5453);
}

float edge_noise(float coordinate) {
    float cell = floor(coordinate);
    float fraction = fract(coordinate);
    float blend = fraction * fraction * (3.0 - 2.0 * fraction);
    return mix(hash_value(cell), hash_value(cell + 1.0), blend);
}

float melt_ripple(float horizontal_position) {
    return (edge_noise(horizontal_position * 3.8) - 0.5) * 0.12
        + (edge_noise(horizontal_position * 8.6 + 3.7) - 0.5) * 0.05;
}

float melt_travel(float progress) {
    float phase = clamp(progress, 0.0, 1.0);
    return mix(phase, smoothstep(0.0, 1.0, phase), 0.35);
}

void vertex() {
    surface_tint = COLOR;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float shelf_occlusion(vec3 axis_x, vec3 axis_y, float alpha) {
    vec3 sample_position = vec3(world_position, 1.0);
    vec2 shelf_uv = vec2(dot(axis_x, sample_position), dot(axis_y, sample_position));
    if (any(lessThan(shelf_uv, vec2(0.0))) || any(greaterThan(shelf_uv, vec2(1.0)))) {
        return 0.0;
    }
    return texture(shelf_texture, shelf_uv).a * alpha;
}

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    vec2 local_uv = clamp((UV - uv_region.xy) / uv_region.zw, vec2(0.0), vec2(1.0));
    float progress = melt_travel(frost_layer ? melt_progress / 0.30 : melt_progress);
    float melt_order = clamp(0.08 + local_uv.y * 0.84 + melt_ripple(local_uv.x),
        0.016, 0.984);
    float remaining = smoothstep(progress - 0.014, progress + 0.014, melt_order);
    float wet_edge = (1.0 - smoothstep(0.0, 0.026, abs(melt_order - progress)))
        * remaining * smoothstep(0.0, 0.08, progress)
        * (1.0 - smoothstep(0.85, 1.0, progress));
    float edge_strength = frost_layer ? 0.10 : 0.28;
    vec3 ice_color = mix(source.rgb, vec3(0.91, 0.98, 1.0), wet_edge * edge_strength);
    float ice_alpha = source.a * remaining;
    if (!frost_layer && progress > 0.0 && progress < 1.0) {
        float face_depth = (melt_order - progress) / 0.84;
        float face_height = 0.10;
        float face_phase = clamp((face_depth + face_height) / face_height, 0.0, 1.0);
        float top_face = smoothstep(-face_height - 0.006, -face_height + 0.006, face_depth)
            * (1.0 - smoothstep(-0.004, 0.006, face_depth));
        float rear_rim = (1.0 - smoothstep(0.0, 0.012, abs(face_depth + face_height)))
            * top_face;
        float front_rim = (1.0 - smoothstep(0.0, 0.012, abs(face_depth))) * top_face;
        float lower_lip = smoothstep(-0.003, 0.005, face_depth)
            * (1.0 - smoothstep(0.012, 0.025, face_depth));
        float surface_presence = smoothstep(0.0, 0.08, progress)
            * (1.0 - smoothstep(0.88, 1.0, progress));
        float silhouette = smoothstep(0.04, 0.45, source.a);
        vec2 top_uv = uv_region.xy
            + vec2(local_uv.x, mix(0.015, 0.10, face_phase)) * uv_region.zw;
        vec3 top_color = mix(texture(TEXTURE, top_uv).rgb,
            mix(vec3(0.86, 0.97, 1.0), vec3(0.43, 0.79, 0.92), face_phase), 0.55);
        top_color = mix(top_color, vec3(0.96, 0.995, 1.0), rear_rim * 0.85);
        top_color = mix(top_color, vec3(0.20, 0.62, 0.79), front_rim * 0.65);
        ice_color = mix(ice_color, vec3(0.21, 0.64, 0.79),
            lower_lip * surface_presence * remaining * 0.42);
        float top_alpha = top_face * silhouette * (opaque_surface ? 1.0 : surface_presence * 0.88);
        float combined_alpha = top_alpha + ice_alpha * (1.0 - top_alpha);
        ice_color = (top_color * top_alpha + ice_color * ice_alpha * (1.0 - top_alpha))
            / max(combined_alpha, 0.00001);
        ice_alpha = combined_alpha;
    }
    if (progress <= 0.0) {
        remaining = 1.0;
        ice_color = source.rgb;
        ice_alpha = source.a;
    } else if (progress >= 1.0) {
        remaining = 0.0;
        ice_alpha = 0.0;
    }
    COLOR = vec4(ice_color * surface_tint.rgb, ice_alpha * surface_tint.a);
    if (shelf_occlusion_enabled) {
        float occlusion = max(shelf_occlusion(shelf_uv_x, shelf_uv_y, shelf_alpha),
            shelf_occlusion(second_shelf_uv_x, second_shelf_uv_y, second_shelf_alpha));
        COLOR.a *= 1.0 - occlusion;
    }
}
