shader_type canvas_item;

// 外循环换章 MorphShape 揭示遮罩(SDF 圆角矩形,支持非正方形):
// 用于"圆(circle_start) → 图框矩形"形变期,把 texture 裁切到当前形状范围内显示,
// 并叠加一层随 black_alpha 渐隐的黑色蒙层,渐隐至 0 正好对齐 _reveal_picture() 硬切换帧。
// SDF 公式与 rounded_rect_mask.gdshader 同源,size 从 float 泛化为 vec2 以支持非正方形矩形。

uniform vec2 rect_size_px = vec2(480.0, 480.0);         // 节点当前像素尺寸(逐帧由脚本刷新)
uniform float radius_px = 28.0;                          // 当前圆角像素半径(逐帧由脚本刷新)
uniform float black_alpha : hint_range(0.0, 1.0) = 1.0;  // 黑色蒙层不透明度,1→0 渐隐
uniform vec2 tex_size_px = vec2(480.0, 480.0);           // 贴图真实像素尺寸(texture 赋值时同步设一次)
// AB outer_loop_25grid(六边形外循环):起始形状换成六边形而不是圆(与首页那块六边形板子同形)。
// 1 = 纯六边形(内切当前节点矩形),0 = 纯圆角矩形(= 对照组原行为,含"圆"= 圆角半径取半边长那一档)。
// 形变期由脚本把它从 1 推到 0,与 rect_size_px / radius_px 的插值同拍 ⇒ 六边形一边长大一边捏成长矩形。
uniform float hex_amount : hint_range(0.0, 1.0) = 0.0;

// 平顶六边形 SDF(左右为尖角,与首页板子朝向一致)。r = 半高(到平边的距离),半宽 = 1.1547r。
float sd_hexagon(vec2 p, float r) {
	const vec3 k = vec3(-0.8660254, 0.5, 0.5773503);
	p = abs(p);
	p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
	p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
	return length(p) * sign(p.y);
}

void fragment() {
	// 手动做"覆盖裁切"采样(等价 stretch_mode=KEEP_ASPECT_COVERED 的视觉效果),
	// 让 UV 保持标准 0..1 供下面的遮罩 SDF 使用——若改用节点内置的 stretch_mode 裁切,
	// Godot 会把 UV 悄悄重映射到贴图上的一段子区间,使遮罩坐标算错
	// (历史踩坑:背景图非正方形时,圆形阶段渲染成了方块)。
	float node_aspect = rect_size_px.x / rect_size_px.y;
	float tex_aspect = tex_size_px.x / tex_size_px.y;
	vec2 crop_uv = UV;
	if (tex_aspect > node_aspect) {
		float visible_frac = node_aspect / tex_aspect;
		crop_uv.x = 0.5 + (UV.x - 0.5) * visible_frac;
	} else {
		float visible_frac = tex_aspect / node_aspect;
		crop_uv.y = 0.5 + (UV.y - 0.5) * visible_frac;
	}
	vec4 col = texture(TEXTURE, crop_uv);
	vec2 p = UV * rect_size_px;
	vec2 hs = rect_size_px * 0.5;
	vec2 q = abs(p - hs) - (hs - vec2(radius_px));
	float d_rect = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius_px;
	// 六边形:内切当前节点矩形 —— 把 x 预缩放,使"正六边形空间"里的尖角正好落在矩形左右边中点,
	// 于是节点是什么长宽比,六边形就跟着压扁/拉长(板子那块是 928:856,不是正六边形的 1.1547:1)。
	vec2 ph = vec2((p.x - hs.x) * (1.1547005 * hs.y / max(hs.x, 0.001)), p.y - hs.y);
	float d_hex = sd_hexagon(ph, hs.y);
	float d = mix(d_rect, d_hex, hex_amount);
	// fwidth 抗锯齿:d 越小(靠内)alpha 越接近 1,越大(靠外)越接近 0,过渡 1px。
	float aa = fwidth(d);
	float a = 1.0 - smoothstep(-aa, aa, d);
	vec3 rgb = mix(col.rgb, vec3(0.0), black_alpha);
	// alpha 乘回 COLOR.a(节点链累乘的 modulate alpha),与 rounded_rect_mask.gdshader 同理。
	COLOR = vec4(rgb, col.a * a * COLOR.a);
}
