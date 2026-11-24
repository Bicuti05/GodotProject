class_name RankTierNav
extends Control


const _SIDE_SCALE: float = 424.8 / 519.2
const _GROUND_CONTACT_OFFSET_RATIO: float = 12.0 / 519.2
const _OFFSCREEN_PAD: float = 24.0
const _SLIDE_SEC: float = 0.35

const _LOCK_HEIGHT_RATIO: float = 0.225

const _ARROW_SIZE_RATIO: float = 0.22
const _ARROW_SIZE_MIN: float = 64.0
const _ARROW_SIZE_MAX: float = 120.0
const _ARROW_EDGE_MARGIN: float = 4.0

@export var five_slot_layout: bool = false

@export var edge_fade: bool = false

@export var slot_scale: float = 1.0

@onready var _slot_center: RankBadgeView = $Center
@onready var _slot_left: RankBadgeView = $Left
@onready var _slot_right: RankBadgeView = $Right
@onready var _slot_far_left: RankBadgeView = $FarLeft
@onready var _slot_far_right: RankBadgeView = $FarRight
@onready var _slot_in: RankBadgeView = $Incoming
@onready var _prev_btn: TextureButton = $PrevBtn
@onready var _next_btn: TextureButton = $NextBtn
@onready var _fade_left: TextureRect = $FadeLeft
@onready var _fade_right: TextureRect = $FadeRight

@onready var _lock_center: TextureRect = $Center / Lock
@onready var _lock_left: TextureRect = $Left / Lock
@onready var _lock_right: TextureRect = $Right / Lock
@onready var _lock_far_left: TextureRect = $FarLeft / Lock
@onready var _lock_far_right: TextureRect = $FarRight / Lock
@onready var _lock_in: TextureRect = $Incoming / Lock

var _center_badge: RankBadgeView = null
var _on_changed: Callable = Callable()

var _player_tier: int = RankBadgeView.TIER_MIN
var _browse_tier: int = RankBadgeView.TIER_MIN
var _active: bool = false
var _animating: bool = false
var _tween: Tween = null
var _locks: Dictionary = {}

var _slot_size: Vector2 = Vector2.ZERO
var _left_ground_global: Vector2 = Vector2.ZERO
var _right_ground_global: Vector2 = Vector2.ZERO
var _center_mid: Vector2 = Vector2.ZERO
var _left_mid: Vector2 = Vector2.ZERO
var _right_mid: Vector2 = Vector2.ZERO
var _far_left_mid: Vector2 = Vector2.ZERO
var _far_right_mid: Vector2 = Vector2.ZERO
var _off_left_mid: Vector2 = Vector2.ZERO
var _off_right_mid: Vector2 = Vector2.ZERO
var _lock_base_pos: Vector2 = Vector2.ZERO


func _ready() -> void :
	_locks = {
		_slot_center: _lock_center, 
		_slot_left: _lock_left, 
		_slot_right: _lock_right, 
		_slot_far_left: _lock_far_left, 
		_slot_far_right: _lock_far_right, 
		_slot_in: _lock_in, 
	}
	for slot: RankBadgeView in _all_slots():
		slot.set_ground_contact_offset_ratio(_GROUND_CONTACT_OFFSET_RATIO)


func setup(center_badge: RankBadgeView, on_changed: Callable = Callable()) -> void :
	_center_badge = center_badge
	_on_changed = on_changed
	_center_badge.set_ground_contact_offset_ratio(_GROUND_CONTACT_OFFSET_RATIO)


func set_ground_positions(left_global: Vector2, right_global: Vector2) -> void :
	_left_ground_global = left_global
	_right_ground_global = right_global
	if not _active:
		return
	_compute_layout()
	if _animating:

		_kill_tween()
		_on_slide_done()
	else:
		_settle_slots()
		_update_arrows()


func activate(player_tier: int) -> void :
	if _center_badge == null:
		SortLogger.error("RankTierNav.activate: setup() 未调用,缺中心徽章引用")
		return
	_player_tier = clampi(player_tier, RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX)
	_browse_tier = _player_tier
	_active = true
	_kill_tween()
	_compute_layout()
	_center_badge.reset_motion()
	_center_badge.visible = false
	visible = true
	_settle_slots()
	_update_arrows()
	_apply_center_idle()


func deactivate() -> void :
	_kill_tween()
	_active = false
	visible = false
	for slot: RankBadgeView in _all_slots():
		if slot != null:
			slot.reset_motion()
	if _slot_in != null:
		_slot_in.visible = false
	if _center_badge != null:
		_center_badge.visible = true


func is_active() -> bool:
	return _active


func get_browse_tier() -> int:
	return _browse_tier


func refresh_player_tier(player_tier: int) -> void :
	if not _active or _animating:
		return
	_player_tier = clampi(player_tier, RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX)
	_refresh_sprites()


func cheat_force_tier(tier: int) -> void :
	if not _active:
		return
	activate(tier)


func _on_prev_btn_pressed() -> void :
	_step(-1)


func _on_next_btn_pressed() -> void :
	_step(1)


func _step(dir: int) -> void :
	if not _active or _animating:
		return
	var to_tier: int = _browse_tier + dir
	if to_tier < RankBadgeView.TIER_MIN or to_tier > RankBadgeView.TIER_MAX:
		return
	_hide_arrows()
	_play_slide(dir, to_tier)


func _play_slide(dir: int, to_tier: int) -> void :
	_compute_layout()
	_kill_tween()
	_browse_tier = to_tier
	_animating = true
	_slot_center.reset_motion(_player_tier < to_tier)

	var slots: Array[RankBadgeView] = _ring_slots()
	var mids: Array[Vector2] = _ring_mids()
	var center_i: int = _ring_center_index()
	var n: int = slots.size()

	var in_tier: int = to_tier + dir * center_i
	var in_valid: bool = in_tier >= RankBadgeView.TIER_MIN and in_tier <= RankBadgeView.TIER_MAX
	if in_valid:
		_apply_slot_look(_slot_in, in_tier)
		_apply_slot(_slot_in, _off_right_mid if dir > 0 else _off_left_mid, _SIDE_SCALE)
		_slot_in.visible = true
	else:
		_slot_in.visible = false

	_tween = create_tween().set_parallel(true)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i: int in range(n):
		var slot: RankBadgeView = slots[i]
		if not slot.visible:
			continue
		var to_i: int = i - dir
		var to_center: bool = to_i == center_i
		if to_i < 0:
			_tween_slot(slot, _off_left_mid, _SIDE_SCALE)
		elif to_i >= n:
			_tween_slot(slot, _off_right_mid, _SIDE_SCALE)
		else:
			_tween_slot(slot, mids[to_i], 1.0 if to_center else _SIDE_SCALE)
	if _slot_in.visible:
		_tween_slot(_slot_in, mids[n - 1] if dir > 0 else mids[0], _SIDE_SCALE)
	_tween.chain().tween_callback(_on_slide_done)


func _on_slide_done() -> void :
	_animating = false
	_settle_slots()
	_update_arrows()
	_apply_center_idle()
	if _on_changed.is_valid():
		_on_changed.call(_browse_tier)


func _apply_center_idle() -> void :
	_slot_center.start_idle_fx(_player_tier >= _browse_tier)


func _kill_tween() -> void :
	_animating = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _all_slots() -> Array[RankBadgeView]:
	return [_slot_center, _slot_left, _slot_right, _slot_far_left, _slot_far_right, _slot_in]


func _ring_slots() -> Array[RankBadgeView]:
	if five_slot_layout:
		return [_slot_far_left, _slot_left, _slot_center, _slot_right, _slot_far_right]
	return [_slot_left, _slot_center, _slot_right]


func _ring_mids() -> Array[Vector2]:
	if five_slot_layout:
		return [_far_left_mid, _left_mid, _center_mid, _right_mid, _far_right_mid]
	return [_left_mid, _center_mid, _right_mid]


func _ring_center_index() -> int:
	return 2 if five_slot_layout else 1


func _settle_slots() -> void :
	var slots: Array[RankBadgeView] = _ring_slots()
	var mids: Array[Vector2] = _ring_mids()
	var center_i: int = _ring_center_index()
	for i: int in range(slots.size()):
		_apply_slot(slots[i], mids[i], 1.0 if i == center_i else _SIDE_SCALE)
	_slot_in.visible = false
	_refresh_sprites()


func _refresh_sprites() -> void :
	var slots: Array[RankBadgeView] = _ring_slots()
	var center_i: int = _ring_center_index()
	for i: int in range(slots.size()):
		var slot: RankBadgeView = slots[i]
		var tier: int = _browse_tier + i - center_i
		slot.visible = tier >= RankBadgeView.TIER_MIN and tier <= RankBadgeView.TIER_MAX
		if slot.visible:
			_apply_slot_look(slot, tier)
	if not five_slot_layout:
		_slot_far_left.visible = false
		_slot_far_right.visible = false


func _apply_slot_look(slot: RankBadgeView, tier: int) -> void :
	var reached: bool = _player_tier >= tier
	slot.set_tier(tier, not reached)
	slot.set_badge_tint(Color.WHITE)
	var lock: TextureRect = _lock_of(slot)
	if lock != null:
		lock.visible = not reached


func _lock_of(slot: RankBadgeView) -> TextureRect:
	return _locks.get(slot, null) as TextureRect


func _apply_slot(slot: RankBadgeView, mid: Vector2, scale_ratio: float) -> void :
	slot.position = mid - _slot_size * 0.5
	slot.scale = Vector2(scale_ratio, scale_ratio)


func _tween_slot(slot: RankBadgeView, mid: Vector2, scale_ratio: float) -> void :
	_tween.tween_property(slot, "position", mid - _slot_size * 0.5, _SLIDE_SEC)
	_tween.tween_property(slot, "scale", Vector2(scale_ratio, scale_ratio), _SLIDE_SEC)


func _update_arrows() -> void :
	_prev_btn.visible = _browse_tier > RankBadgeView.TIER_MIN
	_next_btn.visible = _browse_tier < RankBadgeView.TIER_MAX


func _hide_arrows() -> void :
	_prev_btn.visible = false
	_next_btn.visible = false


func _compute_layout() -> void :
	if _center_badge == null:
		return
	var badge_size: Vector2 = _center_badge.size
	if badge_size.x <= 0.0 or badge_size.y <= 0.0:
		badge_size = _center_badge.custom_minimum_size
	if badge_size.x <= 0.0 or badge_size.y <= 0.0:
		badge_size = Vector2(453.2, 519.2)

	var to_local: Transform2D = get_global_transform().affine_inverse()
	_center_mid = to_local * _center_badge.global_position + badge_size * 0.5
	_slot_size = badge_size * maxf(slot_scale, 0.01)

	var side_half_h: float = _slot_size.y * _SIDE_SCALE * 0.5
	_left_mid = to_local * _left_ground_global - Vector2(0.0, side_half_h)
	_right_mid = to_local * _right_ground_global - Vector2(0.0, side_half_h)
	var left_dx: float = _center_mid.x - _left_mid.x
	var right_dx: float = _right_mid.x - _center_mid.x
	_far_left_mid = _left_mid - Vector2(left_dx, 0.0)
	_far_right_mid = _right_mid + Vector2(right_dx, 0.0)

	var side_half_w: float = _slot_size.x * _SIDE_SCALE * 0.5
	var outer_left_x: float = _far_left_mid.x if five_slot_layout else _left_mid.x
	var outer_right_x: float = _far_right_mid.x if five_slot_layout else _right_mid.x
	_off_left_mid = Vector2(
		minf(outer_left_x - left_dx, - side_half_w - _OFFSCREEN_PAD), _left_mid.y)
	_off_right_mid = Vector2(
		maxf(outer_right_x + right_dx, size.x + side_half_w + _OFFSCREEN_PAD), _right_mid.y)

	var lock_side: float = maxf(_slot_size.y * _LOCK_HEIGHT_RATIO, 1.0)
	_lock_base_pos = (_slot_size - Vector2(lock_side, lock_side)) * 0.5

	for slot: RankBadgeView in _all_slots():
		slot.size = _slot_size
		slot.pivot_offset = _slot_size * 0.5
		var lock: TextureRect = _lock_of(slot)
		if lock != null:
			lock.size = Vector2(lock_side, lock_side)
			lock.position = _lock_base_pos

	_layout_fades(side_half_w)
	_layout_arrows(side_half_w)


func _layout_fades(side_half_w: float) -> void :
	if not edge_fade:
		_fade_left.visible = false
		_fade_right.visible = false
		return
	var outer_mid_x: float = _far_left_mid.x if five_slot_layout else _left_mid.x
	var visible_w: float
	if five_slot_layout:
		visible_w = (outer_mid_x + side_half_w) - maxf(outer_mid_x - side_half_w, 0.0)
	else:
		visible_w = outer_mid_x - side_half_w
	var band: Vector2 = Vector2(maxf(visible_w, 1.0), _slot_size.y)
	var top: float = _center_mid.y - band.y * 0.5
	_fade_left.visible = true
	_fade_left.size = band
	_fade_left.position = Vector2(0.0, top)
	_fade_right.visible = true
	_fade_right.size = band
	_fade_right.position = Vector2(size.x - band.x, top)


func _layout_arrows(side_half_w: float) -> void :
	var arrow_size: float = clampf(
		_slot_size.x * _ARROW_SIZE_RATIO, _ARROW_SIZE_MIN, _ARROW_SIZE_MAX)
	var mid_x: float
	if five_slot_layout:
		mid_x = (maxf(_far_left_mid.x - side_half_w, 0.0)
			+ _far_left_mid.x + side_half_w) * 0.5
	else:
		mid_x = (_left_mid.x - side_half_w) * 0.5
	mid_x = maxf(mid_x, arrow_size * 0.5 + _ARROW_EDGE_MARGIN)
	var half: Vector2 = Vector2(arrow_size, arrow_size) * 0.5
	_prev_btn.size = Vector2(arrow_size, arrow_size)
	_prev_btn.position = Vector2(mid_x, _center_mid.y) - half
	_next_btn.size = Vector2(arrow_size, arrow_size)
	_next_btn.position = Vector2(size.x - mid_x, _center_mid.y) - half
	_prev_btn.pivot_offset = half
	_next_btn.pivot_offset = half
