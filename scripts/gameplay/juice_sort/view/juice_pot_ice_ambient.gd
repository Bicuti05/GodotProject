class_name JuicePotIceAmbient
extends Node2D

const PARTICLE_COUNT: int = 9
const SNOWFLAKE_COUNT: int = 9
const FLAKE_COUNT: int = PARTICLE_COUNT + SNOWFLAKE_COUNT
const FACE_POSITIONS: Array[Vector2] = [Vector2(0.28, 0.3), Vector2(0.65, 0.39), 
	Vector2(0.36, 0.63), Vector2(0.71, 0.72)]
const REFERENCE_CYCLE: float = 2.0
const REFERENCE_DIAMETER: float = 5.286 / 114.4
const SOFT_SNOWFLAKE_TEXTURE: Texture2D = preload("res://assets/effect/texture/ice/ice_snowflake_soft.png")
const SNOWFLAKE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_01.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_02.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_03.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_04.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_05.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_06.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_07.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_08.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_09.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_10.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_11.png"), 
	preload("res://assets/effect/texture/ice/ice_snowflake_figma_12.png")]
const SNOWFLAKE_SHADER: Shader = preload("res://scripts/gameplay/juice_sort/view/ice_snowflake_mask.gdshader")

var _flakes: Array[Dictionary] = []
var _rectangle: Rect2 = Rect2()
var _emitting: bool = false
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void :
	var snow_material: ShaderMaterial = ShaderMaterial.new()
	snow_material.shader = SNOWFLAKE_SHADER
	material = snow_material
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _ready() -> void :
	_random.randomize()
	stop()


func _exit_tree() -> void :
	stop()


func set_surface(surface: Transform2D, rectangle: Rect2) -> void :
	global_transform = surface
	_rectangle = rectangle


func set_emitting(enabled: bool) -> void :
	if enabled == _emitting:
		return
	if not enabled:
		stop()
		return
	_emitting = true
	for index: int in FLAKE_COUNT:
		var flake: Dictionary = _new_flake(index)
		flake["age"] = float(flake["lifetime"]) * (float(index % PARTICLE_COUNT) + _random.randf()) / PARTICLE_COUNT
		_flakes.append(flake)
	show()
	set_process(true)
	queue_redraw()


func _new_flake(index: int) -> Dictionary:
	var snowflake: bool = index >= PARTICLE_COUNT
	var type_index: int = index - PARTICLE_COUNT if snowflake else index
	var spawn_index: int = type_index + floori(float(type_index) / 3.0)
	var spawn: Vector2 = Vector2(_random.randf_range(0.18, 0.82), 
		_random.randf_range(0.03, 0.16))
	var rise: float = _random.randf_range(0.24, 0.38)
	if spawn_index < FACE_POSITIONS.size():
		spawn = FACE_POSITIONS[spawn_index] + Vector2(_random.randf_range(-0.06, 0.06), 
			_random.randf_range(-0.07, 0.07))
		rise = _random.randf_range(0.14, 0.26)
	elif spawn_index >= 8:
		spawn.x = _random.randf_range(0.04, 0.17) if _random.randf() < 0.5\
		else _random.randf_range(0.83, 0.96)
		spawn.y = _random.randf_range(0.28, 0.76)
		rise = _random.randf_range(0.3, 0.5)
	var size_factor: float = _random.randf_range(0.36, 0.56)
	if index % 3 == 1:
		size_factor = _random.randf_range(0.65, 0.82)
	elif index % 3 == 2:
		size_factor = _random.randf_range(0.94, 1.08)
	if snowflake:
		size_factor = _random.randf_range(1.12, 1.3) if type_index % 2 == 0\
		else _random.randf_range(1.45, 1.65)
		size_factor *= 0.8
		rise *= _random.randf_range(0.7, 0.88)
	var diameter: float = REFERENCE_DIAMETER * size_factor
	var lifetime: float = REFERENCE_CYCLE * (_random.randf_range(1.05, 1.38) if snowflake\
	else _random.randf_range(0.72, 1.05))
	var opacity: float = _random.randf_range(0.62, 0.84) if snowflake else _random.randf_range(0.7, 0.95)
	var drift_factor: float = 0.65 if snowflake else 1.0
	return {"age": 0.0, "lifetime": lifetime, 
		"position": _rectangle.position + _rectangle.size * spawn, 
		"rise": _rectangle.size.y * rise, 
		"drift": _rectangle.size.x * _random.randf_range(-0.055, 0.055) * drift_factor, 
		"spread": signf(spawn.x - 0.5) * _rectangle.size.x * _random.randf_range(0.025, 0.065), 
		"sway": _rectangle.size.x * _random.randf_range(0.014, 0.036) * drift_factor, 
		"wave": _random.randf_range(0.4, 0.82), 
		"phase": _random.randf_range(0.0, TAU), 
		"spin": _random.randf_range(-0.65, 0.65) if snowflake else _random.randf_range(-0.24, 0.24), 
		"snowflake": snowflake, "size": _rectangle.size.x * diameter, "opacity": opacity, 
		"glow_size": 1.9 if snowflake else 2.2, "glow_opacity": 0.42 if snowflake else 0.3, 
		"texture": SNOWFLAKE_TEXTURES[index % SNOWFLAKE_TEXTURES.size()]}


func stop() -> void :
	_emitting = false
	_flakes.clear()
	hide()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void :
	if not is_visible_in_tree():
		return
	for index: int in _flakes.size():
		var flake: Dictionary = _flakes[index]
		flake["age"] = float(flake["age"]) + delta
		if float(flake["age"]) >= float(flake["lifetime"]):
			var replacement: Dictionary = _new_flake(index)
			replacement["age"] = - _random.randf_range(0.04, 0.18)
			_flakes[index] = replacement
	queue_redraw()


func _draw() -> void :
	for flake: Dictionary in _flakes:
		var age: float = float(flake["age"])
		if age <= 0.0:
			continue
		var progress: float = age / float(flake["lifetime"])
		var phase: float = float(flake["phase"])
		var position: Vector2 = flake["position"]
		position += Vector2(float(flake["drift"]) * progress + float(flake["spread"]) * (1.0 - exp(-4.0 * progress)) + 
			(sin(phase + progress * TAU * float(flake["wave"])) - sin(phase)) * float(flake["sway"]), 
			- float(flake["rise"]) * progress)
		var reveal: float = smoothstep(0.0, 0.12, progress)
		var opacity: float = float(flake["opacity"]) * reveal\
		* (1.0 - smoothstep(0.54, 0.94, progress))
		var diameter: float = float(flake["size"]) * lerpf(0.35, 1.06, reveal)\
		* lerpf(1.0, 0.35 / 1.06, smoothstep(0.5, 0.98, progress))
		var snowflake: bool = bool(flake["snowflake"])
		if not snowflake:
			opacity *= lerpf(0.78, 1.0, 0.5 + 0.5 * sin(phase + progress * TAU * 1.2))
		var glow_diameter: float = diameter * float(flake["glow_size"])
		draw_set_transform(position, phase + float(flake["spin"]) * age)
		draw_texture_rect(flake["texture"], 
			Rect2(Vector2.ONE * - glow_diameter * 0.5, Vector2.ONE * glow_diameter), false, 
			Color(1.0, 1.0, 1.0, opacity * float(flake["glow_opacity"])))
		if snowflake:
			var snow_diameter: float = diameter * 1.5
			draw_texture_rect(SOFT_SNOWFLAKE_TEXTURE, 
				Rect2(Vector2.ONE * - snow_diameter * 0.5, Vector2.ONE * snow_diameter), false, 
				Color(1.0, 1.0, 1.0, opacity))
		else:
			draw_texture_rect(flake["texture"], 
				Rect2(Vector2.ONE * - diameter * 0.5, Vector2.ONE * diameter), false, 
				Color(1.0, 1.0, 1.0, opacity))
	draw_set_transform_matrix(Transform2D.IDENTITY)
