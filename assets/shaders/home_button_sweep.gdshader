shader_type canvas_item;
render_mode blend_add;

uniform vec2 button_size = vec2(792.0, 216.0);
uniform float progress = -0.25;
uniform float strength : hint_range(0.0, 1.5) = 0.46;
uniform float envelope : hint_range(0.0, 1.0) = 0.0;
uniform float breath : hint_range(0.0, 1.0) = 0.0;
uniform bool glow_mode = false;
uniform vec2 glow_margin = vec2(42.0);
uniform float rim_progress : hint_range(0.0, 1.0) = 0.0;
uniform float rim_envelope : hint_range(0.0, 1.0) = 0.0;
uniform vec4 border_insets = vec4(4.0, 8.0, 4.0, 4.0);
uniform float border_radius = 69.0;
uniform float rim_gap = 8.0;

varying vec2 local_pixel;
varying vec4 vertex_modulate;

void vertex() {
	local_pixel = VERTEX;
	vertex_modulate = COLOR;
}

float rounded_rect_perimeter(vec2 point, vec2 inner_half, float radius) {
	vec2 absolute_point = abs(point);
	vec2 corner_offset = absolute_point - inner_half;
	float corner_length = radius * PI * 0.5;
	float quarter_length = inner_half.x + inner_half.y + corner_length;
	float quarter_distance;
	if (corner_offset.x <= 0.0) {
		quarter_distance = absolute_point.x;
	} else if (corner_offset.y <= 0.0) {
		quarter_distance = inner_half.x + corner_length + inner_half.y - absolute_point.y;
	} else {
		quarter_distance = inner_half.x + radius * atan(corner_offset.x, corner_offset.y);
	}
	float distance_on_edge;
	if (point.x >= 0.0) {
		distance_on_edge = point.y < 0.0 ? quarter_distance : quarter_length * 2.0 - quarter_distance;
	} else {
		distance_on_edge = point.y >= 0.0 ? quarter_length * 2.0 + quarter_distance
				: quarter_length * 4.0 - quarter_distance;
	}
	return distance_on_edge / max(quarter_length * 4.0, 0.001);
}

void fragment() {
	if (glow_mode) {
		vec2 border_start = border_insets.xy;
		vec2 border_end = button_size - border_insets.zw;
		vec2 border_half = max((border_end - border_start) * 0.5, vec2(0.0));
		vec2 point = local_pixel - glow_margin - (border_start + border_end) * 0.5;
		vec2 glow_half = border_half + vec2(rim_gap);
		float radius = min(border_radius, min(border_half.x, border_half.y)) + rim_gap;
		vec2 inner_half = glow_half - vec2(radius);
		vec2 corner_point = abs(point) - inner_half;
		float distance_to_edge = length(max(corner_point, vec2(0.0)))
				+ min(max(corner_point.x, corner_point.y), 0.0) - radius;
		float outline_distance = distance_to_edge / 2.8;
		float halo_distance = max(distance_to_edge, 0.0) / 16.0;
		float outline = exp(-outline_distance * outline_distance);
		float halo = exp(-halo_distance * halo_distance) * smoothstep(-1.5, 4.0, distance_to_edge);
		float edge_progress = rounded_rect_perimeter(point, inner_half, radius);
		float head_distance = (fract(edge_progress - rim_progress + 0.5) - 0.5) / 0.065;
		float follow_distance = (fract(edge_progress - rim_progress) - 0.5) / 0.085;
		float rim = (exp(-head_distance * head_distance)
				+ exp(-follow_distance * follow_distance) * 0.72) * rim_envelope;
		float lower_distance = (point.y - button_size.y * 0.50) / 20.0;
		float center_distance = point.x / (button_size.x * 0.36);
		float lower_glow = exp(-lower_distance * lower_distance - center_distance * center_distance)
				* smoothstep(0.0, 5.0, distance_to_edge);
		float base_opacity = ((outline * 0.43 + halo * 0.16) * (0.12 + breath * 0.70)
				+ lower_glow * breath * 0.16) * strength;
		float rim_opacity = (outline * 0.52 + halo * 0.17) * rim * strength;
		float opacity = base_opacity + rim_opacity;
		vec3 light_color = mix(vec3(1.0, 0.94, 0.62), vec3(1.0, 0.99, 0.94),
				rim_opacity / max(opacity, 0.001));
		COLOR = vec4(light_color, opacity);
	} else {
		vec2 position = local_pixel / max(button_size, vec2(1.0));
		float vertical = position.y - 0.5;
		float diagonal = position.x + vertical * 0.27 + vertical * vertical * 0.08;
		float distance_to_band = diagonal - progress;
		float core_distance = distance_to_band / 0.086;
		float shoulder_distance = distance_to_band / 0.215;
		float trail_distance = (distance_to_band + 0.12) / 0.29;
		float core = exp(-core_distance * core_distance);
		float shoulder = exp(-shoulder_distance * shoulder_distance);
		float trail = exp(-trail_distance * trail_distance);
		float echo_distance = (distance_to_band + 0.20) / 0.052;
		float echo = exp(-echo_distance * echo_distance);
		float band = clamp(core * 0.58 + shoulder * 0.24 + trail * 0.16 + echo * 0.14, 0.0, 1.0);
		float top_face = 1.0 - smoothstep(0.75, 0.94, position.y);
		float side_fade = smoothstep(0.0, 0.03, position.x) * (1.0 - smoothstep(0.97, 1.0, position.x));
		float glow_distance = (position.y - 0.28) / 0.32;
		float face_glow = exp(-glow_distance * glow_distance) * breath * 0.16;
		float mask = texture(TEXTURE, UV).a;
		float light = (band * envelope + face_glow) * strength;
		COLOR = vec4(vec3(1.0, 0.97, 0.88), mask * top_face * side_fade * light);
	}
	COLOR *= vertex_modulate;
}
