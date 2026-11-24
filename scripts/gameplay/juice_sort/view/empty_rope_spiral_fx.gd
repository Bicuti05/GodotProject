class_name EmptyRopeSpiralFx
extends SpiralLightFx

signal halfway_reached()


const CLIMB_DUR: float = 0.85
const TURNS: float = 2.5

var _rope_geometry: Callable = Callable()
var _axis_dx: float = 0.0
var _halfway_emitted: bool = false



func play_rope(geometry_provider: Callable) -> void :
	_halfway_emitted = false
	_rope_geometry = geometry_provider
	var geometry: Dictionary = _rope_geometry.call()
	var top: Vector2 = geometry["top"]
	var bottom: Vector2 = geometry["bottom"]
	var cfg: Cfg = pot_cfg(Vector2(float(geometry["width"]), bottom.y - top.y))
	cfg.climb_start = 0.0
	cfg.climb_end = CLIMB_DUR
	cfg.turns = TURNS
	cfg.beam_dur = 0.0
	cfg.dust_start = 0.0
	cfg.trail_life_beam = cfg.trail_life_climb
	cfg.front_z = 0
	cfg.bottom_dy = (bottom.y - top.y) * 0.5
	cfg.top_dy = - cfg.bottom_dy
	_axis_dx = bottom.x - top.x
	start((top + bottom) * 0.5, cfg, Callable())


func _process(delta: float) -> void :
	if not is_running():
		return
	if not _rope_geometry.is_valid():
		stop()
		finished.emit()
		return
	var geometry: Dictionary = _rope_geometry.call()
	if geometry.is_empty():
		stop()
		finished.emit()
		return
	var top: Vector2 = geometry["top"]
	var bottom: Vector2 = geometry["bottom"]
	_center = (top + bottom) * 0.5
	_axis_dx = bottom.x - top.x
	_cfg.bottom_dy = (bottom.y - top.y) * 0.5
	_cfg.top_dy = - _cfg.bottom_dy
	_advance(delta)
	if is_running() and not _halfway_emitted and climb_progress() >= 0.5:
		_halfway_emitted = true
		halfway_reached.emit()


func stop() -> void :
	_rope_geometry = Callable()
	super.stop()


func _climb_offset(h: _Head, eased: float) -> Vector2:
	var offset: Vector2 = super._climb_offset(h, eased)
	offset.x += lerpf(_axis_dx * 0.5, - _axis_dx * 0.5, eased)
	return offset



func _update_head(h: _Head) -> void :
	if _t < _cfg.climb_end:
		super._update_head(h)
		return
	h.offset = _climb_offset(h, 1.0)
	h.pos = _center + h.offset
	h.depth = cos(h.phase + TAU * _cfg.turns)
	h.attached = true
	h.alpha = clampf(1.0 - (_t - _cfg.climb_end) / HEAD_FADE_DUR, 0.0, 1.0)
