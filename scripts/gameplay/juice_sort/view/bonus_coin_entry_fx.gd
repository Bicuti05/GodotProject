class_name BonusCoinEntryFx
extends Node2D


const LIFE: float = 0.28
const CONFIRM_DURATION: float = 0.36
@export var receive_shader: Shader
@export var impact_star_texture: Texture2D
var _impact_stars: Array[CPUParticles2D] = []
var _strong_impact: bool = false
const STAGGER: float = 0.045
@export var coin_texture: Texture2D
@export var point_texture: Texture2D
@export var star_texture: Texture2D
var _particles: Array[Sprite2D] = []
var _count: int = 0
var _age: float = 0.0
var _running: bool = false
var _center: Vector2
var _burst_coins: Array[Sprite2D] = []
var _burst_origins: Array[Vector2] = []
var _burst_age: float = -1.0
var _burst_active: bool = false
var _receive: Sprite2D
var _receive_material: ShaderMaterial
var _pig_target: Node2D
var _pig_scale: Vector2 = Vector2.ONE

func _ready() -> void :
	var material: = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i: int in range(30):
		var particle: = Sprite2D.new()
		particle.texture = star_texture if i % 5 == 3 else point_texture
		particle.material = material
		particle.hide()
		add_child(particle)
		_particles.append(particle)
	_receive = Sprite2D.new()
	_receive_material = ShaderMaterial.new()
	_receive_material.shader = receive_shader
	_receive.material = _receive_material
	_receive.hide()
	add_child(_receive)
	for i: int in range(12):
		var coin: = Sprite2D.new()
		coin.texture = coin_texture
		coin.hide()
		add_child(coin)
		_burst_coins.append(coin)
	reset()

func start(center: Vector2, count: int, pig: Node2D = null, strong_impact: bool = false) -> void :
	reset(strong_impact)
	_strong_impact = strong_impact
	_center = center
	_pig_target = pig
	if is_instance_valid(pig):
		_pig_scale = pig.scale
		var body: Sprite2D = pig.get_node("Body") as Sprite2D
		_receive.texture = body.texture
		_receive.global_transform = body.global_transform
	if strong_impact:
		_emit_impact_stars(center)
	_count = clampi(count, 1, 6)
	_running = true
	show()
	set_process(true)

func reset(keep_stars: bool = false) -> void :
	if not keep_stars:
		for stars: CPUParticles2D in _impact_stars:
			stars.emitting = false
			stars.hide()
	_strong_impact = false
	if is_instance_valid(_pig_target):
		_pig_target.scale = _pig_scale
	_pig_target = null
	if _receive != null:
		_receive.hide()
	_running = false
	_age = 0.0
	_burst_active = false
	for coin: Sprite2D in _burst_coins:
		coin.hide()
	set_process(false)
	for particle: Sprite2D in _particles:
		particle.hide()
	hide()

func is_running() -> bool:
	return _running or _stars_running()

func _process(delta: float) -> void :
	if _burst_active:
		_sample_burst(delta)
		return
	_age += delta
	for event: int in range(_count):
		var t: float = _age - event * STAGGER
		for j: int in range(5):
			var particle: Sprite2D = _particles[event * 5 + j]
			if t < 0.0 or t >= LIFE:
				particle.hide()
				continue
			var phase: float = clampf(t / LIFE, 0.0, 1.0)
			var position: Vector2
			var diameter: float
			var alpha: float
			if j < 2:

				var side: float = -1.0 if j == 0 else 1.0
				position = _center + Vector2(side * 34.0, -12.0) * (1.0 - smoothstep(0.0, 0.1, t))
				diameter = 30.0
				alpha = smoothstep(0.0, 0.025, t) * (1.0 - smoothstep(0.07, 0.12, t)) * 0.7
			elif j == 2:

				position = _center
				diameter = 46.0 * (1.0 - phase * 0.35)
				alpha = smoothstep(0.0, 0.02, t) * (1.0 - smoothstep(0.035, 0.11, t)) * 0.65
			else:
				var side: float = -1.0 if (event + j) % 2 == 0 else 1.0
				var width: float = 160.0
				if is_instance_valid(_pig_target):
					var body: Sprite2D = _pig_target.get_node("Body") as Sprite2D
					width = (body.global_transform * body.get_rect()).size.x
				position = _center + Vector2(side * width * 0.26, width * 0.24)
				diameter = 36.0 if j == 3 else 28.0
				alpha = smoothstep(0.05, 0.11, t) * (1.0 - smoothstep(0.15, LIFE, t)) * 0.75
			particle.global_position = position
			particle.scale = Vector2.ONE * diameter / particle.texture.get_width()
			particle.modulate = Color(1.0, 0.88, 0.52, alpha)
			particle.show()
	var last: float = float(_count - 1) * STAGGER

	_receive.hide()
	if is_instance_valid(_pig_target):
		var confirm_age: float = _age - last
		var press: float = smoothstep(0.0, 0.055, confirm_age)
		var release: float = smoothstep(0.055, 0.22, confirm_age)
		var response: float = press * (1.0 - release)
		_pig_target.scale = _pig_scale * Vector2(1.0 + response * (0.16 if _strong_impact else 0.035), 1.0 - response * (0.13 if _strong_impact else 0.025))
	if _age >= last + 0.28 and not _stars_running():
		reset()


func start_coin_burst(origins: Array[Vector2]) -> void :
	reset()
	if origins.is_empty():
		return
	_burst_origins = origins.duplicate()
	_burst_age = 0.0
	_burst_active = true
	_running = true
	show()
	set_process(true)

func _sample_burst(delta: float) -> void :
	_burst_age += delta
	var count: int = mini(_burst_coins.size(), _burst_origins.size() * 2)
	for i: int in range(_burst_coins.size()):
		var coin: Sprite2D = _burst_coins[i]
		if i >= count:
			coin.hide()
			continue
		var row: int = i / 2
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var t: float = _burst_age - float(row) * 0.018
		if t < 0.0 or t >= 0.3:
			coin.hide()
			continue

		var origin: Vector2 = _burst_origins[row]
		var outward: float = 1.0 - exp( - t / 0.1)
		coin.global_position = origin + Vector2(side * (45.0 + 42.0 * outward), -12.0 - 25.0 * outward + float(row % 2) * 12.0)
		coin.rotation = side * t * 1.3
		coin.scale = Vector2.ONE * (34.0 if i % 2 == 0 else 42.0) / coin_texture.get_width()
		coin.modulate.a = smoothstep(0.0, 0.035, t) * (1.0 - smoothstep(0.1, 0.3, t)) * 0.85
		coin.show()
	if _burst_age >= 0.3 + float(_burst_origins.size() - 1) * 0.018:
		reset()

func _stars_running() -> bool:
	for stars: CPUParticles2D in _impact_stars:
		if stars.visible:
			return true
	return false

func _emit_impact_stars(center: Vector2) -> void :
	var stars: CPUParticles2D = null
	for candidate: CPUParticles2D in _impact_stars:
		if not candidate.visible:
			stars = candidate
			break
	if stars == null:
		stars = CPUParticles2D.new()
		stars.texture = impact_star_texture
		stars.amount = 11
		stars.lifetime = 0.28
		stars.speed_scale = 0.7
		stars.one_shot = true
		stars.explosiveness = 1.0
		stars.randomness = 0.2
		stars.local_coords = false
		stars.direction = Vector2.UP
		stars.spread = 130.0
		stars.gravity = Vector2(0, 360)
		stars.initial_velocity_min = 288.0
		stars.initial_velocity_max = 504.0
		stars.angular_velocity_min = -240.0
		stars.angular_velocity_max = 240.0
		stars.scale_amount_min = 0.28
		stars.scale_amount_max = 0.45
		var fade: = Gradient.new()
		fade.offsets = PackedFloat32Array([0, 0.45, 0.72, 1])
		fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		stars.color_ramp = fade
		var size_curve: = Curve.new()
		for point: Vector2 in [Vector2(0, 0.65), Vector2(0.12, 1), Vector2(0.5, 0.9), Vector2(1, 0)]:
			size_curve.add_point(point)
		stars.scale_amount_curve = size_curve
		add_child(stars)
		stars.finished.connect(stars.hide)
		_impact_stars.append(stars)
	stars.global_position = center
	stars.global_scale = Vector2.ONE * 0.5
	stars.show()
	stars.restart()

func _exit_tree() -> void :
	AudioManager.stop_sfx(&"bonus_coin_impact")
