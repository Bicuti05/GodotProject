shader_type canvas_item;
render_mode unshaded, blend_add;
uniform sampler2D subject_texture;
uniform float strength = 0.0;
uniform vec2 rim_step = vec2(0.022,0.022);
varying vec4 sprite_tint;
void vertex() {
    sprite_tint = COLOR;
}
void fragment() {
    float a = texture(subject_texture,UV).a;
    float wide = 0.0;
    float tight = 0.0;
    for (int i=0; i<12; i++) {
        float angle = float(i)*0.5235987756;
        vec2 v = vec2(cos(angle),sin(angle));
        tight = max(tight,texture(subject_texture,UV+v*rim_step).a);
        wide = max(wide,texture(subject_texture,UV+v*rim_step*1.8).a);
    }
    float edge = max(tight-a,0.0);
    float diffuse = max(wide-a,0.0);
    COLOR = vec4(vec3(1.0), (edge*0.85+diffuse*0.20)*strength*sprite_tint.a);
}
