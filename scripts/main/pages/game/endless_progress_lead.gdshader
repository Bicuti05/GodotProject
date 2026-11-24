shader_type canvas_item;
render_mode unshaded;

// 沿用倒计时胶囊的透明轮廓和高光，只把新增的那一截画成白色。
varying vec4 tint;
uniform float clip_u = 1.0;

void vertex() {
	tint = COLOR;
}

void fragment() {
	if (UV.x < clip_u) {
		discard;
	}
	vec4 tex = texture(TEXTURE, UV);
	float shade = max(tex.r, max(tex.g, tex.b));
	COLOR = vec4(vec3(shade), tex.a) * tint;
}
