class_name JuiceIceShatterFx
extends Node2D

signal finished

const DURATION: float = 1.2
const BURST_TIME: float = 0.05
const SHARD_COUNT: int = 18
const FLIPPED_SHARD_COUNT: int = 3
const SPARKLE_COUNT: int = 7
const SPARKLE_TEXTURE: = preload("res://assets/effect/texture/ice/ice_crystal_glint.png")
const SHARD_SILHOUETTE_TEXTURE: = preload("res://assets/effect/texture/ice/ice_shard_silhouette.png")
const SHELF_OCCLUSION_SHADER: = preload("res://assets/effect/shader/shelf_occlusion.gdshader")
const FALL_GRAVITY_RANGES: Array[Vector2] = [Vector2(8.0, 11.0), Vector2(14.0, 18.0), Vector2(23.0, 29.0)]
const FALL_VELOCITY_RANGES: Array[Vector2] = [Vector2(-0.48, -0.1), Vector2(-0.12, 0.3), Vector2(0.45, 1.1)]
const SPIN_SPEED_RANGES: Array[Vector2] = [Vector2(4.0, 6.0), Vector2(9.0, 12.0), Vector2(16.0, 20.0)]
const LIFETIME_RANGES: Array[Vector2] = [Vector2(0.78, 0.85), Vector2(0.9, 0.97), Vector2(1.02, 1.08)]
const FADE_PHASE_RANGES: Array[Vector2] = [Vector2(0.46, 0.58), Vector2(0.58, 0.72), Vector2(0.7, 0.82)]

var skin_resources: JuiceSkinResolver
var burst_z_index: int = 0

var _shards: Array[Dictionary] = []
var _surfaces: Array[Dictionary] = []
var _sparkles: Array[Dictionary] = []
var _cells: Array[PackedVector2Array] = []
var _clock: float = 0.0
var _first_shard_time: float = DURATION
var _running: bool = false
var _break_sound_played: bool = false
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _shelves: Array[Sprite2D] = []


func _init() -> void :
	var occlusion_material: ShaderMaterial = ShaderMaterial.new()
	occlusion_material.shader = SHELF_OCCLUSION_SHADER
	occlusion_material.set_shader_parameter("occlusion_enabled", true)
	material = occlusion_material


func _ready() -> void :
	_random.randomize()
	_build_fracture_cells()
	stop()


func _exit_tree() -> void :
	stop()
	_shelves.clear()


func set_shelves(first: Sprite2D, second: Sprite2D) -> void :
	_shelves.assign([first, second])
	_update_shelf_occlusion()


func _update_shelf_occlusion() -> void :
	var shattering: bool = _running and _clock > _first_shard_time
	z_as_relative = not shattering
	z_index = burst_z_index if shattering else 0
	var occlusion_material: ShaderMaterial = material as ShaderMaterial
	occlusion_material.set_shader_parameter("occlusion_enabled", not shattering)
	if shattering:
		return
	for index: int in 2:
		var shelf: Sprite2D = _shelves[index] if index < _shelves.size() else null
		var prefix: String = "shelf_" if index == 0 else "second_shelf_"
		var alpha: float = 0.0
		var axis_x: Vector3 = Vector3.ZERO
		var axis_y: Vector3 = Vector3.ZERO
		if is_instance_valid(shelf) and shelf.is_visible_in_tree() and shelf.texture != null:
			var inverse: Transform2D = shelf.global_transform.affine_inverse()
			var texture_size: Vector2 = shelf.texture.get_size()
			var offset: Vector2 = texture_size * 0.5 if shelf.centered else Vector2.ZERO
			axis_x = Vector3(inverse.x.x, inverse.y.x, inverse.origin.x + offset.x) / texture_size.x
			axis_y = Vector3(inverse.x.y, inverse.y.y, inverse.origin.y + offset.y) / texture_size.y
			alpha = shelf.modulate.a * shelf.self_modulate.a
			if index == 0:
				occlusion_material.set_shader_parameter("shelf_texture", shelf.texture)
		occlusion_material.set_shader_parameter(prefix + "alpha", alpha)
		occlusion_material.set_shader_parameter(prefix + "uv_x", axis_x)
		occlusion_material.set_shader_parameter(prefix + "uv_y", axis_y)


func play(surfaces: Array) -> void :
	stop()
	var inverse: Transform2D = global_transform.affine_inverse()
	for surface: Node2D in surfaces:
		if not is_instance_valid(surface) or not surface.has_method("ice_shatter_snapshot"):
			continue
		var snapshot: Dictionary = surface.call("ice_shatter_snapshot")
		var texture: Texture2D = snapshot["texture"]
		var rectangle: Rect2 = snapshot["rect"]
		var region: Rect2 = snapshot["region"]
		var transform: Transform2D = inverse * (snapshot["transform"] as Transform2D)
		var burst_center: Vector2 = rectangle.position + rectangle.size * Vector2(
			_random.randf_range(0.38, 0.49), _random.randf_range(0.4, 0.52))
		var burst_axis: Vector2 = Vector2.from_angle(_random.randf_range(-2.45, -0.69))
		_surfaces.append({"texture": texture, "rect": rectangle, "region": region, "transform": transform, 
			"center": burst_center, "axis": burst_axis})
		var pattern_rotation: float = float(_random.randi_range(0, 3)) * PI * 0.5
		var mirror: float = -1.0 if _random.randf() < 0.5 else 1.0
		var flip_candidates: Array[int] = []
		for cell_index: int in _cells.size():
			if _polygon_area(_cells[cell_index]) >= 0.018:
				flip_candidates.append(cell_index)
		var flip_indices: Array[int] = []
		for selection: int in mini(FLIPPED_SHARD_COUNT, flip_candidates.size()):
			flip_indices.append(flip_candidates.pop_at(_random.randi_range(0, flip_candidates.size() - 1)))
		var fall_profiles: Array[int] = []
		var spin_profiles: Array[int] = []
		var lifetime_profiles: Array[int] = []
		for profile_index: int in _cells.size():
			fall_profiles.append(profile_index % FALL_GRAVITY_RANGES.size())
			spin_profiles.append(profile_index % (SPIN_SPEED_RANGES.size() * 2))
			lifetime_profiles.append(profile_index % LIFETIME_RANGES.size())
		for cell_index: int in _cells.size():
			var cell: PackedVector2Array = _cells[cell_index]
			var points: PackedVector2Array = PackedVector2Array()
			var centroid: Vector2 = Vector2.ZERO
			for normalized: Vector2 in cell:
				var point: Vector2 = normalized - Vector2.ONE * 0.5
				point.x *= mirror
				point = rectangle.position + (point.rotated(pattern_rotation) + Vector2.ONE * 0.5) * rectangle.size
				points.append(point)
				centroid += point
			centroid /= points.size()
			var vertices: PackedVector2Array = PackedVector2Array()
			var uvs: PackedVector2Array = PackedVector2Array()
			for point: Vector2 in points:
				vertices.append(point - centroid)
				uvs.append((region.position + (point - rectangle.position) / rectangle.size * region.size) / texture.get_size())
			var area: float = _polygon_area(cell)
			var weight: float = clampf(sqrt(area / 0.09), 0.3, 1.0)
			var direction: Vector2 = (centroid - burst_center).normalized().rotated(_random.randf_range(-0.68, 0.68))
			var speed: float = rectangle.size.x * _random.randf_range(4.6, 7.8) * lerpf(1.18, 0.82, weight)
			var release_distance: float = ((centroid - burst_center) / rectangle.size).length()
			var start_time: float = BURST_TIME + release_distance * 0.018 + _random.randf_range(0.0, 0.006) + weight * 0.012
			_first_shard_time = minf(_first_shard_time, start_time)
			var fall_profile: int = fall_profiles.pop_at(_random.randi_range(0, fall_profiles.size() - 1))
			var spin_profile: int = spin_profiles.pop_at(_random.randi_range(0, spin_profiles.size() - 1))
			var lifetime_profile: int = lifetime_profiles.pop_at(_random.randi_range(0, lifetime_profiles.size() - 1))
			var gravity_range: Vector2 = FALL_GRAVITY_RANGES[fall_profile]
			var velocity_range: Vector2 = FALL_VELOCITY_RANGES[fall_profile]
			var spin_range: Vector2 = SPIN_SPEED_RANGES[floori(float(spin_profile) / 2.0)]
			var lifetime_range: Vector2 = LIFETIME_RANGES[lifetime_profile]
			var fade_range: Vector2 = FADE_PHASE_RANGES[lifetime_profile]
			var lifetime: float = minf(_random.randf_range(lifetime_range.x, lifetime_range.y), 
				DURATION - start_time - 0.008)
			var spin_direction: float = -1.0 if spin_profile % 2 == 0 else 1.0
			var flip: bool = cell_index in flip_indices
			var tilt_direction: float = -1.0 if _random.randf() < 0.5 else 1.0
			var angular_drag: float = _random.randf_range(0.85, 2.25)
			var tilt_speed: float = tilt_direction * PI / _motion_time(
				lifetime * _random.randf_range(0.66, 0.76), angular_drag)\
				if flip else tilt_direction * _random.randf_range(4.0, 9.0)
			var cut_shades: PackedFloat32Array = PackedFloat32Array()
			for vertex_index: int in vertices.size():
				cut_shades.append(_random.randf_range(0.72, 1.04))
			var glint_edge: PackedVector2Array = PackedVector2Array()
			var glint_uvs: PackedVector2Array = PackedVector2Array()
			var longest_edge: float = 0.0
			for edge_index: int in vertices.size():
				var edge_start: Vector2 = vertices[edge_index]
				var edge_end: Vector2 = vertices[(edge_index + 1) % vertices.size()]
				var edge_length: float = edge_start.distance_squared_to(edge_end)
				if edge_length > longest_edge:
					longest_edge = edge_length
					glint_edge = PackedVector2Array([edge_start.lerp(edge_end, 0.14), edge_start.lerp(edge_end, 0.86)])
					var uv_start: Vector2 = uvs[edge_index]
					var uv_end: Vector2 = uvs[(edge_index + 1) % vertices.size()]
					glint_uvs = PackedVector2Array([uv_start.lerp(uv_end, 0.14), uv_start.lerp(uv_end, 0.86)])
			_shards.append({"texture": texture, "vertices": vertices, "uvs": uvs, 
				"transform": transform, "centroid": centroid, 
				"start": start_time, 
				"impulse": direction * speed + burst_axis * rectangle.size.x * _random.randf_range(0.25, 0.7), 
				"impulse_drag": _random.randf_range(9.0, 15.0) * lerpf(1.1, 0.85, weight), 
				"velocity": direction * rectangle.size.x * _random.randf_range(0.75, 1.55)
					+ Vector2(0.0, rectangle.size.y * _random.randf_range(velocity_range.x, velocity_range.y)), 
				"gravity": rectangle.size.y * _random.randf_range(gravity_range.x, gravity_range.y) * lerpf(0.85, 1.18, weight), 
				"drag": _random.randf_range(1.0, 2.0) * lerpf(1.05, 0.7, weight), 
				"spin": spin_direction * _random.randf_range(spin_range.x, spin_range.y) * lerpf(1.05, 0.95, weight), 
				"angular_drag": angular_drag, 
				"trail": weight < 0.72 and _random.randf() < 0.45, 
				"trail_limit": rectangle.size.x * 0.1, "trail_width": rectangle.size.x * 0.006, 
				"tilt": tilt_speed, "rock": _random.randf_range(0.26, 0.52), 
				"tilt_axis": Vector2.from_angle(_random.randf_range(0.0, TAU)), 
				"flip": flip, "cut_shades": cut_shades, "lifetime": lifetime, 
				"fade_start": lifetime * maxf(0.64 if flip else 0.0, _random.randf_range(fade_range.x, fade_range.y)), 
				"edge": glint_edge, "edge_uvs": glint_uvs, 
				"depth": minf(sqrt(longest_edge) * _random.randf_range(0.18, 0.28), 
					rectangle.size.x * _random.randf_range(0.025, 0.055) * lerpf(0.6, 1.0, weight)), 
				"brightness": _random.randf_range(0.96, 1.13)})
		for index: int in SPARKLE_COUNT:
			var direction: Vector2 = Vector2.from_angle(_random.randf_range(0.0, TAU))
			_sparkles.append({"transform": transform, "position": burst_center + direction * rectangle.size.x * 0.22, 
				"velocity": direction * rectangle.size.x * _random.randf_range(1.9, 3.7)
						+ Vector2(0.0, - rectangle.size.y * _random.randf_range(0.15, 0.55)), 
					"size": rectangle.size.x * _random.randf_range(0.035, 0.065), 
					"start": BURST_TIME + _random.randf_range(0.008, 0.035), 
					"lifetime": _random.randf_range(0.14, 0.28), "rotation": _random.randf_range(0.0, TAU)})
	_running = not _shards.is_empty()
	visible = _running
	set_process(_running)
	set_clock(0.0)


func _build_fracture_cells() -> void :
	var seeds: PackedVector2Array = PackedVector2Array()
	var anchors: PackedVector2Array = PackedVector2Array([
		Vector2(0.13, 0.14), Vector2(0.5, 0.1), Vector2(0.85, 0.16), 
		Vector2(0.1, 0.46), Vector2(0.41, 0.37), Vector2(0.73, 0.39), 
		Vector2(0.94, 0.54), Vector2(0.2, 0.76), Vector2(0.53, 0.69), 
		Vector2(0.82, 0.81), Vector2(0.47, 0.94), Vector2(0.1, 0.95)])
	for anchor: Vector2 in anchors:
		seeds.append((anchor + Vector2(_random.randf_range(-0.045, 0.045), 
			_random.randf_range(-0.045, 0.045))).clamp(Vector2.ONE * 0.025, Vector2.ONE * 0.975))
	for index: int in range(12, SHARD_COUNT):
		var anchor: Vector2 = seeds[4 if index % 2 == 0 else 8]
		var offset: Vector2 = Vector2.from_angle(float(index) * 2.4) * _random.randf_range(0.035, 0.072)
		seeds.append((anchor + offset).clamp(Vector2.ONE * 0.025, Vector2.ONE * 0.975))
	for index: int in seeds.size():
		var polygon: PackedVector2Array = PackedVector2Array([
			Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
		for other: int in seeds.size():
			if index == other:
				continue
			var normal: Vector2 = seeds[other] - seeds[index]
			var midpoint: Vector2 = (seeds[other] + seeds[index]) * 0.5
			polygon = _clip_cell(polygon, normal, normal.dot(midpoint))
			if polygon.size() < 3:
				break
		if polygon.size() >= 3 and _polygon_area(polygon) > 0.0005:
			_cells.append(polygon)


func _clip_cell(polygon: PackedVector2Array, normal: Vector2, limit: float) -> PackedVector2Array:
	var clipped: PackedVector2Array = PackedVector2Array()
	if polygon.is_empty():
		return clipped
	var previous: Vector2 = polygon[polygon.size() - 1]
	var previous_distance: float = normal.dot(previous) - limit
	for current: Vector2 in polygon:
		var distance: float = normal.dot(current) - limit
		if (distance <= 0.0) != (previous_distance <= 0.0):
			clipped.append(previous.lerp(current, previous_distance / (previous_distance - distance)))
		if distance <= 0.0:
			clipped.append(current)
		previous = current
		previous_distance = distance
	return clipped


func _polygon_area(polygon: PackedVector2Array) -> float:
	var area: float = 0.0
	for index: int in polygon.size():
		area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return absf(area) * 0.5


func set_clock(clock: float) -> void :
	if not _running:
		return
	_clock = clampf(clock, 0.0, DURATION)
	_update_shelf_occlusion()
	if _clock >= DURATION:
		stop()
		finished.emit()
	else:
		if not _break_sound_played and _clock >= BURST_TIME:
			_break_sound_played = true
			AudioManager.play_sfx(skin_resources.sound_id(&"ice_shatter", &"ice_shatter") if skin_resources != null else &"ice_shatter")
		queue_redraw()


func is_running() -> bool:
	return _running


func stop() -> void :
	if _break_sound_played:
		AudioManager.stop_sfx(skin_resources.sound_id(&"ice_shatter", &"ice_shatter") if skin_resources != null else &"ice_shatter")
	_break_sound_played = false
	_running = false
	_clock = 0.0
	_first_shard_time = DURATION
	_update_shelf_occlusion()
	_shards.clear()
	_surfaces.clear()
	_sparkles.clear()
	hide()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void :
	set_clock(_clock + delta)


func _motion_time(age: float, drag: float) -> float:
	return (1.0 - exp( - drag * age)) / drag


func _draw() -> void :
	if _clock < BURST_TIME:
		var progress: float = _clock / BURST_TIME
		var pulse: float = sin(progress * PI)
		for surface: Dictionary in _surfaces:
			var rectangle: Rect2 = surface["rect"]
			var jitter: Vector2 = Vector2(sin(progress * TAU * 2.0), sin(progress * TAU * 1.5))\
			* rectangle.size.x * 0.01 * pulse
			var turn: float = sin(progress * TAU) * 0.012 * pulse
			var center: Vector2 = rectangle.get_center()
			var anticipation: Transform2D = Transform2D(0.0, center + jitter)\
			* Transform2D(turn, Vector2.ZERO) * Transform2D(0.0, - center)
			draw_set_transform_matrix((surface["transform"] as Transform2D) * anticipation)
			draw_texture_rect_region(surface["texture"], rectangle, surface["region"], 
				Color(1.0 + pulse * 0.24, 1.0 + pulse * 0.28, 1.0 + pulse * 0.34, 1.0))
		_draw_burst_flash()
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	_draw_burst_flash()
	for shard: Dictionary in _shards:
		var age: float = _clock - float(shard["start"])
		if age <= 0.0:
			draw_set_transform_matrix((shard["transform"] as Transform2D)\
			* Transform2D(0.0, shard["centroid"]))
			draw_polygon(shard["vertices"], PackedColorArray([Color.WHITE]), shard["uvs"], shard["texture"])
			continue
		if age >= float(shard["lifetime"]):
			continue
		var lifetime: float = float(shard["lifetime"])
		var opacity: float = 1.0 - smoothstep(float(shard["fade_start"]), lifetime, age)
		var velocity: Vector2 = shard["velocity"]
		var drag: float = float(shard["drag"])
		var impulse: Vector2 = shard["impulse"]
		var impulse_drag: float = float(shard["impulse_drag"])
		var displacement: Vector2 = velocity * _motion_time(age, drag) + impulse * _motion_time(age, impulse_drag)\
		+ Vector2(0.0, float(shard["gravity"]) * age * age * 0.5)
		if bool(shard["trail"]) and age < 0.1:
			var current_velocity: Vector2 = velocity * exp( - drag * age) + impulse * exp( - impulse_drag * age)\
			+ Vector2(0.0, float(shard["gravity"]) * age)
			var trail_end: Vector2 = (shard["centroid"] as Vector2) + displacement
			var trail_start: Vector2 = trail_end - (current_velocity * 0.012).limit_length(float(shard["trail_limit"]))
			draw_set_transform_matrix(shard["transform"])
			draw_line(trail_start, trail_end, Color(0.72, 0.94, 1.0, 
				opacity * 0.16 * smoothstep(0.0, 0.012, age) * (1.0 - smoothstep(0.03, 0.1, age))), 
				float(shard["trail_width"]), true)
		var motion: Transform2D = Transform2D(float(shard["spin"]) * _motion_time(age, float(shard["angular_drag"])), 
			(shard["centroid"] as Vector2) + displacement)
		var transform: Transform2D = (shard["transform"] as Transform2D) * motion
		draw_set_transform_matrix(transform)
		_draw_shard(shard, age, opacity)
	for sparkle: Dictionary in _sparkles:
		var age: float = _clock - float(sparkle["start"])
		var lifetime: float = float(sparkle["lifetime"])
		if age < 0.0 or age >= lifetime:
			continue
		var progress: float = age / lifetime
		var position: Vector2 = (sparkle["position"] as Vector2)\
		+ (sparkle["velocity"] as Vector2) * (1.0 - exp(-5.0 * age)) / 5.0
		var size: float = float(sparkle["size"]) * lerpf(1.0, 0.4, progress)
		draw_set_transform_matrix((sparkle["transform"] as Transform2D)\
		* Transform2D(float(sparkle["rotation"]), position))
		draw_texture_rect(_skin_texture(&"ice_sparkle", SPARKLE_TEXTURE), Rect2(Vector2.ONE * - size * 0.5, Vector2.ONE * size), false, 
			Color(0.8, 0.96, 1.0, sin(progress * PI) * 0.7))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_burst_flash() -> void :
	var progress: float = (_clock - BURST_TIME + 0.014) / 0.1
	if progress <= 0.0 or progress >= 1.0:
		return
	var opacity: float = smoothstep(0.0, 0.16, progress) * (1.0 - smoothstep(0.25, 1.0, progress)) * 0.65
	for surface: Dictionary in _surfaces:
		var rectangle: Rect2 = surface["rect"]
		var width: float = rectangle.size.x * lerpf(0.14, 0.32, smoothstep(0.0, 0.35, progress))
		draw_set_transform_matrix((surface["transform"] as Transform2D)\
		* Transform2D((surface["axis"] as Vector2).angle(), surface["center"]))
		draw_texture_rect(_skin_texture(&"ice_sparkle", SPARKLE_TEXTURE), Rect2(Vector2.ONE * - width * 0.5, Vector2.ONE * width), false, 
			Color(0.8, 0.96, 1.0, opacity))


func _draw_shard(shard: Dictionary, age: float, opacity: float) -> void :
	var tilt: float = float(shard["tilt"]) * _motion_time(age, float(shard["angular_drag"]))
	if not bool(shard["flip"]):
		tilt = sin(tilt) * float(shard["rock"]) * exp(-1.2 * age)
	var axis: Vector2 = shard["tilt_axis"]
	var perpendicular: Vector2 = Vector2( - axis.y, axis.x)
	var face_cosine: float = cos(tilt)
	var depth_offset: Vector2 = perpendicular * float(shard["depth"]) * sin(tilt)
	var front: PackedVector2Array = PackedVector2Array()
	var back: PackedVector2Array = PackedVector2Array()
	for vertex: Vector2 in shard["vertices"]:
		var projected: Vector2 = axis * vertex.dot(axis) + perpendicular * vertex.dot(perpendicular) * face_cosine
		front.append(projected - depth_offset * 0.5)
		back.append(projected + depth_offset * 0.5)
	var near_face: PackedVector2Array = front if face_cosine >= 0.0 else back
	var far_face: PackedVector2Array = back if face_cosine >= 0.0 else front
	var uvs: PackedVector2Array = shard["uvs"]
	if absf(face_cosine) >= 0.015:
		draw_polygon(far_face, PackedColorArray([Color(0.48, 0.78, 0.94, opacity)]), 
			uvs, _skin_texture(&"ice_shard", SHARD_SILHOUETTE_TEXTURE))
	for edge_index: int in front.size():
		var next_index: int = (edge_index + 1) % front.size()
		var direction: Vector2 = front[next_index] - front[edge_index]
		if absf(direction.cross(depth_offset)) < 0.001:
			continue
		var normal: Vector2 = Vector2( - direction.y, direction.x).normalized()
		var shade: float = clampf(0.68 + 0.2 * normal.dot(Vector2(-0.6, -0.8)), 0.45, 0.92)
		var side: PackedVector2Array = PackedVector2Array([
			front[edge_index], front[next_index], back[next_index], back[edge_index]])
		var side_uvs: PackedVector2Array = PackedVector2Array([
			uvs[edge_index], uvs[next_index], uvs[next_index], uvs[edge_index]])
		draw_polygon(side, PackedColorArray([Color(0.48 * shade, 0.8 * shade, 1.03 * shade, opacity)]), 
			side_uvs, _skin_texture(&"ice_shard", SHARD_SILHOUETTE_TEXTURE))
	if absf(face_cosine) < 0.015:
		return
	if face_cosine >= 0.0:
		var brightness: float = float(shard["brightness"]) + 0.18 * exp( - age * 18.0)\
		+ 0.035 * sin(age * 18.0 + float(shard["spin"]))
		draw_polygon(near_face, PackedColorArray([Color(brightness, brightness, brightness, opacity)]), 
			shard["uvs"], shard["texture"])
	else:
		var cut_colors: PackedColorArray = PackedColorArray()
		var cut_shades: PackedFloat32Array = shard["cut_shades"]
		for shade: float in cut_shades:
			cut_colors.append(Color(0.7 * shade, 0.92 * shade, shade, opacity))
		draw_polygon(near_face, cut_colors, uvs, _skin_texture(&"ice_shard", SHARD_SILHOUETTE_TEXTURE))
		var center_uv: Vector2 = Vector2.ZERO
		for uv: Vector2 in uvs:
			center_uv += uv
		center_uv /= uvs.size()
		for edge_index: int in range(0, near_face.size(), 2):
			var next_index: int = (edge_index + 1) % near_face.size()
			var facet: PackedVector2Array = PackedVector2Array([depth_offset * 0.5, 
				near_face[edge_index], near_face[next_index]])
			var facet_uvs: PackedVector2Array = PackedVector2Array([center_uv, uvs[edge_index], uvs[next_index]])
			draw_polygon(facet, PackedColorArray([Color(0.9, 0.98, 1.0, opacity * 0.16)]), 
				facet_uvs, _skin_texture(&"ice_shard", SHARD_SILHOUETTE_TEXTURE))
	var glint_edge: PackedVector2Array = PackedVector2Array()
	var face_offset: Vector2 = - depth_offset * 0.5 if face_cosine >= 0.0 else depth_offset * 0.5
	for vertex: Vector2 in shard["edge"]:
		glint_edge.append(axis * vertex.dot(axis) + perpendicular * vertex.dot(perpendicular) * face_cosine + face_offset)
	var glint_normal: Vector2 = (glint_edge[1] - glint_edge[0]).orthogonal().normalized() * 0.375
	var glint_face: PackedVector2Array = PackedVector2Array([
		glint_edge[0] - glint_normal, glint_edge[1] - glint_normal, 
		glint_edge[1] + glint_normal, glint_edge[0] + glint_normal])
	var edge_uvs: PackedVector2Array = shard["edge_uvs"]
	var glint_uvs: PackedVector2Array = PackedVector2Array([
		edge_uvs[0], edge_uvs[1], edge_uvs[1], edge_uvs[0]])
	draw_polygon(glint_face, PackedColorArray([Color(0.78, 0.94, 1.0, opacity * 0.45 * exp( - age * 5.0))]), 
		glint_uvs, _skin_texture(&"ice_shard", SHARD_SILHOUETTE_TEXTURE))


func _skin_texture(field: StringName, fallback: Texture2D) -> Texture2D:
	return skin_resources.effect_texture(field, fallback) if skin_resources != null else fallback
