class_name SettingsDialog
extends DialogScene














const _BODY_TOP: float = 264.0
const _BODY_BOTTOM_GAME: float = 150.0
const _BODY_BOTTOM_HOME: float = 96.0


const _CARD_SIDE_MARGIN: float = 20.0
const _CARD_MAX_WIDTH: float = 1040.0

@export var toggle_on_bg_tex: Texture2D
@export var toggle_off_bg_tex: Texture2D
@export var sound_on_tex: Texture2D
@export var sound_off_tex: Texture2D
@export var vibration_on_tex: Texture2D
@export var vibration_off_tex: Texture2D
@export var music_on_tex: Texture2D
@export var music_off_tex: Texture2D











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

@onready var _card_root: Control = $Root / Content / Center / CardRoot
@onready var _title_back: Label = $Root / Content / Center / CardRoot / TitleBack
@onready var _title: Label = $Root / Content / Center / CardRoot / Title
@onready var _body: VBoxContainer = $Root / Content / Center / CardRoot / Body
@onready var _toggles: HBoxContainer = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles
@onready var _music_toggle: VBoxContainer = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / MusicToggle
@onready var _music_btn: TextureButton = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / MusicToggle / MusicBtn
@onready var _music_label: Label = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / MusicToggle / MusicLabel
@onready var _sound_toggle: VBoxContainer = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / SoundToggle
@onready var _toggles_margin: MarginContainer = $Root / Content / Center / CardRoot / Body / TogglesMargin
@onready var _sound_label: Label = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / SoundToggle / SoundLabel
@onready var _vibration_label: Label = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / VibrationToggle / VibrationLabel
@onready var _close_btn: TextureButton = $Root / Content / Center / CardRoot / CloseButton
@onready var _sound_btn: TextureButton = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / SoundToggle / SoundBtn
@onready var _sound_icon: TextureRect = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / SoundToggle / SoundBtn / Icon
@onready var _vibration_toggle: VBoxContainer = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / VibrationToggle
@onready var _vibration_btn: TextureButton = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / VibrationToggle / VibrationBtn
@onready var _vibration_icon: TextureRect = $Root / Content / Center / CardRoot / Body / TogglesMargin / Toggles / VibrationToggle / VibrationBtn / Icon
@onready var _game_content: VBoxContainer = $Root / Content / Center / CardRoot / Body / GameContent
@onready var _home_content: VBoxContainer = $Root / Content / Center / CardRoot / Body / HomeContent
@onready var _privacy_preference_center: CenterContainer = $Root / Content / Center / CardRoot / Body / HomeContent / LegalFooter / LegalLinksMargin / LegalLinks / LegalBottom / PrivacyPreferenceCenter
@onready var _privacy_preference_btn: LinkButton = $Root / Content / Center / CardRoot / Body / HomeContent / LegalFooter / LegalLinksMargin / LegalLinks / LegalBottom / PrivacyPreferenceCenter / PrivacyPreferenceBtn
@onready var _open_source_licenses_btn: LinkButton = $Root / Content / Center / CardRoot / Body / HomeContent / LegalFooter / LegalLinksMargin / LegalLinks / LegalBottom / OpenSourceLicensesCenter / OpenSourceLicensesBtn
@onready var _privacy_policy_btn: LinkButton = $Root / Content / Center / CardRoot / Body / HomeContent / LegalFooter / LegalLinksMargin / LegalLinks / LegalTop / PrivacyPolicyCenter / PrivacyPolicyBtn
@onready var _terms_btn: LinkButton = $Root / Content / Center / CardRoot / Body / HomeContent / LegalFooter / LegalLinksMargin / LegalLinks / LegalTop / TermsCenter / TermsBtn
@onready var _version_label: Label = $Root / Content / Center / CardRoot / Body / HomeContent / LegalFooter / VersionMargin / Version
@onready var _content: Control = $Root / Content
@onready var _help_btn: CommonBtn = $Root / Content / Center / CardRoot / Body / HomeContent / HomeActionsMargin / HomeActions / HelpBtn
@onready var _help_red_dot: TextureRect = $Root / Content / Center / CardRoot / Body / HomeContent / HomeActionsMargin / HomeActions / HelpBtn / RedDot

var _on_restart: Callable
var _on_home: Callable



var _on_dismissed: Callable
var _closing: bool = false


func _ready() -> void :
	UserState.help_center_badge_changed.connect(_on_help_center_badge_changed)
	SceneManager.bind_press_release_scale(_close_btn)

	AudioManager.claim_button_sound(_sound_btn)

	HapticManager.claim_button_haptic(_vibration_btn)
	_version_label.text = "v" + (ProjectSettings.get_setting("application/config/version", "x.x.x") as String)
	_center_content_pivot()
	get_viewport().size_changed.connect(_center_content_pivot)















func _center_content_pivot() -> void :
	_content.pivot_offset = _content.size * 0.5



func _card_width() -> float:
	return minf(UiMetrics.viewport_size().x - _CARD_SIDE_MARGIN * 2.0, _CARD_MAX_WIDTH)




func _fit_translated_text() -> void :
	var card_width: float = _card_width()

	var title_width: float = card_width - 432.0 - 36.0
	_fit_text(_title_back, &"SETTINGS", 96, title_width)
	_fit_text(_title, &"SETTINGS", 96, title_width)
	var body_width: float = card_width - 208.0
	var toggle_width: float = (body_width - 160.0) * 0.5 - 8.0
	var toggle_font_size: int = 52
	if _music_toggle.visible:
		toggle_width = 224.0
		toggle_font_size = 48
		_fit_text(_music_label, &"SETTINGS_MUSIC", 48, toggle_width)
	_fit_text(_sound_label, &"SETTINGS_SOUND", toggle_font_size, toggle_width)
	_fit_text(_vibration_label, &"SETTINGS_VIBRATION", toggle_font_size, toggle_width)
	var links_width: float = body_width - 16.0
	var link_width: float = (links_width - 24.0) * 0.5 - 8.0
	_fit_text(_privacy_policy_btn, &"PRIVACY_POLICY", 40, link_width)
	_fit_text(_terms_btn, &"TERMS_OF_SERVICE", 40, link_width)
	_fit_text(_privacy_preference_btn, &"PRIVACY_PREFERENCE", 40, link_width)
	var licenses_width: float = link_width if _privacy_preference_center.visible else links_width - 8.0
	_fit_text(_open_source_licenses_btn, &"SETTINGS_OPEN_SOURCE_LICENSES", 40, licenses_width)


func _fit_text(control: Control, key: StringName, base_size: int, max_width: float) -> void :
	var font: Font = control.get_theme_font(&"font")
	var rendered: String = tr(key)
	var font_size: int = base_size
	while font_size > 1 and font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_CENTER, 
			-1.0, font_size).x > max_width:
		font_size -= 1
	control.add_theme_font_size_override(&"font_size", font_size)





func reset_content() -> void :
	_closing = false
	_content.modulate.a = 0.0
	_content.scale = _SHOW_SCALE_START





func _on_show(params: Dictionary = {}) -> void :
	await super._on_show(params)

	_on_restart = params.get("on_restart", Callable())
	_on_home = params.get("on_home", Callable())
	_on_dismissed = params.get("on_dismissed", Callable())
	_refresh_toggles()
	_music_toggle.visible = ABManager.bgm_test.is_bgm_enabled()
	_vibration_toggle.visible = not UiMetrics.is_tablet()
	_apply_toggle_layout()
	var is_home: bool = String(params.get("source", "game")) == "home"
	_home_content.visible = is_home
	_game_content.visible = not is_home


	_help_red_dot.visible = HelpshiftManager.should_show_badge()
	if is_home:
		HelpshiftManager.on_settings_opened()




	Tracker.track_dlg_show(TrackingEvents.DLG_SETTINGS_HOME if is_home
		else TrackingEvents.DLG_SETTINGS_GAME)
	if is_home:

		SortLogger.info("[AuthManager] 调用 check_cmp_required()")
		var cmp_required: bool = AuthManager.check_cmp_required()
		SortLogger.info("[AuthManager] check_cmp_required 返回 %s" % cmp_required)
		_privacy_preference_center.visible = cmp_required
	else:
		_privacy_preference_center.visible = false
	var toggle_padding: int = 0 if is_home else 24
	_toggles_margin.add_theme_constant_override("margin_top", toggle_padding)
	_toggles_margin.add_theme_constant_override("margin_bottom", toggle_padding)
	_card_root.custom_minimum_size.x = _card_width()
	_help_btn.btn_text = tr("HELP_CENTER")
	_fit_translated_text()



	await get_tree().process_frame
	var content_h: float = _body.get_combined_minimum_size().y
	var body_bottom: float = _BODY_BOTTOM_HOME if is_home else _BODY_BOTTOM_GAME
	_card_root.custom_minimum_size = Vector2(_card_width(), _BODY_TOP + content_h + body_bottom)
	await _show_content()




func _on_back_request() -> void :
	_dismiss()


func _notification(what: int) -> void :
	super (what)
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_IN\
	or what == NOTIFICATION_APPLICATION_RESUMED:
		_reset_external_link_feedback()
	elif what == NOTIFICATION_TRANSLATION_CHANGED:
		_help_btn.btn_text = tr("HELP_CENTER")
		_fit_translated_text()


func _reset_external_link_feedback() -> void :
	SceneManager.reset_button_feedback(_privacy_policy_btn)
	SceneManager.reset_button_feedback(_terms_btn)
	SceneManager.reset_button_feedback(_open_source_licenses_btn)




func close() -> void :
	if _closing:
		return
	_closing = true
	_hide_bg()
	await _hide_content()

	visible = false
	Tracker.clear_current_dlg(TrackingEvents.DLG_SETTINGS_HOME if _home_content.visible
		else TrackingEvents.DLG_SETTINGS_GAME)


func _on_close_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_CLOSE)
	_dismiss()


func _on_sound_pressed() -> void :
	var enabled: bool = AudioManager.is_sfx_enabled()
	if enabled:
		AudioManager.play_sfx(&"button_click")
		AudioManager.set_sfx_enabled(false)
	else:
		AudioManager.set_sfx_enabled(true)
		AudioManager.play_sfx(&"button_click")
	_refresh_toggles()
	_track_sw_click(TrackingEvents.SW_SOUND, AudioManager.is_sfx_enabled())


func _on_music_pressed() -> void :
	AudioManager.set_music_enabled( not AudioManager.is_music_enabled())
	_refresh_toggles()



func _apply_toggle_layout() -> void :
	var with_music: bool = _music_toggle.visible
	_toggles.add_theme_constant_override("separation", 0 if with_music else 160)
	for column: VBoxContainer in [_sound_toggle, _vibration_toggle]:
		column.custom_minimum_size.x = 272.0 if with_music else 0.0
		column.add_theme_constant_override("separation", 12 if with_music else 4)
	for button: TextureButton in [_sound_btn, _vibration_btn]:
		button.custom_minimum_size = Vector2(196, 196) if with_music else Vector2(220, 220)
		button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED if with_music else TextureButton.STRETCH_SCALE
	for label: Label in [_sound_label, _vibration_label]:
		label.custom_minimum_size = Vector2(224, 57) if with_music else Vector2(260, 0)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if with_music else Control.SIZE_FILL
		label.add_theme_color_override("font_color", Color(0.2235294, 0.2745098, 0.3411765) if with_music else Color(0.4, 0.298, 0.263))


func _on_vibration_pressed() -> void :
	var enabled: bool = HapticManager.is_enabled()
	if enabled:
		HapticManager.play_event(HapticManager.Event.BUTTON)
		HapticManager.set_enabled(false)
	else:
		HapticManager.set_enabled(true)
		HapticManager.play_event(HapticManager.Event.BUTTON)
	_refresh_toggles()
	_track_sw_click(TrackingEvents.SW_VIBRATION, HapticManager.is_enabled())







func _track_sw_click(sw_name: String, enabled: bool) -> void :
	var state: String = TrackingEvents.SW_STATE_OPEN if enabled else TrackingEvents.SW_STATE_CLOSE
	Tracker.track_sw_click(sw_name, state)


func _refresh_toggles() -> void :
	_music_btn.texture_normal = music_on_tex if AudioManager.is_music_enabled() else music_off_tex
	var sound_enabled: bool = AudioManager.is_sfx_enabled()
	var vibration_enabled: bool = HapticManager.is_enabled()
	_sound_btn.texture_normal = toggle_on_bg_tex if sound_enabled else toggle_off_bg_tex
	_sound_icon.texture = sound_on_tex if sound_enabled else sound_off_tex
	_vibration_btn.texture_normal = toggle_on_bg_tex if vibration_enabled else toggle_off_bg_tex
	_vibration_icon.texture = vibration_on_tex if vibration_enabled else vibration_off_tex



func _dismiss() -> void :
	close()
	if _on_dismissed.is_valid():
		_on_dismissed.call()




func _hide_for_external_action() -> void :
	hide_panel()
	Tracker.clear_current_dlg(TrackingEvents.DLG_SETTINGS_HOME)


func _on_restart_pressed() -> void :
	close()
	if _on_restart.is_valid():
		_on_restart.call()


func _on_home_pressed() -> void :
	close()
	if _on_home.is_valid():
		_on_home.call()





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



func _on_help_pressed() -> void :


	Tracker.track_btn_click(TrackingEvents.BTN_HELP)

	var mobile: bool = OS.has_feature("android") or OS.has_feature("ios")
	var keep_open: bool = mobile and ( not NativeUtilManager.is_online()\
	or not NativeUtilManager.is_help_center_initialized())
	if not keep_open:
		_hide_for_external_action()
	HelpshiftManager.show_help_center()


func _on_help_center_badge_changed(badge_visible: bool) -> void :
	_help_red_dot.visible = badge_visible



func _on_rate_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_RATE)
	_hide_for_external_action()
	RatingManager.open_store_rating_page()



func _on_privacy_policy_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_PRIVACY_POLICY)
	SortLogger.info("[AuthManager] 调用 get_localized_privacy_url(url=https://oakevergames.com/pp.html)")
	var policy_url: String = AuthManager.get_localized_privacy_url("https://oakevergames.com/pp.html")
	SortLogger.info("[AuthManager] get_localized_privacy_url(pp) 返回 %s" % policy_url)
	OS.shell_open(policy_url)
	SceneManager.reset_button_feedback(_privacy_policy_btn)


func _on_terms_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_TERMS)
	SortLogger.info("[AuthManager] 调用 get_localized_privacy_url(url=https://oakevergames.com/tos.html)")
	var terms_url: String = AuthManager.get_localized_privacy_url("https://oakevergames.com/tos.html")
	SortLogger.info("[AuthManager] get_localized_privacy_url(tos) 返回 %s" % terms_url)
	OS.shell_open(terms_url)
	SceneManager.reset_button_feedback(_terms_btn)


func _on_open_source_licenses_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_OPEN_SOURCE_LICENSES)
	SortLogger.info("[AuthManager] 调用 get_localized_privacy_url(url=https://oakevergames.com/open-source-license.html)")
	var licenses_url: String = AuthManager.get_localized_privacy_url("https://oakevergames.com/open-source-license.html")
	SortLogger.info("[AuthManager] get_localized_privacy_url(open-source-license) 返回 %s" % licenses_url)
	OS.shell_open(licenses_url)
	SceneManager.reset_button_feedback(_open_source_licenses_btn)



func _on_privacy_preference_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_PRIVACY_PREFERENCE)
	if not NativeUtilManager.is_online():
		SceneManager.show_toast(tr("CMP_LOAD_FAILED"))
		return
	SortLogger.info("[AuthManager] 调用 show_cmp_ui()")
	AuthManager.show_cmp_ui()
