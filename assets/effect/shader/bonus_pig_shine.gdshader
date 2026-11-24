// Adapted from Bubble Pics RankBadgeView image_shine: no optional shape-mask dependencies.
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float band_width = 0.18;
uniform float intensity = 0.4;
uniform float angle = -0.25;
uniform vec4 tint_color : source_color = vec4(1.0, 0.96, 0.86, 1.0);
// COLOR in fragment already includes TEXTURE. Capture modulation before sampling.
varying vec4 vertex_modulate;
void vertex() {
    vertex_modulate = COLOR;
}
void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float u = UV.x - UV.y * angle;
    float center = mix(-band_width, 1.0 + band_width + abs(angle), progress);
    float shine = (1.0 - smoothstep(0.0, band_width, abs(u - center))) * intensity;
    col.rgb = clamp(col.rgb + tint_color.rgb * shine * col.a, 0.0, 1.0);
    COLOR = col * vertex_modulate;
}
