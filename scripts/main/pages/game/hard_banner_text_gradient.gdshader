shader_type canvas_item;

// 标题描边按源SVG的整段屏幕投影上色；不依赖每个曲线glyph的局部UV。
uniform vec2 screen_start = vec2(0.0);
uniform vec2 screen_end = vec2(0.0, 1.0);
uniform vec4 color_a : source_color = vec4(1.0, 0.5843137255, 0.5098039216, 1.0);
uniform vec4 color_b : source_color = vec4(0.9882352941, 0.3019607843, 0.3372549020, 1.0);
uniform bool use_mid = false;
uniform vec4 color_mid : source_color = vec4(1.0);
uniform float mid_stop : hint_range(0.001, 0.999) = 0.5;

void fragment() {
    vec2 axis = screen_end - screen_start;
    float t = clamp(dot(SCREEN_UV - screen_start, axis) / max(dot(axis, axis), 0.00000001), 0.0, 1.0);
    vec4 ramp = mix(color_a, color_b, t);
    if (use_mid) {
        ramp = t <= mid_stop
            ? mix(color_a, color_mid, t / mid_stop)
            : mix(color_mid, color_b, (t - mid_stop) / (1.0 - mid_stop));
    }
    COLOR = vec4(ramp.rgb, COLOR.a * ramp.a);
}
