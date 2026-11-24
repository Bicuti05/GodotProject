shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
varying vec4 display_tint;
void vertex() { display_tint = COLOR; }
void fragment() {
    vec4 image = texture(TEXTURE, UV);
    COLOR = vec4(image.rgb * display_tint.rgb * display_tint.a, image.a * display_tint.a);
}
