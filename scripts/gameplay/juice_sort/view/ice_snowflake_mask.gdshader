shader_type canvas_item;
render_mode unshaded, blend_mix;

varying vec4 snow_tint;

void vertex() {
	snow_tint = COLOR;
}

void fragment() {
	float coverage = texture(TEXTURE, UV).a;
	COLOR = vec4(snow_tint.rgb, snow_tint.a * coverage);
}
