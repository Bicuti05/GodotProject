extends ColorRect

var running: bool = false
var paused: bool = false
var clock: float = 0.0
var strength: float = 0.0
var sweep_clock: float = -1.0
var arrival_fade: float = 1.0
var role_strength: float = 1.0
@onready var flow_material: ShaderMaterial = material

func _ready() -> void :
	stop()

func start() -> void :
	running = true
	paused = false
	show()

func expand_from(center: Vector2, intensity: float = 1.0) -> void :
	sweep_clock = 0.0
	arrival_fade = 1.0
	role_strength = intensity
	flow_material.set_shader_parameter("origin_uv", center)
	flow_material.set_shader_parameter("viewport_aspect", size.x / maxf(size.y, 1.0))

func set_arrival_fade(value: float) -> void :
	arrival_fade = clampf(value, 0.0, 1.0)

func _process(delta: float) -> void :
	if not running or paused:
		return
	clock += delta
	if sweep_clock >= 0.0:
		sweep_clock += delta
	var desired: float = arrival_fade * role_strength if sweep_clock >= 0.0 else 0.0
	strength = move_toward(strength, desired, delta * 6.0)
	flow_material.set_shader_parameter("motion_time", clock)
	flow_material.set_shader_parameter("strength", strength)
	flow_material.set_shader_parameter("sweep_time", sweep_clock)

func suspend(value: bool) -> void :
	paused = value

func stop() -> void :
	running = false
	paused = false
	clock = 0.0
	sweep_clock = -1.0
	arrival_fade = 1.0
	role_strength = 1.0
	strength = 0.0
	hide()
	if is_instance_valid(flow_material):
		flow_material.set_shader_parameter("motion_time", 0.0)
		flow_material.set_shader_parameter("strength", 0.0)
		flow_material.set_shader_parameter("sweep_time", -1.0)
