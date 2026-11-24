shader_type canvas_item;
render_mode unshaded, blend_add;

// 光图以Plus Lighter叠加，仅保留完整进度原图的Alpha；横向截断由父FillClip负责。
uniform sampler2D fill_mask : filter_linear, repeat_disable;
// 光图所在矩形，换算到完整进度原图UV；允许光图超出原图上下边界。
uniform vec4 mask_uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float glow_strength = 1.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 mask_uv = mask_uv_rect.xy + UV * mask_uv_rect.zw;
	float inside = step(0.0, mask_uv.x) * step(mask_uv.x, 1.0)
			* step(0.0, mask_uv.y) * step(mask_uv.y, 1.0);
	vec4 glow = texture(TEXTURE, UV) * tint;
	glow.a *= texture(fill_mask, mask_uv).a * inside * glow_strength;
	COLOR = glow;
}
