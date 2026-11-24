extends Node2D

var running: bool = false
var paused: bool = false
var clock: float = 0.0
@onready var emitters: Array[MultiMeshInstance2D] = [$LeftRibbon, $LeftSparkle, $RightRibbon, $RightSparkle]

func _ready() -> void :
	stop()

func configure_layout(screen_rect: Rect2) -> void :
	for i in emitters.size():
		var emitter: MultiMeshInstance2D = emitters[i]
		emitter.position = Vector2(screen_rect.position.x - 40.0 if i < 2 else screen_rect.end.x + 40.0, screen_rect.get_center().y)
		emitter.emission_rect_extents = Vector2(16.0, screen_rect.size.y * 0.4)

func play() -> void :
	clock = 0.0
	running = true
	paused = false
	show()
	for emitter in emitters:
		emitter.restart()
		emitter.set_process(false)

func _process(delta: float) -> void :
	if not running or paused:
		return
	clock += delta
	for emitter in emitters:
		emitter._process(delta)
		if emitter.material is ShaderMaterial:
			emitter.material.set_shader_parameter("motion_time", clock)
	if clock >= 4.2:
		stop()

func suspend(value: bool) -> void :
	paused = value

func stop() -> void :
	running = false
	paused = false
	clock = 0.0
	hide()
	for emitter in emitters:
		emitter.clear()
		emitter.set_process(false)
