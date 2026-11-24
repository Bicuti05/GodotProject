shader_type canvas_item;
render_mode unshaded;

// 柔光已离线烘焙成彩色贴图（见 tools/bake_group_halo_textures.py 与 view/CLAUDE.md）：
// 贴图自带花色着色、32 层轮廓扩张与两段光晕，运行时只剩 1 次采样。
// 强度仍沿用原口径线性缩放，并保留 HALO_ALPHA_LIMIT 这道上限。
uniform float halo_strength : hint_range(0.0, 2.0) = 0.0;

const float HALO_ALPHA_LIMIT = 0.74;

void fragment() {
	vec4 baked = texture(TEXTURE, UV);
	float alpha = clamp(baked.a * halo_strength, 0.0, HALO_ALPHA_LIMIT);
	// 原实现只把父链 Alpha 乘到输出上，不改变贴图本身的颜色。
	COLOR = vec4(baked.rgb, alpha * COLOR.a);
}
