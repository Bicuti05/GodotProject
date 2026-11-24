extends Node2D
var running: bool = false
var paused: bool = false
@onready var emitter: MultiMeshInstance2D = $Emitter

func _ready() -> void :
	stop()

func configure_layout(screen_rect: Rect2) -> void :
	position = Vector2(screen_rect.get_center().x, screen_rect.position.y - 75.0)
	emitter.emission_rect_extents = Vector2(screen_rect.size.x * 0.5, 75.0)

func start() -> void :
	if running:
		return
	paused = false
	running = true
	show()
	emitter.restart()
	emitter.set_process(false)

func _process(delta: float) -> void :
	if not running or paused:
		return
	emitter._process(delta)
	emitter.material.set_shader_parameter("motion_time", emitter._clock)

func suspend(value: bool) -> void :
	paused = value

func stop() -> void :
	running = false
	paused = false
	hide()
	if is_instance_valid(emitter):
		emitter.clear()
		emitter.set_process(false)
		emitter.material.set_shader_parameter("motion_time", 0.0)
