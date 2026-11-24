class_name SplashAmbientFoliage
extends Node2D













@export var leaf_atlas: Texture2D = null
@export var petal_atlas: Texture2D = null
@export var flower_atlas: Texture2D = null


@export var use_parent_size: bool = false



const _FLOWER_SIZE_MIN: float = 52.0
const _FLOWER_SIZE_MAX: float = 78.0
const _SMALL_DIV: float = 3.0


const _LEAF_MUL: float = 1.4





const _KINDS: Array[Dictionary] = [
	{"key": "leaf", "grid": 2, "count": 2, 
		"size_min": _FLOWER_SIZE_MIN / _SMALL_DIV * _LEAF_MUL, 
		"size_max": _FLOWER_SIZE_MAX / _SMALL_DIV * _LEAF_MUL, 
		"spin": 1.5}, 
	{"key": "petal", "grid": 3, "count": 2, 
		"size_min": _FLOWER_SIZE_MIN / _SMALL_DIV, "size_max": _FLOWER_SIZE_MAX / _SMALL_DIV, 
		"spin": 2.2}, 
	{"key": "flower", "grid": 2, "count": 1, 
		"size_min": _FLOWER_SIZE_MIN, "size_max": _FLOWER_SIZE_MAX, "spin": 0.9, 
		"speed_mul": 0.7}, 
]


const _VX_MIN: float = 190.0
const _VX_MAX: float = 360.0
const _VY_MIN: float = 60.0
const _VY_MAX: float = 120.0

const _SWAY_PX_MIN: float = 10.0
const _SWAY_PX_MAX: float = 34.0
const _SWAY_CYCLE_MIN: float = 1.6
const _SWAY_CYCLE_MAX: float = 3.6

const _SPAWN_X: Vector2 = Vector2(-0.25, 0.45)


const _SPAWN_LEFT_RATIO: float = 0.45
const _SPAWN_LEFT_X: float = -0.08
const _SPAWN_Y_BELOW: float = 0.06


const _RISE_MAX_PX: float = 800.0

const _OUT_MARGIN: float = 0.12






const _GROW_PEAK: float = 1.5
const _GROW_RAND: float = 0.5


const _FADE_IN: float = 0.12
const _FADE_OUT: float = 0.22

const _A_PEAK: float = 0.92

var _t: float = 0.0
var _items: Array[Dictionary] = []


func _ready() -> void :
	_reset()
	set_process(true)




func _vp() -> Vector2:
	if use_parent_size:
		var area: Control = get_parent() as Control
		if area != null:
			return Vector2(maxf(area.size.x, 1.0), maxf(area.size.y, 1.0))
	return UiMetrics.viewport_size()


func _atlas_of(key: String) -> Texture2D:
	match key:
		"leaf": return leaf_atlas
		"petal": return petal_atlas
		_: return flower_atlas


func _reset() -> void :
	_items.clear()
	for kind: Dictionary in _KINDS:
		for i in int(kind.count):
			var it: Dictionary = _spawn(kind)


			var t: float = randf()
			it.pos.y -= t * float(it.travel_px)
			it.pos.x += t * float(it.travel_x_px)
			_items.append(it)


func _spawn(kind: Dictionary) -> Dictionary:
	var vp: Vector2 = _vp()
	var g: int = int(kind.grid)

	var y_cap: float = vp.y - _RISE_MAX_PX
	var x0: float
	var y0: float
	if randf() < _SPAWN_LEFT_RATIO:
		x0 = _SPAWN_LEFT_X * vp.x

		y0 = randf_range(y_cap + 40.0, vp.y * (1.0 + _SPAWN_Y_BELOW))
	else:
		x0 = randf_range(_SPAWN_X.x, _SPAWN_X.y) * vp.x
		y0 = vp.y * (1.0 + _SPAWN_Y_BELOW)
	return {
		"kind": kind, 
		"pos": Vector2(x0, y0), 
		"vel": Vector2(randf_range(_VX_MIN, _VX_MAX), - randf_range(_VY_MIN, _VY_MAX))
			* float(kind.get("speed_mul", 1.0)), 
		"size": randf_range(float(kind.size_min), float(kind.size_max)), 
		"rot": randf() * TAU, 
		"spin": randf_range( - float(kind.spin), float(kind.spin)), 
		"cell": Vector2i(randi() % g, randi() % g), 
		"sway_px": randf_range(_SWAY_PX_MIN, _SWAY_PX_MAX), 
		"sway_cycle": randf_range(_SWAY_CYCLE_MIN, _SWAY_CYCLE_MAX), 
		"sway_phase": randf() * TAU, 
		"grow_peak": maxf(1.0, _GROW_PEAK * randf_range(1.0 - _GROW_RAND, 1.0 + _GROW_RAND)), 
		"y0": y0, 


		"travel_px": maxf(1.0, y0 - y_cap), 


		"x0": x0, 
		"travel_x_px": maxf(1.0, (1.0 + _OUT_MARGIN) * vp.x - x0), 
	}


func _process(delta: float) -> void :


	if not is_visible_in_tree():
		return
	_t += delta
	for i in _items.size():
		var it: Dictionary = _items[i]
		it.pos += it.vel * delta
		it.rot += float(it.spin) * delta

		if _progress(it) >= 1.0:
			_items[i] = _spawn(it.kind)
		else:
			_items[i] = it
	queue_redraw()




func _progress(it: Dictionary) -> float:
	var v: float = (float(it.y0) - float(it.pos.y)) / maxf(1.0, float(it.travel_px))
	var h: float = (float(it.pos.x) - float(it.x0)) / maxf(1.0, float(it.travel_x_px))
	return clampf(maxf(v, h), 0.0, 1.0)


func _draw() -> void :

	for kind: Dictionary in _KINDS:
		var tex: Texture2D = _atlas_of(String(kind.key))
		if tex == null:
			continue
		var g: int = int(kind.grid)
		var cell: Vector2 = tex.get_size() / float(g)
		for it: Dictionary in _items:
			if it.kind != kind:
				continue
			var travel: float = _progress(it)
			var a: float = _A_PEAK
			if travel < _FADE_IN:
				a *= travel / _FADE_IN
			elif travel > 1.0 - _FADE_OUT:
				a *= (1.0 - travel) / _FADE_OUT
			if a <= 0.004:
				continue
			var sway: float = sin(TAU * (_t / float(it.sway_cycle)) + float(it.sway_phase))\
			* float(it.sway_px)
			var p: Vector2 = Vector2(float(it.pos.x) + sway, float(it.pos.y))

			var grown: float = float(it.size) * lerpf(1.0, float(it.grow_peak), travel)
			var s: float = grown / maxf(1.0, cell.x)
			draw_set_transform(p, float(it.rot), Vector2(s, s))
			draw_texture_rect_region(tex, Rect2( - cell * 0.5, cell), 
				Rect2(Vector2(it.cell) * cell, cell), Color(1.0, 1.0, 1.0, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
