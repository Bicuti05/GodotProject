shader_type canvas_item;

// 圆角矩形遮罩(SDF):在 fragment 里直接算 alpha,不依赖 clip_children/stencil。
// 用于完成页 PhotoWall 等"批量小卡圆角"场景 —— clip_children 每张卡一次离屏 pass,
// Mali-T830 上吃满 ROP;改 SDF 后 12 张卡也是单 batch,无离屏。
//
// 用法:挂在矩形 TextureRect 上,把 size_px 传成节点像素尺寸(vec2),radius_px 传圆角。
// 节点尺寸变化时由调用方刷新 uniform。
//
// ⚠️ **size_px 是 vec2,不是 float**(2026-08-24 由 float 改):AB puzzle_grid_2x3 引入 2:3 图后,
// 完成页卡片不再恒为正方形 —— 用单值会让非方形卡的圆角被拉成椭圆。SDF 公式本身对任意矩形都成立,
// 改的只是把「假设高=宽」换成逐轴传入。**改回 float 会让 2:3 卡的圆角椭圆化。**
//
// ⚠️ **像素坐标取自 vertex() 传下来的 `VERTEX`(节点局部坐标),不能用 `UV * size_px`**
// (2026-08-27 修):`TextureRect` 在 `STRETCH_KEEP_ASPECT_COVERED` 下走 `draw_texture_rect_region`,
// 喂给 fragment 的 UV 是**纹理**的归一化坐标(被 region 裁过),**只有节点宽高比 == 纹理宽高比时
// 才恰好是 0..1**。完成页 PhotoWall 的方图卡(node 456×456 / tex 512×512)恰好满足,故 UV 写法
// 一直没暴露;而 2:3 卡(node 296×456 / tex 512×768,四周等宽 12px 留白改变了宽高比)实测 UV.x 被裁成
// **[0.0157, 0.9843]** ⇒ mask 的 x 轴整体内移 4.6px 并压缩 1.6%,左右两条边各有一段直角没被裁到、
// 圆角还略微椭圆化(左列首个不透明像素 y=16 vs 方图 26,顶行 x=23),视觉上「照片角比相框角方」、
// 角上白边变窄。`VERTEX` 是节点局部坐标,与 stretch_mode / region 完全解耦,任意宽高比都对。
//
// 算法:VERTEX(0..size_px) → 像素坐标 p,以 rect 中心为原点的距离向量 q;rect 半尺寸 hs;
//   d = length(max(|q| - (hs - r), 0)) - r  ← 标准圆角矩形 SDF(d<=0 内,d>0 外)
// 用 fwidth(d) 做 1px 抗锯齿过渡;不引入额外像素采样。

uniform vec2 size_px = vec2(480.0, 480.0);   // TextureRect 像素尺寸(逐轴,支持非方形)
uniform float radius_px = 28.0;             // 圆角像素半径(四角等半径)

varying vec2 v_local_px;

void vertex() {
	v_local_px = VERTEX;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 p = v_local_px;
	vec2 hs = size_px * 0.5;
	vec2 q = abs(p - hs) - (hs - vec2(radius_px));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius_px;
	// fwidth 抗锯齿:d 越小(靠内)alpha 越接近 1,越大(靠外)越接近 0,过渡 1px。
	float aa = fwidth(d);
	float a = 1.0 - smoothstep(-aa, aa, d);
	// alpha 必须乘回入参 COLOR.a(节点链累乘的 modulate alpha)——否则 PhotoWall 渐显时
	// _top_row/_bottom_row 的 modulate.a 0→1 对照片无效,只有金边相框在渐显。
	// rgb 保持原图不动:乘 COLOR.rgb 会因 modulate tint / 色彩空间差异把照片压暗。
	COLOR = vec4(col.rgb, col.a * a * COLOR.a);
}
