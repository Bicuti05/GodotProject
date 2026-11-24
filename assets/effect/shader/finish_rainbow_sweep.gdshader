shader_type canvas_item;
render_mode unshaded;

// 仅提亮原彩虹RGB，Alpha始终来自原图；不会在透明洞或矩形边界扫出白板。
uniform float sweep_progress = -1.0;
uniform float sweep_strength = 0.32;
uniform float sweep_width = 0.14;

varying vec4 rainbow_tint;

void vertex() {
	rainbow_tint = COLOR;
}

void fragment() {
	vec4 tint = rainbow_tint;
	vec4 rainbow = texture(TEXTURE, UV);
	float band = 0.0;
	if (sweep_progress >= 0.0 && sweep_progress <= 1.0) {
		float center = mix(-0.3, 1.3, sweep_progress);
		float distance_to_band = abs(UV.x + (UV.y - 0.5) * 0.24 - center);
		band = 1.0 - smoothstep(0.0, sweep_width, distance_to_band);
	}
	COLOR = vec4(mix(rainbow.rgb, vec3(1.0), band * sweep_strength), rainbow.a) * tint;
}
