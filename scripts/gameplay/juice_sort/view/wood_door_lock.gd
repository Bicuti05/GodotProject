class_name WoodDoorLock
extends Control

signal finished

const DESIGN_SIZE: Vector2 = Vector2(170.0, 877.0)
const THICKNESS: float = 12.0
const CORNER_RADIUS: float = 17.0
const LOCK_SIZE: Vector2 = Vector2(137.55, 168.0)
const LOCK_POSITION: Vector2 = Vector2(16.725, 356.9775)
const LOCK_PIVOT: Vector2 = Vector2(68.5, 102.0)
const SHATTER_LOCK_FALL_TIME: float = 0.19
const SHATTER_LOCK_FADE_TIME: float = 0.74
const SHATTER_LOCK_FADE_DURATION: float = 0.2
const SHATTER_LOCK_RELEASE_VELOCITY: Vector4 = Vector4(110.0, -30.0, 125.0, 0.0)
const SHATTER_LOCK_GRAVITY: float = 2200.0
const SHATTER_CRACK_TIME: float = 0.422
const SHATTER_ANTICIPATION_TIME: float = 0.038
const SHATTER_BREAK_TIME: float = SHATTER_CRACK_TIME + SHATTER_ANTICIPATION_TIME
const SHATTER_IMPACT_DURATION: float = 0.022
const SHATTER_FALL_TIME_SCALE: float = 1.28
const SHATTER_HORIZONTAL_IMPULSE_TIME: float = 0.09
const SHATTER_HORIZONTAL_TAIL_DRAG: float = 2.4
const SHATTER_FADE_DELAY: float = 1.0
const SHATTER_FINISH_TIME: float = SHATTER_BREAK_TIME + 0.45 + SHATTER_FADE_DELAY
const SHATTER_FRAGMENT_RETAIN_RATIO: float = 0.58
const SHATTER_GRAVITY: float = 1320.0
const SHATTER_FRAGMENT_GRAVITY: float = 2400.0
const SHATTER_ORIGIN: Vector2 = LOCK_POSITION + LOCK_PIVOT
const SHATTER_PREPARE_BUDGET_USEC: int = 1800
const LIGHT: Vector3 = Vector3(-0.36, -0.38, 0.852)
const SHATTER_LOCK_TIMES: Array[float] = [0.0, 0.055, 0.115, 0.155, SHATTER_LOCK_FALL_TIME]
const SHATTER_LOCK_KEYS: Array[Vector4] = [
	Vector4(0.0, 0.0, 0.0, 1.0), 
	Vector4(-2.0, 1.0, -4.0, 1.0), 
	Vector4(3.0, -6.0, 10.0, 1.0), 
	Vector4(1.0, -10.0, 6.0, 1.0), 
	Vector4(5.0, -12.0, 11.0, 1.0), 
]
const SHATTER_DOOR_TIMES: Array[float] = [0.0, 0.105, 0.19, 0.275, 0.36, 0.418, SHATTER_BREAK_TIME]
const SHATTER_DOOR_KEYS: Array[Vector4] = [
	Vector4(0.0, 0.0, 0.0, 1.0), 
	Vector4(-0.25, 0.0, -0.025, 1.0), 
	Vector4(-1.6, -0.5, -0.2, 1.0), 
	Vector4(1.2, -0.45, 0.16, 1.0), 
	Vector4(-0.7, 0.0, -0.1, 1.0), 
	Vector4(-1.9, -0.7, -0.26, 1.002), 
	Vector4(1.35, -0.8, 0.14, 1.008), 
]
const REJECT_DURATION: float = 0.32
const REJECT_DISTANCE: float = 4.0


static var _unlock_sound_owner: int = 0
static var _break_sound_owner: int = 0

@export var left_front: Texture2D
@export var right_front: Texture2D
@export var left_back: Texture2D
@export var right_back: Texture2D
@export var wood_grain: Texture2D
@export var lock_body: Texture2D
@export var lock_ring: Texture2D
@export var clasp: Texture2D

var col: int = -1
var _art: Node2D
var _backplate: Control
var _frame: TextureRect
var _left_group: CanvasGroup
var _right_group: CanvasGroup
var _left_surface: Node2D
var _right_surface: Node2D
var _fragment_surface: Node2D
var _shadow: Node2D
var _lock: Node2D
var _condition_reference: Rect2
var _condition: TextureRect
var _count: Label
var _skin_visual: JuiceSkinVisual
var _skin_resources: JuiceSkinResolver
var _remaining_count: int = -1
var _clasp_view: Node2D
var _surfaces: Array[Array] = []
var _profiles: Array[PackedVector2Array] = []
var _time: float = 0.0
var _angles: Vector2 = Vector2.ZERO
var _opacities: Vector2 = Vector2.ONE
var _playing: bool = false
var _shattering: bool = false
var _shatter_generation: int = 0
var _break_sound_played: bool = false
var _fragments: Array[Dictionary] = []
var _cracks: Array[Dictionary] = []


func _ready() -> void :
	_ensure_refs()
	set_process(_playing)
	_apply_time()


func _ensure_refs() -> void :
	if _art != null:
		return
	_art = $Art
	_backplate = $Art / Backplate

	var backplate_view: TextureRect = $Art / Backplate / Texture
	var backplate_region: = AtlasTexture.new()
	backplate_region.atlas = backplate_view.texture
	backplate_region.region = Rect2( - backplate_view.position, _backplate.size)
	backplate_region.filter_clip = true
	backplate_view.texture = backplate_region
	backplate_view.position = Vector2.ZERO
	backplate_view.size = _backplate.size
	_backplate.clip_contents = false
	_frame = $Art / Frame
	_left_group = $Art / LeftDoor
	_right_group = $Art / RightDoor
	_left_surface = $Art / LeftDoor / Surface
	_right_surface = $Art / RightDoor / Surface
	_shadow = $Art / ShadowClip / Shadow
	_lock = $Art / Lock
	_condition = $Art / Lock / Condition
	_condition_reference = Rect2(_condition.position, _condition.size)
	_count = $Art / Lock / Count
	_clasp_view = $Art / Clasp
	_fragment_surface = $Fragments
	_center_count()
	_build_surfaces(0, Rect2(14.0, 14.0, 72.0, 848.0), Rect2(14.0, 0.0, 87.0, 877.0), left_front, left_back)
	_build_surfaces(1, Rect2(87.0, 14.0, 71.0, 848.0), Rect2(78.0, 0.0, 80.0, 877.0), right_front, right_back)


func _center_count() -> void :

	var font: Font = _count.get_theme_font("font")
	var font_size: int = _count.get_theme_font_size("font_size")
	var line: TextLine = TextLine.new()
	line.add_string("0", font, font_size)
	var rid: RID = font.get_rids()[0]
	var text_server: TextServer = TextServerManager.get_primary_interface()
	var glyph: int = text_server.font_get_glyph_index(rid, font_size, "0".unicode_at(0), 0)
	var glyph_offset: Vector2 = text_server.font_get_glyph_offset(rid, Vector2i(font_size, 0), glyph)
	var glyph_size: Vector2 = text_server.font_get_glyph_size(rid, Vector2i(font_size, 0), glyph)
	var correction: float = line.get_size().y * 0.5\
	- line.get_line_ascent() - glyph_offset.y - glyph_size.y * 0.5

	var height: float = maxf(_count.size.y, _count.get_minimum_size().y)
	_count.offset_top = - height * 0.5 + correction
	_count.offset_bottom = height * 0.5 + correction


func configure(display_size: Vector2, flower: Texture2D, remaining_count: int = -1, visual: JuiceSkinVisual = null, resources: JuiceSkinResolver = null) -> void :
	_ensure_refs()
	size = display_size
	_art.scale = display_size / DESIGN_SIZE
	_skin_resources = resources
	_skin_visual = visual
	_condition.texture = flower
	var icon_rect: Rect2 = visual.display_rect(_condition_reference) if visual != null else _condition_reference
	_condition.position = icon_rect.position
	_condition.size = icon_rect.size
	_remaining_count = remaining_count
	_condition.visible = remaining_count < 0
	_count.visible = remaining_count >= 0
	_count.text = str(maxi(0, remaining_count))
	_apply_time()


func condition_texture() -> Texture2D:
	_ensure_refs()
	return _condition.texture


func remaining_count() -> int:
	return _remaining_count



func set_reject_time(time: float) -> void :
	_ensure_refs()
	if time <= 0.0 or time >= REJECT_DURATION:
		_art.position = Vector2.ZERO
		return
	var progress: float = time / REJECT_DURATION
	_art.position = Vector2(sin(progress * TAU * 2.0) * sin(progress * PI) * REJECT_DISTANCE, 0.0)


func _set_lock_pose(travel: Vector2, radians: float, pulse: float = 1.0) -> void :

	var anchor: Vector2 = _art.transform * SHATTER_ORIGIN
	var lock_anchor: Vector2 = SHATTER_ORIGIN * size / DESIGN_SIZE if _shattering else anchor
	var width_scale: float = size.x / DESIGN_SIZE.x if _shattering else _art.scale.x
	var uniform_scale: float = minf(width_scale, minf(lock_anchor.y / LOCK_PIVOT.y, 
		(size.y - lock_anchor.y) / (LOCK_SIZE.y - LOCK_PIVOT.y)))
	_lock.transform = _art.transform.affine_inverse() * Transform2D(radians, 
		Vector2.ONE * uniform_scale * pulse, 0.0, lock_anchor + travel * uniform_scale)
	var clasp_rotation: float = _art.rotation if _shattering else 0.0
	var clasp_scale: float = uniform_scale * _art.scale.x / width_scale if _shattering else uniform_scale
	_clasp_view.transform = _art.transform.affine_inverse() * Transform2D(clasp_rotation, 
		Vector2.ONE * clasp_scale, 0.0, anchor)


func reset_closed() -> void :
	_ensure_refs()
	_stop_sounds()
	_shatter_generation += 1
	_shattering = false
	_playing = false
	_break_sound_played = false
	_time = 0.0
	set_process(false)
	show()
	_apply_time()


func play_shatter() -> void :
	reset_closed()
	_shattering = true
	_apply_time()
	var generation: int = _shatter_generation
	if _fragments.is_empty():
		var prepared: Dictionary = await _prepare_fragments(generation)
		if generation != _shatter_generation or not is_inside_tree():
			return
		_fragments = prepared["fragments"]
		_cracks = prepared["cracks"]
	_playing = true
	_play_skin_sound(&"wood_unlock")
	_unlock_sound_owner = get_instance_id()
	set_process(true)


func stop() -> void :
	_stop_sounds()
	_shatter_generation += 1
	_playing = false
	set_process(false)
	if _fragment_surface != null:
		_fragment_surface.hide()
	hide()


func _stop_sounds() -> void :
	var owner: int = get_instance_id()
	if _unlock_sound_owner == owner:
		_stop_skin_sound(&"wood_unlock")
		_unlock_sound_owner = 0
	if _break_sound_owner == owner:
		_stop_skin_sound(&"wood_break")
		_break_sound_owner = 0


func _exit_tree() -> void :
	stop()


func _process(delta: float) -> void :
	if not _playing:
		return
	_time = minf(SHATTER_FINISH_TIME, _time + delta)
	_apply_time()
	if _time >= SHATTER_FINISH_TIME:
		_playing = false
		set_process(false)
		finished.emit()


func _smooth(value: float) -> float:
	var progress: float = clampf(value, 0.0, 1.0)
	return progress * progress * (3.0 - 2.0 * progress)


func _release_ease(value: float) -> float:
	var remaining: float = 1.0 - clampf(value, 0.0, 1.0)
	return 1.0 - remaining * remaining * remaining


func _apply_time() -> void :
	if _shattering:
		_apply_shatter_time()
		return
	if _fragment_surface != null:
		_fragment_surface.hide()
	_art.scale = size / DESIGN_SIZE
	_art.position = Vector2.ZERO
	_art.rotation = 0.0
	_backplate.visible = true
	_frame.visible = true
	_shadow.visible = true
	_clasp_view.self_modulate.a = 1.0
	_angles = Vector2.ZERO
	_opacities = Vector2.ONE
	_frame.self_modulate.a = 1.0
	_left_group.self_modulate.a = _opacities.x
	_right_group.self_modulate.a = _opacities.y
	_left_group.visible = _opacities.x > 0.0
	_right_group.visible = _opacities.y > 0.0
	_apply_unlock_lock_time()
	_clasp_view.visible = _opacities.x > 0.0 or _opacities.y > 0.0
	_left_surface.queue_redraw()
	_right_surface.queue_redraw()
	_shadow.queue_redraw()
	_lock.queue_redraw()
	_clasp_view.queue_redraw()


func _apply_unlock_lock_time() -> void :
	if _shattering:
		_apply_shatter_lock_time()
		return
	_lock.self_modulate.a = 1.0 - _smooth((_time - 0.65) / 0.3)
	var anticipation: float = clampf((_time - 0.06) / 0.18, 0.0, 1.0)
	var shake: float = sin(anticipation * PI * 3.0) * sin(anticipation * PI) * 1.8 if _time <= 0.24 else 0.0
	var release: float = _smooth((_time - 0.24) / 0.16)
	var fall: float = maxf(0.0, _time - 0.46)
	_set_lock_pose(Vector2(30.0 * fall + 20.0 * fall * fall, 
		10.0 * release + 40.0 * fall + 1600.0 * fall * fall), 
		deg_to_rad(shake + 32.0 * fall + 68.0 * fall * fall))
	_lock.visible = _lock.self_modulate.a > 0.0
	_condition.self_modulate.a = 1.0 - _smooth((_time - 0.3) / 0.16)
	_count.self_modulate.a = _condition.self_modulate.a


func _apply_shatter_lock_time() -> void :
	_lock.self_modulate.a = 1.0 - _smooth((_time - SHATTER_LOCK_FADE_TIME) / SHATTER_LOCK_FADE_DURATION)
	var pose: Vector4 = _shatter_lock_pose(_time)
	_set_lock_pose(Vector2(pose.x, pose.y), deg_to_rad(pose.z), pose.w)
	_lock.visible = _lock.self_modulate.a > 0.0
	_condition.self_modulate.a = 1.0 - _smooth((_time - 0.08) / 0.1)
	_count.self_modulate.a = _condition.self_modulate.a


func _shatter_lock_pose(sample_time: float) -> Vector4:
	if sample_time <= SHATTER_LOCK_FALL_TIME:
		return _shatter_pose(SHATTER_LOCK_KEYS, SHATTER_LOCK_TIMES, sample_time, SHATTER_LOCK_RELEASE_VELOCITY)
	var fall: float = sample_time - SHATTER_LOCK_FALL_TIME
	return SHATTER_LOCK_KEYS.back() + SHATTER_LOCK_RELEASE_VELOCITY * fall\
	+ Vector4(0.0, 0.5 * SHATTER_LOCK_GRAVITY, 80.0, 0.0) * fall * fall


func _apply_shatter_door_pose() -> void :
	var pose: Vector4 = _shatter_pose(SHATTER_DOOR_KEYS, SHATTER_DOOR_TIMES, _time)
	var radians: float = deg_to_rad(pose.z)
	var pivot: Vector2 = size * 0.5
	_art.scale = size / DESIGN_SIZE * pose.w
	_art.rotation = radians
	_art.position = pivot - (size * 0.5 * pose.w).rotated(radians)\
	+ Vector2(pose.x, pose.y) * size.x / DESIGN_SIZE.x


func _corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, 
		Vector2(rect.position.x, rect.end.y)])


func _build_surfaces(side: int, bounds: Rect2, texture_bounds: Rect2, 
		front: Texture2D, back: Texture2D) -> void :
	var profile: PackedVector2Array = PackedVector2Array()
	var centers: Array[Vector2] = [bounds.position + Vector2(bounds.size.x - CORNER_RADIUS, CORNER_RADIUS), 
		bounds.end - Vector2.ONE * CORNER_RADIUS, 
		bounds.position + Vector2(CORNER_RADIUS, bounds.size.y - CORNER_RADIUS), 
		bounds.position + Vector2.ONE * CORNER_RADIUS]
	for quadrant: int in centers.size():
		for sample: int in 9:
			var angle: float = deg_to_rad(-90.0 + 90.0 * float(quadrant) + 90.0 * float(sample) / 8.0)
			profile.append(centers[quadrant] + Vector2(cos(angle), sin(angle)) * CORNER_RADIUS)
	_profiles.append(profile)
	var surfaces: Array[Dictionary] = []
	for index: int in profile.size():
		var first: Vector2 = profile[index]
		var second: Vector2 = profile[(index + 1) % profile.size()]
		var difference: Vector2 = second - first
		if difference.length() < 0.01:
			continue
		var sample_x: float = 48.0 if side == 0 else 121.0
		surfaces.append({
			"vertices": PackedVector3Array([Vector3(first.x, first.y, 0.0), Vector3(second.x, second.y, 0.0), 
				Vector3(second.x, second.y, THICKNESS), Vector3(first.x, first.y, THICKNESS)]), 
			"normal": Vector3(difference.y, - difference.x, 0.0).normalized(), 
			"texture": wood_grain, 
			"uv": PackedVector2Array([Vector2(sample_x / 170.0, first.y / 877.0), 
				Vector2(sample_x / 170.0, second.y / 877.0), 
				Vector2((sample_x + 5.0) / 170.0, second.y / 877.0), 
				Vector2((sample_x + 5.0) / 170.0, first.y / 877.0)]), 
			"tint": Color(0.85, 0.8245, 0.7735, 1.0), 
		})
	for face: int in 2:
		var vertices: PackedVector3Array = PackedVector3Array()
		for point: Vector2 in _corners(texture_bounds):
			vertices.append(Vector3(point.x, point.y, 0.0 if face == 0 else THICKNESS))
		surfaces.append({"vertices": vertices, "normal": Vector3(0.0, 0.0, 1.0 if face == 0 else -1.0), 
			"texture": front if face == 0 else back, "tint": Color.WHITE, 
			"uv": PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])})
	_surfaces.append(surfaces)


func _pose(vertex: Vector3, side: int, radians: float) -> Vector3:
	var hinge: float = 14.0 if side == 0 else 158.0
	var direction: float = 1.0 if side == 0 else -1.0
	var distance: float = (vertex.x - hinge) * direction
	return Vector3(hinge + direction * (distance * cos(radians) + vertex.z * sin(radians)), vertex.y, 
		distance * sin(radians) - vertex.z * cos(radians))


func _normal(normal: Vector3, side: int, radians: float) -> Vector3:
	var direction: float = 1.0 if side == 0 else -1.0
	return Vector3(normal.x * cos(radians) - direction * normal.z * sin(radians), normal.y, 
		direction * normal.x * sin(radians) + normal.z * cos(radians))


func _draw_leaf(canvas: Node2D, side: int) -> void :
	if _surfaces.is_empty():
		return
	var radians: float = deg_to_rad(_angles[side])
	var visible_surfaces: Array[Dictionary] = []
	for surface: Dictionary in _surfaces[side]:
		var normal: Vector3 = _normal(surface["normal"], side, radians)
		if normal.z <= 1e-05:
			continue
		var points: PackedVector2Array = PackedVector2Array()
		var depth: float = 0.0
		for vertex: Vector3 in surface["vertices"]:
			var posed: Vector3 = _pose(vertex, side, radians)
			points.append(Vector2(posed.x, posed.y))
			depth += posed.z
		var light: Vector3 = LIGHT.normalized()
		var brightness: float = (0.7 + 0.3 * maxf(0.0, normal.dot(light))) / (0.7 + 0.3 * light.z)
		var tint: Color = surface["tint"]
		visible_surfaces.append({"depth": depth / 4.0, "points": points, "texture": surface["texture"], 
			"uv": surface["uv"], "color": Color(tint.r * brightness, tint.g * brightness, tint.b * brightness, 1.0)})
	visible_surfaces.sort_custom( func(first: Dictionary, second: Dictionary) -> bool: return float(first["depth"]) < float(second["depth"]))
	for surface: Dictionary in visible_surfaces:
		canvas.draw_polygon(surface["points"], PackedColorArray([surface["color"]]), surface["uv"], surface["texture"])


func _on_left_door_draw() -> void :
	_draw_leaf(_left_surface, 0)


func _on_right_door_draw() -> void :
	if _shattering and _time >= SHATTER_BREAK_TIME:
		return
	_draw_leaf(_right_surface, 1)
	if _shattering:
		_draw_cracks(_right_surface)


func _on_fragments_draw() -> void :
	_fragment_surface.global_transform = _right_surface.global_transform
	_draw_fragments(_fragment_surface)


func _on_shadow_draw() -> void :
	if _profiles.is_empty():
		return
	for side: int in 2:
		if _opacities[side] <= 0.0 or _angles[side] <= 0.0:
			continue
		var radians: float = deg_to_rad(_angles[side])
		var points: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in _profiles[side]:
			var posed: Vector3 = _pose(Vector3(point.x, point.y, 0.0), side, radians)
			points.append(Vector2(posed.x + posed.z * 0.18, posed.y + posed.z * 0.08) - Vector2(14.0, 14.0))
		var alpha: float = 29.0 / 255.0 * sin(radians) * _opacities[side]
		for sample: int in 5:
			var offset: Vector2 = Vector2(float(sample - 2) * 1.4, float(sample - 2) * 0.7)
			_shadow.draw_set_transform(offset)
			_shadow.draw_colored_polygon(points, Color(66.0 / 255.0, 42.0 / 255.0, 24.0 / 255.0, alpha / 5.0))
	_shadow.draw_set_transform(Vector2.ZERO)


func _key_value(keys: Array[Vector2]) -> float:
	for index: int in range(1, keys.size()):
		if _time <= keys[index].x:
			var progress: float = clampf((_time - keys[index - 1].x) / (keys[index].x - keys[index - 1].x), 0.0, 1.0)
			return lerpf(keys[index - 1].y, keys[index].y, _smooth(progress))
	return keys.back().y


func _shatter_pose(keys: Array[Vector4], times: Array[float], sample_time: float, 
		last_velocity: Vector4 = Vector4.ZERO) -> Vector4:
	var last_index: int = keys.size() - 1
	if sample_time <= times[0]:
		return keys[0]
	if sample_time >= times[last_index]:
		return keys[last_index]
	var index: int = 0
	while sample_time > times[index + 1]:
		index += 1
	var start: Vector4 = keys[index]
	var end: Vector4 = keys[index + 1]
	var before_index: int = maxi(0, index - 1)
	var after_index: int = mini(last_index, index + 2)
	var duration: float = times[index + 1] - times[index]
	var start_velocity: Vector4 = (end - keys[before_index]) / (times[index + 1] - times[before_index])
	var end_velocity: Vector4 = (keys[after_index] - start) / (times[after_index] - times[index])
	if index == 0:
		start_velocity = Vector4.ZERO
	if index + 1 == last_index:
		end_velocity = last_velocity
	var progress: float = (sample_time - times[index]) / duration
	var squared: float = progress * progress
	var cubed: float = squared * progress
	return start * (2.0 * cubed - 3.0 * squared + 1.0)\
	+ start_velocity * duration * (cubed - 2.0 * squared + progress)\
	+ end * (-2.0 * cubed + 3.0 * squared) + end_velocity * duration * (cubed - squared)


func _on_lock_draw() -> void :
	var ring_lift: float = _key_value([Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.34, -17.0), 
		Vector2(0.42, -12.0)])
	var ring_rotation: float = _key_value([Vector2(0.0, 0.0), Vector2(0.28, 0.0), Vector2(0.38, 29.0), Vector2(0.46, 24.0)])
	if _shattering:
		ring_lift = _key_value([Vector2(0.0, 0.0), Vector2(0.06, 0.0), 
			Vector2(0.11, -17.0), Vector2(0.135, -10.0), Vector2(0.155, -12.0)])
		ring_rotation = _key_value([Vector2(0.0, 0.0), Vector2(0.07, 0.0), 
			Vector2(0.125, 29.0), Vector2(0.155, 24.0)])
	var ring_pivot: Vector2 = Vector2(88.0, 38.0)
	_lock.draw_set_transform(ring_pivot - LOCK_PIVOT + Vector2(0.0, ring_lift), deg_to_rad(ring_rotation))
	_lock.draw_texture_rect(lock_ring, Rect2( - ring_pivot, LOCK_SIZE), false)
	_lock.draw_set_transform(Vector2.ZERO)
	_lock.draw_texture_rect(lock_body, Rect2( - LOCK_PIVOT, LOCK_SIZE), false)


func _on_clasp_draw() -> void :
	if _shattering and _time >= SHATTER_BREAK_TIME:
		for side: int in 2:
			var direction: float = -1.0 if side == 0 else 1.0
			var age: float = maxf(0.0, _time - SHATTER_BREAK_TIME - 0.02 - float(side) * 0.02)
			var fall_age: float = age * SHATTER_FALL_TIME_SCALE
			_clasp_view.draw_set_transform(Vector2(direction * 95.0 * fall_age, 
				-35.0 * fall_age + 0.5 * SHATTER_GRAVITY * fall_age * fall_age), direction * 2.4 * age)
			_draw_mount(side, deg_to_rad(_angles[side]), 1.0)
		_clasp_view.draw_set_transform(Vector2.ZERO)
		return
	for side: int in 2:
		_draw_mount(side, deg_to_rad(_angles[side]), _opacities[side])


func _draw_mount(side: int, radians: float, alpha: float) -> void :
	if alpha <= 0.0 or cos(radians) <= 0.0:
		return
	var region: Rect2 = Rect2(0.0, 0.0, 90.0, LOCK_SIZE.y) if side == 0\
	else Rect2(90.0, 0.0, LOCK_SIZE.x - 90.0, LOCK_SIZE.y)
	var hinge: float = 14.0 if side == 0 else 158.0
	var points: PackedVector2Array = PackedVector2Array()
	var uv: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in _corners(region):
		var local: Vector2 = point - LOCK_PIVOT
		points.append(Vector2(hinge - SHATTER_ORIGIN.x\
		+ (SHATTER_ORIGIN.x + local.x - hinge) * cos(radians), local.y))
		uv.append(point / LOCK_SIZE)
	_clasp_view.draw_polygon(points, PackedColorArray([Color(1.0, 1.0, 1.0, alpha)]), uv, clasp)


func _apply_shatter_time() -> void :
	var broken: bool = _time >= SHATTER_BREAK_TIME
	if _playing and broken and not _break_sound_played:
		_break_sound_played = true
		_play_skin_sound(&"wood_break")
		_break_sound_owner = get_instance_id()
	var age: float = maxf(0.0, _time - SHATTER_BREAK_TIME)
	_apply_shatter_door_pose()
	_angles = Vector2.ZERO
	_opacities = Vector2.ONE
	_backplate.visible = not broken
	_frame.visible = not broken
	_frame.self_modulate.a = 1.0
	_left_group.visible = not broken
	_right_group.visible = not broken
	_fragment_surface.visible = broken
	if broken:
		_fragment_surface.queue_redraw()
	_left_group.self_modulate.a = 1.0
	_right_group.self_modulate.a = 1.0
	_shadow.visible = not broken
	_apply_unlock_lock_time()
	_clasp_view.visible = true
	_clasp_view.self_modulate.a = 1.0 - _smooth((age - 0.16 - SHATTER_FADE_DELAY) / 0.16)
	_left_surface.queue_redraw()
	_right_surface.queue_redraw()
	_shadow.queue_redraw()
	_lock.queue_redraw()
	_clasp_view.queue_redraw()


func _prepare_fragments(generation: int) -> Dictionary:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 108023
	var fragments: Array[Dictionary] = []
	var cracks: Array[Dictionary] = []
	var slice_start: int = Time.get_ticks_usec()
	for side: int in 2:
		var texture_bounds: Rect2 = Rect2(14.0, 0.0, 87.0, 877.0) if side == 0 else Rect2(78.0, 0.0, 80.0, 877.0)
		var partition: Dictionary = await _fracture_profile(_profiles[side], 16 if side == 0 else 18, random, generation)
		if generation != _shatter_generation:
			return {}
		for crack: Dictionary in partition["cracks"]:
			crack["leaf_side"] = side
			cracks.append(crack)
		for profile: PackedVector2Array in partition["pieces"]:
			fragments.append(_make_fragment(profile, texture_bounds, left_front if side == 0 else right_front, 
				left_back if side == 0 else right_back, random))
			if Time.get_ticks_usec() - slice_start >= SHATTER_PREPARE_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _shatter_generation:
					return {}
				slice_start = Time.get_ticks_usec()
	var frame_texture: Texture2D = _frame.texture
	var frame_bounds: Array[Rect2] = [Rect2(0.0, 14.0, 14.0, 848.0), Rect2(158.0, 14.0, 12.0, 848.0), 
		Rect2(14.0, 0.0, 144.0, 14.0), Rect2(14.0, 862.0, 144.0, 15.0)]
	for frame_index: int in frame_bounds.size():
		var partition: Dictionary = await _fracture_profile(_corners(frame_bounds[frame_index]), 
			4 if frame_index < 2 else 2, random, generation)
		if generation != _shatter_generation:
			return {}
		cracks.append_array(partition["cracks"])
		for profile: PackedVector2Array in partition["pieces"]:
			fragments.append(_make_fragment(profile, Rect2(Vector2.ZERO, DESIGN_SIZE), frame_texture, wood_grain, random, false, true))
			if Time.get_ticks_usec() - slice_start >= SHATTER_PREPARE_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _shatter_generation:
					return {}
				slice_start = Time.get_ticks_usec()
	for index: int in 2:
		var spread: Vector2 = Vector2(random.randf_range(-42.0, 42.0), random.randf_range(-95.0, 95.0))
		var center: Vector2 = SHATTER_ORIGIN + spread
		var width: float = random.randf_range(1.0, 3.2)
		var length: float = random.randf_range(10.0, 17.0) if index == 0 else random.randf_range(25.0, 36.0)
		var profile: PackedVector2Array = PackedVector2Array([center + Vector2( - width, - length * 0.5), 
			center + Vector2(width * random.randf_range(0.3, 0.9), - length * 0.16), 
			center + Vector2(random.randf_range( - width * 0.4, width * 0.8), length * 0.5)])
		if index % 2 == 0:
			profile.append(center + Vector2( - width * 0.7, length * random.randf_range(-0.08, 0.28)))
		fragments.append(_make_fragment(profile, Rect2(Vector2.ZERO, DESIGN_SIZE), wood_grain, wood_grain, 
			random, true))
		if Time.get_ticks_usec() - slice_start >= SHATTER_PREPARE_BUDGET_USEC:
			await get_tree().process_frame
			if generation != _shatter_generation:
				return {}
			slice_start = Time.get_ticks_usec()
	return {"fragments": _retain_fragments(fragments), "cracks": _stylize_cracks(cracks)}


func _stylize_cracks(source_cracks: Array[Dictionary]) -> Array[Dictionary]:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 108024
	var cracks: Array[Dictionary] = []
	var vertical_ratio: float = _art.scale.y / _art.scale.x
	for side: int in 2:
		var bounds: Rect2 = _profile_bounds(_profiles[side]).grow(-9.0)
		var origin: Vector2 = Vector2(bounds.get_center().x, SHATTER_ORIGIN.y)
		var nearest_distance: float = INF
		for source: Dictionary in source_cracks:
			if int(source.get("leaf_side", -1)) != side:
				continue
			for point: Vector2 in source["points"]:
				var offset: Vector2 = (point - SHATTER_ORIGIN) * Vector2(1.0, vertical_ratio)
				if offset.length_squared() < nearest_distance:
					nearest_distance = offset.length_squared()
					origin = point
		origin.y = clampf(origin.y, SHATTER_ORIGIN.y - 14.0, SHATTER_ORIGIN.y + 14.0)
		origin = origin.clamp(bounds.position, bounds.end)
		for direction_index: int in 2:
			var vertical_direction: float = -1.0 if direction_index == 0 else 1.0
			var path: PackedVector2Array = PackedVector2Array([origin])
			var point: Vector2 = origin
			for step: int in 4:
				point = (point + Vector2(random.randf_range(-4.8, 4.8), 
					vertical_direction * random.randf_range(24.0, 53.0))).clamp(bounds.position, bounds.end)
				path.append(point)
			var reveal: float = float(side) * 0.002 + random.randf_range(0.0, 0.003)
			cracks.append({"points": path, "leaf_side": side, "reveal": reveal, 
				"duration": 0.028, "width": random.randf_range(0.9, 1.25)})
			var branch_origin: Vector2 = path[random.randi_range(1, 2)]
			var outward: float = -1.0 if side == 0 else 1.0
			var bend: Vector2 = (branch_origin + Vector2(outward * random.randf_range(3.0, 7.0), 
				vertical_direction * random.randf_range(12.0, 25.0))).clamp(bounds.position, bounds.end)
			var tip: Vector2 = (bend + Vector2(outward * random.randf_range(5.0, 14.0), 
				vertical_direction * random.randf_range(20.0, 42.0))).clamp(bounds.position, bounds.end)
			cracks.append({"points": PackedVector2Array([branch_origin, bend, tip]), "leaf_side": side, 
				"reveal": reveal + random.randf_range(0.015, 0.021), 
				"duration": random.randf_range(0.019, 0.026), "width": random.randf_range(0.48, 0.72)})
	return cracks


func _retain_fragments(fragments: Array[Dictionary]) -> Array[Dictionary]:
	var retained_count: int = roundi(float(fragments.size()) * SHATTER_FRAGMENT_RETAIN_RATIO)
	var indices: PackedInt32Array = PackedInt32Array()
	for index: int in fragments.size():
		indices.append(index)
	var selection_random: RandomNumberGenerator = RandomNumberGenerator.new()
	selection_random.seed = 108024
	for index: int in range(indices.size() - 1, 0, -1):
		var swap_index: int = selection_random.randi_range(0, index)
		var previous_index: int = indices[index]
		indices[index] = indices[swap_index]
		indices[swap_index] = previous_index
	var rectangular_indices: PackedInt32Array = PackedInt32Array()
	var compact_indices: PackedInt32Array = PackedInt32Array()
	var vertical_ratio: float = _art.scale.y / _art.scale.x
	for index: int in indices:
		var bounds: Rect2 = _profile_bounds(fragments[index]["profile"])
		var display_size: Vector2 = Vector2(bounds.size.x, bounds.size.y * vertical_ratio)
		var aspect_ratio: float = maxf(display_size.x, display_size.y) / minf(display_size.x, display_size.y)
		if aspect_ratio >= 2.8:
			rectangular_indices.append(index)
		else:
			compact_indices.append(index)
	var rectangular_count: int = maxi(mini(rectangular_indices.size(), roundi(float(retained_count) * 0.4)), 
		retained_count - compact_indices.size())
	rectangular_indices.resize(rectangular_count)
	compact_indices.resize(retained_count - rectangular_count)
	indices = rectangular_indices
	indices.append_array(compact_indices)
	indices.sort()
	var retained: Array[Dictionary] = []
	var leading: Array[Dictionary] = []
	for index: int in indices:
		var fragment: Dictionary = fragments[index]
		retained.append(fragment)
		if not bool(fragment["splinter"]) and not bool(fragment["frame_piece"]):
			leading.append(fragment)
	leading.sort_custom( func(first: Dictionary, second: Dictionary) -> bool:
		var first_center: Vector2 = first["center"]
		var second_center: Vector2 = second["center"]
		return first_center.distance_squared_to(SHATTER_ORIGIN) < second_center.distance_squared_to(SHATTER_ORIGIN))
	for index: int in mini(4, leading.size()):
		leading[index]["delay"] = 0.0
		leading[index]["hinge_time"] = 0.0
	return retained


func _profile_bounds(profile: PackedVector2Array) -> Rect2:
	var bounds: Rect2 = Rect2(profile[0], Vector2.ZERO)
	for point: Vector2 in profile:
		bounds = bounds.expand(point)
	return bounds


func _profile_signed_area(profile: PackedVector2Array) -> float:
	var area: float = 0.0
	for index: int in profile.size():
		area += profile[index].cross(profile[(index + 1) % profile.size()])
	return area * 0.5


func _profile_center(profile: PackedVector2Array) -> Vector2:
	var weighted: Vector2 = Vector2.ZERO
	var cross_sum: float = 0.0
	for index: int in profile.size():
		var first: Vector2 = profile[index]
		var second: Vector2 = profile[(index + 1) % profile.size()]
		var cross_value: float = first.cross(second)
		cross_sum += cross_value
		weighted += (first + second) * cross_value
	return weighted / (3.0 * cross_sum) if absf(cross_sum) > 0.001 else _profile_bounds(profile).get_center()


func _fracture_profile(profile: PackedVector2Array, count: int, 
		random: RandomNumberGenerator, generation: int) -> Dictionary:
	var pieces: Array[PackedVector2Array] = [profile]
	var cracks: Array[Dictionary] = []
	var slice_start: int = Time.get_ticks_usec()
	var attempts: int = 0
	var source_bounds: Rect2 = _profile_bounds(profile)
	var door_leaf: bool = source_bounds.size.x > 26.0 and source_bounds.size.y > 300.0
	var piece_limit: int = count + 4 if door_leaf else count
	var small_target: int = ceili(float(count) * 0.25) if door_leaf else 0
	var medium_target: int = ceili(float(count) * 0.22) if door_leaf else 0
	while pieces.size() < piece_limit and attempts < piece_limit * 6:
		if generation != _shatter_generation:
			return {}
		attempts += 1
		var chip_cut: bool = false
		var weights: PackedFloat32Array = PackedFloat32Array()
		var chip_weights: PackedFloat32Array = PackedFloat32Array()
		var oversized_weights: PackedFloat32Array = PackedFloat32Array()
		var medium_indices: PackedInt32Array = PackedInt32Array()
		var small_count: int = 0
		var total_weight: float = 0.0
		var total_chip_weight: float = 0.0
		var total_oversized_weight: float = 0.0
		for piece: PackedVector2Array in pieces:
			var area: float = absf(_profile_signed_area(piece))
			if area <= 900.0:
				small_count += 1
			elif area >= 3200.0:
				medium_indices.append(weights.size())
			var bounds: Rect2 = _profile_bounds(piece)
			var distance: float = absf(_profile_center(piece).y - SHATTER_ORIGIN.y)
			var height_limit: float = 210.0 if bounds.size.x < 15.0 else 190.0
			var oversize: float = maxf(bounds.size.y / height_limit, area / 4800.0)
			var weight: float = pow(area, 0.65) * (0.7 + 0.75 * exp( - distance * distance / 42000.0)) if area > 1100.0 else 0.0
			var oversized_weight: float = pow(oversize, 4.0) if oversize > 1.0 and area > 360.0 else 0.0
			oversized_weights.append(oversized_weight)
			total_oversized_weight += oversized_weight
			weights.append(weight)
			total_weight += weight
			var chip_weight: float = exp( - absf(area - 3000.0) / 1800.0) * (0.7 + exp( - distance * distance / 55000.0))\
			if door_leaf and area > 1800.0 and bounds.size.x > 10.0 and bounds.size.y > 25.0 else 0.0
			chip_weights.append(chip_weight)
			total_chip_weight += chip_weight
		var reduce_large: bool = total_oversized_weight > 0.0
		var needs_small: bool = small_count < small_target
		if pieces.size() >= count and not reduce_large and not needs_small:
			break
		if reduce_large:
			weights = oversized_weights
			total_weight = total_oversized_weight
			chip_cut = false
		elif needs_small and total_chip_weight > 0.0:
			weights = chip_weights
			total_weight = total_chip_weight
			chip_cut = true
		else:
			if door_leaf and medium_indices.size() <= medium_target:
				for index: int in medium_indices:
					total_weight -= weights[index]
					weights[index] = 0.0
		if total_weight <= 0.0:
			break
		var selection: float = random.randf() * total_weight
		var selected: int = pieces.size() - 1
		for index: int in weights.size():
			selection -= weights[index]
			if selection < 0.0:
				selected = index
				break
		var split: Dictionary = _split_fragment_profile(pieces[selected], random, chip_cut, reduce_large)
		if not split.is_empty():
			pieces.remove_at(selected)
			pieces.append_array(split["pieces"])
			for seam: PackedVector2Array in split["seams"]:
				if seam.size() < 2:
					continue
				if seam[seam.size() - 1].distance_squared_to(SHATTER_ORIGIN) < seam[0].distance_squared_to(SHATTER_ORIGIN):
					seam.reverse()
				var reveal: float = clampf(seam[0].distance_to(SHATTER_ORIGIN) / 11000.0 + random.randf_range(0.004, 0.01), 0.006, 0.048)
				cracks.append({"points": seam, "reveal": reveal})
		if Time.get_ticks_usec() - slice_start >= SHATTER_PREPARE_BUDGET_USEC:
			await get_tree().process_frame
			if generation != _shatter_generation:
				return {}
			slice_start = Time.get_ticks_usec()
	return {"pieces": pieces, "cracks": cracks}


func _split_fragment_profile(profile: PackedVector2Array, random: RandomNumberGenerator, 
		chip_cut: bool = false, reduce_large: bool = false) -> Dictionary:
	var bounds: Rect2 = _profile_bounds(profile)
	var whole_leaf: bool = bounds.size.x > 58.0 and bounds.size.y > 650.0
	var vertical_ratio: float = _art.scale.y / _art.scale.x
	var display_height: float = bounds.size.y * vertical_ratio
	var along_grain: bool = bounds.size.x > 24.0 and random.randf() < 0.35
	if display_height > bounds.size.x * 1.25 or bounds.size.x < 15.0:
		along_grain = false
	elif bounds.size.x > display_height * 1.25:
		along_grain = true
	if whole_leaf:
		along_grain = false
	var cross_slope: float = random.randf_range(-0.24, 0.24)
	if reduce_large:
		along_grain = bounds.size.x > display_height and bounds.size.x > 24.0
		cross_slope = random.randf_range(-0.16, 0.16)
	if chip_cut:
		cross_slope = random.randf_range(0.12, 0.32) * (-1.0 if random.randf() < 0.5 else 1.0)
	var tangent: Vector2 = Vector2(random.randf_range(-0.1, 0.1), 1.0).normalized() if along_grain else Vector2(1.0, cross_slope).normalized()
	var normal: Vector2 = Vector2(tangent.y, - tangent.x)
	var first_projection: float = profile[0].dot(normal)
	var last_projection: float = first_projection
	for point: Vector2 in profile:
		first_projection = minf(first_projection, point.dot(normal))
		last_projection = maxf(last_projection, point.dot(normal))
	var cut_ratio: float = random.randf_range(0.32, 0.68)
	if reduce_large:
		cut_ratio = random.randf_range(0.32, 0.68)
	elif chip_cut:
		cut_ratio = random.randf_range(0.12, 0.23) if random.randf() < 0.5 else random.randf_range(0.77, 0.88)
	elif not along_grain and bounds.size.y > 220.0:
		cut_ratio = random.randf_range(0.23, 0.75)
		if bounds.size.x < 15.0 and bounds.size.y > 600.0:
			cut_ratio = random.randf_range(0.28, 0.39)
	var cut_projection: float = lerpf(first_projection, last_projection, cut_ratio)
	if not along_grain and not chip_cut and (whole_leaf or ( not reduce_large and bounds.has_point(SHATTER_ORIGIN))):
		var impact: Vector2 = Vector2(bounds.get_center().x, SHATTER_ORIGIN.y + random.randf_range(-72.0, 64.0))
		cut_projection = clampf(impact.dot(normal), lerpf(first_projection, last_projection, 0.25), 
			lerpf(first_projection, last_projection, 0.75))
	var center: Vector2 = bounds.get_center()
	var anchor: Vector2 = center + normal * (cut_projection - center.dot(normal))
	var first_distance: float = (profile[0] - anchor).dot(tangent)
	var last_distance: float = first_distance
	for point: Vector2 in profile:
		first_distance = minf(first_distance, (point - anchor).dot(tangent))
		last_distance = maxf(last_distance, (point - anchor).dot(tangent))
	var amplitude: float = clampf(minf(bounds.size.x, bounds.size.y) * 0.1, 0.8, 6.0)
	if bounds.size.x < 15.0:
		amplitude = random.randf_range(1.0, 2.5)
	if chip_cut:
		amplitude *= 0.45
	var path: PackedVector2Array = _fragment_cut_path(anchor, tangent, normal, 
		first_distance, last_distance, amplitude, along_grain, random)
	var mask: PackedVector2Array = path.duplicate()
	mask.append(path[path.size() - 1] - normal * DESIGN_SIZE.y * 4.0)
	mask.append(path[0] - normal * DESIGN_SIZE.y * 4.0)
	var inside: Array[PackedVector2Array] = Geometry2D.intersect_polygons(profile, mask)
	var outside: Array[PackedVector2Array] = Geometry2D.clip_polygons(profile, mask)
	if inside.size() != 1 or outside.size() != 1:
		return {}
	var pieces: Array[PackedVector2Array] = []
	pieces.append_array(inside)
	pieces.append_array(outside)
	for piece: PackedVector2Array in pieces:
		if piece.size() < 3 or absf(_profile_signed_area(piece)) < 120.0:
			return {}
		var piece_bounds: Rect2 = _profile_bounds(piece)
		if minf(piece_bounds.size.x, piece_bounds.size.y) < 3.0:
			return {}
	if chip_cut:
		var first_area: float = absf(_profile_signed_area(pieces[0]))
		var second_area: float = absf(_profile_signed_area(pieces[1]))
		var small_area: float = minf(first_area, second_area)
		var large_area: float = maxf(first_area, second_area)
		if small_area < 240.0 or small_area > 900.0 or large_area < small_area * 2.8:
			return {}
	return {"pieces": pieces, "seams": Geometry2D.intersect_polyline_with_polygon(path, profile)}


func _fragment_cut_path(anchor: Vector2, tangent: Vector2, normal: Vector2, 
		first_distance: float, last_distance: float, amplitude: float, 
		along_grain: bool, random: RandomNumberGenerator) -> PackedVector2Array:
	var path: PackedVector2Array = PackedVector2Array([anchor + tangent * (first_distance - 24.0), 
		anchor + tangent * first_distance])
	var sections: int = random.randi_range(5, 8) if along_grain else random.randi_range(3, 5)
	var longest_tear: int = random.randi_range(0, sections - 1)
	var direction: float = -1.0 if random.randf() < 0.5 else 1.0
	var previous_notch: float = 0.0
	var interval_weights: PackedFloat32Array = PackedFloat32Array()
	var total_interval_weight: float = 0.0
	for section: int in sections:
		var interval_weight: float = random.randf_range(0.35, 2.6)
		interval_weights.append(interval_weight)
		total_interval_weight += interval_weight
	var interval_start: float = 0.0
	for section: int in sections:
		var interval_size: float = interval_weights[section] / total_interval_weight
		var progress: float = interval_start + interval_size * random.randf_range(0.3, 0.63)
		var notch: float = lerpf(previous_notch, random.randf_range( - amplitude, amplitude), 0.65)
		if not along_grain:
			var fiber_direction: float = direction if section == longest_tear else (-1.0 if random.randf() < 0.5 else 1.0)
			notch = fiber_direction * amplitude * (random.randf_range(0.95, 1.25) if section == longest_tear else random.randf_range(0.16, 0.6))
		path.append(anchor + tangent * lerpf(first_distance, last_distance, progress) + normal * notch)
		if not along_grain:
			var return_progress: float = progress + interval_size * random.randf_range(0.1, 0.22)
			path.append(anchor + tangent * lerpf(first_distance, last_distance, return_progress)
				+ normal * notch * random.randf_range(-0.1, 0.14))
		previous_notch = notch
		interval_start += interval_size
	path.append(anchor + tangent * last_distance)
	path.append(anchor + tangent * (last_distance + 24.0))
	return path


func _make_fragment(profile: PackedVector2Array, texture_bounds: Rect2, front: Texture2D, 
		back: Texture2D, random: RandomNumberGenerator, splinter: bool = false, 
		frame_piece: bool = false) -> Dictionary:
	var source_bounds: Rect2 = _profile_bounds(profile)
	var vertical_ratio: float = _art.scale.y / _art.scale.x
	var shape_random: RandomNumberGenerator = RandomNumberGenerator.new()
	shape_random.seed = int(roundf(source_bounds.get_center().x * 1000.0))\
	+ int(roundf(source_bounds.get_center().y * 1000.0)) * 1000003\
	+ int(roundf(absf(_profile_signed_area(profile)) * 100.0)) * 1000033
	var rectangular: bool = shape_random.randf() < 0.4
	var aspect_limit: float = shape_random.randf_range(3.0, 3.6) if rectangular else 1.75
	var compact_size: Vector2 = Vector2(
		minf(source_bounds.size.x, source_bounds.size.y * vertical_ratio * aspect_limit), 
		minf(source_bounds.size.y, source_bounds.size.x * aspect_limit / vertical_ratio))
	if rectangular:
		if source_bounds.size.x >= source_bounds.size.y * vertical_ratio:
			compact_size.y = compact_size.x / (aspect_limit * vertical_ratio)
		else:
			compact_size.x = compact_size.y * vertical_ratio / aspect_limit
	if not compact_size.is_equal_approx(source_bounds.size):
		var crop_origin: Vector2 = (_profile_center(profile) - compact_size * 0.5).clamp(
			source_bounds.position, source_bounds.end - compact_size)
		if rectangular:
			var corner: float = minf(compact_size.x, compact_size.y * vertical_ratio) * shape_random.randf_range(0.06, 0.12)
			var corner_height: float = corner / vertical_ratio
			profile = PackedVector2Array([
				crop_origin + Vector2(corner, 0.0), 
				crop_origin + Vector2(compact_size.x - corner * 0.55, 0.0), 
				crop_origin + Vector2(compact_size.x, corner_height * 0.8), 
				crop_origin + Vector2(compact_size.x, compact_size.y - corner_height), 
				crop_origin + Vector2(compact_size.x - corner * 0.7, compact_size.y), 
				crop_origin + Vector2(corner * 0.45, compact_size.y), 
				crop_origin + Vector2(0.0, compact_size.y - corner_height * 0.6), 
				crop_origin + Vector2(0.0, corner_height)])
		else:
			var compact_profiles: Array[PackedVector2Array] = Geometry2D.intersect_polygons(
				profile, _corners(Rect2(crop_origin, compact_size)))
			var largest_area: float = 0.0
			for candidate: PackedVector2Array in compact_profiles:
				var candidate_area: float = absf(_profile_signed_area(candidate))
				if candidate_area > largest_area:
					largest_area = candidate_area
					profile = candidate
	if _profile_signed_area(profile) < 0.0:
		profile.reverse()
	var center: Vector2 = _profile_center(profile)
	var bounds: Rect2 = _profile_bounds(profile)
	var area: float = absf(_profile_signed_area(profile))
	var mass: float = clampf(sqrt(area / 16000.0), 0.12, 1.0) if not splinter else 0.04
	var thickness: float = random.randf_range(1.2, 3.0) if splinter else THICKNESS
	var surfaces: Array[Dictionary] = []
	var uv: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in profile:
		uv.append((point - texture_bounds.position) / texture_bounds.size)
	for face: int in 2:
		var vertices: PackedVector3Array = PackedVector3Array()
		for point: Vector2 in profile:
			vertices.append(Vector3(point.x - center.x, point.y - center.y, thickness * (0.5 if face == 0 else -0.5)))
		surfaces.append({"vertices": vertices, "normal": Vector3(0.0, 0.0, 1.0 if face == 0 else -1.0), 
			"texture": front if face == 0 else back, "uv": uv, "tint": Color.WHITE if face == 0 else Color(0.84, 0.79, 0.71)})
	for index: int in profile.size():
		var first: Vector2 = profile[index] - center
		var second: Vector2 = profile[(index + 1) % profile.size()] - center
		var edge: Vector2 = second - first
		if edge.length_squared() < 0.0001:
			continue
		var vertices: PackedVector3Array = PackedVector3Array([Vector3(first.x, first.y, thickness * 0.5), 
			Vector3(second.x, second.y, thickness * 0.5), Vector3(second.x, second.y, - thickness * 0.5), 
			Vector3(first.x, first.y, - thickness * 0.5)])
		var grain_uv: Vector2 = (profile[index] / DESIGN_SIZE).clamp(Vector2.ZERO, Vector2.ONE)
		var edge_tint: Color = Color(0.91, 0.77, 0.55) if absf(edge.x) > absf(edge.y) * 0.45 else Color(0.82, 0.7, 0.51)
		surfaces.append({"vertices": vertices, "normal": Vector3(edge.y, - edge.x, 0.0).normalized(), 
			"texture": wood_grain, "uv": PackedVector2Array([grain_uv, grain_uv + Vector2(0.0, 0.04), 
				grain_uv + Vector2(0.025, 0.04), grain_uv + Vector2(0.025, 0.0)]), "tint": edge_tint})
	var direction: float = -1.0 if center.x < SHATTER_ORIGIN.x else 1.0
	var distance: float = clampf(absf(center.y - SHATTER_ORIGIN.y) / 425.0, 0.0, 1.0)
	var outer_weight: float = clampf(absf(center.x - SHATTER_ORIGIN.x) / 72.0, 0.0, 1.0)
	var trajectory_random: RandomNumberGenerator = RandomNumberGenerator.new()
	trajectory_random.seed = int(roundf(center.x * 1000.0)) + int(roundf(center.y * 1000.0)) * 1000003\
	+ int(roundf(area * 100.0)) * 1000033
	var outward: Vector2 = Vector2(direction, (center.y - SHATTER_ORIGIN.y) / 1400.0).normalized()\
	.rotated(trajectory_random.randf_range(-0.65, 0.65))
	var speed: float = lerpf(290.0, 155.0, mass) * random.randf_range(0.8, 1.3) * lerpf(1.0, 0.72, distance)
	var velocity: Vector2 = outward * speed + Vector2(random.randf_range(-18.0, 18.0), 
		trajectory_random.randf_range(-90.0, 55.0) * lerpf(1.0, 0.82, mass))
	if not frame_piece and not splinter and trajectory_random.randf() < 0.18:
		velocity.x *= - trajectory_random.randf_range(0.35, 0.65)
	var kick: Vector2 = Vector2(direction * lerpf(18.0, 9.0, mass) * (1.0 - outer_weight * 0.45)\
	* trajectory_random.randf_range(0.55, 1.35), random.randf_range(-5.0, 5.0))
	var delay: float = 0.001 + distance * 0.003 + mass * 0.003 + random.randf_range(0.0, 0.007)
	var touches_hinge: bool = bounds.position.x <= 15.0 if direction < 0.0 else bounds.end.x >= 157.0
	var hinged: bool = not splinter and touches_hinge and bounds.size.y > 70.0 and mass > 0.43
	if hinged:
		delay = maxf(delay, 0.006 + distance * 0.004 + random.randf_range(0.0, 0.004))
		kick = Vector2.ZERO
	var fade_start: float = lerpf(0.1, 0.18, mass) + random.randf_range(-0.02, 0.03)
	var fade_duration: float = lerpf(0.12, 0.16, mass)
	var angular_speed: float = clampf(lerpf(0.85, 3.65, pow(random.randf(), 1.3)) * lerpf(1.1, 0.85, mass), 0.8, 3.65)
	var angular_drag: float = random.randf_range(0.5, 1.0)
	var drag: float = lerpf(1.05, 0.38, mass) * trajectory_random.randf_range(0.75, 1.15)
	if frame_piece:
		delay = 0.018 + distance * 0.004 + random.randf_range(0.0, 0.009)
		fade_start = random.randf_range(0.17, 0.2)
		fade_duration = 0.13
		kick = Vector2.ZERO
		angular_speed *= 0.7
	if splinter:
		velocity = outward * random.randf_range(290.0, 380.0) + Vector2(0.0, - random.randf_range(32.0, 58.0))
		delay = random.randf_range(0.0, 0.006)
		fade_start = random.randf_range(0.08, 0.12)
		fade_duration = random.randf_range(0.09, 0.12)
		drag = random.randf_range(1.8, 2.6)
		angular_speed = random.randf_range(3.0, 4.2)
		angular_drag = random.randf_range(1.1, 1.7)
	var spin_axis: Vector3 = Vector3(random.randf_range(-0.5, 0.5), 
		random.randf_range(0.35, 0.9) * (-1.0 if random.randf() < 0.5 else 1.0), 
		random.randf_range(0.45, 1.0) * (-1.0 if random.randf() < 0.5 else 1.0)).normalized()
	var snap: Vector3 = Vector3(spin_axis.x * random.randf_range(0.04, 0.08), 
		spin_axis.y * random.randf_range(0.16, 0.28), spin_axis.z * random.randf_range(0.045, 0.085)) if not splinter else Vector3.ZERO
	return {"center": center, "profile": profile, "surfaces": surfaces, "splinter": splinter, "frame_piece": frame_piece, 
		"hinge_time": (0.008 if frame_piece else 0.004) if hinged else 0.0, "snap": snap, "kick": kick, 
		"pivot": Vector3((14.0 if direction < 0.0 else 158.0) - center.x, 0.0, 0.0) if hinged else Vector3.ZERO, 
		"velocity": velocity, "drag": drag, "angular_drag": angular_drag, 
		"spin": spin_axis * angular_speed, 
		"hinge_spin": Vector3(0.0, direction * 0.5, direction * 0.12) if hinged else Vector3.ZERO, 
		"depth_speed": random.randf_range(-42.0, 42.0), "delay": delay, 
		"fall_rate": trajectory_random.randf_range(0.84, 1.24), 
		"fade_start": fade_start + SHATTER_FADE_DELAY, "fade_duration": fade_duration}


func _fragment_angles(fragment: Dictionary, age: float) -> Vector3:
	var hinge_age: float = minf(age, float(fragment["hinge_time"]))
	var fall_age: float = maxf(0.0, age - float(fragment["hinge_time"]))
	var angular_drag: float = float(fragment["angular_drag"])
	var spin: Vector3 = fragment["spin"]
	var hinge_spin: Vector3 = fragment["hinge_spin"]
	var snap: Vector3 = fragment["snap"]
	var spin_time: float = fall_age * 0.55 + 0.45 * (1.0 - exp( - angular_drag * fall_age)) / angular_drag
	return hinge_spin * hinge_age + spin * spin_time\
	+ snap * _release_ease(age / SHATTER_IMPACT_DURATION)


func _fragment_basis(angles: Vector3) -> Basis:
	var cosine_x: float = cos(angles.x)
	var sine_x: float = sin(angles.x)
	var cosine_y: float = cos(angles.y)
	var sine_y: float = sin(angles.y)
	var cosine_z: float = cos(angles.z)
	var sine_z: float = sin(angles.z)
	return Basis(Vector3(cosine_z * cosine_y, sine_z * cosine_y, - sine_y), 
		Vector3(cosine_z * sine_y * sine_x - sine_z * cosine_x, 
			sine_z * sine_y * sine_x + cosine_z * cosine_x, cosine_y * sine_x), 
		Vector3(cosine_z * sine_y * cosine_x + sine_z * sine_x, 
			sine_z * sine_y * cosine_x - cosine_z * sine_x, cosine_y * cosine_x))


func _draw_cracks(canvas: Node2D) -> void :
	var vertical_ratio: float = _art.scale.y / _art.scale.x
	for crack: Dictionary in _cracks:
		var progress: float = _release_ease((_time - SHATTER_CRACK_TIME - float(crack["reveal"])) / float(crack["duration"]))
		if progress <= 0.0:
			continue
		var path: PackedVector2Array = crack["points"]
		var length: float = 0.0
		for index: int in range(1, path.size()):
			length += path[index].distance_to(path[index - 1])
		var remaining: float = length * progress
		var visible_path: PackedVector2Array = PackedVector2Array([path[0]])
		for index: int in range(1, path.size()):
			var segment_length: float = path[index].distance_to(path[index - 1])
			if remaining < segment_length:
				visible_path.append(path[index - 1].lerp(path[index], remaining / maxf(0.001, segment_length)))
				break
			visible_path.append(path[index])
			remaining -= segment_length
		var leaf_side: int = int(crack.get("leaf_side", -1))
		if leaf_side >= 0:
			var radians: float = deg_to_rad(_angles[leaf_side])
			for index: int in visible_path.size():
				var point: Vector2 = visible_path[index]
				var posed: Vector3 = _pose(Vector3(point.x, point.y, 0.0), leaf_side, radians)
				visible_path[index] = Vector2(posed.x, posed.y)
		for index: int in range(1, visible_path.size()):
			var first: Vector2 = visible_path[index - 1]
			var second: Vector2 = visible_path[index]
			var edge: Vector2 = (second - first) * Vector2(1.0, vertical_ratio)
			if edge.length_squared() < 0.0001:
				continue
			var normal: Vector2 = Vector2( - edge.y, edge.x).normalized() / Vector2(1.0, vertical_ratio)
			var start_width: float = float(crack["width"]) * lerpf(1.0, 0.16, float(index - 1) / float(path.size() - 1))
			var end_width: float = float(crack["width"]) * lerpf(1.0, 0.16, float(index) / float(path.size() - 1))
			canvas.draw_colored_polygon(PackedVector2Array([first - normal * start_width * 0.5, 
				second - normal * end_width * 0.5, second + normal * end_width * 0.5, 
				first + normal * start_width * 0.5]), Color(0.38, 0.21, 0.08, 0.58 * progress))
			canvas.draw_line(first + normal * start_width * 0.65, second + normal * end_width * 0.65, 
				Color(1.0, 0.73, 0.38, 0.25 * progress), 0.26, true)


func _fragment_horizontal_travel(fall_age: float, drag: float) -> float:
	var impulse_time: float = SHATTER_HORIZONTAL_IMPULSE_TIME * SHATTER_FALL_TIME_SCALE
	var impulse_age: float = minf(fall_age, impulse_time)
	var travel: float = (1.0 - exp( - drag * impulse_age)) / drag
	if fall_age > impulse_time:
		var tail_drag: float = drag * SHATTER_HORIZONTAL_TAIL_DRAG
		travel += exp( - drag * impulse_time) * (1.0 - exp( - tail_drag * (fall_age - impulse_time))) / tail_drag
	return travel


func _draw_fragments(canvas: Node2D) -> void :
	var visible_surfaces: Array[Dictionary] = []
	var light: Vector3 = LIGHT.normalized()
	var vertical_ratio: float = _art.scale.y / _art.scale.x
	var vertex_scale: Basis = Basis.from_scale(Vector3(1.0, vertical_ratio, 1.0))
	var normal_scale: Basis = Basis.from_scale(Vector3(1.0, 1.0 / vertical_ratio, 1.0))
	for fragment: Dictionary in _fragments:
		var release_age: float = _time - SHATTER_BREAK_TIME - float(fragment["delay"])
		if release_age < 0.0 and bool(fragment["splinter"]):
			continue
		var age: float = maxf(0.0, release_age)
		var alpha: float = 1.0 - _smooth((age - float(fragment["fade_start"])) / float(fragment["fade_duration"]))
		if alpha <= 0.0:
			continue
		var angles: Vector3 = _fragment_angles(fragment, age)
		var rotation: Basis = _fragment_basis(angles)
		var vertex_rotation: Basis = rotation * vertex_scale
		var normal_rotation: Basis = rotation * normal_scale
		var velocity: Vector2 = fragment["velocity"]
		var center: Vector2 = fragment["center"]
		var drag: float = float(fragment["drag"])
		var fall_age: float = maxf(0.0, age - float(fragment["hinge_time"])) * SHATTER_FALL_TIME_SCALE
		var travel: float = _fragment_horizontal_travel(fall_age, drag)
		var vertical_fall_age: float = fall_age * float(fragment["fall_rate"])
		var kick: Vector2 = fragment["kick"]
		var displacement: Vector2 = kick * _release_ease(age / SHATTER_IMPACT_DURATION)\
		+ Vector2(velocity.x * travel, velocity.y * vertical_fall_age\
		+ 0.5 * SHATTER_FRAGMENT_GRAVITY * vertical_fall_age * vertical_fall_age)
		var fragment_position: Vector2 = center + Vector2(displacement.x, displacement.y / vertical_ratio)
		var pivot: Vector3 = fragment["pivot"]
		var hinge_offset: Vector3 = Vector3.ZERO
		if float(fragment["hinge_time"]) > 0.0:
			var hinge_age: float = minf(age, float(fragment["hinge_time"]))
			var hinge_angles: Vector3 = _fragment_angles(fragment, hinge_age)
			hinge_offset = pivot - _fragment_basis(hinge_angles) * pivot
		for surface: Dictionary in fragment["surfaces"]:
			var original_normal: Vector3 = surface["normal"]
			var normal: Vector3 = (normal_rotation * original_normal).normalized()
			if normal.z <= 1e-05:
				continue
			var points: PackedVector2Array = PackedVector2Array()
			var depth: float = 0.0
			var vertices: PackedVector3Array = surface["vertices"]
			for vertex: Vector3 in vertices:
				var posed: Vector3 = vertex_rotation * vertex + hinge_offset
				points.append(fragment_position + Vector2(posed.x, posed.y / vertical_ratio))
				depth += posed.z
			var brightness: float = (0.7 + 0.3 * maxf(0.0, normal.dot(light))) / (0.7 + 0.3 * light.z)
			var tint: Color = surface["tint"]
			visible_surfaces.append({"depth": depth / float(vertices.size()) + float(fragment["depth_speed"]) * age, 
				"points": points, "texture": surface["texture"], "uv": surface["uv"], 
				"color": Color(tint.r * brightness, tint.g * brightness, tint.b * brightness, alpha)})
	visible_surfaces.sort_custom( func(first: Dictionary, second: Dictionary) -> bool: return float(first["depth"]) < float(second["depth"]))
	for surface: Dictionary in visible_surfaces:
		canvas.draw_polygon(surface["points"], PackedColorArray([surface["color"]]), surface["uv"], surface["texture"])


func _play_skin_sound(id: StringName) -> void :
	AudioManager.play_sfx(_skin_resources.sound_id(id, id) if _skin_resources != null else id)

func _stop_skin_sound(id: StringName) -> void :
	AudioManager.stop_sfx(_skin_resources.sound_id(id, id) if _skin_resources != null else id)


func skin_visual() -> JuiceSkinVisual:
	return _skin_visual

func skin_resources() -> JuiceSkinResolver:
	return _skin_resources
