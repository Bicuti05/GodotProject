class_name RankCollectTrail
extends Node2D


const REFERENCE: PackedScene = preload("res://scripts/gameplay/rank/view/rank_reference_trail.tscn")
const LINGER_SEC: float = 0.35
var playback_speed: float = 1.0
var _core: Sprite2D
var _head: Node2D
var _particles: Array[CPUParticles2D] = []
var _following: Node2D
var _fade: Tween
var _generation: int = 0
var _reference_root: Control

func _ready() -> void :
	z_index = 3
	process_priority = -10
	_reference_root = REFERENCE.instantiate()
	_reference_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reference_root)
	_core = _reference_root.get_node("ScoreTrail")
	_core.process_mode = Node.PROCESS_MODE_INHERIT
	_core.runtime_enabled = false
	_head = Node2D.new()
	_head.name = "TrailHead"
	add_child(_head)
	_core.target_path = _core.get_path_to(_head)
	_core.use_self_when_no_target = false
	_core.use_parent_when_no_target = false
	for child: Node in _core.get_children():
		if child is CPUParticles2D:
			child.reparent(_head, false)
			child.position = Vector2.ZERO
			_particles.append(child)
	set_process(false)

func follow(target: Node2D) -> void :
	cancel()
	_head.modulate.a = 1.0
	_following = target
	_head.global_position = target.global_position
	_core.trail_duration = 0.2 / maxf(playback_speed, 0.01)
	_core.runtime_enabled = true
	_core.notify_target_moved()
	for particle: CPUParticles2D in _particles:
		particle.speed_scale = playback_speed
		particle.show()
		particle.restart()
		particle.emitting = true
	show()
	set_process(true)

func _process(_delta: float) -> void :
	if is_instance_valid(_following):
		_head.global_position = _following.global_position
	else:
		finish()

func finish() -> void :
	if _following == null:
		return

	if is_instance_valid(_following):
		_head.global_position = _following.global_position
		_core.notify_target_moved()
	_following = null
	set_process(false)
	for particle: CPUParticles2D in _particles:
		particle.emitting = false
	_generation += 1
	var generation: int = _generation
	_fade = create_tween()
	_fade.set_speed_scale(playback_speed)

	_fade.tween_property(_head, "modulate:a", 0.0, LINGER_SEC)
	_fade.tween_callback( func() -> void :
		if generation == _generation:
			cancel()
			queue_free())

func cancel() -> void :
	_generation += 1
	if is_instance_valid(_fade):
		_fade.kill()
	_fade = null
	_following = null
	set_process(false)
	if is_instance_valid(_core):
		_core.runtime_enabled = false
		_core.clear_trail()
	for particle: CPUParticles2D in _particles:
		particle.emitting = false
		particle.hide()
	hide()

func _exit_tree() -> void :
	cancel()
