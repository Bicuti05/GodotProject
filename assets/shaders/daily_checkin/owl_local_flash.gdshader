shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float strength = 0.0;
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(vec3(1.0), tex.a * strength * COLOR.a);
}
