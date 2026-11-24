extends Node2D




@export var texture: Texture2D
@export var config: Dictionary = {}

class Particle:
	extends RefCounted
	var born: float = 0.0
	var lifetime: float = 0.0
	var position: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO
	var size: float = 0.0
	var angle: float = 0.0
	var angular_velocity: float = 0.0
	var limit: float = 0.0
	var color: Color = Color.WHITE
	var frame: int = 0

var _particles: Array[Particle] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _elapsed: float = 0.0
var _next_birth: float = 0.0
var _burst_pending: bool = false
var _emitter_transform: Transform2D = Transform2D.IDENTITY


func _ready() -> void :
	set_process(false)


func start(emitter_transform: Transform2D) -> void :
	stop()
	_emitter_transform = emitter_transform
	if config.seed == 0:
		_rng.randomize()
	else:
		_rng.seed = config.seed
	_elapsed = 0.0
	_next_birth = config.delay + (1.0 / config.rate if config.rate > 0.0 else 0.0)
	_burst_pending = config.burst > 0
	set_process(true)


func stop() -> void :
	set_process(false)
	_particles.clear()
	queue_redraw()


func _process(delta: float) -> void :
	_elapsed += delta
	for i in range(_particles.size() - 1, -1, -1):
		if _elapsed - _particles[i].born >= _particles[i].lifetime:
			_particles.remove_at(i)
	if _burst_pending and _elapsed >= config.delay:
		_burst_pending = false
		for i in int(config.burst):
			_spawn(config.delay)
	if config.rate > 0.0:

		var due: int = maxi(0, int(floor((minf(_elapsed, config.delay + config.duration) - _next_birth) * config.rate)) + 1)
		for i in mini(due, int(config.max_count)):
			_spawn(_next_birth + float(i) / config.rate)
		_next_birth += float(due) / config.rate
	for particle in _particles:
		var step: float = minf(delta, _elapsed - particle.born)
		var speed: float = particle.velocity.length()
		var before: Vector3 = particle.velocity
		if config.dampen > 0.0 and speed > particle.limit:

			var after_speed: float = particle.limit + (speed - particle.limit) * pow(1.0 - config.dampen, step * 60.0)
			particle.velocity *= after_speed / speed
		particle.position += (before + particle.velocity) * (0.5 * step)
		particle.angle += particle.angular_velocity * step
	queue_redraw()
	if _elapsed >= config.delay + config.duration and _particles.is_empty():
		set_process(false)


func _spawn(born: float) -> void :
	if _particles.size() >= int(config.max_count):
		return
	var particle: Particle = Particle.new()
	particle.born = born
	particle.lifetime = _random_range(config.lifetime)
	particle.size = _random_range(config.size) * config.unit_scale
	particle.angle = - _random_range(config.rotation)
	particle.angular_velocity = - _random_range(config.angular_velocity)
	particle.limit = _random_range(config.limit)
	particle.color = Color(config.color_min[0], config.color_min[1], config.color_min[2], config.color_min[3]).lerp(
		Color(config.color_max[0], config.color_max[1], config.color_max[2], config.color_max[3]), _rng.randf())
	particle.frame = _rng.randi_range(0, int(config.frames) - 1)
	var azimuth: float = _rng.randf_range(0.0, TAU)
	var radius_ratio: float = sqrt(_rng.randf()) if config.radius_thickness > 0.0 else 1.0
	var tilt: float = deg_to_rad(config.cone_angle) * radius_ratio
	var speed: float = _random_range(config.speed)
	var initial: Vector3 = Vector3(sin(tilt) * cos(azimuth), sin(tilt) * sin(azimuth), cos(tilt)) * speed
	initial += Vector3(_random_range(config.velocity_x), _random_range(config.velocity_y), 0.0)
	var projected: Vector2 = _emitter_transform.basis_xform(Vector2(initial.x, - initial.y))
	particle.velocity = Vector3(projected.x, projected.y, initial.z)
	var origin: Vector2 = Vector2(cos(azimuth), - sin(azimuth)) * config.radius * radius_ratio
	origin = _emitter_transform.basis_xform(origin) * config.unit_scale * config.shape_scale
	particle.position = Vector3(origin.x, origin.y, 0.0) / config.unit_scale
	_particles.append(particle)


func _draw() -> void :
	var grid: int = int(config.grid)
	var frame_size: Vector2 = texture.get_size() / float(grid)
	var fade_out: Array = config.get("fade_out", [])
	for particle in _particles:
		var age: float = clampf((_elapsed - particle.born) / particle.lifetime, 0.0, 1.0)
		var size: float = particle.size * sample_curve(config.size_curve, age)
		var color: Color = particle.color * _sample_gradient(age)
		if not fade_out.is_empty():

			color.a *= 1.0 - smoothstep(fade_out[0], fade_out[1], _elapsed - particle.born)
		var frame: int = particle.frame
		var source: Rect2 = Rect2(Vector2(frame % grid, frame / grid) * frame_size, frame_size)
		draw_set_transform(Vector2(particle.position.x, particle.position.y) * config.unit_scale, particle.angle)
		draw_texture_rect_region(texture, Rect2(Vector2.ONE * ( - size * 0.5), Vector2.ONE * size), source, color)
	draw_set_transform(Vector2.ZERO)


func _random_range(values: Array) -> float:
	return lerpf(values[0], values[1], _rng.randf())



static func sample_curve(keys: Array, time: float) -> float:
	if time <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		if time > keys[i][0]:
			continue
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		var span: float = b[0] - a[0]
		var t: float = (time - a[0]) / span
		var t2: float = t * t
		var t3: float = t2 * t
		return (2.0 * t3 - 3.0 * t2 + 1.0) * a[1] + (t3 - 2.0 * t2 + t) * span * a[3]\
		+ (-2.0 * t3 + 3.0 * t2) * b[1] + (t3 - t2) * span * b[2]
	return keys[-1][1]


func _sample_gradient(time: float) -> Color:
	var color: Array = config.color_keys[-1]
	for i in range(1, config.color_keys.size()):
		var a: Array = config.color_keys[i - 1]
		var b: Array = config.color_keys[i]
		if time <= b[0]:
			var weight: float = clampf((time - a[0]) / (b[0] - a[0]), 0.0, 1.0)
			color = [time, lerpf(a[1], b[1], weight), lerpf(a[2], b[2], weight), lerpf(a[3], b[3], weight)]
			break
	var alpha: float = config.alpha_keys[-1][1]
	for i in range(1, config.alpha_keys.size()):
		var a: Array = config.alpha_keys[i - 1]
		var b: Array = config.alpha_keys[i]
		if time <= b[0]:
			alpha = lerpf(a[1], b[1], clampf((time - a[0]) / (b[0] - a[0]), 0.0, 1.0))
			break
	return Color(color[1], color[2], color[3], alpha)
