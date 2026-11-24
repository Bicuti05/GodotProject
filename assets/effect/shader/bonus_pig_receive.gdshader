shader_type canvas_item;
render_mode blend_add;
uniform float progress = 0.0;
uniform float strength = 0.0;
void fragment() {
    float alpha = texture(TEXTURE, UV).a;
    float center = mix(0.08, 0.85, progress);
    float band = 1.0 - smoothstep(0.0, 0.20, abs(UV.y - center));
    COLOR = vec4(1.0, 0.76, 0.22, alpha * band * strength);
}
