shader_type canvas_item;
render_mode unshaded;

// 三套 Figma 原图共用 UV；缓动后的权重由倒计时比例计算，不另跑动画时钟。
uniform sampler2D yellow_fill : source_color, filter_linear, repeat_disable;
uniform sampler2D red_fill : source_color, filter_linear, repeat_disable;
uniform vec3 color_weights = vec3(1.0, 0.0, 0.0);
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 fill = texture(TEXTURE, UV) * color_weights.x
			+ texture(yellow_fill, UV) * color_weights.y
			+ texture(red_fill, UV) * color_weights.z;
	COLOR = fill * tint;
}
