class_name RankRowSparkleFx
extends CPUParticles2D


func play() -> void :
	visible = true
	emitting = false
	restart()


func stop() -> void :
	emitting = false
	visible = false
