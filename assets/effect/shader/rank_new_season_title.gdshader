shader_type canvas_item;
render_mode unshaded;

uniform sampler2D body_mask : filter_linear, repeat_disable;
uniform sampler2D face_mask : filter_linear, repeat_disable;
uniform vec4 outline_color;
uniform vec4 body_fill_color;
uniform vec4 face_fill_color;
uniform vec4 body_shadow_color;
uniform vec4 face_shadow_color;
uniform vec4 inner_shadow_color;
uniform vec2 body_shadow_offset;
uniform vec2 face_shadow_offset;
uniform vec2 inner_shadow_offset;
uniform float body_sigma;
uniform float face_sigma;
uniform float inner_sigma;
uniform float body_opacity = 1.0;
uniform float face_opacity = 1.0;
uniform float group_opacity = 1.0;
uniform bool body_shadow_behind = false;
uniform bool face_shadow_behind = false;
uniform vec2 raster_size;
uniform bool display_cached = false;
varying vec4 tint;

void vertex() { tint = COLOR; }

vec4 over(vec4 bg, vec4 fg) {
	float a = fg.a + bg.a * (1.0 - fg.a);
	return vec4((fg.rgb * fg.a + bg.rgb * bg.a * (1.0 - fg.a)) / max(a, 0.00001), a);
}

float alpha_at(sampler2D source, vec2 uv) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return 0.0;
	return texture(source, uv).a;
}

float blurred(sampler2D source, vec2 uv, vec2 offset, float sigma) {
	if (sigma <= 0.00001) return alpha_at(source, uv - offset / raster_size);
	float result = 0.0;
	float norm = 0.0;
	// Small-shadow kernel; executed only when rebuilding the bounded title cache.
	for (int y = -3; y <= 3; y++) for (int x = -3; x <= 3; x++) {
		vec2 pos = vec2(float(x), float(y)) * sigma;
		float weight = exp(-dot(pos, pos) / (2.0 * sigma * sigma));
		result += alpha_at(source, uv + (pos - offset) / raster_size) * weight;
		norm += weight;
	}
	return result / norm;
}

void fragment() {
	if (display_cached) {
		// SubViewport texture contains premultiplied RGB; normal canvas blend expects straight RGB.
		vec4 cached = texture(TEXTURE, UV);
		COLOR = vec4(cached.rgb / max(cached.a, 0.00001), cached.a) * tint;
	} else {
		vec4 body_sample = texture(body_mask, UV);
		float body = body_sample.a;
		float face = alpha_at(face_mask, UV);
		// These hard-alpha and inner arithmetic operations follow the reference SVG filters.
		float hard_body = clamp(body * 127.0, 0.0, 1.0);
		float hard_face = clamp(face * 127.0, 0.0, 1.0);
		float body_drop = blurred(body_mask, UV, body_shadow_offset, body_sigma);
		float face_drop = blurred(face_mask, UV, face_shadow_offset, face_sigma);
		body_drop *= body_shadow_behind ? 1.0 : 1.0 - hard_body;
		face_drop *= face_shadow_behind ? 1.0 : 1.0 - hard_face;
		float inside = max(0.0, hard_face - blurred(face_mask, UV, inner_shadow_offset, inner_sigma));
		vec4 body_layer = vec4(body_shadow_color.rgb, body_shadow_color.a * body_drop);
		// The mask RGB channels are premultiplied coverage, not display colors.
		vec4 body_ink = vec4(
			(outline_color.rgb * outline_color.a * body_sample.r + body_fill_color.rgb * body_fill_color.a * body_sample.g)
			/ max(outline_color.a * body_sample.r + body_fill_color.a * body_sample.g, 0.00001),
			outline_color.a * body_sample.r + body_fill_color.a * body_sample.g);
		body_layer = over(body_layer, body_ink);
		body_layer.a *= body_opacity;
		vec4 face_layer = vec4(face_shadow_color.rgb, face_shadow_color.a * face_drop);
		face_layer = over(face_layer, vec4(face_fill_color.rgb, face_fill_color.a * face));
		face_layer = over(face_layer, vec4(inner_shadow_color.rgb, inner_shadow_color.a * inside * face));
		face_layer.a *= face_opacity;
		vec4 result = over(body_layer, face_layer);
		result.a *= group_opacity;
		COLOR = result * tint;
	}
}
