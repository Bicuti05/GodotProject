extends Node


signal celebration_started
signal celebration_core_finished
signal acting_finished
@export var smile_mask: Texture2D
@export var proud_mask: Texture2D
@export var party_mask: Texture2D
const ModuleConfig = preload("res://scripts/gameplay/daily_checkin/view/checkin_module_config.gd")
var actors: Dictionary = {}
var views: Dictionary = {}
var masks: Dictionary = {}
var durations: Dictionary = {}
var registration: Dictionary
var config: Dictionary
var role: = ""
var animation: = "idle"
var clock: = 0.0
var paused: = false
var sequence: = ""
var core_finished: = true
var render_warmed: = false
var prepared: bool = false

func _ready() -> void :
	render_warmed = DisplayServer.get_name() == "headless"
	if not render_warmed:
		RenderingServer.frame_post_draw.connect(_finish_render_warmup, CONNECT_ONE_SHOT)
	config = ModuleConfig.read()
	registration = JSON.parse_string(FileAccess.get_file_as_string(config.body_registration))
	for name in config.roles:
		var spec: Dictionary = config.roles[name]
		var view: SubViewport = get_node(str(name) + "SpineViewport")
		var actor: SpineSprite = view.get_node(str(name) + "NativeSpine")
		var data: SpineSkeletonDataResource = actor.get_skeleton_data_res()
		var calibration: Dictionary = registration[name]
		actor.scale = Vector2.ONE * float(calibration.scale)
		actor.position = Vector2(view.size) * 0.5 - Vector2(calibration.offset[0], calibration.offset[1])
		actor.get_skeleton().set_skin_by_name(spec.skin)
		actor.get_skeleton().set_to_setup_pose()
		actor.get_animation_state().set_animation(spec.idle, true, 0)
		actor.update_skeleton(0)
		actors[name] = actor
		views[name] = view
		masks[name] = get(str(name) + "_mask")
		durations[name] = {}
		for anim in data.get_animations(): durations[name][anim.get_name()] = anim.get_duration()
		assert (durations[name].has(spec.idle), "Missing role idle animation")
		await get_tree().process_frame
		if not is_inside_tree():
			return
	prepared = true

func wait_for_preparation() -> void :
	while not prepared and is_inside_tree():
		await get_tree().process_frame

func _finish_render_warmup() -> void :
	render_warmed = true
	for name in views:
		if name != role: (views[name] as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED

func set_role(value: String, celebrate: bool = false, _waiting: bool = false) -> void :
	role = value
	clock = 0.0
	sequence = ""
	core_finished = true
	paused = false
	var spec: Dictionary = config.roles[role]
	animation = spec.idle
	for name in actors:
		(views[name] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS if name == role else (SubViewport.UPDATE_DISABLED if render_warmed else SubViewport.UPDATE_ONCE)
	var actor: SpineSprite = actors[role]
	actor.get_animation_state().clear_tracks()
	actor.get_skeleton().set_to_setup_pose()
	actor.get_animation_state().set_animation(spec.idle, true, 0)
	actor.update_skeleton(0)
	if celebrate: play_celebrate()

func play_peek_sequence() -> void :
	var spec: Dictionary = config.roles.get(role, {})
	if not spec.has("peek_sequence"): return
	clock = 0.0
	sequence = "peek"
	var names: Array = spec.peek_sequence
	var actor: SpineSprite = actors[role]
	var state = actor.get_animation_state()
	state.set_animation(names[0], false, 0)
	for i in range(1, names.size()):
		state.add_animation(names[i], float(durations[role][names[i - 1]]), false, 0)
	state.add_animation(spec.idle, float(durations[role][names.back()]), true, 0)
	actor.update_skeleton(0)
	animation = names[0]

func play_celebrate() -> void :
	var spec: Dictionary = config.roles.get(role, {})
	if not spec.has("celebration"): return
	clock = 0.0
	sequence = "celebration"
	core_finished = false
	animation = "celebrate"
	var actor: SpineSprite = actors[role]
	var entry = actor.get_animation_state().set_animation(spec.celebration, false, 0)
	entry.set_mix_duration(spec.attack_mix_seconds)
	actor.get_animation_state().add_animation(spec.idle, float(durations[role][spec.celebration]), true, 0)
	actor.update_skeleton(0)
	celebration_started.emit()

func return_to_idle() -> void :
	if role.is_empty():
		return
	var spec: Dictionary = config.roles[role]
	var entry = actors[role].get_animation_state().set_animation(spec.idle, true, 0)
	entry.set_mix_duration(float(spec.mix_seconds))
	actors[role].update_skeleton(0.0)
	animation = spec.idle
	sequence = ""

func get_texture_for(value: String) -> Texture2D:
	return (views[value] as SubViewport).get_texture()

func get_viewport_size(value: String) -> Vector2:
	return Vector2((views[value] as SubViewport).size)

func render_target_bytes() -> int:
	var bytes: = 0
	for view: SubViewport in views.values(): bytes += view.size.x * view.size.y * 4
	return bytes

func _finish_core() -> void :
	if core_finished: return
	core_finished = true
	celebration_core_finished.emit()

func _process(delta: float) -> void :
	if role.is_empty() or paused: return
	var animation_delta: float = delta * float(config.party_flow.playback_speed) if sequence == "celebration" else delta
	clock += animation_delta
	var actor: SpineSprite = actors[role]
	actor.update_skeleton(animation_delta)
	var entry = actor.get_animation_state().get_current(0)
	if entry == null: return
	var actual: String = entry.get_animation().get_name()
	var spec: Dictionary = config.roles[role]
	var previous: = animation
	animation = "celebrate" if actual == str(spec.get("celebration", "")) else actual
	if sequence == "celebration":
		if animation == "celebrate" and entry.get_animation_time() >= float(spec.core_complete_seconds): _finish_core()
		if previous == "celebrate" and animation == str(spec.idle):
			_finish_core()
			sequence = ""
			acting_finished.emit()
	elif sequence == "peek" and animation == str(spec.idle):
		sequence = "peek_idle"
		acting_finished.emit()

	if sequence == "peek_idle" and animation == str(spec.idle) and entry.get_track_time() >= float(spec.peek_idle_seconds):
		play_peek_sequence()

func suspend(value: bool) -> void :
	paused = value
	if not role.is_empty():
		(views[role] as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED if value else SubViewport.UPDATE_ALWAYS

func cancel() -> void :
	role = ""
	sequence = ""
	clock = 0.0
	core_finished = true
	paused = false
	for name in actors:
		(actors[name] as SpineSprite).get_animation_state().clear_tracks()
		(views[name] as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED

func _exit_tree() -> void :
	cancel()
	for actor in actors.values():
		if is_instance_valid(actor): (actor as SpineSprite).set_skeleton_data_res(null)
