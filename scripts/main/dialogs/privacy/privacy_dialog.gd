class_name PrivacyDialog
extends DialogScene






signal accepted

@onready var _title_label: Label = $Root / Content / Dialog / TitleLabel


@onready var _title_back: Label = $Root / Content / Dialog / TitleBack
@onready var _content_label: RichTextLabel = $Root / Content / Dialog / ContentLabel
@onready var _content: Control = $Root / Content
@onready var _dialog: Control = $Root / Content / Dialog
@onready var _card_bg: NinePatchRect = $Root / Content / Dialog / CardBg
@onready var _accept_button: Control = $Root / Content / Dialog / AcceptButton











const _SHOW_DUR: float = 0.3
const _SHOW_SCALE_START: Vector2 = Vector2(0.7, 0.7)
const _SHOW_SCALE_PEAK: Vector2 = Vector2(1.05, 1.05)
const _SHOW_SCALE_SEG1_DUR: float = 0.0996
const _SHOW_SCALE_SEG2_DUR: float = _SHOW_DUR - _SHOW_SCALE_SEG1_DUR
const _SHOW_FADE_DUR: float = 0.0548

const _HIDE_DUR: float = 0.3167
const _HIDE_SCALE_END: Vector2 = Vector2(0.8, 0.8)
const _HIDE_SCALE_PEAK: Vector2 = Vector2(1.05, 1.05)
const _HIDE_SCALE_SEG1_DUR: float = 0.1493
const _HIDE_SCALE_SEG2_DUR: float = _HIDE_DUR - _HIDE_SCALE_SEG1_DUR


const _HIDE_FADE_DELAY: float = 0.1174
const _HIDE_FADE_DUR: float = 0.05





const _DIALOG_SIDE_MARGIN: float = 20.0
const _DIALOG_MAX_WIDTH: float = 1040.0


const _DIALOG_DESIGN_WIDTH: float = 1008.0
const _CARD_BG_LEFT: float = -16.0
const _CARD_BG_RIGHT: float = 1025.0
const _TITLE_LEFT: float = 166.0
const _TITLE_RIGHT: float = 842.0
const _CONTENT_LEFT: float = 60.0
const _CONTENT_RIGHT: float = 948.0
const _ACCEPT_LEFT: float = 108.0
const _ACCEPT_RIGHT: float = 900.0

const _TITLE_BACK_OFFSET_Y: float = 2.0



const _TITLE_FONT_SIZE_MAX: int = 108
const _TITLE_FONT_SIZE_MIN: int = 40
const _TITLE_PADDING: float = 16.0
const _CARD_TOP: float = -8.0
const _TITLE_TOP: float = 14.0
const _TITLE_WIDTH: float = 676.0
const _TITLE_BOX_HEIGHT: float = 172.0

const _GAP_TITLE_TO_CONTENT: float = 142.0



const _CONTENT_BOX_HEIGHT: float = 400.0

const _GAP_CONTENT_TO_BUTTON: float = 80.0
const _BUTTON_HEIGHT: float = 216.0


const _CARD_BOTTOM_MARGIN: float = 408.0

const _CARD_OVERFLOW_MARGIN: float = 32.0


const _CONTENT_FONT_SIZE_MAX: int = 64
const _CONTENT_FONT_SIZE_MIN: int = 28

const _CONTENT_AVAIL_HEIGHT: float = 390.0

const _LINK_COLOR: String = "#1e7fff"


const _TERMS_URL: String = "https://oakevergames.com/tos.html"
const _POLICY_URL: String = "https://oakevergames.com/pp.html"

var _closing: bool = false

func _ready() -> void :



	_content_label.text = _build_desc_bbcode(_TERMS_URL, _POLICY_URL)
	_content_label.meta_clicked.connect(_on_link_clicked)
	_center_content_pivot()
	_layout_dialog_width()
	_fit_title_font_size()
	_layout_dialog_height()
	get_viewport().size_changed.connect(_center_content_pivot)
	get_viewport().size_changed.connect(_layout_dialog_width)
	get_viewport().size_changed.connect(_layout_dialog_height)














func _center_content_pivot() -> void :
	_content.pivot_offset = _content.size * 0.5



func reset_content() -> void :
	_closing = false
	_content.modulate.a = 0.0
	_content.scale = _SHOW_SCALE_START





func _on_show(params: Dictionary = {}) -> void :
	await super._on_show(params)
	_layout_dialog_width()
	_fit_title_font_size()
	_layout_dialog_height()
	await _fit_content_font_size()
	await _show_content()




func _layout_dialog_width() -> void :
	var w: float = minf(UiMetrics.viewport_size().x - _DIALOG_SIDE_MARGIN * 2.0, _DIALOG_MAX_WIDTH)
	var half: float = w * 0.5
	_dialog.offset_left = - half
	_dialog.offset_right = half
	var delta_x: float = (w - _DIALOG_DESIGN_WIDTH) * 0.5
	_card_bg.offset_left = _CARD_BG_LEFT + delta_x
	_card_bg.offset_right = _CARD_BG_RIGHT + delta_x
	_title_label.offset_left = _TITLE_LEFT + delta_x
	_title_label.offset_right = _TITLE_RIGHT + delta_x
	_title_back.offset_left = _TITLE_LEFT + delta_x
	_title_back.offset_right = _TITLE_RIGHT + delta_x
	_content_label.offset_left = _CONTENT_LEFT + delta_x
	_content_label.offset_right = _CONTENT_RIGHT + delta_x
	_accept_button.offset_left = _ACCEPT_LEFT + delta_x
	_accept_button.offset_right = _ACCEPT_RIGHT + delta_x




func _layout_dialog_height() -> void :
	var title_bottom: float = _TITLE_TOP + _TITLE_BOX_HEIGHT
	var content_top: float = title_bottom + _GAP_TITLE_TO_CONTENT
	var content_bottom: float = content_top + _CONTENT_BOX_HEIGHT
	var button_top: float = content_bottom + _GAP_CONTENT_TO_BUTTON
	var button_bottom: float = button_top + _BUTTON_HEIGHT
	var card_bottom: float = content_bottom + _CARD_BOTTOM_MARGIN
	var dialog_height: float = (card_bottom - _CARD_TOP) - _CARD_OVERFLOW_MARGIN

	_title_label.offset_top = _TITLE_TOP
	_title_label.offset_bottom = title_bottom
	_title_back.offset_top = _TITLE_TOP + _TITLE_BACK_OFFSET_Y
	_title_back.offset_bottom = title_bottom + _TITLE_BACK_OFFSET_Y
	_content_label.offset_top = content_top
	_content_label.offset_bottom = content_bottom
	_accept_button.offset_top = button_top
	_accept_button.offset_bottom = button_bottom
	_card_bg.offset_top = _CARD_TOP
	_card_bg.offset_bottom = card_bottom
	_dialog.offset_top = - dialog_height * 0.5
	_dialog.offset_bottom = dialog_height * 0.5




func _fit_title_font_size() -> void :
	if _title_label == null or _title_label.text == "":
		return
	var font: Font = _title_label.get_theme_font("font")
	if font == null:
		return
	var rendered: String = tr(_title_label.text)
	var max_w: float = _TITLE_WIDTH - _TITLE_PADDING * 2.0
	var font_size: int = _TITLE_FONT_SIZE_MAX
	while font_size > _TITLE_FONT_SIZE_MIN:
		var text_w: float = font.get_string_size(
			rendered, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
		if text_w <= max_w:
			break
		font_size -= 2
	_title_label.add_theme_font_size_override("font_size", font_size)
	_title_back.add_theme_font_size_override("font_size", font_size)





func _on_accept_btn_pressed() -> void :
	if _closing:
		return
	_closing = true
	await _hide_content()
	accepted.emit()






func _show_content() -> void :
	var tw: Tween = create_tween()
	tw.tween_property(_content, "scale", _SHOW_SCALE_PEAK, _SHOW_SCALE_SEG1_DUR)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_content, "modulate:a", 1.0, _SHOW_FADE_DUR)
	tw.tween_property(_content, "scale", Vector2.ONE, _SHOW_SCALE_SEG2_DUR)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished





func _hide_content() -> void :
	var tw: Tween = create_tween()
	tw.tween_property(_content, "scale", _HIDE_SCALE_PEAK, _HIDE_SCALE_SEG1_DUR)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_content, "scale", _HIDE_SCALE_END, _HIDE_SCALE_SEG2_DUR)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_content, "modulate:a", 0.0, _HIDE_FADE_DUR).set_delay(_HIDE_FADE_DELAY)
	await tw.finished








func _on_link_clicked(meta: Variant) -> void :
	var raw_url: String = str(meta)
	if raw_url == _TERMS_URL:

		Tracker.track_btn_click(TrackingEvents.BTN_TERMS)
	elif raw_url == _POLICY_URL:

		Tracker.track_btn_click(TrackingEvents.BTN_PRIVACY_POLICY)
	SortLogger.info("[AuthManager] 调用 get_localized_privacy_url(url=%s)" % raw_url)
	var url: String = AuthManager.get_localized_privacy_url(raw_url)
	SortLogger.info("[AuthManager] get_localized_privacy_url 返回 %s" % url)
	OS.shell_open(url)




func _build_desc_bbcode(terms_url: String, policy_url: String) -> String:
	var s: String = tr("TERMS_PRIVACY_READ_ACCEPT")

	s = s.replace("\\n", "\n")
	s = s.replace("%1", "[url=%s][color=%s]" % [terms_url, _LINK_COLOR])
	s = s.replace("%2", "[/color][/url]")
	s = s.replace("%3", "[url=%s][color=%s]" % [policy_url, _LINK_COLOR])
	s = s.replace("%4", "[/color][/url]")
	return s





func _notification(what: int) -> void :
	super._notification(what)
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if _title_label != null:
			_fit_title_font_size()
			_layout_dialog_height()
		if _content_label != null:
			_fit_content_font_size()




func _fit_content_font_size() -> void :
	if _content_label == null:
		return
	var s: int = _CONTENT_FONT_SIZE_MAX
	_content_label.add_theme_font_size_override("normal_font_size", s)
	await get_tree().process_frame
	while s > _CONTENT_FONT_SIZE_MIN:
		var h: float = _content_label.get_content_height()
		if h <= 0.0:
			break
		if h <= _CONTENT_AVAIL_HEIGHT:
			break
		s -= 2
		_content_label.add_theme_font_size_override("normal_font_size", s)
		await get_tree().process_frame
