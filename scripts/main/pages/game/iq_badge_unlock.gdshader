shader_type canvas_item;
uniform float unlock_progress : hint_range(0.0, 1.0) = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	// Preserve the white IQ lettering and darkest shadow; tint gray petals only.
	float lightness = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float petal = (1.0 - smoothstep(0.82, 0.96, lightness)) * smoothstep(0.12, 0.32, lightness);
	vec3 red = vec3(min(1.0, lightness * 1.48), lightness * 0.22, lightness * 0.32);
	COLOR = tint * vec4(mix(source.rgb, red, petal * unlock_progress), source.a);
}
