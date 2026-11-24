shader_type canvas_item;

// 整段实时文字遮罩按源SVG的hardAlpha与Gaussian参数投影，避免字体图集邻字串色。
uniform float sigma = 0.603487;
uniform float hard_alpha = 127.0;
uniform vec4 shadow_color : source_color = vec4(0.533654, 0.0667067, 0.072013, 1.0);
varying vec4 pass_color;

void vertex() {
	pass_color = COLOR;
}

float mask_alpha(vec2 uv, float sampled_alpha) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return 0.0;
	}
	return clamp(sampled_alpha * hard_alpha, 0.0, 1.0);
}

void fragment() {
	float alpha = 0.0;
	float total = 0.0;
	// 3σ范围的7×7离散Gaussian；sigma直接来自SVG。
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			float weight = exp(-0.5 * float(x * x + y * y));
			vec2 sample_uv = UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * sigma;
			alpha += mask_alpha(sample_uv, texture(TEXTURE, sample_uv).a) * weight;
			total += weight;
		}
	}
	COLOR = vec4(shadow_color.rgb * pass_color.rgb, alpha / total * shadow_color.a * pass_color.a);
}
