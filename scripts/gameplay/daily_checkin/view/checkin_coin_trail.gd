extends CPUParticles2D

signal expired(node: CPUParticles2D)
var paused: bool = false
var retiring: bool = false
var retire_clock: float = 0.0

func _ready() -> void :
	reset()

func begin() -> void :
	retiring = false
	retire_clock = 0.0
	paused = false
	speed_scale = 1.0
	show()
	restart()
	emitting = true

func retire() -> void :
	emitting = false
	retiring = true
	retire_clock = 0.0

func suspend(value: bool) -> void :
	paused = value
	speed_scale = 0.0 if value else 1.0

func _process(delta: float) -> void :
	if retiring and not paused:
		retire_clock += delta
		if retire_clock >= 0.48:
			retiring = false
			expired.emit(self)

func reset() -> void :
	hide()
	restart()
	emitting = false
	speed_scale = 0.0
	paused = false
	retiring = false
	retire_clock = 0.0
