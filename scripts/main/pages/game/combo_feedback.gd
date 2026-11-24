class_name ComboFeedback
extends Control


const SKINS: Array[String] = ["Nice!", "Great!", "Excellent!", "Amazing!", 
	"Incredible!", "Unstoppable!", "Legendary!"]
const SFX_IDS: Array[StringName] = [&"combo_nice", &"combo_great", &"combo_excellent", 
	&"combo_amazing", &"combo_incredible", &"combo_unstoppable", &"combo_legendary"]
const ANIMATION: StringName = &"Animation"
const REFERENCE_TIME: float = 0.5

const REFERENCE_CONTENT_HEIGHT: float = 126.0
const REFERENCE_SKIN: String = "Amazing!"

const LEGENDARY_START_COUNT: int = 8
const FULLSCREEN_FX_DURATION: float = 1.0
const PETAL_SPAWN_MIN_GAP: float = 18.0
const PETAL_SPAWN_MIN_DISTANCE: float = 72.0
const PETAL_SPAWN_LOCAL_X_DISTANCE: float = 140.0
const PETAL_SPAWN_LOCAL_Y_GAP: float = 24.0
const PETAL_SPAWN_Y_RANGE: Vector2 = Vector2(-64.0, 92.0)
const PETAL_SPAWN_ATTEMPTS: int = 64
const PETAL_SPAWN_MIN_CHANGE: float = 48.0
const PETAL_SPAWN_SIDE_INNER: float = 230.0
const PETAL_SPAWN_SIDE_RATIO: float = 0.15
const PETAL_SPAWN_RANGES: Dictionary = {
	2: Vector2(-472.0, 472.0), 
	3: Vector2(-472.0, 472.0), 
	4: Vector2(-472.0, 429.0), 
	5: Vector2(-472.0, 472.0), 
	6: Vector2(-433.0, 472.0), 
	7: Vector2(-472.0, 425.0), 
	8: Vector2(-468.0, 472.0), 
	9: Vector2(-472.0, 450.0), 
	10: Vector2(-472.0, 472.0), 
	11: Vector2(-464.0, 472.0), 
	12: Vector2(-439.0, 472.0), 
	13: Vector2(-472.0, 472.0), 
	14: Vector2(-462.0, 472.0), 
	16: Vector2(-472.0, 459.0), 
	17: Vector2(-408.0, 472.0), 
	18: Vector2(-472.0, 472.0), 
	19: Vector2(-472.0, 472.0), 
	20: Vector2(-446.0, 472.0), 
	21: Vector2(-472.0, 455.0), 
}

@onready var _spine: SpineSprite = $Spine
@onready var _timing_spine: SpineSprite = $TimingSpine

var _pending: Array[Dictionary] = []
var _tween: Tween = null
var _center: Vector2 = Vector2.ZERO
var _display_scale: float = 0.0
var _sfx_id: StringName = &""
var _outer_glow_slots: Array[SpineSlot] = []
var _fullscreen_slots: Array[SpineSlot] = []
var _title_slots: Array[SpineSlot] = []
var _fullscreen_bones: Array[SpineBone] = []
var _fullscreen_motion_bones: Array[SpineBone] = []
var _fullscreen_setup_positions: Array[Vector2] = []
var _fullscreen_glow_bones: Array[bool] = []
var _fullscreen_bone_poses: Array[Vector4] = []
var _fullscreen_pose_applied: bool = false
var _fullscreen_enabled: bool = false
var _fullscreen_only: bool = false
var _fullscreen_count: int = 2
var _petal_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _petal_motion_bones: Array[SpineBone] = []
var _petal_spawn_offsets: Array[Vector2] = []
var _petal_previous_spawn_x: Dictionary = {}
var _petal_offsets_applied: bool = false


func _ready() -> void :
	var fullscreen_bone_names: Dictionary = {}
	for slot: SpineSlot in _spine.get_skeleton().get_slots():
		var slot_name: String = slot.get_data().get_name()
		if slot_name.begins_with("fx_"):
			_fullscreen_slots.append(slot)
			var bone: SpineBone = slot.get_bone()
			var bone_name: String = bone.get_data().get_bone_name()
			if not fullscreen_bone_names.has(bone_name):
				fullscreen_bone_names[bone_name] = true
				_fullscreen_bones.append(bone)
		else:
			_title_slots.append(slot)
		if slot_name.ends_with("_base_glow") or ("_flower_" in slot_name and slot_name.ends_with("_glow")):
			_outer_glow_slots.append(slot)
	_spine.before_animation_state_apply.connect(_on_spine_before_animation_state_apply)
	_spine.before_world_transforms_change.connect(_on_spine_before_world_transforms_change)
	_spine.world_transforms_changed.connect(_on_spine_world_transforms_changed)
	_on_spine_world_transforms_changed(_spine)
	_petal_rng.randomize()
	_timing_spine.before_animation_state_apply.connect(_on_timing_before_animation_state_apply)
	_timing_spine.before_world_transforms_change.connect(_on_timing_before_world_transforms_change)


func _on_spine_before_animation_state_apply(_sprite: SpineSprite) -> void :
	_restore_fullscreen_bone_poses()


func _restore_fullscreen_bone_poses() -> void :
	if not _fullscreen_pose_applied:
		return
	for bone_index: int in _fullscreen_motion_bones.size():
		var bone: SpineBone = _fullscreen_motion_bones[bone_index]
		var pose: Vector4 = _fullscreen_bone_poses[bone_index]
		bone.set_x(pose.x)
		bone.set_y(pose.y)
		bone.set_scale_x(pose.z)
		bone.set_scale_y(pose.w)
	_fullscreen_pose_applied = false


func _on_spine_before_world_transforms_change(_sprite: SpineSprite) -> void :
	if not _fullscreen_enabled or _fullscreen_pose_applied:
		return
	var viewport: Vector2 = UiMetrics.viewport_size()
	var layout_scale: Vector2 = viewport / UiMetrics.DESIGN
	var viewport_center: Vector2 = get_global_transform().affine_inverse() * (viewport * 0.5)
	var offset: Vector2 = (viewport_center - _spine.position) / _spine.scale
	for bone_index: int in _fullscreen_motion_bones.size():
		var bone: SpineBone = _fullscreen_motion_bones[bone_index]
		var pose: Vector4 = Vector4(bone.get_x(), bone.get_y(), bone.get_scale_x(), bone.get_scale_y())
		_fullscreen_bone_poses[bone_index] = pose
		var setup_y: float = _fullscreen_setup_positions[bone_index].y
		var vertical_scale: float = layout_scale.y if _fullscreen_glow_bones[bone_index] else layout_scale.x
		bone.set_x(pose.x * layout_scale.x / _spine.scale.x + offset.x)
		bone.set_y((setup_y * layout_scale.y + (pose.y - setup_y) * vertical_scale) / _spine.scale.y - offset.y)
		bone.set_scale_x(pose.z * layout_scale.x / _spine.scale.x)
		bone.set_scale_y(pose.w * vertical_scale / _spine.scale.y)
	_fullscreen_pose_applied = not _fullscreen_motion_bones.is_empty()


func _on_timing_before_animation_state_apply(_sprite: SpineSprite) -> void :
	if not _petal_offsets_applied:
		return
	for petal_index: int in _petal_motion_bones.size():
		var bone: SpineBone = _petal_motion_bones[petal_index]
		bone.set_x(bone.get_x() - _petal_spawn_offsets[petal_index].x)
		bone.set_y(bone.get_y() - _petal_spawn_offsets[petal_index].y)
	_petal_offsets_applied = false


func _on_timing_before_world_transforms_change(_sprite: SpineSprite) -> void :
	if _petal_offsets_applied:
		return
	for petal_index: int in _petal_motion_bones.size():
		var bone: SpineBone = _petal_motion_bones[petal_index]
		bone.set_x(bone.get_x() + _petal_spawn_offsets[petal_index].x)
		bone.set_y(bone.get_y() + _petal_spawn_offsets[petal_index].y)
	_petal_offsets_applied = not _petal_motion_bones.is_empty()


func _on_spine_world_transforms_changed(_sprite: SpineSprite) -> void :
	for slot: SpineSlot in _outer_glow_slots:
		var color: Color = slot.get_color()
		color.a = 0.0
		slot.set_color(color)
	if not _fullscreen_enabled:
		for slot: SpineSlot in _fullscreen_slots:
			var color: Color = slot.get_color()
			color.a = 0.0
			slot.set_color(color)
	if _fullscreen_only:
		for slot: SpineSlot in _title_slots:
			var color: Color = slot.get_color()
			color.a = 0.0
			slot.set_color(color)


static func skin_for_count(combo_count: int) -> String:
	return SKINS[clampi(combo_count - 2, 0, SKINS.size() - 1)]



static func sfx_for_count(combo_count: int) -> StringName:
	return SFX_IDS[clampi(combo_count - 2, 0, SFX_IDS.size() - 1)]



func play(combos: Array[int], center: Vector2, 
		haptic_events: Array[int] = [], fullscreen_fx_enabled: bool = false, 
		petal_feedback_enabled: bool = false, _timing_feedback_variant: int = 1) -> void :
	if combos.is_empty():
		return

	if combos[0] == 2:
		hide_now()
	_center = center

	for i: int in combos.size():
		_pending.append({"count": combos[i], 
			"haptic_event": haptic_events[i] if i < haptic_events.size() else -1, 
			"fullscreen_fx_enabled": fullscreen_fx_enabled, 
			"petal_feedback_enabled": petal_feedback_enabled})
	if _tween == null:
		_play_next()



func is_playing() -> bool:
	return (is_instance_valid(_spine) and _spine.is_visible_in_tree())\
	or (is_instance_valid(_timing_spine) and _timing_spine.is_visible_in_tree())


func hide_now() -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_pending.clear()
	_stop_sfx()
	_hide_spines()


func preview_fullscreen_stage(stage: int, center: Vector2) -> void :
	var combos: Array[int] = []
	for combo_count: int in range(2, LEGENDARY_START_COUNT + 1):
		var combo_stage: int = 1 if combo_count <= 4 else (2 if combo_count <= 7 else 3)
		if stage in [4, 5] or combo_stage == stage:
			combos.append(combo_count)
	hide_now()
	play(combos, center, [], true)


func _play_next() -> void :
	_stop_sfx()
	_hide_spines()
	if _pending.is_empty():
		return
	var feedback: Dictionary = _pending.pop_front()
	var count: int = int(feedback["count"])
	var timing_feedback_enabled: bool = bool(feedback["petal_feedback_enabled"])
	_fullscreen_count = count
	_fullscreen_enabled = bool(feedback["fullscreen_fx_enabled"])
	_fullscreen_only = timing_feedback_enabled and _fullscreen_enabled
	var spine: SpineSprite = _timing_spine if timing_feedback_enabled else _spine
	var animation: StringName = ANIMATION
	var skeleton: SpineSkeleton = spine.get_skeleton()
	var state: SpineAnimationState = spine.get_animation_state()
	var bounds: Rect2
	var display_scale: float
	if timing_feedback_enabled:
		skeleton.set_skin_by_name(skin_for_count(count))
		bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
		display_scale = 1.0
	else:
		_ensure_display_scale()
		_apply_reference_pose(skeleton, state, skin_for_count(count))
		_filter_reference_slots(skeleton, false)
		bounds = skeleton.get_bounds()
		display_scale = _display_scale
	spine.scale = Vector2.ONE * display_scale
	spine.position = _center - bounds.get_center() * display_scale
	state.clear_tracks()
	skeleton.set_to_setup_pose()
	if timing_feedback_enabled and count >= 4:
		_randomize_petal_spawn_positions(skeleton)
	state.set_animation(animation, false, 0)
	state.update(0.0)
	state.apply(skeleton)
	if timing_feedback_enabled:
		_on_timing_before_world_transforms_change(spine)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	if not timing_feedback_enabled:
		_on_spine_world_transforms_changed(spine)
	if timing_feedback_enabled and count >= 4:
		_play_top_petals()
	else:
		spine.show()

	if bool(feedback["fullscreen_fx_enabled"]):
		_play_fullscreen_fx_for_count(count)

	_sfx_id = sfx_for_count(count)
	AudioManager.play_sfx(_sfx_id)

	var haptic_event: int = int(feedback["haptic_event"])
	if haptic_event >= 0:
		HapticManager.play_event(haptic_event)

	var duration: float = skeleton.get_data().find_animation(animation).get_duration()
	_tween = create_tween()
	_tween.tween_interval(duration)
	_tween.tween_callback( func() -> void :
		_tween = null
		_play_next())


func _play_top_petals() -> void :
	_timing_spine.show()


func _randomize_petal_spawn_positions(skeleton: SpineSkeleton) -> void :
	var spawn_positions: Array[Vector2] = []
	var petal_ids: Array[int] = []
	for petal_id: int in PETAL_SPAWN_RANGES:
		var bone: SpineBone = skeleton.find_bone("petal_%02d_motion" % petal_id)
		if bone.is_active():
			petal_ids.append(petal_id)
	for shuffle_index: int in range(petal_ids.size() - 1, 0, -1):
		var swap_index: int = _petal_rng.randi_range(0, shuffle_index)
		var swap_id: int = petal_ids[shuffle_index]
		petal_ids[shuffle_index] = petal_ids[swap_index]
		petal_ids[swap_index] = swap_id
	var side_count: int = ceili(petal_ids.size() * PETAL_SPAWN_SIDE_RATIO)
	for petal_index: int in petal_ids.size():
		var petal_id: int = petal_ids[petal_index]
		var bone: SpineBone = skeleton.find_bone("petal_%02d_motion" % petal_id)
		var setup_x: float = bone.get_data().get_x()
		var setup_y: float = bone.get_data().get_y()
		var previous_spawn_x: float = _petal_previous_spawn_x.get(petal_id, setup_x)
		var spawn_range: Vector2 = PETAL_SPAWN_RANGES[petal_id]
		if petal_index < side_count:
			spawn_range.y = minf(spawn_range.y, - PETAL_SPAWN_SIDE_INNER)
		elif petal_index < side_count * 2:
			spawn_range.x = maxf(spawn_range.x, PETAL_SPAWN_SIDE_INNER)
		var spawn_position: Vector2 = _pick_petal_spawn_position(spawn_range, 
			spawn_positions, previous_spawn_x)
		spawn_positions.append(spawn_position)
		_petal_motion_bones.append(bone)
		_petal_spawn_offsets.append(spawn_position - Vector2(setup_x, setup_y))
		_petal_previous_spawn_x[petal_id] = spawn_position.x


func _pick_petal_spawn_position(spawn_range: Vector2, spawn_positions: Array[Vector2], 
		previous_spawn_x: float) -> Vector2:
	var blocked_ranges: Array[Vector2] = [Vector2(previous_spawn_x - PETAL_SPAWN_MIN_CHANGE, 
		previous_spawn_x + PETAL_SPAWN_MIN_CHANGE)]
	for spawn_position: Vector2 in spawn_positions:
		blocked_ranges.append(Vector2(spawn_position.x - PETAL_SPAWN_MIN_GAP, 
			spawn_position.x + PETAL_SPAWN_MIN_GAP))
	blocked_ranges.sort_custom( func(left: Vector2, right: Vector2) -> bool:
		return left.x < right.x)
	var free_ranges: Array[Vector2] = []
	var free_width: float = 0.0
	var next_x: float = spawn_range.x
	for blocked_range: Vector2 in blocked_ranges:
		var range_end: float = minf(blocked_range.x, spawn_range.y)
		if range_end > next_x:
			free_ranges.append(Vector2(next_x, range_end))
			free_width += range_end - next_x
		next_x = maxf(next_x, blocked_range.y)
		if next_x >= spawn_range.y:
			break
	if next_x < spawn_range.y:
		free_ranges.append(Vector2(next_x, spawn_range.y))
		free_width += spawn_range.y - next_x
	var best_position: Vector2 = Vector2.ZERO
	var best_score: float = -1.0
	var minimum_distance_squared: float = PETAL_SPAWN_MIN_DISTANCE * PETAL_SPAWN_MIN_DISTANCE
	for attempt: int in PETAL_SPAWN_ATTEMPTS:
		var candidate: Vector2 = Vector2(_pick_petal_spawn_x(free_ranges, free_width), 
			_petal_rng.randf_range(PETAL_SPAWN_Y_RANGE.x, PETAL_SPAWN_Y_RANGE.y))
		var score: float = INF
		for spawn_position: Vector2 in spawn_positions:
			score = minf(score, candidate.distance_squared_to(spawn_position))
			if absf(candidate.x - spawn_position.x) < PETAL_SPAWN_LOCAL_X_DISTANCE:
				var vertical_score: float = absf(candidate.y - spawn_position.y)\
				/ PETAL_SPAWN_LOCAL_Y_GAP * PETAL_SPAWN_MIN_DISTANCE
				score = minf(score, vertical_score * vertical_score)
		if score >= minimum_distance_squared:
			return candidate
		if score > best_score:
			best_score = score
			best_position = candidate
	return best_position


func _pick_petal_spawn_x(free_ranges: Array[Vector2], free_width: float) -> float:
	var remaining_width: float = _petal_rng.randf_range(0.0, free_width)
	for free_range: Vector2 in free_ranges:
		var range_width: float = free_range.y - free_range.x
		if remaining_width <= range_width:
			return free_range.x + remaining_width
		remaining_width -= range_width
	var last_range: Vector2 = free_ranges.back()
	return last_range.y


func _play_fullscreen_fx_for_count(combo_count: int) -> void :
	if combo_count <= 4:
		_play_fullscreen_fx_stage_one()
	elif combo_count <= 7:
		_play_fullscreen_fx_stage_two()
	else:
		_play_fullscreen_fx_stage_three()


func _play_fullscreen_fx_stage_one() -> void :
	_play_fullscreen_spine(1)


func _play_fullscreen_fx_stage_two() -> void :
	_play_fullscreen_spine(2)


func _play_fullscreen_fx_stage_three() -> void :
	_play_fullscreen_spine(3)


func _play_fullscreen_spine(stage: int) -> void :
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	if _fullscreen_only:
		var state: SpineAnimationState = _spine.get_animation_state()
		skeleton.set_skin_by_name(skin_for_count(_fullscreen_count))
		skeleton.set_to_setup_pose()
		_spine.scale = Vector2.ONE
		_spine.position = get_global_transform().affine_inverse() * (UiMetrics.viewport_size() * 0.5)
		state.set_animation(ANIMATION, false, 0)
		state.update(0.0)
		state.apply(skeleton)
	var stage_prefix: String = "fx_s%d_" % stage
	for bone: SpineBone in _fullscreen_bones:
		var bone_name: String = bone.get_data().get_bone_name()
		var is_glow: bool = bone_name.begins_with("fx_glow_")
		if not bone_name.begins_with(stage_prefix) and not (stage == 3 and is_glow):
			continue
		_fullscreen_motion_bones.append(bone)
		_fullscreen_setup_positions.append(Vector2(bone.get_data().get_x(), bone.get_data().get_y()))
		_fullscreen_glow_bones.append(is_glow)
	_fullscreen_bone_poses.resize(_fullscreen_motion_bones.size())
	_on_spine_before_world_transforms_change(_spine)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	_on_spine_world_transforms_changed(_spine)
	_spine.show()



func _ensure_display_scale() -> void :
	if _display_scale > 0.0:
		return
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	_apply_reference_pose(skeleton, _spine.get_animation_state(), REFERENCE_SKIN)
	_filter_reference_slots(skeleton, true)
	_display_scale = REFERENCE_CONTENT_HEIGHT / skeleton.get_bounds().size.y



func _hide_spines() -> void :
	_restore_fullscreen_bone_poses()
	_fullscreen_motion_bones.clear()
	_fullscreen_setup_positions.clear()
	_fullscreen_glow_bones.clear()
	_fullscreen_bone_poses.clear()
	_fullscreen_enabled = false
	_fullscreen_only = false
	_petal_motion_bones.clear()
	_petal_spawn_offsets.clear()
	_petal_offsets_applied = false
	for spine: SpineSprite in [_spine, _timing_spine]:
		spine.hide()
		spine.get_animation_state().clear_tracks()
		spine.get_skeleton().set_to_setup_pose()


func _stop_sfx() -> void :
	if _sfx_id != &"":
		AudioManager.stop_sfx(_sfx_id)
		_sfx_id = &""



func _apply_reference_pose(skeleton: SpineSkeleton, state: SpineAnimationState, skin: String, 
		animation: StringName = ANIMATION) -> void :
	state.clear_tracks()
	skeleton.set_skin_by_name(skin)
	skeleton.set_to_setup_pose()
	state.set_animation(animation, false, 0)
	state.update(REFERENCE_TIME)
	state.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)



func _filter_reference_slots(skeleton: SpineSkeleton, include_flowers: bool) -> void :
	for slot: SpineSlot in skeleton.get_slots():
		var slot_name: String = slot.get_data().get_name()
		var is_text: bool = slot_name.begins_with("gp_text_")
		var is_flower: bool = "_flower_" in slot_name and not slot_name.ends_with("_shadow")\
		and not slot_name.ends_with("_glow")
		if not is_text and not (include_flowers and is_flower):
			slot.set_attachment(null)
