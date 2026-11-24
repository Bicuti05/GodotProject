shader_type canvas_item;
render_mode unshaded;

// Unity frame/frame_2实际使用的eff_grid3贴图，保留原边角与柔光，不推算底板圆角。
uniform sampler2D frame_texture : filter_linear, repeat_disable;
uniform vec2 body_size = vec2(852.0, 169.0);
uniform float padding = 64.0;
uniform float progress = 0.0;
uniform float expansion_pixels = 18.0;
uniform vec4 ripple_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform bool use_color_texture = false;
uniform sampler2D color_texture : source_color, filter_linear, repeat_disable;
uniform vec2 color_center;
uniform float color_size = 1264.0;
uniform vec2 body_origin = vec2(5.0, 62.0);
uniform float angle = 0.0;
varying vec2 pixel_position;

// 保留Unity扩散节奏，只将曲线转换为四边相同的像素距离。
float unity_expansion(float age) {
	float t2 = age * age;
	float t3 = t2 * age;
	float value = (2.0 * t3 - 3.0 * t2 + 1.0) * 0.9220581
		+ (t3 - 2.0 * t2 + age) * 0.22390883 + (-2.0 * t3 + 3.0 * t2);
	return clamp((value - 0.9220581) / (1.0 - 0.9220581), 0.0, 1.0);
}

// 九宫格边角固定，只延长中间直边；保留原贴图的圆角和柔光宽度。
float frame_axis(float p, float target_extent, float source_extent, float corner_extent) {
	float source_corner = 32.0;
	if (p < corner_extent) {
		return p / corner_extent * source_corner;
	}
	if (p > target_extent - corner_extent) {
		return source_extent - (target_extent - p) / corner_extent * source_corner;
	}
	return source_corner + (p - corner_extent) / max(target_extent - corner_extent * 2.0, 1.0)
		* (source_extent - source_corner * 2.0);
}

float source_frame(vec2 p, float expansion) {
	vec2 expanded_size = body_size + vec2(expansion * 2.0);
	vec2 expanded_point = p + vec2(expansion);
	vec2 corner = body_size * vec2(32.0) / vec2(494.0, 92.0);
	vec2 source_point = vec2(
		frame_axis(expanded_point.x, expanded_size.x, 494.0, corner.x),
		frame_axis(expanded_point.y, expanded_size.y, 92.0, corner.y));
	vec2 uv = (vec2(9.0, 210.0) + source_point) / 512.0;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	// 收掉低透明度雾边，保留原角形与主体柔光；让基础色更清楚。
	float alpha = texture(frame_texture, uv).a;
	return smoothstep(0.04, 0.49, alpha) * 0.72;
}

void vertex() {
	pixel_position = VERTEX;
}

void fragment() {
	vec2 p = pixel_position - vec2(padding);
	float coverage = 0.0;
	float time = progress * 1.25;
	for (int i = 0; i < 2; i++) {
		float age = time - float(i) * 0.25;
		if (age >= 0.0 && age < 1.0) {
			float hold_end = i == 0 ? 0.7735256 : 0.8352941;
			float opacity = min(clamp(age / 0.078706, 0.0, 1.0), clamp((1.0 - age) / (1.0 - hold_end), 0.0, 1.0));
			float layer = source_frame(p, unity_expansion(age) * expansion_pixels) * opacity;
			coverage = layer + coverage * (1.0 - layer);
		}
	}
	vec4 selected = ripple_color;
	if (use_color_texture) {
		vec2 point = p + body_origin - color_center;
		float c = cos(angle);
		float s = sin(angle);
		selected = texture(color_texture, vec2(c * point.x + s * point.y, -s * point.x + c * point.y) / color_size + 0.5);
	}
	COLOR = vec4(selected.rgb, selected.a * coverage);
}
