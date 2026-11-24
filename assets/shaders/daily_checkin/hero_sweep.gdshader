shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float progress = -0.4;
uniform float strength = 0.0;
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float diagonal = UV.x * 0.78 + (1.0 - UV.y) * 0.22;
    float band = exp(-pow((diagonal - progress) / 0.085, 2.0));
    COLOR = vec4(vec3(1.0, 0.94, 0.73), tex.a * band * strength);
}
