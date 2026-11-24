class_name SunlightFx
extends Control

signal finished

const BACK_ICE_MELT_DURATION_SCALE: float = 1.15

@export var settings: SunlightFxSettings
@onready var _rays: ColorRect = $Rays
@onready var _shader: ShaderMaterial = $Rays.material as ShaderMaterial
var _flowers: Array[Node2D] = []
var _clock: float = 0.0
var _running: bool = false
var _paused: bool = false
var _speed: float = 1.0
var _ice_origins: PackedVector2Array = PackedVector2Array()
var _ice_axes: PackedVector4Array = PackedVector4Array()


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings = settings.duplicate() as SunlightFxSettings
	stop()


func _exit_tree() -> void :
	stop()


func prepare(bounds: Rect2, flowers: Array, options: SunlightFxSettings = null) -> void :
	stop()
	if options != null:
		settings = options.duplicate() as SunlightFxSettings
	position = bounds.position
	size = bounds.size.max(Vector2.ONE)
	_rays.size = size
	_flowers.assign(flowers)
	_shader.set_shader_parameter("area_size", size)
	_shader.set_shader_parameter("reveal_duration", settings.light_reveal_duration)
	_shader.set_shader_parameter("fade_start", settings.fade_in + settings.hold)
	_shader.set_shader_parameter("fade_end", settings.fade_in + settings.hold + settings.fade_out)
	_shader.set_shader_parameter("light_enabled", settings.light_enabled)
	_shader.set_shader_parameter("drops_enabled", settings.drops_enabled)
	_shader.set_shader_parameter("drop_count", clampi(settings.drop_count, 0, 8))
	_shader.set_shader_parameter("drop_size", maxf(0.01, settings.drop_size))
	_shader.set_shader_parameter("melt_delay", settings.melt_delay)
	_shader.set_shader_parameter("melt_duration", settings.melt_duration)
	for flower: Node2D in _flowers:
		if is_instance_valid(flower):
			flower.call("set_frost_visible", settings.frost_enabled)
	show()
	set_clock(0.0)


func play(bounds: Rect2, flowers: Array, options: SunlightFxSettings = null) -> void :
	prepare(bounds, flowers, options)
	_running = true
	_paused = false
	set_process(true)


func set_clock(clock: float, melt_enabled: bool = true) -> void :
	_clock = maxf(0.0, clock)
	var envelope: float = smoothstep(0.0, settings.fade_in, _clock)\
	* (1.0 - smoothstep(settings.fade_in + settings.hold, 
		settings.fade_in + settings.hold + settings.fade_out, _clock))
	var melt: float = clampf((_clock - settings.melt_delay) / settings.melt_duration, 0.0, 1.0)\
	if melt_enabled else 0.0
	var back_melt: float = clampf((_clock - settings.melt_delay)
		/ (settings.melt_duration * BACK_ICE_MELT_DURATION_SCALE), 0.0, 1.0)\
		if melt_enabled else 0.0
	_shader.set_shader_parameter("clock", _clock)
	_shader.set_shader_parameter("envelope", envelope)
	_shader.set_shader_parameter("melt_enabled", melt_enabled)
	var origins: PackedVector2Array = PackedVector2Array()
	var axes: PackedVector4Array = PackedVector4Array()
	var canvas_inverse: Transform2D = _rays.get_global_transform_with_canvas().affine_inverse()
	for flower: Node2D in _flowers:
		if is_instance_valid(flower):
			flower.call("set_melt_progress", melt, back_melt)
			if origins.size() < 8:
				var ice_transform: Transform2D = canvas_inverse * (flower.call("ice_surface_transform") as Transform2D)
				origins.append(ice_transform.origin)
				axes.append(Vector4(ice_transform.x.x, ice_transform.x.y, 
					ice_transform.y.x, ice_transform.y.y))
	if not _flowers.is_empty():
		_ice_origins = origins
		_ice_axes = axes
	_shader.set_shader_parameter("ice_count", _ice_origins.size())
	var render_origins: PackedVector2Array = _ice_origins.duplicate()
	var render_axes: PackedVector4Array = _ice_axes.duplicate()
	render_origins.resize(8)
	render_axes.resize(8)
	_shader.set_shader_parameter("ice_origins", render_origins)
	_shader.set_shader_parameter("ice_axes", render_axes)


func finish_melting() -> void :
	for flower: Node2D in _flowers:
		if is_instance_valid(flower):
			flower.call("set_frozen", false)
	_flowers.clear()


func set_paused(paused: bool) -> void :
	_paused = paused


func set_speed(speed: float) -> void :
	_speed = maxf(0.1, speed)


func ice_melt_duration() -> float:
	return settings.melt_delay + settings.melt_duration * BACK_ICE_MELT_DURATION_SCALE


func is_running() -> bool:
	return _running


func stop() -> void :
	_running = false
	_clock = 0.0
	_flowers.clear()
	_ice_origins.clear()
	_ice_axes.clear()
	_shader.set_shader_parameter("clock", 0.0)
	_shader.set_shader_parameter("ice_count", 0)
	_shader.set_shader_parameter("melt_enabled", false)
	hide()
	set_process(false)


func _process(delta: float) -> void :
	if not _running or _paused:
		return
	set_clock(_clock + delta * _speed)
	if _clock >= settings.duration():
		for flower: Node2D in _flowers:
			if is_instance_valid(flower):
				flower.call("set_frozen", false)
		stop()
		finished.emit()
