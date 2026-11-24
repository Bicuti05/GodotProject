class_name CompleteColumnFlowerFx
extends Node2D

const ATLAS_SHADER: Shader = preload("res://assets/effect/shader/particle_atlas_cell.gdshader")
const BURST_AMOUNT: int = 8
const TRAIL_AMOUNT: int = 12
const PARTICLE_SIZE_RATIO: float = 0.07
const PARTICLE_SPIN: float = 180.0
const GLOW_DIAMETER_RATIO: float = 1.6 * 0.7 / JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO
const OVERLAY_ALPHA: float = 0.5
const OVERLAY_DIAMETER_RATIO: float = 1.4
const LANDING_FADE_DUR: float = 0.18

var _glow: Sprite2D
var _burst: GPUParticles2D
var _trail: GPUParticles2D
var _overlay: Sprite2D
var _burst_lifecycle: = GpuParticleLifecycle.new()
var _trail_lifecycle: = GpuParticleLifecycle.new()
var _atlas_material: ShaderMaterial
var _configured: bool = false
var _started: bool = false
var _trail_started: bool = false
var _dropping: bool = false
var _glow_scale: float = 1.0
var _overlay_scale: float = 1.0


func _init() -> void :
	hide()
	_glow = Sprite2D.new()
	_glow.name = "Rays"
	_glow.visible = false
	add_child(_glow)
	_atlas_material = ShaderMaterial.new()
	_atlas_material.shader = ATLAS_SHADER
	_burst = _make_emitter("Burst", BURST_AMOUNT, 0.5, true)
	_trail = _make_emitter("FlightPetals", TRAIL_AMOUNT, 0.28, false)
	_overlay = Sprite2D.new()
	_overlay.name = "ElementGlow"
	_overlay.visible = false
	var glow_material: = CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_overlay.material = glow_material
	add_child(_overlay)
	_burst_lifecycle.prepare([_burst], 2, is_visible_in_tree)
	_trail_lifecycle.prepare([_trail], 2, is_visible_in_tree)


func _make_emitter(emitter_name: String, amount: int, lifetime: float, burst: bool) -> GPUParticles2D:
	var material: = ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	material.angle_min = -180.0
	material.angle_max = 180.0
	material.angular_velocity_min = PARTICLE_SPIN * 0.5
	material.angular_velocity_max = PARTICLE_SPIN * 1.5
	material.anim_offset_max = 1.0
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	var ramp: = GradientTexture1D.new()
	ramp.gradient = gradient
	material.color_ramp = ramp
	var emitter: = GPUParticles2D.new()
	emitter.name = emitter_name
	emitter.visible = false
	emitter.emitting = false
	emitter.local_coords = false
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.one_shot = burst
	emitter.explosiveness = 1.0 if burst else 0.0
	emitter.process_material = material
	emitter.visibility_rect = Rect2(-512.0, -512.0, 1024.0, 1024.0)
	add_child(emitter)
	return emitter


func configure(diameter: float, petal: Texture2D, whole_texture: bool, rays: Texture2D, tint: Color, 
		visible_diameter: float, overlay_texture: Texture2D, foreground_z: int) -> void :
	if _configured:
		_burst_lifecycle.reconfigure(_configure_emitter.bind(_burst, diameter, visible_diameter, petal, whole_texture, tint, true))
		_trail_lifecycle.reconfigure(_configure_emitter.bind(_trail, diameter, visible_diameter, petal, whole_texture, tint, false))
	else:
		_configure_emitter(_burst, diameter, visible_diameter, petal, whole_texture, tint, true)
		_configure_emitter(_trail, diameter, visible_diameter, petal, whole_texture, tint, false)
	_configured = true
	_started = false
	_trail_started = false
	_dropping = false
	_glow.texture = rays
	_glow.modulate = Color(tint, 0.0)
	_glow_scale = visible_diameter * GLOW_DIAMETER_RATIO / maxf(1.0, float(rays.get_width())) if rays != null else 1.0
	_glow.scale = Vector2.ONE * _glow_scale
	_glow.rotation = 0.0
	_glow.visible = false
	_overlay.texture = overlay_texture
	_overlay.z_index = foreground_z
	_overlay.modulate = Color(tint, 0.0)
	_overlay_scale = visible_diameter * OVERLAY_DIAMETER_RATIO / maxf(1.0, float(overlay_texture.get_width())) if overlay_texture != null else 1.0
	_overlay.scale = Vector2.ONE * _overlay_scale
	_overlay.visible = false
	show()


func _configure_emitter(emitter: GPUParticles2D, diameter: float, visible_diameter: float, petal: Texture2D, 
		whole_texture: bool, tint: Color, burst: bool) -> void :
	emitter.texture = petal
	emitter.material = null if whole_texture else _atlas_material
	emitter.modulate = Color.WHITE if whole_texture else tint
	var material: ParticleProcessMaterial = emitter.process_material
	var cell_width: float = maxf(1.0, float(petal.get_width()) * (1.0 if whole_texture else 0.5)) if petal != null else 1.0
	material.scale_min = diameter * PARTICLE_SIZE_RATIO * 0.5 / cell_width
	material.scale_max = diameter * PARTICLE_SIZE_RATIO * 1.5 / cell_width
	material.initial_velocity_min = diameter * (0.6 if burst else 0.12)
	material.initial_velocity_max = diameter * (1.2 if burst else 0.35)
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = diameter * 0.24 if burst else visible_diameter * 0.25
	emitter.visibility_rect = Rect2(Vector2.ONE * - diameter * 3.0, Vector2.ONE * diameter * 6.0)


func advance(elapsed: float, element_scale: float, flying: bool, dropping: bool, fade_progress: float) -> void :
	if not _started:
		_started = true
		_glow.visible = _glow.texture != null
		_burst_lifecycle.play()
		_overlay.visible = _overlay.texture != null
	_glow.scale = Vector2.ONE * _glow_scale * element_scale
	_overlay.scale = Vector2.ONE * _overlay_scale * element_scale
	_glow.rotation = deg_to_rad(54.0) * elapsed
	fade_progress = clampf(fade_progress, 0.0, 1.0)
	var fade_alpha: float = 1.0 - fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
	_glow.modulate.a = 0.75 * fade_alpha if dropping else 0.75 * clampf(elapsed / 0.1, 0.0, 1.0)
	_overlay.modulate.a = OVERLAY_ALPHA * fade_alpha if dropping else OVERLAY_ALPHA * clampf(elapsed / 0.1, 0.0, 1.0)
	if dropping:
		if not _dropping:
			_dropping = true
			_burst_lifecycle.reset_immediate()
			_trail_lifecycle.reset_immediate()
		if fade_progress >= 1.0:
			_overlay.hide()
			_glow.hide()
	elif flying and not _trail_started:
		_trail_started = true
		_trail_lifecycle.play()
	elif not flying and _trail_started:
		_trail_lifecycle.stop_with_tail()


func reset_for_pool() -> void :
	_burst_lifecycle.reset_immediate()
	_trail_lifecycle.reset_immediate()
	_overlay.hide()
	_overlay.modulate.a = 0.0
	_glow.hide()
	_glow.modulate.a = 0.0
	hide()
	_started = false
	_trail_started = false
	_dropping = false


func _exit_tree() -> void :
	reset_for_pool()
