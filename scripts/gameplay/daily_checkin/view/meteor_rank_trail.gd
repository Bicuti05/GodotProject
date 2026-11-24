extends "res://scripts/gameplay/rank/view/rank_collect_trail.gd"

var effect_paused: = false

func _ready() -> void :
	super._ready()
	z_index = 0
	_reference_root.scale = Vector2.ONE * 0.6
	_head.scale = Vector2.ONE * 0.6

func follow(target: Node2D) -> void :
	super.follow(target)
	_core.trail_duration = 0.65

func sample_current() -> void :
	if not effect_paused and is_instance_valid(_following):
		_head.global_position = _following.global_position
		_core.notify_target_moved()

func suspend_effect(value: bool) -> void :
	effect_paused = value
	process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	if is_instance_valid(_fade):
		if value:
			_fade.pause()
		else:
			_fade.play()

func use_pink_palette() -> void :

	for name in ["TrailAlp", "TrailGlow", "TrailAdd"]:
		var line: Line2D = _core.get_node(name)
		var gradient: = line.gradient.duplicate(true) as Gradient
		for index in gradient.get_point_count():
			var original: = gradient.get_color(index)
			gradient.set_color(index, Color.from_hsv(0.91, original.s * 0.55, original.v, original.a))
		line.gradient = gradient
	for particle in _particles:
		var original: Color = particle.color
		particle.color = Color.from_hsv(0.91, original.s * 0.55, original.v, original.a)
