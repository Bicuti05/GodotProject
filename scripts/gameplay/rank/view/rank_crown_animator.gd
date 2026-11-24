class_name RankCrownAnimator
extends Control


const ANCHOR_START: Vector2 = Vector2(499.0, 45.0)
const ANCHOR_PHASE1: Vector2 = Vector2(499.0, -15.0)
const ANCHOR_PHASE2: Vector2 = Vector2(131.0, -37.0)
const ANCHOR_PHASE3: Vector2 = Vector2(180.0, 46.0)
const ANCHOR_ROW_CENTER: Vector2 = Vector2(492.0, 100.0)

const INITIAL_SCALE: float = 0.2
const PHASE1_SEC: float = 0.167
const PHASE1_PEAK_SCALE: float = 3.5
const PHASE1_BOUNCE_SEC: float = 0.083
const PHASE1_BOUNCE_SCALE: float = 2.6
const PHASE1_SETTLE_SEC: float = 0.083
const PHASE1_SETTLE_SCALE: float = 2.7
const PHASE2_SEC: float = 0.25
const PHASE2_SCALE: float = 1.36
const PHASE3_SEC: float = 0.117
const PHASE3_SQUISH: Vector2 = Vector2(1.2, 0.8)
const PHASE4_SEC: float = 0.083
const PHASE4_FINAL_SCALE: float = 0.7

const PHASE2_ROT_DEG: float = -8.0
const PHASE3_ROT_DEG: float = -37.0

const IDLE_PERIOD_SEC: float = 1.5
const IDLE_SQUISH_SEC: float = 0.117
const IDLE_SQUISH_SCALE: Vector2 = Vector2(1.08, 0.8)
const IDLE_STRETCH_SEC: float = 0.1
const IDLE_STRETCH_SCALE: Vector2 = Vector2(1.0, 1.1)
const IDLE_BOUNCE_SEC: float = 0.083
const IDLE_BOUNCE_SCALE: Vector2 = Vector2(1.01, 0.98)
const IDLE_RECOVER_SEC: float = 0.083

var _generation: int = 0
var _home_parent: Node = null
var _attached_item: Control = null
var _fly_tween: Tween = null
var _idle_tween: Tween = null
var _land_tween: Tween = null
var _burst_fx: RankCrownBurstFx = null
var _shine_fx: RankCrownShineFx = null
var _sparkle_fx: RankRowSparkleFx = null


@export var anchor_start: Vector2 = ANCHOR_START
@export var anchor_phase1: Vector2 = ANCHOR_PHASE1
@export var anchor_phase2: Vector2 = ANCHOR_PHASE2
@export var anchor_phase3: Vector2 = ANCHOR_PHASE3
@export var anchor_row_center: Vector2 = ANCHOR_ROW_CENTER
@export var final_scale: float = PHASE4_FINAL_SCALE
@export var final_rotation: float = PHASE3_ROT_DEG

func _ready() -> void :
	_home_parent = get_parent()
	z_as_relative = false
	z_index = 105
	visible = false


func play_fly_in(item: Control, from_resting_pose: bool = false) -> void :
	if item == null:
		return
	var home: CanvasItem = _home_parent as CanvasItem
	var start_pose: Transform2D = home.get_global_transform().affine_inverse() * get_global_transform()
	_kill_tweens()
	var generation: int = _generation
	if from_resting_pose and _shine_fx != null:
		_shine_fx.stop()
	_detach_to_home()

	var p_start: Vector2 = _item_local_to_home(item, anchor_start)
	var p1: Vector2 = _item_local_to_home(item, anchor_phase1)
	var p2: Vector2 = _item_local_to_home(item, anchor_phase2)
	var p3: Vector2 = _item_local_to_home(item, anchor_phase3)

	position = p_start
	scale = Vector2.ONE * INITIAL_SCALE
	rotation_degrees = 0.0
	if from_resting_pose:
		position = start_pose.origin
		scale = start_pose.get_scale()
		rotation = start_pose.get_rotation()
	visible = true

	if _burst_fx != null:
		_burst_fx.play_at(p1)

	_fly_tween = create_tween()
	_fly_tween.set_parallel(true)
	_fly_tween.tween_property(self, "position", p1, PHASE1_SEC).set_trans(Tween.TRANS_LINEAR)
	_fly_tween.tween_property(self, "scale", Vector2.ONE * PHASE1_PEAK_SCALE, PHASE1_SEC)\
	.set_trans(Tween.TRANS_LINEAR)
	if from_resting_pose:
		_fly_tween.tween_property(self, "rotation_degrees", 0.0, PHASE1_SEC).set_trans(Tween.TRANS_LINEAR)

	_fly_tween.chain().tween_property(self, "scale", Vector2.ONE * PHASE1_BOUNCE_SCALE, 
		PHASE1_BOUNCE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_fly_tween.chain().tween_property(self, "scale", Vector2.ONE * PHASE1_SETTLE_SCALE, 
		PHASE1_SETTLE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_fly_tween.chain().tween_property(self, "position", p2, PHASE2_SEC)\
	.set_trans(Tween.TRANS_LINEAR)
	_fly_tween.tween_property(self, "scale", Vector2.ONE * PHASE2_SCALE, PHASE2_SEC)\
	.set_trans(Tween.TRANS_LINEAR)
	_fly_tween.tween_property(self, "rotation_degrees", PHASE2_ROT_DEG, PHASE2_SEC)\
	.set_trans(Tween.TRANS_LINEAR)

	_fly_tween.chain().tween_property(self, "position", p3, PHASE3_SEC)\
	.set_trans(Tween.TRANS_LINEAR)
	_fly_tween.tween_property(self, "scale", PHASE3_SQUISH, PHASE3_SEC).set_trans(Tween.TRANS_LINEAR)
	_fly_tween.tween_property(self, "rotation_degrees", final_rotation, PHASE3_SEC)\
	.set_trans(Tween.TRANS_LINEAR)

	if from_resting_pose:
		_fly_tween.chain().tween_callback( func() -> void :
			AudioManager.play_sfx(&"rank_rise_landed")
			HapticManager.play_event(HapticManager.Event.BUTTON))
	_fly_tween.chain().tween_property(self, "scale", Vector2.ONE * final_scale, 
		PHASE4_SEC).set_trans(Tween.TRANS_LINEAR)

	var tw: Tween = _fly_tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation != _generation:
		return
	_attach_to(item)
	_trigger_border_fx(item)
	_start_idle()


func show_resting(item: Control) -> void :
	if item == null:
		return
	_kill_tweens()
	_attach_to(item)
	var row: = item as RankItemView
	if row != null and row.podium_slot == 0:
		row.show_flow_light()
	_start_idle()


func play_land_bounce() -> void :
	if not visible or _attached_item == null or is_flying():
		return
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	if _land_tween != null and _land_tween.is_valid():
		_land_tween.kill()
	var generation: int = _generation
	var resting: Vector2 = anchor_phase3
	_land_tween = create_tween().set_parallel(true)
	_land_tween.tween_property(self, "position", resting + Vector2(0.0, 10.0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_land_tween.tween_property(self, "scale", Vector2(1.08, 0.82) * final_scale, 0.07)
	_land_tween.tween_property(self, "rotation_degrees", final_rotation + 4.0, 0.07)
	_land_tween.chain().tween_property(self, "position", resting - Vector2(0.0, 7.0), 0.1).set_trans(Tween.TRANS_SINE)
	_land_tween.tween_property(self, "scale", Vector2(0.98, 1.1) * final_scale, 0.1)
	_land_tween.tween_property(self, "rotation_degrees", final_rotation - 2.0, 0.1)
	_land_tween.chain().tween_property(self, "position", resting, 0.18).set_trans(Tween.TRANS_SINE)
	_land_tween.tween_property(self, "scale", Vector2.ONE * final_scale, 0.18)
	_land_tween.tween_property(self, "rotation_degrees", final_rotation, 0.18)
	_land_tween.chain().tween_callback( func() -> void :
		_land_tween = null
		if generation == _generation:
			_start_idle())


func play_collect_drop() -> void :
	if not visible or _attached_item == null or is_flying():
		return

	await play_fly_in(_attached_item, true)


func _trigger_border_fx(item: Control) -> void :
	var row: = item as RankItemView
	if row != null and row.podium_slot == 0:
		row.play_outline_flash()
		row.show_flow_light()
	if _sparkle_fx != null:
		_sparkle_fx.play()


func set_fx(burst: RankCrownBurstFx, shine: RankCrownShineFx, sparkle: RankRowSparkleFx) -> void :
	_burst_fx = burst
	_shine_fx = shine
	_sparkle_fx = sparkle


func hide_crown() -> void :
	_kill_tweens()
	var row: = _attached_item as RankItemView
	if row != null:
		row.reset_first_place_fx()
	_detach_to_home()
	visible = false
	if _burst_fx != null:
		_burst_fx.stop()
	if _shine_fx != null:
		_shine_fx.stop()
	if _sparkle_fx != null:
		_sparkle_fx.stop()


func _item_local_to_home(item: Control, p: Vector2) -> Vector2:
	var home: = _home_parent as CanvasItem
	if home == null:
		return p
	return home.get_global_transform().affine_inverse() * (item.get_global_transform() * p)


func _attach_to(item: Control) -> void :
	if get_parent() != item:
		reparent(item, false)
	_attached_item = item
	position = anchor_phase3
	scale = Vector2.ONE * final_scale
	rotation_degrees = final_rotation
	visible = true
	if _shine_fx != null:
		if _shine_fx.get_parent() != item:
			_shine_fx.reparent(item, false)
		_shine_fx.position = anchor_phase3
	if _sparkle_fx != null:
		if _sparkle_fx.get_parent() != item:
			_sparkle_fx.reparent(item, false)
		_sparkle_fx.position = anchor_row_center


func _detach_to_home() -> void :
	if _home_parent != null and get_parent() != _home_parent:
		reparent(_home_parent, false)
	for fx: Node2D in [_shine_fx, _sparkle_fx]:
		if fx != null and _home_parent != null and fx.get_parent() != _home_parent:
			fx.reparent(_home_parent, false)
	_attached_item = null


func _start_idle() -> void :
	if _shine_fx != null:
		_shine_fx.play()
	var s: float = final_scale
	var wait: float = maxf(IDLE_PERIOD_SEC - IDLE_SQUISH_SEC - IDLE_STRETCH_SEC
		- IDLE_BOUNCE_SEC - IDLE_RECOVER_SEC, 0.0)
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_interval(wait)
	_idle_tween.tween_property(self, "scale", IDLE_SQUISH_SCALE * s, IDLE_SQUISH_SEC)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_idle_tween.tween_property(self, "scale", IDLE_STRETCH_SCALE * s, IDLE_STRETCH_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "scale", IDLE_BOUNCE_SCALE * s, IDLE_BOUNCE_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "scale", Vector2.ONE * s, IDLE_RECOVER_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_tweens() -> void :
	_generation += 1
	if _fly_tween != null and _fly_tween.is_valid():
		_fly_tween.kill()
	_fly_tween = null
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	if _land_tween != null and _land_tween.is_valid():
		_land_tween.kill()
	_land_tween = null


func get_attached_item() -> Control:
	return _attached_item


func is_flying() -> bool:
	return _fly_tween != null and _fly_tween.is_valid() and _fly_tween.is_running()
