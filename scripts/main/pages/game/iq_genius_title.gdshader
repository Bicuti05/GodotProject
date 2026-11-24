shader_type canvas_item;
render_mode unshaded;

// 原SVG字面渐变y=77.3712..135.484，外轮廓y=10.602..135.484；加上画布余量50px。
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	// 离屏视口RGB已预乘Alpha，通道本身就是覆盖率，不再乘一次mask.a。
	float body = mask.r;
	float face = mask.g;
	float y = UV.y / TEXTURE_PIXEL_SIZE.y;
	vec3 face_color = mix(vec3(1.0, 0.9215686, 0.2705882), vec3(0.9843137, 0.6862745, 0.0117647),
			clamp((y - 127.3712) / 58.1128, 0.0, 1.0));
	vec3 border_color = mix(vec3(0.745098, 0.3607843, 0.1960784), vec3(0.6392157, 0.2313725, 0.0392157),
			clamp((y - 60.602) / 124.882, 0.0, 1.0));
	float shadow = 0.0;
	float weight_sum = 0.0;
	// 原SVG阴影stdDeviation=0.605，dy=6；小面积标题使用3×3采样。
	for (int sy = -1; sy <= 1; sy++) {
		for (int sx = -1; sx <= 1; sx++) {
			vec2 offset = vec2(float(sx), float(sy));
			float weight = exp(-dot(offset, offset) / (2.0 * 0.605 * 0.605));
			shadow += texture(TEXTURE, UV + (offset - vec2(0.0, 6.0)) * TEXTURE_PIXEL_SIZE).r * weight;
			weight_sum += weight;
		}
	}
	shadow = shadow / weight_sum * (1.0 - body);
	float alpha = body + shadow;
	vec3 rgb = border_color * max(0.0, body - face) + face_color * face
			+ vec3(0.363782, 0.0687919, 0.0721441) * shadow;
	COLOR = vec4(rgb / max(alpha, 0.00001), alpha) * tint;
}
