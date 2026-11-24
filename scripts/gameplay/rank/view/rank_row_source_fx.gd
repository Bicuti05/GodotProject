class_name RankRowSourceFx
extends Node2D

const SOURCE_SIZE: Vector2 = Vector2(970.0, 180.0)
const PARTICLE_SIZE_FACTOR: float = 0.5

@export var arrow_texture: Texture2D

@onready var _source: Control = $Particles
@onready var _glow: CPUParticles2D = $Particles / EffectGlow / Glow
@onready var _arrow_group: Control = $Particles / Arrow
@onready var _arrow: CPUParticles2D = $Particles / Arrow / Arrow
var _stars: Array[CPUParticles2D] = []
var _particles: Array[CPUParticles2D] = []
var _particle_scales: Array[Vector2] = []
var _particle_rects: Array[Vector2] = []


func _ready() -> void :
	for node: Node in _source.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node: Node in _source.find_children("*", "CPUParticles2D", true, false):
		var particle: CPUParticles2D = node as CPUParticles2D
		_particles.append(particle)
		_particle_scales.append(particle.scale)
		_particle_rects.append(particle.emission_rect_extents)
		if particle != _arrow:
			particle.scale_amount_min *= PARTICLE_SIZE_FACTOR
			particle.scale_amount_max *= PARTICLE_SIZE_FACTOR
	if arrow_texture != null:
		_arrow.texture = arrow_texture

	_arrow.preprocess = _arrow.lifetime
	for node: Node in $Particles / EffectStars.get_children():
		_stars.append(node as CPUParticles2D)
	stop()


func fit_row(row_size: Vector2) -> void :
	var ratio: Vector2 = row_size / SOURCE_SIZE
	_source.scale = ratio

	for index: int in _particles.size():
		_particles[index].scale = _particle_scales[index] / ratio
		_particles[index].emission_rect_extents = _particle_rects[index] * ratio


func play_stars() -> void :
	show()
	for particle: CPUParticles2D in _stars:
		_restart(particle)


func play_glow() -> void :
	show()
	_restart(_glow)


func start_arrows() -> void :
	show()
	_arrow_group.modulate.a = 1.0
	_restart(_arrow)


func set_arrow_alpha(alpha: float) -> void :
	_arrow_group.modulate.a = alpha


func stop_glow() -> void :
	_clear(_glow)


func stop_arrows() -> void :
	_clear(_arrow)
	_arrow_group.modulate.a = 1.0


func stop() -> void :
	hide()
	_clear(_glow)
	stop_arrows()
	for particle: CPUParticles2D in _stars:
		_clear(particle)


func _restart(particle: CPUParticles2D) -> void :
	particle.show()
	particle.restart()
	particle.emitting = true


func _clear(particle: CPUParticles2D) -> void :
	particle.hide()
	particle.restart()
	particle.emitting = false
