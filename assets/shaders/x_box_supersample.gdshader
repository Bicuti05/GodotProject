shader_type canvas_item;

// 通用「横向盒式超采样」shader:沿**屏幕 x 方向**在一个像素的足迹内均匀取 TAPS 个样本求平均,
// 等价于把这个像素本该覆盖的那一段纹理积分一遍,而不是只在中心点采一次。
//
// 为什么需要它(当前唯一消费者:`JuiceBoardView`,见 `_draw_rope()`):
// 绳子微风摆动走的是剪切变换 ⇒ 每一行、每一帧的横向亚像素相位都不同;而绳贴图左轮廓是
// 一条约 1 纹素的高光边,默认 Linear 过滤在不同相位下重采样出的亮度差极大 ⇒ 边缘看着在
// 沸腾、爬毛刺。做完一个像素宽的盒式平均后,边缘亮度只随亚像素位置**线性平滑**变化,
// 也就是正常的抗锯齿边,闪动消失。
//
// 采样步长取 `dFdx(UV)`:它自带剪切与真机 canvas 缩放(非整数),所以本 shader 不需要知道
// 任何缩放系数,也不依赖「整数像素吸附」—— 那套吸的是逻辑像素,在真机上本来就失效。
//
// 只在 x 方向做,两个原因:① 绳子纵向基本 1:1、没有纵向重采样问题;② 横向采样不会跨过
// `draw_texture_rect_region` 的**纵向**裁剪边界(平铺接缝 / 绳身末行),不会把下一段的
// 像素吃进来。横向越界只会吃到贴图自己右侧那条影子列,恰好把硬裁边也软化掉。
//
// 预乘后再平均:直接平均 RGB 会把透明像素的颜色混进边缘,形成暗边/彩边。
//
// ⚠️ 挂在 `JuiceBoardView` 根节点上 ⇒ 只作用于它自己 `_draw()` 里的绘制(目前只有绳三段),
// 子节点(货架板 / 花朵 / 高亮胶囊 / 特效)各有自己的 material,不受影响。
// 万一以后 `_draw()` 里加了无贴图的命令(如 `draw_rect` / `draw_style_box`)也是安全的:
// TEXTURE 是默认白图、UV 恒定 ⇒ 各 tap 完全相同 ⇒ 结果等于 `COLOR`,与默认 canvas shader 一致。

const int TAPS = 4;
varying vec4 vertex_tint;

void vertex() {
	// vertex阶段的COLOR尚未乘纹理，保留绘制色与节点调制色（含淡出Alpha）。
	vertex_tint = COLOR;
}

void fragment() {
	vec2 du = dFdx(UV) / float(TAPS);
	vec2 uv = UV - du * (float(TAPS) - 1.0) * 0.5;
	vec4 acc = vec4(0.0);
	for (int i = 0; i < TAPS; i++) {
		vec4 c = texture(TEXTURE, uv + du * float(i));
		acc += vec4(c.rgb * c.a, c.a);
	}
	acc /= float(TAPS);
	vec3 rgb = acc.a > 0.0 ? acc.rgb / acc.a : vec3(1.0);
	// fragment输入COLOR已含默认纹理采样；只乘保存的调制色，避免纹理颜色被重复相乘。
	COLOR = vec4(rgb, acc.a) * vertex_tint;
}
