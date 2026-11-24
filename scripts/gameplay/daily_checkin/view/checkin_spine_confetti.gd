extends Node2D

const Config = preload("res://scripts/gameplay/daily_checkin/view/checkin_module_config.gd")
var running: bool = false
var paused: bool = false
var clock: float = 0.0
var duration: float = 2.6
var playback_speed: float = 1.0
@onready var actor: SpineSprite = $NativeConfetti

func _ready() -> void :
	var config: Dictionary = Config.read()
	playback_speed = float(config.party_flow.playback_speed)
	var spec: Dictionary = config.roles.party
	var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.body_registration))
	var calibration: Dictionary = registration.party
	actor.scale = Vector2.ONE * float(calibration.scale)
	actor.position = - Vector2(calibration.offset[0], calibration.offset[1])
	actor.get_skeleton().set_skin_by_name(spec.skin)
	for animation in actor.get_skeleton_data_res().get_animations():
		if animation.get_name() == spec.celebration:
			duration = animation.get_duration()
	stop()

func start(firing_transform: Transform2D) -> void :
	transform = firing_transform
	clock = 0.0
	running = true
	paused = false
	modulate.a = 1.0
	show()
	actor.get_animation_state().clear_tracks()
	actor.get_skeleton().set_to_setup_pose()
	var entry = actor.get_animation_state().set_animation(Config.read().roles.party.celebration, false, 0)
	entry.set_mix_duration(0.0)
	actor.update_skeleton(0.0)

func _process(delta: float) -> void :
	if not running or paused:
		return
	var animation_delta: float = delta * playback_speed
	clock += animation_delta
	actor.update_skeleton(animation_delta)

	if clock >= duration:
		stop()

func suspend(value: bool) -> void :
	paused = value

func stop() -> void :
	running = false
	paused = false
	clock = 0.0
	hide()
	if is_instance_valid(actor):
		actor.get_animation_state().clear_tracks()

func _exit_tree() -> void :
	if is_instance_valid(actor):
		actor.set_skeleton_data_res(null)
