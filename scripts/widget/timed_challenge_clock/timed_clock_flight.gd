class_name TimedClockFlight
extends Control


const DURATION: float = 0.5

const CLOCK_IDLE_SPEED: float = 0.125
const SOURCE_CENTER: Vector2 = Vector2(534.0, 162.0)
const SOURCE_SIZE: Vector2 = Vector2(200.0, 236.0)
const ARC_MIN: float = 90.0
const ARC_MAX: float = 180.0

@onready var _actor: Node2D = $Actor
@onready var _visual: TimedChallengeClock = $Actor / Visual
var _target: TextureRect = null
var _saved_texture: Texture2D = null
var _saved_visible: bool = false
var _generation: int = 0
var _tween: Tween = null
var _prepared: bool = false
var _docked: bool = false
var _start: Transform2D = Transform2D.IDENTITY
var _active: Callable = Callable()


func _ready() -> void :
	_visual.position = - SOURCE_CENTER
	reset_now()


func prepare_target(target: TextureRect) -> bool:
	reset_now()
	if not is_instance_valid(target) or not target.is_inside_tree():
		return false
	_target = target
	_saved_texture = target.texture
	_saved_visible = target.visible
	_prepared = true
	_target.texture = null
	_target.show()
	return true


func dock_direct(target: TextureRect) -> void :
	if not prepare_target(target):
		return
	show()
	_actor.show()
	_visual.play_idle_at_phase(0.0, CLOCK_IDLE_SPEED)
	_visual.hud_pose_weight = 1.0
	_visual._sync_clock_pose()
	_land()


func fly_from(source: TimedChallengeClock, active: Callable) -> bool:
	if not _prepared or not is_instance_valid(_target) or not active.call():
		return false
	_generation += 1
	var generation: int = _generation
	_active = active
	show()
	_actor.show()
	_visual.play_idle_at_phase(source.idle_phase(), CLOCK_IDLE_SPEED, source.pointer_pose())

	_start = get_global_transform_with_canvas().affine_inverse()\
	* source.get_global_transform_with_canvas() * Transform2D(0.0, SOURCE_CENTER)
	_actor.transform = _start
	source.hide_clock_for_handoff()
	var tween: Tween = create_tween()
	_tween = tween
	tween.tween_method(_sample, 0.0, 1.0, DURATION).set_trans(Tween.TRANS_LINEAR)
	while generation == _generation and is_instance_valid(_target) and active.call()\
	and tween.is_valid() and tween.is_running():
		await get_tree().process_frame
	if generation != _generation:
		return false
	if not is_instance_valid(_target) or not active.call():
		reset_now()
		return false
	_sample(1.0)
	_land()
	_tween = null
	_active = Callable()
	return true



static func flight_progress(u: float) -> float:
	var t: float = clampf(u, 0.0, 1.0)
	return t * t * t * (10.0 + t * (-15.0 + 6.0 * t))


func _sample(u: float) -> void :
	if not is_instance_valid(_target):
		return
	var target_pose: Transform2D = get_global_transform_with_canvas().affine_inverse()\
	* _target.get_global_transform_with_canvas()
	var dst: Vector2 = target_pose * (_target.size * 0.5)
	var direction: Vector2 = dst - _start.origin
	var side: Vector2 = Vector2(direction.y, - direction.x).normalized()
	if side.x > 0.0:
		side = - side
	var bend: float = clampf(direction.length() * 0.18, ARC_MIN, ARC_MAX)
	var c1: Vector2 = _start.origin + direction * 0.12 + side * bend
	var c2: Vector2 = dst - direction * 0.28 + side * bend * 0.72
	var t: float = flight_progress(u)
	var inv: float = 1.0 - t
	_actor.position = _start.origin * inv * inv * inv + c1 * 3.0 * inv * inv * t\
	+ c2 * 3.0 * inv * t * t + dst * t * t * t
	var fit: float = minf(_target.size.x / SOURCE_SIZE.x, _target.size.y / SOURCE_SIZE.y)
	var dst_scale: Vector2 = Vector2(target_pose.x.length(), target_pose.y.length()) * fit
	var start_scale: Vector2 = Vector2(_start.x.length(), _start.y.length())
	var settle: float = sin(PI * clampf((u - 0.84) / 0.16, 0.0, 1.0)) * 0.025
	_actor.scale = start_scale.lerp(dst_scale, smoothstep(0.08, 1.0, u)) * (1.0 + settle)
	_actor.rotation = lerp_angle(_start.get_rotation(), target_pose.get_rotation(), t)
	_visual.hud_pose_weight = smoothstep(0.68, 1.0, u)


func _land() -> void :
	var phase: float = _visual.idle_phase()
	var pointer_pose: Vector2 = _visual.pointer_pose()
	var fit: float = minf(_target.size.x / SOURCE_SIZE.x, _target.size.y / SOURCE_SIZE.y)
	_actor.reparent(_target, true)

	_visual.play_idle_at_phase(phase, CLOCK_IDLE_SPEED, pointer_pose)
	_actor.position = _target.size * 0.5
	_actor.scale = Vector2.ONE * fit
	_actor.rotation = 0.0
	_visual.hud_pose_weight = 1.0
	_visual._sync_clock_pose()
	_docked = true


func _process(_delta: float) -> void :
	if _docked and is_instance_valid(_target) and is_instance_valid(_actor):
		var fit: float = minf(_target.size.x / SOURCE_SIZE.x, _target.size.y / SOURCE_SIZE.y)
		_actor.position = _target.size * 0.5
		_actor.scale = Vector2.ONE * fit


func is_docked() -> bool:
	return _docked and is_instance_valid(_target)


func visual() -> TimedChallengeClock:
	return _visual


func reset_now() -> void :
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_docked = false
	_active = Callable()
	if is_instance_valid(_actor):
		_actor.hide()
		if _actor.get_parent() != self and is_inside_tree():
			_actor.reparent(self, true)
		_actor.transform = Transform2D.IDENTITY
	if is_instance_valid(_visual):
		_visual.reset_now()
	if _prepared and is_instance_valid(_target):
		_target.texture = _saved_texture
		_target.visible = _saved_visible
	_prepared = false
	_target = null
	_saved_texture = null
	hide()


func _exit_tree() -> void :
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if is_instance_valid(_visual) and _visual.is_inside_tree():
		_visual.reset_now()

	if is_instance_valid(_actor) and _actor.get_parent() != self:
		_actor.queue_free()
	if _prepared and is_instance_valid(_target):
		_target.texture = _saved_texture
		_target.visible = _saved_visible
