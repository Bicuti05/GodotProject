class_name JuiceEndlessDifficultyConfig
extends Resource


@export_group("Target score")
@export_range(0.0, 64.0, 0.25) var initial_target_score: float = 6.0
@export_range(1, 200, 1) var first_phase_pots: int = 20
@export_range(0.0, 64.0, 0.25) var first_phase_target_score: float = 11.0
@export_range(2, 400, 1) var second_phase_pots: int = 40
@export_range(0.0, 64.0, 0.25) var second_phase_target_score: float = 18.25
@export_range(0.0, 2.0, 0.05) var late_score_per_pot: float = 0.35
@export_range(1.0, 128.0, 0.25) var max_target_score: float = 32.0

@export_group("Recovery pots")

@export_range(0, 100, 1) var recovery_interval: int = 6
@export_range(0.1, 1.0, 0.05) var recovery_multiplier: float = 0.9

@export_group("Available colors")
@export_range(5, 10, 1) var initial_colors: int = 5
@export_range(1, 200, 1) var color_interval: int = 24
@export_range(5, 10, 1) var max_colors: int = 10

@export_group("Preferred flower colors")
@export_range(3, 8, 1) var initial_preferred_colors: int = 5
@export_range(1, 200, 1) var preferred_color_interval: int = 24
@export_range(3, 8, 1) var max_preferred_colors: int = 8


func target_score(done: int) -> float:
	var progress: int = maxi(0, done)
	var first_end: int = maxi(1, first_phase_pots)
	var second_end: int = maxi(first_end + 1, second_phase_pots)
	var target: float
	if progress <= first_end:
		target = lerpf(initial_target_score, first_phase_target_score, float(progress) / first_end)
	elif progress <= second_end:
		target = lerpf(first_phase_target_score, second_phase_target_score, 
			float(progress - first_end) / (second_end - first_end))
	else:
		target = second_phase_target_score + float(progress - second_end) * late_score_per_pot
	var multiplier: float = recovery_multiplier if recovery_interval > 0\
	and progress > 0 and progress % recovery_interval == 0 else 1.0
	return minf(max_target_score, target) * multiplier


func color_limit(done: int) -> int:
	return mini(max_colors, initial_colors + int(maxi(0, done) / maxi(1, color_interval)))


func preferred_flower_colors(done: int) -> int:
	return mini(max_preferred_colors, 
		initial_preferred_colors + int(maxi(0, done) / maxi(1, preferred_color_interval)))
