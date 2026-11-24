shader_type canvas_item;
render_mode unshaded;

uniform float alpha_floor : hint_range(0.0, 1.0) = 0.40;
uniform float alpha_core : hint_range(0.0, 1.0) = 0.56;
uniform vec4 ripple_tint : source_color = vec4(1.0, 1.0, 0.80, 1.0);

// fragment 的默认 COLOR 已含纹理，保留顶点调制，避免再次采样相乘使 RGB/alpha 平方。
varying vec4 effect_modulate;

void vertex() {
	effect_modulate = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	tex.rgb *= ripple_tint.rgb;
	tex.a *= smoothstep(alpha_floor, alpha_core, tex.a);
	COLOR = effect_modulate * tex;
}
