shader_type canvas_item;
render_mode unshaded;

// Centre reveal sampled from banner_hard; separate side recoil sampled from hard_super_hard. Cloth renderer adapted from reward_banner_cloth without touching that popup.

uniform float elapsed = -1.0;
uniform vec2 cloth_origin = vec2(0.0);
uniform vec2 cloth_scale = vec2(1.0);
uniform float half_width = 430.0;
uniform float unfold_duration = 0.20;
uniform float edge_delay = 0.10;
uniform float settle_time = 0.52;
uniform bool title_surface = false;

uniform vec4 side_motion = vec4(0.0, 0.0, 1.0, 1.0);

float hard_panel_curve(float p) {
	if (p < 0.0833333) return mix(0.0000000, 0.0571500, clamp((p - 0.0000000) / 0.0833333, 0.0, 1.0));
	if (p < 0.1666667) return mix(0.0571500, 0.1143000, clamp((p - 0.0833333) / 0.0833333, 0.0, 1.0));
	if (p < 0.2500000) return mix(0.1143000, 0.2643000, clamp((p - 0.1666667) / 0.0833333, 0.0, 1.0));
	if (p < 0.3333333) return mix(0.2643000, 0.4143000, clamp((p - 0.2500000) / 0.0833333, 0.0, 1.0));
	if (p < 0.4166667) return mix(0.4143000, 0.5214500, clamp((p - 0.3333333) / 0.0833333, 0.0, 1.0));
	if (p < 0.5000000) return mix(0.5214500, 0.6285999, clamp((p - 0.4166667) / 0.0833333, 0.0, 1.0));
	if (p < 0.5833333) return mix(0.6285999, 0.7214500, clamp((p - 0.5000000) / 0.0833333, 0.0, 1.0));
	if (p < 0.6666667) return mix(0.7214500, 0.8143000, clamp((p - 0.5833333) / 0.0833333, 0.0, 1.0));
	if (p < 0.7500000) return mix(0.8143000, 0.8857000, clamp((p - 0.6666667) / 0.0833333, 0.0, 1.0));
	if (p < 0.8333333) return mix(0.8857000, 0.9571000, clamp((p - 0.7500000) / 0.0833333, 0.0, 1.0));
	if (p < 0.9166667) return mix(0.9571000, 0.9785500, clamp((p - 0.8333333) / 0.0833333, 0.0, 1.0));
	if (p < 1.0000000) return mix(0.9785500, 1.0000000, clamp((p - 0.9166667) / 0.0833333, 0.0, 1.0));
	return 1.0;
}

float unfold_progress(float distance) {
	return hard_panel_curve(clamp((elapsed - edge_delay * distance) / unfold_duration, 0.0, 1.0));
}

vec2 cloth_center(float horizontal) {
	float distance = abs(horizontal) / half_width;
	float spread = 0.0;
	for (int section = 0; section < 6; section++) {
		float section_distance = distance * (float(section) + 0.5) / 6.0;
		spread += mix(0.055, 1.0, unfold_progress(section_distance)) / 6.0;
	}
	float progress = unfold_progress(distance);
	float life = 1.0 - smoothstep(0.32, settle_time, elapsed);
	float curl = -24.0 * pow(distance, 1.8) * (1.0 - progress);
	float wave = 8.0 * distance * sin(3.14159265 * progress) * sin(distance * 3.14159265 - elapsed * 6.2831853);
	wave *= smoothstep(0.0, 0.16, elapsed);
	float side = horizontal >= 0.0 ? 1.0 : 0.0;
	float angle = mix(side_motion.x, side_motion.y, side);
	float extension = mix(side_motion.z, side_motion.w, side);
	float edge = smoothstep(0.40, 1.0, distance);
	float recoil = -sin(angle) * sign(horizontal) * half_width * distance * distance * edge * 0.55;
	float follow = 2.0 * distance * distance * progress * life * sin(elapsed * 5.6548668 - distance * 2.0420352);
	return vec2(horizontal * spread * mix(1.0, extension, edge), curl + wave + follow + recoil);
}

void vertex() {
	if (title_surface) {
		UV.y = 1.0 - UV.y;
		COLOR.a *= smoothstep(0.26, 0.46, elapsed);
	}
	if (elapsed >= 0.0 && elapsed < settle_time) {
		vec2 point = (VERTEX - cloth_origin) / cloth_scale;
		vec2 center = cloth_center(point.x);
		vec2 tangent = cloth_center(point.x + 2.0) - cloth_center(point.x - 2.0);
		float angle = clamp(atan(tangent.y, tangent.x), -0.85, 0.85);
		float thickness = mix(0.5, 1.0, unfold_progress(abs(point.x) / half_width));
		vec2 normal = vec2(-sin(angle), cos(angle));
		VERTEX = cloth_origin + (center + normal * point.y * thickness) * cloth_scale;
	}
}
