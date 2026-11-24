class_name RankListRiseAnim
extends RefCounted


const RISE_TIME_SCALE: float = 1.3

const COLLAPSE_SEC: float = 0.3
const LIFT_SEC: float = COLLAPSE_SEC
const DROP_SEC: float = 0.6 * RISE_TIME_SCALE
const LIFT_Y: float = -22.0

const STEP_BASE_SEC: float = 0.156

const TILT_ANGLE_DEG: float = 5.0
const TILT_SEC_MIN: float = 0.08

const _OVER_ITEM_SOUND_KINDS: Array[StringName] = [
	&"rank_over_item_1", &"rank_over_item_2", 
	&"rank_over_item_3", &"rank_over_item_4", 
	&"rank_over_item_5", &"rank_over_item_6", 
	&"rank_over_item_7", &"rank_over_item_8", 
	&"rank_over_item_9", &"rank_over_item_10", 
]


static func play(list: RankListView, old_rank: int, new_rank: int) -> void :
	if list == null or not is_instance_valid(list):
		return
	var generation: int = list.animation_generation
	var old_row: int = list.row_index_of_rank(old_rank)
	var real_me: RankItemView = list.row_node_at(old_row) as RankItemView
	if real_me == null:
		return
	if new_rank >= old_rank:
		await _play_in_place(list, real_me, generation)
		return
	var new_row: int = list.row_index_of_rank(new_rank)
	if new_row < 0:
		return

	list.set_drag_enabled(false)
	var overlay: RankItemView = list.get_rise_overlay_item()
	overlay.clone_bind_from(real_me)
	overlay.position = Vector2(0.0, list.content_y_to_overlay_y(real_me.position.y))
	overlay.visible = true
	list._player_hidden = true
	real_me.visible = false
	overlay.set_rise_outline(true)
	overlay.play_rise_arrows()

	AudioManager.play_sfx(&"rank_rise_begin")
	AudioManager.play_sfx(&"rank_item_shrink")
	HapticManager.play_event(HapticManager.Event.BUTTON)
	list.begin_shift(list.build_rise_collapse_targets(old_row))
	var collapse: = list.create_animation_tween()
	collapse.tween_method( func(t: float) -> void :
			if is_instance_valid(list):
				list.set_shift_t(t), 
		0.0, 1.0, COLLAPSE_SEC).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var lift: = list.create_animation_tween()
	lift.tween_property(overlay, "position:y", overlay.position.y + LIFT_Y, LIFT_SEC)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await list.wait_animation(lift, generation)
	if not list.animation_is_active(generation):
		return

	var steps: PackedFloat32Array = _build_step_durations(old_rank - new_rank)
	var scroll_sec: float = 0.0
	for d in steps:
		scroll_sec += d
	var scroll_from: float = list.get_scroll_vertical()
	var scroll_to: float = list.scroll_target_for_row(new_row)
	var need: float = list.row_base_y_at(old_row) - list.row_base_y_at(new_row)
	var by_scroll: float = maxf(scroll_from - scroll_to, 0.0)
	var by_overlay: float = maxf(need - by_scroll, 0.0)
	var ov_from_y: float = overlay.position.y
	_run_crossover(list, overlay, old_rank, new_rank, steps, generation)
	await _scroll_by_steps(list, scroll_from, scroll_to, overlay, ov_from_y, by_overlay, 
		steps, scroll_sec, generation)
	if not list.animation_is_active(generation):
		return
	overlay.reset_tilt()
	overlay.set_rank_only(new_rank)


	var settle: Array = list.build_rise_settle_targets(old_rank, new_rank)
	list.begin_shift(settle[0], settle[1])
	var drop_target_y: float = list.content_y_to_overlay_y(list.row_base_y_at(new_row))
	var drop_start_y: float = overlay.position.y
	var drop: = list.create_animation_tween()
	drop.tween_method( func(t: float) -> void :
			var eased: float = _ease_out_quad(t)
			if is_instance_valid(overlay):
				overlay.position.y = lerpf(drop_start_y, drop_target_y, eased)
			if is_instance_valid(list):
				list.set_shift_t(eased), 
		0.0, 1.0, DROP_SEC)
	await list.wait_animation(drop, generation)
	if not list.animation_is_active(generation):
		return
	overlay.set_rise_outline(false)
	overlay.stop_rise_arrows()
	list.play_rise_land_burst(drop_target_y)

	list.end_shift()
	overlay.visible = false
	list._player_hidden = false
	real_me.visible = true
	AudioManager.play_sfx(&"rank_rise_landed")
	HapticManager.play_event(HapticManager.Event.BUTTON)
	list.set_drag_enabled(true)


static func _play_in_place(list: RankListView, item_me: RankItemView, generation: int) -> void :
	item_me.pivot_offset = item_me.size * 0.5
	var bump: = list.create_animation_tween()
	bump.tween_property(item_me, "scale", Vector2(1.12, 1.12), 0.15)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	bump.tween_property(item_me, "scale", Vector2.ONE, 0.15)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	HapticManager.play_event(HapticManager.Event.BUTTON)
	await list.wait_animation(bump, generation)
	if not list.animation_is_active(generation):
		return
	item_me.pivot_offset = Vector2.ZERO
	AudioManager.play_sfx(&"rank_finish_rise")
	HapticManager.play_event(HapticManager.Event.BUTTON)
	await list.get_tree().create_timer(0.5).timeout


static func _build_step_durations(steps: int) -> PackedFloat32Array:
	var arr: = PackedFloat32Array()
	if steps <= 0:
		return arr
	if steps == 1:
		arr.append(STEP_BASE_SEC * 3.0)
		return arr
	if steps == 2:
		arr.append(STEP_BASE_SEC * 2.0)
		arr.append(STEP_BASE_SEC * 3.0)
		return arr
	for _i in range(steps - 2):
		arr.append(STEP_BASE_SEC)
	arr.append(STEP_BASE_SEC * 2.0)
	arr.append(STEP_BASE_SEC * 3.0)
	return arr


static func _scroll_by_steps(list: RankListView, scroll_from: float, scroll_to: float, 
		overlay: RankItemView, ov_from_y: float, ov_by: float, 
		steps: PackedFloat32Array, total_sec: float, generation: int) -> void :
	if total_sec <= 0.0 or steps.is_empty():
		list.set_scroll_vertical(scroll_to)
		if ov_by > 0.0 and is_instance_valid(overlay):
			overlay.position.y = ov_from_y - ov_by
		return
	var n: int = steps.size()
	var tw: = list.create_animation_tween()
	tw.tween_method( func(elapsed: float) -> void :
			if not is_instance_valid(list):
				return
			var acc: float = 0.0
			var seg: int = n
			var seg_t: float = 1.0
			for i in n:
				if elapsed <= acc + steps[i]:
					seg = i
					seg_t = clampf((elapsed - acc) / maxf(steps[i], 0.0001), 0.0, 1.0)
					break
				acc += steps[i]
			var k: float = 1.0 if seg >= n else (float(seg) + seg_t) / float(n)
			list.set_scroll_vertical(lerpf(scroll_from, scroll_to, k))
			if ov_by > 0.0 and is_instance_valid(overlay):
				overlay.position.y = ov_from_y - ov_by * k, 
		0.0, total_sec, total_sec)
	await list.wait_animation(tw, generation)
	if not list.animation_is_active(generation):
		return
	if not is_instance_valid(list):
		return
	list.set_scroll_vertical(scroll_to)
	if ov_by > 0.0 and is_instance_valid(overlay):
		overlay.position.y = ov_from_y - ov_by


static func _run_crossover(list: RankListView, overlay: RankItemView, 
		old_rank: int, new_rank: int, steps: PackedFloat32Array, generation: int) -> void :
	var n: int = steps.size()
	if n <= 0:
		return
	var acc: float = 0.0
	for i in n:
		var trigger_t: float = acc + steps[i] * 0.5
		acc += steps[i]
		var tilt_sec: float = maxf(TILT_SEC_MIN, steps[i] * 0.5)
		var sound_idx: int = mini(i, _OVER_ITEM_SOUND_KINDS.size() - 1)
		var shown_rank: int = maxi(old_rank - i, new_rank)
		var step_flip: bool = (i % 2) == 1
		var apply: = func() -> void :
			if not is_instance_valid(list) or not list.animation_is_active(generation)\
			or not is_instance_valid(overlay) or not overlay.visible:
				return
			AudioManager.play_sfx(_OVER_ITEM_SOUND_KINDS[sound_idx])
			overlay.set_rank_only(shown_rank)
			overlay.play_right_edge_tilt(TILT_ANGLE_DEG, tilt_sec, step_flip)
		if trigger_t <= 0.0:
			apply.call()
		else:
			var cue: Tween = list.create_animation_tween()
			cue.tween_interval(trigger_t)
			cue.tween_callback(apply)


static func _ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)
