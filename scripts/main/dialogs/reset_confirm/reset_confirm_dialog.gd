class_name ResetConfirmDialog
extends DialogScene

const SHOW_SCALE_START: = Vector2(0.82, 0.82)
const SHOW_DUR: = 0.22
const HIDE_DUR: = 0.16
const _BODY_TOP: float = 270.0
const _BODY_HEIGHT: float = 152.0
const _BODY_MAX_HEIGHT: float = 220.0
const _BODY_FONT_SIZE: int = 64

const _STREAK_BODY_MIN: int = 3

const _ACCENT_COLOR: String = "#6f320d"

@onready var _content: Control = $Content
@onready var _card: Control = $Content / Center / Card
@onready var _title_back: Label = $Content / Center / Card / TitleBack
@onready var _title: Label = $Content / Center / Card / Title
@onready var _body: RichTextLabel = $Content / Center / Card / Body
@onready var _close_btn: TextureButton = $Content / Center / Card / CloseButton
@onready var _restart_btn: CommonBtn = $Content / Center / Card / RestartButton
@onready var _cancel_btn: CommonBtn = $Content / Center / Card / CancelButton
var _on_confirm: Callable
var _body_key: StringName = &"JUICE_RESET_DIALOG_BODY"
var _body_args: Dictionary = {"N": 0, "M": 0}
var _closing: bool = false


func _ready() -> void :
	SceneManager.bind_press_release_scale(_close_btn)
	_fit_translated_text()


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit_translated_text()


func _fit_translated_text() -> void :

	var title_width: float = _card.custom_minimum_size.x - 432.0 - 36.0
	var title_font: Font = _title.get_theme_font(&"font")
	var title_text: String = tr(&"JUICE_RESET_DIALOG_TITLE")
	var title_size: int = 96
	while title_size > 1 and title_font.get_string_size(title_text, 
			HORIZONTAL_ALIGNMENT_CENTER, -1.0, title_size).x > title_width:
		title_size -= 1
	_title.add_theme_font_size_override(&"font_size", title_size)
	_title_back.add_theme_font_size_override(&"font_size", title_size)

	_body.offset_top = _BODY_TOP
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body.text = _body_bbcode()


	var body_size: int = _BODY_FONT_SIZE
	_set_body_font_size(body_size)

	var body_height: float = _body.get_content_height()
	while body_size > 1 and body_height > _BODY_MAX_HEIGHT:
		body_size -= 1
		_set_body_font_size(body_size)
		body_height = _body.get_content_height()
	_body.offset_bottom = _BODY_TOP + maxf(_BODY_HEIGHT, body_height)


func reset_content() -> void :
	_closing = false
	_content.modulate.a = 0.0
	_content.scale = SHOW_SCALE_START
	_content.pivot_offset = _content.size * 0.5


func _on_show(params: Dictionary = {}) -> void :
	await super._on_show(params)
	Tracker.track_dlg_show(TrackingEvents.DLG_RESET_CONFIRM)
	_on_confirm = params.get("on_confirm", Callable())
	_configure_layout()
	_pick_body(int(params.get("done", 0)), int(params.get("total", 0)), 
		int(params.get("streak", 0)))
	_fit_translated_text()
	_content.pivot_offset = _content.size * 0.5
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_content, "modulate:a", 1.0, SHOW_DUR)
	tw.tween_property(_content, "scale", Vector2.ONE, SHOW_DUR)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


func _pick_body(done: int, total: int, streak: int) -> void :
	if _is_streak_state(streak):
		_body_key = &"JUICE_RESET_DIALOG_BODY_STREAK"
		_body_args = {"N": streak}
	else:
		_body_key = &"JUICE_RESET_DIALOG_BODY"
		_body_args = {"N": done, "M": total}



static func _is_streak_state(streak: int) -> bool:
	return streak >= _STREAK_BODY_MIN



func _body_bbcode() -> String:
	var text: String = tr(_body_key)
	if _body_key == &"JUICE_RESET_DIALOG_BODY":
		return text.replace("{N}/{M}", _accent("%d/%d" % [_body_args["N"], _body_args["M"]]))
	return text.replace("{N}", _accent(str(_body_args["N"])))


func _accent(value: String) -> String:
	return "[b][color=%s]%s[/color][/b]" % [_ACCENT_COLOR, value]


func _set_body_font_size(size: int) -> void :
	_body.add_theme_font_size_override(&"normal_font_size", size)
	_body.add_theme_font_size_override(&"bold_font_size", size)


func _on_back_request() -> void :
	close()


func _on_hide() -> void :
	await super._on_hide()
	Tracker.clear_current_dlg(TrackingEvents.DLG_RESET_CONFIRM)


func close() -> void :
	if _closing:
		return
	_closing = true
	_hide_bg()
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_content, "modulate:a", 0.0, HIDE_DUR)
	tw.tween_property(_content, "scale", SHOW_SCALE_START, HIDE_DUR)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	visible = false
	Tracker.clear_current_dlg(TrackingEvents.DLG_RESET_CONFIRM)


func _on_restart_pressed() -> void :
	if _closing:
		return

	Tracker.track_btn_click(TrackingEvents.BTN_CONFIRM)
	var callback: Callable = _on_confirm
	await close()
	if callback.is_valid():
		callback.call()



func _on_cancel_pressed() -> void :
	if _closing:
		return
	Tracker.track_btn_click(TrackingEvents.BTN_CLOSE)
	close()


func _configure_layout() -> void :
	_body.visible = true
	_restart_btn.visible = true
	_cancel_btn.visible = true
	_card.custom_minimum_size.y = 1104.0
	for label: Label in [_title, _title_back]:
		label.offset_left = -364.0
		label.offset_right = 364.0
	_title.offset_top = 22.0
	_title.offset_bottom = 194.0
	_title_back.offset_top = 26.0
	_title_back.offset_bottom = 198.0
	_close_btn.offset_left = -192.0
	_close_btn.offset_right = -48.0
	_close_btn.offset_top = 40.0
	_close_btn.offset_bottom = 184.0
