shader_type canvas_item;

// 图集取格,不做任何几何变换(旋转/缩放交给 ParticleProcessMaterial 的
// angle/angular_velocity/scale_amount,这里不重复实现)。
//
// 两种用法(anim_speed 决定):
// ① 随机静帧:anim_speed_min/max = 0、anim_offset_min/max = 0/1,每颗粒子的 anim_offset
//    落定在一个随机静态值上(速度为 0,offset 就不会随时间变化)。
// ② 循环播放序列动画:anim_speed_min/max > 0,INSTANCE_CUSTOM.z 随粒子寿命持续增长
//    (`anim_offset + anim_speed × 归一化存活进度`),用 mod 让帧号循环回卷而不是撞到最后一帧
//    卡死——anim_offset 仍决定每颗粒子的随机起始帧,speed 决定循环快慢。
// 帧号 → 网格坐标按"先读行再读列":同一列内先从上到下走完全部行,再换到下一列
// (行是内层/快变索引,列是外层/慢变索引),不是通常的从左到右先走列。
//
// ⚠️ 别声明 TAU/PI/E——Godot shader 语言已内置,重复声明会让整个 shader 编译失败,
// 且失败时引擎静默回退成"整张图集缩略图糊在每颗粒子上"(见 confetti_flip.gdshader 同款踩坑)。

uniform float h_frames = 2.0;
uniform float v_frames = 2.0;

void vertex() {
	float seed = INSTANCE_CUSTOM.z;
	float total = h_frames * v_frames;
	float frame = mod(floor(seed * total), total);
	float row = mod(frame, v_frames);
	float col = floor(frame / v_frames);
	UV /= vec2(h_frames, v_frames);
	UV += vec2(col / h_frames, row / v_frames);
}
