extends Node2D

signal opened
signal reward_revealed
signal opening_sound_cued
const Config = preload("res://scripts/gameplay/daily_checkin/view/checkin_module_config.gd")
var actor: SpineSprite
var spec: Dictionary
var durations: Dictionary = {}
var release_emitted: = false
var opening_sound_emitted: bool = false
var phase: = "off"
var paused: = false
var calibration_bounds: Rect2

func _ready() -> void :
	spec = Config.read().gift
	actor = $giftNativeSpine
	var data = actor.get_skeleton_data_res()
	for anim in data.get_animations(): durations[anim.get_name()] = anim.get_duration()
	for name in [spec.idle, spec.open]: assert (durations.has(name), "Missing gift animation")
	actor.get_skeleton().set_to_setup_pose()
	actor.get_animation_state().set_animation(spec.idle, true, 0)
	actor.update_skeleton(0)
	calibration_bounds = actor.get_skeleton().get_bounds()
	actor.scale = Vector2.ONE * float(spec.width) / calibration_bounds.size.x
	actor.position = - calibration_bounds.get_center() * actor.scale
	hide()

func start_idle() -> void :
	cancel()
	show()
	phase = "idle"
	paused = false
	actor.get_skeleton().set_to_setup_pose()
	var entry = actor.get_animation_state().set_animation(spec.idle, true, 0)
	entry.set_mix_duration(0)
	actor.update_skeleton(0)

func open_box() -> void :
	if phase != "idle": return
	phase = "open"
	release_emitted = false
	opening_sound_emitted = false
	var entry = actor.get_animation_state().set_animation(spec.open, false, 0)
	entry.set_mix_duration(0.06)
	actor.update_skeleton(0)

func _process(delta: float) -> void :
	if paused or phase == "off" or phase == "opened": return
	actor.update_skeleton(delta)
	var entry = actor.get_animation_state().get_current(0)
	if entry == null: return
	if phase == "open" and not opening_sound_emitted and entry.get_animation_time() >= maxf(0.0, float(spec.reward_reveal_seconds) - float(spec.open_sound_lead_seconds)):
		opening_sound_emitted = true
		opening_sound_cued.emit()
	if phase == "open" and not release_emitted and entry.get_animation_time() >= float(spec.reward_reveal_seconds):
		release_emitted = true
		reward_revealed.emit()
	if phase == "open" and entry.get_animation_time() >= float(durations[spec.open]):
		phase = "opened"
		opened.emit()

func suspend(value: bool) -> void : paused = value
func cancel() -> void :
	phase = "off"
	release_emitted = false
	opening_sound_emitted = false
	paused = false
	modulate = Color.WHITE
	hide()
	if is_instance_valid(actor): actor.get_animation_state().clear_tracks()
func _exit_tree() -> void :
	if is_instance_valid(actor): actor.set_skeleton_data_res(null)
