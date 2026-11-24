class_name RankIntroductionDialog
extends PageScene


signal closed

const _FIT_BASE_FONT_BODY: int = 48
const _FIT_MIN_FONT_BODY: int = 20
const _FIT_BASE_FONT_TITLE: int = 100
const _FIT_MIN_FONT_TITLE: int = 48
const _FIT_TITLE_MAX_WIDTH: float = 672.0
const _FIT_LINE_HEIGHT: float = 96.0
const _FIT_LINE2_HEIGHT: float = 120.0

const _SLIDE_PX: float = 32.0
const _STAGGER_SEC: float = 0.11
const _ITEM_DUR: float = 0.4
const _OVERLAY_DUR: float = 0.25
const _EXIT_DUR: float = 0.2
const _REST_POS_META: StringName = &"_intro_rest_pos"

@onready var _overlay: ColorRect = $Root / Overlay
@onready var _content: Control = $Root / Content
@onready var _title: Label = $Root / Content / Title
@onready var _flowers: TextureRect = $Root / Content / Flowers
@onready var _arrow_down: TextureRect = $Root / Content / ArrowDown
@onready var _line1: Label = $Root / Content / Line1
@onready var _row1: TextureRect = $Root / Content / Row1
@onready var _row2: TextureRect = $Root / Content / Row2
@onready var _row3: TextureRect = $Root / Content / Row3
@onready var _line2: Label = $Root / Content / Line2
@onready var _arrow_left: TextureRect = $Root / Content / ArrowLeft
@onready var _badge_1: TextureRect = $Root / Content / Badge1
@onready var _badge_2: TextureRect = $Root / Content / Badge2
@onready var _badge_3: TextureRect = $Root / Content / Badge3
@onready var _line3: Label = $Root / Content / Line3
@onready var _tap_hint: Label = $Root / Content / TapHint

var _closing: bool = false
var _generation: int = 0
var _enter_tween: Tween
var _exit_tween: Tween


func _ready() -> void :
	_cache_rest_positions()


func _on_show(_params: Dictionary = {}) -> void :
	_generation += 1
	_closing = false
	_fit_all_text()
	visible = true
	_kill_tweens()
	_prepare_shell()
	_prepare_groups_hidden()

	Tracker.track_scr_show(TrackingEvents.SCR_CHALLENGE_START)
	_play_enter()


func _fit_all_text() -> void :
	_fit_title_font_size()
	for line: Label in [_line1, _line3, _tap_hint]:
		_fit_label_font_size(line, _FIT_BASE_FONT_BODY, _FIT_MIN_FONT_BODY, _FIT_LINE_HEIGHT)
	_fit_label_font_size(_line2, _FIT_BASE_FONT_BODY, _FIT_MIN_FONT_BODY, _FIT_LINE2_HEIGHT)


func _fit_title_font_size() -> void :
	var font: Font = _title.get_theme_font("font")
	var rendered: String = tr(_title.text)
	if font == null or rendered.is_empty():
		return
	var font_size: int = _FIT_BASE_FONT_TITLE
	while font_size > _FIT_MIN_FONT_TITLE:
		var w: float = font.get_string_size(
			rendered, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
		if w <= _FIT_TITLE_MAX_WIDTH:
			break
		font_size -= 2
	_title.add_theme_font_size_override("font_size", font_size)


func _fit_label_font_size(label: Label, base_size: int, min_size: int, max_height: float = 0.0) -> void :
	var font: Font = label.get_theme_font("font")
	var rendered: String = tr(label.text)
	if font == null or rendered.is_empty():
		return
	var outline: float = float(label.get_theme_constant("outline_size"))
	var avail_w: float = (label.offset_right - label.offset_left) - outline * 2.0

	var height: float = max_height if max_height > 0.0 else label.offset_bottom - label.offset_top
	var avail_h: float = height - outline * 2.0
	if avail_w <= 0.0 or avail_h <= 0.0:
		return
	var font_size: int = base_size
	while true:
		label.add_theme_font_size_override("font_size", font_size)

		if label.get_combined_minimum_size().y <= avail_h or font_size <= min_size:
			break
		font_size -= 2
	if max_height > 0.0:
		label.offset_bottom = label.offset_top + max_height


func _on_tap_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_CHALLENGE_START)
	_close()


func _on_back_request() -> void :
	_close()


func _close() -> void :
	if _closing:
		return
	_closing = true
	var generation: int = _generation
	_kill_tweens()
	_snap_groups_final()
	_exit_tween = create_tween()
	_exit_tween.set_parallel(true)
	_exit_tween.tween_property(_overlay, "self_modulate:a", 0.0, _EXIT_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(_content, "modulate:a", 0.0, _EXIT_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var tw: Tween = _exit_tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation != _generation:
		return
	visible = false
	closed.emit()


func _stagger_groups() -> Array:
	return [
		[_title], 
		[_flowers, _arrow_down, _line1], 
		[_row1], 
		[_row2], 
		[_row3], 
		[_line2], 
		[_badge_1, _badge_2, _badge_3, _arrow_left], 
		[_line3], 
		[_tap_hint], 
	]


func _cache_rest_positions() -> void :
	for group: Array in _stagger_groups():
		for n: CanvasItem in group:
			if n.has_meta(_REST_POS_META):
				continue
			n.set_meta(_REST_POS_META, (n as Control).position)


func _prepare_shell() -> void :
	_content.modulate = Color.WHITE
	_content.scale = Vector2.ONE
	_overlay.self_modulate = Color(1, 1, 1, 0)


func _prepare_groups_hidden() -> void :
	_cache_rest_positions()
	for group: Array in _stagger_groups():
		for n: CanvasItem in group:
			var ctrl: Control = n as Control
			var rest: Vector2 = ctrl.get_meta(_REST_POS_META)
			ctrl.position = Vector2(rest.x, rest.y + _SLIDE_PX)
			ctrl.modulate = Color(1, 1, 1, 0)


func _play_enter() -> void :
	_enter_tween = create_tween()
	_enter_tween.set_parallel(true)
	_enter_tween.tween_property(_overlay, "self_modulate:a", 1.0, _OVERLAY_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var groups: Array = _stagger_groups()
	for i: int in groups.size():
		var delay: float = float(i) * _STAGGER_SEC
		for n: CanvasItem in groups[i]:
			var ctrl: Control = n as Control
			var rest: Vector2 = ctrl.get_meta(_REST_POS_META)
			_enter_tween.tween_property(ctrl, "modulate:a", 1.0, _ITEM_DUR)\
			.set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_enter_tween.tween_property(ctrl, "position:y", rest.y, _ITEM_DUR)\
			.set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _snap_groups_final() -> void :
	for group: Array in _stagger_groups():
		for n: CanvasItem in group:
			var ctrl: Control = n as Control
			if ctrl.has_meta(_REST_POS_META):
				ctrl.position = ctrl.get_meta(_REST_POS_META)
			ctrl.modulate = Color.WHITE
	_content.modulate = Color.WHITE
	_content.scale = Vector2.ONE
	_overlay.self_modulate = Color.WHITE


func _kill_tweens() -> void :
	if _enter_tween != null and _enter_tween.is_valid():
		_enter_tween.kill()
	_enter_tween = null
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()
	_exit_tween = null

func _on_hide() -> void :
	_generation += 1
	_closing = true
	_kill_tweens()
	visible = false
	closed.emit()
