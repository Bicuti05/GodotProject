shader_type canvas_item;
render_mode unshaded;

// 普通粒子固定为实际花色，炫彩粒子采样原炫彩图，与内层流光共用旋转角度。
uniform sampler2D color_texture : source_color, filter_linear, repeat_disable;
uniform vec2 effect_origin;
uniform vec2 effect_scale = vec2(1.0);
uniform vec2 color_center;
uniform float color_size = 1264.0;
uniform float angle = 0.0;
uniform vec4 effect_color : source_color = vec4(1.0);
uniform bool use_color_texture = false;
varying vec2 effect_point;
varying vec4 item_tint;

void vertex() {
	effect_point = ((MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy - effect_origin) / max(abs(effect_scale), vec2(0.0001));
	item_tint = COLOR;
}

void fragment() {
	vec4 shape = texture(TEXTURE, UV);
	vec2 p = effect_point - color_center;
	float c = cos(angle);
	float s = sin(angle);
	vec4 selected = texture(color_texture,
			vec2(c * p.x + s * p.y, -s * p.x + c * p.y) / color_size + 0.5);
	vec3 rgb = use_color_texture ? selected.rgb : effect_color.rgb;
	float color_alpha = use_color_texture ? selected.a : 1.0;
	float brightness = max(shape.r, max(shape.g, shape.b));
	// 强度放进覆盖率，不乘黑RGB；避免半透明边缘压成黑色描边。
	COLOR = vec4(rgb, shape.a * brightness * color_alpha * item_tint.a * effect_color.a);
}
