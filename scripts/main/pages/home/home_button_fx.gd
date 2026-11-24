class_name HomeButtonFx
extends Control

const DEFAULT_SETTINGS: Dictionary = {
	"sweep_enabled": true, 
	"stars_enabled": true, 
	"sweep_duration": 0.95, 
	"sweep_interval": 3.3, 
	"sweep_strength": 0.46, 
	"glow_strength": 0.9, 
	"breath_strength": 0.035, 
	"star_amount": 18, 
	"star_size": 42.0, 
	"star_lifetime": 1.9, 
	"star_speed": 30.0, 
}
const PARAMETER_DEFINITIONS: Array[Dictionary] = [
	{"key": "sweep_duration", "label": "扫光时长（秒）", "min": 0.5, "max": 1.8, "step": 0.05}, 
	{"key": "sweep_interval", "label": "扫光周期（秒）", "min": 2.4, "max": 7.0, "step": 0.1}, 
	{"key": "sweep_strength", "label": "扫光亮度", "min": 0.1, "max": 0.6, "step": 0.02}, 
	{"key": "glow_strength", "label": "描边柔光强度（0关闭）", "min": 0.0, "max": 1.5, "step": 0.05}, 
	{"key": "breath_strength", "label": "弹性呼吸幅度（0关闭）", "min": 0.0, "max": 0.06, "step": 0.005}, 
	{"key": "star_amount", "label": "星光数量", "min": 8.0, "max": 36.0, "step": 1.0}, 
	{"key": "star_size", "label": "星光大小", "min": 18.0, "max": 52.0, "step": 1.0}, 
	{"key": "star_lifetime", "label": "星光寿命（秒）", "min": 1.2, "max": 3.4, "step": 0.1}, 
	{"key": "star_speed", "label": "星光上浮速度", "min": 8.0, "max": 42.0, "step": 1.0}, 
]
const FIRST_SWEEP_DELAY: float = 0.35
const BREATH_DURATION: float = 1.55
const GLOW_MARGIN: float = 42.0
const STAR_SPAWN_HEIGHT_RATIO: float = 0.76
const STAR_ADDITIONAL_RISE_RATIO: float = 0.42
const PETAL_DURATION: float = 1.7

const PARTICLE_UPDATE_FRAMES: int = 2

@onready var _button: CommonBtn = get_parent() as CommonBtn
@onready var _face: NinePatchRect = get_parent().get_node("Tex") as NinePatchRect
@onready var _sweep: NinePatchRect = $Sweep
@onready var _glow: ColorRect = $Glow
@onready var _corner_gleams: Array[TextureRect] = [$Corners / LeftGleam, $Corners / RightGleam]
@onready var _petals: Array[TextureRect] = [
	$Petals / LeftPink, $Petals / LeftMint, $Petals / RightPink, $Petals / RightMint, 
]
@onready var _particles: Array[GPUParticles2D] = [
	$Stars / WhiteSoft, $Stars / YellowSoft, $Stars / WhiteRay, $Stars / YellowRay, 
]

var _settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var _enabled: bool = false
var _running: bool = false
var _application_active: bool = true
var _elapsed: float = 0.0
var _sweep_material: ShaderMaterial
var _glow_material: ShaderMaterial
var _visual_parts: Array[Dictionary] = []
var _star_rise_integral: float = 1.0
var _petal_origins: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _particle_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()


func _ready() -> void :
	_sweep_material = _sweep.material.duplicate() as ShaderMaterial
	_sweep.material = _sweep_material
	_glow_material = _glow.material.duplicate() as ShaderMaterial
	_glow.material = _glow_material
	for particles: GPUParticles2D in _particles:
		particles.process_material = particles.process_material.duplicate() as ParticleProcessMaterial
	_particle_lifecycle.prepare(_particles, PARTICLE_UPDATE_FRAMES, _can_animate)
	var star_material: ParticleProcessMaterial = _particles[0].process_material as ParticleProcessMaterial
	if star_material.directional_velocity_curve is CurveXYZTexture:
		_star_rise_integral = _measure_rise_integral((star_material.directional_velocity_curve as CurveXYZTexture).curve_y)
	for child: Node in _button.get_children():
		if child is Control:
			var part: Control = child as Control
			_visual_parts.append({"node": part, "scale": part.scale, "pivot": part.pivot_offset})
	_button.button_down.connect(_on_button_down)
	_apply_settings()
	set_effect_enabled(false)


func get_settings() -> Dictionary:
	return _settings.duplicate()


func set_settings(values: Dictionary) -> void :
	var next: Dictionary = DEFAULT_SETTINGS.duplicate()
	for key: String in ["sweep_enabled", "stars_enabled"]:
		if values.get(key) is bool:
			next[key] = values[key]
	for definition: Dictionary in PARAMETER_DEFINITIONS:
		var key: String = definition["key"]
		var value: Variant = values.get(key, next[key])
		if value is float or value is int:
			var number: float = float(value)
			if is_finite(number):
				next[key] = clampf(number, float(definition["min"]), float(definition["max"]))
	next["star_amount"] = int(next["star_amount"])
	if next == _settings:
		return
	_settings = next
	if is_node_ready():
		replay()
		_apply_settings()


func set_effect_enabled(enabled: bool) -> void :
	_enabled = enabled
	visible = enabled
	set_process(enabled)
	if not enabled and is_node_ready():
		_set_running(false)


func replay() -> void :
	_elapsed = 0.0
	_set_running(false)


func _process(delta: float) -> void :
	_set_running(_can_animate())
	if not _running:
		return
	if _sweep.texture != _face.texture:
		_sweep.texture = _face.texture
	_elapsed += delta
	var interval: float = float(_settings["sweep_interval"])
	var phase: float = fmod(_elapsed, interval) - FIRST_SWEEP_DELAY
	var breath_duration: float = minf(BREATH_DURATION, interval - FIRST_SWEEP_DELAY)
	var breath_progress: float = clampf(phase / breath_duration, 0.0, 1.0)
	var breath: float = _breath_pose(breath_progress)
	var glow_breath: float = maxf(0.0, breath)
	_apply_visual_pose(breath, breath_progress)
	_sweep_material.set_shader_parameter("breath", glow_breath)
	_glow_material.set_shader_parameter("breath", glow_breath)
	_glow.visible = float(_settings["glow_strength"]) > 0.0
	_animate_rim(_elapsed, interval)
	_sweep_material.set_shader_parameter("envelope", 0.0)
	var duration: float = float(_settings["sweep_duration"])
	var sweep_active: bool = bool(_settings["sweep_enabled"]) and phase >= 0.0 and phase <= duration
	_sweep.visible = bool(_settings["sweep_enabled"]) and (sweep_active or glow_breath > 0.001)
	if sweep_active:
		var progress: float = clampf(phase / duration, 0.0, 1.0)
		var motion_progress: float = smoothstep(0.0, 1.0, progress)
		var envelope: float = smoothstep(0.0, 0.18, progress)\
		* (1.0 - smoothstep(0.64, 1.0, progress))
		_sweep_material.set_shader_parameter("progress", lerpf(-0.22, 1.22, motion_progress))
		_sweep_material.set_shader_parameter("envelope", envelope)
	_particle_lifecycle.set_opacity(0.95 + glow_breath * 0.05)
	_animate_corner_gleams(phase)
	_animate_petals(phase)


func _can_animate() -> bool:
	return _enabled and _application_active and can_process() and is_visible_in_tree()\
	and not _button.disabled and not _button.button_pressed\
	and _button.mouse_filter != Control.MOUSE_FILTER_IGNORE and _button.modulate.a >= 0.98


func _animate_rim(elapsed: float, interval: float) -> void :
	_glow_material.set_shader_parameter("rim_progress", fposmod(elapsed, interval) / interval)
	_glow_material.set_shader_parameter("rim_envelope", smoothstep(0.0, 0.18, elapsed))


func _animate_petals(phase: float) -> void :
	var sweep_duration: float = float(_settings["sweep_duration"])
	var duration: float = minf(PETAL_DURATION, float(_settings["sweep_interval"])\
	- FIRST_SWEEP_DELAY - sweep_duration * 0.59 - 0.06)
	for index: int in range(_petals.size()):
		var petal: TextureRect = _petals[index]
		var left_side: bool = index < 2
		var pair_index: int = index % 2
		var delay: float = sweep_duration * (0.08 + float(pair_index) * 0.16\
		+ (0.0 if left_side else 0.35))
		var progress: float = clampf((phase - delay) / duration, 0.0, 1.0)
		var opacity: float = smoothstep(0.0, 0.14, progress)\
		* (1.0 - smoothstep(0.52, 1.0, progress))
		petal.visible = bool(_settings["stars_enabled"]) and opacity > 0.005
		petal.self_modulate.a = opacity * 0.92
		var lift: float = 1.0 - pow(1.0 - progress, 2.0)
		var side: float = -1.0 if left_side else 1.0
		var drift: float = sin(progress * TAU + float(index) * 1.7)\
		* sin(progress * PI) * size.y * 0.04
		petal.position = _petal_origins[index] + Vector2(
			side * size.x * (0.03 + float(pair_index) * 0.016) * lift + drift, 
			- size.y * (0.8 + float(pair_index) * 0.1) * lift)
		petal.rotation = side * deg_to_rad(18.0 + lift * 15.0 + sin(progress * TAU) * 12.0)
		var petal_scale: float = lerpf(0.48, 1.0, smoothstep(0.0, 0.28, progress))\
		* lerpf(1.0, 0.72, smoothstep(0.55, 1.0, progress))
		petal.scale = Vector2.ONE * petal_scale


func _breath_pose(progress: float) -> float:
	if progress < 0.4:
		return smoothstep(0.0, 0.4, progress)
	if progress < 0.68:
		return lerpf(1.0, -0.09, smoothstep(0.4, 0.68, progress))
	if progress < 0.86:
		return lerpf(-0.09, 0.04, smoothstep(0.68, 0.86, progress))
	return lerpf(0.04, 0.0, smoothstep(0.86, 1.0, progress))


func _animate_corner_gleams(phase: float) -> void :
	var sweep_duration: float = float(_settings["sweep_duration"])
	for index: int in range(_corner_gleams.size()):
		var gleam: TextureRect = _corner_gleams[index]
		var delay: float = sweep_duration * (0.02 if index == 0 else 0.42)
		var progress: float = clampf((phase - delay) / (sweep_duration * 0.6), 0.0, 1.0)
		var highlight: float = pow(sin(progress * PI), 2.0)
		gleam.visible = bool(_settings["stars_enabled"]) and highlight > 0.005
		gleam.self_modulate.a = highlight * 0.95
		gleam.scale = Vector2.ONE * (0.3 + highlight * 0.85)


func _apply_visual_pose(breath: float, progress: float) -> void :
	var amplitude: float = float(_settings["breath_strength"])
	var stretch: Vector2 = Vector2.ONE + Vector2(amplitude, amplitude * 1.35) * breath
	for entry: Dictionary in _visual_parts:
		var part: Control = entry["node"] as Control
		part.pivot_offset = _button.size * 0.5 - part.position
		part.scale = (entry["scale"] as Vector2) * stretch
		if part is HomeCoinBonusFx:
			(part as HomeCoinBonusFx).set_button_motion(progress, amplitude)


func _reset_visual_pose() -> void :
	for entry: Dictionary in _visual_parts:
		var part: Control = entry["node"] as Control
		if is_instance_valid(part):
			part.scale = entry["scale"] as Vector2
			part.pivot_offset = entry["pivot"] as Vector2
			if part is HomeCoinBonusFx:
				(part as HomeCoinBonusFx).set_button_motion(0.0, 0.0)


func _on_button_down() -> void :
	_set_running(false)


func _exit_tree() -> void :
	_particle_lifecycle.reset_immediate()
	_reset_visual_pose()


func _set_running(running: bool) -> void :
	if _running == running:
		return
	_running = running
	_elapsed = 0.0
	_sweep.hide()
	_glow.hide()
	_glow_material.set_shader_parameter("breath", 0.0)
	_glow_material.set_shader_parameter("rim_envelope", 0.0)
	for index: int in range(_petals.size()):
		var petal: TextureRect = _petals[index]
		petal.hide()
		petal.self_modulate.a = 0.0
		petal.rotation = 0.0
		petal.scale = Vector2.ONE
		petal.position = _petal_origins[index]
	for gleam: TextureRect in _corner_gleams:
		gleam.hide()
		gleam.self_modulate.a = 0.0
		gleam.scale = Vector2.ONE
	if not running:
		_reset_visual_pose()
	if running and bool(_settings["stars_enabled"]):
		_particle_lifecycle.play()
	else:
		_particle_lifecycle.reset_immediate()


func _apply_settings() -> void :
	_sweep_material.set_shader_parameter("strength", float(_settings["sweep_strength"]))
	_glow_material.set_shader_parameter("strength", float(_settings["glow_strength"]))
	var total: int = int(_settings["star_amount"])
	var soft_count: int = roundi(float(total) * 0.3)
	var ray_count: int = (total - soft_count * 2) / 2
	var counts: Array[int] = [soft_count, soft_count, ray_count, total - soft_count * 2 - ray_count]
	for index: int in range(_particles.size()):
		var particles: GPUParticles2D = _particles[index]
		particles.amount = maxi(1, counts[index])
		particles.lifetime = float(_settings["star_lifetime"])
		var material: ParticleProcessMaterial = particles.process_material as ParticleProcessMaterial
		material.particle_flag_disable_z = true
		var texture_width: float = maxf(1.0, float(particles.texture.get_width()))
		var particle_scale: float = float(_settings["star_size"]) / texture_width
		material.scale_min = particle_scale * 0.65
		material.scale_max = particle_scale * (1.1 if index >= 2 else 1.0)
		material.initial_velocity_min = float(_settings["star_speed"]) * 0.65
		material.initial_velocity_max = float(_settings["star_speed"]) * 1.35
		material.damping_min = 5.0
		material.damping_max = 9.0
		material.orbit_velocity_min = -0.022 if index < 2 else -0.018
		material.orbit_velocity_max = 0.022 if index < 2 else 0.018
		material.spread = 30.0 if index < 2 else 12.0
		material.direction = Vector3(0, -1, 0) if index < 2\
		else Vector3(-0.45 if index == 2 else 0.45, -1, 0)
	_layout()


static func _measure_rise_integral(curve: Curve) -> float:
	if curve == null:
		return 1.0
	var integral: float = 0.0
	for sample_index: int in range(32):
		var age: float = (float(sample_index) + 0.5) / 32.0
		integral += absf(curve.sample_baked(age))
	return maxf(0.01, integral / 32.0)


func _layout() -> void :
	if not is_node_ready():
		return
	_sweep_material.set_shader_parameter("button_size", size)
	_glow_material.set_shader_parameter("button_size", size)
	_glow_material.set_shader_parameter("glow_margin", Vector2.ONE * GLOW_MARGIN)
	_glow.offset_left = - GLOW_MARGIN
	_glow.offset_top = - GLOW_MARGIN
	_glow.offset_right = GLOW_MARGIN
	_glow.offset_bottom = GLOW_MARGIN
	var petal_size: Vector2 = Vector2.ONE * clampf(size.y * 0.32, 36.0, 74.0)
	for index: int in range(_petals.size()):
		var petal: TextureRect = _petals[index]
		var left_side: bool = index < 2
		var pair_index: int = index % 2
		var center_x: float = 0.08 + float(pair_index) * 0.035
		if not left_side:
			center_x = 1.0 - center_x
		petal.size = petal_size
		petal.pivot_offset = petal_size * 0.5
		_petal_origins[index] = Vector2(size.x * center_x, size.y * 0.83) - petal_size * 0.5
		petal.position = _petal_origins[index]
	var corner_size: Vector2 = Vector2(84.0, 84.0)
	for index: int in range(_corner_gleams.size()):
		var gleam: TextureRect = _corner_gleams[index]
		var center: Vector2 = Vector2(size.x * 0.1, size.y * 0.18) if index == 0\
		else Vector2(size.x * 0.9, size.y * 0.55)
		gleam.size = corner_size
		gleam.pivot_offset = corner_size * 0.5
		gleam.position = center - corner_size * 0.5
	for index: int in range(_particles.size()):
		var particles: GPUParticles2D = _particles[index]
		var center_x: float = 0.5 if index < 2 else (0.18 if index == 2 else 0.82)
		particles.position = Vector2(size.x * center_x, size.y * STAR_SPAWN_HEIGHT_RATIO)
		particles.visibility_rect = Rect2( - size * 0.5 - Vector2(90.0, 140.0), size + Vector2(180.0, 280.0))
		var material: ParticleProcessMaterial = particles.process_material as ParticleProcessMaterial
		var width_ratio: float = 0.42 if index < 2 else 0.13
		material.emission_box_extents = Vector3(maxf(1.0, size.x * width_ratio), maxf(1.0, size.y * 0.1), 0.0)
		var mean_lifetime: float = maxf(0.01, particles.lifetime * (1.0 - material.lifetime_randomness * 0.5))
		var rise_speed: float = size.y * STAR_ADDITIONAL_RISE_RATIO / (mean_lifetime * _star_rise_integral)
		material.directional_velocity_min = rise_speed * 0.88
		material.directional_velocity_max = rise_speed * 1.12


func _on_resized() -> void :
	if is_node_ready():
		replay()
	_layout()


func _on_visibility_changed() -> void :
	if is_node_ready() and not is_visible_in_tree():
		_set_running(false)


func _notification(what: int) -> void :
	if what == NOTIFICATION_PAUSED:
		if is_node_ready():
			_set_running(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_application_active = false
		if is_node_ready():
			_set_running(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_application_active = true
