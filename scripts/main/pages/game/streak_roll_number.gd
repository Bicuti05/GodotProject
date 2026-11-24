class_name StreakRollNumber
extends Control








const ROLL_DURATION: float = 0.55

const SHADOW_OFFSET_Y: float = 7.2
const OUTLINE_SIZE: int = 43
const MIN_FONT_SIZE: int = 80

@onready var _from: Label = $From
@onready var _to: Label = $To
@onready var _from_outline: Label = $FromOutline
@onready var _to_outline: Label = $ToOutline
@onready var _from_shadow: Label = $FromShadow
@onready var _to_shadow: Label = $ToShadow

var _generation: int = 0
var _tween: Tween = null
var _base_font_size: int = 228
var _box_height: float = 0.0


func _ready() -> void :
	mouse_filter = MOUSE_FILTER_IGNORE
	for label: Label in _all_labels():
		label.mouse_filter = MOUSE_FILTER_IGNORE
	_apply_layout()
	hide_now()
	get_viewport().size_changed.connect(_apply_layout)





func configure(
	font_size: int, 
	grad_top: Color, 
	grad_bottom: Color, 
	shadow: Color, 
	grad_dir: Vector2 = Vector2(0.0, 1.0), 
	grad_span: Vector2 = Vector2(0.0, 1.0)
) -> void :
	_base_font_size = font_size
	for label: Label in _all_labels():
		label.add_theme_font_size_override("font_size", font_size)
	for label: Label in [_from, _to]:
		label.add_theme_color_override("font_color", Color.WHITE)
		var mat: ShaderMaterial = label.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("grad_top", grad_top)
			mat.set_shader_parameter("grad_bottom", grad_bottom)
			mat.set_shader_parameter("grad_dir", grad_dir)
			mat.set_shader_parameter("grad_from", grad_span.x)
			mat.set_shader_parameter("grad_to", grad_span.y)
	for label: Label in [_from_outline, _to_outline]:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.0))
		label.add_theme_color_override("font_outline_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	for label: Label in [_from_shadow, _to_shadow]:
		label.add_theme_color_override("font_color", shadow)
		label.add_theme_color_override("font_outline_color", shadow)
		label.add_theme_constant_override("outline_size", OUTLINE_SIZE)


func prepare(from_value: int, to_value: int) -> void :
	hide_now()
	visible = true
	var from_text: String = str(maxi(from_value, 0))
	var to_text: String = str(maxi(to_value, 0))
	for label: Label in [_from, _from_outline, _from_shadow]:
		label.text = from_text
	for label: Label in [_to, _to_outline, _to_shadow]:
		label.text = to_text
	_fit_font_size()
	_apply_layout()
	for label: Label in [_from, _from_outline, _from_shadow]:
		label.visible = true



func play(from_value: int, to_value: int) -> void :
	prepare(from_value, to_value)
	for label: Label in _all_labels():
		label.visible = true
	var generation: int = _generation
	var start_y: float = _start_y()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_from_shadow, "position:y", start_y - size.y + SHADOW_OFFSET_Y, ROLL_DURATION)
	_tween.parallel().tween_property(_from_outline, "position:y", start_y - size.y, ROLL_DURATION)
	_tween.parallel().tween_property(_from, "position:y", start_y - size.y, ROLL_DURATION)
	_tween.parallel().tween_property(_to_shadow, "position:y", start_y + SHADOW_OFFSET_Y, ROLL_DURATION)
	_tween.parallel().tween_property(_to_outline, "position:y", start_y, ROLL_DURATION)
	_tween.parallel().tween_property(_to, "position:y", start_y, ROLL_DURATION)
	await _tween.finished
	if generation != _generation:
		return
	for label: Label in [_from, _from_outline, _from_shadow]:
		label.visible = false


func hide_now() -> void :
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	visible = false
	if is_node_ready():
		for label: Label in _all_labels():
			label.visible = false



func _fit_font_size() -> void :
	var font: Font = _from.get_theme_font("font")
	if font == null:
		return
	var max_width: float = maxf(size.x - 12.0, 1.0)
	var font_size: int = _base_font_size
	while font_size > MIN_FONT_SIZE:
		var from_width: float = font.get_string_size(_from.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		var to_width: float = font.get_string_size(_to.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		if maxf(from_width, to_width) <= max_width:
			break
		font_size -= 2
	for label: Label in _all_labels():
		label.add_theme_font_size_override("font_size", font_size)


func _apply_layout() -> void :


	_box_height = size.y
	for label: Label in _all_labels():
		_box_height = maxf(_box_height, label.get_combined_minimum_size().y)
	var start_y: float = _start_y()
	_place(_from_shadow, start_y + SHADOW_OFFSET_Y)
	_place(_from_outline, start_y)
	_place(_from, start_y)
	_place(_to_shadow, size.y + start_y + SHADOW_OFFSET_Y)
	_place(_to_outline, size.y + start_y)
	_place(_to, size.y + start_y)
	_sync_gradient_box()


func _place(label: Label, top_y: float) -> void :
	label.size = Vector2(size.x, _box_height)
	label.position = Vector2(0.0, top_y)




func _sync_gradient_box() -> void :
	var font: Font = _from.get_theme_font("font")
	if font == null:
		return
	var font_size: int = _from.get_theme_font_size("font_size")
	var text_width: float = 0.0
	for label: Label in [_from, _to]:
		if label.text.is_empty():
			continue
		text_width = maxf(
			text_width, 
			font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		)
	if text_width <= 0.0:
		return
	var line_height: float = font.get_height(font_size)
	var origin: = Vector2((size.x - text_width) * 0.5, (_box_height - line_height) * 0.5)
	for label: Label in [_from, _to]:
		var mat: ShaderMaterial = label.material as ShaderMaterial
		if mat == null:
			continue
		mat.set_shader_parameter("box_origin", origin)
		mat.set_shader_parameter("box_size", Vector2(text_width, line_height))


func _all_labels() -> Array[Label]:
	var labels: Array[Label] = [_from, _to, _from_outline, _to_outline, _from_shadow, _to_shadow]
	return labels


func _start_y() -> float:
	return (size.y - _box_height) * 0.5
