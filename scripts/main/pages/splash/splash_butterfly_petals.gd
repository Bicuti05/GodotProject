extends Node2D

const _GRID_SIZE: int = 5
const _POOL_SIZE: int = 16
const _EMISSION_INTERVAL: float = 1.0 / 6.0

class Petal extends RefCounted:
	var active: bool = false
	var age: float = 0.0
	var lifetime: float = 0.0
	var frame: int = 0
	var size: float = 0.0
	var start_position: Vector2 = Vector2.ZERO
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var initial_angle: float = 0.0
	var rotation_delta: float = 0.0
	var angle: float = 0.0

@export var atlas: Texture2D = null
var emission_position: Vector2 = Vector2.ZERO
var size_multiplier: float = 1.0

var _items: Array[Petal] = []
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _emitting: bool = false
var _emission_elapsed: float = 0.0


func _ready() -> void :
	_random.randomize()
	for particle_index: int in range(_POOL_SIZE):
		_items.append(Petal.new())
	set_process(false)


func set_emitting(enabled: bool) -> void :
	_emitting = enabled
	_emission_elapsed = 0.0
	for item: Petal in _items:
		item.active = false
	visible = enabled
	set_process(enabled)
	queue_redraw()


func _spawn() -> void :
	for item: Petal in _items:
		if item.active:
			continue
		item.active = true
		item.age = 0.0
		item.lifetime = 0.5 * _random.randf_range(0.8, 1.2)
		item.frame = _random.randi_range(0, _GRID_SIZE * _GRID_SIZE - 1)
		item.size = _random.randf_range(18.0, 28.0) * size_multiplier
		item.start_position = emission_position + Vector2(
			_random.randf_range(-20.0, 20.0), 20.0 + _random.randf_range(-16.0, 16.0))
		item.position = item.start_position
		item.velocity = Vector2( - _random.randf_range(140.0, 220.0), _random.randf_range(-40.0, 40.0))
		item.initial_angle = deg_to_rad(_random.randf_range(0.0, 180.0))
		item.rotation_delta = deg_to_rad(_random.randf_range(90.0, 180.0))
		if _random.randi_range(0, 1) == 0:
			item.rotation_delta = - item.rotation_delta
		item.angle = item.initial_angle
		return


func _process(delta: float) -> void :
	if not _emitting or not is_visible_in_tree():
		return
	for item: Petal in _items:
		if not item.active:
			continue
		item.age += delta
		if item.age >= item.lifetime:
			item.active = false
			continue
		item.position = item.start_position + item.velocity * item.age
		item.angle = item.initial_angle + item.rotation_delta * (item.age / item.lifetime)
	_emission_elapsed += delta
	while _emission_elapsed >= _EMISSION_INTERVAL:
		_emission_elapsed -= _EMISSION_INTERVAL
		_spawn()
	queue_redraw()


func _draw() -> void :
	if atlas == null:
		return
	var frame_size: Vector2 = atlas.get_size() / float(_GRID_SIZE)
	for item: Petal in _items:
		if not item.active:
			continue
		var cell: Vector2 = Vector2(item.frame % _GRID_SIZE, floori(float(item.frame) / float(_GRID_SIZE)))
		var alpha: float = 1.0 - item.age / item.lifetime
		draw_set_transform(item.position, item.angle)
		draw_texture_rect_region(atlas, Rect2(Vector2.ONE * ( - item.size * 0.5), Vector2.ONE * item.size), 
			Rect2(cell * frame_size, frame_size), Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO)
