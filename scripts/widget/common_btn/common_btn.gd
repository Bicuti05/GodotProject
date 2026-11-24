@tool
class_name CommonBtn
extends Button





















enum Variant{PRIMARY, SECONDARY, TERTIARY, HARD, LIGHT_RED, SUPER_HARD}


const _FACE: Dictionary = {
	Variant.PRIMARY: preload("res://assets/sprites/common_btn_bg_primary.png"), 
	Variant.SECONDARY: preload("res://assets/sprites/common_btn_bg_secondary.png"), 
	Variant.TERTIARY: preload("res://assets/sprites/common_btn_bg_tertiary.png"), 
	Variant.HARD: preload("res://assets/sprites/common_btn_bg_red.png"), 
	Variant.LIGHT_RED: preload("res://assets/sprites/common_btn_bg_light_red.png"), 
	Variant.SUPER_HARD: preload("res://assets/sprites/common_btn_bg_purple.png"), 
}

const _BASE_FONT_SIZE: int = 102
const _MIN_FONT_SIZE: int = 1



const _TEXT_SIDE_PADDING: float = 64.0


const _BOTTOM_LIP: float = 16.0

const _CONTENT_TOP: float = 8.0

const _CONTENT_BOTTOM_SINGLE: float = 32.0

const _SUB_ROW_EXTRA: float = 24.0

const _SUB_ROW_CENTER: float = 148.0

const _SUB_FONT_SIZE: int = 52




const _ICON_TEXT_SEPARATION: float = 14.0



const _GRAY_SHADER: Shader = preload("res://assets/shaders/disabled_gray.gdshader")
static var _gray_mat: ShaderMaterial









static func apply_disabled_gray(node: CanvasItem, on: bool) -> void :
	if node == null:
		return
	if on and _gray_mat == null:
		_gray_mat = ShaderMaterial.new()
		_gray_mat.shader = _GRAY_SHADER
	var mat: ShaderMaterial = _gray_mat if on else null
	node.material = mat
	_apply_gray_to_descendants(node, on, mat)





const _GRAY_TARGET_META: StringName = &"_common_btn_gray_target"
static func _apply_gray_to_descendants(node: Node, on: bool, mat: ShaderMaterial) -> void :
	for child in node.get_children():
		if child is CanvasItem:
			var ci: CanvasItem = child as CanvasItem
			if ci.has_meta(_GRAY_TARGET_META) or ci.use_parent_material:
				ci.set_meta(_GRAY_TARGET_META, true)
				ci.use_parent_material = not on
				ci.material = mat if on else null
		_apply_gray_to_descendants(child, on, mat)

@export var variant: Variant = Variant.PRIMARY:
	set(value):
		variant = value
		_apply_variant()

@export var face_override: Texture2D:
	set(value):
		face_override = value
		_apply_variant()
@export var btn_text: String = "":
	set(value):
		btn_text = value
		_apply_text()
@export var btn_icon: Texture2D = null:
	set(value):
		btn_icon = value
		_apply_icon()
@export var btn_icon_size: Vector2 = Vector2(133.547, 122.1):
	set(value):
		btn_icon_size = value
		_apply_icon()
@export var btn_icon_gap: float = 8.523:
	set(value):
		btn_icon_gap = value
		_apply_icon()


@export var auto_fit_text: bool = true:
	set(value):
		auto_fit_text = value
		_apply_text()


@export var base_font_size: int = _BASE_FONT_SIZE:
	set(value):
		base_font_size = value
		_apply_text()


@export var min_font_size: int = _MIN_FONT_SIZE:
	set(value):
		min_font_size = value
		_apply_text()


@export_range(0.0, 1.0) var side_padding_scale: float = 1.0:
	set(value):
		side_padding_scale = value
		_apply_text()





@export var btn_sub_text: String = "":
	set(value):
		btn_sub_text = value
		_apply_sub()



@export var btn_sub_icon: Texture2D = null:
	set(value):
		btn_sub_icon = value
		_apply_sub()

@export var sub_font_size: int = _SUB_FONT_SIZE:
	set(value):
		sub_font_size = value
		_apply_sub()

@export var sub_font_color: Color = Color.WHITE:
	set(value):
		sub_font_color = value
		_apply_sub()

@onready var _tex: NinePatchRect = $Tex
@onready var _contents: HBoxContainer = $Contents
@onready var _icon: TextureRect = $Contents / Icon
@onready var _text_group: Control = $Contents / TextGroup
@onready var _label: Label = $Contents / TextGroup / Label
@onready var _sub_row: HBoxContainer = $SubRow
@onready var _sub_icon: TextureRect = $SubRow / SubIcon
@onready var _sub_text_group: Control = $SubRow / SubTextGroup
@onready var _sub_label: Label = $SubRow / SubTextGroup / SubLabel

@onready var _wave_label: RichTextLabel = $Contents / TextGroup / WaveLabel
@onready var _sub_wave_label: RichTextLabel = $SubRow / SubTextGroup / SubWaveLabel



var _fitted_font_size: int = _BASE_FONT_SIZE

var _wave_effect: WaveJumpEffect = null
var _sub_wave_effect: WaveJumpEffect = null


func _ready() -> void :
	_apply_variant()
	_apply_icon()
	_apply_text()
	_apply_sub()
	apply_disabled_gray(self, disabled)



func set_button_disabled(value: bool) -> void :
	disabled = value
	apply_disabled_gray(self, value)


func _apply_variant() -> void :
	if not is_node_ready():
		return
	_tex.texture = face_override if face_override != null else _FACE[variant]
	_update_wave_visibility()



func _wave_enabled() -> bool:
	return variant == Variant.HARD or variant == Variant.SUPER_HARD




func _update_wave_visibility() -> void :
	var wave: bool = _wave_enabled()
	var wave_just_enabled: bool = wave and not _wave_label.visible
	_label.visible = not wave
	_wave_label.visible = wave
	_sub_wave_label.visible = wave and btn_sub_text != ""
	_sub_label.visible = not wave
	if wave:
		_apply_wave_text()
		if wave_just_enabled:
			_restart_wave()



func _restart_wave() -> void :
	if _wave_effect != null:
		_wave_effect.restart()




func _apply_wave_text() -> void :
	if _wave_effect == null and not _wave_label.custom_effects.is_empty():
		_wave_effect = _wave_label.custom_effects[0] as WaveJumpEffect
	if _sub_wave_effect == null and not _sub_wave_label.custom_effects.is_empty():
		_sub_wave_effect = _sub_wave_label.custom_effects[0] as WaveJumpEffect
	_fill_wave_label(_wave_label, _wave_effect, tr(btn_text), _label)
	if btn_sub_text != "":
		_fill_wave_label(_sub_wave_label, _sub_wave_effect, tr(btn_sub_text), _sub_label)


func _fill_wave_label(rich: RichTextLabel, effect: WaveJumpEffect, text: String, src: Label) -> void :
	var font_size: int = src.get_theme_font_size("font_size")
	rich.add_theme_font_size_override("normal_font_size", font_size)
	rich.add_theme_font_size_override("bold_font_size", font_size)
	rich.add_theme_constant_override("outline_size", src.get_theme_constant(&"outline_size"))


	rich.fit_content = false
	rich.text = "[center][wave_jump]%s[/wave_jump][/center]" % text.replace("[", "[lb]")
	var font: Font = src.get_theme_font("font")
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x\
	if font != null else 0.0



	var line_h: float = float(rich.get_content_height())
	if line_h <= 0.0:
		line_h = font.get_height(font_size) if font != null else float(font_size)
	rich.custom_minimum_size = Vector2(ceilf(text_w) + 4.0, ceilf(line_h))
	if effect != null:
		effect.set_source_text(text)


func _apply_text() -> void :
	if not is_node_ready():
		return
	_label.text = btn_text
	_fit_text_font_size()
	_update_wave_visibility()


func _apply_icon() -> void :
	if not is_node_ready():
		return
	_icon.texture = btn_icon
	_icon.visible = btn_icon != null
	_icon.custom_minimum_size = btn_icon_size
	_contents.add_theme_constant_override("separation", roundi(btn_icon_gap) if _icon.visible else 14)
	_apply_text()




func _apply_sub() -> void :
	if not is_node_ready():
		return
	var two_line: bool = btn_sub_text != ""
	_sub_row.visible = two_line
	_sub_label.text = btn_sub_text
	_sub_label.add_theme_color_override("font_color", sub_font_color)
	_sub_wave_label.add_theme_color_override("default_color", sub_font_color)
	_sub_icon.texture = btn_sub_icon
	_sub_icon.visible = btn_sub_icon != null
	_layout_rows()
	_fit_sub_font_size()
	_update_wave_visibility()






func _layout_rows() -> void :
	_contents.offset_top = _CONTENT_TOP
	if btn_sub_text == "":
		_contents.offset_bottom = - _CONTENT_BOTTOM_SINGLE
		return
	_contents.offset_bottom = - (_CONTENT_BOTTOM_SINGLE + _SUB_ROW_EXTRA)
	var sub_h: float = float(sub_font_size)
	if _sub_icon.visible:
		sub_h = maxf(sub_h, _sub_icon.custom_minimum_size.y)
	_sub_row.offset_top = _SUB_ROW_CENTER - sub_h * 0.5
	_sub_row.offset_bottom = _SUB_ROW_CENTER + sub_h * 0.5 - size.y




func _fit_sub_font_size() -> void :
	if btn_sub_text == "":
		return
	var font_size: int = sub_font_size
	var font: Font = _sub_label.get_theme_font("font")
	var rendered: String = tr(btn_sub_text)
	var icon_reserved: float = (_sub_icon.custom_minimum_size.x + _ICON_TEXT_SEPARATION) if _sub_icon.visible else 0.0
	var side_reserved: float = _TEXT_SIDE_PADDING * side_padding_scale\
	+ float(_sub_label.get_theme_constant(&"outline_size"))
	var max_width: float = size.x - side_reserved * 2.0 - icon_reserved
	var text_width: float = 0.0
	if font != null and rendered != "":
		text_width = font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
		if auto_fit_text and max_width > 0.0:
			while font_size > min_font_size and text_width > max_width:
				font_size -= 2
				text_width = font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
	_sub_label.add_theme_font_size_override("font_size", font_size)
	_sub_text_group.custom_minimum_size.x = text_width










func _fit_text_font_size() -> void :
	var font_size: int = base_font_size
	var font: Font = _label.get_theme_font("font")
	var rendered: String = tr(btn_text)
	var side_reserved: float = _TEXT_SIDE_PADDING * side_padding_scale\
	+ float(_label.get_theme_constant(&"outline_size"))
	var max_width: float = size.x - side_reserved * 2.0
	if _icon.visible:
		max_width -= _icon.custom_minimum_size.x + float(_contents.get_theme_constant("separation"))
	var text_width: float = 0.0
	if font != null and rendered != "":
		text_width = font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
		if auto_fit_text and max_width > 0.0:
			while font_size > min_font_size and text_width > max_width:
				font_size -= 2
				text_width = font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
	_label.add_theme_font_size_override("font_size", font_size)
	_text_group.custom_minimum_size.x = text_width

	_fitted_font_size = font_size
	_layout_rows()



func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_text()
		_apply_sub()
	elif what == NOTIFICATION_RESIZED and is_node_ready():

		_layout_rows()
		if auto_fit_text:
			_fit_text_font_size()
			_fit_sub_font_size()
