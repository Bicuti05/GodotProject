shader_type canvas_item;
render_mode unshaded;
uniform sampler2D glyph_mask_texture : filter_linear, repeat_disable;
uniform vec2 mask_pixel_size = vec2(0.001);
uniform vec4 fill_color : source_color = vec4(1.0);
uniform vec4 top_color : source_color = vec4(1.0, 0.96202, 0.74679, 1.0);
uniform vec4 bottom_color : source_color = vec4(1.0, 0.74119, 0.08654, 1.0);
uniform vec4 outline_color : source_color = vec4(0.63529, 0.21569, 0.10588, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.63529, 0.21569, 0.10588, 1.0);
uniform bool gradient_enabled = false;
uniform float first_stop = 0.0;
uniform float outline_width = 0.0;
uniform float padding = 20.0;
uniform vec2 content_size = vec2(400.0, 80.0);
uniform vec2 shadow_offset = vec2(0.0);
varying vec4 pass_color;
void vertex() { pass_color = COLOR; }
float expanded_alpha(vec2 uv) {
    float a = texture(glyph_mask_texture, uv).a;
    if (outline_width < 0.01) { return a; }
    for (int i = 0; i < 16; i++) {
        float angle = float(i) * 0.3926990817;
        vec2 offset = vec2(cos(angle), sin(angle)) * mask_pixel_size * outline_width;
        a = max(a, texture(glyph_mask_texture, uv + offset).a);
        a = max(a, texture(glyph_mask_texture, uv + offset * 0.5).a);
    }
    return a;
}
void fragment() {
    float fill_a = texture(glyph_mask_texture, UV).a;
    float border_a = expanded_alpha(UV) * outline_color.a;
    float shadow_a = 0.0;
    if (length(shadow_offset) > 0.001) {
        shadow_a = expanded_alpha(UV - shadow_offset * mask_pixel_size) * shadow_color.a;
    }
    float y = (UV.y / mask_pixel_size.y - padding) / max(content_size.y, 1.0);
    float t = clamp((y - first_stop) / max(1.0 - first_stop, 0.001), 0.0, 1.0);
    vec4 fill = gradient_enabled ? vec4(mix(top_color.rgb, bottom_color.rgb, t), 1.0) : fill_color;
    fill_a *= fill.a;
    vec3 under = outline_color.rgb * border_a + shadow_color.rgb * shadow_a * (1.0 - border_a);
    float under_a = border_a + shadow_a * (1.0 - border_a);
    vec3 premultiplied = fill.rgb * fill_a + under * (1.0 - fill_a);
    float a = fill_a + under_a * (1.0 - fill_a);
    COLOR = vec4(premultiplied / max(a, 0.00001), a) * pass_color;
}
