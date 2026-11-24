shader_type canvas_item;
render_mode unshaded;

// 目标花盆按原贴图Alpha挖空；目标列与可选源列分别按完整胶囊挖空。
uniform sampler2D pot_texture : filter_linear, repeat_disable;
uniform bool pot_enabled = false;
uniform vec3 pot_uv_x = vec3(0.0);
uniform vec3 pot_uv_y = vec3(0.0);
uniform vec4 pot_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool pot_flip_h = false;
uniform bool pot_flip_v = false;
uniform vec4 capsule_rect = vec4(0.0);
uniform vec4 source_capsule_rect = vec4(0.0);
uniform vec2 mask_size = vec2(1.0);
uniform float dim_alpha = 0.65;
varying float item_alpha;

void vertex() {
	item_alpha = COLOR.a;
}

float capsule_alpha(vec2 point, vec4 rect) {
	if (rect.z <= 0.0 || rect.w <= 0.0) { return 0.0; }
	float radius = min(rect.z, rect.w) * 0.5;
	vec2 offset = point - rect.xy - rect.zw * 0.5;
	offset.y -= clamp(offset.y, -rect.w * 0.5 + radius, rect.w * 0.5 - radius);
	float distance_to_edge = length(offset) - radius;
	float edge_width = max(fwidth(distance_to_edge), 0.5);
	return 1.0 - smoothstep(-edge_width, edge_width, distance_to_edge);
}

void fragment() {
	vec2 point = UV * mask_size;
	float pot_hole = 0.0;
	if (pot_enabled) {
		vec2 pot_uv = vec2(dot(pot_uv_x, vec3(point, 1.0)), dot(pot_uv_y, vec3(point, 1.0)));
		float inside = step(0.0, pot_uv.x) * step(pot_uv.x, 1.0)
				* step(0.0, pot_uv.y) * step(pot_uv.y, 1.0);
		if (pot_flip_h) { pot_uv.x = 1.0 - pot_uv.x; }
		if (pot_flip_v) { pot_uv.y = 1.0 - pot_uv.y; }
		pot_hole = texture(pot_texture, pot_region.xy + pot_uv * pot_region.zw).a * inside;
	}
	float capsule_hole = capsule_alpha(point, capsule_rect);
	float source_hole = capsule_alpha(point, source_capsule_rect);
	COLOR = vec4(0.0, 0.0, 0.0, dim_alpha * (1.0 - max(pot_hole, max(capsule_hole, source_hole))) * item_alpha);
}
