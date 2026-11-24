shader_type canvas_item;
render_mode blend_add;
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

// The supplied rays have an opaque background. Fade it radially around their light source.
void fragment() {
	vec4 light = texture(TEXTURE, UV);
	vec2 image_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 from_center = (UV - vec2(0.49, 0.46)) * image_size;
	float radius = length(from_center) * 2.0 / min(image_size.x, image_size.y);
	float fade = 1.0 - smoothstep(0.15, 1.0, radius);
	COLOR = vec4(light.rgb * vertex_color.rgb, light.a * vertex_color.a * fade);
}
