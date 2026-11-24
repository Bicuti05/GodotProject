class_name SpiralLightFx
extends Node2D













signal finished()



class Cfg extends RefCounted:

	var radius: float = 70.0
	var bottom_dy: float = 100.0
	var top_dy: float = -20.0
	var turns: float = 1.5

	var tilt: float = 0.22
	var climb_start: float = 0.1
	var climb_end: float = 0.69
	var beam_dur: float = 0.3

	var beam_wave: float = 40.0

	var ring_w: float = 230.0
	var ring_dur: float = 0.28

	var head_size: float = 70.0
	var trail_width: float = 24.0
	var dust_size: float = 17.0
	var dust_speed: float = 29.0

	var dust_start: float = 0.0

	var trail_life_climb: float = 0.24
	var trail_life_beam: float = 0.26

	var front_z: int = 1
	var fade_at_top: bool = false
	var top_fade_duration: float = 0.1



const RING_SQUASH: = 0.28

const CLIMB_PHASE: = PI * 0.5
const HEAD_FADE_DUR: = 0.08
const HEAD_BEAM_SCALE: = 1.15
const HEAD_CORE_RATIO: = 0.38

const TRAIL_GLOW_RATIO: = 2.2
const TRAIL_GLOW_ALPHA: = 0.3
const TRAIL_CORE_RATIO: = 0.4
const TRAIL_MIN_SAMPLE_DIST: = 2.0

const BACK_ALPHA: = 0.45

const DEPTH_SCALE_MIN: = 0.7

const DUST_RATE: = 45.0
const DUST_LIFETIME: = 0.7
const DUST_EMIT_MIN_DEPTH: = -0.3
const GOLD: = Color(1.0, 0.82, 0.32)
const CORE: = Color(1.0, 0.97, 0.85)


const POT_RADIUS_RATIO: = 0.3
const POT_BOTTOM_V: = 0.4
const POT_TOP_V: = -0.08
const POT_BEAM_WAVE_RATIO: = 0.18
const POT_RING_WIDTH_RATIO: = 0.95
const POT_HEAD_SIZE_RATIO: = 0.3
const POT_TRAIL_WIDTH_RATIO: = 0.1
const POT_DUST_SIZE_RATIO: = 0.07
const POT_DUST_SPEED_RATIO: = 0.12

const POT_CLIMB_END: = 0.65
const POT_DUST_START: = 0.4


const ROPE_RADIUS_RATIO: = 0.42
const ROPE_BOTTOM_PAD_RATIO: = 0.3
const ROPE_TOP_PAD_RATIO: = 0.15
const ROPE_TURNS: = 2.0
const ROPE_CLIMB_START: = 0.08
const ROPE_CLIMB_END: = 0.7
const ROPE_BEAM_DUR: = 0.22
const ROPE_BEAM_WAVE_RATIO: = 0.25
const ROPE_RING_WIDTH_RATIO: = 1.1
const ROPE_HEAD_SIZE_RATIO: = 0.36
const ROPE_TRAIL_WIDTH_RATIO: = 0.1
const ROPE_DUST_SIZE_RATIO: = 0.08
const ROPE_DUST_SPEED_RATIO: = 0.15
const ROPE_TRAIL_LIFE_CLIMB: = 0.22
const ROPE_TRAIL_LIFE_BEAM: = 0.18


@export var head_texture: Texture2D
@export var dust_texture: Texture2D

@onready var _back: Node2D = $Back
@onready var _front: Node2D = $Front
@onready var _dusts: Array[CPUParticles2D] = [$Front / Dust0, $Front / Dust1]




class _Head extends RefCounted:
	var phase: float = 0.0
	var side: float = 1.0
	var beam_from: Vector2 = Vector2.ZERO
	var pos: Vector2 = Vector2.ZERO
	var offset: Vector2 = Vector2.ZERO
	var attached: bool = true
	var depth: float = 0.0
	var alpha: float = 0.0
	var offs: PackedVector2Array = PackedVector2Array()
	var attach: PackedByteArray = PackedByteArray()
	var depths: PackedFloat32Array = PackedFloat32Array()
	var born: PackedFloat32Array = PackedFloat32Array()

	func clear() -> void :
		offs.clear()
		attach.clear()
		depths.clear()
		born.clear()
		alpha = 0.0


var _heads: Array[_Head] = []
var _running: bool = false
var _t: float = 0.0
var _center: Vector2 = Vector2.ZERO
var _cfg: Cfg = Cfg.new()
var _dst_provider: Callable = Callable()
var _beam_captured: bool = false



static func pot_cfg(size: Vector2) -> Cfg:
	var c: = Cfg.new()
	c.radius = size.x * POT_RADIUS_RATIO
	c.bottom_dy = size.y * POT_BOTTOM_V
	c.top_dy = size.y * POT_TOP_V
	c.turns = 1.5
	c.climb_start = 0.1
	c.climb_end = POT_CLIMB_END
	c.beam_dur = 0.3
	c.beam_wave = size.x * POT_BEAM_WAVE_RATIO
	c.ring_w = size.x * POT_RING_WIDTH_RATIO
	c.ring_dur = 0.28
	c.head_size = size.x * POT_HEAD_SIZE_RATIO
	c.trail_width = size.x * POT_TRAIL_WIDTH_RATIO
	c.dust_size = size.x * POT_DUST_SIZE_RATIO
	c.dust_speed = size.x * POT_DUST_SPEED_RATIO
	c.dust_start = POT_DUST_START
	c.trail_life_climb = 0.24
	c.trail_life_beam = 0.26
	c.front_z = 1
	return c




static func rope_cfg(top_y: float, bottom_y: float, fruit_d: float, front_z: int) -> Cfg:
	var c: = Cfg.new()
	var mid: float = (top_y + bottom_y) * 0.5
	c.radius = fruit_d * ROPE_RADIUS_RATIO
	c.bottom_dy = bottom_y + fruit_d * ROPE_BOTTOM_PAD_RATIO - mid
	c.top_dy = top_y - fruit_d * ROPE_TOP_PAD_RATIO - mid
	c.turns = ROPE_TURNS
	c.climb_start = ROPE_CLIMB_START
	c.climb_end = ROPE_CLIMB_END
	c.beam_dur = ROPE_BEAM_DUR
	c.beam_wave = fruit_d * ROPE_BEAM_WAVE_RATIO
	c.ring_w = fruit_d * ROPE_RING_WIDTH_RATIO
	c.ring_dur = 0.3
	c.head_size = fruit_d * ROPE_HEAD_SIZE_RATIO
	c.trail_width = fruit_d * ROPE_TRAIL_WIDTH_RATIO
	c.dust_size = fruit_d * ROPE_DUST_SIZE_RATIO
	c.dust_speed = fruit_d * ROPE_DUST_SPEED_RATIO
	c.dust_start = 0.0
	c.trail_life_climb = ROPE_TRAIL_LIFE_CLIMB
	c.trail_life_beam = ROPE_TRAIL_LIFE_BEAM
	c.front_z = front_z
	return c


func _ready() -> void :
	for i in 2:
		var h: = _Head.new()
		h.phase = CLIMB_PHASE + PI * float(i)
		h.side = 1.0 if i == 0 else -1.0
		_heads.append(h)
	_back.draw.connect(_draw_layer.bind(_back, false))
	_front.draw.connect(_draw_layer.bind(_front, true))
	set_process(false)
	visible = false





func start(center: Vector2, cfg: Cfg, dst_provider: Callable) -> void :
	modulate.a = 1.0
	_center = center
	_cfg = cfg
	_dst_provider = dst_provider
	_t = 0.0
	_beam_captured = false
	_front.z_index = cfg.front_z
	for h: _Head in _heads:
		h.clear()
	var tex_w: float = 1.0
	if dust_texture != null:
		tex_w = maxf(1.0, float(dust_texture.get_width()))
	var dust_scale: float = cfg.dust_size / tex_w
	for p: CPUParticles2D in _dusts:
		p.amount = maxi(1, roundi(DUST_RATE * DUST_LIFETIME))
		p.lifetime = DUST_LIFETIME
		p.scale_amount_min = dust_scale * 0.7
		p.scale_amount_max = dust_scale * 1.3
		p.initial_velocity_min = cfg.dust_speed * 0.3
		p.initial_velocity_max = cfg.dust_speed
		p.emitting = false
		p.restart()
		p.emitting = false
	visible = true
	_running = true
	set_process(true)
	_advance(0.0)



func follow(center: Vector2) -> void :
	_center = center



func stop() -> void :
	_running = false
	set_process(false)
	visible = false
	for h: _Head in _heads:
		h.clear()
	for p: CPUParticles2D in _dusts:
		p.emitting = false
		p.restart()
		p.emitting = false
	_back.queue_redraw()
	_front.queue_redraw()


func is_running() -> bool:
	return _running




func climb_progress() -> float:
	if not _running or _t < _cfg.climb_start:
		return 0.0
	if _t >= _cfg.climb_end:
		return 1.0
	return _eased_climb()



func climb_y() -> float:
	return _center.y + lerpf(_cfg.bottom_dy, _cfg.top_dy, climb_progress())




static func time_at_climb(cfg: Cfg, e: float) -> float:
	var p: float = acos(clampf(1.0 - 2.0 * e, -1.0, 1.0)) / PI
	return cfg.climb_start + p * (cfg.climb_end - cfg.climb_start)




static func ride_offset(cfg: Cfg, e: float, phase: float) -> Vector3:
	var theta: float = phase + TAU * cfg.turns * e
	var y: float = lerpf(cfg.bottom_dy, cfg.top_dy, e)
	return Vector3(cfg.radius * sin(theta), y + cfg.radius * cfg.tilt * cos(theta), cos(theta))



func total_duration() -> float:
	if _cfg.fade_at_top:
		return _cfg.climb_end + _cfg.top_fade_duration
	return _cfg.climb_end + _cfg.beam_dur + HEAD_FADE_DUR + DUST_LIFETIME


func _process(delta: float) -> void :
	_advance(delta)


func _advance(delta: float) -> void :
	if not _running:
		return
	_t += delta
	if _t >= total_duration():
		stop()
		finished.emit()
		return
	if _cfg.fade_at_top:
		modulate.a = 1.0 - clampf((_t - _cfg.climb_end) / _cfg.top_fade_duration, 0.0, 1.0)
	var life: float = _cfg.trail_life_beam if _t >= _cfg.climb_end else _cfg.trail_life_climb
	for i in _heads.size():
		var h: _Head = _heads[i]
		_update_head(h)
		_sample(h)
		_prune(h, life)
		var dust: CPUParticles2D = _dusts[i]
		dust.global_position = to_global(h.pos)
		dust.emitting = not _cfg.fade_at_top and h.alpha > 0.0 and h.depth >= DUST_EMIT_MIN_DEPTH\
		and _t >= _cfg.dust_start and _t < _cfg.climb_end + _cfg.beam_dur
	_back.queue_redraw()
	_front.queue_redraw()


func _eased_climb() -> float:
	var p: float = (_t - _cfg.climb_start) / (_cfg.climb_end - _cfg.climb_start)
	return 0.5 - 0.5 * cos(PI * clampf(p, 0.0, 1.0))


func _update_head(h: _Head) -> void :
	if _t < _cfg.climb_start:
		h.alpha = 0.0
		h.attached = true
		h.offset = _climb_offset(h, 0.0)
		h.pos = _center + h.offset
		h.depth = cos(h.phase)
		return
	if _t < _cfg.climb_end or _cfg.fade_at_top:
		var p: float = (_t - _cfg.climb_start) / (_cfg.climb_end - _cfg.climb_start)
		var eased: float = _eased_climb()
		h.offset = _climb_offset(h, eased)
		h.pos = _center + h.offset
		h.depth = cos(h.phase + TAU * _cfg.turns * eased)
		h.attached = true
		h.alpha = clampf(p / 0.15, 0.0, 1.0)
		return
	if not _beam_captured:
		_beam_captured = true
		for each: _Head in _heads:
			each.beam_from = _center + _climb_offset(each, 1.0)
	var dst: Vector2 = h.beam_from
	if _dst_provider.is_valid():
		dst = _dst_provider.call()
	var u: float = clampf((_t - _cfg.climb_end) / _cfg.beam_dur, 0.0, 1.0)
	var e: float = u * u
	var dir: Vector2 = dst - h.beam_from
	var perp: Vector2 = dir.orthogonal().normalized() if dir.length() > 0.01 else Vector2.RIGHT
	h.pos = h.beam_from.lerp(dst, e) + perp * h.side * _cfg.beam_wave * sin(PI * e)
	h.attached = false
	h.depth = 1.0
	var after: float = _t - _cfg.climb_end - _cfg.beam_dur
	h.alpha = 1.0 if after <= 0.0 else clampf(1.0 - after / HEAD_FADE_DUR, 0.0, 1.0)



func _climb_offset(h: _Head, eased: float) -> Vector2:
	var theta: float = h.phase + TAU * _cfg.turns * eased
	var r: float = _cfg.radius
	var y: float = lerpf(_cfg.bottom_dy, _cfg.top_dy, eased)
	return Vector2(r * sin(theta), y + r * _cfg.tilt * cos(theta))


func _sample(h: _Head) -> void :
	if h.alpha <= 0.0 or _t >= _cfg.climb_end + _cfg.beam_dur:
		return
	var stored: Vector2 = h.offset if h.attached else h.pos
	var n: int = h.offs.size()
	if n > 0 and bool(h.attach[n - 1]) == h.attached\
	and h.offs[n - 1].distance_to(stored) < TRAIL_MIN_SAMPLE_DIST:
		return
	h.offs.append(stored)
	h.attach.append(1 if h.attached else 0)
	h.depths.append(h.depth)
	h.born.append(_t)


func _prune(h: _Head, life: float) -> void :
	var drop: int = 0
	while drop < h.born.size() and _t - h.born[drop] > life:
		drop += 1
	if drop == 0:
		return
	h.offs = h.offs.slice(drop)
	h.attach = h.attach.slice(drop)
	h.depths = h.depths.slice(drop)
	h.born = h.born.slice(drop)


func _sample_pos(h: _Head, i: int) -> Vector2:
	return _center + h.offs[i] if bool(h.attach[i]) else h.offs[i]


func _draw_layer(canvas: Node2D, front: bool) -> void :
	if not _running:
		return
	var life: float = _cfg.trail_life_beam if _t >= _cfg.climb_end else _cfg.trail_life_climb
	if front:
		_draw_ring(canvas)
	for h: _Head in _heads:
		_draw_trail(canvas, h, front, life, _cfg.trail_width * TRAIL_GLOW_RATIO, GOLD, TRAIL_GLOW_ALPHA)
		_draw_trail(canvas, h, front, life, _cfg.trail_width, GOLD, 1.0)
		_draw_trail(canvas, h, front, life, _cfg.trail_width * TRAIL_CORE_RATIO, CORE, 1.0)
		if h.alpha > 0.0 and (h.depth >= 0.0) == front:
			_draw_head(canvas, h)


func _draw_ring(canvas: Node2D) -> void :
	if head_texture == null or _t >= _cfg.ring_dur:
		return
	var k: float = _t / _cfg.ring_dur
	var w: float = _cfg.ring_w * lerpf(0.6, 1.2, k)
	var sz: = Vector2(w, w * RING_SQUASH)
	var c: Vector2 = _center + Vector2(0.0, _cfg.bottom_dy)
	var col: Color = GOLD
	col.a = 1.0 - k
	canvas.draw_texture_rect(head_texture, Rect2(c - sz * 0.5, sz), false, col)


func _draw_head(canvas: Node2D, h: _Head) -> void :
	if head_texture == null:
		return
	var depth_k: float = (h.depth + 1.0) * 0.5
	var s: float = _cfg.head_size * lerpf(DEPTH_SCALE_MIN, 1.0, depth_k)
	if not h.attached:
		s *= HEAD_BEAM_SCALE
	var a: float = h.alpha * (1.0 if h.depth >= 0.0 else BACK_ALPHA)
	var glow: Color = GOLD
	glow.a = a
	canvas.draw_texture_rect(head_texture, Rect2(h.pos - Vector2(s, s) * 0.5, Vector2(s, s)), false, glow)
	var cs: float = s * HEAD_CORE_RATIO
	var core: Color = CORE
	core.a = a
	canvas.draw_texture_rect(head_texture, Rect2(h.pos - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), false, core)




func _draw_trail(canvas: Node2D, h: _Head, front: bool, life: float, head_w: float, 
		rgb: Color, alpha: float) -> void :
	var n: int = h.offs.size()
	if n == 0:
		return
	var pts: = PackedVector2Array()
	var ks: = PackedFloat32Array()
	var ds: = PackedFloat32Array()
	for i in n:
		pts.append(_sample_pos(h, i))
		ks.append(clampf(1.0 - (_t - h.born[i]) / life, 0.0, 1.0))
		ds.append(h.depths[i])
	if h.alpha > 0.0 and _t < _cfg.climb_end + _cfg.beam_dur:
		pts.append(h.pos)
		ks.append(1.0)
		ds.append(h.depth)
	var m: int = pts.size()
	if m < 2:
		return
	var normals: = PackedVector2Array()
	normals.resize(m)
	for i in m:
		var a: Vector2 = pts[maxi(i - 1, 0)]
		var b: Vector2 = pts[mini(i + 1, m - 1)]
		var d: Vector2 = b - a
		normals[i] = d.orthogonal().normalized() if d.length() > 0.001 else Vector2.UP
	for i in m - 1:
		var seg_front: bool = (ds[i] + ds[i + 1]) * 0.5 >= 0.0
		if seg_front != front:
			continue
		var layer_a: float = alpha * (1.0 if front else BACK_ALPHA)
		var w0: float = head_w * ks[i] * 0.5
		var w1: float = head_w * ks[i + 1] * 0.5
		var c0: Color = rgb
		c0.a = ks[i] * layer_a
		var c1: Color = rgb
		c1.a = ks[i + 1] * layer_a


		var quad: = PackedVector2Array([
			pts[i] + normals[i] * w0, pts[i + 1] + normals[i + 1] * w1, 
			pts[i + 1] - normals[i + 1] * w1, pts[i] - normals[i] * w0])
		canvas.draw_primitive(quad, PackedColorArray([c0, c1, c1, c0]), PackedVector2Array())
