shader_type canvas_item;

// Bonus 标题的静态样式。0=橙色渐变，1=分离高斯模糊，2=字面内/外阴影，3=缓存合成。
// 字形与描边由多语言 Label 渲染；各模式只在文字变化/首次播放时进离屏缓存。
uniform int effect_mode = 0;
uniform vec4 gradient_top : source_color = vec4(0.9843137, 0.6277124, 0.0117647, 1.0);
uniform vec4 gradient_bottom : source_color = vec4(0.9647059, 0.3137255, 0.0039216, 1.0);
uniform float gradient_top_stop = 0.22115384;
uniform float gradient_top_y = 5.5;
uniform float gradient_height = 115.0;
uniform vec2 blur_direction = vec2(1.0, 0.0);
// Figma blur radius 对应高斯标准差 radius/2；垂直半尺寸缓存同时减半此参数。
uniform float blur_radius = 90.75;
uniform vec4 inner_color : source_color = vec4(0.9137255, 0.7254902, 0.8078431, 1.0);
uniform vec4 face_shadow_color : source_color = vec4(0.9127855, 0.7256789, 0.8071399, 1.0);
uniform vec2 inner_offset = vec2(0.0, -1.4374801);
uniform float inner_blur = 1.4374801;
uniform vec2 face_shadow_offset = vec2(0.0, 1.4520001);

varying float local_y;
varying vec4 vertex_modulate;

void vertex() {
	local_y = VERTEX.y;
	vertex_modulate = COLOR;
}

float mask_inside(vec2 uv) {
	// 缓存外围透明 padding 覆盖完整阴影，边界外禁止重复边缘像素。
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return 1.0;
}

void fragment() {
	if (effect_mode == 0) {
		float t = clamp((local_y - gradient_top_y) / max(gradient_height, 1.0), 0.0, 1.0);
		t = clamp((t - gradient_top_stop) / (1.0 - gradient_top_stop), 0.0, 1.0);
		// 本层填充与描边均为白色剪影，字面由上方白字层覆盖。
		COLOR.rgb = mix(gradient_top.rgb, gradient_bottom.rgb, t) * vertex_modulate.rgb;
	} else if (effect_mode == 1) {
		float sigma = max(blur_radius * 0.5, 0.01);
		float total = 0.0;
		float weight_total = 0.0;
		for (int i = -15; i <= 15; i++) {
			float z = float(i) / 5.0;
			float weight = exp(-0.5 * z * z);
			vec2 sample_uv = UV + blur_direction * TEXTURE_PIXEL_SIZE * (z * sigma);
			total += texture(TEXTURE, sample_uv).a * mask_inside(sample_uv) * weight;
			weight_total += weight;
		}
		COLOR = vec4(vec3(1.0), total / weight_total) * vertex_modulate;
	} else if (effect_mode == 2) {
		float a = texture(TEXTURE, UV).a;
		float shifted = 0.0;
		float weight_total = 0.0;
		float sigma = max(inner_blur * 0.5, 0.01);
		for (int y = -2; y <= 2; y++) {
			for (int x = -2; x <= 2; x++) {
				vec2 delta = vec2(float(x), float(y));
				float weight = exp(-dot(delta, delta) / (2.0 * sigma * sigma));
				vec2 sample_uv = UV - (inner_offset + delta) * TEXTURE_PIXEL_SIZE;
				shifted += texture(TEXTURE, sample_uv).a * mask_inside(sample_uv) * weight;
				weight_total += weight;
			}
		}
		float inner = (1.0 - shifted / weight_total) * inner_color.a;
		vec3 face = mix(vec3(1.0), inner_color.rgb, inner);
		vec2 shadow_uv = UV - face_shadow_offset * TEXTURE_PIXEL_SIZE;
		float shadow = texture(TEXTURE, shadow_uv).a * mask_inside(shadow_uv) * face_shadow_color.a;
		float result_alpha = a + shadow * (1.0 - a);
		vec3 premultiplied = face * a + face_shadow_color.rgb * shadow * (1.0 - a);
		COLOR = vec4(premultiplied / max(result_alpha, 0.00001), result_alpha) * vertex_modulate;
	} else {
		// 透明 Viewport 存的是预乘颜色；转回直通 alpha 后沿用原 Title 的调制淡入淡出。
		vec4 cached = texture(TEXTURE, UV);
		COLOR = vec4(cached.rgb / max(cached.a, 0.00001), cached.a) * vertex_modulate;
	}
}
