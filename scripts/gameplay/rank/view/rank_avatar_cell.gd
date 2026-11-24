class_name RankAvatarCell
extends Button


signal picked(avatar_index: int)

enum FrameKind{NONE, CURRENT, LIST}


const CURRENT_INNER_RECT: Rect2 = Rect2(19, 16, 187, 187)
const LIST_INNER_RECT: Rect2 = Rect2(11, 9, 146, 146)
const SELECTED_INNER_RECT: Rect2 = Rect2(21, 20, 164, 164)

@export var current_frame: Texture2D = null
@export var list_frame: Texture2D = null
@export var frame_kind: FrameKind = FrameKind.NONE:
	set(value):
		frame_kind = value
		if is_node_ready():
			_refresh_frame()

@onready var _img: TextureRect = $Root / Avatar
@onready var _frame: TextureRect = $Root / Frame
@onready var _selected_ring: TextureRect = $Root / Selected

var _avatar_index: int = -1


func _ready() -> void :
	_refresh_frame()
	_layout_frame(_selected_ring, SELECTED_INNER_RECT)


func _on_pressed() -> void :
	picked.emit(_avatar_index)


func bind(avatar_index: int, tex: Texture2D) -> void :
	_avatar_index = avatar_index
	if _img != null:
		_img.texture = tex


func get_avatar_index() -> int:
	return _avatar_index


func set_selected(on: bool) -> void :
	if _selected_ring != null:
		_selected_ring.visible = on


func _refresh_frame() -> void :
	_frame.texture = current_frame if frame_kind == FrameKind.CURRENT else list_frame
	_frame.visible = frame_kind != FrameKind.NONE and _frame.texture != null
	if _frame.visible:
		_layout_frame(_frame, CURRENT_INNER_RECT if frame_kind == FrameKind.CURRENT else LIST_INNER_RECT)


func _layout_frame(frame: TextureRect, inner: Rect2) -> void :
	if frame.texture == null:
		return
	var image_size: Vector2 = frame.texture.get_size()
	frame.anchor_left = - inner.position.x / inner.size.x
	frame.anchor_top = - inner.position.y / inner.size.y
	frame.anchor_right = (image_size.x - inner.position.x) / inner.size.x
	frame.anchor_bottom = (image_size.y - inner.position.y) / inner.size.y


static func fit_list_frame(frame: TextureRect, avatar: TextureRect) -> void :
	if frame.texture == null:
		return
	var factor: Vector2 = avatar.size / LIST_INNER_RECT.size
	frame.position = avatar.position - LIST_INNER_RECT.position * factor
	frame.size = frame.texture.get_size() * factor
