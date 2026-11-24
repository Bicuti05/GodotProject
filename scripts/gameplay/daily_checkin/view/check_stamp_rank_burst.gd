extends Node2D

var emitters: Array[CPUParticles2D] = []
var paused: = false
var impact_count: = 0

func _ready() -> void :
	for group_name in ["GlowAlp", "StarAlp", "StarAdd"]:
		var p: = get_node(group_name) as CPUParticles2D
		p.name = group_name
		if group_name != "GlowAlp":

			p.amount = 6
			p.seed = 23041
			p.lifetime_randomness = 0.2

			p.scale_amount_min *= 0.5
			p.scale_amount_max *= 0.5
		emitters.append(p)

	z_index = 1
	reset()

func play(at: Vector2, diameter: float) -> void :
	position = at
	scale = Vector2.ONE * diameter / 108.0
	impact_count += 1
	show()
	for p in emitters:
		p.speed_scale = 0.0 if paused else 1.0
		p.restart()
		p.emitting = true

func reset() -> void :
	impact_count = 0
	paused = false
	for p in emitters:
		p.restart()
		p.emitting = false
		p.speed_scale = 0.0
	hide()

func suspend(value: bool) -> void :
	paused = value
	for p in emitters: p.speed_scale = 0.0 if value else 1.0
