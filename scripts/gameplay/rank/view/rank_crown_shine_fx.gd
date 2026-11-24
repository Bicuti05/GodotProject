class_name RankCrownShineFx
extends CPUParticles2D


func play() -> void :
	visible = true
	restart()
	emitting = true


func stop() -> void :
	emitting = false
	visible = false
