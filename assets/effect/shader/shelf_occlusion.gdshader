shader_type canvas_item;

uniform sampler2D shelf_texture : filter_linear, repeat_disable;
uniform bool occlusion_enabled = false;
uniform vec3 shelf_uv_x = vec3(0.0);
uniform vec3 shelf_uv_y = vec3(0.0);
uniform vec3 second_shelf_uv_x = vec3(0.0);
uniform vec3 second_shelf_uv_y = vec3(0.0);
uniform float shelf_alpha = 0.0;
uniform float second_shelf_alpha = 0.0;

varying vec2 world_position;

void vertex() {
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
	if (occlusion_enabled) {
		float occlusion = max(shelf_occlusion(shelf_uv_x, shelf_uv_y, shelf_alpha),
				shelf_occlusion(second_shelf_uv_x, second_shelf_uv_y, second_shelf_alpha));
		COLOR.a *= 1.0 - occlusion;
	}
}
