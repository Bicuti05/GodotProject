class_name RankBadgeView
extends Control


const TIER_MIN: int = 1
const TIER_MAX: int = 7

const _SHINE_SHADER: Shader = preload("res://assets/effect/shader/image_shine.gdshader")
const _SHINE_DURATION_SEC: float = 1.4
const _SHINE_PROGRESS_FROM: float = 0.0
const _SHINE_PROGRESS_TO: float = 1.0
const _SHINE_LOOP_INTERVAL_SEC: float = 5.5
const _SHINE_BAND_WIDTH: float = 0.18
const _SHINE_INTENSITY: float = 0.4
const _SHINE_ANGLE: float = -0.25
const _SHINE_TINT: Color = Color(1.0, 0.96, 0.86, 1.0)

const _SPARKLE_START_DELAY_SEC: float = 0.18
const _SPARKLE_BEAT_SEC: Array[float] = [0.0, 0.48, 1.05, 1.7]
var _sparkle_spot_ratios: Array[Vector2] = [
	Vector2(-0.32, -0.3), 
	Vector2(0.34, -0.22), 
	Vector2(-0.28, 0.3), 
	Vector2(0.3, 0.26), 
]

@export var badges: Array[Texture2D] = []
@export var badges_dark: Array[Texture2D] = []

@onready var _float_host: Node2D = $FloatHost
@onready var _shadow: Sprite2D = $Shadow
@onready var _rise_motes: CPUParticles2D = $FloatHost / RiseMotes
@onready var _img: Sprite2D = $FloatHost / Badge
@onready var _sparkles: CPUParticles2D = $FloatHost / Sparkles

var _tier: int = TIER_MIN
var _dark: bool = false
var _badge_tint: Color = Color.WHITE
var _ground_contact_offset_ratio: float = 0.0

var _shine_mat: ShaderMaterial = null
var _shine_tween: Tween = null
var _shine_loop_tween: Tween = null
var _shine_loop_active: bool = false
var _sparkle_gen: int = 0
var _rise_motes_stop_msec: int = -1


func _ready() -> void :
	_sync_badge_layout()
	_refresh()
	_apply_badge_tint()


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED:
		_sync_badge_layout()


func set_tier(tier: int, dark: bool = false) -> void :
	_tier = clampi(tier, TIER_MIN, TIER_MAX)
	_dark = dark
	_refresh()


func get_tier() -> int:
	return _tier


func set_ground_contact_offset_ratio(offset_ratio: float) -> void :
	_ground_contact_offset_ratio = offset_ratio
	_sync_badge_layout()


func get_warmup_shader_key() -> String:
	var shader: Shader = _SHINE_SHADER
	return shader.get_code().sha256_text()


func set_badge_tint(tint: Color) -> void :
	_badge_tint = tint
	_apply_badge_tint()


func _apply_badge_tint() -> void :
	if _img != null:
		_img.modulate = _badge_tint


func start_idle_fx(with_highlights: bool = true) -> void :
	if not with_highlights:
		_kill_shine_loop()
		stop_shine()
		_stop_sparkles(true)
		_stop_rise_motes(true)
		return
	_start_rise_motes()
	_start_shine_loop()


func play_shine(duration_sec: float = _SHINE_DURATION_SEC) -> void :
	if _img == null:
		return
	_stop_sparkles()
	_kill_shine_tween()
	var mat: ShaderMaterial = _ensure_shine_mat()
	_img.material = mat
	mat.set_shader_parameter("progress", _SHINE_PROGRESS_FROM)
	_shine_tween = create_tween()
	_shine_tween.tween_method(_set_shine_progress, _SHINE_PROGRESS_FROM, _SHINE_PROGRESS_TO, 
		maxf(duration_sec, 0.01))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shine_tween.tween_callback(_finish_shine)


func stop_shine() -> void :
	_kill_shine_tween()
	_finish_shine()


func reset_motion(clear_residual: bool = false) -> void :
	_kill_shine_loop()
	stop_shine()
	_stop_sparkles(clear_residual)
	_stop_rise_motes(clear_residual)


func _start_rise_motes() -> void :
	if _rise_motes == null:
		return
	_sync_rise_motes_layout()
	if _rise_motes.emitting or _has_live_rise_motes():
		_rise_motes.emitting = true
		return
	_rise_motes.restart()
	_rise_motes.emitting = true


func _has_live_rise_motes() -> bool:
	if _rise_motes == null or _rise_motes_stop_msec < 0:
		return false
	return Time.get_ticks_msec() - _rise_motes_stop_msec < int(_rise_motes.lifetime * 1000.0)


func _stop_rise_motes(clear_residual: bool = false) -> void :
	if _rise_motes == null:
		return
	_rise_motes.emitting = false
	if clear_residual:
		_clear_particles(_rise_motes)
		_rise_motes_stop_msec = -1
	else:
		_rise_motes_stop_msec = Time.get_ticks_msec()


func _sync_rise_motes_layout() -> void :
	if _rise_motes == null:
		return
	var half: Vector2 = size * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		half = custom_minimum_size * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		half = Vector2(100.0, 100.0)
	_rise_motes.position = Vector2(0.0, half.y * 0.92)
	_rise_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rise_motes.emission_rect_extents = Vector2(half.x * 0.55, 10.0)
	var rise_v: float = half.y * 0.55
	_rise_motes.initial_velocity_min = rise_v * 0.55
	_rise_motes.initial_velocity_max = rise_v * 0.9


func _refresh() -> void :
	if _img == null:
		return
	var pool: Array[Texture2D] = badges_dark if _dark else badges
	if pool.is_empty():
		return
	_img.texture = pool[clampi(_tier - 1, 0, pool.size() - 1)]
	_sync_badge_layout()


func _start_shine_loop() -> void :
	_kill_shine_loop()
	_shine_loop_active = true
	play_shine()
	_shine_loop_tween = create_tween().set_loops()
	_shine_loop_tween.tween_interval(maxf(_SHINE_LOOP_INTERVAL_SEC, _SHINE_DURATION_SEC + 0.1))
	_shine_loop_tween.tween_callback(play_shine)


func _kill_shine_loop() -> void :
	_shine_loop_active = false
	if _shine_loop_tween != null and _shine_loop_tween.is_valid():
		_shine_loop_tween.kill()
	_shine_loop_tween = null


func _ensure_shine_mat() -> ShaderMaterial:
	if _shine_mat == null:
		_shine_mat = ShaderMaterial.new()
		_shine_mat.shader = _SHINE_SHADER
	_shine_mat.set_shader_parameter("band_width", _SHINE_BAND_WIDTH)
	_shine_mat.set_shader_parameter("intensity", _SHINE_INTENSITY)
	_shine_mat.set_shader_parameter("angle", _SHINE_ANGLE)
	_shine_mat.set_shader_parameter("tint_color", _SHINE_TINT)
	return _shine_mat


func _set_shine_progress(value: float) -> void :
	if _shine_mat != null:
		_shine_mat.set_shader_parameter("progress", value)


func _finish_shine() -> void :
	if _shine_mat != null:
		_shine_mat.set_shader_parameter("progress", _SHINE_PROGRESS_TO)
	if _img != null:
		_img.material = null
	_shine_tween = null
	if _shine_loop_active:
		_start_sparkle_twinkles()


func _start_sparkle_twinkles() -> void :
	_sparkle_gen += 1
	var gen: int = _sparkle_gen
	if not is_inside_tree():
		return
	for i: int in range(_SPARKLE_BEAT_SEC.size()):
		var delay_sec: float = _SPARKLE_START_DELAY_SEC + _SPARKLE_BEAT_SEC[i]
		var spot_i: int = i
		get_tree().create_timer(delay_sec).timeout.connect(
			func() -> void :
				if gen != _sparkle_gen or not _shine_loop_active:
					return
				_emit_one_sparkle_at(_sparkle_spot(spot_i)), 
			CONNECT_ONE_SHOT)


func _sparkle_spot(index: int) -> Vector2:
	if _sparkle_spot_ratios.is_empty():
		return Vector2.ZERO
	var ratio: Vector2 = _sparkle_spot_ratios[index % _sparkle_spot_ratios.size()]
	var half: Vector2 = size * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		half = custom_minimum_size * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		half = Vector2(100.0, 100.0)
	var jitter: Vector2 = Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
	return Vector2(half.x * ratio.x, half.y * ratio.y) + jitter


func _emit_one_sparkle_at(local_pos: Vector2) -> void :
	if _sparkles == null:
		return
	_sparkles.position = local_pos
	_sparkles.restart()


func _stop_sparkles(clear_residual: bool = false) -> void :
	_sparkle_gen += 1
	if _sparkles == null:
		return
	_sparkles.emitting = false
	if clear_residual:
		_clear_particles(_sparkles)
	_sparkles.position = Vector2.ZERO


func _clear_particles(p: CPUParticles2D) -> void :
	p.amount = p.amount


func _sync_badge_layout() -> void :
	if _img == null or _float_host == null:
		return
	var s: Vector2 = size
	if s.x <= 0.0 or s.y <= 0.0:
		s = custom_minimum_size
	if s.x <= 0.0 or s.y <= 0.0:
		s = Vector2(200.0, 200.0)
	var tex: Texture2D = _img.texture
	if tex != null:
		var ts: Vector2 = tex.get_size()
		if ts.x > 0.0 and ts.y > 0.0:
			var sc: float = minf(s.x / ts.x, s.y / ts.y)
			_img.scale = Vector2(sc, sc)
			_shadow.scale = Vector2(sc, sc)

			_shadow.position = s * 0.5 + Vector2(0.0, 
				(ts.y * 0.5 - _shadow.texture.get_height() * 0.25) * sc)
	_float_host.position = s * 0.5 + Vector2(0.0, s.y * _ground_contact_offset_ratio)
	_sync_rise_motes_layout()
	if _sparkles != null:
		_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT


func _kill_shine_tween() -> void :
	if _shine_tween != null and _shine_tween.is_valid():
		_shine_tween.kill()
	_shine_tween = null
