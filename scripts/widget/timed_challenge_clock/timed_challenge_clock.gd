class_name TimedChallengeClock
extends Control



const ENTER_DURATION: float = 0.68
const FINISH_DURATION: float = 0.55
const IDLE_DURATION: float = 4.0
const POPUP_POINTER_PERIOD: float = 24.0
const HUD_POINTER_PERIOD: float = 32.0
const POINTER_BLEND_DURATION: float = 0.15
const RIBBON_PIVOT: Vector2 = Vector2(533.0, 280.0)
const TITLE_REVEAL_BEGIN: float = 0.18
const TITLE_REVEAL_END: float = 0.38

@export var clock_only: bool = false
@export var decoration_alpha: float = 1.0
@export_range(0.0, 1.0) var hud_pose_weight: float = 0.0
@export var banner_elapsed: float = -1.0
@export var ribbon_sides: Vector4 = Vector4(0.0, 0.0, 1.0, 1.0)

@onready var _player: AnimationPlayer = $AnimationPlayer
@onready var _ribbon: Bone2D = $Stage / Skeleton / Ribbon
@onready var _clock: Bone2D = $Stage / Skeleton / Clock
@onready var _minute_hand: Bone2D = $Stage / Skeleton / Clock / MinuteHand
@onready var _hour_hand: Bone2D = $Stage / Skeleton / Clock / HourHand
@onready var _left_leaf: Bone2D = $Stage / Skeleton / LeftLeaf
@onready var _right_leaf: Bone2D = $Stage / Skeleton / RightLeaf
@onready var _cloth: ShaderMaterial = $Stage / Skeleton / Ribbon / Art.material as ShaderMaterial
var _ribbon_text: Node2D = null
var _pointer_running: bool = false
var _pointer_angle: float = 0.0
var _pointer_speed: float = 0.0
var _pointer_speed_from: float = 0.0
var _pointer_speed_to: float = 0.0
var _pointer_blend_elapsed: float = 0.0


func _ready() -> void :
	reset_now()


func play_enter() -> void :
	_play(&"enter")


func play_finish() -> void :
	_play(&"finish")


func _play(animation: StringName) -> void :
	reset_now()
	show()
	_player.play(animation)
	_player.advance(0.0)
	_player.queue(&"idle")
	_start_pointer_motion(Vector2.ZERO, TAU / POPUP_POINTER_PERIOD)
	_sync_banner_cloth()
	_sync_decorations()
	_sync_ribbon_text()



func play_idle_at_phase(phase: float, playback_rate: float = 1.0, 
		pointer_pose: Vector2 = Vector2(-1.0, -1.0)) -> void :
	reset_now()
	_player.speed_scale = clampf(playback_rate, 0.05, 2.0)
	show()
	_player.play(&"idle")
	_player.seek(fposmod(phase, IDLE_DURATION), true)
	var pointer_speed: float = TAU / (HUD_POINTER_PERIOD if clock_only else POPUP_POINTER_PERIOD)
	var pose: Vector2 = pointer_pose
	if pose.y < 0.0:
		pose = Vector2(phase * pointer_speed, pointer_speed)
	_start_pointer_motion(pose, pointer_speed)
	_sync_decorations()
	_sync_clock_pose()


func idle_phase() -> float:
	return _player.current_animation_position if _player.current_animation == &"idle" else 0.0



func pointer_pose() -> Vector2:
	return Vector2(_pointer_angle, _pointer_speed)


func hide_clock_for_handoff() -> void :
	_clock.hide()


func is_appearing() -> bool:
	return is_playing() and _player.current_animation in [&"enter", &"finish"]


func is_playing() -> bool:
	return is_instance_valid(_player) and _player.is_playing()


func reset_now() -> void :
	_pointer_running = false
	_pointer_angle = 0.0
	_pointer_speed = 0.0
	_pointer_speed_from = 0.0
	_pointer_speed_to = 0.0
	_pointer_blend_elapsed = 0.0
	decoration_alpha = 1.0
	hud_pose_weight = 0.0
	if is_instance_valid(_clock):
		_clock.show()
	if is_instance_valid(_player):
		_player.clear_queue()
		_player.stop()
		_player.speed_scale = 1.0
		_player.play(&"RESET")
		_player.advance(0.0)
		_player.stop()
	_sync_banner_cloth()
	_sync_decorations()
	_reset_ribbon_text()
	hide()


func bind_ribbon_text(host: Node2D) -> void :
	assert (host.get_parent() == get_parent(), "飘带标题和ClockRig必须处于同一局部画布")
	_ribbon_text = host
	_sync_ribbon_text()


func _process(delta: float) -> void :
	if is_visible_in_tree():
		if _clock.visible:
			_advance_pointer_motion(delta)
		_sync_banner_cloth()
		_sync_decorations()
		_sync_clock_pose()
		_sync_ribbon_text()



func _start_pointer_motion(pose: Vector2, target_speed: float) -> void :
	_pointer_angle = pose.x
	_pointer_speed = maxf(pose.y, 0.0)
	_pointer_speed_from = _pointer_speed
	_pointer_speed_to = target_speed
	_pointer_blend_elapsed = 0.0
	_pointer_running = true
	_sync_pointer_pose()


func _pointer_distance_at(time: float) -> float:
	var u: float = clampf(time / POINTER_BLEND_DURATION, 0.0, 1.0)
	var eased_distance: float = u * u * u - 0.5 * u * u * u * u
	var blend_time: float = minf(time, POINTER_BLEND_DURATION)
	return _pointer_speed_from * blend_time\
	+ (_pointer_speed_to - _pointer_speed_from) * POINTER_BLEND_DURATION * eased_distance\
	+ _pointer_speed_to * maxf(time - POINTER_BLEND_DURATION, 0.0)


func _advance_pointer_motion(delta: float) -> void :
	if not _pointer_running or delta <= 0.0:
		return
	var before: float = _pointer_blend_elapsed
	var after: float = before + delta
	_pointer_angle += _pointer_distance_at(after) - _pointer_distance_at(before)
	_pointer_blend_elapsed = minf(after, POINTER_BLEND_DURATION)
	_pointer_speed = lerpf(_pointer_speed_from, _pointer_speed_to, 
		smoothstep(0.0, POINTER_BLEND_DURATION, _pointer_blend_elapsed))
	_sync_pointer_pose()


func _sync_pointer_pose() -> void :
	_minute_hand.rotation = _pointer_angle
	_hour_hand.rotation = 0.0


func _sync_decorations() -> void :
	if not is_instance_valid(_ribbon):
		return
	var opacity: float = 0.0 if clock_only else clampf(decoration_alpha, 0.0, 1.0)
	_ribbon.modulate.a = opacity
	_left_leaf.modulate.a = opacity
	_right_leaf.modulate.a = opacity


func _sync_clock_pose() -> void :
	if clock_only and hud_pose_weight > 0.0:
		_clock.position = _clock.position.lerp(Vector2(532.0, 176.0), hud_pose_weight)
		_clock.rotation *= 1.0 - hud_pose_weight
		_clock.scale = _clock.scale.lerp(Vector2.ONE, hud_pose_weight)


func _sync_banner_cloth() -> void :
	if is_instance_valid(_cloth):
		_cloth.set_shader_parameter("elapsed", banner_elapsed)
		_cloth.set_shader_parameter("side_motion", ribbon_sides)


func _sync_ribbon_text() -> void :
	if not is_instance_valid(_ribbon_text) or not is_instance_valid(_ribbon):
		return

	var pivot: Vector2 = position + RIBBON_PIVOT * scale
	var pose: Transform2D = Transform2D(_ribbon.rotation, Vector2.ZERO)
	pose.x *= _ribbon.scale.x
	pose.y *= _ribbon.scale.y
	pose.origin = pivot + (_ribbon.position - RIBBON_PIVOT) * scale - pose.basis_xform(pivot)

	_ribbon_text.transform = pose
	_ribbon_text.modulate.a = smoothstep(TITLE_REVEAL_BEGIN, TITLE_REVEAL_END, banner_elapsed) * decoration_alpha


func _reset_ribbon_text() -> void :
	if is_instance_valid(_ribbon_text):
		_ribbon_text.transform = Transform2D.IDENTITY
		_ribbon_text.modulate.a = 1.0


func _exit_tree() -> void :
	_pointer_running = false
	if is_instance_valid(_player):
		_player.clear_queue()
		_player.stop()
	_reset_ribbon_text()
