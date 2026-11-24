extends Node2D


const GRADIENT_SHADER = preload("res://assets/shaders/daily_checkin/text_gradient.gdshader")

@export var text: = "":
	set(value):
		text = value
		_refresh_ink()
@export var font: Font
@export var font_size: = 60:
	set(value):
		font_size = value
		_refresh_ink()
@export var box_size: = Vector2(400, 80):
	set(value):
		box_size = value
		_refresh_ink()
@export var color: = Color.WHITE:
	set(value):
		color = value
		_refresh_ink()
@export var outline_color: = Color("a2371b")
@export var outline_size: = 0
@export var fit_width: = true
@export var vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	set(value):
		vertical_alignment = value
		_refresh_ink()
@export var line_height_ratio: float = 0.0:
	set(value):
		line_height_ratio = value
		_refresh_ink()
@export var glyph_scale: = Vector2.ONE:
	set(value):
		glyph_scale = value
		_refresh_ink()
@export var glyph_offset: = Vector2.ZERO:
	set(value):
		glyph_offset = value
		_refresh_ink()
var shadow_offset: = Vector2.ZERO:
	set(value):
		shadow_offset = value
		if _style_material != null:
			_style_material.set_shader_parameter("shadow_offset", value)
			_refresh_ink()
var shadow_color: = Color("a2371b")
var _style_material: ShaderMaterial
var _mask: SubViewport
var _ink: Node2D
var _gradient_sprite: Sprite2D

func _ready() -> void :
	if outline_size > 0:
		_ensure_live_mask()

func configure_gradient(top: Color, bottom: Color, first_stop: float = 0.0) -> void :
	_ensure_live_mask()
	_style_material.set_shader_parameter("gradient_enabled", true)
	_style_material.set_shader_parameter("top_color", top)
	_style_material.set_shader_parameter("bottom_color", bottom)
	_style_material.set_shader_parameter("first_stop", first_stop)

func _ensure_live_mask() -> void :
	if _mask != null:
		return
	_mask = $LiveGlyphMask
	_mask.render_target_update_mode = SubViewport.UPDATE_ONCE
	_ink = $LiveGlyphMask / Ink
	_ink.renderer = self
	_gradient_sprite = $LiveStyledGlyphs
	_gradient_sprite.texture = _mask.get_texture()
	_style_material = ShaderMaterial.new()
	_style_material.shader = GRADIENT_SHADER
	_style_material.set_shader_parameter("glyph_mask_texture", _mask.get_texture())
	_style_material.set_shader_parameter("mask_pixel_size", Vector2.ONE / Vector2(_mask.size))
	_style_material.set_shader_parameter("fill_color", color)
	_style_material.set_shader_parameter("outline_color", outline_color)
	_style_material.set_shader_parameter("outline_width", float(outline_size))
	_style_material.set_shader_parameter("shadow_color", shadow_color)
	_style_material.set_shader_parameter("shadow_offset", shadow_offset)
	_style_material.set_shader_parameter("content_size", box_size)
	_gradient_sprite.material = _style_material
	_refresh_ink()

func _refresh_ink() -> void :
	queue_redraw()
	if _ink == null:
		return
	var padding: int = _mask_padding()
	_mask.size = Vector2i(ceili(box_size.x) + padding * 2, ceili(box_size.y) + padding * 2)
	_ink.position = Vector2(padding, padding)
	_gradient_sprite.position = Vector2( - padding, - padding)
	_style_material.set_shader_parameter("mask_pixel_size", Vector2.ONE / Vector2(_mask.size))
	_style_material.set_shader_parameter("padding", float(padding))
	_style_material.set_shader_parameter("content_size", box_size)
	_style_material.set_shader_parameter("fill_color", color)
	_ink.queue_redraw()
	_mask.render_target_update_mode = SubViewport.UPDATE_ONCE

func _mask_padding() -> int:
	var bounds: Rect2 = Rect2(Vector2.ZERO, box_size)
	var pivot: Vector2 = box_size * 0.5
	var glyph_transform: Transform2D = Transform2D(0.0, glyph_scale, 0.0, pivot + glyph_offset)
	var ts: TextServer = TextServerManager.get_primary_interface()
	for row: Dictionary in _layout():
		var line: TextLine = TextLine.new()
		line.add_string(row.line, font, row.size)
		var cursor: Vector2 = Vector2(row.point) - pivot
		for glyph: Dictionary in ts.shaped_text_get_glyphs(line.get_rid()):
			var ink: Rect2 = Rect2()
			if glyph.font_rid.is_valid() and glyph.index != 0:
				var key: Vector2i = Vector2i(int(row.size), 0)
				ts.font_render_glyph(glyph.font_rid, key, glyph.index)
				ink = Rect2(ts.font_get_glyph_offset(glyph.font_rid, key, glyph.index), 
					ts.font_get_glyph_size(glyph.font_rid, key, glyph.index))
			for _repeat_index: int in int(glyph.repeat):
				if ink.has_area():
					bounds = bounds.merge(glyph_transform * Rect2(cursor + Vector2(glyph.offset) + ink.position, ink.size))
				cursor.x += float(glyph.advance)

	bounds = bounds.grow(float(outline_size) + 2.0)
	bounds = bounds.merge(Rect2(bounds.position + shadow_offset, bounds.size))
	var overflow: Vector2 = ( - bounds.position).max(bounds.end - box_size)
	return maxi(20, ceili(maxf(overflow.x, overflow.y)))

func _layout() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if font == null or text.is_empty():
		return rows
	var lines: = text.split("\n")
	var size: = font_size
	if fit_width:
		for line in lines:
			var width: = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			if width > box_size.x:
				size = mini(size, int(floor(font_size * box_size.x / width)))
	var font_height: float = font.get_height(size)
	var line_height: float = size * line_height_ratio if line_height_ratio > 0.0 else font_height
	var block_offset: float = 0.0
	if vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		block_offset = (box_size.y - lines.size() * line_height) * 0.5
	elif vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
		block_offset = box_size.y - lines.size() * line_height
	var first_baseline: float = block_offset + (line_height - font_height) * 0.5 + font.get_ascent(size)
	for index in lines.size():
		var width: = font.get_string_size(lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		rows.append({"line": lines[index], "size": size, "point": Vector2((box_size.x - width) * 0.5, first_baseline + index * line_height)})
	return rows

func draw_fill(canvas: RID, fill: Color) -> void :
	var pivot: = box_size * 0.5

	var owner_node: Node2D = _ink if _mask != null else self
	owner_node.draw_set_transform(pivot + glyph_offset, 0.0, glyph_scale)
	for row in _layout():
		font.draw_string(canvas, row.point - pivot, row.line, HORIZONTAL_ALIGNMENT_LEFT, -1, row.size, fill)
	owner_node.draw_set_transform(Vector2.ZERO)

func _draw() -> void :
	if _mask == null:
		draw_fill(get_canvas_item(), color)
