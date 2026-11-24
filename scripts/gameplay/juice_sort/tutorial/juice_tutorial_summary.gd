class_name JuiceTutorialSummary
extends Control


@export var font: Font
@export var connect_icon: Texture2D
@export var collect_icon: Texture2D
@export var empty_rope_icon: Texture2D
const KEYS: = ["JUICE_RULE_CONNECT_SAME_COLOR", "JUICE_RULE_COLLECT_BY_COLOR", "JUICE_RULE_USE_EMPTY_ROPES"]
var active_rule: int = -1
var _labels: Array[Label] = []
var _panel: = StyleBoxFlat.new()
var _active: = StyleBoxFlat.new()


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.bg_color = Color("#fffdf4")
	_panel.border_color = Color("#bdd6bc")
	_panel.set_border_width_all(2)
	_panel.set_corner_radius_all(28)
	_active.bg_color = Color("#e7f3df")
	_active.set_corner_radius_all(22)
	for index: int in 3:
		var label: = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_color_override("font_color", Color("#41634f"))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_constant_override("line_spacing", 0)
		label.text = tr(KEYS[index])
		add_child(label)
		_labels.append(label)
	resized.connect(_layout)
	_layout()


func set_active_rule(index: int) -> void :
	active_rule = index
	for item: int in _labels.size():
		_labels[item].text = tr(KEYS[item])
	_layout()


func _layout() -> void :
	var part: float = size.x / 3.0
	for index: int in _labels.size():
		_labels[index].position = Vector2(part * index + 90, 18)
		_labels[index].add_theme_font_size_override("font_size", 40)
		_labels[index].size = Vector2(part - 100, size.y - 36)
		var font_size: int = 40
		while font_size > 18 and _labels[index].get_minimum_size().y > size.y - 36:
			font_size -= 1
			_labels[index].add_theme_font_size_override("font_size", font_size)
		_labels[index].size = Vector2(part - 100, size.y - 36)
	queue_redraw()


func _draw() -> void :
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	var part: float = size.x / 3.0
	if active_rule >= 0 and active_rule < 3:
		draw_style_box(_active, Rect2(part * active_rule + 7, 7, part - 14, size.y - 14))
	for index: int in [1, 2]:
		draw_line(Vector2(part * index, 36), Vector2(part * index, size.y - 36), Color("#ccddc8"), 2, true)
	var icons: Array[Texture2D] = [connect_icon, collect_icon, empty_rope_icon]
	for index: int in icons.size():
		_tex(icons[index], Rect2(part * index + 10, 24, 72, size.y - 48))


func _tex(texture: Texture2D, rect: Rect2) -> void :
	if texture == null:
		return
	var fitted: Vector2 = texture.get_size() * minf(rect.size.x / texture.get_width(), rect.size.y / texture.get_height())
	draw_texture_rect(texture, Rect2(rect.get_center() - fitted * 0.5, fitted), false)
