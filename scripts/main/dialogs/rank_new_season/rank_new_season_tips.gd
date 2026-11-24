class_name RankNewSeasonTips
extends Control

const ICON_SIZE: float = 96.0
const BASE_FONT_SIZE: int = 54
const MIN_FONT_SIZE: int = 24
const ICON_KEY: StringName = &"collect"

@export var font: Font

@export var font_fit_width: float = 0.0

var paragraph: TextParagraph
var icon_texture: Texture2D
var icon_rect: Rect2
var text_origin: Vector2
var font_size: int = BASE_FONT_SIZE

func set_content(template: String, texture: Texture2D) -> void :
	icon_texture = texture
	var parts: PackedStringArray = template.split("%s", true, 1)
	font_size = BASE_FONT_SIZE
	while true:
		paragraph = TextParagraph.new()
		paragraph.width = font_fit_width if font_fit_width > 0.0 else size.x
		paragraph.alignment = HORIZONTAL_ALIGNMENT_CENTER
		paragraph.add_string(parts[0], font, font_size, TranslationServer.get_locale())


		paragraph.add_object(ICON_KEY, Vector2(ICON_SIZE, font.get_height(font_size)), INLINE_ALIGNMENT_CENTER)
		paragraph.add_string(parts[1], font, font_size, TranslationServer.get_locale())
		if paragraph.get_size().y <= size.y or font_size <= MIN_FONT_SIZE:
			break
		font_size -= 1
	paragraph.width = size.x
	text_origin = Vector2(0.0, (size.y - paragraph.get_size().y) * 0.5)
	var object_rect: Rect2
	for line: int in paragraph.get_line_count():
		if paragraph.get_line_objects(line).has(ICON_KEY):
			object_rect = paragraph.get_line_object_rect(line, ICON_KEY)
			break
	icon_rect = Rect2(object_rect.get_center() + text_origin - Vector2.ONE * ICON_SIZE * 0.5, 
		Vector2.ONE * ICON_SIZE)
	queue_redraw()

func _draw() -> void :
	if paragraph == null:
		return
	paragraph.draw(get_canvas_item(), text_origin, Color("232f3e"))
	if icon_texture != null:
		draw_texture_rect(icon_texture, icon_rect, false)
