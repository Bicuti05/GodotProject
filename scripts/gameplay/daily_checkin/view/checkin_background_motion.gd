extends Node

signal meteor_due

var rng: = RandomNumberGenerator.new()
var next_meteor_at: = 0.0
var active: = false
var paused: = false
var focus_active: = false
var elapsed: = 0.0
var clouds: Array[Dictionary] = []
var stars: Array[Dictionary] = []
var glow: Sprite2D
var glow_scale: = Vector2.ONE

func _ready() -> void :
	rng.randomize()

func set_meteor_seed(value: int) -> void :
	rng.seed = value

func add_cloud(sprite: Sprite2D, amplitude: Vector2, period: float) -> void :
	clouds.append({"node": sprite, "home": sprite.position, "amplitude": amplitude, "period": period})

func add_star(sprite: Sprite2D, index: int) -> void :
	stars.append({"node": sprite, "home": sprite.position, "scale": sprite.scale, "alpha": sprite.modulate.a, "phase": index * 0.73})

func set_glow(sprite: Sprite2D) -> void :
	glow = sprite
	glow_scale = sprite.scale

func start() -> void :
	stop()
	active = true
	next_meteor_at = rng.randf_range(0.55, 1.35)

func stop() -> void :
	active = false
	paused = false
	focus_active = false
	elapsed = 0.0
	for item in clouds:
		item.node.position = item.home
	for item in stars:
		item.node.position = item.home
		item.node.scale = item.scale
		item.node.modulate.a = item.alpha
	if is_instance_valid(glow):
		glow.scale = glow_scale

func set_focus(value: bool) -> void :
	focus_active = value

	next_meteor_at = elapsed + rng.randf_range(0.35, 0.7)

func _process(delta: float) -> void :
	if not active or paused:
		return
	elapsed += delta
	if elapsed >= next_meteor_at:
		next_meteor_at = elapsed + rng.randf_range(0.35, 0.7)
		if not focus_active: meteor_due.emit()
	for item in clouds:
		var phase: float = elapsed * TAU / item.period
		item.node.position = item.home + Vector2(sin(phase) * item.amplitude.x, sin(phase * 0.63) * item.amplitude.y)
	for item in stars:
		var wave: float = sin(elapsed * TAU / 3.6 + item.phase)
		item.node.modulate.a = item.alpha * (0.65 + wave * 0.3)
		item.node.scale = item.scale * (1.0 + wave * 0.07)
		item.node.position = item.home + Vector2(sin(elapsed * 0.55 + item.phase) - sin(item.phase), sin(elapsed * 0.45 + item.phase) - sin(item.phase)) * 5.0
	if is_instance_valid(glow):

		glow.scale = glow_scale * (1.0 + sin(elapsed * TAU / 5.2) * 0.025)
