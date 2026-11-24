shader_type canvas_item;

uniform vec4 mouth_rect = vec4(60.0, 78.0, 61.0, 61.0);

void fragment() {
	vec2 point = (UV / TEXTURE_PIXEL_SIZE - mouth_rect.xy) / mouth_rect.zw;
	float sides = min(point.x, 1.0 - point.x);
	float bottom = 1.0 - point.y;
	float arch = point.y < 0.5 ? 0.5 - length(point - vec2(0.5)) : sides;
	float inside = smoothstep(0.0, 0.025, min(min(sides, bottom), arch));
	COLOR.rgb = mix(COLOR.rgb, vec3(0.16, 0.055, 0.025), inside);
}
