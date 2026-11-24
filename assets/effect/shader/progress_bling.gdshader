shader_type canvas_item;
render_mode unshaded;

uniform sampler2D color_texture : source_color, filter_linear, repeat_disable;
uniform float angle = 0.0;
uniform vec2 color_center;
uniform float color_size = 1264.0;
varying vec2 pixel_position;
varying vec4 tint;

void vertex() {
	pixel_position = VERTEX;
	tint = COLOR;
}

void fragment() {
	vec2 p = pixel_position - color_center;
	float c = cos(angle);
	float s = sin(angle);
	vec2 color_uv = vec2(c * p.x + s * p.y, -s * p.x + c * p.y) / color_size + 0.5;
	vec4 selected = texture(color_texture, color_uv);
	vec4 mask = texture(TEXTURE, UV);
	// 内层恢复原图RGB旋转，不再替换为纯色或亮度高光。
	COLOR = vec4(selected.rgb, mask.a * selected.a) * tint;
}
