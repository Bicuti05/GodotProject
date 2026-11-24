class_name RankSourceCollectionFx
extends Node2D

signal item_arrived(index: int)

const LANDING_SCALE: float = 0.67
const SOURCE_TARGET: Vector2 = Vector2(-250.0, 0.0)

@onready var _source: Control = $Collection
@onready var _player: AnimationPlayer = $Collection / CollectionAppear
var _sprites: Array[Sprite2D] = []
var _particles: Array[CPUParticles2D] = []
var _particle_scales: Array[Vector2] = []
var _generation: int = 0
var _home_parent: Node
var _fly_count: int = 0
var _follow_item: RankItemView
var _follow_transform: Transform2D


func _ready() -> void :
	_home_parent = get_parent()
	for node: Node in _source.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index: int in range(1, 7):
		_sprites.append(_source.get_node("Collection%d" % index) as Sprite2D)
	for node: Node in _source.find_children("*", "CPUParticles2D", true, false):
		var particle: CPUParticles2D = node as CPUParticles2D
		_particles.append(particle)
		_particle_scales.append(particle.scale)
		particle.scale_amount_min *= 0.5
		particle.scale_amount_max *= 0.5
	cancel_all()


func get_fly_count() -> int:
	return _fly_count


func play(list: RankListView, item: RankItemView, tex: Texture2D, count: int) -> void :
	cancel_all()
	if count <= 0 or tex == null or item == null:
		return
	var generation: int = _generation
	var list_generation: int = list.animation_generation

	_fly_count = 6
	var name: StringName = &"Count2"
	var animation: Animation = _player.get_animation(name)
	var arrivals: Array[float] = []
	for index: int in range(_fly_count):
		var track: int = animation.find_track(NodePath("Collection/Collection%d:modulate" % (index + 1)), Animation.TYPE_VALUE)
		arrivals.append(animation.track_get_key_time(track, animation.track_get_key_count(track) - 1))

	if get_parent() != item:
		reparent(item, false)
	var ratio: float = item.get_collect_icon_global_rect().size.x / (float(tex.get_width()) * LANDING_SCALE)
	var target: Vector2 = item.get_collect_target_global_pos()


	var reflected: bool = target.x > UiMetrics.viewport_size().x * 0.5
	var axes: Vector2 = Vector2( - ratio if reflected else ratio, ratio)
	global_transform = Transform2D(Vector2(axes.x, 0.0), Vector2(0.0, axes.y), target - SOURCE_TARGET * axes)
	_follow_item = item
	_follow_transform = item.get_global_transform().affine_inverse() * global_transform
	set_process(true)
	for sprite: Sprite2D in _sprites:
		sprite.texture = tex
		sprite.flip_h = reflected
	for index: int in _particles.size():
		var particle: CPUParticles2D = _particles[index]

		particle.scale = _particle_scales[index] / ratio
		particle.show()
		particle.restart()
		particle.emitting = false
	show()
	_player.play("RESET")
	_player.advance(0.0)
	_player.play(name)
	_player.advance(0.0)
	var arrived: int = 0
	while generation == _generation and list.animation_is_active(list_generation) and _player.is_playing():
		var time: float = _player.current_animation_position
		while arrived < arrivals.size() and time >= arrivals[arrived]:
			item_arrived.emit(arrived)
			arrived += 1
		await get_tree().process_frame
	if generation != _generation:
		return
	if not list.animation_is_active(list_generation):
		cancel_all()
		return
	while arrived < arrivals.size():
		item_arrived.emit(arrived)
		arrived += 1


func retarget_receiver(item: RankItemView) -> void :
	if not visible or item == null or item == _follow_item:
		return

	var world: Transform2D = global_transform
	reparent(item, true)
	global_transform = world
	_follow_item = item
	_follow_transform = item.get_global_transform().affine_inverse() * world


func _process(_delta: float) -> void :
	if not is_instance_valid(_follow_item) or not _follow_item.is_inside_tree():
		cancel_all()
		return

	global_transform = _follow_item.get_global_transform() * _follow_transform


func cancel_all() -> void :
	_generation += 1
	set_process(false)
	_follow_item = null
	_player.stop()
	hide()
	for particle: CPUParticles2D in _particles:
		particle.hide()
		particle.restart()
		particle.emitting = false
	for sprite: Sprite2D in _sprites:
		sprite.modulate.a = 0.0
	if _home_parent != null and is_instance_valid(_home_parent) and get_parent() != _home_parent:
		reparent(_home_parent, false)
	scale = Vector2.ONE
	position = Vector2.ZERO
