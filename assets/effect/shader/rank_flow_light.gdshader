shader_type canvas_item;
render_mode blend_add;

// 第 1 名那一行的常驻「流光」(移植 jigsolitaire `Effect_ranklist_first_003.prefab` 的材质
// `em_glow_603_add`,shader 是它家的 uber-shader `Art/Shader/Learnings_Common.shader`)。
//
// **原型的动画不在 Animator 里**:那个 GameObject 上的 Animator `m_Controller: {fileID: 0}` ——
// 没有控制器,代码里的 `animator.Play(0, -1, 0f)` 是空操作。动画全由 uber-shader 内部按 TIME 跑。
//
// 该材质只开了 mask 这一路(`_UseDissolve` / `_UseDisturbance` / `_UseTexRamp` 全 0),故这一段
// **可以精确移植**(与 rank/CLAUDE.md「已知未完成」里那个 40 参数、dissolve+disturbance+ramp 全开的
// 「徽章扫光」不同,那个仍不可移植)。原型 shader 的对应三行:
//
//   float2 rot   = rotate(uv_Mask, _MaskRotate * PI * 2.0);
//   half2 scroll = half2(_MaskSpeedU, _MaskSpeedV) * _Time.y;
//   o.Alpha = MainTex.a * tex2D(_Mask, rot + scroll).r * vertexColor.a * _MainTexColor.a;
//   Blend SrcAlpha [_Overlay_Mode]      // _Overlay_Mode = 1 = Additive
//
// 材质实读值:`_MaskRotate = 0.431`(×2π ≈ 155.2°)/ `_MaskSpeedU = 0.5` / `_MaskSpeedV = 0`
// (贴图槽的 tiling/offset 也复查过,`_MainTex_ST` / `_Mask_ST` 都是 (1,1,0,0),没有额外缩放)。
//
// 表现:遮罩 `et_mask_702` 是一条竖亮带(横向剖面只有 x 80..190 有值),旋转 155° 后成为一条**细斜带**,
// 以 0.5 UV/s 扫过整条(周期 2s),任一瞬间只点亮约 7% 面积 —— **这就是原型效果,是对的**。
// (2026-08-11 曾试加 `mask_floor` / `sweep_gain` 让整条常亮,产品要求回退原型口径,勿再加。)

uniform sampler2D mask_tex : repeat_enable, filter_linear;
/// 遮罩 UV 旋转(圈数,×TAU 后即弧度)。原型 `_MaskRotate`。
uniform float mask_rotate : hint_range(0.0, 1.0) = 0.431;
/// 遮罩 UV 滚动速度(UV/秒)。原型 `_MaskSpeedU` / `_MaskSpeedV`。
uniform vec2 mask_speed = vec2(0.5, 0.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	// 绕 UV 中心旋转(原型的 rotator 节点默认 pivot 是 0.5,0.5)
	float a = mask_rotate * TAU;
	vec2 c = UV - vec2(0.5);
	vec2 uv_mask = vec2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a)) + vec2(0.5);
	uv_mask += mask_speed * TIME;
	// 只取遮罩的 R 通道乘进 alpha(原型 `.r`),颜色仍来自主贴图
	COLOR = vec4(base.rgb, base.a * texture(mask_tex, uv_mask).r) * COLOR;
}
