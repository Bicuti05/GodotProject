class_name HexBoard
extends Control




















const HEX_CENTER_DY: float = 41.0








const HEX_AREA_SIZE: Vector2 = Vector2(928.0, 856.0)



const CELL_COUNT: int = 25


const CENTER_CELL: int = 24













const COVER_SCALE: float = 1.03


const POP_GAP_SEC: float = 0.12

@onready var _picture: TextureRect = $Picture
@onready var _covers: Node2D = $Covers
@onready var _reveal_effect: HexRevealEffect = $RevealEffect



@onready var _section_title: CurveLabel = $SectionTitle
@onready var _progress_label: Label = $ProgressLabel


var _cells: Array[Sprite2D] = []
var _reveal_generation: int = 0


func _ready() -> void :
	for child in _covers.get_children():
		var s: = child as Sprite2D
		if s != null:
			_cells.append(s)
	if _cells.size() != CELL_COUNT:
		SortLogger.error("HexBoard: 盖子数量 %d,期望 %d(hex_board.tscn 被改过?)" % [_cells.size(), CELL_COUNT])
	for cell in _cells:
		cell.scale = _base_scale()



func _base_scale() -> Vector2:
	return Vector2.ONE * COVER_SCALE



func set_picture(tex: Texture2D) -> void :
	_picture.texture = tex




func apply_revealed(revealed: Array) -> void :
	cancel_reveal()
	for i in _cells.size():
		var s: Sprite2D = _cells[i]
		s.scale = _base_scale()
		s.modulate.a = 1.0
		s.visible = not revealed.has(i)




func play_reveal(idx: int) -> void :
	if idx < 0 or idx >= _cells.size():
		return
	cancel_reveal()
	var generation: int = _reveal_generation
	var cell: Sprite2D = _cells[idx]
	if not cell.visible:
		return
	_reveal_effect.play_cell(idx, cell)
	AudioManager.play_sfx(&"outerloop_pieces_unlock")
	HapticManager.play_event(HapticManager.Event.HEX_BREAK)
	await get_tree().create_timer(HexRevealEffect.COVER_HIDE_SEC).timeout
	if generation != _reveal_generation or not is_visible_in_tree():
		return
	cell.visible = false
	await get_tree().create_timer(HexRevealEffect.DURATION_SEC - HexRevealEffect.COVER_HIDE_SEC).timeout
	if generation != _reveal_generation or not is_visible_in_tree():
		return
	_reveal_effect.stop()
	await get_tree().create_timer(POP_GAP_SEC).timeout



func cancel_reveal() -> void :
	_reveal_generation += 1
	if is_node_ready():
		_reveal_effect.stop()



func set_progress(done: int, total: int) -> void :
	_progress_label.text = "%d/%d" % [done, total]



func set_title(title: String) -> void :
	_section_title.minimum_word_gap = 12.0
	_section_title.text = title




func hex_center_global() -> Vector2:
	var rect: Rect2 = get_global_rect()
	return rect.get_center() + Vector2(0.0, HEX_CENTER_DY * rect.size.y / size.y)





func hex_outer_size() -> Vector2:
	var rect: Rect2 = get_global_rect()
	return HEX_AREA_SIZE * (rect.size.y / size.y)
