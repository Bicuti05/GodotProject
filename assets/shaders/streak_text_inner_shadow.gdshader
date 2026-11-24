shader_type canvas_item;

// 连胜横幅上行文字的「白色内阴影」（对应设计稿 INNER_SHADOW：白 61%、偏移 (0,4.2)、模糊 4.2、无扩散）。
//
// 挂在 CanvasGroup 上：组内那层白色字形先被渲染成纹理，这里再按
// 「当前像素在字形内、沿偏移方向采样的邻域在字形外」的差值算出内阴影强度。
// 直接挂在 Label 上做不到——Label 的 TEXTURE 是字体图集，不是字形覆盖度。

uniform vec4 shadow_color : source_color = vec4(1.0, 1.0, 1.0, 0.61);
// 阴影偏移（像素，屏幕坐标向下为正）
uniform vec2 shadow_offset = vec2(0.0, 4.2);
// 阴影模糊半径（像素）：用环形多点采样近似高斯
uniform float shadow_blur = 4.2;
// 判定「这里算字形内部」的 alpha 阈值
uniform float glyph_alpha = 0.5;
// 纹理像素尺寸（由脚本按源纹理大小写入，避免依赖 TEXTURE_PIXEL_SIZE）
uniform vec2 tex_size = vec2(800.0, 184.0);

// Capture canvas opacity before the texture is sampled, including ancestor fades.
varying float canvas_opacity;

void vertex() {
	canvas_opacity = COLOR.a;
}

void fragment() {
	float a = textureLod(TEXTURE, UV, 0.0).a;
	if (a < 0.01) {
		COLOR = vec4(0.0);
	} else {
		vec2 px = 1.0 / max(tex_size, vec2(1.0));
		// 环形 12 点采样：取「字形按 offset 平移后」在同一像素处的 alpha。
		// 平移后的形状 = 原形状整体 +offset，所以采样点是 UV - offset（不是 +offset）。
		float sum = 0.0;
		for (int i = 0; i < 12; i++) {
			float ang = float(i) * 0.5235988; // TAU / 12
			vec2 d = (shadow_offset + vec2(cos(ang), sin(ang)) * shadow_blur) * px;
			sum += textureLod(TEXTURE, UV - d, 0.0).a;
		}
		float outside = clamp((1.0 - sum / 12.0) / max(1.0 - glyph_alpha, 0.01), 0.0, 1.0);
		// 只在字形内部出现（外沿由描边层负责）
		float s = clamp(a * outside, 0.0, 1.0);
		COLOR = vec4(shadow_color.rgb, shadow_color.a * s * canvas_opacity);
	}
}
