class_name RankZoneBanner
extends Control


const BANNER_PITCH: float = 106.0

enum Kind{UPGRADE, DOWNGRADE}

const TEXT_KEY_UPGRADE: String = "RANK_ZONE_UPGRADE"
const TEXT_KEY_DOWNGRADE: String = "RANK_ZONE_DOWNGRADE"

@export var range_label: Label = null

@export var bg_upgrade: Texture2D = null
@export var bg_downgrade: Texture2D = null

@onready var _bg: TextureRect = $Bg
@onready var _text: Label = $Row / TextLabel


func setup(kind: Kind, from_rank: int, to_rank: int) -> void :
	_bg.texture = bg_upgrade if kind == Kind.UPGRADE else bg_downgrade
	var zone_text: String = tr(TEXT_KEY_UPGRADE if kind == Kind.UPGRADE else TEXT_KEY_DOWNGRADE)
	if range_label == null:
		_text.text = "%d-%d %s" % [from_rank, to_rank, zone_text]
		_center_number(_text)
		return
	_text.text = zone_text
	range_label.text = "%d-%d" % [from_rank, to_rank]
	var font: Font = _text.get_theme_font("font")
	var font_size: int = 48
	var range_width: float = 0.0
	var text_width: float = 0.0
	while font_size >= 28:
		range_width = font.get_string_size(range_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		text_width = font.get_string_size(zone_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if range_width + 16.0 + text_width <= 752.0:
			break
		font_size -= 2
	_text.add_theme_font_size_override("font_size", font_size)
	range_label.add_theme_font_size_override("font_size", font_size)
	var left: float = (984.0 - range_width - 16.0 - text_width) * 0.5
	range_label.offset_left = left
	range_label.offset_right = left + range_width
	_text.offset_left = left + range_width + 16.0
	_text.offset_right = left + range_width + 16.0 + text_width
	_center_number(range_label)


func _center_number(label: Label) -> void :
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var line: TextLine = TextLine.new()
	line.add_string(label.text, font, font_size, TranslationServer.get_locale())
	var rid: RID = font.get_rids()[0]
	var text_server: TextServer = TextServerManager.get_primary_interface()
	var glyph: int = text_server.font_get_glyph_index(rid, font_size, "0".unicode_at(0), 0)
	var glyph_offset: Vector2 = text_server.font_get_glyph_offset(rid, Vector2i(font_size, 0), glyph)
	var glyph_size: Vector2 = text_server.font_get_glyph_size(rid, Vector2i(font_size, 0), glyph)
	var correction: float = line.get_size().y * 0.5\
	- line.get_line_ascent() - glyph_offset.y - glyph_size.y * 0.5
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.offset_top = correction
	label.offset_bottom = correction
