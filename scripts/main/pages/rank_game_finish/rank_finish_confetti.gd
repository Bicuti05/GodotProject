class_name RankFinishConfetti
extends Node2D

const EDGE_INSET: float = 40.0
const SPAN_RATIO: float = 0.8
const UPDATE_FRAMES: int = 2

@onready var _emitters: Array[GPUParticles2D] = [$LeftRibbon, $RightRibbon, $LeftSparkle, $RightSparkle]

var _lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _tail_tween: Tween
var _generation: int = 0


func _ready() -> void :

	for emitter: GPUParticles2D in _emitters:
		emitter.process_material = emitter.process_material.duplicate() as ParticleProcessMaterial
	_place_emitters()
	_lifecycle.prepare(_emitters, UPDATE_FRAMES, func() -> bool: return is_visible_in_tree())


func play() -> void :
	reset()
	_place_emitters()
	show()
	_lifecycle.play()
	var generation: int = _generation
	_tail_tween = create_tween()

	_tail_tween.tween_interval(_emitters[0].lifetime + 0.2)
	_tail_tween.tween_callback( func() -> void :
		if generation == _generation:
			reset())


func reset() -> void :
	_generation += 1
	if _tail_tween != null and _tail_tween.is_valid():
		_tail_tween.kill()
	_tail_tween = null
	hide()
	_lifecycle.reset_immediate()


func _place_emitters() -> void :
	var viewport_size: Vector2 = UiMetrics.viewport_size()
	for index: int in _emitters.size():
		var emitter: GPUParticles2D = _emitters[index]
		emitter.position = Vector2( - EDGE_INSET if index % 2 == 0 else viewport_size.x + EDGE_INSET, 
			viewport_size.y * 0.5)
		var material: ParticleProcessMaterial = emitter.process_material as ParticleProcessMaterial
		material.emission_box_extents.y = viewport_size.y * SPAN_RATIO * 0.5
		emitter.visibility_rect = Rect2(-160.0, - viewport_size.y * 0.5 - 300.0, 
			viewport_size.x + 320.0, viewport_size.y + 600.0)


func _exit_tree() -> void :
	reset()
