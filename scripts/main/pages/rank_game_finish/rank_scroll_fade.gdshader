shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float top_uv = 0.0;
uniform float bottom_uv = 1.0;
uniform float fade_uv = 0.0;

void fragment() {
	// CanvasGroup's back buffer contains premultiplied RGB; restore straight RGB
	// before the normal canvas alpha blend and fade the combined content once.
	vec4 content = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (content.a > 0.0001) {
		content.rgb /= content.a;
	}
	float width = max(fade_uv, 0.000001);
	float top_alpha = smoothstep(top_uv, top_uv + width, SCREEN_UV.y);
	float bottom_alpha = 1.0 - smoothstep(bottom_uv - width, bottom_uv, SCREEN_UV.y);
	COLOR *= content;
	COLOR.a *= top_alpha * bottom_alpha;
}
