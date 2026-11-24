class_name JuiceLockGuideOverlay
extends Control





































signal closed

const TITLE_KEY: = "JUICE_LOCK_GUIDE_TITLE"

const DESC_COLOR_KEY: = "JUICE_LOCK_GUIDE_DESC_COLOR"

const DESC_COUNT_KEY: = "JUICE_LOCK_GUIDE_DESC_COUNT"
const TAP_KEY: = "JUICE_LOCK_GUIDE_TAP"

const FADE_IN_TIME: = 0.25
const FADE_OUT_TIME: = 0.18

var _dim: ColorRect = null
var _lock_art: JuiceLockOverlay = null
var _title: Label = null
var _desc: Label = null
var _tap: Label = null

var _open: bool = false

var _interactive: bool = false

var _art_global: Rect2 = Rect2()
var _column_width_ratio: float = 0.0
var _tween: Tween = null




func _ensure_refs() -> void :
	if _dim != null:
		return
	_dim = get_node_or_null("Root/Dim") as ColorRect
	_lock_art = get_node_or_null("Root/LockArt") as JuiceLockOverlay
	_title = get_node_or_null("Root/Title") as Label
	_desc = get_node_or_null("Root/Desc") as Label
	_tap = get_node_or_null("Root/Tap") as Label
	if _dim == null or _lock_art == null\
	or _title == null or _desc == null or _tap == null:
		SortLogger.error("JuiceLockGuideOverlay: 场景结构不完整(缺 Dim / LockArt / Title / Desc / Tap)")








func open(art_global: Rect2, condition: String, remaining: int, 
		flower_tex: Texture2D = null, visual_version: int = 1, column_width_ratio: float = 0.0, visual: JuiceSkinVisual = null, resources: JuiceSkinResolver = null) -> void :
	_ensure_refs()
	if _dim == null:
		return
	_open = true
	_interactive = false
	_art_global = art_global
	_column_width_ratio = column_width_ratio
	_lock_art.set_lock_visual_version(visual_version)
	_title.text = tr(TITLE_KEY)
	if condition == JuiceLevel.LOCK_COLLECT_COUNT:
		_desc.text = tr(DESC_COUNT_KEY).format({"N": maxi(0, remaining)})
		_lock_art.show_count(maxi(0, remaining))
	else:
		_desc.text = tr(DESC_COLOR_KEY)
		_lock_art.show_flower(flower_tex, visual)
		_lock_art.set_skin_resources(resources)
	_tap.text = tr(TAP_KEY)
	_layout()
	visible = true
	modulate.a = 0.0
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 1.0, FADE_IN_TIME)
	_tween.tween_callback( func() -> void : _interactive = true)




func close(immediate: bool = false) -> void :
	if not _open:
		return
	_open = false
	_interactive = false
	_kill_tween()
	if immediate:
		visible = false
		modulate.a = 0.0
		closed.emit()
		return
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 0.0, FADE_OUT_TIME)
	_tween.tween_callback( func() -> void :
		visible = false
		closed.emit())


func is_open() -> bool:
	return _open




func _gui_input(event: InputEvent) -> void :
	if not _interactive:
		return
	var released: bool = (event is InputEventMouseButton
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
		and not (event as InputEventMouseButton).pressed)
	if released or (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed):
		accept_event()
		close(false)


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED and _open:
		_layout()











func _layout() -> void :
	_ensure_refs()
	if _dim == null:
		return
	_dim.position = Vector2.ZERO
	_dim.size = UiMetrics.viewport_size()
	var r: Rect2 = get_global_transform().affine_inverse() * _art_global
	if r.size.x <= 0.0 or r.size.y <= 0.0:

		_lock_art.visible = false
		return
	var fruit_d: float = r.size.x / JuiceLockOverlay.FRAME_W * JuiceLockOverlay.DESIGN_FRUIT_D
	_lock_art.visible = true
	_lock_art.set_geometry(r.position.x + r.size.x * 0.5, r.position.y, r.size.y, fruit_d, _column_width_ratio * fruit_d)


func _kill_tween() -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
