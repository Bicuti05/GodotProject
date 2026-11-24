class_name RankCollectBar
extends Control

const FONT_SIZE: int = 60
const TEXT_COLOR: Color = Color("232f3e")
const CONTENT_HEIGHT: float = 135.0
const TEXT_WIDTH_MIN: float = 86.153847
const TEXT_LEFT: float = 125.51294
const TEXT_RIGHT_INSET: float = 16.0
const RIGHT_OVERFLOW: float = 92.0
const BASE_WIDTH: float = TEXT_LEFT + TEXT_WIDTH_MIN + RIGHT_OVERFLOW + TEXT_RIGHT_INSET
const SHOW_SLIDE_SEC: float = 0.3
const HIDE_SLIDE_SEC: float = 0.3
const FLOAT_SEC: float = 0.65
const PUNCH_SCALE: float = 1.16
const PUNCH_SEC: float = 0.16

@onready var _icon: TextureRect = $Icon
@onready var _count_label: Label = $CountLabel
@onready var _delta_label: Label = $DeltaLabel

var _layout_top: float = 144.0
var _count: int = 0
var _slide_offset: float = 0.0
var _slide_tween: Tween
var _icon_impact: Tween
var _icon_base_position: Vector2
var _punch_tween: Tween
var _float_tween: Tween
var _generation: int = 0

func _ready() -> void :
	_count_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_count_label.add_theme_color_override("font_color", TEXT_COLOR)
	_icon_base_position = _icon.position
	reset_now()

func apply_layout(top_in_parent: float) -> void :
	_layout_top = top_in_parent
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	_apply_geometry()

func bind_element(tex: Texture2D) -> void :
	_icon.texture = tex

func set_count(value: int) -> void :
	_count = maxi(value, 0)
	_count_label.text = str(_count)
	_apply_geometry()

func get_count() -> int:
	return _count

func show_bar() -> bool:
	reset_now()
	var generation: int = _generation
	_slide_offset = size.x
	_apply_geometry()
	show()
	_slide_tween = create_tween()
	_slide_tween.tween_method(_set_slide_offset, _slide_offset, 0.0, SHOW_SLIDE_SEC)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return await _wait_tween(_slide_tween, generation)

func hide_bar() -> bool:
	var generation: int = _generation
	_slide_tween = create_tween()
	_slide_tween.tween_method(_set_slide_offset, _slide_offset, size.x, HIDE_SLIDE_SEC)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if not await _wait_tween(_slide_tween, generation):
		return false
	reset_now()
	return true

func float_delta(delta: int) -> bool:
	if delta <= 0:
		return true
	var generation: int = _generation
	_delta_label.text = "+%d" % delta
	_delta_label.position.y = -21.0
	_delta_label.modulate = Color.WHITE
	_delta_label.show()
	_apply_geometry()
	_float_tween = create_tween()
	_float_tween.set_parallel(true)
	_float_tween.tween_property(_delta_label, "position:y", -77.0, FLOAT_SEC)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_float_tween.tween_property(_delta_label, "modulate:a", 0.0, FLOAT_SEC * 0.5)\
	.set_delay(FLOAT_SEC * 0.5)
	if not await _wait_tween(_float_tween, generation):
		return false
	_delta_label.hide()
	return true

func reset_now() -> void :
	_generation += 1
	for tween: Tween in [_slide_tween, _punch_tween, _float_tween, _icon_impact]:
		if tween != null and tween.is_valid():
			tween.kill()
	_slide_tween = null
	_punch_tween = null
	_icon_impact = null
	_float_tween = null
	hide()
	modulate = Color.WHITE
	_slide_offset = 0.0
	if _icon != null:
		_icon.scale = Vector2.ONE
		_icon.position = _icon_base_position
	if _count_label != null:
		_count_label.scale = Vector2.ONE
	if _delta_label != null:
		_delta_label.hide()
		_delta_label.position.y = -21.0
		_delta_label.modulate = Color.WHITE
	_apply_geometry()

func punch_icon() -> void :
	if _punch_tween != null and _punch_tween.is_valid():
		_punch_tween.kill()
	_count_label.scale = Vector2.ONE
	_icon_impact = RankCollectImpact.play(self, _icon, _icon_base_position, Vector2.ONE, _icon_impact)
	_punch_tween = create_tween()
	_punch_tween.set_parallel(true)

	_punch_tween.tween_property(_count_label, "scale", Vector2.ONE * PUNCH_SCALE, PUNCH_SEC * 0.5)
	_punch_tween.chain().tween_property(_count_label, "scale", Vector2.ONE, PUNCH_SEC * 0.5)

func get_icon_global_rect() -> Rect2:
	return Rect2(get_global_transform() * _icon_base_position, _icon.size * get_global_transform().get_scale())

func _set_slide_offset(value: float) -> void :
	_slide_offset = value
	_apply_geometry()

func _apply_geometry() -> void :
	var width: float = TEXT_WIDTH_MIN
	if _count_label != null:
		width = maxf(_count_label.get_minimum_size().x, width)
	if _delta_label != null and _delta_label.visible:
		width = maxf(width, _delta_label.get_minimum_size().x)
	var extra: float = width - TEXT_WIDTH_MIN
	offset_left = RIGHT_OVERFLOW - BASE_WIDTH - extra + _slide_offset
	offset_right = RIGHT_OVERFLOW + _slide_offset
	offset_top = _layout_top
	offset_bottom = _layout_top + CONTENT_HEIGHT

	for label: Label in [_count_label, _delta_label]:
		if label != null:
			label.offset_left = TEXT_LEFT
			label.offset_right = - RIGHT_OVERFLOW - TEXT_RIGHT_INSET
	if _count_label != null:
		_count_label.pivot_offset = Vector2(_count_label.size.x, 36.0)

func _wait_tween(tween: Tween, generation: int) -> bool:
	while generation == _generation and tween.is_valid() and tween.is_running():
		await get_tree().process_frame
	return generation == _generation
