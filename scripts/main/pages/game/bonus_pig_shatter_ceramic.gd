class_name BonusPigShatterCeramic
extends Node2D

signal geometry_ready

const DEFAULT_SHARD_COUNT: int = 22
const DEFAULT_SEED: int = 281026
const CHIP_COUNT: int = 32
const IMPACT_UV: Vector2 = Vector2(0.5, 0.5)
const HERO_SEEDS: Array[Vector2] = [
	Vector2(0.18, 0.2), Vector2(0.83, 0.2), 
	Vector2(0.45, 0.45), Vector2(0.55, 0.45), Vector2(0.45, 0.55), Vector2(0.55, 0.55), 
	Vector2(0.24, 0.88), Vector2(0.75, 0.88), Vector2(0.19, 0.58), 
	Vector2(0.81, 0.58), Vector2(0.49, 0.76), Vector2(0.48, 0.12), 
]

@export var pig_texture: Texture2D

var burst_force: float = 1.0
var gravity_strength: float = 1.0
var tumble_strength: float = 1.0
var shell_thickness: float = 8.0
var fall_duration: float = 0.85
var crack_duration: float = 0.045
var _shards: Array[Dictionary] = []
var _chips: Array[Dictionary] = []
var _cracks: Array[Dictionary] = []
var _outlines: Array[PackedVector2Array] = []
var _aspect: Vector2 = Vector2.ONE
var _build_generation: int = 0
var _shard_count: int = 0
var _seed: int = DEFAULT_SEED
var _prepared: bool = false
var _active: bool = false
var _edge: float = 1.0
var _age: float = 0.0
var _crack_overlay: Node2D
var _crack_keys: Dictionary = {}

func _ready() -> void :
	hide()
	_crack_overlay = Node2D.new()
	_crack_overlay.z_index = 5
	_crack_overlay.draw.connect(_draw_cracks)
	add_child(_crack_overlay)
	await rebuild(DEFAULT_SHARD_COUNT, DEFAULT_SEED)

func is_prepared() -> bool:
	return _prepared

func configure(settings: Dictionary) -> void :
	burst_force = float(settings.get("burst_force", 1.0))
	gravity_strength = float(settings.get("gravity", 1.0))
	tumble_strength = float(settings.get("tumble", 1.0))
	shell_thickness = float(settings.get("thickness", 8.0))
	fall_duration = float(settings.get("duration", 0.85))
	crack_duration = float(settings.get("crack_duration", 0.045))

func rebuild(count: int, fracture_seed: int) -> void :
	count = clampi(count, 12, 40)
	if _prepared and count == _shard_count and fracture_seed == _seed:
		return
	_build_generation += 1
	var generation: int = _build_generation
	_prepared = false
	reset()
	for shard: Dictionary in _shards:
		(shard["root"] as Node2D).queue_free()
	for chip: Dictionary in _chips:
		(chip["node"] as Polygon2D).queue_free()
	_shards.clear()
	_chips.clear()
	_cracks.clear()
	_crack_keys.clear()
	_shard_count = count
	_seed = fracture_seed
	await get_tree().process_frame
	if generation != _build_generation:
		return
	if _outlines.is_empty():
		var image: Image = pig_texture.get_image()
		await get_tree().process_frame
		if generation != _build_generation:
			return
		if image.is_compressed():
			image.decompress()
			await get_tree().process_frame
			if generation != _build_generation:
				return
		var bitmap: = BitMap.new()
		bitmap.create_from_image_alpha(image, 0.08)
		await get_tree().process_frame
		if generation != _build_generation:
			return
		var texture_size: Vector2 = pig_texture.get_size()
		_aspect = texture_size / maxf(texture_size.x, texture_size.y)
		for outline: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 2.0):
			var normalized: = PackedVector2Array()
			for point: Vector2 in outline:
				normalized.append(point / texture_size)
			_outlines.append(normalized)
		await get_tree().process_frame
		if generation != _build_generation:
			return
	var rng: = RandomNumberGenerator.new()
	rng.seed = _seed
	var seeds: Array[Vector2] = HERO_SEEDS.duplicate()
	var attempts: int = 0
	while seeds.size() < count and attempts < count * 100:
		attempts += 1
		if attempts % 80 == 0:
			await get_tree().process_frame
			if generation != _build_generation:
				return
		var distribution: float = rng.randf()
		var point: = Vector2(rng.randf_range(0.06, 0.94), rng.randf_range(0.05, 0.94))
		var spacing: float = rng.randf_range(0.075, 0.14)
		if distribution < 0.45:
			point = IMPACT_UV + Vector2(rng.randf_range(-0.19, 0.19), rng.randf_range(-0.18, 0.18))
			spacing = rng.randf_range(0.025, 0.055)
		elif distribution < 0.7:
			point = Vector2(rng.randf_range(0.27, 0.36) if rng.randf() < 0.5 else rng.randf_range(0.68, 0.75), rng.randf_range(0.28, 0.8))
			spacing = rng.randf_range(0.035, 0.08)
		spacing *= sqrt(22.0 / float(count))
		var accepted: bool = false
		for outline: PackedVector2Array in _outlines:
			if Geometry2D.is_point_in_polygon(point, outline):
				accepted = true
				break
		for existing: Vector2 in seeds:
			if point.distance_to(existing) < spacing:
				accepted = false
				break
		if accepted:
			seeds.append(point)
	for seed_index: int in range(seeds.size()):
		var cell: = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
		for neighbor_index: int in range(seeds.size()):
			if seed_index == neighbor_index:
				continue
			var normal: Vector2 = seeds[neighbor_index] - seeds[seed_index]
			var midpoint: Vector2 = (seeds[neighbor_index] + seeds[seed_index]) * 0.5
			cell = _clip_half_plane(cell, normal, midpoint.dot(normal))
			if cell.size() < 3:
				break
		if cell.size() >= 3:
			for outline: PackedVector2Array in _outlines:
				for polygon: PackedVector2Array in Geometry2D.intersect_polygons(cell, outline):
					if Geometry2D.is_polygon_clockwise(polygon) or polygon.size() < 3:
						continue
					var area: float = absf(_signed_area(polygon))
					if area < 2e-05:
						continue
					var fractured: PackedVector2Array = _jagged_polygon(polygon, seeds[seed_index], seeds)
					_add_shard(fractured, area, rng)
					_collect_cracks(polygon, seeds[seed_index], seeds)
		if seed_index % 3 == 2:
			await get_tree().process_frame
			if generation != _build_generation:
				return
	var first_release: float = INF
	for shard: Dictionary in _shards:
		first_release = minf(first_release, float(shard["delay"]))
	for shard: Dictionary in _shards:
		shard["delay"] = maxf(float(shard["delay"]) - first_release, 0.0)
	_assign_motion_profiles(rng)
	_build_chips(rng)
	_prepared = true
	geometry_ready.emit()

func _clip_half_plane(polygon: PackedVector2Array, normal: Vector2, limit: float) -> PackedVector2Array:
	var result: = PackedVector2Array()
	if polygon.is_empty():
		return result
	var previous: Vector2 = polygon[polygon.size() - 1]
	var previous_distance: float = previous.dot(normal) - limit
	for current: Vector2 in polygon:
		var current_distance: float = current.dot(normal) - limit
		if (current_distance <= 0.0) != (previous_distance <= 0.0):
			var fraction: float = previous_distance / (previous_distance - current_distance)
			result.append(previous.lerp(current, fraction))
		if current_distance <= 0.0:
			result.append(current)
		previous = current
		previous_distance = current_distance
	return result

func _signed_area(polygon: PackedVector2Array) -> float:
	var area: float = 0.0
	for vertex_index: int in range(polygon.size()):
		area += polygon[vertex_index].cross(polygon[(vertex_index + 1) % polygon.size()])
	return area * 0.5

func _centroid(polygon: PackedVector2Array) -> Vector2:
	var weighted_center: = Vector2.ZERO
	for vertex_index: int in range(polygon.size()):
		var current: Vector2 = polygon[vertex_index]
		var following: Vector2 = polygon[(vertex_index + 1) % polygon.size()]
		weighted_center += (current + following) * current.cross(following)
	return weighted_center / (6.0 * _signed_area(polygon))

func _is_internal_edge(midpoint: Vector2, seed_point: Vector2, seeds: Array[Vector2]) -> bool:
	var own_distance: float = midpoint.distance_squared_to(seed_point)
	for neighbor: Vector2 in seeds:
		if neighbor != seed_point and absf(midpoint.distance_squared_to(neighbor) - own_distance) < 5e-05:
			return true
	return false

func _jagged_edge(start: Vector2, finish: Vector2) -> PackedVector2Array:
	var reversed: bool = start.x > finish.x or (is_equal_approx(start.x, finish.x) and start.y > finish.y)
	var first: Vector2 = finish if reversed else start
	var last: Vector2 = start if reversed else finish
	var direction: Vector2 = last - first
	var normal: Vector2 = Vector2( - direction.y, direction.x).normalized()
	var rng: = RandomNumberGenerator.new()
	rng.seed = _seed + roundi(first.x * 10000.0) * 31 + roundi(first.y * 10000.0) * 17 + roundi(last.x * 10000.0) * 13 + roundi(last.y * 10000.0)
	var path: = PackedVector2Array([first])
	var cut_count: int = rng.randi_range(0, 3)
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	for cut_index: int in range(cut_count):
		var fraction: float = (float(cut_index) + rng.randf_range(0.35, 0.7)) / float(cut_count + 1)
		var displacement: float = minf(direction.length() * 0.05, 0.006) * side * rng.randf_range(0.15, 1.0)
		if rng.randf() < 0.25:
			side = - side
		path.append(first.lerp(last, fraction) + normal * displacement)
	path.append(last)
	if reversed:
		path.reverse()
	return path

func _jagged_polygon(polygon: PackedVector2Array, seed_point: Vector2, seeds: Array[Vector2]) -> PackedVector2Array:
	var result: = PackedVector2Array()
	for vertex_index: int in range(polygon.size()):
		var start: Vector2 = polygon[vertex_index]
		var finish: Vector2 = polygon[(vertex_index + 1) % polygon.size()]
		result.append(start)
		if _is_internal_edge((start + finish) * 0.5, seed_point, seeds):
			var edge: PackedVector2Array = _jagged_edge(start, finish)
			for cut_index: int in range(1, edge.size() - 1):
				result.append(edge[cut_index])
	return result

func _add_shard(polygon: PackedVector2Array, area: float, rng: RandomNumberGenerator) -> void :
	var center: Vector2 = _centroid(polygon)
	var local_polygon: = PackedVector2Array()
	var texture_uv: = PackedVector2Array()
	var low: = Vector2(INF, INF)
	var high: = Vector2( - INF, - INF)
	for point: Vector2 in polygon:
		local_polygon.append((point - center) * _aspect)
		texture_uv.append(point * pig_texture.get_size())
		low = low.min(point)
		high = high.max(point)
	var root: = Node2D.new()
	root.hide()
	add_child(root)
	var rim: = Polygon2D.new()
	var rim_shape: PackedVector2Array = local_polygon.duplicate()
	rim_shape.append_array(local_polygon)
	rim.polygon = rim_shape
	var rim_faces: Array[PackedInt32Array] = []
	for vertex_index: int in range(local_polygon.size()):
		var next_index: int = (vertex_index + 1) % local_polygon.size()
		rim_faces.append(PackedInt32Array([vertex_index, next_index, next_index + local_polygon.size(), vertex_index + local_polygon.size()]))
	rim.polygons = rim_faces
	rim.color = Color(0.88, 0.46, 0.065)
	root.add_child(rim)
	var interior: = Polygon2D.new()
	interior.polygon = local_polygon
	interior.color = Color(0.58, 0.27, 0.04)
	root.add_child(interior)
	var front: = Polygon2D.new()
	front.polygon = local_polygon
	front.uv = texture_uv
	front.texture = pig_texture
	root.add_child(front)
	var edge_line: = Line2D.new()
	edge_line.points = local_polygon
	edge_line.closed = true
	edge_line.default_color = Color(1.0, 0.79, 0.28)
	edge_line.width = 0.002
	root.add_child(edge_line)
	var distance: float = center.distance_to(IMPACT_UV)
	var size_weight: float = clampf(sqrt(area) / 0.24, 0.25, 1.0)
	var dimensions: Vector2 = high - low
	var slenderness: float = maxf(dimensions.x, dimensions.y) / maxf(minf(dimensions.x, dimensions.y), 0.005)
	var side: float = -1.0 if center.x < 0.5 else 1.0
	var direction: Vector2 = Vector2(center.x - IMPACT_UV.x, (center.y - IMPACT_UV.y) * 0.72).normalized().rotated(rng.randf_range(-0.2, 0.2))
	var speed: float = rng.randf_range(2.0, 3.2) * lerpf(1.18, 0.72, size_weight) * lerpf(1.0, 1.2, clampf((slenderness - 1.0) / 3.0, 0.0, 1.0))
	var velocity: Vector2 = direction * speed + Vector2(side * rng.randf_range(0.12, 0.32), - rng.randf_range(0.12, 0.32))
	if center.y < 0.3:
		velocity.y -= rng.randf_range(0.2, 0.45)
	_shards.append({
		"root": root, "front": front, "interior": interior, "rim": rim, "edge_line": edge_line, 
		"origin": (center - Vector2.ONE * 0.5) * _aspect, "velocity": velocity, 
		"delay": minf(distance * 0.014 + size_weight * 0.001, 0.012), 
		"roll_angle": rng.randf_range(1.1, 3.3) * (-1.0 if rng.randf() < 0.5 else 1.0), 
		"tilt_axis": rng.randf_range( - PI, PI), 
		"secondary_angle": rng.randf_range(0.2, 0.6) * (-1.0 if rng.randf() < 0.5 else 1.0), 
		"depth": rng.randf_range(-0.42, 0.55), 
		"weight": size_weight, "gravity": rng.randf_range(0.92, 1.1), 
		"thickness": rng.randf_range(0.55, 1.2), 
	})

func _assign_motion_profiles(rng: RandomNumberGenerator) -> void :
	var back_count: int = maxi(1, roundi(_shards.size() * 0.35))
	var candidates: Array[int] = []
	for shard_index: int in range(_shards.size()):
		candidates.append(shard_index)
		var shard: Dictionary = _shards[shard_index]
		shard["primary_angle"] = rng.randf_range(0.65, 1.4) * (-1.0 if rng.randf() < 0.5 else 1.0)
		shard["primary_limit"] = 1.48
	while back_count > 0 and not candidates.is_empty():
		var candidate_index: int = rng.randi_range(0, candidates.size() - 1)
		var shard: Dictionary = _shards[candidates[candidate_index]]
		candidates.remove_at(candidate_index)
		var back_angle: float = rng.randf_range(2.1, 2.8) if rng.randf() < 0.5 else rng.randf_range(3.2, 4.7)
		shard["primary_angle"] = back_angle * (-1.0 if rng.randf() < 0.5 else 1.0)
		shard["primary_limit"] = 5.1
		back_count -= 1

func _collect_cracks(polygon: PackedVector2Array, seed_point: Vector2, seeds: Array[Vector2]) -> void :
	for vertex_index: int in range(polygon.size()):
		var start: Vector2 = polygon[vertex_index]
		var finish: Vector2 = polygon[(vertex_index + 1) % polygon.size()]
		var midpoint: Vector2 = (start + finish) * 0.5
		if not _is_internal_edge(midpoint, seed_point, seeds):
			continue
		var key: String = "%d,%d:%d,%d" % [roundi(midpoint.x * 10000.0), roundi(midpoint.y * 10000.0), roundi(start.distance_to(finish) * 10000.0), _seed]
		if _crack_keys.has(key):
			continue
		_crack_keys[key] = true
		var points: PackedVector2Array = _jagged_edge(start, finish)
		for point_index: int in range(points.size()):
			points[point_index] = (points[point_index] - Vector2.ONE * 0.5) * _aspect
		_cracks.append({"points": points, "distance": midpoint.distance_to(IMPACT_UV)})

func _build_chips(rng: RandomNumberGenerator) -> void :
	var impact_origin: Vector2 = (IMPACT_UV - Vector2.ONE * 0.5) * _aspect
	var impact_sources: Array[Dictionary] = []
	for shard: Dictionary in _shards:
		var origin: Vector2 = shard["origin"]
		if origin.distance_to(impact_origin) < 0.2:
			impact_sources.append(shard)
	if impact_sources.is_empty():
		impact_sources.assign(_shards)
	for chip_index: int in range(CHIP_COUNT):
		var chip: = Polygon2D.new()
		var radius: float = rng.randf_range(0.0035, 0.014)
		var vertex_count: int = rng.randi_range(3, 6)
		var chip_shape: = PackedVector2Array()
		var proportions: = Vector2(rng.randf_range(0.5, 1.5), rng.randf_range(0.35, 1.2))
		for vertex_index: int in range(vertex_count):
			var angle: float = (float(vertex_index) + rng.randf_range(0.1, 0.6)) * TAU / float(vertex_count)
			chip_shape.append(Vector2(cos(angle), sin(angle)) * radius * rng.randf_range(0.6, 1.0) * proportions)
		chip.polygon = chip_shape
		chip.color = Color(rng.randf_range(0.8, 1.0), rng.randf_range(0.42, 0.78), rng.randf_range(0.04, 0.16))
		chip.z_index = 4
		chip.hide()
		add_child(chip)
		var angle: float = float(chip_index) * TAU / float(CHIP_COUNT) + rng.randf_range(-0.22, 0.22)
		var source: Dictionary = impact_sources[rng.randi_range(0, impact_sources.size() - 1)]
		var source_origin: Vector2 = source["origin"]
		var chip_origin: Vector2 = impact_origin.lerp(source_origin, rng.randf_range(0.15, 0.45))
		_chips.append({"node": chip, "origin": chip_origin, "velocity": Vector2(cos(angle), sin(angle)) * rng.randf_range(1.8, 3.7) + Vector2.UP * 0.2, "spin": rng.randf_range(-9.0, 9.0), "delay": rng.randf_range(0.0, 0.01), "life": rng.randf_range(0.36, 0.72)})

func play(center: Vector2, edge: float) -> void :
	if not _prepared:
		return
	global_position = center
	_edge = edge
	_active = true
	sample(0.0)

func sample(age: float) -> void :
	if not _active:
		return
	_age = maxf(age, 0.0)
	visible = age >= 0.0 and age < fall_duration + 0.15
	for shard: Dictionary in _shards:
		var root: Node2D = shard["root"]
		var front: Polygon2D = shard["front"]
		var interior: Polygon2D = shard["interior"]
		var rim: Polygon2D = shard["rim"]
		var edge_line: Line2D = shard["edge_line"]
		var delay: float = shard["delay"]
		var elapsed: float = maxf(_age - delay, 0.0)
		var weight: float = shard["weight"]
		var life: float = fall_duration * lerpf(0.76, 1.0, weight)
		root.visible = elapsed < life
		var opening: float = clampf(elapsed / 0.012, 0.0, 1.0)
		root.position = _sample_shard_position(shard, _age)
		var rotation_progress: float = elapsed / life
		root.rotation = float(shard["roll_angle"]) * tumble_strength * rotation_progress
		root.scale = Vector2.ONE * _edge * (1.0 + float(shard["depth"]) * elapsed)
		root.z_index = 1 if float(shard["depth"]) > 0.0 else 0
		root.modulate.a = 1.0 - smoothstep(life * 0.86, life, elapsed)
		var primary_limit: float = shard["primary_limit"]
		var primary_angle: float = clampf(float(shard["primary_angle"]) * tumble_strength, - primary_limit, primary_limit) * rotation_progress
		var secondary_angle: float = clampf(float(shard["secondary_angle"]) * tumble_strength, -0.7, 0.7) * rotation_progress
		var facing: float = cos(primary_angle) * cos(secondary_angle)
		var tilt: float = shard["tilt_axis"]
		var axis: = Vector2(cos(tilt), sin(tilt))
		var perpendicular: = Vector2( - axis.y, axis.x)
		var cross_tilt: float = sin(secondary_angle) * sin(primary_angle)
		var face_transform: = Transform2D(axis * (cos(secondary_angle) * axis.x + cross_tilt * perpendicular.x) + perpendicular * cos(primary_angle) * perpendicular.x, axis * (cos(secondary_angle) * axis.y + cross_tilt * perpendicular.y) + perpendicular * cos(primary_angle) * perpendicular.y, Vector2.ZERO)
		var thickness: float = shell_thickness * float(shard["thickness"])
		var projected_normal: Vector2 = axis * sin(secondary_angle) * cos(primary_angle) - perpendicular * sin(primary_angle)
		var face_offset: Vector2 = projected_normal * thickness * 0.5 / _edge
		front.transform = Transform2D(face_transform.x, face_transform.y, face_offset)
		interior.transform = Transform2D(face_transform.x, face_transform.y, - face_offset)
		var shell_sides: = PackedVector2Array()
		for point: Vector2 in front.polygon:
			shell_sides.append(face_transform * point + face_offset)
		for point: Vector2 in front.polygon:
			shell_sides.append(face_transform * point - face_offset)
		rim.polygon = shell_sides
		rim.visible = opening > 0.0 and thickness > 0.0
		interior.visible = facing < 0.0
		front.visible = facing >= 0.0
		edge_line.transform = front.transform if facing >= 0.0 else interior.transform
		edge_line.width = lerpf(0.35, thickness * 0.18, projected_normal.length()) / _edge
		edge_line.visible = opening > 0.0
		edge_line.default_color = Color(0.87, 0.55, 0.15, opening * 0.65) if facing >= 0.0 else Color(0.86, 0.49, 0.12, opening)
		var shade: float = lerpf(0.82, 1.0, absf(facing))
		front.color = Color(shade, shade, shade)
		interior.color = Color(0.58, 0.27, 0.04) * Color(shade, shade, shade)
	for chip: Dictionary in _chips:
		var node: Polygon2D = chip["node"]
		var elapsed: float = _age - float(chip["delay"])
		var life: float = fall_duration * float(chip["life"])
		node.visible = elapsed >= 0.0 and elapsed < life
		var velocity: Vector2 = chip["velocity"]
		var origin: Vector2 = chip["origin"]
		node.position = origin * _edge + velocity * burst_force * _edge * _sample_burst_travel(maxf(elapsed, 0.0)) + Vector2(0.0, 1.4 * gravity_strength * _edge * elapsed * elapsed)
		node.rotation = float(chip["spin"]) * elapsed
		node.scale = Vector2.ONE * _edge
		node.modulate.a = 1.0 - smoothstep(life * 0.64, life, elapsed)
	_crack_overlay.queue_redraw()

func _sample_shard_position(shard: Dictionary, age: float) -> Vector2:
	var delay: float = shard["delay"]
	var elapsed: float = maxf(age - delay, 0.0)
	var origin: Vector2 = shard["origin"]
	var velocity: Vector2 = shard["velocity"]
	return (origin + velocity * burst_force * _sample_burst_travel(elapsed)) * _edge + Vector2(0.0, 1.45 * gravity_strength * float(shard["gravity"]) * _edge * elapsed * elapsed)

func _sample_burst_travel(elapsed: float) -> float:
	var impulse_duration: float = 0.085
	if elapsed <= impulse_duration:
		return elapsed
	return impulse_duration + (1.0 - exp( - (elapsed - impulse_duration) * 4.0)) / 4.0

func shard_world_position(index: int, age: float) -> Vector2:
	if _shards.is_empty():
		return global_position
	return to_global(_sample_shard_position(_shards[index % _shards.size()], age))

func impact_world_position() -> Vector2:
	return to_global((IMPACT_UV - Vector2.ONE * 0.5) * _aspect * _edge)

func _draw_cracks() -> void :
	var trace_duration: float = minf(crack_duration, 0.022)
	if not _active or _age >= trace_duration * 1.8:
		return
	var wave: float = 0.1 + _age / maxf(trace_duration, 0.01) * 0.85
	var fade: float = 1.0 - smoothstep(trace_duration * 0.7, trace_duration * 1.8, _age)
	for crack: Dictionary in _cracks:
		var alpha: float = smoothstep(float(crack["distance"]) * 0.65, float(crack["distance"]) * 0.65 + 0.08, wave) * fade
		if alpha <= 0.0:
			continue
		var points: PackedVector2Array = crack["points"]
		var width: float = lerpf(1.0, maxf(_edge * 0.005, 2.0), smoothstep(0.0, trace_duration, _age))
		var traced: = PackedVector2Array()
		var highlight: = PackedVector2Array()
		for point: Vector2 in points:
			traced.append(point * _edge)
			highlight.append(point * _edge + Vector2(width * 0.3, - width * 0.25))
		_crack_overlay.draw_polyline(traced, Color(0.17, 0.06, 0.008, alpha), width, true)
		_crack_overlay.draw_polyline(highlight, Color(1.0, 0.85, 0.35, alpha * 0.8), maxf(width * 0.22, 0.8), true)

func reset() -> void :
	_active = false
	_age = 0.0
	hide()
	if is_instance_valid(_crack_overlay):
		_crack_overlay.queue_redraw()
