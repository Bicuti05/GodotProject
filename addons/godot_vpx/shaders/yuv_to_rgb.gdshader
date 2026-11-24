shader_type canvas_item;

uniform sampler2D y_texture : filter_nearest, repeat_disable;
uniform sampler2D u_texture : filter_nearest, repeat_disable;
uniform sampler2D v_texture : filter_nearest, repeat_disable;
uniform sampler2D a_texture : filter_nearest, repeat_disable;
uniform bool has_alpha = false;
uniform bool use_bt709 = false;

void fragment() {
    float y = texture(y_texture, UV).r;
    float u = texture(u_texture, UV).r - 0.5;
    float v = texture(v_texture, UV).r - 0.5;

    vec3 rgb;
    if (use_bt709) {
        rgb.r = y + 1.5748 * v;
        rgb.g = y - 0.1873 * u - 0.4681 * v;
        rgb.b = y + 1.8556 * u;
    } else {
        rgb.r = y + 1.402 * v;
        rgb.g = y - 0.344136 * u - 0.714136 * v;
        rgb.b = y + 1.772 * u;
    }

    float a = 1.0;
    if (has_alpha) {
        a = texture(a_texture, UV).r;
    }

    COLOR = vec4(clamp(rgb, vec3(0.0), vec3(1.0)), a);
}
