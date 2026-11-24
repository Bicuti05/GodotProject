shader_type canvas_item;

// 连胜横幅中央数字的渐变字面（Lv2 / Lv3）。
//
// 与 `streak_text_gradient.gdshader` 的分工：那个按屏幕 UV 上色，供 CurveLabel 曲线文字
// 共用；数字是直排 Label，滚动时整块移动，因此这里按 **Label 局部坐标** 计算渐变——
// 父级入场缩放/位移与滚动位移都不会影响渐变落点，也不需要逐帧同步 UV。
//
// Figma 数字层是 LINEAR 填充：方向和起止位置都相对文字框（含行高）计算，
// 由 `streak_roll_number.gd` 按档位把 box_* / grad_* 写进来。

// 渐变上下两档（Lv1 传同一颜色即纯色）
uniform vec4 grad_top : source_color = vec4(1.0, 0.402799, 0.11859, 1.0);
uniform vec4 grad_bottom : source_color = vec4(1.0, 0.402799, 0.11859, 1.0);
// 文字框在 Label 局部坐标中的左上角与尺寸（逻辑像素）
uniform vec2 box_origin = vec2(0.0, 0.0);
uniform vec2 box_size = vec2(270.0, 272.0);
// 渐变方向（局部空间单位向量，y 向下）与起止位置（占文字框投影长度的 0~1）
uniform vec2 grad_dir = vec2(0.0, 1.0);
uniform float grad_from = 0.0;
uniform float grad_to = 1.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// 片元沿渐变方向投影到文字框上，换算成线性渐变的 0~1 位置
	vec2 local = local_pos - box_origin;
	float lo = min(0.0, box_size.x * grad_dir.x) + min(0.0, box_size.y * grad_dir.y);
	float hi = max(0.0, box_size.x * grad_dir.x) + max(0.0, box_size.y * grad_dir.y);
	float raw = clamp((dot(local, grad_dir) - lo) / max(hi - lo, 0.0001), 0.0, 1.0);
	float t = clamp((raw - grad_from) / max(grad_to - grad_from, 0.0001), 0.0, 1.0);
	COLOR.rgb = mix(grad_top.rgb, grad_bottom.rgb, t);
}
