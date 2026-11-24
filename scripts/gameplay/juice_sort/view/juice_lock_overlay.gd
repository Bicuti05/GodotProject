class_name JuiceLockOverlay
extends Control

var _flower_reference: Rect2
var _skin_visual: JuiceSkinVisual
var _skin_resources: JuiceSkinResolver










const DESIGN_FRUIT_D: = 230.0

const FRAME_W: = 200.0


const VINE_TEX_W: = 217.0
const VINE_TEX_H: = 1010.0
const VINE_TEX_X: = -8.5

const VINE_FRAME_H: = 1010.0




const VINE_Y_OFF: = -10.0


const BADGE_TEX_W: = 176.0
const BADGE_TEX_H: = 171.0
const BADGE_RING_CX: = 87.5
const BADGE_RING_CY: = 92.5

const BADGE_CY_OFF: = -3.5

const NUM_DX: = -0.55
const NUM_DY: = -0.61
const NUM_FONT_SIZE: = 84.444


const FLOWER_D: = DESIGN_FRUIT_D * 0.6





const FLOWER_DX: = 0.5
const FLOWER_DY: = 2.0 + 5.0 * FLOWER_D / 200.0
const WOOD_DOOR_SCENE: PackedScene = preload("res://scripts/gameplay/juice_sort/view/wood_door_lock.tscn")


var col: int = -1

var _vine0: TextureRect = null
var _vine1: TextureRect = null
var _badge: TextureRect = null
var _num: Label = null
var _flower: TextureRect = null
var _wood_door: WoodDoorLock = null
var _lock_visual_version: int = 1
var _color_lock: bool = false
var _remaining_count: int = 0
var _geometry_scale: float = 1.0
var _column_width: float = 0.0




func _ensure_refs() -> void :
	if _vine0 != null:
		return
	_vine0 = get_node_or_null("Vine0") as TextureRect
	_vine1 = get_node_or_null("Vine1") as TextureRect
	_badge = get_node_or_null("Badge") as TextureRect
	_num = get_node_or_null("Num") as Label
	_flower = get_node_or_null("Flower") as TextureRect
	if _vine0 == null or _vine1 == null or _badge == null or _num == null or _flower == null:
		SortLogger.error("JuiceLockOverlay: 场景结构不完整(缺 Vine0 / Vine1 / Badge / Num / Flower)")




func set_geometry(col_center_x: float, top: float, height: float, fruit_d: float, column_width: float = 0.0) -> void :
	_ensure_refs()
	if _vine0 == null:
		return
	var s: float = fruit_d / DESIGN_FRUIT_D
	if s <= 0.0 or height <= 0.0:
		return
	position = Vector2(col_center_x - FRAME_W * 0.5 * s, top)
	size = Vector2(FRAME_W * s, height)

	var hd: float = height / s
	_geometry_scale = s
	_column_width = column_width

	var vine_size: = Vector2(VINE_TEX_W * s, VINE_TEX_H * s)
	_vine0.position = Vector2(VINE_TEX_X * s, VINE_Y_OFF * s)
	_vine0.size = vine_size


	_vine1.visible = hd > VINE_FRAME_H
	if _vine1.visible:
		_vine1.position = Vector2(VINE_TEX_X * s, (hd - VINE_FRAME_H + VINE_Y_OFF) * s)
		_vine1.size = vine_size


	var ring_cx: float = FRAME_W * 0.5
	var ring_cy: float = hd * 0.5 + BADGE_CY_OFF
	_badge.position = Vector2((ring_cx - BADGE_RING_CX) * s, (ring_cy - BADGE_RING_CY) * s)
	_badge.size = Vector2(BADGE_TEX_W * s, BADGE_TEX_H * s)


	_num.size = Vector2(BADGE_TEX_W * s, BADGE_TEX_H * s)
	_num.position = Vector2((ring_cx + NUM_DX - BADGE_TEX_W * 0.5) * s, 
		(ring_cy + NUM_DY - BADGE_TEX_H * 0.5) * s)
	_num.add_theme_font_size_override(&"font_size", maxi(1, roundi(NUM_FONT_SIZE * s)))

	_flower.size = Vector2(FLOWER_D * s, FLOWER_D * s)
	_flower.position = Vector2((ring_cx + FLOWER_DX - FLOWER_D * 0.5) * s, 
		(ring_cy + FLOWER_DY - FLOWER_D * 0.5) * s)
	_flower_reference = Rect2(_flower.position, _flower.size)
	_apply_skin_icon()
	_sync_wood_door()










func set_lean(slope: float, pivot_y: float) -> void :
	pivot_offset = Vector2(size.x * 0.5, pivot_y)
	rotation = - atan(slope)



func show_count(remaining: int) -> void :
	_ensure_refs()
	if _num == null:
		return
	_num.text = str(maxi(0, remaining))
	_color_lock = false
	_remaining_count = maxi(0, remaining)
	_sync_wood_door()



func show_flower(tex: Texture2D, visual: JuiceSkinVisual = null) -> void :
	_ensure_refs()
	if _flower == null:
		return
	_skin_visual = visual
	_flower.texture = tex
	_apply_skin_icon()
	_color_lock = true
	_flower.visible = true
	_num.visible = false
	_sync_wood_door()


func set_lock_visual_version(version: int) -> void :
	var selected: int = 3 if version == 3 else 1
	if _lock_visual_version == selected:
		return
	_lock_visual_version = selected
	_ensure_refs()
	_sync_wood_door()


func uses_wood_door() -> bool:
	return _lock_visual_version == 3


func wood_door_view() -> WoodDoorLock:
	return _wood_door


func _sync_wood_door() -> void :
	var use_wood: bool = uses_wood_door()
	_vine0.visible = not use_wood
	_vine1.visible = not use_wood and size.y / _geometry_scale > VINE_FRAME_H
	_badge.visible = not use_wood
	_flower.visible = not use_wood and _color_lock
	_num.visible = not use_wood and not _color_lock
	clip_contents = not use_wood
	if not use_wood:
		if is_instance_valid(_wood_door):
			_wood_door.stop()
		return
	if not is_instance_valid(_wood_door):
		_wood_door = WOOD_DOOR_SCENE.instantiate() as WoodDoorLock
		add_child(_wood_door)
	var width: float = WoodDoorLock.DESIGN_SIZE.x * _geometry_scale
	if _column_width > 0.0:
		width = minf(width, _column_width)
	_wood_door.position = Vector2((size.x - width) * 0.5, 0.0)
	_wood_door.configure(Vector2(width, size.y), 
		_flower.texture if _color_lock else null, -1 if _color_lock else _remaining_count, _skin_visual, _skin_resources)
	_wood_door.reset_closed()


func set_skin_resources(resources: JuiceSkinResolver) -> void :
	_skin_resources = resources
	_sync_wood_door()


func _apply_skin_icon() -> void :
	if _flower == null or not _flower_reference.has_area():
		return
	var rect: Rect2 = _skin_visual.display_rect(_flower_reference) if _skin_visual != null else _flower_reference
	_flower.position = rect.position
	_flower.size = rect.size
