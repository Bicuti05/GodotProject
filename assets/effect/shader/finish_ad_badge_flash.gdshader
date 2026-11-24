shader_type canvas_item;

uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec4 badge = texture(TEXTURE, UV);
	badge.rgb = mix(badge.rgb, vec3(1.0), flash_strength);
	COLOR = vertex_color * badge;
}
