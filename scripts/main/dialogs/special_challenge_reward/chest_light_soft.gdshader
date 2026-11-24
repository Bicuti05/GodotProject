shader_type canvas_item;
render_mode unshaded;

uniform vec4 atlas_region = vec4(1024.0, 398.0, 897.0, 445.0);
uniform float blur_radius = 6.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec2 local_uv = (UV / TEXTURE_PIXEL_SIZE - atlas_region.xy) / atlas_region.zw;
	float softness = smoothstep(0.72, 1.0, local_uv.y);
	vec2 radius = TEXTURE_PIXEL_SIZE * blur_radius * softness;
	vec2 lower = (atlas_region.xy + vec2(0.5)) * TEXTURE_PIXEL_SIZE;
	vec2 upper = (atlas_region.xy + atlas_region.zw - vec2(0.5)) * TEXTURE_PIXEL_SIZE;
	vec4 sampled = vec4(0.0);
	for (int row = -1; row <= 1; row++) {
		for (int column = -1; column <= 1; column++) {
			float weight = float((row == 0 ? 2 : 1) * (column == 0 ? 2 : 1));
			vec2 sample_uv = clamp(UV + vec2(float(column), float(row)) * radius, lower, upper);
			vec4 pixel = texture(TEXTURE, sample_uv);
			sampled += vec4(pixel.rgb * pixel.a, pixel.a) * weight;
		}
	}
	sampled /= 16.0;
	COLOR = vec4(sampled.rgb / max(sampled.a, 0.00001), sampled.a * (1.0 - smoothstep(0.82, 1.0, local_uv.y))) * vertex_tint;
}
