shader_type canvas_item;

// 彩带「三轴翻滚」+ 3×3 图集取格。挂在 confetti_rain.tscn 的 GPUParticles2D 上。
//
// 三个轴各由谁负责(需求"x/y/z 三轴随机旋转"):
//   z 轴(面内自转)→ 材质的 angular_velocity + angle(随机初始朝向),**不在本 shader 里**
//   x/y 轴(翻面)  → 下面那段"绕平面内任意轴翻转"的投影压缩
//
// 为什么必须自定义 shader:ParticleProcessMaterial **没有非等比(x/y 分开)的缩放通道** ——
// scale_curve 只能等比缩放。**全程 GPU、零额外节点、零 CPU 开销**,是最省性能的做法。
//
// ⚠️ **别退回"x 乘一个 cos、y 再乘另一个独立 cos"那种写法**(2026-08 初版就是,产品反馈
// "旋转总是一个轴向")。两个**互不相关**的压缩不是 3D 旋转的投影:
//   ① 真实翻转只有**一个**压缩方向 —— 绕哪根轴转就压缩垂直于它的那一个方向;
//   ② 两个方向同时独立压缩时整片一起缩放,观感是"忽大忽小的脉动",不是"在翻";
//   ③ ef_point_002 的九格里 3 个是圆、其余是柔和弧片,**近似对称** —— 压 x 与压 y 只差 90°,
//      再叠上 z 自转就彻底分辨不出方向,于是只剩"某个轴在动"的印象。
// 正确模型:每片随机一个**轴朝向 φ**(整个寿命固定),把顶点分解到「轴向 / 垂直轴向」两个分量,
// **只压缩垂直分量** —— 这就是绕该轴翻转的正交投影。配上 z 自转即三轴翻滚。
//
// ⚠️ 挂了自定义 shader 后 CanvasItemMaterial 的 particles_animation 就不再生效,图集取格必须自己做。
// 下面那段 UV 计算照抄引擎内置实现(canvas_item_material.cpp),帧号取自 **INSTANCE_CUSTOM.z**
// (粒子的 anim_offset 写在这个通道,不是 .x),并要求材质给 anim_offset_min/max = 0/1。
//
// ⚠️ **别声明 `TAU` / `PI` / `E`** —— Godot 的着色器语言已内置它们,重复定义会让**整个 shader
// 编译失败**。而 shader 编译失败时引擎是**静默回退到默认渲染**:表现不是"没效果",而是
// 「整张 480×480 图集被缩成几十像素的九宫格缩略图糊在每片彩带上」(踩过一次,排查时一度误判成
// "vertex() 里改 UV 无效")。看到这种缩略图先查 shader 有没有编译错误,别急着改 UV 逻辑。

uniform float h_frames = 3.0;
uniform float v_frames = 3.0;
// 翻面速度区间(rad/s)。每片在区间内随机,避免整屏同步翻面。
uniform float flip_speed_min = 1.2;
uniform float flip_speed_max = 3.2;

void vertex() {
	float seed = INSTANCE_CUSTOM.z;

	// ── 图集取格(复刻内置 particles_animation)──
	float total = h_frames * v_frames;
	float frame = clamp(floor(seed * total), 0.0, total - 1.0);
	UV /= vec2(h_frames, v_frames);
	UV += vec2(mod(frame, h_frames) / h_frames, floor((frame + 0.5) / h_frames) / v_frames);

	// ── 绕平面内任意轴翻转(x/y 两轴合成的投影压缩)──
	// φ 决定"绕哪根轴翻"(每片固定、随机):φ=0 绕水平轴(看着上下翻)、φ=π/2 绕竖直轴(左右翻),
	// 其余角度是斜轴翻转 —— 这才覆盖了 x/y 两个轴向以及它们的任意组合。
	float phi = fract(seed * 5.31) * TAU;
	vec2 axis = vec2(cos(phi), sin(phi));
	vec2 perp = vec2(-axis.y, axis.x);
	// 翻转相位:cos 过零 = 纸片正好侧对镜头(不可见),变负 = 翻到背面(镜像)
	float rx = fract(seed * 7.13);
	float k = cos(TIME * mix(flip_speed_min, flip_speed_max, rx) + seed * TAU);
	// 只压缩垂直于轴的分量,轴向分量保持原长 —— 正交投影下的刚体翻转
	float along = dot(VERTEX.xy, axis);
	float across = dot(VERTEX.xy, perp) * k;
	VERTEX.xy = axis * along + perp * across;
}
