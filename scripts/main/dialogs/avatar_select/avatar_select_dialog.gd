class_name AvatarSelectDialog
extends PageScene


signal closed

const GRID_COLUMNS: int = 4
const GRID_CELL_SIZE: float = 180.0

@export var cell_scene: PackedScene = null

@onready var _pool: RankAvatarPool = $AvatarPool
@onready var _scroll: ScrollContainer = $Root / Content / Dialog / ListBg / Scroll
@onready var _grid: GridContainer = $Root / Content / Dialog / ListBg / Scroll / GridMargin / Grid
@onready var _selection: TextureRect = $Root / Content / Dialog / ListBg / Scroll / GridMargin / SelectionLayer / Selected
@onready var _current: RankAvatarCell = $Root / Content / Dialog / CurrentAvatar
@onready var _name_input: LineEdit = $Root / Content / Dialog / NameBg / NameInput
@onready var _close_btn: TextureButton = $Root / Content / Dialog / CloseButton
@onready var _anim: AnimationPlayer = $Root / AnimationPlayer

var _cells: Array[RankAvatarCell] = []
var _selected_index: int = -1
var _selection_target: RankAvatarCell = null
var _closing: bool = false
var _generation: int = 0


func _ready() -> void :
	set_process(false)
	SceneManager.bind_press_release_scale(_close_btn)
	_name_input.max_length = RankManager.NICKNAME_MAX_LENGTH
	_grid.columns = GRID_COLUMNS
	_build_grid()
	ScrollDragHelper.attach(_scroll)


func _build_grid() -> void :
	for avatar_index in RankFakeUserGenerator.VISIBLE_AVATARS:
		var cell: RankAvatarCell = cell_scene.instantiate() as RankAvatarCell
		cell.custom_minimum_size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
		_grid.add_child(cell)
		cell.bind(avatar_index, _texture_for(avatar_index))
		cell.picked.connect(_on_cell_picked)
		_cells.append(cell)


func _on_show(_params: Dictionary = {}) -> void :
	set_meta(RankSessionFlow.DIALOG_LEASE, null)
	_generation += 1
	_closing = false
	UserState.mark_rank_avatar_dialog_shown()
	RankManager.ensure_profile()
	_selected_index = RankManager.get_display_avatar_index()
	_name_input.text = UserState.get_rank_nickname()
	_refresh_selection()
	set_process(true)
	visible = true

	Tracker.track_scr_show(TrackingEvents.SCR_EDIT_NAME)
	_anim.play_section_with_markers("GenericPopup", &"", &"Mark")


func _refresh_selection() -> void :
	_current.bind(_selected_index, _texture_for(_selected_index))
	_selection_target = null
	for cell in _cells:
		cell.set_selected(false)
		if cell.get_avatar_index() == _selected_index:
			_selection_target = cell
	_selection.visible = _selection_target != null
	_layout_selection()


func _process(_delta: float) -> void :

	_layout_selection()


func _layout_selection() -> void :
	if _selection_target == null:
		return
	var parent: Control = _selection.get_parent() as Control
	var transform: Transform2D = parent.get_global_transform().affine_inverse()\
	* _selection_target.get_global_transform()
	var inner: Rect2 = RankAvatarCell.SELECTED_INNER_RECT
	var factor: Vector2 = _selection_target.size / inner.size
	_selection.position = transform * ( - inner.position * factor)
	_selection.size = _selection.texture.get_size() * factor
	_selection.rotation = transform.get_rotation()
	_selection.scale = transform.get_scale()


func _on_cell_picked(avatar_index: int) -> void :
	_selected_index = avatar_index
	_refresh_selection()





func _on_hide() -> void :
	_generation += 1
	_closing = true
	set_process(false)
	_anim.stop()
	visible = false
	closed.emit()


func _on_confirm_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_EDIT_CONFIRM)
	if _name_input.text.strip_edges().is_empty():
		SceneManager.show_toast("RANK_AVATAR_NAME_EMPTY")
		return
	if RankManager.set_profile(_name_input.text, _selected_index):
		_close()


func _on_close_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_CLOSE)
	_close()


func _on_back_request() -> void :
	_close()


func _close() -> void :
	if _closing:
		return
	_closing = true
	var generation: int = _generation
	_anim.play_section_with_markers("GenericPopup", &"Mark", &"")
	while generation == _generation and _anim.is_playing():
		await get_tree().process_frame
	if generation != _generation:
		return
	set_process(false)
	visible = false
	closed.emit()


func _texture_for(avatar_index: int) -> Texture2D:
	return _pool.get_texture(avatar_index)


func get_cell_count() -> int:
	return _cells.size()


func get_cell_at(idx: int) -> RankAvatarCell:
	return _cells[idx] if idx >= 0 and idx < _cells.size() else null


func get_selected_index() -> int:
	return _selected_index
