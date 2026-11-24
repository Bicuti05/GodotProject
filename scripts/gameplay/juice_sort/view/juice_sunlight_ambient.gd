class_name JuiceSunlightAmbient
extends Node2D

@export var settings: SunlightFxSettings
@onready var _halo: Node2D = $Halo
@onready var _sun_effect: Node2D = $SunEffect
@onready var _sun_particles: GPUParticles2D = $SunParticles
@onready var _cold_particles: GPUParticles2D = $ColdParticles
var _sun_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _cold_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _sun_enabled: bool = false
var _frozen: bool = false
var _sun_emitting: bool = false
var _cold_emitting: bool = false
var _cold_tail: float = -1.0
var _melt: float = 0.0
var _clock: float = 0.0
var _speed: float = 1.0
var _paused: bool = false
var _stopped: bool = false


func _ready() -> void :
	settings = settings.duplicate() as SunlightFxSettings
	_configure_sun()
	_configure_cold()
	_sun_lifecycle.prepare([_sun_particles], 2, _can_render)
	_cold_lifecycle.prepare([_cold_particles], 2, _can_render)
	_halo.hide()
	_sun_effect.hide()
	set_process(false)


func _exit_tree() -> void :
	stop()


func configure(options: SunlightFxSettings) -> void :
	settings = options.duplicate() as SunlightFxSettings
	_sun_lifecycle.reconfigure(_configure_sun)
	_cold_lifecycle.reconfigure(_configure_cold)
	_sun_emitting = false
	_cold_emitting = false
	_cold_tail = -1.0
	_clock = 0.0
	_sync_effects()


func set_diameter(diameter: float) -> void :
	scale = Vector2.ONE * diameter / 200.0


func set_ice_geometry(center: Vector2, cover_scale: float) -> void :
	_cold_particles.position = center + Vector2(0.0, -10.0 * cover_scale)
	_cold_particles.scale = Vector2.ONE * cover_scale


func set_sunlight(enabled: bool) -> void :
	if _sun_enabled == enabled:
		return
	_sun_enabled = enabled
	_clock = 0.0
	_stopped = false
	_sync_effects()


func set_frozen(enabled: bool) -> void :
	if _frozen == enabled and _melt == 0.0:
		return
	_frozen = enabled
	_melt = 0.0
	_stopped = false
	_cold_tail = -1.0
	if not enabled:
		_cold_lifecycle.reset_immediate()
		_cold_emitting = false
	_sync_effects()


func set_melt_progress(progress: float) -> void :
	if _melt == clampf(progress, 0.0, 1.0):
		return
	var was_melting: bool = _melt > 0.0
	_melt = clampf(progress, 0.0, 1.0)
	if _melt > 0.0 and _cold_emitting:
		_cold_lifecycle.stop_with_tail()
		_cold_emitting = false
		_cold_tail = settings.cold_particle_lifetime
	elif not was_melting and _melt == 0.0:
		return
	_cold_lifecycle.set_opacity(1.0 - smoothstep(0.0, 1.0, _melt))
	if _melt >= 1.0:
		_cold_lifecycle.reset_immediate()
		_cold_tail = -1.0
	elif was_melting and _melt == 0.0:
		_cold_tail = -1.0
		_sync_effects()


func set_playback(speed: float, paused: bool) -> void :
	_speed = maxf(0.0, speed)
	_paused = paused
	_update_speed()


func stop_motion() -> void :
	_stopped = true
	_sun_lifecycle.reset_immediate()
	_cold_lifecycle.reset_immediate()
	_sun_emitting = false
	_cold_emitting = false
	_cold_tail = -1.0
	_halo.scale = Vector2.ONE
	_halo.modulate.a = 1.0
	_sun_effect.scale = Vector2.ONE
	_sun_effect.modulate.a = 1.0
	_update_speed()
	set_process(false)


func stop() -> void :
	_sun_enabled = false
	_frozen = false
	_melt = 0.0
	_clock = 0.0
	_paused = false
	_speed = 1.0
	stop_motion()
	_halo.hide()
	_sun_effect.hide()


func _configure_sun() -> void :
	var material: ParticleProcessMaterial = _sun_particles.process_material as ParticleProcessMaterial
	material.particle_flag_disable_z = true
	_sun_particles.amount = maxi(1, settings.sun_particle_count)
	_sun_particles.lifetime = settings.sun_particle_lifetime
	material.scale_min = settings.sun_particle_size * 0.7
	material.scale_max = settings.sun_particle_size * 1.25
	material.initial_velocity_min = settings.sun_particle_speed * 0.7
	material.initial_velocity_max = settings.sun_particle_speed * 1.2
	material.color.a = settings.sun_particle_opacity


func _configure_cold() -> void :
	var material: ParticleProcessMaterial = _cold_particles.process_material as ParticleProcessMaterial
	material.particle_flag_disable_z = true
	_cold_particles.amount = maxi(1, settings.cold_particle_count)
	_cold_particles.lifetime = settings.cold_particle_lifetime
	material.scale_min = settings.cold_particle_size * 0.75
	material.scale_max = settings.cold_particle_size * 1.25
	material.initial_velocity_min = settings.cold_particle_speed * 0.75
	material.initial_velocity_max = settings.cold_particle_speed * 1.2
	material.color.a = settings.cold_particle_opacity


func _sync_effects() -> void :
	_halo.visible = _sun_enabled and settings.halo_enabled
	_sun_effect.visible = _sun_enabled and settings.halo_enabled
	var sun_active: bool = _sun_enabled and settings.sun_particles_enabled\
	and settings.sun_particle_count > 0 and not _stopped
	if sun_active and not _sun_emitting:
		_sun_lifecycle.set_opacity(1.0)
		_sun_lifecycle.play()
	elif not sun_active and _sun_emitting:
		_sun_lifecycle.reset_immediate()
	_sun_emitting = sun_active
	var cold_active: bool = _frozen and _melt == 0.0 and settings.cold_enabled\
	and settings.cold_particle_count > 0 and not _stopped
	if cold_active and not _cold_emitting:
		_cold_lifecycle.set_opacity(1.0)
		_cold_lifecycle.play()
	elif not cold_active and _cold_emitting:
		_cold_lifecycle.reset_immediate()
	_cold_emitting = cold_active
	_update_speed()
	_sample_halo()
	set_process( not _stopped and (_sun_enabled or _cold_emitting or _cold_tail >= 0.0))


func _sample_halo() -> void :
	var pulse: float = settings.halo_pulse(_clock)
	_halo.scale = Vector2.ONE * (1.0 + settings.halo_amplitude * pulse)
	_halo.modulate.a = lerpf(0.5, 1.0, pulse) * 0.85
	_sun_effect.scale = Vector2.ONE * (1.0 + settings.halo_amplitude * 0.5 * pulse)
	_sun_effect.modulate.a = lerpf(0.65, 1.0, pulse)


func _can_render() -> bool:
	return is_inside_tree() and is_visible_in_tree() and can_process()\
	and not _paused and not _stopped and _speed > 0.0


func _update_speed() -> void :
	if not is_node_ready():
		return
	var effective_speed: float = _speed if is_inside_tree() and can_process()\
	and not _paused and not _stopped else 0.0
	_sun_particles.speed_scale = effective_speed
	_cold_particles.speed_scale = effective_speed


func _notification(what: int) -> void :
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED:
		_update_speed()


func _process(delta: float) -> void :
	if _paused or _stopped:
		return
	var elapsed: float = delta * _speed
	var period: float = maxf(0.1, settings.halo_period)
	var next_clock: float = _clock + elapsed
	_clock = fmod(next_clock, period)
	if _sun_enabled:
		_sample_halo()
	if _cold_tail >= 0.0:
		_cold_tail -= elapsed
		if _cold_tail < 0.0:
			_cold_lifecycle.reset_immediate()
			if not _sun_enabled and not _cold_emitting:
				set_process(false)
