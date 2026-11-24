shader_type canvas_item;

// AB outer_loop_25grid(首页外循环六边形):把下一章缩略图裁成「大六边形 25 格」的形状。
// 挂在 HexBoard/Picture(TextureRect,尺寸 == mask 贴图尺寸 928×856,expand_mode = IGNORE_SIZE)上。
// **同一份材质也挂在 HexBoard/GridShadow 上**:那张 hex_grid_shadow.png 尺寸恰为 928×856,
// tex_ar == rect_ar ⇒ 下面的 cover 采样退化成恒等采样,只剩"alpha 乘遮罩"这一件事 —— 正是它需要的
// (不裁的话它 52% 的描边压在格缝白边上,外圈交点会被啃出一个白色尖角,见 hex_board.gd 的 GridShadow 段)。
//
// 做两件事,都不带任何魔法常量:
//   1) mask 采样:mask_tex(hex_mask.png)的 alpha 即「25 格实体区域」,格间白缝在 mask 里是透明的
//      → 直接乘到输出 alpha,得到软边六边形(对齐 solitaire 的 UI/HexMask shader 思路:
//        用贴图 alpha 而不是 Stencil / Light2D 遮罩,规避锯齿)。
//   2) cover 采样:缩略图任意长宽比都居中裁剪填满本 rect、不失真。node 长宽比直接取 mask 贴图的
//      长宽比 —— node 尺寸由 .tscn 设成与 mask 等大,故两者恒等,不需要再传一个 rect_aspect uniform
//      (少一处需要跟 .tscn 手工同步的常量)。
//
// 揭格动画不在本 shader 里:25 个盖子是 HexBoard/Covers 下的独立节点,由脚本逐个缩放 + 淡出。
// 本 shader 只负责「图被裁成六边形」这一件事,盖子揭开后露出的就是这张图。

uniform sampler2D mask_tex : hint_default_white, filter_linear;

void fragment() {
	vec2 uv = UV;
	vec2 mask_size = vec2(textureSize(mask_tex, 0));
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	float rect_ar = mask_size.x / mask_size.y;
	float tex_ar = tex_size.x / tex_size.y;
	// 贴图比 rect 更宽 → 横向缩采样窗口(裁掉左右);更高 → 纵向缩(裁掉上下)
	vec2 scale = (tex_ar > rect_ar) ? vec2(rect_ar / tex_ar, 1.0) : vec2(1.0, tex_ar / rect_ar);
	vec2 sample_uv = (uv - vec2(0.5)) * scale + vec2(0.5);

	// ⚠️ **不能写 `texture(TEXTURE, sample_uv) * COLOR`**:Godot canvas_item 的入口 COLOR 已经是
	// `texture(TEXTURE, UV) * modulate`(同 bubble.gdshader 记的坑)。
	// 这里换了 UV 重新采样,再乘 COLOR 等于「cover 采样的图 × 原 UV 采样的同一张图」——两份的偏移
	// 在中心为 0、向边缘线性张开到 ±(1-scale)/2(本例竖向最大 ±33px),肉眼就是"一张复制体略微
	// 错位盖在原图上"的重影,同时整图被压成 value²(实测灰 127 → 63,整块图发暗)。
	// 故:rgb 直接用 cover 采样的结果,alpha 只把节点链累乘的 modulate.a 反解出来乘回去
	// (首页整页淡入靠它;和上面几个 shader 同一套写法)。
	vec4 src = texture(TEXTURE, uv);
	float mod_a = src.a > 0.0001 ? COLOR.a / src.a : 1.0;
	vec4 c = texture(TEXTURE, sample_uv);
	c.a *= mod_a * texture(mask_tex, uv).a;
	COLOR = c;
}
