class_name JuiceGroupHighlightLandingParticles
extends Node2D

const HUE_MIN: float = 0.0
const HUE_MAX: float = 1.0
const SATURATION_MIN: float = 0.18
const SATURATION_MAX: float = 0.35
const START_RADIUS_MIN_RATIO: float = 0.4
const START_RADIUS_MAX_RATIO: float = 0.44
const TRAVEL_DISTANCE_MIN_RATIO: float = 0.08
const TRAVEL_DISTANCE_MAX_RATIO: float = 0.18
const MAX_RADIUS_RATIO: float = START_RADIUS_MAX_RATIO + TRAVEL_DISTANCE_MAX_RATIO
const PARTICLE_RADIUS_MIN_RATIO: float = 0.05
const PARTICLE_RADIUS_MAX_RATIO: float = 0.08
const GLOW_RADIUS_SCALE: float = 2.0
const WHITE_CORE_RADIUS_RATIO: float = 0.84
const GLOW_OPACITY: float = 0.72
const GLOW_INTENSITY_MULTIPLIER: float = 1.5
const GLOW_LAYER_COUNT: int = 3
const STAR_OUTLINE_POINT_COUNT: int = 32


const STAR_TEXTURE_EXTENT: float = 2.0
const MOTION_DURATION: float = 0.36
const SIZE_DURATION: float = 0.38
const FADE_IN_DURATION: float = 0.035

var star_texture: Texture2D
var _particles: Array[Dictionary] = []
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _diameter: float = 0.0
var _lifetime: float = 0.5
var _age: float = -1.0


func _ready() -> void :
	hide()


func _exit_tree() -> void :
	stop()


func prepare(particle_count: int, diameter: float, origin: Vector2, lifetime: float, 
		lifetime_min: float = 0.0) -> void :
	stop()
	position = origin
	_diameter = diameter
	_lifetime = lifetime
	if particle_count <= 0 or diameter <= 0.0 or lifetime <= 0.0:
		return
	var minimum_lifetime: float = minf(lifetime_min, lifetime) if lifetime_min > 0.0 else lifetime
	_random.randomize()
	var sector_angle: float = TAU / float(particle_count)
	var rotation_offset: float = _random.randf_range(0.0, TAU)
	var rounded_star_points: PackedVector2Array = _make_star_points(4.0)
	var sharp_star_points: PackedVector2Array = _make_star_points(6.0)
	for particle_index: int in particle_count:
		var angle: float = rotation_offset + float(particle_index) * sector_angle\
		+ _random.randf_range(-0.4, 0.4) * sector_angle
		var color: Color = Color.from_hsv(_random.randf_range(HUE_MIN, HUE_MAX), 
			_random.randf_range(SATURATION_MIN, SATURATION_MAX), 1.0)
		var start_radius: float = diameter * _random.randf_range(
			START_RADIUS_MIN_RATIO, START_RADIUS_MAX_RATIO)
		_particles.append({
			"direction": Vector2.from_angle(angle), 
			"start_radius": start_radius, 
			"travel_distance": diameter * _random.randf_range(
				TRAVEL_DISTANCE_MIN_RATIO, TRAVEL_DISTANCE_MAX_RATIO), 
			"radius_ratio": _random.randf_range(PARTICLE_RADIUS_MIN_RATIO, PARTICLE_RADIUS_MAX_RATIO), 
			"star_points": rounded_star_points if particle_index % 2 == 0 else sharp_star_points, 
			"color": color, 
			"lifetime": _random.randf_range(minimum_lifetime, lifetime), 
		})


func _make_star_points(profile: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index: int in STAR_OUTLINE_POINT_COUNT:
		var angle: float = TAU * float(point_index) / float(STAR_OUTLINE_POINT_COUNT)
		var direction: Vector2 = Vector2.from_angle(angle)
		points.append(Vector2(
			signf(direction.x) * pow(absf(direction.x), profile), 
			signf(direction.y) * pow(absf(direction.y), profile)))
	return points


func set_age(age: float) -> void :
	_age = age
	if age < 0.0 or age >= _lifetime or _particles.is_empty():
		hide()
		return
	show()
	queue_redraw()


func stop() -> void :
	hide()
	_age = -1.0
	_particles.clear()
	queue_redraw()


func _draw() -> void :
	if _age < 0.0 or _age >= _lifetime or _particles.is_empty():
		return
	var motion_progress: float = clampf(_age / MOTION_DURATION, 0.0, 1.0)
	var eased_progress: float = 1.0 - pow(1.0 - motion_progress, 3.0)
	var size_factor: float = 1.0 - 0.4 * clampf(_age / SIZE_DURATION, 0.0, 1.0)
	for particle: Dictionary in _particles:
		var lifetime: float = particle["lifetime"]
		if _age >= lifetime:
			continue
		var progress: float = _age / lifetime
		var opacity: float = smoothstep(0.0, FADE_IN_DURATION, _age)\
		* (1.0 - smoothstep(0.25, 1.0, progress))
		var direction: Vector2 = particle["direction"]
		var start_radius: float = particle["start_radius"]
		var travel_distance: float = particle["travel_distance"]
		var radius_ratio: float = particle["radius_ratio"]
		var star_points: PackedVector2Array = particle["star_points"]
		var color: Color = particle["color"]
		var particle_position: Vector2 = direction * (start_radius + travel_distance * eased_progress)
		particle_position.y += _diameter\
		* (0.06 * motion_progress * motion_progress - 0.05 * motion_progress)
		particle_position = particle_position.limit_length(_diameter * MAX_RADIUS_RATIO)
		var core_radius: float = _diameter * radius_ratio * size_factor
		if star_texture != null:
			draw_set_transform(particle_position, 0.0, Vector2.ONE)
			var extent: float = core_radius * STAR_TEXTURE_EXTENT
			draw_texture_rect(star_texture, 
				Rect2(Vector2.ONE * - extent, Vector2.ONE * extent * 2.0), false, 
				Color(color, opacity))
			continue
		var glow_radius: float = core_radius * GLOW_RADIUS_SCALE
		for glow_index: int in GLOW_LAYER_COUNT:
			var glow_progress: float = float(glow_index) / float(GLOW_LAYER_COUNT - 1)
			var glow: Color = color.lightened(0.55)
			glow.a = opacity * clampf(
				GLOW_OPACITY * GLOW_INTENSITY_MULTIPLIER * lerpf(0.45, 1.0, glow_progress), 
				0.0, 1.0)
			var layer_radius: float = glow_radius * lerpf(1.0, 0.65, glow_progress)
			draw_set_transform(particle_position, 0.0, Vector2.ONE * layer_radius)
			draw_colored_polygon(star_points, glow)
		var core: Color = color
		core.a = opacity
		draw_set_transform(particle_position, 0.0, Vector2.ONE * core_radius)
		draw_colored_polygon(star_points, core)
		var white_core: Color = Color.WHITE
		white_core.a = opacity
		draw_set_transform(particle_position, 0.0, Vector2.ONE * core_radius * WHITE_CORE_RADIUS_RATIO)
		draw_colored_polygon(star_points, white_core)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
