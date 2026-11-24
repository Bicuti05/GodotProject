// 段位徽章扫光：保留贴图轮廓和页面继承的透明度。
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float band_width : hint_range(0.05, 0.5) = 0.18;
uniform float intensity : hint_range(0.0, 3.0) = 0.4;
uniform float angle : hint_range(-0.5, 0.5) = -0.25;
uniform vec4 tint_color : source_color = vec4(0.7, 0.88, 1.0, 1.0);
varying vec4 item_modulate;

void vertex() {
    item_modulate = COLOR;
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float u = UV.x - UV.y * angle;
    float center = mix(-band_width, 1.0 + band_width, progress);
    float shine = smoothstep(band_width, 0.0, abs(u - center)) * intensity;
    col.rgb = clamp(col.rgb + tint_color.rgb * shine * col.a, 0.0, 1.0);
    COLOR = col * item_modulate;
}
