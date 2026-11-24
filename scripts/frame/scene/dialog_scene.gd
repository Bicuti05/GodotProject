class_name DialogScene
extends PageScene



























const _BG_COLOR: Color = Color(0, 0, 0, 0.8)
const _BG_NODE_NAME: String = "DialogBg"
const _BG_FADE_SEC: float = 0.25






const FADE_OUT_DUR: float = 0.45

var _background_initial_opacity: float = 0.0
var _background_handoff: Callable = Callable()
var _bg: ColorRect = null
var _bg_tween: Tween = null





func reset_content() -> void :
	pass





func background_fade_duration() -> float:
	return _BG_FADE_SEC


func show_bg() -> void :
	reset_content()
	if _bg == null:
		_bg = ColorRect.new()
		_bg.name = _BG_NODE_NAME
		_bg.color = _BG_COLOR
		_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_bg)
	move_child(_bg, 0)
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	_bg.visible = true
	_bg.modulate.a = clampf(_background_initial_opacity / _BG_COLOR.a, 0.0, 1.0)

	if _background_handoff.is_valid():
		_background_handoff.call()
	_background_handoff = Callable()
	_background_initial_opacity = 0.0
	_bg_tween = create_tween()
	_bg_tween.tween_property(_bg, "modulate:a", 1.0, background_fade_duration()).set_ease(Tween.EASE_OUT)
	await _bg_tween.finished




func _on_show(params: Dictionary) -> void :
	_background_initial_opacity = float(params.get("background_initial_opacity", 0.0))
	_background_handoff = params.get("background_handoff", Callable()) as Callable
	await show_bg()


func _hide_bg() -> void :
	if _bg == null:
		return
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	_bg_tween = create_tween()
	_bg_tween.tween_property(_bg, "modulate:a", 0.0, _BG_FADE_SEC).set_ease(Tween.EASE_IN)
	await _bg_tween.finished
	_bg.visible = false


func _on_hide() -> void :
	await _hide_bg()
	visible = false






func fade_out() -> void :
	if not visible:
		return
	var tw: = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE_OUT_DUR)
	tw.tween_callback(hide_panel)
	await tw.finished



func hide_panel() -> void :
	reset_content()
	visible = false
