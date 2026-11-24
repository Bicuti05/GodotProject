shader_type canvas_item;

// 通用「禁用置灰」shader:去饱和 + 向浅灰抬升,保留原 alpha(故按钮保持不透明,不会透出身后底板)。
// 配合 use_parent_material:挂在按钮根节点,可见后代设 use_parent_material=true 即整体置灰。
// saturation: 0=纯灰, 1=原色;
// lift: 向 target_gray 抬升的比例(0=保留原灰度会偏黑, 1=完全等于 target_gray);
// target_gray: 抬升目标浅灰值(越大越亮)。
//   注:原来用 *value 乘法压暗,深色按钮(如深绿)置灰后会接近黑;改为向浅灰 mix 抬升,保证亮灰观感。

uniform float saturation : hint_range(0.0, 1.0) = 0.0;
uniform float lift : hint_range(0.0, 1.0) = 0.6;
uniform float target_gray : hint_range(0.0, 1.0) = 0.72;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rgb = mix(vec3(gray), c.rgb, saturation);
	rgb = mix(rgb, vec3(target_gray), lift);
	COLOR = vec4(rgb, c.a);
}
