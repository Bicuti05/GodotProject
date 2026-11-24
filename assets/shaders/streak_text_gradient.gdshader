shader_type canvas_item;

// 连胜横幅文字的竖向渐变填充。
// 设计稿文字是竖向渐变 + 深棕描边，而 CurveLabel 只支持纯色填充：
// 这里按亮度把字形分两档——亮部（填充）替换成渐变，暗部（深棕描边）原样保留。
// 描边在抗锯齿边缘与填充混合，用 smoothstep 过渡避免出现硬边。
//
// ⚠️ 不能用节点局部坐标：CurveLabel 为了让字符沿弧线倾斜，每个字形都套了一层
// `draw_set_transform`，顶点坐标是「相对该字形原点」的，拿它算渐变会导致每个字各染一遍、
// 整行看起来是纯色。改为用屏幕 UV：由 game_start_banner.gd 每帧把两条文字的墨迹上下沿
// （含横幅滑入滑出时的位移）换算成 UV 写进 ink_*_uv。

uniform vec4 grad_top : source_color = vec4(1.0, 0.941, 0.35, 1.0);
uniform vec4 grad_mid : source_color = vec4(1.0, 0.831, 0.12, 1.0);
uniform vec4 grad_bottom : source_color = vec4(1.0, 0.55, 0.02, 1.0);
// true = 三档渐变（经过 grad_mid）；false = 只用上下两档线性过渡
uniform bool use_mid = true;
// 渐变起止（屏幕 UV 的 y，运行时由脚本按文字实际位置写入）
uniform float ink_top_uv = 0.0;
uniform float ink_bottom_uv = 0.02;
// 亮度阈值：低于此值认为是描边色，不做替换（填充必须明显亮于描边）
uniform float outline_luma = 0.55;

void fragment() {
	vec4 src = COLOR;
	float luma = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	float t = clamp((SCREEN_UV.y - ink_top_uv) / max(ink_bottom_uv - ink_top_uv, 0.0001), 0.0, 1.0);
	vec3 mid = use_mid ? grad_mid.rgb : mix(grad_top.rgb, grad_bottom.rgb, 0.5);
	vec3 ramp = t < 0.5
			? mix(grad_top.rgb, mid, t / 0.5)
			: mix(mid, grad_bottom.rgb, (t - 0.5) / 0.5);
	// 亮度高于 outline_luma 的像素（填充）走渐变，低于的（描边）保持原色
	float k = smoothstep(outline_luma - 0.10, outline_luma + 0.06, luma);
	COLOR.rgb = mix(src.rgb, ramp, k);
}
