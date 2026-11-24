class_name TimedEndlessRewardDialog
extends DialogScene

signal claim_requested

const BACKGROUND_IN_DURATION: float = 0.2
const OUT_DURATION: float = 0.22

const PANEL_SIZE: Vector2 = Vector2(1000.0, 1200.0)
const TITLE_RECT: Rect2 = Rect2(190.0, 215.0, 620.0, 80.0)
const COUNT_RECT: Rect2 = Rect2(524.0, 455.0, 180.0, 100.0)
const MESSAGE_WIDTH: float = 750.0
const MESSAGE_CENTER: Vector2 = Vector2(502.0, 730.0)

@onready var _panel: Control = $Root / Panel
@onready var _composite: CanvasGroup = $Root / Panel / Composite
@onready var _title: Label = $Root / Panel / Composite / RibbonText / Title
@onready var _title_outline: Label = $Root / Panel / Composite / RibbonText / TitleOutline
@onready var _count: Label = $Root / Panel / Composite / Count
@onready var _message: RichTextLabel = $Root / Panel / Composite / Message
@onready var _claim: CommonBtn = $Root / Panel / Composite / Claim
@onready var _claim_icon: TextureRect = $Root / Panel / Composite / Claim / Contents / Icon
@onready var _shadow: TextureRect = $Root / Panel / Composite / RibbonText / TitleShadow
@onready var _shadow_viewport: SubViewport = $TitleShadowViewport
@onready var _shadow_mask: Label = $TitleShadowViewport / Mask
@onready var _clock: TimedChallengeClock = $Root / Panel / Composite / ClockRig

var _motion: PopupMotion = PopupMotion.new()
var _generation: int = 0
var _result: Dictionary = {}
var _requested: bool = false
var _pending_coin_hud: Control = null
var _coin_hud: Control = null
var _coin_hud_parent: Node = null
var _coin_hud_index: int = -1


func _ready() -> void :
	_shadow.texture = _shadow_viewport.get_texture()
	resized.connect(_layout_panel)
	_clock.bind_ribbon_text($Root / Panel / Composite / RibbonText)
	_set_claim_locked(true)
	reset_content()


func reset_content() -> void :
	_generation += 1
	_requested = false
	_result = {}
	_restore_coin_hud()
	if not is_node_ready():
		return
	_motion.reset(_panel)
	_clock.reset_now()
	_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_set_claim_locked(true)
	modulate.a = 1.0
	if is_instance_valid(_bg):
		_bg.color = _BG_COLOR
	if is_instance_valid(_pending_coin_hud):
		_attach_coin_hud(_pending_coin_hud)
	_pending_coin_hud = null


func background_fade_duration() -> float:
	return BACKGROUND_IN_DURATION


func _on_show(params: Dictionary) -> void :
	_pending_coin_hud = params.get("coin_hud", null) as Control
	var generation: int = _generation + 1
	await super._on_show(params)
	if generation != _generation or not visible:
		return
	_result = (params.get("result", {}) as Dictionary).duplicate(true)
	_refresh_text()
	_layout_panel()
	_clock.play_finish()
	if not await _motion.appear(_panel, _composite) or generation != _generation or not visible:
		return

	while generation == _generation and visible and _clock.is_appearing():
		await get_tree().process_frame
	if generation == _generation and visible:
		_set_claim_locked(false)


func _layout_panel() -> void :
	if not is_node_ready():
		return
	_panel.size = PANEL_SIZE
	_panel.position = Vector2(UiMetrics.center_left(PANEL_SIZE.x), 
		(UiMetrics.viewport_size().y - PANEL_SIZE.y) * 0.5)


func _refresh_text() -> void :
	var key: StringName = &"TIMED_CHALLENGE_TIME_UP" if _result.get("reason", "") == "time_up" else &"TIMED_CHALLENGE_DEAD_END"
	_title.text = tr(key)
	_fit_label(_title, TITLE_RECT, 80, 1, 1.0, 
		float(_title_outline.get_theme_constant("outline_size")) * 2.0)
	_title_outline.text = _title.text
	_title_outline.add_theme_font_size_override("font_size", _title.get_theme_font_size("font_size"))
	_title_outline.size = TITLE_RECT.size
	_title_outline.position = TITLE_RECT.get_center() - _title_outline.size * 0.5
	_shadow_mask.text = _title.text
	_shadow_mask.add_theme_font_size_override("font_size", _title.get_theme_font_size("font_size"))
	_shadow_mask.size = TITLE_RECT.size
	_shadow_mask.position = (Vector2(_shadow_viewport.size) - _shadow_mask.size) * 0.5
	_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var cups: int = int(_result.get("cups", 0))
	_count.text = "x%d" % cups
	_fit_label(_count, COUNT_RECT, 140, 40, 1.2)
	_claim.btn_text = "+%d" % int(_result.get("coins", 0))
	var text: String
	var rich: String
	if cups <= 10:
		text = tr(String(_result.get("encouragement_key", "GAME_STREAK_BLOOMING")))
		rich = text.replace("[", "[lb]")
	else:
		var percent: float = float(_result.get("percentile", 0.0))
		var percent_text: String = "%.1f%%" % percent
		text = tr("TIMED_CHALLENGE_PERCENTILE") % percent
		rich = text.replace("[", "[lb]").replace(percent_text, "[color=#FF861C]%s[/color]" % percent_text)
	var font: FontVariation = _message.get_theme_font("normal_font") as FontVariation
	var measured: Vector2 = Vector2.ZERO
	var chosen: int = 60
	for font_size: int in range(60, 27, -1):
		var excess: int = maxi(0, roundi(font.base_font.get_height(font_size) - float(font_size) * 1.2))
		font.spacing_top = - int(excess / 2)
		font.spacing_bottom = - (excess - int(excess / 2))
		var paragraph: = TextParagraph.new()
		paragraph.width = MESSAGE_WIDTH
		paragraph.add_string(text, font, font_size, TranslationServer.get_locale())
		measured = paragraph.get_size()
		chosen = font_size
		if measured.y <= 120.0:
			break
	_message.add_theme_font_size_override("normal_font_size", chosen)
	_message.size = Vector2(MESSAGE_WIDTH, maxf(80.0, measured.y))
	_message.position = MESSAGE_CENTER - _message.size * 0.5
	_message.text = "[center]%s[/center]" % rich


func _fit_label(label: Label, rect: Rect2, maximum: int, minimum: int, line_ratio: float, 
		horizontal_padding: float = 0.0) -> void :
	var font: FontVariation = label.get_theme_font("font") as FontVariation
	for font_size: int in range(maximum, minimum - 1, -1):
		var excess: int = maxi(0, roundi(font.base_font.get_height(font_size) - float(font_size) * line_ratio))
		font.spacing_top = - int(excess / 2)
		font.spacing_bottom = - (excess - int(excess / 2))
		label.add_theme_font_size_override("font_size", font_size)
		if font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x\
		+ horizontal_padding <= rect.size.x:
			break
	label.size = rect.size

	label.position = rect.get_center() - label.size * 0.5


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible and not _result.is_empty():
		_refresh_text()


func _on_claim_pressed() -> void :
	if _claim.disabled or _requested:
		return
	_requested = true
	_set_claim_locked(true)
	_blacken_background()
	claim_requested.emit()


func has_claim_request() -> bool:
	return _requested


func retry_claim() -> void :
	_requested = false
	if is_instance_valid(_bg):
		_bg.color = _BG_COLOR
	_set_claim_locked(false)



func _set_claim_locked(locked: bool) -> void :
	_claim.disabled = locked
	CommonBtn.apply_disabled_gray(_claim, false)


func coin_source_rect() -> Rect2:
	var coin_size: Vector2 = _claim_icon.size
	return Rect2(UiMetrics.viewport_size() * 0.5 - coin_size * 0.5, coin_size)



func prepare_collection() -> bool:
	_set_claim_locked(true)
	_blacken_background()
	var generation: int = _generation
	var finished: bool = await _motion.disappear_composited(_panel, _panel, _composite, null, OUT_DURATION)
	return finished and generation == _generation and visible


func _blacken_background() -> void :
	if not is_instance_valid(_bg):
		return
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	_bg_tween = null
	_bg.color = _BG_COLOR
	_bg.modulate.a = 1.0
	modulate.a = 1.0


func _attach_coin_hud(hud: Control) -> void :
	_coin_hud = hud
	_coin_hud_parent = hud.get_parent()
	_coin_hud_index = hud.get_index()
	hud.reparent(self, true)


func _restore_coin_hud() -> void :
	var hud: Control = _coin_hud
	_coin_hud = null
	if is_instance_valid(hud):
		if is_instance_valid(_coin_hud_parent):
			hud.reparent(_coin_hud_parent, true)
			_coin_hud_parent.move_child(hud, mini(_coin_hud_index, _coin_hud_parent.get_child_count() - 1))
		else:
			hud.queue_free()
	_coin_hud_parent = null
	_coin_hud_index = -1


func close_after_claim() -> bool:
	_set_claim_locked(true)
	var generation: int = _generation
	if not await _motion.disappear_composited(_panel, self, _composite, _bg, OUT_DURATION) or generation != _generation:
		return false
	hide_panel()
	return true


func _on_hide() -> void :
	await close_after_claim()


func _on_back_request() -> void :

	return


func _exit_tree() -> void :
	_restore_coin_hud()
