class_name SplashAmbientLight
extends Node2D















@export var beam_texture: Texture2D = null

@export var spot_texture: Texture2D = null
@export var beam_alpha_multiplier: float = 1.0




const _BEAMS: Array[Dictionary] = [
	{"uv": Vector2(0.03, 0.16), "sx": 1.2, "sy": 1.1, "phase": 1.1}, 
	{"uv": Vector2(0.1, 0.1), "sx": 1.5, "sy": 1.25, "phase": 0.0}, 
	{"uv": Vector2(0.24, 0.05), "sx": 1.0, "sy": 1.05, "phase": 2.1}, 
	{"uv": Vector2(0.31, 0.02), "sx": 0.8, "sy": 0.95, "phase": 3.2}, 
	{"uv": Vector2(0.38, 0.12), "sx": 1.8, "sy": 1.4, "phase": 4.0}, 
	{"uv": Vector2(0.47, 0.08), "sx": 1.35, "sy": 1.2, "phase": 5.3}, 
]


const _BEAM_TILT: float = - PI / 4.0

const _BEAM_A_MIN: float = 0.07
const _BEAM_A_MAX: float = 0.182
const _BEAM_CYCLE: float = 3.2


const _SPOT_COUNT: int = 6


const _SPOT_LEFT_RATIO: float = 0.5
const _SPOT_TOP_X: Vector2 = Vector2(-0.05, 0.38)
const _SPOT_TOP_Y: float = -0.04
const _SPOT_LEFT_X: float = -0.04
const _SPOT_LEFT_Y: Vector2 = Vector2(-0.04, 0.55)

const _SPOT_SPEED_MIN: float = 25.0
const _SPOT_SPEED_MAX: float = 55.0
const _SPOT_SWAY_PX: float = 12.0
const _SPOT_SWAY_CYCLE_MIN: float = 2.4
const _SPOT_SWAY_CYCLE_MAX: float = 5.0

const _SPOT_SIZE_MIN: float = 18.0
const _SPOT_SIZE_MAX: float = 46.0

const _SPOT_A_PEAK: float = 0.063


const _SPOT_A_RAND: float = 0.4

const _SPOT_LIFE_MIN: float = 8.0
const _SPOT_LIFE_MAX: float = 15.0


const _SPOT_LIFE_RAND: float = 0.3

var _t: float = 0.0
var _spots: Array[Dictionary] = []


func _ready() -> void :
	_reset_spots()
	set_process(true)




func _vp() -> Vector2:
	return UiMetrics.viewport_size()


func _reset_spots() -> void :
	_spots.clear()
	for i in _SPOT_COUNT:
		var m: Dictionary = _new_spot()

		m.age = randf() * m.life
		_spots.append(m)


func _new_spot() -> Dictionary:
	var vp: Vector2 = _vp()
	var pos: Vector2
	if randf() < _SPOT_LEFT_RATIO:
		pos = Vector2(_SPOT_LEFT_X * vp.x, 
			randf_range(_SPOT_LEFT_Y.x, _SPOT_LEFT_Y.y) * vp.y)
	else:
		pos = Vector2(randf_range(_SPOT_TOP_X.x, _SPOT_TOP_X.y) * vp.x, 
			_SPOT_TOP_Y * vp.y)
	return {
		"pos": pos, 
		"speed": randf_range(_SPOT_SPEED_MIN, _SPOT_SPEED_MAX), 
		"size": randf_range(_SPOT_SIZE_MIN, _SPOT_SIZE_MAX), 
		"life": randf_range(_SPOT_LIFE_MIN, _SPOT_LIFE_MAX)
			* randf_range(1.0 - _SPOT_LIFE_RAND, 1.0 + _SPOT_LIFE_RAND), 
		"age": 0.0, 
		"sway_cycle": randf_range(_SPOT_SWAY_CYCLE_MIN, _SPOT_SWAY_CYCLE_MAX), 
		"sway_phase": randf() * TAU, 
		"a_peak": _SPOT_A_PEAK * randf_range(1.0 - _SPOT_A_RAND, 1.0 + _SPOT_A_RAND), 
	}


func _process(delta: float) -> void :


	if not is_visible_in_tree():
		return
	_t += delta
	for i in _spots.size():
		var m: Dictionary = _spots[i]
		m.age += delta
		if m.age >= m.life:


			_spots[i] = _new_spot()
			continue

		m.pos += Vector2( - sin(_BEAM_TILT), cos(_BEAM_TILT)) * m.speed * delta
		_spots[i] = m
	queue_redraw()


func _draw() -> void :
	var vp: Vector2 = _vp()
	_draw_beams(vp)
	_draw_spots()


func _draw_beams(vp: Vector2) -> void :
	if beam_texture == null:
		return
	var tex_size: Vector2 = beam_texture.get_size()
	var src: = Rect2(Vector2.ZERO, tex_size)
	for b: Dictionary in _BEAMS:

		var k: float = 0.5 + 0.5 * sin(TAU * (_t / _BEAM_CYCLE) + float(b.phase))
		var a: float = lerpf(_BEAM_A_MIN, _BEAM_A_MAX, k) * beam_alpha_multiplier
		var center: Vector2 = Vector2(vp.x * float(b.uv.x), vp.y * float(b.uv.y))
		draw_set_transform(center, _BEAM_TILT, Vector2(float(b.sx), float(b.sy)))
		draw_texture_rect_region(beam_texture, 
			Rect2( - tex_size * 0.5, tex_size), src, Color(1.0, 1.0, 1.0, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_spots() -> void :
	if spot_texture == null:
		return
	var tex_size: Vector2 = spot_texture.get_size()
	var src: = Rect2(Vector2.ZERO, tex_size)
	for m: Dictionary in _spots:
		var tau_n: float = clampf(float(m.age) / maxf(0.001, float(m.life)), 0.0, 1.0)

		var a: float = float(m.a_peak) * sin(PI * tau_n)
		if a <= 0.004:
			continue
		var sway: float = sin(TAU * (_t / float(m.sway_cycle)) + float(m.sway_phase)) * _SPOT_SWAY_PX
		var p: Vector2 = Vector2(float(m.pos.x) + sway, float(m.pos.y))
		var s: float = float(m.size) / maxf(1.0, tex_size.x)
		draw_set_transform(p, 0.0, Vector2(s, s))
		draw_texture_rect_region(spot_texture, 
			Rect2( - tex_size * 0.5, tex_size), src, Color(1.0, 1.0, 1.0, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
