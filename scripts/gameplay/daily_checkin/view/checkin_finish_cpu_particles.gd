extends MultiMeshInstance2D




signal finished

@export var amount: int = 8
@export var lifetime: float = 1.0
@export var one_shot: bool = false
@export_range(0.0, 1.0) var explosiveness: float = 0.0
@export_range(0.0, 1.0) var randomness: float = 0.0
@export_range(0.0, 1.0) var lifetime_randomness: float = 0.0
@export var local_coords: bool = true
@export var emitting: bool = false:
	set(value):
		emitting = value
		set_process(emitting or _alive_count > 0)

@export_enum("Point:0", "Sphere:1", "Rectangle:3", "Points:4") var emission_shape: int = 0
@export var emission_sphere_radius: float = 1.0
@export var emission_rect_extents: Vector2 = Vector2.ONE
@export var emission_points: PackedVector2Array = PackedVector2Array()
@export var direction: Vector2 = Vector2.RIGHT
@export var spread: float = 45.0
@export var initial_velocity_min: float = 0.0
@export var initial_velocity_max: float = 0.0
@export var gravity: Vector2 = Vector2.ZERO
@export var damping_min: float = 0.0
@export var damping_max: float = 0.0
@export var radial_velocity_min: float = 0.0
@export var radial_velocity_max: float = 0.0
@export var radial_velocity_curve: Curve = null
@export var angle_min: float = 0.0
@export var angle_max: float = 0.0
@export var angular_velocity_min: float = 0.0
@export var angular_velocity_max: float = 0.0
@export var scale_amount_min: float = 1.0
@export var scale_amount_max: float = 1.0
@export var scale_amount_curve: Curve = null
@export var color: Color = Color.WHITE
@export var color_ramp: Gradient = null
@export var anim_offset_min: float = 0.0
@export var anim_offset_max: float = 0.0
@export var horizontal_sway: float = 0.0
@export var turbulence_enabled: bool = false
@export var turbulence_noise_scale: float = 1.5
@export_range(0.0, 1.0) var turbulence_influence_min: float = 0.03
@export_range(0.0, 1.0) var turbulence_influence_max: float = 0.05


const SIMULATION_FPS: float = 30.0
const BUFFER_STRIDE: int = 16

class Particle:
	extends RefCounted
	var active: bool = false
	var next_birth: float = 0.0
	var age: float = 0.0
	var life: float = 1.0
	var position: Vector2 = Vector2.ZERO
	var origin: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var radial_direction: Vector2 = Vector2.RIGHT
	var radial_speed: float = 0.0
	var damping: float = 0.0
	var angle: float = 0.0
	var angular_speed: float = 0.0
	var size: float = 1.0
	var anim_offset: float = 0.0
	var turbulence_influence: float = 0.0

var _particles: Array[Particle] = []
var _buffer: PackedFloat32Array = PackedFloat32Array()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _noise: FastNoiseLite = FastNoiseLite.new()
var _clock: float = 0.0
var _remainder: float = 0.0
var _alive_count: int = 0
var _started: bool = false


func _ready() -> void :
	prepare_pool()
	if emitting:
		restart()
	else:
		set_process(false)


func prepare_pool() -> void :
	if multimesh != null and _particles.size() == amount:
		return
	_particles.clear()
	for i in amount:
		_particles.append(Particle.new())
	_buffer.resize(amount * BUFFER_STRIDE)
	_buffer.fill(0.0)
	var tex_size: Vector2 = texture.get_size() if texture != null else Vector2.ONE

	var quad: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([
		- tex_size * 0.5, Vector2(tex_size.x, - tex_size.y) * 0.5, 
		tex_size * 0.5, Vector2( - tex_size.x, tex_size.y) * 0.5])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, 
		Vector2.ONE, Vector2.DOWN])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = quad

	multimesh.custom_aabb = AABB(Vector3(-2000, -3000, -1), Vector3(5000, 6500, 2))
	multimesh.instance_count = amount
	multimesh.visible_instance_count = 0
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE


func restart() -> void :
	prepare_pool()
	clear()
	_rng.randomize()
	_noise.seed = int(_rng.randi() & 2147483647)
	for i in amount:
		var phase: float = (float(i) + _rng.randf() * randomness) / float(amount)
		_particles[i].next_birth = phase * lifetime * (1.0 - explosiveness)
	_started = true
	emitting = true


func clear() -> void :
	emitting = false
	_started = false
	_clock = 0.0
	_remainder = 0.0
	_alive_count = 0
	for p: Particle in _particles:
		p.active = false
	_buffer.fill(0.0)
	if multimesh != null:
		multimesh.visible_instance_count = 0
	set_process(false)



func warm_render_pipeline() -> void :
	restart()
	_simulate_step(maxf(1.0 / SIMULATION_FPS, lifetime / float(amount)))
	_upload_particles()


func _process(delta: float) -> void :
	if not is_visible_in_tree():
		return
	_remainder += minf(delta, 0.25)
	var step: float = 1.0 / SIMULATION_FPS
	while _remainder >= step:
		_simulate_step(step)
		_remainder -= step
	_upload_particles()


func _simulate_step(delta: float) -> void :
	var end: float = _clock + delta
	_alive_count = 0
	for p: Particle in _particles:
		var particle_delta: float = delta
		if emitting and p.next_birth <= end:
			_spawn(p)
			particle_delta = minf(delta, maxf(0.0, end - p.next_birth))
			p.next_birth += lifetime
		if not p.active:
			continue
		_move_particle(p, particle_delta)
		if p.age >= p.life:
			p.active = false
		else:
			_alive_count += 1
	_clock = end

	if one_shot and _clock >= lifetime * (1.0 - explosiveness):
		emitting = false
	if _started and not emitting and _alive_count == 0:
		_started = false
		set_process(false)
		finished.emit()


func _spawn(p: Particle) -> void :
	p.active = true
	p.age = 0.0
	p.life = lifetime * (1.0 - _rng.randf() * lifetime_randomness)
	var birth: Vector2 = Vector2.ZERO
	match emission_shape:
		1: birth = Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf() * emission_sphere_radius
		3: birth = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * emission_rect_extents
		4:
			if not emission_points.is_empty():
				birth = emission_points[_rng.randi_range(0, emission_points.size() - 1)]
	p.origin = Vector2.ZERO if local_coords else global_position
	p.position = birth if local_coords else global_transform * birth
	var angle: float = direction.angle() + deg_to_rad(_rng.randf_range( - spread, spread))
	p.velocity = Vector2.RIGHT.rotated(angle) * _rng.randf_range(initial_velocity_min, initial_velocity_max)
	if not local_coords:
		p.velocity = global_transform.basis_xform(p.velocity)
	p.radial_direction = (p.position - p.origin).normalized()
	if p.radial_direction.is_zero_approx():
		p.radial_direction = Vector2.RIGHT.rotated(_rng.randf() * TAU)
	p.radial_speed = _rng.randf_range(radial_velocity_min, radial_velocity_max)
	p.damping = _rng.randf_range(damping_min, damping_max)
	p.angle = deg_to_rad(_rng.randf_range(angle_min, angle_max))
	p.angular_speed = deg_to_rad(_rng.randf_range(angular_velocity_min, angular_velocity_max))
	p.size = _rng.randf_range(scale_amount_min, scale_amount_max)
	p.anim_offset = _rng.randf_range(anim_offset_min, anim_offset_max)
	p.turbulence_influence = _rng.randf_range(turbulence_influence_min, turbulence_influence_max)


func _move_particle(p: Particle, delta: float) -> void :
	delta = minf(delta, maxf(0.0, p.life - p.age))
	var phase: float = (p.age + delta * 0.5) / p.life
	var radial: Vector2 = p.radial_direction * p.radial_speed
	if radial_velocity_curve != null:
		radial *= radial_velocity_curve.sample_baked(phase)
	p.velocity += gravity * delta
	if p.damping > 0.0:
		p.velocity = p.velocity.normalized() * maxf(0.0, p.velocity.length() - p.damping * delta)
	if turbulence_enabled and not p.velocity.is_zero_approx():


		var pos: Vector2 = p.position * (0.01 * turbulence_noise_scale)
		var noise_time: float = _clock * 0.2
		var noise_direction: Vector2 = Vector2(
			_noise.get_noise_3d(pos.x, pos.y, noise_time), 
			_noise.get_noise_3d(pos.x + 31.7, pos.y - 17.3, noise_time)).normalized()
		var influence: float = p.turbulence_influence
		p.velocity = p.velocity.lerp(noise_direction * p.velocity.length() * (1.0 + (1.0 - influence) * 0.2), influence)
	p.position += (p.velocity + radial) * delta
	if horizontal_sway > 0.0:
		p.position.x += sin(p.age * 1.8 + p.anim_offset * TAU) * horizontal_sway * delta
	p.age += delta


func _upload_particles() -> void :
	var inverse: Transform2D = Transform2D.IDENTITY if local_coords else global_transform.affine_inverse()
	var count: int = 0
	for p: Particle in _particles:
		if not p.active:
			continue
		var phase: float = clampf(p.age / p.life, 0.0, 1.0)
		var size: float = p.size
		if scale_amount_curve != null:
			size *= scale_amount_curve.sample_baked(phase)

		var xform: Transform2D = inverse * Transform2D( - (p.angle + p.angular_speed * p.age), Vector2.ONE * size, 0.0, p.position)
		var tint: Color = color
		if color_ramp != null:
			tint *= color_ramp.sample(phase)
		var offset: int = count * BUFFER_STRIDE
		_buffer[offset] = xform.x.x
		_buffer[offset + 1] = xform.y.x
		_buffer[offset + 2] = 0.0
		_buffer[offset + 3] = xform.origin.x
		_buffer[offset + 4] = xform.x.y
		_buffer[offset + 5] = xform.y.y
		_buffer[offset + 6] = 0.0
		_buffer[offset + 7] = xform.origin.y
		_buffer[offset + 8] = tint.r
		_buffer[offset + 9] = tint.g
		_buffer[offset + 10] = tint.b
		_buffer[offset + 11] = tint.a
		_buffer[offset + 12] = 0.0
		_buffer[offset + 13] = phase
		_buffer[offset + 14] = p.anim_offset
		_buffer[offset + 15] = p.life / lifetime
		count += 1

	if count > 0:
		multimesh.buffer = _buffer
	multimesh.visible_instance_count = count
