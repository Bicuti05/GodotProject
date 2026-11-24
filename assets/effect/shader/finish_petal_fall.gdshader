shader_type canvas_item;

// 顶部花瓣「三轴翻滚」+ 3×3 图集取格。挂在 confetti_fall.tscn 的 GPUParticles2D 上。
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

// 尚未绑定配方/发射器变换时不绘制；由 confetti_fall.gd 更新本实例独立材质。
uniform float particle_scale_max = 0.0;
uniform vec4 inverse_emitter_basis = vec4(1.0, 0.0, 0.0, 1.0);
varying float petal_instance_valid;

// 2% 余量覆盖实例变换的半精度存储与矩阵运算误差，不将异常尺寸夹回合法范围。
bool particle_scale_is_valid(float x_squared, float y_squared, float max_scale) {
	float limit = max_scale * 1.02;
	return max_scale > 0.0 && !isinf(max_scale) && x_squared > 0.0 && y_squared > 0.0
		&& x_squared <= limit * limit && y_squared <= limit * limit;
}

// 复用原顶部彩带八色，GPU粒子anim_offset给每片固定随机颜色。
uniform vec4 petal_color_0 : source_color = vec4(0.941176, 0.439216, 0.941176, 1.0);
uniform vec4 petal_color_1 : source_color = vec4(0.941176, 0.815686, 0.188235, 1.0);
uniform vec4 petal_color_2 : source_color = vec4(0.941176, 0.188235, 0.188235, 1.0);
uniform vec4 petal_color_3 : source_color = vec4(0.941176, 0.941176, 0.439216, 1.0);
uniform vec4 petal_color_4 : source_color = vec4(0.941176, 0.564706, 0.439216, 1.0);
uniform vec4 petal_color_5 : source_color = vec4(0.439216, 0.815686, 0.941176, 1.0);
uniform vec4 petal_color_6 : source_color = vec4(0.062745, 0.815686, 0.815686, 1.0);
uniform vec4 petal_color_7 : source_color = vec4(0.188235, 0.815686, 0.062745, 1.0);
varying vec4 petal_tint;

void vertex() {
	// MODEL_MATRIX 已包含粒子实例变换；仅局部坐标扣除发射器基底，全局坐标传入单位基底。
	mat2 emitter_inverse = mat2(inverse_emitter_basis.xy, inverse_emitter_basis.zw);
	vec2 particle_x = emitter_inverse * MODEL_MATRIX[0].xy;
	vec2 particle_y = emitter_inverse * MODEL_MATRIX[1].xy;
	petal_instance_valid = particle_scale_is_valid(dot(particle_x, particle_x),
		dot(particle_y, particle_y), particle_scale_max) ? 1.0 : 0.0;

	float color_index = floor(fract(INSTANCE_CUSTOM.z * 7.13) * 8.0);
	vec4 palette = petal_color_0;
	if (color_index < 1.0) palette = petal_color_0;
	else if (color_index < 2.0) palette = petal_color_1;
	else if (color_index < 3.0) palette = petal_color_2;
	else if (color_index < 4.0) palette = petal_color_3;
	else if (color_index < 5.0) palette = petal_color_4;
	else if (color_index < 6.0) palette = petal_color_5;
	else if (color_index < 7.0) palette = petal_color_6;
	else palette = petal_color_7;
	petal_tint = COLOR * palette;
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
	if (petal_instance_valid < 0.5) {
		VERTEX = vec2(0.0);
	}
}


// 复用原花瓣形状与明暗，随机花色由ParticleProcessMaterial给出，不被金色图集染偏。
void fragment() {
	if (petal_instance_valid < 0.5) {
		discard;
	}
	vec4 particle_tint = petal_tint;
	vec4 petal = texture(TEXTURE, UV);
	float brightness = max(petal.r, max(petal.g, petal.b));
	COLOR = vec4(particle_tint.rgb * mix(0.80, 1.0, brightness), particle_tint.a * petal.a);
}
