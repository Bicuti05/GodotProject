class_name PropBtn
extends Button


const DEAD_PROP_MOTION: Animation = preload("res://scripts/widget/prop_btn/dead_prop_motion.tres")
const TOOL_PROMPT_ORANGE: Color = Color(1.0, 0.58695984, 0.0, 1.0)



























enum PropState{LOCKED, FREE, COUNT, COIN, AD, NOT_READY, DISABLED}







enum PropType{HINT, UNDO, ROPE, FILL_POT}

const _DEFS: = {
	PropType.HINT: {"id": "hint", "unlock_level": 3, "init_count": 3, "coin_price": 400}, 
	PropType.UNDO: {"id": "undo", "unlock_level": 2, "init_count": 3, "coin_price": 400}, 
	PropType.ROPE: {"id": "rope", "unlock_level": 5, "init_count": 1, "coin_price": 1200}, 

	PropType.FILL_POT: {"id": "fill_pot", "unlock_level": 7, "init_count": 0, "coin_price": 1200}, 
}

signal pressed_prop(prop_id: String)





const _BASE_SIZE: Vector2 = Vector2(204.0, 228.0)












const _BADGE_TEXT_SIZE: int = 46





const BADGE_CENTER_X: float = 174.0
const BADGE_TEXT_PAD: float = 26.0

const BADGE_MIN_W: float = 88.0




const COIN_BADGE_BASE_W: float = 104.0
const COIN_BADGE_TEXT_LEFT: float = 65.0
const COIN_BADGE_TEXT_RIGHT_PAD: float = 19.0

@export var bg_texture: Texture2D
@export var bg_disabled_texture: Texture2D
@export var hint_texture: Texture2D
@export var undo_texture: Texture2D
@export var rope_texture: Texture2D
@export var rope_dead_texture: Texture2D
@export var fill_pot_texture: Texture2D
@export var hint_disabled_texture: Texture2D
@export var undo_disabled_texture: Texture2D
@export var rope_disabled_texture: Texture2D
@export var fill_pot_disabled_texture: Texture2D
@export var badge_orange_bg: Texture2D
@export var badge_green_bg: Texture2D
@export var badge_blue_bg: Texture2D
@export var badge_gray_bg: Texture2D
@export var coin_texture: Texture2D
@export var coin_disabled_texture: Texture2D

@onready var _hint_guide: Node2D = $HintGuideMotion
@onready var _bg: TextureRect = $Bg
@onready var _dead_glow: TextureRect = $DeadGlow

@onready var _undo_guide_motion: Node2D = $UndoGuideMotion
@onready var _icon: TextureRect = $Icon
@onready var _badge: Control = $Badge
@onready var _badge_bg: NinePatchRect = $Badge / BadgeBg
@onready var _badge_number: Label = $Badge / Number
@onready var _coin: Control = $CoinBadge
@onready var _coin_bg: NinePatchRect = $CoinBadge / BadgeBg
@onready var _coin_icon: TextureRect = $CoinBadge / CoinIcon
@onready var _coin_number: Label = $CoinBadge / CoinNumber
@onready var _lock: Control = $LockOverlay
@onready var _lock_icon: TextureRect = $LockOverlay / LockIcon
@onready var _lock_lv: Label = $LockOverlay / LvLabel

var _type: int = PropType.HINT
var _dead_dialog_icon: bool = false

var _state: int = PropState.LOCKED


var _business_state: int = PropState.LOCKED

var _unlock_revealed: bool = true


var _affordable: bool = false


var _effect_available: bool = true
var _display_count: int = 0
var _highlight_tween: Tween = null
var _dead_shake_tween: Tween = null
var _dead_motion_targets: Array[Dictionary] = []
var _dead_icon_rotation: float = 0.0
var _dead_icon_last_rotation: float = 0.0
var _dead_recommended: bool = false
var _hint_prompt_playing: bool = false
var _hint_prompt_stopping: bool = false
var _hint_prompt_time: float = 0.0

var _undo_guide_preview_unavailable: bool = false



var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void :
	pressed.connect(_on_pressed)
	button_down.connect(_on_button_down)
	visibility_changed.connect(_on_visibility_changed)
	button_down.connect(_on_hint_guide_button_down)
	visibility_changed.connect(_on_hint_guide_visibility_changed)


func configure(type: int) -> void :
	stop_hint_guide_motion(true)
	if _type != type:
		set_dead_glow(false)
		stop_undo_guide_motion(true)
		_dead_dialog_icon = false
	_type = type
	if _icon == null:
		return
	_icon.texture = _icon_texture_for(false)




func _icon_texture_for(disabled_visual: bool) -> Texture2D:
	if disabled_visual:
		match _type:
			PropType.HINT:
				return hint_disabled_texture
			PropType.UNDO:
				return undo_disabled_texture
			PropType.ROPE:
				return rope_disabled_texture
			PropType.FILL_POT:
				return fill_pot_disabled_texture
		return null
	match _type:
		PropType.HINT:
			return hint_texture
		PropType.UNDO:
			return undo_texture
		PropType.ROPE:
			return rope_dead_texture if _dead_dialog_icon else rope_texture
		PropType.FILL_POT:
			return fill_pot_texture
	return null



func set_dead_dialog_icon(enabled: bool) -> void :
	if _dead_dialog_icon == enabled:
		return
	_dead_dialog_icon = enabled
	if _icon != null:
		_apply_visual()









var _early_unlocked: bool = false

func set_early_unlocked(enabled: bool) -> void :
	_early_unlocked = enabled


func refresh(
	level: int, coins: int, available: bool, free: bool, count: int, ad_ready: bool, 
	unlock_revealed: bool = true
) -> void :
	var unlock_level: int = _DEFS[_type]["unlock_level"]
	var coin_price: int = get_base_coin_price()
	var locked: bool = level < unlock_level and not _early_unlocked
	var affordable: bool = coins >= coin_price
	if locked:
		_business_state = PropState.LOCKED
	elif free:
		_business_state = PropState.FREE
	elif count > 0:
		_business_state = PropState.COUNT
	elif affordable:
		_business_state = PropState.COIN
	elif ad_ready:
		_business_state = PropState.AD
	else:
		_business_state = PropState.NOT_READY
	_effect_available = available
	_affordable = affordable
	_display_count = count
	_unlock_revealed = unlock_revealed
	_resolve_display_state()
	_apply_visual()













func needs_ad_ready(level: int, coins: int, available: bool, free: bool, count: int, 
		unlock_revealed: bool = true) -> bool:
	if (level < _DEFS[_type]["unlock_level"] and not _early_unlocked) or not unlock_revealed or not available:
		return false
	return not (free or count > 0 or coins >= get_base_coin_price())



func set_unlock_revealed(revealed: bool) -> void :
	_unlock_revealed = revealed
	_resolve_display_state()
	_apply_visual()


func _resolve_display_state() -> void :
	var data_locked: bool = _business_state == PropState.LOCKED
	var display_locked: bool = data_locked or not _unlock_revealed
	var actionable: bool = _business_state == PropState.FREE\
	or _business_state == PropState.COUNT\
	or (_business_state == PropState.COIN and _affordable)\
	or _business_state == PropState.AD
	var unavailable: bool = data_locked or not _effect_available or not actionable



	var ad_not_ready_only: bool = _business_state == PropState.NOT_READY and _effect_available

	disabled = false
	if display_locked:
		_state = PropState.LOCKED
	elif unavailable and not ad_not_ready_only:
		_state = PropState.DISABLED
	else:
		_state = _business_state



func get_unlock_level() -> int:
	return _DEFS[_type]["unlock_level"]




static func get_unlock_level_by_id(prop_id: String) -> int:
	for def: Dictionary in _DEFS.values():
		if def["id"] == prop_id:
			return def["unlock_level"]
	return 0



func get_base_coin_price() -> int:
	return _DEFS[_type]["coin_price"]


func get_state() -> int:
	return _state



func get_business_state() -> int:
	return _business_state


func get_prop_id() -> String:
	return _DEFS[_type]["id"]


func get_reward_collect_global_rect() -> Rect2:
	return _icon.get_global_rect()


func set_reward_count_display(count: int) -> void :
	_display_count = count
	_business_state = PropState.COUNT
	_state = PropState.COUNT
	_apply_visual()



func play_undo_guide_motion(loop: bool = true, preview_unavailable: bool = false) -> bool:
	if not _can_play_undo_guide_motion(preview_unavailable):
		stop_undo_guide_motion(true)
		return false
	_sync_guide_badge_obstacles(_undo_guide_motion)
	var playing: bool = bool(_undo_guide_motion.call("play", loop))
	_undo_guide_preview_unavailable = preview_unavailable if playing else false
	return playing



func stop_undo_guide_motion(immediate: bool = false) -> void :
	_undo_guide_preview_unavailable = false
	if is_instance_valid(_undo_guide_motion):
		_undo_guide_motion.call("stop", immediate)


func is_undo_guide_motion_playing() -> bool:
	return is_instance_valid(_undo_guide_motion)\
	and bool(_undo_guide_motion.call("is_playing"))



func is_unlock_highlight_playing() -> bool:
	return _highlight_tween != null and _highlight_tween.is_valid()


func _can_play_undo_guide_motion(preview_unavailable: bool = false) -> bool:
	if not is_node_ready() or not is_instance_valid(_undo_guide_motion):
		return false
	if _type != PropType.UNDO or not is_visible_in_tree() or disabled or is_pressed():
		return false
	if not preview_unavailable and get_state() in [PropState.LOCKED, PropState.DISABLED, PropState.NOT_READY]:
		return false
	return not _dead_glow.visible and not is_unlock_highlight_playing()


func _sync_guide_badge_obstacles(motion: Node2D) -> void :
	if not is_instance_valid(motion):
		return
	var badge_rects: Array[Rect2] = []

	if _badge != null and _badge.visible:
		badge_rects.append(_badge.get_rect())
	if _coin != null and _coin.visible:
		badge_rects.append(_coin.get_rect())
	motion.call("set_badge_obstacles", badge_rects)



func set_dead_glow(visible_now: bool) -> void :
	if _dead_glow == null:
		return
	_dead_recommended = visible_now
	if visible_now:
		stop_undo_guide_motion(true)
		stop_hint_guide_motion(true)
		_dead_glow.visible = true
		_start_dead_shake()
	elif not _hint_prompt_playing:
		_dead_glow.visible = false
		_stop_dead_shake()


func _start_dead_shake(loop: bool = true) -> void :

	if (_highlight_tween != null and _highlight_tween.is_valid())\
	or (_dead_shake_tween != null and _dead_shake_tween.is_valid())\
	or not is_visible_in_tree() or is_pressed():
		return

	for target: Control in [_bg, _icon, _dead_glow]:
		_dead_motion_targets.append({"node": target, "scale": target.scale, 
			"pivot": target.pivot_offset, "last_scale": target.scale, 
			"motion_pivot": target.size * 0.5})
		target.pivot_offset = target.size * 0.5
	_dead_icon_rotation = _icon.rotation
	_dead_icon_last_rotation = _icon.rotation
	_dead_glow.modulate = TOOL_PROMPT_ORANGE
	_apply_dead_motion(0.0)
	_dead_shake_tween = create_tween()
	if loop:
		_dead_shake_tween.set_loops()
	_dead_shake_tween.tween_method(_apply_dead_motion, 0.0, DEAD_PROP_MOTION.length, 
		DEAD_PROP_MOTION.length)
	if not loop:
		_dead_shake_tween.finished.connect(_stop_dead_shake)


func _apply_dead_motion(time: float) -> void :
	if _dead_motion_targets.is_empty():
		return
	if _hint_prompt_playing:
		_hint_prompt_time = time
	var body_scale: Vector2 = Vector2(
		DEAD_PROP_MOTION.bezier_track_interpolate(0, time), 
		DEAD_PROP_MOTION.bezier_track_interpolate(1, time))
	var icon_scale: Vector2 = Vector2(
		DEAD_PROP_MOTION.bezier_track_interpolate(2, time), 
		DEAD_PROP_MOTION.bezier_track_interpolate(3, time))
	for entry: Dictionary in _dead_motion_targets:
		var target: Control = entry["node"]

		if not target.scale.is_equal_approx(entry["last_scale"])\
		or not target.pivot_offset.is_equal_approx(entry["motion_pivot"]):
			_stop_dead_shake()
			return
		var next_scale: Vector2 = entry["scale"] * body_scale
		if target == _icon:
			next_scale *= icon_scale
		target.scale = next_scale
		entry["last_scale"] = next_scale
	if not is_equal_approx(_icon.rotation, _dead_icon_last_rotation):
		_stop_dead_shake()
		return
	_icon.rotation = _dead_icon_rotation + DEAD_PROP_MOTION.bezier_track_interpolate(4, time)
	_dead_icon_last_rotation = _icon.rotation
	var light: Color = DEAD_PROP_MOTION.value_track_interpolate(5, time)
	_dead_glow.modulate.a = light.a


func _stop_dead_shake() -> void :
	if _dead_shake_tween != null and _dead_shake_tween.is_valid():
		_dead_shake_tween.kill()
	_dead_shake_tween = null
	for entry: Dictionary in _dead_motion_targets:
		var target: Control = entry["node"]
		if target.scale.is_equal_approx(entry["last_scale"]):
			target.scale = entry["scale"]
		if target.pivot_offset.is_equal_approx(entry["motion_pivot"]):
			target.pivot_offset = entry["pivot"]
	if not _dead_motion_targets.is_empty() and is_equal_approx(_icon.rotation, _dead_icon_last_rotation):
		_icon.rotation = _dead_icon_rotation
	_dead_motion_targets.clear()
	if _hint_prompt_playing and _dead_glow != null:
		_dead_glow.visible = false
	_hint_prompt_playing = false
	_hint_prompt_stopping = false
	if _dead_glow != null:
		_dead_glow.modulate.a = 0.0


func _on_pressed() -> void :
	pressed_prop.emit(_DEFS[_type]["id"])


func _on_button_down() -> void :
	set_dead_glow(false)
	stop_undo_guide_motion(true)


func _on_visibility_changed() -> void :
	if not is_visible_in_tree():
		set_dead_glow(false)
		stop_undo_guide_motion(true)


func _exit_tree() -> void :
	_stop_dead_shake()
	stop_undo_guide_motion(true)
	stop_hint_guide_motion(true)


func play_hint_guide_motion(loop: bool, _new_background: bool) -> bool:
	if not is_node_ready():
		return false
	if _type != PropType.HINT or not is_visible_in_tree() or disabled or is_pressed()\
	or _state in [PropState.LOCKED, PropState.DISABLED, PropState.NOT_READY]\
	or _dead_recommended\
	or (_highlight_tween != null and _highlight_tween.is_valid()):
		return false
	if loop and is_hint_guide_motion_playing() and not _hint_prompt_stopping:
		return true
	stop_hint_guide_motion(true)
	stop_undo_guide_motion(true)
	_hint_prompt_playing = true
	_dead_glow.visible = true
	_start_dead_shake(loop)
	return is_hint_guide_motion_playing()


func is_hint_guide_motion_playing() -> bool:
	return _hint_prompt_playing and _dead_shake_tween != null and _dead_shake_tween.is_valid()


func stop_hint_guide_motion(immediate: bool = false) -> void :

	if is_instance_valid(_hint_guide):
		_hint_guide.call("stop", true)
	if not _hint_prompt_playing:
		return
	if immediate:
		_stop_dead_shake()
		return
	if _hint_prompt_stopping:
		return
	_hint_prompt_stopping = true
	_dead_shake_tween.kill()
	var scales: Array[Vector2] = []
	for entry: Dictionary in _dead_motion_targets:
		scales.append((entry["node"] as Control).scale)
	var rotation_from: float = _icon.rotation
	var alpha_from: float = _dead_glow.modulate.a
	_dead_shake_tween = create_tween()
	_dead_shake_tween.tween_method( func(weight: float) -> void :
		if not is_equal_approx(_icon.rotation, _dead_icon_last_rotation):
			_stop_dead_shake()
			return
		for i: int in range(_dead_motion_targets.size()):
			var entry: Dictionary = _dead_motion_targets[i]
			var target: Control = entry["node"]
			if not target.scale.is_equal_approx(entry["last_scale"])\
			or not target.pivot_offset.is_equal_approx(entry["motion_pivot"]):
				_stop_dead_shake()
				return
			target.scale = scales[i].lerp(entry["scale"], weight)
			entry["last_scale"] = target.scale
		_icon.rotation = lerpf(rotation_from, _dead_icon_rotation, weight)
		_dead_icon_last_rotation = _icon.rotation
		_dead_glow.modulate.a = alpha_from * (1.0 - weight), 0.0, 1.0, 0.12)
	_dead_shake_tween.finished.connect(_stop_dead_shake)


func _on_hint_guide_button_down() -> void :

	stop_hint_guide_motion(true)


func _on_hint_guide_visibility_changed() -> void :
	if not is_visible_in_tree():
		stop_hint_guide_motion(true)














func set_base_scale(s: Vector2) -> void :
	_base_scale = s
	pivot_offset = _BASE_SIZE * 0.5
	if _highlight_tween == null or not _highlight_tween.is_valid():
		scale = _base_scale


func play_unlock_highlight() -> void :
	stop_undo_guide_motion(true)
	stop_hint_guide_motion(true)
	_stop_dead_shake()
	if _highlight_tween != null and _highlight_tween.is_valid():
		_highlight_tween.kill()
	pivot_offset = _BASE_SIZE * 0.5
	_highlight_tween = create_tween().set_loops()
	_highlight_tween.tween_property(self, "scale", _base_scale * 1.12, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_highlight_tween.tween_property(self, "scale", _base_scale, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_unlock_highlight() -> void :
	if _highlight_tween != null and _highlight_tween.is_valid():
		_highlight_tween.kill()
	_highlight_tween = null
	scale = _base_scale
	if _dead_recommended:
		_start_dead_shake()




func _layout_badge(text: String) -> void :
	if _badge_number == null or _badge == null:
		return
	_badge_number.text = text
	var font: Font = _badge_number.get_theme_font("font")
	var fs: int = _badge_number.get_theme_font_size("font_size")
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x\
	if font != null else 0.0
	var w: float = maxf(BADGE_MIN_W, text_w + BADGE_TEXT_PAD * 2.0)
	_badge.offset_left = BADGE_CENTER_X - w * 0.5
	_badge.offset_right = BADGE_CENTER_X + w * 0.5




func _layout_coin_badge(price_text: String) -> void :
	if _coin_number == null or _coin == null:
		return
	_coin_number.text = price_text
	var font: Font = _coin_number.get_theme_font("font")
	var fs: int = _coin_number.get_theme_font_size("font_size")
	var text_w: float = font.get_string_size(price_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x\
	if font != null else 0.0
	var w: float = maxf(COIN_BADGE_TEXT_LEFT + text_w + COIN_BADGE_TEXT_RIGHT_PAD, COIN_BADGE_BASE_W)
	_coin.offset_left = BADGE_CENTER_X - w * 0.5
	_coin.offset_right = BADGE_CENTER_X + w * 0.5


func _apply_visual() -> void :

	var preview_unavailable: bool = _undo_guide_preview_unavailable and is_undo_guide_motion_playing()
	if not _can_play_undo_guide_motion(preview_unavailable):
		stop_undo_guide_motion(true)
	if _state in [PropState.LOCKED, PropState.DISABLED, PropState.NOT_READY]:
		stop_hint_guide_motion()


	var locked: bool = _state == PropState.LOCKED
	var is_free: bool = _business_state == PropState.FREE
	var is_count: bool = _business_state == PropState.COUNT
	var is_coin: bool = _business_state == PropState.COIN
	var is_ad: bool = _business_state == PropState.AD
	var is_not_ready: bool = _business_state == PropState.NOT_READY
	var is_disabled_visual: bool = _state == PropState.DISABLED
	var is_body_disabled_visual: bool = is_disabled_visual




	if _bg != null:
		_bg.texture = bg_disabled_texture if locked or is_body_disabled_visual else bg_texture
	if _icon != null:
		_icon.visible = not locked
		_icon.texture = _icon_texture_for(is_body_disabled_visual)


	if _lock != null:
		_lock.visible = locked
		if _lock_icon != null:
			_lock_icon.visible = locked
		if _lock_lv != null:
			_lock_lv.text = "Lv.%d" % _DEFS[_type]["unlock_level"]


	if _badge != null:
		var show_badge: bool = not locked and (is_count or is_ad or is_not_ready or is_free)
		_badge.visible = show_badge
		if show_badge and _badge_bg != null and _badge_number != null:
			if is_disabled_visual or is_not_ready:
				_badge_bg.texture = badge_gray_bg
			elif is_free:
				_badge_bg.texture = badge_green_bg
			elif is_count:
				_badge_bg.texture = badge_blue_bg
			else:
				_badge_bg.texture = badge_orange_bg
			if is_free:

				_layout_badge("FREE")
			elif is_ad or is_not_ready:
				_layout_badge("AD")
			else:
				_layout_badge(str(_display_count))


	if _coin != null:
		_coin.visible = not locked and is_coin
		if _coin.visible:
			_layout_coin_badge(str(get_base_coin_price()))
			if _coin_bg != null:
				_coin_bg.texture = badge_gray_bg if is_disabled_visual else badge_orange_bg
			_coin.modulate = Color.WHITE
			if _coin_icon != null:
				_coin_icon.texture = coin_disabled_texture if is_disabled_visual else coin_texture

	_sync_guide_badge_obstacles(_undo_guide_motion)
	_sync_guide_badge_obstacles(_hint_guide)
