shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float motion_time = 0.0;
uniform float strength = 0.0;
uniform float sweep_time = -1.0;
uniform vec2 origin_uv = vec2(0.5);
uniform float viewport_aspect = 0.46;

float soft_field(float distance, float time, float delay) {
    float age = time - delay - 0.08;
    if (age < 0.0) return 0.0;
    // Geometry completes before opacity fades: farthest corner has distance <= 1.
    float spread = clamp(age / 0.82, 0.0, 1.0);
    float radius = mix(0.015, 1.22, 1.0 - pow(1.0 - spread, 2.0));
    float filled = 1.0 - smoothstep(radius - 0.16, radius + 0.12, distance);
    float front_distance = (distance - radius + 0.08) / 0.18;
    float front = exp(-front_distance * front_distance);
    // Filled light reaches every corner; a broad soft leading fold shows movement.
    float field = filled * 0.64 + front * 0.46;
    float appear = smoothstep(0.0, 0.10, age);
    // Peak relaxes to a low static field; lift alpha owns the final disappearance.
    float fade = mix(1.0, 0.28, smoothstep(0.85, 1.55, age));
    return field * appear * fade;
}

void fragment() {
    if (strength <= 0.0001 || sweep_time < 0.0) {
        COLOR = vec4(0.0);
    } else {
        vec2 point = (UV - origin_uv) * vec2(viewport_aspect, 1.0);
        vec2 reach = max(origin_uv, vec2(1.0) - origin_uv) * vec2(viewport_aspect, 1.0);
        float distance = length(point) / max(length(reach), 0.01);
        float angle = atan(point.y, point.x);
        vec3 rose = vec3(1.0, 0.34, 0.77);
        vec3 lilac = vec3(0.66, 0.48, 1.0);
        vec3 gold = vec3(1.0, 0.84, 0.36);
        vec3 warm_white = vec3(1.0, 0.97, 0.89);
        // Separate soft color sectors. Cyan is a narrow edge accent, not a third wash.
        float rose_sector = 0.5 + 0.5 * sin(angle + 0.60 + sin(sweep_time * 1.4) * 0.16);
        vec3 tint = mix(lilac, rose, rose_sector);
        float warm_sector = smoothstep(0.25, 0.95, 0.5 + 0.5 * cos(angle - 0.70));
        tint = mix(tint, gold, warm_sector * 0.72);
        float cyan_edge = pow(max(0.0, 0.5 + 0.5 * sin(angle - 1.80)), 8.0)
            * smoothstep(0.55, 0.95, distance) * 0.18;
        tint = mix(tint, vec3(0.70, 0.95, 1.0), cyan_edge);
        tint = mix(warm_white, tint, smoothstep(0.02, 0.28, distance));
        float first = soft_field(distance, sweep_time, 0.0);
        float second = soft_field(distance, sweep_time, 0.18) * 0.55;
        float coverage = first + second * (1.0 - first);
        // A short contracting warm glow precedes the outward release, never a full-screen flash.
        float gather_progress = clamp(sweep_time / 0.08, 0.0, 1.0);
        float gather_radius = mix(0.32, 0.20, gather_progress);
        float gather_distance = distance / gather_radius;
        float gather = exp(-gather_distance * gather_distance * 1.5)
            * smoothstep(0.0, 0.045, sweep_time)
            * (1.0 - smoothstep(0.08, 0.16, sweep_time)) * 0.78;
        // Soft overlap joins the contraction and expansion without a blank or snap frame.
        float combined = coverage + gather * (1.0 - coverage);
        vec3 wave_tint = mix(tint, warm_white, second / max(first + second, 0.0001) * 0.18);
        vec3 final_tint = mix(wave_tint, warm_white, gather / max(coverage + gather, 0.0001));
        COLOR = vec4(final_tint, clamp(combined * strength, 0.0, 0.86));
    }
}
