extends Node2D



var rays: Array[Node2D] = []
var glow: Sprite2D
var burst: CPUParticles2D
var tweens: Array[Tween] = []
var playing: = false
var speed: = 1.0

func _ready() -> void :
	rays = [$Ray1, $Ray2]
	glow = $Glow
	burst = $Burst
	reset()

func play_feedback(object_size: Vector2, hero_mode: bool = false, playback_speed: float = 1.0) -> void :
	reset()
	show()
	playing = true
	speed = playback_speed
	var width: = maxf(object_size.x, 1.0)
	var radius: = width * (0.62 if hero_mode else 0.72)
	for index in 2:
		var ray: = rays[index]
		var base: = radius * (1.0 if index == 0 else 0.82)
		ray.rotation = 0.0 if index == 0 else deg_to_rad(15)
		ray.scale = Vector2.ONE * base * 0.65
		ray.modulate.a = 0.0
		var grow: = _tween()
		grow.tween_property(ray, "scale", Vector2.ONE * base * 1.14, 0.224 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		grow.tween_property(ray, "scale", Vector2.ONE * base, 0.496 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var fade: = _tween()
		fade.tween_property(ray, "modulate:a", 0.14 if hero_mode else 0.24, 0.32 / speed)
		fade.tween_property(ray, "modulate:a", 0.0, 0.4 / speed)
		_tween().tween_property(ray, "rotation", ray.rotation + deg_to_rad(38.8) * (1 if index == 0 else -1), 0.72 / speed)
	glow.scale = Vector2.ONE * width * (1.55 if hero_mode else 2.3) / glow.texture.get_width()
	glow.modulate = Color(1, 0.94, 0.7, 0)
	var light: = _tween()
	light.tween_property(glow, "modulate:a", 0.22 if hero_mode else 0.38, 0.4 / speed)
	light.tween_property(glow, "modulate:a", 0.0, 0.9 / speed)
	light.tween_callback( func() -> void : playing = false;hide())
	burst.amount = 14 if hero_mode else 12
	burst.emission_sphere_radius = width * 0.47
	burst.initial_velocity_min = 120 if hero_mode else 65
	burst.initial_velocity_max = 240 if hero_mode else 140
	burst.speed_scale = speed
	burst.show()
	burst.restart()
	burst.emitting = true

func reset() -> void :
	for tween in tweens:
		if tween.is_valid(): tween.kill()
	tweens.clear()
	playing = false
	if is_instance_valid(burst):
		burst.emitting = false
		burst.hide()
	hide()

func suspend(value: bool) -> void :
	for tween in tweens:
		if tween.is_valid():
			if value: tween.pause()
			else: tween.play()
	if is_instance_valid(burst): burst.speed_scale = 0.0 if value else speed

func _tween() -> Tween:
	var tween: = create_tween().set_ignore_time_scale(true)
	tweens.append(tween)
	return tween

func _exit_tree() -> void :
	reset()
