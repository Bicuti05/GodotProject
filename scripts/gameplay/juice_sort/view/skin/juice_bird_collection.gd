class_name JuiceBirdCollection
extends Node2D

const RISE_DURATION: float = 0.36
const OPEN_DURATION: float = 0.3
const RISE_DISTANCE: float = 85.0
const BIRD_STAGGER: float = 0.07
const FEEDBACK_RETURN_DURATION: float = 0.1
const EMPTY_VISIBLE_WIDTH: float = 147.0
const FULL_VISIBLE_WIDTH: float = 286.0
const FULL_VISIBLE_CENTER_X: float = 159.0

var house: Sprite2D
var door: Sprite2D
var origin: Vector2
var empty_size: Vector2
var empty_scale: Vector2
var empty_anchor: Vector2
var mouth_rect: Rect2
var open_house: Texture2D
var completed: JuiceSkinVisual
var is_filled: bool = false


func setup(pack: JuiceSkinDefinition, empty: JuiceSkinVisual, full: JuiceSkinVisual, 
		source: Rect2, atlas: Texture2D, opened: Texture2D) -> void :
	open_house = opened
	var artwork_offset: = Vector2(empty.content_rect.position.x, empty.source_bottom - 165.0)
	mouth_rect = Rect2(pack.bird_mouth_rect.position + artwork_offset, pack.bird_mouth_rect.size)
	completed = full
	empty_size = empty.texture.get_size()
	empty_scale = source.size / empty_size
	empty_anchor = Vector2(90.5 + artwork_offset.x, empty.source_bottom)
	position = source.get_center()
	origin = position
	house = Sprite2D.new()
	house.texture = empty.texture
	house.scale = empty_scale
	add_child(house)
	door = Sprite2D.new()
	door.texture = atlas
	door.hframes = 3
	door.vframes = 2
	door.frame = 0
	door.centered = false
	var door_scale: Vector2 = mouth_rect.size / pack.door_closed_rect.size * empty_scale
	door.scale = door_scale
	door.position = (mouth_rect.position - empty_size * 0.5) * empty_scale\
	- pack.door_closed_rect.position * door_scale
	door.z_index = 2
	add_child(door)


func advance_open(age: float) -> void :
	var rise: float = clampf(age / RISE_DURATION, 0.0, 1.0)
	position = origin - Vector2(0.0, RISE_DISTANCE * (1.0 - pow(1.0 - rise, 3.0)))
	scale = Vector2.ONE * lerpf(1.0, 1.3, 1.0 - pow(1.0 - rise, 3.0))
	if age >= RISE_DURATION and not is_filled and house.texture != open_house:
		_set_house_texture(open_house, 296.0)
	var opening: float = clampf((age - RISE_DURATION) / OPEN_DURATION, 0.0, 1.0)
	door.frame = mini(int(opening * 6.0), 5)


func mouth_global_position() -> Vector2:
	return to_global((mouth_rect.get_center() - empty_size * 0.5) * empty_scale)


func advance_entry_feedback(age: float, duration: float) -> void :
	if age < 0.0:
		return
	var grow: float = clampf(age / duration, 0.0, 1.0)
	var recover: float = clampf((age - duration) / FEEDBACK_RETURN_DURATION, 0.0, 1.0)
	var feedback: float = lerpf(1.0, 1.3, grow) if age < duration else lerpf(1.3, 1.0, 1.0 - pow(1.0 - recover, 3.0))
	scale = Vector2.ONE * 1.3 * feedback


func fill() -> void :
	if is_filled:
		return
	is_filled = true
	_set_house_texture(completed.texture, completed.bottom_anchor.y * completed.texture.get_height())
	door.frame = 5


func _set_house_texture(texture: Texture2D, source_bottom: float) -> void :
	house.texture = texture
	var ratio: float = EMPTY_VISIBLE_WIDTH / FULL_VISIBLE_WIDTH
	house.scale = empty_scale * ratio
	house.position = (empty_anchor - empty_size * 0.5\
	+ (texture.get_size() * 0.5 - Vector2(FULL_VISIBLE_CENTER_X, source_bottom)) * ratio) * empty_scale


func filled_global_rect() -> Rect2:
	return house.global_transform * house.get_rect()


func place_filled(rect: Rect2) -> void :
	var local_size: Vector2 = house.texture.get_size() * house.scale
	scale = rect.size / local_size
	global_position = rect.get_center() - house.position * scale


func remove_door() -> void :
	door.hide()
