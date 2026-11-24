class_name EmptyColFeedback
extends Control


const MAX_PER_ROUND: int = 3
const ANIMATION: StringName = &"quickShow"

@export var applause_scene: PackedScene
@export var spiral_scene: PackedScene

var shown_count: int = 0
var shown_operations: Array[String] = []
var _pool: Array[SpineSprite] = []
var _active: Array[SpineSprite] = []
var _spiral_pool: Array[EmptyRopeSpiralFx] = []
var _spiral_active: Array[EmptyRopeSpiralFx] = []
var _pending_applause: Dictionary = {}
var _reference_bounds: Rect2 = Rect2()


func reset_round(count: int = 0, operations: Array = []) -> void :
	hide_now()
	shown_operations.clear()
	for key: Variant in operations:
		if shown_operations.size() >= MAX_PER_ROUND:
			break
		if key is String and not key.is_empty() and not shown_operations.has(key):
			shown_operations.append(key)
	shown_count = clampi(count, 0, MAX_PER_ROUND)
	shown_count = maxi(shown_count, shown_operations.size())


func can_show(operation_key: String = "") -> bool:
	return shown_count < MAX_PER_ROUND and not shown_operations.has(operation_key)


func play(center: Vector2, width: float, rope_geometry: Callable, operation_key: String) -> void :
	if not can_show(operation_key):
		return
	shown_count += 1
	shown_operations.append(operation_key)
	var spiral: EmptyRopeSpiralFx
	if _spiral_pool.is_empty():
		spiral = spiral_scene.instantiate() as EmptyRopeSpiralFx
		spiral.halfway_reached.connect(_on_spiral_halfway_reached.bind(spiral))
		spiral.finished.connect(_on_spiral_finished.bind(spiral))
		add_child(spiral)
		move_child(spiral, 0)
	else:
		spiral = _spiral_pool.pop_back()
	_spiral_active.append(spiral)
	_pending_applause[spiral] = {"center": center, "width": width}
	spiral.play_rope(rope_geometry)
	AudioManager.play_sfx(&"empty_rope_light")


func _play_applause(center: Vector2, width: float) -> void :
	var spine: SpineSprite
	if _pool.is_empty():
		spine = applause_scene.instantiate() as SpineSprite
		spine.animation_completed.connect(_on_animation_completed)
		add_child(spine)
	else:
		spine = _pool.pop_back()
	var skeleton: SpineSkeleton = spine.get_skeleton()
	var state: SpineAnimationState = spine.get_animation_state()
	var duration: float = skeleton.get_data().find_animation(ANIMATION).get_duration()

	if _reference_bounds.size.x <= 0.0:
		_apply_pose(skeleton, state, duration * 0.5)
		_reference_bounds = skeleton.get_bounds()
	var display_scale: float = width / maxf(_reference_bounds.size.x, 1.0)
	spine.scale = Vector2.ONE * display_scale
	spine.position = center - _reference_bounds.get_center() * display_scale
	_apply_pose(skeleton, state, 0.0)
	_active.append(spine)
	spine.show()
	AudioManager.play_sfx(&"empty_rope_applaud")


func hide_now() -> void :
	AudioManager.stop_sfx(&"empty_rope_light")
	AudioManager.stop_sfx(&"empty_rope_applaud")
	_pending_applause.clear()
	for spine: SpineSprite in _active:
		spine.hide()
		spine.get_animation_state().clear_tracks()
		_pool.append(spine)
	_active.clear()
	for spiral: EmptyRopeSpiralFx in _spiral_active:
		spiral.stop()
		_spiral_pool.append(spiral)
	_spiral_active.clear()


func _apply_pose(skeleton: SpineSkeleton, state: SpineAnimationState, time: float) -> void :
	state.clear_tracks()
	skeleton.set_to_setup_pose()
	state.set_animation(ANIMATION, false, 0)
	state.update(time)
	state.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)


func _on_animation_completed(sprite: Object, _state: Object, _entry: Object) -> void :
	var spine: SpineSprite = sprite as SpineSprite
	if not _active.has(spine):
		return
	spine.hide()
	_active.erase(spine)
	_pool.append(spine)


func _on_spiral_halfway_reached(spiral: EmptyRopeSpiralFx) -> void :
	if not _spiral_active.has(spiral) or not _pending_applause.has(spiral):
		return
	var params: Dictionary = _pending_applause[spiral]
	_pending_applause.erase(spiral)
	_play_applause(params["center"] as Vector2, float(params["width"]))


func _on_spiral_finished(spiral: EmptyRopeSpiralFx) -> void :
	if not _spiral_active.has(spiral):
		return
	_pending_applause.erase(spiral)
	_spiral_active.erase(spiral)
	_spiral_pool.append(spiral)
