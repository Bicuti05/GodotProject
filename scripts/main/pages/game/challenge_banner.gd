class_name ChallengeBanner
extends Control



const IN_DURATION: float = 0.35
const HOLD_DURATION: float = 0.75
const OUT_DURATION: float = 0.46
const DISMISS_DURATION: float = 0.15
const HOLD_DRIFT_PX: float = 24.0
const EDGE_MARGIN: float = 48.0
const CARD_VISUAL_CENTER: Vector2 = Vector2(387.5, 110.5)
const CARD_SIZE: Vector2 = Vector2(775.0, 224.0)
const CARD_DURATION: float = IN_DURATION + HOLD_DURATION + OUT_DURATION
const PETAL_POOL_SIZE: int = 32
const MOVING_EMIT_INTERVAL: float = 0.055
const HOLD_EMIT_INTERVAL: float = 0.18
const PETAL_LIFE_MAX: float = 0.95

@export var petal_textures: Array[Texture2D] = []
@export var title_textures: Dictionary[String, Texture2D] = {}
@export var title_positions: Dictionary[String, Vector2] = {}
@onready var _card: TextureRect = $Card
@onready var _title: TextureRect = $Card / Title

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _petals: Array[Dictionary] = []
var _time: float = 0.0
var _next_emit_at: float = 0.0
var _dst_center: Vector2 = Vector2.ZERO
var _card_center: Vector2 = Vector2.ZERO
var _card_velocity_x: float = 0.0
var _display_scale: float = 1.0
var _left: float = 0.0
var _right: float = 0.0
var _dismissing: bool = false
var _dismiss_time: float = 0.0
var _dismiss_center: Vector2 = Vector2.ZERO
var _dismiss_alpha: float = 0.0
var _dismiss_rotation: float = 0.0


func _ready() -> void :
	_rng.randomize()
	_card.pivot_offset = CARD_VISUAL_CENTER

	for i: int in PETAL_POOL_SIZE:
		_petals.append({"active": false})
	hide_now()



func play(center: Vector2, title_locale: String = "") -> void :
	hide_now()
	_apply_title_locale(TranslationServer.get_locale() if title_locale.is_empty() else title_locale)
	_dst_center = center
	_time = 0.0
	_next_emit_at = 0.0
	_dismissing = false
	_update_viewport_bounds()
	visible = true
	_card.visible = true
	_apply_card_motion(0.0)
	set_process(true)



static func _language_of(locale: String) -> String:
	return locale.replace("-", "_").get_slice("_", 0).to_lower()


func _apply_title_locale(locale: String) -> void :
	var language: String = _language_of(locale)
	if not title_textures.has(language):
		language = "en"
	_title.texture = title_textures[language]
	_title.position = title_positions[language]
	_title.size = _title.texture.get_size()



func dismiss() -> void :
	if not visible or not _card.visible or _dismissing:
		return
	_dismissing = true
	_dismiss_time = 0.0
	_dismiss_center = _card_center
	_dismiss_alpha = _card.modulate.a
	_dismiss_rotation = _card.rotation



func is_card_showing() -> bool:
	return visible and _card.visible and not _dismissing



func hide_now() -> void :
	set_process(false)
	visible = false
	_dismissing = false
	for petal: Dictionary in _petals:
		petal["active"] = false
	if is_instance_valid(_card):
		_card.visible = false
		_card.modulate = Color.WHITE
		_card.rotation = 0.0
		_card.scale = Vector2.ONE
	queue_redraw()


func _update_viewport_bounds() -> void :
	var inv: Transform2D = get_global_transform_with_canvas().affine_inverse()
	var viewport: Rect2 = get_viewport_rect()
	_left = (inv * viewport.position).x
	_right = (inv * viewport.end).x
	_display_scale = minf(1.0, maxf(1.0, _right - _left - 96.0) / CARD_SIZE.x)



func _motion_at(t: float) -> Dictionary:
	var half_w: float = CARD_SIZE.x * _display_scale * 0.5
	var start_x: float = _right + half_w + EDGE_MARGIN
	var in_x: float = _dst_center.x + HOLD_DRIFT_PX * 0.5
	var out_x: float = _dst_center.x - HOLD_DRIFT_PX * 0.5
	var end_x: float = _left - half_w - EDGE_MARGIN
	var drift_v: float = - HOLD_DRIFT_PX / HOLD_DURATION
	var x: float
	var vx: float
	if t < IN_DURATION:
		var u: float = clampf(t / IN_DURATION, 0.0, 1.0)
		var start_v: float = (in_x - start_x) / IN_DURATION * 1.9
		x = _hermite(start_x, in_x, start_v, drift_v, IN_DURATION, u)
		vx = _hermite_velocity(start_x, in_x, start_v, drift_v, IN_DURATION, u)
	elif t < IN_DURATION + HOLD_DURATION:
		x = in_x + drift_v * (t - IN_DURATION)
		vx = drift_v
	else:
		var u: float = clampf((t - IN_DURATION - HOLD_DURATION) / OUT_DURATION, 0.0, 1.0)
		var end_v: float = (end_x - out_x) / OUT_DURATION * 1.9
		x = _hermite(out_x, end_x, drift_v, end_v, OUT_DURATION, u)
		vx = _hermite_velocity(out_x, end_x, drift_v, end_v, OUT_DURATION, u)
	var progress: float = clampf(t / CARD_DURATION, 0.0, 1.0)
	return {"center": Vector2(x, _dst_center.y + 4.0 * sin(progress * TAU)), 
		"vx": vx, "rotation": deg_to_rad(lerpf(-1.0, 1.0, smoothstep(0.0, 1.0, progress)))}


func _hermite(a: float, b: float, va: float, vb: float, duration: float, u: float) -> float:
	return (2.0 * u * u * u - 3.0 * u * u + 1.0) * a\
	+ (u * u * u - 2.0 * u * u + u) * duration * va\
	+ (-2.0 * u * u * u + 3.0 * u * u) * b\
	+ (u * u * u - u * u) * duration * vb


func _hermite_velocity(a: float, b: float, va: float, vb: float, duration: float, u: float) -> float:
	return ((6.0 * u * u - 6.0 * u) * a + (3.0 * u * u - 4.0 * u + 1.0) * duration * va\
	+ (-6.0 * u * u + 6.0 * u) * b + (3.0 * u * u - 2.0 * u) * duration * vb) / duration


func _apply_card_motion(t: float) -> void :
	var sample: Dictionary = _motion_at(t)
	_card_center = sample["center"]
	_card_velocity_x = float(sample["vx"])
	_card.position = _card_center - CARD_VISUAL_CENTER
	_card.scale = Vector2.ONE * _display_scale
	_card.rotation = float(sample["rotation"])

	var alpha: float = smoothstep(0.0, 0.12, t)\
	* (1.0 - smoothstep(CARD_DURATION - 0.16, CARD_DURATION, t))
	_card.modulate.a = alpha


func _process(delta: float) -> void :
	if not visible or delta <= 0.0:
		return
	_time += delta
	for petal: Dictionary in _petals:
		if bool(petal["active"]):
			petal["age"] = float(petal["age"]) + delta
			if float(petal["age"]) >= float(petal["life"]):
				petal["active"] = false
	if _dismissing:
		_dismiss_time += delta
		_card_center = _dismiss_center + Vector2(-40.0 * _dismiss_time, 0.0)
		_card.position = _card_center - CARD_VISUAL_CENTER
		_card.rotation = _dismiss_rotation
		_card.modulate.a = _dismiss_alpha * (1.0 - smoothstep(0.0, DISMISS_DURATION, _dismiss_time))
		if _dismiss_time >= DISMISS_DURATION:
			_card.visible = false
	else:
		_apply_card_motion(minf(_time, CARD_DURATION))

		var emitted: int = 0
		while _next_emit_at < minf(_time, CARD_DURATION - 0.08) and emitted < 8:
			_spawn_petal(_next_emit_at)
			var holding: bool = _next_emit_at >= IN_DURATION and _next_emit_at < IN_DURATION + HOLD_DURATION
			_next_emit_at += HOLD_EMIT_INTERVAL if holding else MOVING_EMIT_INTERVAL
			emitted += 1
		if emitted == 8:
			_next_emit_at = _time
		if _time >= CARD_DURATION:
			_card.visible = false
	queue_redraw()
	if not _card.visible and active_petal_count() == 0:
		hide_now()


func _spawn_petal(birth: float) -> void :
	if petal_textures.is_empty():
		return
	var sample: Dictionary = _motion_at(birth)
	var center: Vector2 = sample["center"]
	var half_w: float = CARD_SIZE.x * _display_scale * 0.5
	var half_h: float = CARD_SIZE.y * _display_scale * 0.5
	for petal: Dictionary in _petals:
		if bool(petal["active"]):
			continue

		var pick: float = _rng.randf()
		var texture_idx: int = _rng.randi_range(0, 1) if pick < 0.65 else _rng.randi_range(3, 4)
		if pick > 0.95:
			texture_idx = 2
		var behind: Vector2 = Vector2(half_w + _rng.randf_range(12.0, 42.0) * _display_scale, 
			_rng.randf_range( - half_h * 0.7, half_h * 0.7))
		var vx: float = clampf(float(sample["vx"]) * 0.12, -230.0, -55.0)
		petal.merge({"active": true, "texture": texture_idx % petal_textures.size(), 
			"origin": center + behind.rotated(float(sample["rotation"])), 
			"velocity": Vector2(vx * _rng.randf_range(0.7, 1.0), _rng.randf_range(-18.0, 18.0)), 
			"age": maxf(0.0, _time - birth), "life": _rng.randf_range(0.65, PETAL_LIFE_MAX), 
			"size": _rng.randf_range(38.0, 66.0) * _display_scale, 
			"angle": _rng.randf_range( - PI, PI), "spin": _rng.randf_range(-1.1, 1.1), 
			"phase": _rng.randf_range(0.0, TAU)}, true)
		return


func active_petal_count() -> int:
	var count: int = 0
	for petal: Dictionary in _petals:
		if bool(petal["active"]):
			count += 1
	return count


func _draw() -> void :

	for petal: Dictionary in _petals:
		if not bool(petal["active"]):
			continue
		var tex: Texture2D = petal_textures[int(petal["texture"])]
		var age: float = float(petal["age"])
		var u: float = clampf(age / float(petal["life"]), 0.0, 1.0)
		var alpha: float = smoothstep(0.0, 0.08, age) * (1.0 - smoothstep(0.35, 1.0, u)) * 0.85
		var pos: Vector2 = petal["origin"] + (petal["velocity"] as Vector2) * age
		pos.y += 8.0 * sin(float(petal["phase"]) + age * 3.0) * sin(u * PI)
		var size_px: float = float(petal["size"]) * lerpf(1.0, 0.85, u)
		draw_set_transform(pos, float(petal["angle"]) + float(petal["spin"]) * age)
		draw_texture_rect(tex, Rect2(Vector2.ONE * - size_px * 0.5, Vector2.ONE * size_px), false, 
			Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform_matrix(Transform2D.IDENTITY)
