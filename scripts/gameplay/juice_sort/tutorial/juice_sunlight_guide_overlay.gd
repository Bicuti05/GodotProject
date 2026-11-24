class_name JuiceSunlightGuideOverlay
extends Control



signal closed(acknowledged: bool)

const DESC_KEY: = "JUICE_SUNLIGHT_GUIDE_DESC"
const TAP_KEY: = "JUICE_LOCK_GUIDE_TAP"
const FADE_IN_TIME: float = 0.25
const FADE_OUT_TIME: float = 0.18
const DESC_BOTTOM: float = 600.0
const DESC_MIN_HEIGHT: float = 280.0
const DESC_ART_GAP: float = 48.0
const DESC_TOP_PADDING: float = 32.0

var _dim: ColorRect
var _art: Node2D
var _template: Sprite2D
var _desc: Label
var _tap: Label
var _desc_base_font_size: int = 0
var _sprites: Array[Sprite2D] = []
var _visuals: Array[Dictionary] = []
var _open: bool = false
var _interactive: bool = false
var _closing: bool = false
var _tween: Tween


func _ensure_refs() -> void :
	if _dim != null:
		return
	_dim = get_node("Root/Dim") as ColorRect
	_art = get_node("Root/Art") as Node2D
	_template = get_node("Root/Art/Template") as Sprite2D
	_desc = get_node("Root/Desc") as Label
	_tap = get_node("Root/Tap") as Label
	_desc_base_font_size = _desc.get_theme_font_size(&"font_size")
	set_process(false)


func open(visuals: Array[Dictionary]) -> void :
	_ensure_refs()
	_kill_tween()
	_visuals = visuals
	_open = true
	_closing = false
	_interactive = false
	while _sprites.size() < visuals.size():
		var sprite: Sprite2D = _template.duplicate(0) as Sprite2D
		sprite.name = "Highlight%d" % _sprites.size()
		_art.add_child(sprite)
		_sprites.append(sprite)
	_desc.text = tr(DESC_KEY)
	_tap.text = tr(TAP_KEY)
	_layout()
	visible = true
	modulate.a = 0.0
	set_process(true)
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 1.0, FADE_IN_TIME)
	_tween.tween_callback( func() -> void : _interactive = true)


func close(immediate: bool = false) -> void :
	if not _open or (_closing and not immediate):
		return
	_interactive = false
	_closing = true
	_kill_tween()
	if immediate:
		_finish_close(false)
		return
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 0.0, FADE_OUT_TIME)
	_tween.tween_callback( func() -> void : _finish_close(true))


func is_open() -> bool:
	return _open


func _finish_close(acknowledged: bool) -> void :
	_open = false
	_closing = false
	visible = false
	modulate.a = 0.0
	set_process(false)
	_visuals.clear()
	for sprite: Sprite2D in _sprites:
		sprite.hide()
		sprite.texture = null
		sprite.material = null
	closed.emit(acknowledged)


func _process(_delta: float) -> void :
	_update_art()



func _update_art() -> void :
	var inverse: Transform2D = _art.get_global_transform_with_canvas().affine_inverse()
	for index: int in _sprites.size():
		var sprite: Sprite2D = _sprites[index]
		if index >= _visuals.size():
			sprite.hide()
			continue
		var visual: Dictionary = _visuals[index]
		var source_ref: WeakRef = visual.get("source") as WeakRef
		if source_ref != null:
			var source: Sprite2D = source_ref.get_ref() as Sprite2D
			if not is_instance_valid(source) or not source.is_visible_in_tree():
				sprite.hide()
				continue
			sprite.texture = source.texture
			sprite.centered = source.centered
			sprite.offset = source.offset
			sprite.flip_h = source.flip_h
			sprite.flip_v = source.flip_v
			sprite.hframes = source.hframes
			sprite.vframes = source.vframes
			sprite.frame = source.frame
			sprite.region_enabled = source.region_enabled
			sprite.region_rect = source.region_rect
			sprite.region_filter_clip_enabled = source.region_filter_clip_enabled
			sprite.material = source.material
			sprite.modulate = _source_modulate(source)
			sprite.self_modulate = source.self_modulate
			sprite.texture_filter = source.texture_filter
			sprite.transform = inverse * source.get_global_transform_with_canvas()
		else:
			sprite.texture = visual["texture"] as Texture2D
			sprite.centered = true
			sprite.offset = Vector2.ZERO
			sprite.flip_h = false
			sprite.flip_v = false
			sprite.hframes = 1
			sprite.vframes = 1
			sprite.frame = 0
			sprite.region_enabled = false
			sprite.material = null
			sprite.transform = inverse * (visual["transform"] as Transform2D)
			sprite.modulate = Color.WHITE
			sprite.self_modulate = Color.WHITE
		sprite.visible = sprite.texture != null


func _source_modulate(source: CanvasItem) -> Color:
	var color: Color = source.modulate
	var parent: CanvasItem = null if source.is_set_as_top_level() else (source.get_parent() as CanvasItem)
	while parent != null:
		color *= parent.modulate
		parent = null if parent.is_set_as_top_level() else (parent.get_parent() as CanvasItem)
	return color


func _gui_input(event: InputEvent) -> void :
	if not _interactive:
		return
	var released: bool = event is InputEventMouseButton\
	and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT\
	and not (event as InputEventMouseButton).pressed
	if released or (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed):
		accept_event()
		close()


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED and _open:
		_layout()


func _layout() -> void :
	size = UiMetrics.viewport_size()
	_dim.size = size
	_update_art()

	var desc_bottom: float = DESC_BOTTOM
	var inverse: Transform2D = _desc.get_parent().get_global_transform_with_canvas().affine_inverse()
	for sprite: Sprite2D in _sprites:
		if not sprite.visible:
			continue
		var rect: Rect2 = (inverse * sprite.get_global_transform_with_canvas()) * sprite.get_rect()
		desc_bottom = minf(desc_bottom, rect.position.y - DESC_ART_GAP)
	var safe_top: float = UiMetrics.safe_insets().x + DESC_TOP_PADDING
	var font_size: int = _desc_base_font_size
	_desc.add_theme_font_size_override(&"font_size", font_size)
	var text_h: float = _desc.get_minimum_size().y
	while font_size > 1 and desc_bottom - text_h < safe_top:
		font_size -= 1
		_desc.add_theme_font_size_override(&"font_size", font_size)
		text_h = _desc.get_minimum_size().y
	var desc_h: float = maxf(DESC_MIN_HEIGHT, text_h)
	_desc.size = Vector2(_desc.size.x, desc_h)
	_desc.position = Vector2(UiMetrics.center_left(_desc.size.x), desc_bottom - desc_h)
	_tap.position = Vector2(UiMetrics.center_left(_tap.size.x), size.y - 392.0)


func _kill_tween() -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
