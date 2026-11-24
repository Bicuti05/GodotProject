class_name GameDataLayer
extends Control


signal card_appeared(index: int)


const CARD_BASE_SIZE: = Vector2(280.0, 269.2308)
const CARD_SCALE: float = 1.05
const CARD_SIZE: = CARD_BASE_SIZE * CARD_SCALE
const CARD_GAP: float = 24.0
const ROW_SIZE: = Vector2(CARD_SIZE.x * 3.0 + CARD_GAP * 2.0, CARD_SIZE.y)
const POP_DURATION: float = 0.14
const POP_STAGGER: float = 0.45
const COUNT_DURATION: float = 0.3
const POP_FROM_SCALE: float = 0.5
const PUNCH_SCALE: float = 1.1
const PUNCH_UP: float = 0.05
const PUNCH_DOWN: float = 0.1
const BURST_EDGE_POINTS: int = 64
const BURST_EDGE_BAND: float = 5.0
const APPEAR_SOUND_VOLUME: float = 1.25

@export var normal_background: Texture2D
@export var hard_background: Texture2D
@export var super_hard_background: Texture2D
@export var s_badge: Texture2D
@export var a_badge: Texture2D
@export var b_badge: Texture2D
@export var rise_badge: Texture2D

@onready var _cards: Array[Control] = [$TimeCard, $StepCard, $StreakCard]
@onready var _time_value: Label = $TimeCard / Value
@onready var _step_value: Label = $StepCard / Value
@onready var _streak_value: Label = $StreakCard / Value
@onready var _badges: Array[ResultBadge] = [$TimeCard / Badge, $StepCard / Badge, $StreakCard / Badge]
var _bursts: Array[GPUParticles2D] = []
var _burst_lifecycles: Array[GpuParticleLifecycle] = []
var _particle_dependencies_injected: bool = false
var _dst_values: Array[int] = [0, 0, 1]

var _pop_tween: Tween = null
var _entrance_complete: bool = false
var _presentation_generation: int = 0
var _appeared_mask: int = 0


func _ready() -> void :
	prepare_cached_dependencies()
	_bursts.assign([$TimeCard / Burst, $StepCard / Burst, $StreakCard / Burst])
	for emitter: GPUParticles2D in _bursts:
		var lifecycle: = GpuParticleLifecycle.new()
		lifecycle.prepare([emitter], 2, func() -> bool: return is_visible_in_tree())
		_burst_lifecycles.append(lifecycle)
	size = ROW_SIZE
	for i in _cards.size():
		_cards[i].position = Vector2(i * (CARD_SIZE.x + CARD_GAP), 0.0)
		_cards[i].size = CARD_BASE_SIZE
		_cards[i].pivot_offset = CARD_BASE_SIZE * 0.5
		_cards[i].position += (CARD_SIZE - CARD_BASE_SIZE) * 0.5
	reset()


func prepare_cached_dependencies() -> void :
	if _particle_dependencies_injected:
		return
	for i: int in 3:
		FinishParticleCache.inject("card%d" % i, get_node(["TimeCard", "StepCard", "StreakCard"][i]), ["Burst"])
	_particle_dependencies_injected = true


func set_data(data: Dictionary, is_hard: bool, is_super_hard: bool) -> void :
	var seconds: int = maxi(0, int(data["elapsed_ms"])) / 1000
	var iq_enabled: bool = bool(data.get("iq_data_enabled", false))
	var iq_metric: String = String(data.get("iq_replacement_metric", "")) if iq_enabled else ""
	var final_iq: float = float(data.get("final_iq", 0.0))
	var display_metrics: Array[String] = CompleteEncourageTextPicker.METRICS.duplicate()
	_dst_values = [seconds, maxi(0, int(data["move_attempt_count"])), maxi(1, int(data["win_streak_count"]))]
	if iq_metric == "streak":

		display_metrics = ["time", "streak", "step"]
		_dst_values = [_dst_values[0], _dst_values[2], _dst_values[1]]
	for i: int in range(1, _cards.size()):
		var metric: String = display_metrics[i]
		var replace_with_iq: bool = metric == iq_metric
		if replace_with_iq:
			_dst_values[i] = maxi(0, roundi(final_iq))
		(_cards[i].get_node("Title") as Label).text = "FINISH_DATA_IQ" if replace_with_iq\
		else ("FINISH_DATA_STEPS" if metric == "step" else "FINISH_DATA_STREAK")
	_time_value.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	_step_value.text = str(_dst_values[1])
	_streak_value.text = str(_dst_values[2])
	var background: Texture2D = normal_background
	if is_super_hard:
		background = super_hard_background
	elif is_hard:
		background = hard_background
	for card: Control in _cards:
		(card.get_node("Background") as TextureRect).texture = background
		_fit_label(card.get_node("Title") as Label, 50)
		_fit_label(card.get_node("Value") as Label, 64)
	var percentiles: Dictionary = data.get("percentiles", {})
	var improvements: Dictionary = data.get("record_improvements", {})
	var textures: Dictionary = {"s": s_badge, "a": a_badge, "b": b_badge, "rise": rise_badge}
	for i: int in _cards.size():
		var metric: String = display_metrics[i]
		var rating: String = ""
		if metric == iq_metric:
			rating = CompleteEncourageTextPicker.iq_badge(final_iq, bool(data.get("iq_score_boost_enabled", false)))
		else:
			var has_rating_data: bool = not bool(data.get("use_new_result_data", false))\
			or ResultPercentileBank.has_metric_data(metric, int(data["target_flower_count"]), true)
			rating = CompleteEncourageTextPicker.badge(
				float(percentiles.get(metric, -1.0)), bool(improvements.get(metric, false))) if has_rating_data else ""
		_badges[i].configure(textures.get(rating), rating == "rise")


func _fit_label(label: Label, font_size: int) -> void :
	var font: Font = label.get_theme_font("font")
	var text: String = label.tr(label.text)
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var available_width: float = label.size.x - 12.0
	var fitted_size: int = font_size
	if text_width > available_width:
		fitted_size = maxi(1, floori(font_size * available_width / text_width))

		while fitted_size > 1 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size).x > available_width:
			fitted_size -= 1
	label.add_theme_font_size_override("font_size", fitted_size)


func play_appear() -> void :
	reset()
	var generation: int = _presentation_generation
	for i: int in _cards.size():
		_set_card_value(0.0, i)
	visible = true
	_pop_tween = create_tween().set_parallel(true)
	var complete_at: float = maxf(POP_DURATION, COUNT_DURATION) + POP_STAGGER * (_cards.size() - 1)
	for i in _cards.size():
		var card: Control = _cards[i]
		var delay: float = i * POP_STAGGER
		_pop_tween.tween_callback(_play_card_appear.bind(i, generation)).set_delay(delay)
		_pop_tween.tween_property(card, "modulate:a", 1.0, POP_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
		_pop_tween.tween_property(card, "scale", Vector2.ONE * CARD_SCALE, POP_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
		_pop_tween.tween_method(_set_card_value.bind(i), 0.0, 1.0, COUNT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)

		var stamp_at: float = delay + maxf(POP_DURATION, COUNT_DURATION)
		var impact_at: float = stamp_at + ResultBadge.STAMP_PRESS_DURATION
		_pop_tween.tween_callback(_play_card_sound.bind(i, generation)).set_delay(impact_at)

		if _badges[i].texture != null:
			_badges[i].append_stamp(_pop_tween, stamp_at, _play_card_burst.bind(i))
			_pop_tween.tween_property(card, "scale", Vector2.ONE * CARD_SCALE * PUNCH_SCALE, PUNCH_UP)\
			.from(Vector2.ONE * CARD_SCALE).set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT).set_delay(impact_at)
			_pop_tween.tween_property(card, "scale", Vector2.ONE * CARD_SCALE, PUNCH_DOWN)\
			.from(Vector2.ONE * CARD_SCALE * PUNCH_SCALE).set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT).set_delay(impact_at + PUNCH_UP)
			complete_at = maxf(complete_at, stamp_at + maxf(ResultBadge.STAMP_DURATION, 
				ResultBadge.STAMP_PRESS_DURATION + PUNCH_UP + PUNCH_DOWN))
	_pop_tween.tween_callback( func() -> void : _entrance_complete = true)\
	.set_delay(complete_at)


func _set_card_value(progress: float, index: int) -> void :
	var value: int = floori(_dst_values[index] * progress)
	match index:
		0: _time_value.text = "%02d:%02d" % [value / 60, value % 60]
		1: _step_value.text = str(value)
		2: _streak_value.text = str(value)


func is_entrance_complete() -> bool:
	return _entrance_complete


func _play_card_burst(index: int) -> void :
	_burst_lifecycles[index].play()


func _play_card_appear(index: int, generation: int) -> void :
	var bit: int = 1 << index
	if generation != _presentation_generation or not is_visible_in_tree() or (_appeared_mask & bit) != 0:
		return
	_appeared_mask |= bit
	card_appeared.emit(index)



func _play_card_sound(index: int, generation: int) -> void :
	if generation != _presentation_generation or not is_visible_in_tree():
		return
	match index:
		0: AudioManager.play_sfx(&"finish_data_time", APPEAR_SOUND_VOLUME)
		1: AudioManager.play_sfx(&"finish_data_steps", APPEAR_SOUND_VOLUME)
		2: AudioManager.play_sfx(&"finish_data_streak", APPEAR_SOUND_VOLUME)


func warm_render_pipeline() -> void :

	for difficulty in 3:

		NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:game_data_cards_d%d" % difficulty)
		set_data({"elapsed_ms": 809000, "move_attempt_count": 1234567890, 
			"win_streak_count": 1234567890}, difficulty == 1, difficulty == 2)
		visible = true
		for card: Control in _cards:
			card.scale = Vector2.ONE * CARD_SCALE
			card.modulate.a = 1.0
		await RenderingServer.frame_post_draw

		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:game_data_cards_d%d" % difficulty)

	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:game_data_badges")
	for texture: Texture2D in [s_badge, a_badge, b_badge]:
		_badges[0].configure(texture, false)
		_badges[0].show()
		_badges[0].scale = Vector2.ONE
		_badges[0].modulate.a = 1.0
		await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:game_data_badges")


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:game_data_rise")
	_badges[0].warm_rise()
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:game_data_rise")
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:game_data_burst")
	await _play_card_burst(0)
	_bursts[0].request_particles_process(0.1)
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:game_data_burst")
	reset()


func reset() -> void :
	_presentation_generation += 1
	_appeared_mask = 0
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = null
	for id: StringName in [&"finish_data_time", &"finish_data_steps", &"finish_data_streak"]:
		AudioManager.stop_sfx(id)
	_entrance_complete = false
	visible = false
	for card: Control in _cards:
		card.scale = Vector2.ONE * CARD_SCALE * POP_FROM_SCALE
		card.modulate.a = 0.0
	for lifecycle: GpuParticleLifecycle in _burst_lifecycles:
		lifecycle.reset_immediate()
	for badge_node: ResultBadge in _badges:
		badge_node.reset()
