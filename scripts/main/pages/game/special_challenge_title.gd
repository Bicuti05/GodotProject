@tool
extends CurveLabel



func _draw() -> void :
	if visible_characters != 0:
		visible_characters = 0
	var display_text: String = atr(text)
	if display_text.is_empty() or curve == null:
		return
	var font: Font = _resolve_font()
	var text_server: TextServer = TextServerManager.get_primary_interface()
	var layout: Dictionary = _fit_spaced_line(display_text, font, _resolve_font_size(), text_server)
	if layout.is_empty():
		return
	var font_size: int = layout.raster_font_size
	var outline_color: Color = get_theme_color(&"font_outline_color")
	var steps: int = clampi(int(ceil(TAU * outline_stamp_radius / 2.0)), 12, 128)
	for item: Dictionary in layout.items:
		draw_set_transform(item.origin, item.angle, Vector2.ONE * layout.scale)
		var glyph: Dictionary = item.glyph
		for step: int in steps:
			var angle: float = TAU * float(step) / float(steps)
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * outline_stamp_radius
			text_server.font_draw_glyph(glyph.font_rid, get_canvas_item(), font_size, 
				item.position + offset, glyph.index, outline_color)
		text_server.font_draw_glyph(glyph.font_rid, get_canvas_item(), font_size, 
			item.position, glyph.index, outline_color)
	for item: Dictionary in layout.items:
		draw_set_transform(item.origin, item.angle, Vector2.ONE * layout.scale)
		var glyph: Dictionary = item.glyph
		text_server.font_draw_glyph(glyph.font_rid, get_canvas_item(), font_size, 
			item.position, glyph.index, get_theme_color(&"font_color"))
	draw_set_transform(Vector2.ZERO)
