shader_type canvas_item;
render_mode unshaded, blend_mix;

varying vec4 halo_tint;

void vertex() {
	halo_tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float radius = length(UV * 2.0 - 1.0);
	float feather = 1.0 - smoothstep(0.80, 1.0, radius);
	COLOR = vec4(source.rgb * halo_tint.rgb, source.a * halo_tint.a * feather);
}
