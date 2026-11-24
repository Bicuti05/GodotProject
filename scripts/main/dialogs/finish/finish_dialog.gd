class_name FinishDialog
extends DialogScene


















signal next_pressed
signal ad_reward_pressed

const NEXT_FADE_DUR: float = 0.25
const ENCOURAGEMENT_FADE_DUR: float = 0.6
const AD_BUTTON_GAP: float = 28.0


const SINGLE_BUTTON_BOTTOM_GAP: float = 176.0
const DOUBLE_BUTTON_BOTTOM_GAP: float = 156.0
const ENCOURAGEMENT_SIZE: = Vector2(792.0, 128.0)
const DATA_ENCOURAGEMENT_HEIGHT: float = 192.0
const DATA_ENCOURAGEMENT_FONT_SIZE: int = 64

const TIMED_ENCOURAGEMENT_HEIGHT: float = 240.0
const DATA_REWARD_LIFT: float = 96.0
const ENCOURAGEMENT_FONT_SIZE: int = 48
const DATA_TEXT_GAP: float = 16.0

const TEXT_BUTTON_GAP: float = 64.0

const TEXT_AD_BUTTON_GAP: float = 96.0
const DATA_REWARD_GAP: float = 64.0

const REWARD_CONTENT_BOTTOM: float = 1580.0

const NEXT_FACE_CENTER_FROM_BOTTOM: float = 439.0
const NEXT_FACE_CENTER_LIFT: float = 5.0



const NEXT_BTN_SIZE: = Vector2(792.0, 216.0)


const _REWARD_DELAY: float = 0.0

const _CONFETTI_DELAY: float = 1.0






const CONFETTI_FALL_TOP_INSET: float = 80.0




const CONFETTI_SIDE_EDGE_INSET: float = 40.0

const CONFETTI_SIDE_SPAN_RATIO: float = 0.8


const CONFETTI_SIDE_EMIT_DUR: float = 0.15


var _fireworks: FireworkShow

var _confetti_fall: GPUParticles2D


var _confetti_side: GPUParticles2D
var _confetti_side_r: GPUParticles2D
var _sparkle_side: GPUParticles2D
var _sparkle_side_r: GPUParticles2D
var _reward: RewardLayer
var _game_data: GameDataLayer
@onready var _encouragement: RichTextLabel = $Encouragement
var _ad_button: FinishAdButton
@onready var _next_button: CommonBtn = $NextButton


var _entrance_complete: bool = false
var _reward_entrance_complete: bool = false

var _presentation_generation: int = 0

var _is_super_hard_title: bool = false
var _next_level_unique_id: String = ""
var _next_fade_tween: Tween = null
var _encouragement_fade_tween: Tween = null
var _ad_enabled: bool = false
var _game_data_enabled: bool = false
var _score_haptic_event: int = -1
var _score_haptic: int = 0
var _timed_endless_result: Dictionary = {}
var _encouragement_selection: Dictionary = {}
var _data_encouragement_height: float = DATA_ENCOURAGEMENT_HEIGHT
var _ad_busy: bool = false
var _ad_reward_presenting: bool = false
var _ad_claimed: bool = false

var _ad_refresh_busy: bool = false
var _ad_refresh_requested: bool = false
var _next_requested: bool = false
var _cart_exit_tween: Tween = null
const BUTTON_APPEAR_DELAY: float = 0.1
const EXIT_UI_FADE_DUR: float = 0.18
const EXIT_DECORATION_FADE_DUR: float = 0.45

const CART_EXIT_DUR: float = 0.9


var _confetti_side_tween: Tween = null



func _ready() -> void :
	prepare_cached_dependencies()
	_components = PageComponentLoader.new(self, COMPONENT_SCENES)
	AudioManager.claim_button_sound(_next_button)
	visible = false
	_refresh_encouragement()
	get_viewport().size_changed.connect(_layout_next_button)
	AdManager.reward_ad_loaded.connect(_on_reward_ad_loaded)


const COMPONENT_SCENES: Dictionary = {
	"RewardLayer": {"RewardLayer": "res://scripts/main/dialogs/finish/view/reward_layer.tscn"}, 
	"AdButton": {"AdButton": "res://scripts/main/dialogs/finish/view/finish_ad_button.tscn"}, 
	"GameDataLayer": {"GameDataLayer": "res://scripts/main/dialogs/finish/view/game_data_layer.tscn"}, 
}
var _components: PageComponentLoader
var _content_ready: bool = false
var _particle_dependencies_injected: bool = false
var _fall_particles: = GpuParticleLifecycle.new()
var _side_particles: = GpuParticleLifecycle.new()


func prepare_cached_dependencies() -> void :
	if _particle_dependencies_injected:
		return
	FinishParticleCache.inject("confetti", self, ["ConfettiFall", "Confetti", "ConfettiRight", "Sparkle", "SparkleRight"])
	FinishParticleCache.inject_fireworks(self)
	_fireworks = get_node("FireworkLayer") as FireworkShow
	_confetti_fall = get_node("ConfettiFall") as GPUParticles2D
	_confetti_side = get_node("Confetti") as GPUParticles2D
	_confetti_side_r = get_node("ConfettiRight") as GPUParticles2D
	_sparkle_side = get_node("Sparkle") as GPUParticles2D
	_sparkle_side_r = get_node("SparkleRight") as GPUParticles2D
	_fall_particles.prepare([_confetti_fall], 2, func() -> bool: return is_visible_in_tree() and not _next_requested)
	_side_particles.prepare([_confetti_side, _confetti_side_r, _sparkle_side, _sparkle_side_r], 2, 
		func() -> bool: return is_visible_in_tree() and not _next_requested)
	_fall_particles.reset_immediate()
	_side_particles.reset_immediate()
	_particle_dependencies_injected = true


func prepare_component_dependencies(_path: String, component: Node) -> void :
	if component.has_method("prepare_cached_dependencies"):
		component.prepare_cached_dependencies()


func prepare_for_display(active: Callable) -> bool:
	if not is_node_ready():
		await ready
	for group: String in COMPONENT_SCENES:
		if not await _components.ensure_group(group, active):
			return false
	_content_ready = true
	_layout_next_button()
	await _reward.prepare_render_points()
	return active.call()


func bind_component_group(group: String) -> void :
	match group:
		"RewardLayer": _reward = get_node("RewardLayer") as RewardLayer
		"GameDataLayer":
			_game_data = get_node("GameDataLayer") as GameDataLayer
			_game_data.card_appeared.connect(_on_score_card_appeared)
		"AdButton":
			_ad_button = get_node("AdButton") as FinishAdButton
			_ad_button.pressed.connect(_on_ad_pressed)
	get_node(group).process_mode = Node.PROCESS_MODE_INHERIT


func show_bg() -> void :
	if not _content_ready:
		if not await prepare_for_display( func() -> bool: return is_inside_tree() and visible):
			return
	await super.show_bg()


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_encouragement()
		_layout_next_button()



func _refresh_encouragement() -> void :
	if not _timed_endless_result.is_empty():
		var phrase: String = tr(String(_timed_endless_result["encouragement_key"]))
		if int(_timed_endless_result["cups"]) > 10:
			phrase = (tr("TIMED_CHALLENGE_RESULT") % [int(_timed_endless_result["cups"]), 
				float(_timed_endless_result["percentile"])]) + "\n" + phrase
		_encouragement.text = _colored_encouragement(phrase)
		return
	var key: String = String(_encouragement_selection.get("key", "FINISH_ENCOURAGEMENT_NORMAL_1"))
	var text: String = tr(key)
	var metric: String = String(_encouragement_selection.get("metric", "normal"))
	if metric == "iq":
		text = text % int(_encouragement_selection["iq"])
	elif metric != "normal":
		text = text % int(_encouragement_selection["pct"])
	_encouragement.text = _colored_encouragement(text)



static func _colored_encouragement(text: String) -> String:
	var percent: = RegEx.new()
	percent.compile("[0-9]+(?:[.,][0-9]+)?[   ]*[%％٪]")
	return percent.sub(text.replace("[", "[lb]"), "[color=#F19D17]$0[/color]", true)



func _fit_encouragement() -> void :
	var large_text: bool = _game_data_enabled or not _timed_endless_result.is_empty()
	var text_height: float = TIMED_ENCOURAGEMENT_HEIGHT if not _timed_endless_result.is_empty() else DATA_ENCOURAGEMENT_HEIGHT
	var text_size: = Vector2(ENCOURAGEMENT_SIZE.x, 
		text_height if large_text else ENCOURAGEMENT_SIZE.y)
	var paragraph: = TextParagraph.new()
	paragraph.width = text_size.x - 16.0
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var font: Font = _encouragement.get_theme_font("normal_font")
	var font_size: int = DATA_ENCOURAGEMENT_FONT_SIZE if large_text else ENCOURAGEMENT_FONT_SIZE
	while font_size > 1:
		_encouragement.add_theme_font_size_override("normal_font_size", font_size)
		paragraph.clear()
		paragraph.add_string(_encouragement.get_parsed_text(), font, font_size)

		if _encouragement.get_line_count() <= 2 and paragraph.get_line_count() <= 2\
		and paragraph.get_size().y <= text_size.y - 16.0\
		and _encouragement.get_content_height() <= text_size.y - 16.0:
			break
		font_size -= 1
	_encouragement.add_theme_font_size_override("normal_font_size", font_size)
	if large_text:
		_data_encouragement_height = text_size.y
	_encouragement.size = _encouragement_size()
	if large_text:

		_data_encouragement_height = _encouragement.size.y


func _encouragement_size() -> Vector2:
	return Vector2(ENCOURAGEMENT_SIZE.x, 
		_data_encouragement_height if _game_data_enabled or not _timed_endless_result.is_empty() else ENCOURAGEMENT_SIZE.y)




func prepare_render_pool() -> void :
	if not _content_ready:
		await prepare_for_display( func() -> bool: return is_inside_tree())
	await _reward.prepare_render_points()
	await _fireworks.prepare_pool_spread()





func warm_render_pipeline() -> bool:
	var viewport: = get_viewport() as SubViewport
	if viewport == null or viewport.get_parent() is SubViewportContainer:
		SortLogger.error("FinishDialog warmup requires a detached SubViewport")
		return false

	reset_content()
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:dialog_shell")
	visible = true


	await _wait_render_frames(1)

	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:dialog_shell")


	await _fireworks.warm_render_pipeline()


	await _reward.warm_render_pipeline()

	await _game_data.warm_render_pipeline()


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:confetti_fall")
	_show_confetti_fall()
	_confetti_fall.request_particles_process(0.1)
	await _wait_render_frames(3)
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:confetti_fall")
	_hide_confetti_fall()

	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:confetti_side")
	await _show_confetti_side()
	for c: GPUParticles2D in [_confetti_side, _confetti_side_r, _sparkle_side, _sparkle_side_r]:
		c.request_particles_process(0.1)
	await _wait_render_frames(1)
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:confetti_side")
	_hide_confetti_side()

	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:ad_button")
	await _ad_button.warm_render_pipeline()
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:ad_button")


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:button")
	_next_button.btn_text = "NEXT"
	_next_button.set_button_disabled(false)
	_next_button.modulate.a = 1.0
	_encouragement.show()
	_encouragement.modulate.a = 1.0
	await _wait_render_frames(1)
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:button")

	reset_content()
	visible = false
	return true


func _wait_render_frames(count: int) -> void :
	for i in count:
		await RenderingServer.frame_post_draw




func _layout_next_button() -> void :
	if not _content_ready:
		return

	SceneManager.reset_button_feedback(_next_button)
	SceneManager.reset_button_feedback(_ad_button)
	var vp: Vector2 = UiMetrics.viewport_size()
	_next_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_next_button.size = NEXT_BTN_SIZE
	var button_gap: float = AD_BUTTON_GAP
	var center_y: float = vp.y - NEXT_FACE_CENTER_FROM_BOTTOM + NEXT_FACE_CENTER_LIFT
	var split_offset: float = (NEXT_BTN_SIZE.y + button_gap) * 0.5 if _ad_enabled else 0.0
	var next_top: float = center_y + split_offset - NEXT_BTN_SIZE.y * 0.5
	if _game_data_enabled:
		var bottom_gap: float = DOUBLE_BUTTON_BOTTOM_GAP if _ad_enabled else SINGLE_BUTTON_BOTTOM_GAP
		next_top = vp.y - UiMetrics.safe_insets().y - bottom_gap - NEXT_BTN_SIZE.y
	_ad_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_ad_button.size = NEXT_BTN_SIZE
	_ad_button.position = Vector2(UiMetrics.center_left(NEXT_BTN_SIZE.x), 
		next_top - (NEXT_BTN_SIZE.y + button_gap if _ad_enabled else 0.0))
	_next_button.position = Vector2(
		UiMetrics.center_left(NEXT_BTN_SIZE.x), 
		next_top)
	var first_button_top: float = _ad_button.position.y if _ad_enabled else next_top
	var text_gap: float = TEXT_AD_BUTTON_GAP if _ad_enabled else TEXT_BUTTON_GAP
	_fit_encouragement()
	var text_size: Vector2 = _encouragement_size()
	_encouragement.visible = _game_data_enabled or not _timed_endless_result.is_empty()
	_encouragement.position = Vector2(UiMetrics.center_left(ENCOURAGEMENT_SIZE.x), 
		first_button_top - text_gap - text_size.y)
	var content_bottom: float = first_button_top - DATA_REWARD_GAP
	if _game_data_enabled:
		_game_data.position = Vector2(UiMetrics.center_left(GameDataLayer.ROW_SIZE.x), 
			_encouragement.position.y - DATA_TEXT_GAP - GameDataLayer.ROW_SIZE.y)
		content_bottom = _game_data.position.y - DATA_REWARD_GAP
	elif not _timed_endless_result.is_empty():

		content_bottom = _encouragement.position.y - DATA_REWARD_GAP

	_reward.pivot_offset = Vector2(vp.x * 0.5, 0.0)
	_reward.position = Vector2(0.0, - DATA_REWARD_LIFT if _game_data_enabled else 0.0)
	_reward.scale = Vector2.ONE * minf(1.0, (content_bottom - _reward.position.y) / REWARD_CONTENT_BOTTOM)
	SceneManager.clear_button_feedback_baseline(_next_button)
	SceneManager.clear_button_feedback_baseline(_ad_button)


func _decoration_nodes() -> Array[CanvasItem]:
	return [_confetti_fall, _confetti_side, _confetti_side_r, _sparkle_side, _sparkle_side_r, _fireworks]






func reset_content() -> void :
	HapticManager.cancel_event(_score_haptic)
	_score_haptic = 0
	_score_haptic_event = -1
	if not _content_ready:
		return
	_presentation_generation += 1
	if _cart_exit_tween != null and _cart_exit_tween.is_valid():
		_cart_exit_tween.kill()
	_cart_exit_tween = null
	_game_data.modulate.a = 1.0
	for decoration: CanvasItem in _decoration_nodes():
		decoration.modulate.a = 1.0
	_game_data.reset()
	_encouragement.modulate.a = 0.0
	_encouragement_selection.clear()
	_data_encouragement_height = DATA_ENCOURAGEMENT_HEIGHT
	_timed_endless_result = {}
	_refresh_encouragement()
	_game_data_enabled = false
	_ad_enabled = false
	_ad_busy = false
	_ad_reward_presenting = false
	_ad_claimed = false
	_ad_refresh_requested = false
	_next_requested = false
	_ad_button.reset_reward()
	_layout_next_button()
	_reward_entrance_complete = false
	_next_level_unique_id = ""
	_entrance_complete = false
	_hide_reward()
	_hide_fireworks()
	_hide_confetti_fall()
	_hide_confetti_side()
	_hide_next_button()
	modulate.a = 1.0







func _on_show(params: Dictionary) -> void :
	_next_special_challenge = false



	Tracker.track_scr_show(TrackingEvents.SCR_GAME_FINISH)
	_is_super_hard_title = bool(params.get("is_super_hard", false))
	await super._on_show(params)
	_ad_enabled = bool(params.get("ad_reward_enabled", false))
	var haptic_style: int = int(params.get("haptic_style", 0))
	_reward.haptic_style = haptic_style
	_reward.cart_appear_sound_id = StringName(params.get("finish_cart_appear_sound_id", &"finish_cart_appear"))
	_score_haptic_event = HapticProfiles.shake_event_for(HapticProfiles.Event.IQ_SCORE_POP, haptic_style)\
	if haptic_style in [1, 2] else -1
	_game_data_enabled = bool(params.get("game_data_enabled", false))
	_timed_endless_result = (params.get("timed_endless_result", {}) as Dictionary).duplicate(true)
	if not _timed_endless_result.is_empty():
		_game_data_enabled = false
	_refresh_encouragement()
	_layout_next_button()
	_play_celebration(bool(params.get("is_hard", false)))






















func _play_celebration(is_hard: bool) -> void :
	if not visible:
		return
	_show_fireworks()
	_show_confetti_side()
	_wait_then_show_reward(is_hard)
	_wait_then_show_confetti_fall()




func _show_fireworks() -> void :

	_fireworks.show()
	_fireworks.play()



func _hide_fireworks() -> void :
	if is_instance_valid(_fireworks):
		_fireworks.stop()





func _wait_then_show_reward(is_hard: bool) -> void :
	var generation: int = _presentation_generation
	await get_tree().create_timer(_REWARD_DELAY).timeout

	if not visible or generation != _presentation_generation:
		return
	_show_reward(is_hard)
	await get_tree().create_timer(RewardLayer.APPEAR_DUR).timeout

	if not visible or generation != _presentation_generation:
		return
	_reward_entrance_complete = true



func _show_reward(is_hard: bool) -> void :
	_reward.play_appear(is_hard, _is_super_hard_title)




func _hide_reward() -> void :
	_reward.reset()






func _wait_then_show_confetti_fall() -> void :
	var generation: int = _presentation_generation
	await get_tree().create_timer(_CONFETTI_DELAY).timeout

	if not visible or generation != _presentation_generation or _next_requested:
		return
	_show_confetti_fall()




func _show_confetti_fall() -> void :
	_fall_particles.reconfigure(_place_confetti_fall)
	_fall_particles.play()


func _hide_confetti_fall() -> void :
	_fall_particles.reset_immediate()



func _place_confetti_fall() -> void :
	var vs: Vector2 = UiMetrics.viewport_size()
	_confetti_fall.position = Vector2(vs.x * 0.5, - CONFETTI_FALL_TOP_INSET)
	var pm: ParticleProcessMaterial = _confetti_fall.process_material as ParticleProcessMaterial
	pm.emission_box_extents.x = vs.x * 0.5
	_confetti_fall.visibility_rect = Rect2( - vs.x * 0.5 - 200.0, -700.0, vs.x + 400.0, vs.y + 1060.0)






func _show_confetti_side() -> void :
	_side_particles.reconfigure(_place_confetti_side)
	_kill_confetti_side_tween()
	_side_particles.play()
	_confetti_side_tween = create_tween()
	_confetti_side_tween.tween_interval(CONFETTI_SIDE_EMIT_DUR)
	_confetti_side_tween.tween_callback(_side_particles.stop_with_tail)


func _hide_confetti_side() -> void :
	_kill_confetti_side_tween()
	_side_particles.reset_immediate()


func _kill_confetti_side_tween() -> void :
	if _confetti_side_tween != null and _confetti_side_tween.is_valid():
		_confetti_side_tween.kill()
	_confetti_side_tween = null






func _place_confetti_side() -> void :
	var vs: Vector2 = UiMetrics.viewport_size()
	var y: float = vs.y * 0.5
	for c: GPUParticles2D in [_confetti_side, _sparkle_side]:
		c.position = Vector2( - CONFETTI_SIDE_EDGE_INSET, y)
	for c: GPUParticles2D in [_confetti_side_r, _sparkle_side_r]:
		c.position = Vector2(vs.x + CONFETTI_SIDE_EDGE_INSET, y)
	for c: GPUParticles2D in [_confetti_side, _confetti_side_r, _sparkle_side, _sparkle_side_r]:
		var pm: ParticleProcessMaterial = c.process_material as ParticleProcessMaterial
		pm.emission_box_extents.y = vs.y * CONFETTI_SIDE_SPAN_RATIO * 0.5
		c.visibility_rect = Rect2(-160.0, - vs.y * 0.5 - 300.0, vs.x + 320.0, vs.y + 600.0)





func _on_score_card_appeared(_index: int) -> void :
	if visible and _game_data_enabled and not _next_requested and _score_haptic_event >= 0:
		_score_haptic = HapticManager.play_event(_score_haptic_event)


func _exit_tree() -> void :
	HapticManager.cancel_event(_score_haptic)
	_score_haptic = 0



func show_game_data(data: Dictionary, is_hard: bool, is_super_hard: bool) -> void :
	var generation: int = _presentation_generation
	var presentation: Dictionary = data.duplicate()
	var percentiles: Dictionary = CompleteEncourageTextPicker.get_percentiles(data)
	presentation["percentiles"] = percentiles
	if _encouragement_selection.is_empty():
		_encouragement_selection = CompleteEncourageTextPicker.pick(percentiles, 
			String(data.get("iq_replacement_metric", "")) if bool(data.get("iq_data_enabled", false)) else "", 
			float(data.get("final_iq", 0.0)), bool(data.get("iq_score_boost_enabled", false)))
	_refresh_encouragement()

	if _game_data_enabled:
		_layout_next_button()
	while not _reward_entrance_complete:
		if not is_inside_tree() or not visible or generation != _presentation_generation:
			return
		await get_tree().process_frame

	if not visible or generation != _presentation_generation or not _game_data_enabled:
		return
	_game_data.set_data(presentation, is_hard, is_super_hard)
	_game_data.play_appear()
	while not _game_data.is_entrance_complete():
		if not is_inside_tree() or not visible or generation != _presentation_generation:
			return
		await get_tree().process_frame




func show_next_button() -> void :
	var generation: int = _presentation_generation
	while not _reward_entrance_complete:
		if not is_inside_tree() or not visible or generation != _presentation_generation:
			return
		await get_tree().process_frame
	if not is_inside_tree() or not visible or generation != _presentation_generation:
		return
	if not _entrance_complete and _next_fade_tween == null:
		await get_tree().create_timer(BUTTON_APPEAR_DELAY).timeout
		if not is_inside_tree() or not visible or generation != _presentation_generation or _next_requested:
			return
		_show_next_button()
	while not _entrance_complete:
		if not is_inside_tree() or not visible or generation != _presentation_generation:
			return
		await get_tree().process_frame





func _show_next_button() -> void :
	_refresh_next_button()
	_next_button.modulate.a = 0.0
	_next_button.disabled = true
	if _ad_enabled:
		_ad_button.start_roll(FinishAdRewardTable.draw())
	_next_fade_tween = _next_button.create_tween()
	_next_fade_tween.tween_property(_next_button, "modulate:a", 1.0, NEXT_FADE_DUR)
	if _game_data_enabled or not _timed_endless_result.is_empty():
		_encouragement.modulate.a = 0.0
		_encouragement_fade_tween = _encouragement.create_tween()
		_encouragement_fade_tween.tween_property(_encouragement, "modulate:a", 1.0, ENCOURAGEMENT_FADE_DUR)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_next_fade_tween.tween_callback( func() -> void :
		if visible:
			_entrance_complete = true
			_refresh_next_button())



func set_next_tracking(unique_id: String, special_challenge: bool) -> void :
	_next_level_unique_id = unique_id
	_next_special_challenge = special_challenge


func _refresh_next_button() -> void :
	var locked: bool = _ad_busy or _next_requested or not _entrance_complete
	_next_button.variant = CommonBtn.Variant.SECONDARY
	_next_button.btn_text = "NEXT"
	_next_button.base_font_size = 102
	_next_button.btn_icon = null
	_next_button.btn_sub_text = ""
	_next_button.btn_sub_icon = null
	_next_button.set_button_disabled(false)
	_next_button.disabled = locked


func is_entrance_complete() -> bool:
	return _entrance_complete



func is_reward_entrance_complete() -> bool:
	return _reward_entrance_complete





func _hide_next_button() -> void :
	if _encouragement_fade_tween != null and _encouragement_fade_tween.is_valid():
		_encouragement_fade_tween.kill()
	_encouragement_fade_tween = null
	if _next_fade_tween != null and _next_fade_tween.is_valid():
		_next_fade_tween.kill()
	_next_fade_tween = null
	_next_button.modulate.a = 0.0
	_next_button.variant = CommonBtn.Variant.SECONDARY
	_next_button.set_button_disabled(true)
	_next_button.btn_sub_text = ""
	_next_button.btn_sub_icon = null
	_next_button.btn_icon = null





func _on_next_pressed() -> void :
	if not _next_special_challenge:
		Tracker.track_btn_click(TrackingEvents.BTN_NEXT, "", _next_level_unique_id)
	if _next_button.disabled or not _entrance_complete:
		return
	_ad_button.cancel_roll()
	_request_next()



func _request_next() -> void :
	if _next_requested:
		return
	_next_requested = true
	_next_button.disabled = true
	_ad_button.disabled = true
	_ad_button.cancel_roll()

	if _encouragement_fade_tween != null and _encouragement_fade_tween.is_valid():
		_encouragement_fade_tween.kill()
	_encouragement_fade_tween = null

	_kill_confetti_side_tween()
	_fall_particles.stop_with_tail()
	_side_particles.stop_with_tail()
	_reward.play_disappear()
	var generation: int = _presentation_generation
	_cart_exit_tween = create_tween()
	_cart_exit_tween.tween_property(_next_button, "modulate:a", 0.0, EXIT_UI_FADE_DUR)
	_cart_exit_tween.parallel().tween_property(_ad_button, "modulate:a", 0.0, EXIT_UI_FADE_DUR)
	_cart_exit_tween.parallel().tween_property(_game_data, "modulate:a", 0.0, EXIT_UI_FADE_DUR)
	_cart_exit_tween.parallel().tween_property(_encouragement, "modulate:a", 0.0, EXIT_UI_FADE_DUR)
	var exit_duration: float = minf(CART_EXIT_DUR, RewardLayer.DISAPPEAR_DUR)
	var decoration_fade: float = minf(EXIT_DECORATION_FADE_DUR, exit_duration)
	for decoration: CanvasItem in _decoration_nodes():
		_cart_exit_tween.parallel().tween_property(decoration, "modulate:a", 0.0, decoration_fade)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_cart_exit_tween.tween_interval(maxf(0.0, exit_duration - maxf(EXIT_UI_FADE_DUR, decoration_fade)))
	_cart_exit_tween.tween_callback(_finish_cart_exit.bind(generation))


func _finish_cart_exit(generation: int) -> void :
	if visible and generation == _presentation_generation and _next_requested:
		next_pressed.emit()



func _on_ad_pressed() -> void :
	if not _ad_button.disabled and _entrance_complete and not _ad_busy and not _ad_claimed:
		Tracker.track_btn_click(TrackingEvents.BTN_GAME_END_ADS, TrackingEvents.SCR_GAME_FINISH)
		ad_reward_pressed.emit()

func begin_ad_claim() -> Dictionary:
	var reward: Dictionary = _ad_button.get_settled_reward()
	if not visible or not _ad_enabled or _ad_busy or _ad_claimed or _ad_button.disabled or reward.is_empty():
		return {}
	_ad_busy = true
	_ad_button.set_claim_busy(true)
	_next_button.disabled = true
	return {"generation": _presentation_generation, "reward": reward}

func is_ad_claim_current(generation: int) -> bool:
	return generation == _presentation_generation and visible and _ad_busy and not _ad_claimed

func begin_ad_reward_presentation(generation: int) -> void :
	if not is_ad_claim_current(generation):
		return

	_ad_enabled = false
	_ad_button.reset_reward()
	_layout_next_button()
	_ad_reward_presenting = true
	_next_button.disabled = true

func get_ad_reward_texture(kind: String) -> Texture2D:
	return _ad_button.get(("coin" if kind == "coins" else kind) + "_icon") as Texture2D

func end_ad_claim(generation: int, rewarded: bool) -> void :
	if not is_ad_claim_current(generation):
		return
	_ad_busy = false
	_ad_reward_presenting = false
	_ad_claimed = rewarded
	if rewarded:
		_ad_enabled = false
		_ad_button.reset_reward()
		_layout_next_button()
	else:

		_ad_button.set_ad_available(false)
		_ad_button.set_claim_busy(false)
	_refresh_next_button()
	if not rewarded:
		_refresh_ad_available()


func _on_reward_ad_loaded() -> void :
	_refresh_ad_available()




func _refresh_ad_available() -> void :
	if not visible or not _ad_enabled or _ad_busy or _ad_claimed or _next_requested or not _ad_button.visible:
		return
	_ad_button.set_ad_available(false)
	_ad_refresh_requested = true
	if _ad_refresh_busy:
		return
	_ad_refresh_busy = true
	while _ad_refresh_requested:
		_ad_refresh_requested = false
		var generation: int = _presentation_generation
		var available: bool = await AdManager.check_reward_ads_available("finish_ad_reward")
		if generation != _presentation_generation or _ad_refresh_requested:
			continue
		if visible and _ad_enabled and not _ad_busy and not _ad_claimed and not _next_requested:
			_ad_button.set_ad_available(available)
	_ad_refresh_busy = false

func _on_hide() -> void :
	reset_content()
	await super._on_hide()

var _next_special_challenge: bool = false
