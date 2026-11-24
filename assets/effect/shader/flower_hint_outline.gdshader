shader_type canvas_item;

// 根据贴图 alpha 轮廓生成 hint 强调效果：
//   1. 贴近花朵的白色粗描边；
//   2. 描边外侧的黄色柔光。
//
// 宽度单位是源贴图像素，因此 JuiceFruit 缩放时效果会与花朵一起等比缩放。
// vertex 阶段按效果半径扩展 Sprite2D 四边形，描边和外发光不依赖素材预留透明边。

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 16.0, 0.5) = 6.0;

uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.05, 0.9);
uniform float glow_width : hint_range(0.0, 32.0, 0.5) = 14.0;
uniform float glow_strength : hint_range(0.0, 2.0, 0.05) = 1.0;

const int DIRECTION_COUNT = 24;
const float ANTIALIAS_PADDING = 2.0;

// fragment 阶段的 COLOR 已经乘过 TEXTURE；在 vertex 阶段单独保存 CanvasItem 调制色，
// 否则透明区 COLOR.a 恒为 0，会把所有画在轮廓外的描边与发光再次清成透明。
varying vec4 item_modulate;


void vertex() {
	item_modulate = COLOR;
	float padding = outline_width + glow_width + ANTIALIAS_PADDING;
	VERTEX += (UV * 2.0 - 1.0) * padding;
}


float in_texture_bounds(vec2 uv) {
	return step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
}


void fragment() {
	float padding = outline_width + glow_width + ANTIALIAS_PADDING;
	vec2 padding_uv = TEXTURE_PIXEL_SIZE * padding;
	vec2 source_uv = UV * (vec2(1.0) + padding_uv * 2.0) - padding_uv;
	vec4 texel = texture(TEXTURE, source_uv) * in_texture_bounds(source_uv);
	vec3 base_rgb = texel.rgb * item_modulate.rgb;
	float source_alpha = texel.a;

	// 同时采样各层半径的中点，避免宽描边或外发光在细小、凹陷轮廓处断开。
	float outline_mask = source_alpha;
	float glow_inner_mask = 0.0;
	float glow_outer_mask = 0.0;
	float outer_radius = outline_width + glow_width;
	for (int i = 0; i < DIRECTION_COUNT; i++) {
		float angle = TAU * float(i) / float(DIRECTION_COUNT);
		vec2 direction = vec2(cos(angle), sin(angle));
		vec2 half_outline_uv = source_uv + direction * TEXTURE_PIXEL_SIZE * outline_width * 0.5;
		vec2 outline_uv = source_uv + direction * TEXTURE_PIXEL_SIZE * outline_width;
		vec2 glow_inner_uv = source_uv + direction * TEXTURE_PIXEL_SIZE * (outline_width + glow_width * 0.5);
		vec2 glow_outer_uv = source_uv + direction * TEXTURE_PIXEL_SIZE * outer_radius;

		outline_mask = max(outline_mask, texture(TEXTURE, half_outline_uv).a * in_texture_bounds(half_outline_uv));
		outline_mask = max(outline_mask, texture(TEXTURE, outline_uv).a * in_texture_bounds(outline_uv));
		glow_inner_mask = max(glow_inner_mask, texture(TEXTURE, glow_inner_uv).a * in_texture_bounds(glow_inner_uv));
		glow_outer_mask = max(glow_outer_mask, texture(TEXTURE, glow_outer_uv).a * in_texture_bounds(glow_outer_uv));
	}
	float glow_mask = max(glow_inner_mask, glow_outer_mask * 0.35);

	float outline_alpha = clamp(outline_mask - source_alpha, 0.0, 1.0);
	float glow_alpha = clamp(glow_mask - max(source_alpha, outline_mask), 0.0, 1.0);
	glow_alpha *= glow_color.a * glow_strength;
	outline_alpha *= outline_color.a;

	// 由外向内做标准 alpha 合成，保证本体颜色不被描边或外发光染黄。
	vec3 glow_rgb = glow_color.rgb * item_modulate.rgb;
	vec3 outline_rgb = outline_color.rgb * item_modulate.rgb;
	vec3 premultiplied = glow_rgb * glow_alpha;
	float result_alpha = glow_alpha;

	premultiplied = outline_rgb * outline_alpha + premultiplied * (1.0 - outline_alpha);
	result_alpha = outline_alpha + result_alpha * (1.0 - outline_alpha);
	premultiplied = base_rgb * source_alpha + premultiplied * (1.0 - source_alpha);
	result_alpha = source_alpha + result_alpha * (1.0 - source_alpha);

	vec3 result_rgb = premultiplied / max(result_alpha, 0.00001);
	COLOR = vec4(result_rgb, result_alpha * item_modulate.a);
}
