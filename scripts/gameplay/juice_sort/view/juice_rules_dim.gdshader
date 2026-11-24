shader_type canvas_item;
render_mode unshaded;

uniform float dim_amount = 0.0;

void fragment() {
	// 只淡化该条规则的真实像素，让原卡片底色透出；字形、透明边和缩放始终跟随内容。
	COLOR.a *= 1.0 - 0.9 * dim_amount;
}
