shader_type canvas_item;
render_mode unshaded;

uniform float elapsed = -1.0;
uniform vec2 cloth_origin = vec2(0.0);
uniform vec2 cloth_scale = vec2(1.0);
uniform float half_width = 505.75;
uniform float unfold_duration = 0.38;
uniform float edge_delay = 0.18;
uniform float settle_time = 0.78;
uniform bool title_surface = false;

float unfold_progress(float distance) {
	return smoothstep(0.0, unfold_duration, elapsed - edge_delay * distance);
}

vec2 cloth_center(float horizontal) {
	float distance = abs(horizontal) / half_width;
	float spread = 0.0;
	for (int section = 0; section < 6; section++) {
		float section_distance = distance * (float(section) + 0.5) / 6.0;
		spread += mix(0.055, 1.0, unfold_progress(section_distance)) / 6.0;
	}
	float progress = unfold_progress(distance);
	float life = 1.0 - smoothstep(0.48, settle_time, elapsed);
	float curl = -82.0 * pow(distance, 1.8) * (1.0 - progress);
	float wave = 32.0 * distance * sin(3.14159265 * progress) * sin(distance * 3.14159265 - elapsed * 6.2831853);
	wave *= smoothstep(0.0, 0.16, elapsed);
	float follow = 10.0 * distance * distance * progress * life * sin(elapsed * 5.6548668 - distance * 2.0420352);
	return vec2(horizontal * spread, curl + wave + follow);
}

void vertex() {
	if (title_surface) {
		UV.y = 1.0 - UV.y;
		COLOR.a *= smoothstep(0.26, 0.46, elapsed);
	}
	if (elapsed < settle_time) {
		vec2 point = (VERTEX - cloth_origin) / cloth_scale;
		vec2 center = cloth_center(point.x);
		vec2 tangent = cloth_center(point.x + 2.0) - cloth_center(point.x - 2.0);
		float angle = clamp(atan(tangent.y, tangent.x), -0.85, 0.85);
		float thickness = mix(0.5, 1.0, unfold_progress(abs(point.x) / half_width));
		vec2 normal = vec2(-sin(angle), cos(angle));
		VERTEX = cloth_origin + (center + normal * point.y * thickness) * cloth_scale;
	}
}
