shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D retained_clock_texture : repeat_disable, filter_linear;
uniform vec4 retained_clock_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform bool retain_clock = false;

void fragment() {
	vec4 grouped = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec4 retained = vec4(0.0);
	if (retain_clock) {
		vec2 clock_uv = (SCREEN_UV - retained_clock_rect.xy) / max(retained_clock_rect.zw, vec2(0.000001));
		if (all(greaterThanEqual(clock_uv, vec2(0.0))) && all(lessThanEqual(clock_uv, vec2(1.0)))) {
			retained = textureLod(retained_clock_texture, clock_uv, 0.0);
		}
	}
	// 两个透明渲染目标均为预乘Alpha；插值一次后转回普通混合，不能把两幅半透明图叠绘。
	vec4 merged = mix(retained, grouped, opacity);
	if (merged.a > 0.00001) {
		merged.rgb /= merged.a;
	} else {
		merged = vec4(0.0);
	}
	COLOR *= merged;
}
