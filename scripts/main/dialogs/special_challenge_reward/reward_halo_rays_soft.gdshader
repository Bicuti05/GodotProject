shader_type canvas_item;
render_mode unshaded;

varying vec4 vertex_tint;

void vertex() {
    vertex_tint = COLOR;
}

void fragment() {
    vec4 ray_color = texture(TEXTURE, UV);
    float radius = length(UV - vec2(0.5));
    ray_color.a *= smoothstep(0.035, 0.18, radius);
    COLOR = ray_color * vertex_tint;
}
