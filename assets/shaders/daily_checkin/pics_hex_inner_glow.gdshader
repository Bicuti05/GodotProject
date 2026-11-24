shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform vec3 glow_tint = vec3(1.0);
uniform float iridescence = 0.0;
uniform float color_phase = 0.0;
void fragment() {
    vec4 tex = texture(TEXTURE,UV);
    // Source additive glow stores the shape in RGB on an opaque black canvas.
    // Convert luminance to coverage when adapting it to ordinary alpha blending.
    float texture_mask = tex.a*max(tex.r,max(tex.g,tex.b));
    float radius = length((UV-vec2(0.5))*vec2(1.0,1.12));
    float softness = 0.22+0.78*smoothstep(0.12,0.46,radius);
    // Pastel iridescence belongs only to the masked halo, never the subject or particles.
    vec2 centered = UV - vec2(0.5);
    float angle = atan(centered.y, centered.x) + color_phase;
    float blend = 0.5 + 0.5 * sin(angle);
    vec3 pink = vec3(1.0, 0.76, 0.91);
    vec3 aqua = vec3(0.72, 0.94, 1.0);
    vec3 pastel = mix(pink, aqua, blend);
    float warm_edge = smoothstep(0.10, 0.48, centered.y);
    pastel = mix(pastel, vec3(1.0, 0.93, 0.76), warm_edge * 0.65);
    // Color-only refinement: leave the central peak white and tint the outer halo.
    // Original texture coverage, softness and alpha are deliberately unchanged.
    float outer_color = iridescence * smoothstep(0.14, 0.40, radius);
    vec3 tint = mix(glow_tint, pastel, outer_color);
    COLOR = vec4(tint,texture_mask*softness*COLOR.a);
}
