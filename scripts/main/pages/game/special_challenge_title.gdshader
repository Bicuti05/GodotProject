shader_type canvas_item;
render_mode unshaded;

// Figma 20475:35161: 15.84px 主轮廓、4.4px 内边、红色渐变与分层阴影。
uniform vec4 glyph_bounds = vec4(64.0, 140.0, 900.0, 130.0);
uniform sampler2D title_mask : filter_linear, repeat_disable;
uniform sampler2D horizontal_blur : filter_linear, repeat_disable;
uniform bool blur_only = false;
uniform bool display_cached = false;
// 按 Figma 原导出的外围 Alpha 衰减校准；设计稿 Blur 36.08px 不直接等于 2σ。
uniform float glow_sigma = 15.0;
uniform float glow_opacity = 1.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

float body_alpha(vec2 uv) {
	return texture(title_mask, uv).a;
}

float white_alpha(vec2 uv) {
	vec4 pixel = texture(title_mask, uv);
	return pixel.a * smoothstep(0.4, 0.95, pixel.g);
}

vec4 over(vec4 background, vec4 foreground) {
	float alpha = foreground.a + background.a * (1.0 - foreground.a);
	vec3 rgb = foreground.rgb * foreground.a + background.rgb * background.a * (1.0 - foreground.a);
	return vec4(rgb / max(alpha, 0.00001), alpha);
}

float gaussian_alpha(sampler2D source, vec2 uv, vec2 direction, float sigma) {
	float value = 0.0;
	float weight_sum = 0.0;
	for (int i = -14; i <= 14; i++) {
		float offset = float(i) * 4.0;
		float weight = exp(-offset * offset / (2.0 * sigma * sigma));
		value += texture(source, uv + direction * offset).a * weight;
		weight_sum += weight;
	}
	return value / weight_sum;
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	// 两个缓存视口分别做横向和纵向卷积，避免稀疏二维采样产生重影。
	if (display_cached) {
		// 透明视口缓存的 RGB 已预乘 Alpha，恢复后再交给普通透明混合。
		// 保留独立顶点透明度，使 CanvasGroup 淡出时颜色和 Alpha 同步衰减。
		vec4 cached = texture(TEXTURE, UV);
		COLOR = vec4(cached.rgb / max(cached.a, 0.00001), cached.a) * tint;
	} else if (blur_only) {
		COLOR = vec4(vec3(1.0), gaussian_alpha(title_mask, UV, vec2(px.x, 0.0), glow_sigma)) * tint;
	} else {
		float body = body_alpha(UV);
		float white = white_alpha(UV);
		float glow = gaussian_alpha(horizontal_blur, UV, vec2(0.0, px.y), glow_sigma);
		float weight_sum = 0.0;
		float shadow = 0.0;
		float inner_shadow = 0.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 offset = vec2(float(x), float(y));
				float weight = exp(-dot(offset, offset) * 0.5);
				shadow += body_alpha(UV + (offset * 2.365 - vec2(0.0, 3.96)) * px) * weight;
				inner_shadow += white_alpha(UV + (offset * 0.605 - vec2(0.0, 3.14)) * px) * weight;
				weight_sum += weight;
			}
		}
		shadow /= weight_sum;
		inner_shadow /= weight_sum;
		float inner_border = white;
		for (int i = 0; i < 12; i++) {
			float angle = float(i) * 6.2831853 / 12.0;
			inner_border = max(inner_border, white_alpha(UV + vec2(cos(angle), sin(angle)) * 4.4 * px));
		}
		float gradient_y = clamp((UV.y / px.y - glyph_bounds.y) / glyph_bounds.w, 0.0, 1.0);
		vec3 red = vec3(1.0, 0.301961, 0.301961);
		vec3 gradient = mix(red, vec3(1.0, 0.478431, 0.478431), gradient_y);
		vec3 body_color = mix(red, gradient, inner_border);
		body_color = mix(body_color, red * 0.78, inner_shadow * (1.0 - white) * 0.5);
		float top_edge = max(0.0, body - body_alpha(UV - vec2(0.0, 1.8) * px));
		float bottom_edge = max(0.0, body - body_alpha(UV + vec2(0.0, 1.8) * px));
		body_color = mix(body_color, vec3(1.0, 0.85, 0.85), top_edge * 0.8);
		body_color = mix(body_color, red * 0.72, bottom_edge * 0.45);
		body_color = mix(body_color, vec3(0.992157, 0.996078, 0.992157), white);
		vec4 result = vec4(red, glow * glow_opacity);
		result = over(result, vec4(vec3(0.0), shadow * 0.4));
		result = over(result, vec4(body_color, body));
		COLOR = result * tint;
	}
}
