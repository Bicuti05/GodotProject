shader_type canvas_item;

// Figma 20109:5734: 256×150 gradient rotated 45°, clipped by 20109:5733.
uniform float sweep_offset = 0.0;
varying vec4 item_modulate;

void vertex() {
	item_modulate = COLOR;
}

float gradient_alpha(float x) {
	if (x < 0.2) { return mix(0.0, 0.055, x / 0.2); }
	if (x < 0.43) { return mix(0.055, 0.27, (x - 0.2) / 0.23); }
	if (x < 0.5) { return mix(0.27, 0.8, (x - 0.43) / 0.07); }
	if (x < 0.57) { return mix(0.8, 0.27, (x - 0.5) / 0.07); }
	if (x < 0.8) { return mix(0.27, 0.055, (x - 0.57) / 0.23); }
	return mix(0.055, 0.0, (x - 0.8) / 0.2);
}

void fragment() {
	vec4 tint = item_modulate;
	vec2 p = vec2(5.926, 4.25) + UV * vec2(78.5641, 81.5276);
	vec2 relative = p - vec2(-177.986328, -284.052338) - vec2(sweep_offset);
	vec2 local = vec2(relative.x + relative.y, -relative.x + relative.y) * 0.707106781;
	float inside = step(0.0, local.x) * step(local.x, 256.0) * step(0.0, local.y) * step(local.y, 150.0);
	float alpha = texture(TEXTURE, UV).a * inside * gradient_alpha(clamp(local.x / 256.0, 0.0, 1.0));
	COLOR = vec4(vec3(1.0, 252.0 / 255.0, 235.0 / 255.0), alpha) * tint;
}
