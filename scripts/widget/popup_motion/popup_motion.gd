class_name PopupMotion
extends RefCounted

const IN_DURATION: float = 0.25
const OUT_DURATION: float = 0.28
const START_SCALE: float = 0.9

var _generation: int = 0
var _tween: Tween = null
var _composite: CanvasGroup = null


func reset(content: Control) -> void :
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	content.hide()
	_reset_composite()
	content.modulate.a = 0.0
	content.scale = Vector2.ONE


func appear(content: Control, composite: CanvasGroup = null) -> bool:
	reset(content)
	var generation: int = _generation
	content.pivot_offset = content.size * 0.5
	content.scale = Vector2.ONE * START_SCALE
	if is_instance_valid(composite):
		_composite = composite
		content.modulate.a = 1.0
		_set_composite_opacity(0.0)
	content.show()
	var tw: Tween = content.create_tween().set_parallel(true)
	_tween = tw
	if is_instance_valid(_composite):
		tw.tween_method(_set_composite_opacity, 0.0, 1.0, IN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(content, "modulate:a", 1.0, IN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(content, "scale", Vector2.ONE, IN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return await _wait(content, tw, generation)


func disappear(content: Control, layer: Control, duration: float = OUT_DURATION) -> bool:
	_generation += 1
	var generation: int = _generation
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var tw: Tween = content.create_tween()
	_tween = tw
	tw.tween_property(layer, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not await _wait(content, tw, generation):
		return false
	reset(content)
	layer.hide()
	layer.modulate.a = 1.0
	return true




func disappear_composited(content: Control, layer: Control, composite: CanvasGroup, 
		background: CanvasItem, duration: float = OUT_DURATION, retain_clock: bool = false, 
		active: Callable = Callable()) -> bool:
	_generation += 1
	var generation: int = _generation
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_composite = composite
	var material: ShaderMaterial = composite.material as ShaderMaterial
	material.set_shader_parameter("retain_clock", retain_clock)
	_set_composite_opacity(1.0)
	var tw: Tween = content.create_tween().set_parallel(true)
	_tween = tw
	tw.tween_method(_set_composite_opacity, 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if is_instance_valid(background):
		tw.tween_property(background, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not await _wait(content, tw, generation, active):
		return false
	if retain_clock:
		return true
	reset(content)
	layer.hide()
	layer.modulate.a = 1.0
	return true


func _set_composite_opacity(alpha: float) -> void :
	if is_instance_valid(_composite):
		(_composite.material as ShaderMaterial).set_shader_parameter("opacity", alpha)


func _reset_composite() -> void :
	if is_instance_valid(_composite):
		var material: ShaderMaterial = _composite.material as ShaderMaterial
		material.set_shader_parameter("opacity", 1.0)
		material.set_shader_parameter("retain_clock", false)
		_composite.self_modulate = Color.WHITE
		_composite.show()
	_composite = null


func _wait(content: Control, tw: Tween, generation: int, active: Callable = Callable()) -> bool:

	while generation == _generation and is_instance_valid(content) and content.is_inside_tree()\
	and tw.is_valid() and tw.is_running():
		if active.is_valid() and not bool(active.call()):
			tw.kill()
			_tween = null
			return false
		await content.get_tree().process_frame
	if generation != _generation or not is_instance_valid(content) or not content.is_inside_tree():
		return false
	_tween = null
	return not active.is_valid() or bool(active.call())
