extends Node2D

var particles: Array[Dictionary] = []
var rng: = RandomNumberGenerator.new()
var paused: = false
var _ring_position: = Vector2.ZERO
var _ring_age: = 1.0
var _ring_color: = Color.WHITE

func _ready() -> void :
	rng.seed = 7814

func clear() -> void :
	particles.clear()
	_ring_age = 1.0
	paused = false
	queue_redraw()

func ring(center: Vector2, color: Color) -> void :
	_ring_position = center
	_ring_color = color
	_ring_age = 0.0

func burst(center: Vector2, count: int, confetti: bool = false, cone: Vector2 = Vector2( - PI, 0.0)) -> void :
	var colors: = [Color("ffe35b"), Color("b8ed55"), Color("42ccec"), Color("ed7acf"), Color("ff866b")]
	for index in count:
		var angle: = rng.randf_range(cone.x, cone.y) if confetti else rng.randf_range(0.0, TAU)
		var speed: = rng.randf_range(260.0, 610.0) if confetti else rng.randf_range(70.0, 220.0)
		particles.append({
			"position": center + Vector2(rng.randf_range(-22, 22), rng.randf_range(-15, 15)), 
			"velocity": Vector2.from_angle(angle) * speed, 
			"life": rng.randf_range(0.95, 1.45) if confetti else rng.randf_range(0.3, 0.6), 
			"age": 0.0, "color": colors[index % colors.size()] if confetti else Color("fff5b4"), 
			"rotation": rng.randf_range(0.0, TAU), "spin": rng.randf_range(-6.0, 6.0), 
			"size": rng.randf_range(8.0, 14.0) if confetti else rng.randf_range(2.0, 5.0), 
			"confetti": confetti, 
		})

func _process(delta: float) -> void :
	if paused:
		return
	if particles.is_empty() and _ring_age >= 0.65:
		return
	_ring_age += delta
	for particle in particles:
		particle.age += delta
		particle.position += particle.velocity * delta
		particle.velocity.y += (350.0 if particle.confetti else 18.0) * delta
		particle.rotation += particle.spin * delta
	particles = particles.filter( func(particle: Dictionary) -> bool: return particle.age < particle.life)
	queue_redraw()

func _draw() -> void :
	if _ring_age < 0.65:
		var t: = _ring_age / 0.65
		var color: = _ring_color
		color.a = (1.0 - t) * 0.65
		draw_arc(_ring_position, lerpf(38.0, 112.0, t), 0.0, TAU, 64, color, lerpf(6.0, 1.0, t), true)
	for particle in particles:
		var color: Color = particle.color
		color.a = clampf((particle.life - particle.age) / 0.25, 0.0, 1.0)
		if particle.confetti:
			draw_set_transform(particle.position, particle.rotation, Vector2(1.0, cos(particle.age * 8.0)))
			draw_rect(Rect2(Vector2( - particle.size * 0.35, - particle.size * 0.6), Vector2(particle.size * 0.7, particle.size * 1.2)), color)
		else:
			draw_circle(particle.position, particle.size, color)
	draw_set_transform(Vector2.ZERO)
