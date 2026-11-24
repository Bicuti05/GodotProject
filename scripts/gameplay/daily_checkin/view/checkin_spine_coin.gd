extends Node2D

const Config = preload("res://scripts/gameplay/daily_checkin/view/checkin_module_config.gd")
var shared_data: SpineSkeletonDataResource
var actor: SpineSprite
var reference_width: = 100.0
var animation_seconds: = 0.0
var front_bounds: Rect2
var active: = false
var paused: = false
var landing_start: = -1.0
var landing_end: = 0.0

func _ready() -> void :
	var spec: Dictionary = Config.read().coin
	actor = $coinNativeSpine
	shared_data = actor.get_skeleton_data_res()
	for anim in shared_data.get_animations():
		if anim.get_name() == spec.animation: animation_seconds = anim.get_duration()
	assert (animation_seconds > 0, "Missing rotating coin animation")
	actor.get_skeleton().set_to_setup_pose()
	actor.get_animation_state().set_animation(spec.animation, true, 0)
	actor.update_skeleton(0)
	front_bounds = actor.get_skeleton().get_bounds()
	assert (front_bounds.size.x > 0)
	actor.scale = Vector2.ONE * reference_width / front_bounds.size.x
	actor.position = - front_bounds.get_center() * actor.scale
	stop()

func play(phase: float = 0.0) -> void :
	show()
	active = true
	paused = false
	landing_start = -1.0
	var entry = actor.get_animation_state().set_animation(Config.read().coin.animation, true, 0)
	entry.set_track_time(clampf(phase, 0.0, 0.9) * animation_seconds)
	entry.set_time_scale(1.0)
	entry.set_mix_duration(0.0)
	actor.update_skeleton(0)

func align_landing(progress: float) -> void :
	if progress < 0.65 or not active: return
	var entry = actor.get_animation_state().get_current(0)
	if landing_start < 0:
		landing_start = entry.get_track_time()
		landing_end = ceilf(landing_start / animation_seconds) * animation_seconds
		entry.set_time_scale(0.0)
	entry.set_track_time(lerpf(landing_start, landing_end, smoothstep(0.65, 1.0, progress)))
	actor.update_skeleton(0)

func _process(delta: float) -> void :
	if active and not paused and is_visible_in_tree(): actor.update_skeleton(delta)
func suspend(value: bool) -> void : paused = value
func stop() -> void :
	active = false
	paused = false
	landing_start = -1.0
	hide()
func _exit_tree() -> void :
	if is_instance_valid(actor): actor.set_skeleton_data_res(null)
