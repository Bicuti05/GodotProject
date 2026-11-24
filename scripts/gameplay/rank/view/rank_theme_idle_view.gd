class_name RankThemeIdleView
extends Control


const _SPARKLE_LOOP_INTERVAL_SEC: float = 5.5
const _SPARKLE_START_DELAY_SEC: float = 0.18
const _SPARKLE_BEAT_SEC: Array[float] = [0.0, 0.48, 1.05, 1.7]
const _SPARKLE_ALPHA_MIN: float = 0.35
const _SPARKLE_SAMPLE_GRID: int = 28
const _SPARKLE_FALLBACK_RATIOS: Array[Vector2] = [
	Vector2(-0.32, -0.3), 
	Vector2(0.34, -0.22), 
	Vector2(-0.28, 0.3), 
	Vector2(0.3, 0.26), 
]

const _RISE_EMIT_WIDTH_RATIO: float = 0.95
const _RISE_EMIT_HEIGHT_PX: float = 18.0

@onready var _host: Node2D = $Host
@onready var _img: Sprite2D = $Host / Theme
@onready var _rise_motes: CPUParticles2D = $Host / RiseMotes
@onready var _sparkles: CPUParticles2D = $Host / Sparkles

var _sparkle_loop_tween: Tween = null
var _sparkle_loop_active: bool = false
var _sparkle_gen: int = 0
var _host_base: Vector2 = Vector2.ZERO
var _sparkle_spots_local: Array[Vector2] = []


func _ready() -> void :
	_sync_layout()


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED:
		_sync_layout()


func set_texture(tex: Texture2D) -> void :
	if _img == null:
		return
	_img.texture = tex
	_sync_layout()


func start_idle_fx() -> void :
	if _sparkle_spots_local.is_empty():
		_rebuild_sparkle_spots()
	_start_rise_motes()
	_start_sparkle_loop()


func reset_motion() -> void :
	_kill_sparkle_loop()
	_stop_sparkles()
	_stop_rise_motes()


func _start_sparkle_loop() -> void :
	_kill_sparkle_loop()
	_sparkle_loop_active = true
	_start_sparkle_twinkles()
	_sparkle_loop_tween = create_tween().set_loops()
	_sparkle_loop_tween.tween_interval(_SPARKLE_LOOP_INTERVAL_SEC)
	_sparkle_loop_tween.tween_callback(_start_sparkle_twinkles)


func _kill_sparkle_loop() -> void :
	_sparkle_loop_active = false
	if _sparkle_loop_tween != null and _sparkle_loop_tween.is_valid():
		_sparkle_loop_tween.kill()
	_sparkle_loop_tween = null


func _start_sparkle_twinkles() -> void :
	_sparkle_gen += 1
	var gen: int = _sparkle_gen
	if not is_inside_tree() or not _sparkle_loop_active:
		return
	var picks: Array[Vector2] = _pick_sparkle_spots(_SPARKLE_BEAT_SEC.size())
	for i: int in range(_SPARKLE_BEAT_SEC.size()):
		var delay_sec: float = _SPARKLE_START_DELAY_SEC + _SPARKLE_BEAT_SEC[i]
		var pos: Vector2 = picks[i] if i < picks.size() else Vector2.ZERO
		get_tree().create_timer(delay_sec).timeout.connect(
			func() -> void :
				if gen != _sparkle_gen or not _sparkle_loop_active:
					return
				_emit_one_sparkle_at(pos), 
			CONNECT_ONE_SHOT)


func _pick_sparkle_spots(count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if count <= 0:
		return out
	var pool: Array[Vector2] = _sparkle_spots_local.duplicate()
	if pool.is_empty():
		pool = _fallback_sparkle_spots()
	pool.shuffle()
	for i: int in range(count):
		var base: Vector2 = pool[i % pool.size()]
		var jitter: Vector2 = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		out.append(base + jitter)
	return out


func _fallback_sparkle_spots() -> Array[Vector2]:
	var half: Vector2 = _half_size()
	var out: Array[Vector2] = []
	for ratio: Vector2 in _SPARKLE_FALLBACK_RATIOS:
		out.append(Vector2(half.x * ratio.x, half.y * ratio.y))
	return out


func _emit_one_sparkle_at(local_pos: Vector2) -> void :
	if _sparkles == null:
		return
	_sparkles.position = local_pos
	_sparkles.restart()


func _stop_sparkles() -> void :
	_sparkle_gen += 1
	if _sparkles == null:
		return
	_sparkles.emitting = false
	_sparkles.position = Vector2.ZERO


func _rebuild_sparkle_spots() -> void :
	_sparkle_spots_local.clear()
	if _img == null or _img.texture == null:
		return
	var src: Image = _img.texture.get_image()
	if src == null:
		return
	var img: Image = src
	if img.is_compressed():
		img = src.duplicate()
		var err: Error = img.decompress()
		if err != OK:
			return
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 1 or h <= 1:
		return
	var sc: float = _img.scale.x
	if sc <= 0.0:
		sc = 1.0
	var grid: int = mini(_SPARKLE_SAMPLE_GRID, mini(w, h))
	grid = maxi(grid, 8)
	var edge: Array[Vector2] = []
	var solid: Array[Vector2] = []
	for gy: int in range(grid):
		for gx: int in range(grid):
			var px: int = clampi(int((float(gx) + 0.5) / float(grid) * float(w)), 0, w - 1)
			var py: int = clampi(int((float(gy) + 0.5) / float(grid) * float(h)), 0, h - 1)
			if img.get_pixel(px, py).a < _SPARKLE_ALPHA_MIN:
				continue
			var local: Vector2 = Vector2(
				(float(px) + 0.5 - float(w) * 0.5) * sc, 
				(float(py) + 0.5 - float(h) * 0.5) * sc)
			solid.append(local)
			if _is_edge_pixel(img, px, py, w, h):
				edge.append(local)
	_sparkle_spots_local = edge if not edge.is_empty() else solid


func _is_edge_pixel(img: Image, px: int, py: int, w: int, h: int) -> bool:
	var dirs: Array[Vector2i] = [
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), 
	]
	for d: Vector2i in dirs:
		var nx: int = px + d.x
		var ny: int = py + d.y
		if nx < 0 or ny < 0 or nx >= w or ny >= h:
			return true
		if img.get_pixel(nx, ny).a < _SPARKLE_ALPHA_MIN:
			return true
	return false


func _start_rise_motes() -> void :
	if _rise_motes == null:
		return
	_sync_rise_motes_layout()
	_rise_motes.restart()
	_rise_motes.emitting = true


func _stop_rise_motes() -> void :
	if _rise_motes == null:
		return
	_rise_motes.emitting = false


func _sync_rise_motes_layout() -> void :
	if _rise_motes == null:
		return
	var half: Vector2 = _half_size()
	_rise_motes.position = Vector2(0.0, half.y * 0.92)
	_rise_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rise_motes.emission_rect_extents = Vector2(half.x * _RISE_EMIT_WIDTH_RATIO, _RISE_EMIT_HEIGHT_PX)
	var rise_v: float = half.y * 0.85
	_rise_motes.initial_velocity_min = rise_v * 0.5
	_rise_motes.initial_velocity_max = rise_v * 1.05


func _half_size() -> Vector2:
	var half: Vector2 = size * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		half = custom_minimum_size * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		half = Vector2(100.0, 100.0)
	return half


func _sync_layout() -> void :
	if _img == null or _host == null:
		return
	var s: Vector2 = size
	if s.x <= 0.0 or s.y <= 0.0:
		s = custom_minimum_size
	if s.x <= 0.0 or s.y <= 0.0:
		s = Vector2(200.0, 200.0)
	_host_base = s * 0.5
	_host.position = _host_base
	var tex: Texture2D = _img.texture
	if tex != null:
		var ts: Vector2 = tex.get_size()
		if ts.x > 0.0 and ts.y > 0.0:
			var sc: float = minf(s.x / ts.x, s.y / ts.y)
			_img.scale = Vector2(sc, sc)
	_sync_rise_motes_layout()
	if _sparkles != null:
		_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	if _img.texture != null:
		_rebuild_sparkle_spots()
