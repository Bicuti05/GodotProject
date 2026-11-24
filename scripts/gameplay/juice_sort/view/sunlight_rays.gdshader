shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D halo_back_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D halo_main_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D halo_upper_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D halo_radial_texture : source_color, filter_linear, repeat_disable;
uniform vec2 area_size = vec2(720.0, 1560.0);
uniform float clock = 0.0;
uniform float envelope = 0.0;
uniform float reveal_duration = 0.68;
uniform float fade_start = 2.52;
uniform float fade_end = 3.40;
uniform bool light_enabled = true;
uniform bool drops_enabled = true;
uniform int drop_count : hint_range(0, 8) = 6;
uniform float drop_size : hint_range(0.4, 1.5) = 1.5;
uniform int ice_count = 0;
uniform vec2 ice_origins[8];
uniform vec4 ice_axes[8];
uniform float melt_delay = 0.38;
uniform float melt_duration = 1.68;
uniform bool melt_enabled = true;
varying vec4 surface_tint;

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

float melt_front(float horizontal_position, float progress) {
    return clamp((melt_travel(progress) - 0.08 - melt_ripple(horizontal_position))
        / 0.84, 0.0, 1.0);
}

float light_arrival(vec2 point) {
    float distance_phase = pow(clamp((point.y + 16.0) / 1024.0, 0.0, 1.0), 0.72);
    float ray_direction = (point.x - 154.0) / max(point.y + 220.0, 220.0);
    float ray_wave = 0.5 + 0.32 * sin(ray_direction * 9.0 + 0.7)
        + 0.18 * sin(ray_direction * 19.0 + 0.5);
    float onset = 0.035 + distance_phase * 0.36 + ray_wave * 0.08;
    float phase = clamp(clock / max(reveal_duration, 0.00001), 0.0, 1.0);
    return smoothstep(onset, onset + 0.34 + distance_phase * 0.16, phase);
}

vec4 composite_over(vec4 background, vec4 foreground) {
    float opacity = foreground.a + background.a * (1.0 - foreground.a);
    vec3 color = foreground.rgb * foreground.a
        + background.rgb * background.a * (1.0 - foreground.a);
    return vec4(color / max(opacity, 0.00001), opacity);
}

vec4 collected_halo(vec2 point, int layer) {
    vec2 anchor = vec2(256.0, -96.0);
    vec2 image_size = vec2(640.0, 600.0) * 1.12;
    vec2 texture_origin = vec2(0.5, 0.0);
    float rotation = radians(-1.1);
    float rotation_rate = radians(4.05);
    float opacity_scale = 0.50;
    if (layer == 1) {
        anchor = vec2(270.0, -73.0);
        image_size = vec2(640.0, 900.0);
        rotation = 0.0;
        rotation_rate = radians(2.85);
        opacity_scale = 0.78;
    } else if (layer == 2) {
        anchor = vec2(284.0, -81.0);
        image_size = vec2(640.0, 330.0);
        rotation = radians(1.4);
        rotation_rate = radians(-4.95);
        opacity_scale = 0.72;
    } else if (layer == 3) {
        anchor = vec2(270.0, -73.0);
        image_size = vec2(969.0, 964.0) * 1.50;
        texture_origin = vec2(0.530764, 0.530660);
        rotation = 0.0;
        rotation_rate = radians(-3.65);
        opacity_scale = 0.55;
    }
    rotation += rotation_rate * clock;
    vec2 offset = point * 0.75 - anchor;
    float rotation_cosine = cos(rotation);
    float rotation_sine = sin(rotation);
    vec2 local_point = vec2(rotation_cosine * offset.x - rotation_sine * offset.y,
        rotation_sine * offset.x + rotation_cosine * offset.y);
    vec2 halo_uv = local_point / image_size + texture_origin;
    if (halo_uv.x < 0.0 || halo_uv.x > 1.0 || halo_uv.y < 0.0 || halo_uv.y > 1.0) {
        return vec4(0.0);
    }
    vec4 halo = vec4(0.0);
    if (layer == 0) {
        halo = texture(halo_back_texture, halo_uv);
    } else if (layer == 1) {
        halo = texture(halo_main_texture, halo_uv);
    } else if (layer == 2) {
        halo = texture(halo_upper_texture, halo_uv);
    } else {
        halo = texture(halo_radial_texture, halo_uv);
        float source_opacity = clamp(halo.a, 0.0, 1.0);
        float core_attenuation = mix(0.62, 1.0,
            smoothstep(30.0, 170.0, length(local_point)));
        halo.a = pow(source_opacity, 1.30) * core_attenuation;
        float edge_fade = smoothstep(0.0, 0.04, halo_uv.x)
            * (1.0 - smoothstep(0.96, 1.0, halo_uv.x))
            * smoothstep(0.0, 0.04, halo_uv.y)
            * (1.0 - smoothstep(0.96, 1.0, halo_uv.y));
        halo.a *= edge_fade;
    }
    halo.rgb *= vec3(1.0, 0.941176, 0.8);
    halo.a *= light_arrival(point) * envelope * opacity_scale;
    return halo;
}

vec3 spectral_color(float phase) {
    float position = clamp(phase, 0.0, 1.0) * 6.0;
    if (position < 1.0) {
        return mix(vec3(0.55, 0.16, 1.0), vec3(0.16, 0.37, 1.0), position);
    }
    if (position < 2.0) {
        return mix(vec3(0.16, 0.37, 1.0), vec3(0.06, 0.86, 1.0), position - 1.0);
    }
    if (position < 3.0) {
        return mix(vec3(0.06, 0.86, 1.0), vec3(0.14, 0.90, 0.32), position - 2.0);
    }
    if (position < 4.0) {
        return mix(vec3(0.14, 0.90, 0.32), vec3(1.0, 0.91, 0.08), position - 3.0);
    }
    if (position < 5.0) {
        return mix(vec3(1.0, 0.91, 0.08), vec3(1.0, 0.48, 0.09), position - 4.0);
    }
    return mix(vec3(1.0, 0.48, 0.09), vec3(1.0, 0.18, 0.26), position - 5.0);
}

vec4 optical_accents(vec2 point) {
    float tail = 1.0 - smoothstep(fade_start, fade_end, clock);
    if (tail <= 0.0 || clock <= 0.0) {
        return vec4(0.0);
    }
    float fade = smoothstep(0.48, 1.14, clock) * tail;
    float source_fade = smoothstep(0.0, 0.20, clock) * tail;
    vec2 rainbow_point = (point - vec2(510.0, 850.0)) / 1.15 + vec2(510.0, 850.0);
    vec2 rainbow_offset = rainbow_point - vec2(190.0 + sin(clock * 0.6) * 4.0, 245.0);
    float rainbow_distance = length(rainbow_offset);
    float rainbow_angle = atan(rainbow_offset.y, rainbow_offset.x);
    float rainbow_radius = 710.0 + sin(clock * 0.4) * 3.0;
    float rainbow_band = (rainbow_distance - rainbow_radius) / 21.0;
    float rainbow_alpha = exp(-0.5 * rainbow_band * rainbow_band)
        * smoothstep(0.1, 0.34, rainbow_angle)
        * (1.0 - smoothstep(1.06, 1.29, rainbow_angle)) * fade * 0.22;
    float rainbow_phase = (rainbow_distance - rainbow_radius + 31.0) / 62.0;
    vec4 result = vec4(spectral_color(rainbow_phase), rainbow_alpha);
    float travel = smoothstep(0.7, 4.9, clock);
    vec2 source = vec2(154.0 + travel * 8.0, -16.0 + travel * 4.0);
    vec2 optical_center = vec2(342.0 + travel * 44.0, 640.0 + travel * 62.0);
    vec4 axis_positions = vec4(0.50, 0.80, 1.11, 1.48);
    vec4 ghost_radii = vec4(20.0, 35.0, 68.0, 108.0);
    vec4 ghost_strengths = vec4(0.45, 0.38, 0.39, 0.35);
    for (int index = 0; index < 4; index++) {
        vec2 center = source + (optical_center - source) * axis_positions[index];
        float radius = ghost_radii[index]
            * (1.0 + sin(clock * 0.75 + float(index) * 0.7) * 0.045);
        vec2 local = point - center;
        float radial_position = length(local) / radius;
        if (radial_position > 1.4) {
            continue;
        }
        float local_angle = atan(local.y, local.x);
        float rim_direction = clock * 0.18 + float(index) * 0.72;
        float rim_variation = 0.75 + 0.25 * cos(local_angle - rim_direction);
        float edge_distance = (radial_position - 0.94) / 0.075;
        float inner_distance = (radial_position - 0.76) / 0.085;
        float ghost_edge = exp(-0.5 * edge_distance * edge_distance) * rim_variation;
        float ghost_fill = (1.0 - smoothstep(0.38, 1.06, radial_position)) * 0.52;
        float inner_reflection = exp(-0.5 * inner_distance * inner_distance) * 0.12;
        float pulse = 0.93 + 0.07 * sin(clock + float(index) * 1.4);
        float opacity = (ghost_fill + ghost_edge + inner_reflection)
            * ghost_strengths[index] * fade * pulse;
        vec3 edge_tint = vec3(1.0, 0.98, 0.94);
        vec3 fill_tint = vec3(1.0, 0.99, 0.96);
        if (index == 1) {
            edge_tint = vec3(1.0, 0.97, 0.91);
            fill_tint = vec3(1.0, 0.99, 0.95);
        } else if (index == 2) {
            edge_tint = vec3(1.0, 0.985, 0.96);
            fill_tint = vec3(1.0, 0.995, 0.98);
        } else if (index == 3) {
            edge_tint = vec3(1.0, 0.97, 0.955);
            fill_tint = vec3(1.0, 0.99, 0.97);
        }
        float edge_mix = smoothstep(0.78, 0.98, radial_position) * 0.65;
        vec3 dispersion = spectral_color((radial_position - 0.78) / 0.36);
        vec3 edge_color = edge_tint * 0.92 + dispersion * 0.08;
        result = composite_over(result, vec4(mix(fill_tint, edge_color, edge_mix), opacity));
    }
    float source_radius = distance(point, source);
    float source_spread = mix(0.72, 1.0, smoothstep(0.0, 0.32, clock));
    float wide_source = source_radius / (94.0 * source_spread);
    float core_source = source_radius / 23.0;
    float source_alpha = (exp(-0.5 * wide_source * wide_source) * 0.20
        + exp(-0.5 * core_source * core_source) * 0.37) * source_fade;
    return composite_over(result, vec4(1.0, 0.99, 0.95, source_alpha));
}

void vertex() {
    surface_tint = COLOR;
}

void fragment() {
    vec2 screen_point = UV * area_size;
    vec2 point = screen_point / max(area_size.x / 720.0, 0.00001);
    vec4 result = vec4(0.0);
    if (light_enabled) {
        for (int layer = 0; layer < 4; layer++) {
            result = composite_over(result, collected_halo(point, layer));
        }
        result = composite_over(result, optical_accents(point));
    }
    if (drops_enabled && melt_enabled && drop_count > 0 && clock > melt_delay
        && clock < melt_delay + melt_duration + 0.98) {
        for (int index = 0; index < 8; index++) {
            if (index >= ice_count) {
                break;
            }
            vec2 ice_axis_x = ice_axes[index].xy;
            vec2 ice_axis_y = ice_axes[index].zw;
            float drop_scale = max(length(ice_axis_y) / 135.0, 0.00001);
            vec2 opposite_corner = ice_origins[index] + ice_axis_x + ice_axis_y;
            vec2 ice_min = min(min(ice_origins[index], opposite_corner),
                min(ice_origins[index] + ice_axis_x, ice_origins[index] + ice_axis_y));
            vec2 ice_max = max(max(ice_origins[index], opposite_corner),
                max(ice_origins[index] + ice_axis_x, ice_origins[index] + ice_axis_y));
            if (screen_point.x < ice_min.x - 22.0 * drop_scale
                || screen_point.x > ice_max.x + 22.0 * drop_scale
                || screen_point.y < ice_min.y - 16.0 * drop_scale
                || screen_point.y > ice_max.y + 220.0 * drop_scale) {
                continue;
            }
            for (int drop = 0; drop < 8; drop++) {
                if (drop >= drop_count) {
                    break;
                }
                float seed = float(index * 8 + drop) + 125.0;
                float birth_fraction = (float(drop) + 0.25
                    + hash_value(seed) * 0.50) / float(drop_count);
                float birth_progress = 0.14 + 0.74
                    * mix(birth_fraction, birth_fraction * birth_fraction, 0.30);
                float age = clock - melt_delay - birth_progress * melt_duration;
                float lifetime = 0.84 + hash_value(seed + 1.0) * 0.14;
                if (age < 0.0 || age >= lifetime) {
                    continue;
                }
                float horizontal_phase = fract(float(drop) * 0.61803398875 + 0.11
                    + hash_value(seed + 2.0) * 0.14);
                float horizontal_position = 0.12 + 0.76 * horizontal_phase;
                float gather_duration = 0.14 + hash_value(seed + 5.0) * 0.04;
                float attached_progress = birth_progress
                    + min(age, gather_duration) / max(melt_duration, 0.00001);
                float front = melt_front(horizontal_position, attached_progress);
                float fall_age = max(0.0, age - gather_duration);
                vec2 center = ice_origins[index] + ice_axis_x * horizontal_position
                    + ice_axis_y * front
                    + vec2((hash_value(seed + 3.0) - 0.5) * 16.0 * fall_age
                        + sin(fall_age * 7.0 + seed) * 3.0 * smoothstep(0.0, 0.18, fall_age),
                        18.0 * fall_age + 260.0 * fall_age * fall_age) * drop_scale;
                float growth = mix(0.35, 1.0, smoothstep(0.0, gather_duration, age));
                float radius = (0.75 + hash_value(seed + 4.0) * 0.5)
                    * drop_scale * drop_size * growth;
                vec2 drop_local = (screen_point - center)
                    / (vec2(3.3, 5.8 + smoothstep(0.0, 0.08, fall_age) * 0.9
                        + fall_age * 1.2) * radius);
                if (abs(drop_local.x) > 1.1 || abs(drop_local.y) > 1.1) {
                    continue;
                }
                float taper = mix(0.32, 1.0, smoothstep(-1.0, 0.25, drop_local.y));
                float shape = 1.0 - smoothstep(0.84, 1.04,
                    length(vec2(drop_local.x / taper, drop_local.y)));
                float highlight = 1.0 - smoothstep(0.18, 0.6,
                    length((drop_local - vec2(-0.22, 0.05)) / vec2(0.6, 1.0)));
                float opacity = shape * smoothstep(0.0, 0.06, age)
                    * (1.0 - smoothstep(lifetime - 0.24, lifetime, age)) * 0.78;
                vec3 water_color = mix(vec3(0.70, 0.87, 1.0), vec3(0.97, 0.99, 1.0),
                    highlight * 0.9);
                result = composite_over(result, vec4(water_color, opacity));
            }
        }
    }
    COLOR = vec4(result.rgb * surface_tint.rgb, result.a * surface_tint.a);
}
