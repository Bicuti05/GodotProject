extends Control

signal presentation_closed

signal continue_pressed

const SpineCoin = preload("res://scripts/gameplay/daily_checkin/view/checkin_spine_coin.tscn")
const ModuleConfig = preload("res://scripts/gameplay/daily_checkin/view/checkin_module_config.gd")
const MeteorTrail = preload("res://scripts/gameplay/daily_checkin/view/meteor_rank_trail.tscn")
const Metrics = preload("res://scripts/gameplay/daily_checkin/view/daily_checkin_layout.gd")
const MeteorHead = preload("res://scripts/gameplay/daily_checkin/view/checkin_meteor_head.tscn")
@export var coin_trail_scene: PackedScene
@export var cute_expression: Texture2D
@export var proud_expression: Texture2D
@export var party_expression: Texture2D
@export var check_texture: Texture2D
@export var idle_texture: Texture2D
@export var gift_texture: Texture2D
const HERO_FINAL: = Vector2(541.37, 669.42)
const HERO_INITIAL: = Vector2(540.0, 1165.0)
const HERO_SCALE: = 744.0 / 1280.0
const CHECK_SIZE: = 107.1
const CHECK_OFFSET: = Vector2(0, 2.625)
const CHECKIN_SETTLE_SOUND_LEAD_SECONDS: float = 0.31
const CHECKIN_SFX_VOLUMES: Dictionary = {
	&"checkin_transform": 0.65, 
	&"checkin_celebration_phrase": 0.72, 
	&"checkin_confetti": 0.56, 
	&"checkin_settle": 0.46, 
	&"checkin_gift_open": 0.69, 
}
var module_config: Dictionary = ModuleConfig.read()
var ACTIVATION_AT: float = module_config.ui.activation_at
var INFORMATION_AT: float = module_config.ui.information_at
var INFORMATION_END: float = module_config.ui.information_end
var TODAY_FEEDBACK_AT: float = module_config.ui.today_feedback_at
var OK_SOURCE_AT: float = module_config.ui.ok_source_at
var OK_SOURCE_END: float = module_config.ui.ok_source_end
var POST_STAMP_HOLD: float = module_config.ui.post_stamp_hold
var OK_UNLOCK_HOLD: float = module_config.ui.ok_unlock_hold
var REWARD_POST_GIFT_HOLD: float = module_config.ui.reward_post_gift_hold
const GROUP_HOME: = [Vector2(317, 981), Vector2(73, 1252), Vector2(0, 0), Vector2(50, 1758), Vector2(160, 1858.551)]
const DAY_HINT_KEYS: Array[String] = [
	"DAILY_CHECKIN_DAY_1_HINT", 
	"DAILY_CHECKIN_DAY_2_HINT", 
	"DAILY_CHECKIN_DAY_3_HINT", 
	"DAILY_CHECKIN_DAY_4_HINT", 
	"DAILY_CHECKIN_DAY_5_HINT", 
	"DAILY_CHECKIN_DAY_6_HINT", 
	"DAILY_CHECKIN_DAY_7_HINT", 
]

var day: = 1
var settlement: Dictionary = {}
var reward_by_day: Dictionary = {}
var celebrate: bool = false
var hero_arrived: bool = false
var hero_idle_started: bool = false
var party_lift_started: bool = false
var background_flow: ColorRect
var celebration_ripple: Node2D
var confetti_burst: Node2D
var rank_confetti_burst: Node2D
var confetti_fall: Node2D
var coin_trails: Array[CPUParticles2D] = []
var _coin_trail_pool: Array[CPUParticles2D] = []
var reward_visible: = false
var today_completed: = false
var closed: = true

var stage: Node2D
var background: Sprite2D
var background_motion: Node
var active_trails: Array[Node2D] = []
var active_meteors: Array[Node2D] = []
var _meteor_pool: Array[Node2D] = []
var _yellow_trail_pool: Array[Node2D] = []
var _pink_trail_pool: Array[Node2D] = []
var _coin_pool: Array[Node2D] = []
var meteor_serial: = 0
var motion_paused: = false
var meteor_active: = false
var _last_meteor_palette: int = -1
var hero: Node2D
var rank_particles: Node2D
var hero_activation: Node2D
var cell_activation: Node2D
var check_stamp_burst: Node2D
var gift_idles: Dictionary = {}
var reward_cell_proxy: Node2D
var hero_image: Sprite2D
var hero_mask: Sprite2D
var spine_hero: Node
var hero_expression: Texture2D
var celebration_started: = false
var ui_unlock_ready: = false
var celebration_core_complete: = true
var focus_active: = false
var focus_weight: = 1.0
var sweep_image: Sprite2D
var sweep_material: ShaderMaterial
var glow: Sprite2D
var calendar: Node2D
var day_icons: Array[Node2D] = []
var day_bases: Array[Sprite2D] = []
var number: Node2D
var heading: Node2D
var message: Node2D
var ok_rig: Node2D
var ok_button: Button
var info_groups: Array[Node2D] = []
var party_fx: Node2D
var fx: Node2D
var ambient: Node2D
var meteor: Node2D
var gift_actor: Node2D
var coin_hud: Control
var coin_balance: Label
var coin_hud_icon: TextureRect
var reward_hint: Node2D
var coin_flights: Array[Node2D] = []
var reward_phase: = "off"
var displayed_coins: int = 0
var landed_coins: = 0
var reward_aura: Sprite2D
var reward_veil: ColorRect
var reward_layer: Node2D
var reward_card: Node2D
var reward_hit: Button
var reward_number: Node2D
var reward_title: Node2D
var reward_icon: Node2D
var reward_fx: Node2D
var page_curves: Dictionary
var ok_entrance_complete: = false
var director: Node
var sound_players: Array[AudioStreamPlayer] = []
@onready var _check_confirm_sound: AudioStreamPlayer = $Audio / Sound1
var _presentation_prepared: bool = false
var _preparation_failed: bool = false

func _ready() -> void :
	page_curves = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effect/daily_checkin/pics_page_curves.json"))
	director = $MotionDirector
	_bind_scene()
	stage.hide()
	background.hide()
	background_motion.stop()
	get_viewport().size_changed.connect(_layout_viewport)
	_layout_viewport()
	if not await hero_activation.native_rays.wait_for_preparation():
		_preparation_failed = true
		return
	await spine_hero.wait_for_preparation()
	if not is_inside_tree():
		return

	for mask: Texture2D in spine_hero.masks.values():
		rank_particles.idle.prepare_mask(mask, Vector2(618, 590))
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_presentation_prepared = true

func wait_for_preparation() -> bool:
	while not _presentation_prepared and not _preparation_failed and is_inside_tree():
		await get_tree().process_frame
	return _presentation_prepared

func _layout_viewport() -> void :
	var viewport_size: = UiMetrics.viewport_size()
	Metrics.apply(stage, viewport_size)

	coin_hud.scale = Vector2.ONE / stage.scale
	coin_hud.position = stage.to_local(Vector2(viewport_size.x - coin_hud.size.x - 24.0, 20.0 + UiMetrics.safe_insets().x))
	background.scale = viewport_size / background.texture.get_size()
	background_flow.size = viewport_size
	var screen_rect: Rect2 = Rect2(stage.to_local(Vector2.ZERO), viewport_size / stage.scale)
	confetti_fall.configure_layout(screen_rect)
	rank_confetti_burst.configure_layout(screen_rect)
	var reward_screen_rect: Rect2 = Rect2(reward_layer.to_local(Vector2.ZERO), viewport_size / stage.scale)
	reward_veil.position = reward_screen_rect.position
	reward_veil.size = reward_screen_rect.size
	reward_hit.position = reward_screen_rect.position
	reward_hit.size = reward_screen_rect.size

func play_settlement(result: Dictionary) -> void :
	settlement = result.duplicate(true)
	day = int(settlement.day_index)
	reward_by_day = settlement.reward_by_day.duplicate()
	celebrate = day >= int(module_config.expression.celebration_from_day)

	_cancel_visuals()
	celebration_core_complete = not celebrate
	hero_arrived = false
	displayed_coins = int(settlement.coins_before)
	coin_hud.set_display(displayed_coins, int(settlement.coins_after))
	closed = false

	background.hide()
	stage.hide()
	background.modulate.a = 0.0
	$FigmaStage / TopCloud.self_modulate.a = 0.0
	$FigmaStage / BottomCloud.self_modulate.a = 0.0
	number.text = str(day)
	_refresh_locale()
	today_completed = false
	_set_expression(party_expression if celebrate else proud_expression)
	_restore_final_layout()
	_render_days(day if today_completed else day - 1)
	background_motion.start()
	background_flow.start()
	director.begin()

	hero.position = HERO_INITIAL + Vector2(0, 20)
	hero.scale = Vector2.ONE * 0.97
	hero.modulate.a = 0.0
	glow.position = HERO_INITIAL
	glow.modulate.a = 0.0
	_set_expression(cute_expression)
	meteor.modulate.a = 1.0
	ambient.modulate.a = 0.0
	for index in info_groups.size():
		info_groups[index].modulate.a = 0.0
		info_groups[index].position = GROUP_HOME[index] + Vector2(0, 32)
	ok_button.disabled = true
	ok_entrance_complete = false
	background.show()
	stage.show()
	var background_enter: Tween = director.animate()
	background_enter.tween_property(background, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for cloud: CanvasItem in [$FigmaStage / TopCloud, $FigmaStage / BottomCloud]:
		var cloud_enter: Tween = director.animate()
		cloud_enter.tween_interval(0.05)
		cloud_enter.tween_property(cloud, "self_modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	director.at(0.08, "hero_entrance", _hero_entrance)
	director.at(ACTIVATION_AT, "expression_sweep", _expression_sweep)


	if not celebrate:
		director.at(ACTIVATION_AT + 1.2, "hero_settle_drift", _hero_lift)
		director.at(ACTIVATION_AT + 1.32, "hero_lift", _start_ambient)



func _hero_entrance() -> void :
	var tween: Tween = director.animate().set_parallel(true)
	tween.tween_property(hero, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(hero, "position", HERO_INITIAL, 0.37).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(hero, "scale", Vector2.ONE, 0.37).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "modulate:a", 1.0, 0.32)

func _expression_sweep() -> void :

	_play_checkin_sfx(&"checkin_transform")
	hero_activation.begin_reveal()

func _swap_expression_at_peak() -> void :
	if closed or not director.running:
		return
	director.cue_fired.emit("expression_swap")
	_set_expression(party_expression if celebrate else proud_expression, false, celebrate)
	hero_activation.play_feedback(Vector2(618, 590), true, 1.0)

	var center: = stage.to_local(hero.global_position)
	rank_particles.play_impact(center, 618.0 * absf(hero.scale.x))
	if celebrate:
		_play_checkin_sfx(&"checkin_celebration_phrase")
		director.at(float(module_config.party_flow.after_swap_delay), "spine_celebrate_after_swap", _start_celebration_before_lift)

func _on_sunflower_slam() -> void :
	if closed or not director.running: return
	director.cue_fired.emit("sunflower_slam_particles")
	if celebrate:
		background_flow.expand_from(hero.global_position / UiMetrics.viewport_size(), 1.0)


func _start_sunflower_idle() -> void :
	if closed or not hero_arrived or hero_idle_started:
		return
	hero_idle_started = true
	if not celebrate:
		spine_hero.play_peek_sequence()
		director.cue_fired.emit("spine_peek_after_settle")
	rank_particles.start_idle(hero_mask, Vector2(618, 590))
	rank_particles.set_occluded(reward_visible)
	rank_particles.suspend(motion_paused)
	if celebrate:
		confetti_fall.start()
		confetti_fall.suspend(motion_paused or reward_visible)

func _shooting_star(force_palette: int = -1) -> void :
	if closed or not stage.visible or reward_visible or motion_paused or focus_active or active_meteors.size() >= 3:
		return
	for index in range(active_trails.size() - 1, -1, -1):
		if not is_instance_valid(active_trails[index]):
			active_trails.remove_at(index)
	var rng: RandomNumberGenerator = background_motion.rng
	var right_edge: = stage.to_local(Vector2(UiMetrics.viewport_size().x, 0)).x
	var left_edge: = stage.to_local(Vector2.ZERO).x
	var lane: = meteor_serial % 3
	meteor_serial += 1
	var entry_y: = rng.randf_range(-780, -550) if lane == 0 else (rng.randf_range(-460, -160) if lane == 1 else rng.randf_range(90, 350))
	var from: = Vector2(right_edge + rng.randf_range(70, 190), entry_y)
	var to: = Vector2(left_edge - rng.randf_range(150, 240), 0.0)

	to.y = from.y + from.x - to.x
	var duration: = rng.randf_range(1.85, 2.3)
	var pink: bool = force_palette == 1 if force_palette >= 0 else (_last_meteor_palette != 1 if _last_meteor_palette >= 0 else rng.randf() < 0.45)
	_last_meteor_palette = 1 if pink else 0
	var head: Node2D = _meteor_pool.pop_back() if not _meteor_pool.is_empty() else MeteorHead.instantiate()
	head.name = "PinkMeteor" if pink else "YellowMeteor"
	head.position = from
	head.modulate.a = 0.0
	head.scale = Vector2.ONE * rng.randf_range(0.76, 1.0)
	if head.get_parent() == null:
		meteor.add_child(head)
	head.show()
	var art: Sprite2D = head.get_node("Star")
	art.scale = Vector2.ONE * 0.17
	art.modulate = Color(1.0, 0.72, 0.9) if pink else Color(1.0, 0.92, 0.2)
	var star_material: = CanvasItemMaterial.new()
	star_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	art.material = star_material
	active_meteors.append(head)
	meteor_active = true
	var pool: Array[Node2D] = _pink_trail_pool if pink else _yellow_trail_pool
	var fresh: bool = pool.is_empty()
	var trail: Node2D = MeteorTrail.instantiate() if fresh else pool.pop_back()
	trail.name = "RealRankPinkTrail" if pink else "RealRankYellowTrail"

	if trail.get_parent() == null:
		meteor.add_child(trail)
	trail.set_meta(&"pink", pink)
	trail.show()
	meteor.move_child(trail, 0)
	active_trails.append(trail)
	if pink and fresh:
		trail.use_pink_palette()
	trail.follow(head)
	var peak_alpha: = 0.78 if pink else 1.0
	trail.modulate.a = peak_alpha
	var tween: Tween = director.animate().set_parallel(true)
	tween.tween_property(head, "modulate:a", peak_alpha, 0.16)
	tween.tween_method( func(t: float) -> void :
		if is_instance_valid(head):
			head.position = from.lerp(to, t)
		if is_instance_valid(trail):
			trail.sample_current()
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(head, "modulate:a", 0.0, 0.8).set_delay(duration * 0.72)
	tween.tween_property(trail, "modulate:a", 0.0, 0.8).set_delay(duration * 0.72)
	tween.chain().tween_callback( func() -> void :
		_release_trail(trail)
		_release_meteor(head)
		meteor_active = not active_meteors.is_empty()
	)

func _hero_lift() -> void :
	if celebrate:
		confetti_fall.start()
		confetti_fall.suspend(motion_paused or reward_visible)
		director.cue_fired.emit("party_confetti_fall_during_lift")
	var tween: Tween = director.animate()
	var lift_seconds: float = float(module_config.ui.hero_lift_seconds)

	director.at(maxf(0.0, lift_seconds - CHECKIN_SETTLE_SOUND_LEAD_SECONDS), "hero_settle_sound", func() -> void :
		_play_checkin_sfx(&"checkin_settle")
	)
	tween.tween_method(_sample_hero_lift, 0.0, 1.0, lift_seconds).set_trans(Tween.TRANS_LINEAR)
	director.at(float(module_config.ui.information_lift_delay), "information_reveal", _reveal_information)
	director.at(float(module_config.ui.information_lift_delay) + 0.64, "today_confirm", _confirm_today)
	tween.tween_callback(_on_hero_lift_finished)

func _sample_hero_lift(value: float) -> void :

	var time: float = clampf(value, 0.0, 1.0)
	var progress: float = time * time * (10.0 + time * (-20.0 + time * (15.0 - 4.0 * time)))
	hero.position = HERO_INITIAL.lerp(HERO_FINAL, progress)
	glow.position = HERO_INITIAL.lerp(Vector2(540, 657), progress)
	if celebrate:
		celebration_ripple.follow_lift(hero.position, progress)
		background_flow.set_arrival_fade(1.0 - smoothstep(0.92, 1.0, progress))
		if progress >= 0.999:
			background_flow.stop()

func _start_celebration_before_lift() -> void :
	if closed or not director.running or not celebrate or celebration_started or spine_hero.role != "party":
		return
	celebration_started = true
	spine_hero.play_celebrate()

func _on_hero_lift_finished() -> void :
	if closed:
		return
	hero_arrived = true
	hero.position = HERO_FINAL
	background_flow.stop()
	_start_sunflower_idle()

	_try_finish_presentation()

func _start_ambient() -> void :
	director.animate().tween_property(ambient, "modulate:a", 1.0, 0.6)

func _reveal_information() -> void :


	for index in 4:
		var group: Node2D = info_groups[index]
		group.position = GROUP_HOME[index] + Vector2(0, float(module_config.ui.information_offset_y))
		group.modulate.a = 0.0
		var tween: Tween = director.animate().set_parallel(true)
		tween.tween_property(group, "position", GROUP_HOME[index], 0.4).set_delay(index * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(group, "modulate:a", 1.0, 0.4).set_delay(index * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _after_today_feedback() -> void :
	director.cue_fired.emit("today_feedback_complete")
	director.at(POST_STAMP_HOLD, "ok_reveal", _reveal_ok)

func _after_gift_feedback() -> void :
	director.cue_fired.emit("gift_feedback_complete")

	director.at(REWARD_POST_GIFT_HOLD, "reward_reveal", _show_reward)

func _reveal_ok() -> void :
	ok_entrance_complete = false
	ok_button.disabled = true
	var tween: Tween = director.animate()
	tween.tween_method(_sample_ok, OK_SOURCE_AT, OK_SOURCE_END, OK_SOURCE_END - OK_SOURCE_AT)
	tween.tween_callback( func() -> void :
		ok_entrance_complete = true
		director.cue_fired.emit("ok_entrance_complete")
		director.at(OK_UNLOCK_HOLD, "ok_unlock_ready", _on_ui_unlock_ready)
	)

func _sample_ok(source_time: float) -> void :
	var alpha: float = clampf(hero_activation._sample_keys(page_curves["Root/ContinueButton/m_Alpha"], source_time, ""), 0.0, 1.0)
	ok_rig.modulate.a = alpha
	ok_rig.position = GROUP_HOME[4] + Vector2(0, 32.0 * (1.0 - alpha))

func _confirm_today() -> void :
	var rig: = day_icons[day - 1]
	if settlement.reward_coins > 0:
		_play_reward_cell(rig)
		return
	_play_check_stamp(rig, _after_today_feedback, true)

func _play_check_stamp(rig: Node2D, completed: Callable, ordinary: bool = false) -> void :
	day_bases[day - 1].show()
	rig.show()

	var stamp: = rig.get_child(0) as Sprite2D
	stamp.texture = check_texture
	var check_scale: Vector2 = Vector2.ONE * (CHECK_SIZE / check_texture.get_width())
	stamp.position = CHECK_OFFSET
	stamp.scale = check_scale * 1.75
	stamp.modulate.a = 0.0
	stamp.show()
	var tween: Tween = director.animate()



	tween.tween_property(stamp, "scale", check_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(stamp, "modulate:a", 1.0, 0.08)
	tween.tween_callback( func() -> void :
		today_completed = true
		_render_days(day)
		if ordinary: _play_check_confirm_sound()
		stamp.scale = check_scale * Vector2(1.08, 0.9)
		cell_activation.position = rig.position
		cell_activation.play_feedback(Vector2(102.9, 102.9), false, 2.0)
		cell_activation.burst.emitting = false
		cell_activation.burst.hide()
		check_stamp_burst.play(rig.position + CHECK_OFFSET, CHECK_SIZE)
		director.cue_fired.emit("check_stamp_impact")
		fx.ring(rig.position, Color("fff1a5"))
	)
	tween.tween_interval(0.05)
	tween.tween_property(stamp, "scale", check_scale * Vector2(0.97, 1.04), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(stamp, "scale", check_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(completed)

func _play_reward_cell(rig: Node2D) -> void :

	var original: Sprite2D = rig.get_node("DayStateOverlay")
	var visual: Sprite2D = reward_cell_proxy.get_node("GiftVisual")
	visual.texture = original.texture
	visual.transform = original.transform
	visual.modulate = original.modulate
	reward_cell_proxy.position = rig.position
	reward_cell_proxy.scale = Vector2.ONE
	reward_cell_proxy.rotation = 0.0
	reward_cell_proxy.show()
	if gift_idles.has(day - 1): gift_idles[day - 1].target = reward_cell_proxy
	rig.hide()
	cell_activation.position = rig.position
	cell_activation.play_feedback(Vector2(96.6, 108.15), false, 2.0)

	director.at(0.16, "gift_cell_ready", _after_gift_feedback)

func _show_reward() -> void :
	if closed or reward_visible or int(settlement.reward_coins) <= 0: return
	rank_particles.set_occluded(true)
	spine_hero.suspend(true)
	confetti_fall.suspend(true)
	for idle in gift_idles.values(): idle.set_occluded(true)
	reward_visible = true
	reward_phase = "travel"
	reward_fx.reset()
	reward_layer.show()
	reward_layer.modulate.a = 1.0
	reward_veil.modulate.a = 0.0
	reward_aura.modulate.a = 0.2
	reward_title.modulate.a = 0.0
	reward_number.modulate.a = 0.0
	reward_number.position = Vector2(-250, -175 + float(module_config.gift.display_offset_y))
	reward_number.box_size = Vector2(500, 160)
	reward_number.text = "+%d" % settlement.reward_coins
	reward_icon.stop()
	reward_hit.disabled = true
	reward_hint.text = ""
	coin_hud.show()
	reward_cell_proxy.hide()
	day_icons[day - 1].hide()
	var source = reward_card.to_local(day_icons[day - 1].to_global(Vector2.ZERO))
	var destination = Vector2(0, 40)
	gift_actor.start_idle()
	gift_actor.position = source
	gift_actor.scale = Vector2.ONE * float(module_config.gift.cell_width) / float(module_config.gift.width)
	director.cue_fired.emit("gift_depart_calendar")
	var tween = director.animate().set_parallel(true)
	tween.tween_property(reward_veil, "modulate:a", 1.0, 0.18)

	tween.tween_method( func(seconds: float) -> void :
		_sample_gift_flight(seconds, source, destination)
	, 0.0, float(module_config.gift.travel_seconds), float(module_config.gift.travel_seconds)).set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_callback(_on_gift_arrived)

func _sample_gift_flight(seconds: float, source: Vector2, destination: Vector2) -> void :
	var curve: Dictionary = module_config.gift.travel_curve
	var lift_time = float(curve.lift_seconds)
	var main_time = float(curve.main_seconds)
	var settle_time = float(curve.settle_seconds)
	var small = float(module_config.gift.cell_width) / float(module_config.gift.width)
	var lift = source + Vector2(0, - float(curve.lift_distance))
	var landing = destination + Vector2(0, - float(curve.landing_overshoot))
	if seconds <= lift_time:
		var u = smoothstep(0.0, 1.0, clampf(seconds / lift_time, 0.0, 1.0))
		gift_actor.position = source.lerp(lift, u)
		gift_actor.scale = Vector2.ONE * small * lerpf(1.0, 1.04, u)
	elif seconds < lift_time + main_time:
		var u = clampf((seconds - lift_time) / main_time, 0.0, 1.0)
		var progress = smoothstep(0.0, 1.0, u)
		var dx = destination.x - source.x
		var control1 = lift + Vector2(dx * 0.25, -85)
		var control2 = landing + Vector2( - dx * 0.12, -24)
		var inverse = 1.0 - progress
		gift_actor.position = inverse * inverse * inverse * lift + 3 * inverse * inverse * progress * control1 + 3 * inverse * progress * progress * control2 + progress * progress * progress * landing
		var growth = smoothstep(float(curve.scale_delay_fraction), 1.0, u)
		gift_actor.scale = Vector2.ONE * lerpf(small * 1.04, 1.0, growth)
	else:
		var u = clampf((seconds - lift_time - main_time) / settle_time, 0.0, 1.0)
		gift_actor.position = landing.lerp(destination, smoothstep(0.0, 1.0, u))
		var squash = sin(PI * u) * 0.015
		gift_actor.scale = Vector2(1.0 + squash, 1.0 - squash)

func _on_gift_arrived() -> void :
	if closed or not reward_visible or reward_phase != "travel": return
	reward_phase = "idle"
	reward_hit.disabled = false
	director.cue_fired.emit("gift_idle")
	reward_fx.play_title(Rect2(reward_title.position, reward_title.box_size))
	reward_fx.suspend(motion_paused)
	var tween = director.animate().set_parallel(true)
	tween.tween_property(reward_title, "modulate:a", 1.0, 0.12)
	tween.chain().tween_callback(dismiss_reward)

func dismiss_reward() -> void :

	if not reward_visible or reward_hit.disabled or reward_phase != "idle": return
	reward_hit.disabled = true
	reward_phase = "open"
	reward_hint.text = ""
	director.cue_fired.emit("gift_open")
	gift_actor.open_box()

func _on_gift_opening_sound_cued() -> void :
	if reward_visible and reward_phase == "open":
		_play_checkin_sfx(&"checkin_gift_open")

func _on_gift_reward_revealed() -> void :
	if closed or not reward_visible or reward_phase != "open": return
	reward_phase = "coins"
	director.cue_fired.emit("gift_reward_revealed")
	reward_aura.modulate.a = 1.0
	var retire = director.animate().set_parallel(true)
	var delay = float(module_config.gift.retire_delay)
	var duration = float(module_config.gift.retire_seconds)
	retire.tween_property(gift_actor, "modulate:a", 0.0, duration).set_delay(delay)
	retire.tween_property(gift_actor, "scale", Vector2.ONE * 0.92, duration).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	retire.tween_property(reward_aura, "modulate:a", 0.0, duration).set_delay(delay)
	retire.chain().tween_callback( func() -> void :
		gift_actor.cancel()
		director.cue_fired.emit("gift_retired_after_reveal")
	)
	reward_icon.play()
	reward_icon.position = Vector2(0, -70)
	reward_icon.modulate.a = 0.0
	reward_icon.scale = Vector2.ONE * float(module_config.gift.display_coin_width) * 0.6 / reward_icon.reference_width
	reward_fx.play_coin(reward_icon.position, float(module_config.gift.display_coin_width) * 0.6)
	reward_fx.suspend(motion_paused)
	var tween = director.animate().set_parallel(true)
	tween.tween_method(_sample_reward_coin_reveal, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(reward_icon, "modulate:a", 1.0, 0.1)
	tween.tween_property(reward_number, "modulate:a", 1.0, 0.18).set_delay(0.08)
	tween.chain().tween_interval(float(module_config.gift.coin_hold))
	tween.chain().tween_callback(_collect_reward_coins)

func _sample_reward_coin_reveal(progress: float) -> void :
	var width: float = float(module_config.gift.display_coin_width) * lerpf(0.6, 1.0, progress)
	reward_icon.position = Vector2(0, -70).lerp(Vector2(0, -325 + float(module_config.gift.display_offset_y)), progress)
	reward_icon.scale = Vector2.ONE * width / reward_icon.reference_width
	reward_fx.update_coin_pose(reward_icon.position, width)

func _collect_reward_coins() -> void :
	if closed or not reward_visible or reward_phase != "coins": return
	reward_phase = "collect"
	reward_fx.stop()
	landed_coins = 0
	var fade = director.animate().set_parallel(true)
	fade.tween_property(reward_title, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(reward_icon, "modulate:a", 0.0, 0.14)
	fade.tween_property(reward_number, "modulate:a", 0.0, 0.18)
	fade.chain().tween_callback(reward_icon.stop)
	var count = int(module_config.gift.coin_count)
	var origin = reward_card.position + reward_icon.position
	var destination = reward_layer.to_local(coin_hud.icon_target_rect().get_center())
	var landing_width = coin_hud.icon_design_width() * coin_hud.scale.x
	for i in count:
		var coin: Node2D = _coin_pool.pop_back() if not _coin_pool.is_empty() else SpineCoin.instantiate()
		if coin.get_parent() == null:
			reward_layer.add_child(coin)
		coin.position = origin
		coin.play(randf() * 0.9)
		coin.name = "RewardFlightCoin"
		coin.z_index = 100
		var visible_width = float(module_config.gift.flight_coin_width) + float(i % 3) * 15.0
		coin.scale = Vector2.ONE * visible_width / coin.reference_width
		coin.modulate.a = 0.0
		coin_flights.append(coin)
		var trail: CPUParticles2D = _acquire_coin_trail()
		trail.global_position = coin.global_position

		var angle = - PI * 0.5 + (float(i) - float(count - 1) * 0.5) * 0.55
		var spread = Vector2(cos(angle), sin(angle)) * float(80 + (i % 3) * 45)
		var start = origin + spread
		var arc = float(module_config.gift.flight_arc_height) * randf_range(0.61, 1.39)
		var control = (start + destination) * 0.5 + Vector2((i - (count - 1) * 0.5) * 25.0, arc)
		var duration = float(module_config.gift.flight_seconds) * randf_range(0.7, 1.3)
		var tween = director.animate()
		tween.tween_interval(i * float(module_config.gift.flight_stagger))
		tween.tween_property(coin, "position", start, float(module_config.gift.flight_pop_seconds)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(coin, "modulate:a", 1.0, 0.1)
		tween.tween_callback( func() -> void :
			trail.global_position = coin.global_position
			trail.begin()
		)
		tween.tween_method( func(t: float) -> void :
			coin.position = (1 - t) * (1 - t) * start + 2 * (1 - t) * t * control + t * t * destination
			trail.global_position = coin.global_position

			coin.align_landing(t)
			coin.scale = Vector2.ONE * lerpf(visible_width, landing_width, smoothstep(0.65, 1.0, t)) / coin.reference_width
		, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback( func() -> void :
			trail.retire()
			_release_coin(coin)
			landed_coins += 1
			displayed_coins = int(settlement.coins_before) + int(round(float(settlement.reward_coins) * landed_coins / count))
			coin_hud.set_display(displayed_coins, int(settlement.coins_after))
			coin_hud.punch(director)
			AudioManager.play_sfx(&"coin_fly")
			if landed_coins == count: _finish_coin_collection()
		)

func _finish_coin_collection() -> void :
	displayed_coins = int(settlement.coins_after)
	coin_hud.set_display(displayed_coins, int(settlement.coins_after))
	reward_phase = "done"
	var on_reward_collected: Callable = settlement.get("on_reward_collected", Callable())
	if on_reward_collected.is_valid():
		on_reward_collected.call()
	director.cue_fired.emit("reward_coins_collected")
	var tween = director.animate().set_parallel(true)
	tween.tween_property(reward_layer, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback( func() -> void :
		gift_actor.cancel()
		reward_layer.hide()
		reward_fx.reset()
		reward_visible = false
		rank_particles.set_occluded(false)
		spine_hero.suspend(motion_paused)
		for idle in gift_idles.values(): idle.set_occluded(false)
		confetti_fall.suspend(motion_paused)
		director.at(0.0, "reward_check_reveal", func() -> void :
			_play_check_stamp(day_icons[day - 1], func() -> void :
				director.cue_fired.emit("reward_check_complete")
				_after_today_feedback()
			)
		)
	)

func _on_celebration_focus_started() -> void :
	celebration_core_complete = false
	focus_active = true
	background_motion.set_focus(true)
	confetti_burst.start(stage.global_transform.affine_inverse() * hero.global_transform)
	director.at((float(module_config.party_flow.horn_peak_seconds) + float(module_config.party_flow.side_confetti_delay)) / float(module_config.party_flow.playback_speed), "rank_confetti_after_horn", func() -> void :
		_play_checkin_sfx(&"checkin_confetti")
		rank_confetti_burst.play()
	)

	director.at(float(module_config.party_flow.ripple_start_seconds) / float(module_config.party_flow.playback_speed), "party_ripple_during_hold", func() -> void :
		celebration_ripple.play(stage.to_local(hero.global_position))
	)

func _on_celebration_core_finished() -> void :
	celebration_core_complete = true
	focus_active = false
	background_motion.set_focus(false)
	director.cue_fired.emit("spine_core_blow_complete")
	if celebrate and not party_lift_started:
		party_lift_started = true


		director.at(float(module_config.party_flow.after_blow_hold), "party_lift_after_blow", func() -> void :
			celebration_ripple.retire()
			_hero_lift()
			director.at(0.12, "hero_lift", _start_ambient)
		)

	_try_finish_presentation()

func _on_ui_unlock_ready() -> void :
	ui_unlock_ready = true
	_try_finish_presentation()

func _try_finish_presentation() -> void :
	if closed or reward_visible or not director.running or not ui_unlock_ready or not celebration_core_complete or not hero_arrived: return
	director.cue_fired.emit("complete")
	director.finish()

func _process(delta: float) -> void :
	if is_instance_valid(reward_fx):
		reward_fx.suspend(motion_paused)
	if not _presentation_prepared or closed or motion_paused or not is_instance_valid(meteor): return
	var spec: Dictionary = module_config.focus
	focus_weight = move_toward(focus_weight, 0.0 if focus_active else 1.0, delta / float(spec.transition_seconds))
	meteor.modulate.a = lerpf(float(spec.meteor_opacity), 1.0, focus_weight)
	if is_instance_valid(rank_particles.idle):
		rank_particles.idle.modulate.a = lerpf(float(spec.sunflower_idle_opacity), 1.0, focus_weight)
		rank_particles.idle.focus_suppressed = focus_active
	for idle in gift_idles.values():
		idle.modulate.a = lerpf(float(spec.gift_idle_opacity), 1.0, focus_weight)
		idle.focus_suppressed = focus_active

func _on_complete() -> void :
	background_flow.stop()
	if closed or not ok_entrance_complete:
		return
	ok_button.disabled = false

	SortLogger.info("[DailyCheckin] day=%d reward=%d" % [day, settlement.reward_coins])

func close_presentation(force: bool = false) -> void :
	if closed or (director.running and not force):
		return
	if not _presentation_prepared:
		closed = true
		stage.hide()
		background_motion.stop()
		presentation_closed.emit()

		return
	_cancel_visuals()
	_render_days(day)
	_restore_final_layout()
	closed = true
	spine_hero.cancel()
	for idle in gift_idles.values(): idle.reset()
	stage.visible = false
	background.hide()
	presentation_closed.emit()

	SortLogger.info("CHECKIN_CLOSED day=%d" % day)

func _cancel_visuals() -> void :
	_stop_checkin_sfx()
	ok_entrance_complete = false
	celebration_started = false
	party_lift_started = false
	hero_arrived = false
	hero_idle_started = false
	background_flow.stop()
	celebration_ripple.stop()
	confetti_burst.stop()
	rank_confetti_burst.stop()
	confetti_fall.stop()
	for trail in coin_trails.duplicate():
		_release_coin_trail(trail)
	ui_unlock_ready = false
	celebration_core_complete = true
	focus_active = false
	focus_weight = 1.0
	director.cancel()
	reward_fx.reset()
	background_motion.stop()
	rank_particles.clear()
	motion_paused = false
	meteor_active = false
	_last_meteor_palette = -1
	meteor_serial = 0
	for head in active_meteors.duplicate():
		_release_meteor(head)
	for trail in active_trails.duplicate():
		_release_trail(trail)
	fx.clear()
	party_fx.clear()
	hero_activation.reset()
	spine_hero.cancel()
	cell_activation.reset()
	check_stamp_burst.reset()
	for idle in gift_idles.values(): idle.reset()
	reward_cell_proxy.hide()
	for rig in day_icons: rig.show()
	for player in sound_players:
		player.stop()
		player.stream_paused = false
	reward_visible = false
	reward_phase = "off"
	gift_actor.cancel()
	reward_icon.stop()
	for coin in coin_flights.duplicate():
		_release_coin(coin)
	coin_hud.hide()
	coin_hud.reset()
	reward_layer.visible = false
	reward_hit.disabled = true
	sweep_material.set_shader_parameter("strength", 0.0)
	for rig in day_icons:
		rig.scale = Vector2.ONE

func prepare_hidden_entrance() -> void :
	background.modulate.a = 0.0
	background.hide()
	stage.hide()

func _restore_final_layout() -> void :
	hero.position = HERO_FINAL
	hero.scale = Vector2.ONE
	hero.rotation = 0.0
	hero.modulate.a = 1.0
	_set_expression(party_expression if celebrate else proud_expression)
	glow.position = Vector2(540.0, 657)
	glow.modulate.a = 1.0
	ambient.modulate.a = 1.0
	meteor.position = Vector2.ZERO
	meteor.scale = Vector2.ONE
	meteor.modulate.a = 1.0
	for index in info_groups.size():
		info_groups[index].position = GROUP_HOME[index]
		info_groups[index].scale = Vector2.ONE
		info_groups[index].modulate.a = 1.0
	ok_entrance_complete = true
	ok_button.disabled = false

func _set_expression(texture: Texture2D, celebrate: bool = false, waiting: bool = false) -> void :
	hero_expression = texture
	var role: = "smile" if texture == cute_expression else ("party" if texture == party_expression else "proud")
	spine_hero.set_role(role, celebrate, waiting)
	hero_image.texture = spine_hero.get_texture_for(role)
	hero_image.position = Vector2.ZERO
	hero_image.scale = Vector2.ONE
	hero_mask.texture = spine_hero.masks[role]
	hero_mask.position = Vector2.ZERO
	hero_mask.scale = Vector2.ONE
	hero_mask.hide()
	sweep_image.texture = hero_image.texture
	sweep_image.position = Vector2.ZERO
	sweep_image.scale = Vector2.ONE

	var render_size: Vector2 = spine_hero.get_viewport_size(role)
	hero_activation.rim_material.set_shader_parameter("rim_step", Vector2(14.0 / render_size.x, 14.0 / render_size.y))

func _render_days(completed_days: int) -> void :
	for index in 7:
		var rig: = day_icons[index]
		var has_reward: bool = int(reward_by_day.get(index + 1, 0)) > 0
		day_bases[index].visible = index < completed_days or not has_reward

		var visual: Sprite2D = rig.get_node("DayStateOverlay")
		visual.name = "DayStateOverlay"
		visual.scale = Vector2.ONE
		visual.modulate = Color.WHITE
		visual.position = Vector2.ZERO
		if index < completed_days:
			visual.texture = check_texture
			visual.position = CHECK_OFFSET
			visual.scale = Vector2.ONE * (CHECK_SIZE / check_texture.get_width())
			visual.show()
		elif has_reward:
			visual.texture = gift_texture
			visual.position = Vector2(2.1 if index == 4 else 0.0, -1.575)
			visual.scale = Vector2(96.6, 108.15) / gift_texture.get_size()
			visual.show()
		else:
			visual.texture = idle_texture
			visual.hide()
		if gift_idles.has(index):
			var idle: Node2D = gift_idles[index]
			if index >= completed_days and int(reward_by_day.get(index + 1, 0)) > 0:
				idle.anchor_offset = visual.position
				idle.start(rig, gift_texture, Vector2(96.6, 108.15))
				idle.set_occluded(reward_visible)
				idle.suspend(motion_paused)
			else: idle.reset()

func _exit_tree() -> void :
	_stop_checkin_sfx()
	if director != null:
		director.cancel()
	if background_motion != null:
		background_motion.stop()
	for trail in active_trails:
		if is_instance_valid(trail):
			trail.cancel()
	for player in sound_players:
		player.stop()


func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and not is_visible_in_tree():
		_stop_checkin_sfx()

func _play_checkin_sfx(id: StringName) -> void :
	if closed or not is_visible_in_tree() or motion_paused or not director.running:
		return
	AudioManager.play_sfx(id, float(CHECKIN_SFX_VOLUMES[id]))

func _stop_checkin_sfx() -> void :
	for id: StringName in CHECKIN_SFX_VOLUMES:
		AudioManager.stop_sfx(id)

func _play_check_confirm_sound() -> void :
	if is_visible_in_tree() and UserState.is_sfx_enabled():
		_check_confirm_sound.play()



func _on_continue_pressed() -> void :
	if closed or director.running:
		return
	continue_pressed.emit()
	close_presentation()

func _on_ok_down() -> void :
	ok_rig.scale = Vector2.ONE * 0.97

func _on_ok_up() -> void :
	ok_rig.scale = Vector2.ONE

func _refresh_locale() -> void :
	heading.text = tr("DAILY_CHECKIN_STREAK_TITLE")
	message.text = tr(DAY_HINT_KEYS[day - 1])
	reward_title.text = tr("DAILY_CHECKIN_REWARD_TITLE")
	$FigmaStage / ContinueRig / LiveButtonCaption.text = tr("DAILY_CHECKIN_OK")
	for index in 7:
		calendar.get_node("DayLabel%d" % (index + 1)).text = tr("DAILY_CHECKIN_DAY_LABEL") % (index + 1)

func _bind_scene() -> void :
	stage = $FigmaStage
	background = $Background
	background_flow = $FullScreenColorFlow
	celebration_ripple = $FigmaStage / CelebrationAfterglowRipple
	confetti_burst = $FigmaStage / ScreenAnchoredSpineConfetti
	rank_confetti_burst = $FigmaStage / RankHornInstantConfetti
	confetti_fall = $FigmaStage / CelebrationIdleConfettiFall
	background_motion = $DecorativeBackgroundMotion
	ambient = $FigmaStage / Ambient
	glow = $FigmaStage / HeroGlow
	meteor = $FigmaStage / ShootingStar
	party_fx = $FigmaStage / ConfettiBehindHero
	rank_particles = $FigmaStage / SunflowerRankParticleFeedback
	hero = $FigmaStage / HeroRig
	hero_activation = $FigmaStage / HeroRig / PrimaryActivationLayers
	hero_image = $FigmaStage / HeroRig / Expression
	hero_mask = $FigmaStage / HeroRig / BodyMaskForIdleParticles
	spine_hero = $FigmaStage / HeroRig / LiveSpineHero
	sweep_image = $FigmaStage / HeroRig / AlphaMaskedSweep
	number = $FigmaStage / DayNumber
	heading = $FigmaStage / StreakTitle
	calendar = $FigmaStage / SevenDayCalendar
	cell_activation = $FigmaStage / SevenDayCalendar / TodayCellActivationLayers
	check_stamp_burst = $FigmaStage / SevenDayCalendar / TodayCheckRankLandingBurst
	reward_cell_proxy = $FigmaStage / SevenDayCalendar / RewardCellVisualProxy
	message = $FigmaStage / Encouragement
	ok_rig = $FigmaStage / ContinueRig
	ok_button = $FigmaStage / ContinueRig / ContinueButton
	SceneManager.claim_button_feedback(ok_button)
	fx = $FigmaStage / TransientFX
	reward_layer = $FigmaStage / EarnedCoinsOverlay
	reward_veil = $FigmaStage / EarnedCoinsOverlay / Veil
	reward_card = $FigmaStage / EarnedCoinsOverlay / Card
	reward_title = $FigmaStage / EarnedCoinsOverlay / Card / Title
	reward_fx = $FigmaStage / EarnedCoinsOverlay / Card / RewardFx
	reward_aura = $FigmaStage / EarnedCoinsOverlay / Card / Aura
	gift_actor = $FigmaStage / EarnedCoinsOverlay / Card / Gift
	reward_icon = $FigmaStage / EarnedCoinsOverlay / Card / Coin
	reward_number = $FigmaStage / EarnedCoinsOverlay / Card / Number
	reward_hint = $FigmaStage / EarnedCoinsOverlay / Hint
	reward_hit = $FigmaStage / EarnedCoinsOverlay / Hit
	coin_hud = $FigmaStage / GameCoinHud

	sweep_material = sweep_image.material
	hero_activation.bind_expression(hero_image)
	hero_activation.reveal_material.set_shader_parameter("source_premultiplied", true)
	background_motion.add_cloud($FigmaStage / TopCloud, Vector2(30, 12), 10.0)
	background_motion.add_cloud($FigmaStage / BottomCloud, Vector2(-24, 10), 12.0)
	background_motion.set_glow(glow)
	for index in 7:
		day_bases.append(calendar.get_node("FixedDayGear%d" % (index + 1)))
		day_icons.append(calendar.get_node("DayIcon%d" % (index + 1)))
		if index in [1, 3, 6]:
			gift_idles[index] = calendar.get_node("GiftPodiumIdle%d" % (index + 1))
	info_groups = [number, heading, calendar, message, ok_rig]
	coin_hud_icon = coin_hud.icon
	coin_balance = coin_hud.label
	for child in $Audio.get_children():
		sound_players.append(child)
	number.configure_gradient(Color("fff5be"), Color("ffbd16"))
	number.shadow_offset = Vector2(0, 4)
	heading.configure_gradient(Color("fff4b5"), Color("ffbd16"), 0.1634615)
	heading.shadow_offset = Vector2(0, 2)
	reward_title.configure_gradient(Color("ffff63"), Color("ffc904"), 0.3125)

func _release_meteor(head: Node2D) -> void :
	active_meteors.erase(head)
	head.hide()
	_meteor_pool.append(head)

func _release_trail(trail: Node2D) -> void :
	active_trails.erase(trail)
	trail.cancel()
	trail.hide()
	if bool(trail.get_meta(&"pink")):
		_pink_trail_pool.append(trail)
	else:
		_yellow_trail_pool.append(trail)

func _release_coin(coin: Node2D) -> void :
	coin_flights.erase(coin)
	coin.stop()
	_coin_pool.append(coin)

func _acquire_coin_trail() -> CPUParticles2D:
	var trail: CPUParticles2D
	if _coin_trail_pool.is_empty():
		trail = coin_trail_scene.instantiate()
		stage.add_child(trail)
		trail.expired.connect(_release_coin_trail)
	else:
		trail = _coin_trail_pool.pop_back()
	coin_trails.append(trail)
	return trail

func _release_coin_trail(trail: CPUParticles2D) -> void :
	if not coin_trails.has(trail):
		return
	coin_trails.erase(trail)
	trail.reset()
	_coin_trail_pool.append(trail)

func can_close() -> bool:
	return _presentation_prepared and not closed and not director.running
