// 文字竖向渐变(用于「+N」金币飘字字芯)。
// 仅对「白色字芯」上竖向渐变;描边 / 投影(非白色,如深棕 #9C520A)保持原色不被染。
// 靠 font_color 设白来区分字芯,outline/shadow 用各自深色 → shader 只改白色那部分。
// VERTEX.y 在 Label 局部空间,按脚本传入的文字高度 rect_h 映射渐变(t=0 顶→t=1 底)。
shader_type canvas_item;

uniform vec4 grad_top : source_color = vec4(1.0, 0.965, 0.620, 1.0);    // 顶 #FFF69E
uniform vec4 grad_bottom : source_color = vec4(1.0, 0.902, 0.404, 1.0); // 底 #FFE667
uniform float rect_h = 60.0;   // Label 文字高度(脚本传入)

varying float v_y;

void vertex() {
	v_y = VERTEX.y;
}

void fragment() {
	// 仅白色字芯上渐变;描边 / 投影(深棕)非白 → 原样保留
	if (COLOR.r > 0.85 && COLOR.g > 0.85 && COLOR.b > 0.85) {
		float t = clamp(v_y / max(rect_h, 1.0), 0.0, 1.0);
		vec3 g = mix(grad_top.rgb, grad_bottom.rgb, t);
		COLOR = vec4(g, COLOR.a);
	}
}
