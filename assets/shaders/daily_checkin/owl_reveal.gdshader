shader_type canvas_item;
render_mode unshaded;
uniform sampler2D noise_texture;
uniform bool source_premultiplied = false;
uniform float transition = 1.0;
uniform float reveal_alpha = 1.0;
uniform vec2 noise_aspect = vec2(1.0);
// Same alpha-noise dissolve equation as Pics Mobile/Learnings_Dissolve.
// Width=1, Softness=1, EdgeStrength=.393 from DailyFirstWinOwlDissolve.mat.
varying vec4 vertex_tint;
void vertex() {
    vertex_tint = COLOR;
}
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (source_premultiplied && tex.a > 0.0001) tex.rgb /= tex.a;
    vec2 noise_uv = (UV - vec2(0.5)) * noise_aspect + vec2(0.5);
    float noise = texture(noise_texture, noise_uv).a;
    float factor = noise - transition * 2.0 + 1.0;
    float band = clamp((1.0 - factor) * 2.0, 0.0, 1.0);
    float visible = clamp(factor * 2.0, 0.0, 1.0);
    tex.rgb *= 1.0 + .393 * band * visible;
    tex.a *= visible * reveal_alpha;
    // Fragment COLOR already contains TEXTURE: multiplying it again squares RGB/alpha.
    // Match the unshaded Sprite2D when transition is zero, including at reset handoff.
    COLOR = vertex_tint * tex;
}
