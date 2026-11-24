class_name RankBannerGlintFx
extends Control


const _SPARKLE_START_DELAY_SEC: float = 0.18
const _SPARKLE_BEAT_SEC: Array[float] = [0.0, 0.48, 1.05, 1.7]
const _SPARKLE_ROUND_SEC: float = 2.4
const _SPARKLE_JITTER_PX: float = 6.0

var _spot_ratios: Array[Vector2] = [
	Vector2(-0.42, -0.22), 
	Vector2(-0.16, 0.26), 
	Vector2(0.14, -0.26), 
	Vector2(0.42, 0.2), 
	Vector2(-0.3, 0.24), 
	Vector2(0.32, -0.24), 
]

@onready var _rise: CPUParticles2D = $RiseMotes
@onready var _sparkles: CPUParticles2D = $Sparkles

var _token: int = 0
var _running: bool = false
var _spot_cursor: int = 0


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED:
		_sync_layout()


func start() -> void :
	_token += 1
	var token: int = _token
	_running = true
	_spot_cursor = 0
	_sync_layout()
	_rise.restart()
	_rise.emitting = true
	_run_sparkle_loop(token)


func stop() -> void :
	_token += 1
	_running = false
	if _rise != null:
		_rise.emitting = false
	if _sparkles != null:
		_sparkles.emitting = false
		_sparkles.position = _center()


func _run_sparkle_loop(token: int) -> void :
	await get_tree().create_timer(_SPARKLE_START_DELAY_SEC).timeout
	while _running and token == _token:
		var prev: float = 0.0
		for beat: float in _SPARKLE_BEAT_SEC:
			var dt: float = beat - prev
			if dt > 0.0:
				await get_tree().create_timer(dt).timeout
				if not _running or token != _token:
					return
			prev = beat
			_emit_one_sparkle()
		var tail: float = _SPARKLE_ROUND_SEC - prev
		if tail <= 0.0:
			tail = 0.1
		await get_tree().create_timer(tail).timeout


func _emit_one_sparkle() -> void :
	if _sparkles == null:
		return
	_sparkles.position = _next_spot()
	_sparkles.restart()


func _next_spot() -> Vector2:
	if _spot_ratios.is_empty():
		return _center()
	var ratio: Vector2 = _spot_ratios[_spot_cursor % _spot_ratios.size()]
	_spot_cursor += 1
	var half: Vector2 = _half()
	var jitter: = Vector2(
		randf_range( - _SPARKLE_JITTER_PX, _SPARKLE_JITTER_PX), 
		randf_range( - _SPARKLE_JITTER_PX, _SPARKLE_JITTER_PX))
	return _center() + Vector2(half.x * ratio.x, half.y * ratio.y) + jitter


func _sync_layout() -> void :
	if _rise == null:
		return
	var half: Vector2 = _half()
	var center: Vector2 = _center()
	_rise.position = Vector2(center.x, center.y + half.y * 0.92)
	_rise.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rise.emission_rect_extents = Vector2(half.x * 0.55, 10.0)
	var rise_v: float = half.y * 0.55
	_rise.initial_velocity_min = rise_v * 0.55
	_rise.initial_velocity_max = rise_v * 0.9
	if _sparkles != null:
		_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT


func _half() -> Vector2:
	var s: Vector2 = size
	if s.x <= 0.0 or s.y <= 0.0:
		s = custom_minimum_size
	if s.x <= 0.0 or s.y <= 0.0:
		s = Vector2(862.0, 472.0)
	return s * 0.5


func _center() -> Vector2:
	return _half()
