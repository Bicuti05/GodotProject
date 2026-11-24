class_name RankCrownBurstFx
extends Node2D


func play_at(pos: Vector2) -> void :
	position = pos
	visible = true
	for node in get_children():
		var p: = node as CPUParticles2D
		if p == null:
			continue
		p.emitting = false
		p.restart()


func stop() -> void :
	for node in get_children():
		var p: = node as CPUParticles2D
		if p != null:
			p.emitting = false
	visible = false


func get_emitting_names() -> Array[String]:
	var names: Array[String] = []
	for node in get_children():
		var p: = node as CPUParticles2D
		if p != null and p.emitting:
			names.append(String(p.name))
	return names
