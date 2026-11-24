class_name RankPodiumSweepFx
extends Control

const VISIBLE_SEC: float = 0.7500005
const PARTICLES_AT: float = 0.25000027
const PARTICLE_SIZE_FACTOR: float = 0.5
const CONFETTI_OFFSET_Y: float = 200.0

@export var mask_texture: Texture2D = null

@export var sweep_region: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
@export_range(0.01, 3.0, 0.01) var sweep_thickness: float = 2.75
@onready var _mask: TextureRect = $Mask
@onready var _range: Control = $Mask / Range
@onready var _glow: Sprite2D = $Mask / Range / Glow
@onready var _source: Control = $Source
@onready var _player: AnimationPlayer = $Source / AnimationPlayer

var _particles: Array[CPUParticles2D] = []
var _particle_scales: Array[Vector2] = []
var _particle_rects: Array[Vector2] = []
var _particle_positions: Array[Vector2] = []
var _generation: int = 0
var _tween: Tween


func _ready() -> void :


	var library: AnimationLibrary = _player.get_animation_library(&"").duplicate(true) as AnimationLibrary
	for name: StringName in library.get_animation_list():
		var animation: Animation = library.get_animation(name)
		for track: int in animation.get_track_count():
			if String(animation.track_get_path(track)).ends_with(":emitting"):
				animation.track_set_enabled(track, false)
	_player.remove_animation_library(&"")
	_player.add_animation_library(&"", library)
	for node: Node in _source.find_children("*", "CPUParticles2D", true, false):
		var particle: CPUParticles2D = node as CPUParticles2D
		_particles.append(particle)
		_particle_scales.append(particle.scale)
		_particle_rects.append(particle.emission_rect_extents)
		_particle_positions.append(particle.position)
		if particle.get_parent().name != &"EffectFlreworks":
			particle.scale_amount_min *= PARTICLE_SIZE_FACTOR
			particle.scale_amount_max *= PARTICLE_SIZE_FACTOR
	for node: Node in _source.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rank: int in range(1, 4):
		(_source.get_node("Rank%d" % rank) as Control).hide()
	stop()


func play(list: RankListView, rank: int, list_generation: int, include_confetti: bool = true) -> void :
	stop()
	var generation: int = _generation
	var confetti: Control = _source.get_node("EffectFlreworks")
	confetti.visible = include_confetti
	_mask.texture = mask_texture
	_mask.size = size
	_source.scale = Vector2.ONE
	_source.position = Vector2.ZERO
	var source_mask: Sprite2D = _source.get_node("Rank%d/Podium/PodiumMask" % rank)
	var source_center: Vector2 = _source.get_global_transform().affine_inverse() * source_mask.global_position
	var ratio: Vector2 = size / source_mask.texture.get_size()
	_source.scale = ratio
	_source.position = size * 0.5 - source_center * ratio
	var source_glow: Sprite2D = source_mask.get_node("Glow")
	_glow.texture = source_glow.texture
	_glow.material = source_glow.material
	var animation: StringName = StringName("Sweep%d" % rank)
	var source_animation: Animation = _player.get_animation(animation)
	var color_track: int = source_animation.find_track(NodePath("Rank%d/Podium/PodiumMask/Glow:modulate" % rank), Animation.TYPE_VALUE)
	var glow_color: Color = source_animation.track_get_key_value(color_track, 0)
	var width_factor: float = source_glow.texture.get_width() * source_glow.scale.x / source_mask.texture.get_width()

	var duration: float = VISIBLE_SEC
	for index: int in _particles.size():
		var particle: CPUParticles2D = _particles[index]
		if include_confetti or particle.get_parent().name != &"EffectFlreworks":
			duration = maxf(duration, PARTICLES_AT + particle.lifetime * 2.0 + 0.05)


		particle.scale = _particle_scales[index] / ratio
		particle.emission_rect_extents = _particle_rects[index] * ratio
		if particle.get_parent().name == &"EffectFlreworks":
			particle.position = _particle_positions[index] + Vector2(0.0, CONFETTI_OFFSET_Y / ratio.y)
		particle.hide()
		particle.restart()
		particle.emitting = false
	visible = true
	_glow.show()
	_player.play(animation)
	_player.pause()
	var burst: Dictionary = {"started": false}

	var sample: Callable = func(time: float) -> void :
		if generation != _generation or not list.animation_is_active(list_generation):
			return
		_player.seek(time, true)
		if time >= PARTICLES_AT and not burst.started:
			burst.started = true
			for particle: CPUParticles2D in _particles:
				if include_confetti or particle.get_parent().name != &"EffectFlreworks":
					particle.show()
					particle.restart()


		var rising: Control = _source.get_node("EffectRisingParticle")
		for node: Node in rising.get_children():
			var particle: CPUParticles2D = node as CPUParticles2D
			var height: float = 0.5 if particle.name == &"GlowAlp" else 0.82
			particle.position = (size * Vector2(0.5, height) - _source.position) / ratio - rising.position
		_sample_glow(source_glow, time, glow_color, width_factor)
	sample.call(0.0)
	_tween = list.create_animation_tween()
	_tween.tween_method(sample, 0.0, duration, duration).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback( func() -> void :
		if generation == _generation:
			_tween = null
			stop())


func _sample_glow(source_glow: Sprite2D, time: float, glow_color: Color, width_factor: float) -> void :
	_range.position = size * sweep_region.position
	_range.size = size * sweep_region.size
	var progress: float = smoothstep(0.0, VISIBLE_SEC, time)
	var thickness: float = size.y * sweep_thickness * clampf(source_glow.scale.y / 4.0, 0.0, 1.0)


	_glow.position = Vector2(_range.size.x * 0.5, lerpf(_range.size.y + thickness * 0.5, - thickness * 0.5, progress))
	_glow.scale = Vector2(_range.size.x * width_factor, thickness) / _glow.texture.get_size()

	glow_color.a *= clampf(minf(time / 0.06, (VISIBLE_SEC - time) / 0.12), 0.0, 1.0)
	_glow.modulate = glow_color


func stop() -> void :
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_player.stop()
	hide()
	for particle: CPUParticles2D in _particles:
		particle.hide()
		particle.restart()
		particle.emitting = false
