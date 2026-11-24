extends Node2D

@export var light_texture: Texture2D
var rings: Array[Sprite2D] = []
var running: bool = false
var paused: bool = false
var clock: float = 0.0
var exit_clock: float = -1.0
var follow_origin: Vector2 = Vector2.ZERO
var exit_duration: float = 0.55
func _ready() -> void :
	rings.assign([$Wave1, $Wave2, $Wave3])
	stop()
func play(at: Vector2) -> void :
	position = at
	follow_origin = at
	clock = 0
	exit_clock = -1
	running = true
	paused = false
	show()
	_sample()
func retire() -> void :
	if running and exit_clock < 0.0: exit_clock = 0.0
func follow_lift(at: Vector2, progress: float) -> void :
	if not running or exit_clock < 0.0:
		return


	var p: float = clampf(progress, 0.0, 0.8)
	var displacement_fraction: float = 0.55 * (p - p * p / 1.6)
	var full_displacement: Vector2 = (at - follow_origin) / maxf(progress, 0.0001)
	position = follow_origin + full_displacement * displacement_fraction

func _process(delta: float) -> void :
	if not running or paused: return
	clock += delta
	if exit_clock >= 0: exit_clock += delta
	_sample()

	if clock >= 1.29 or exit_clock >= exit_duration: stop()
func _sample() -> void :


	var tail: float = clampf((clock - 0.18) / 1.07, 0.0, 1.0)
	var envelope: float = 1.0 - smoothstep(0.0, 1.0, tail)
	if exit_clock >= 0.0:
		envelope *= 1.0 - smoothstep(0.0, exit_duration, exit_clock)
	for i in rings.size():
		var t: float = clampf((clock - i * 0.13) / 0.6, 0, 1)
		var r: Sprite2D = rings[i]
		(r.material as ShaderMaterial).set_shader_parameter("wave_progress", t)
		(r.material as ShaderMaterial).set_shader_parameter("tail_progress", tail)
		var start_size: float = [920.0, 810.0, 710.0][i]
		var end_size: float = [1380.0, 1170.0, 1000.0][i]
		r.scale = Vector2.ONE * lerpf(start_size, end_size, 1 - pow(1 - t, 2)) / float(light_texture.get_width())
		r.modulate.a = smoothstep(0.0, 0.1, clock - i * 0.13) * [0.44, 0.22, 0.1][i] * envelope
func suspend(value: bool) -> void : paused = value
func stop() -> void :
	running = false
	paused = false
	clock = 0
	exit_clock = -1
	hide()
	for r in rings: r.modulate.a = 0
