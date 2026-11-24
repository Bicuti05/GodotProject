@tool
class_name CurveLabel
extends Label





@export var curve: Curve:
	set(v):
		if curve != null and curve.changed.is_connected(queue_redraw):
			curve.changed.disconnect(queue_redraw)
		curve = v
		if curve == null:
			curve = _make_default_curve()
		if not curve.changed.is_connected(queue_redraw):
			curve.changed.connect(queue_redraw)
		queue_redraw()


@export var amplitude: float = 80.0:
	set(v):
		amplitude = v
		queue_redraw()


@export var align_to_tangent: bool = false:
	set(v):
		align_to_tangent = v
		queue_redraw()



@export var minimum_word_gap: float = 0.0:
	set(v):
		minimum_word_gap = maxf(0.0, v)
		queue_redraw()



@export var digit_color: Color = Color(0, 0, 0, 0):
	set(v):
		digit_color = v
		queue_redraw()





@export var digit_outline_size: int = 0:
	set(v):
		digit_outline_size = maxi(0, v)
		queue_redraw()







@export var outline_stamp_radius: float = 0.0:
	set(v):
		outline_stamp_radius = maxf(0.0, v)
		queue_redraw()


func _enter_tree() -> void :


	visible_characters = 0


func _ready() -> void :
	if curve == null:
		curve = _make_default_curve()


func _draw() -> void :


	if visible_characters != 0:
		visible_characters = 0
	var display_text: String = atr(text)
	if display_text.is_empty() or curve == null:
		return

	var font: Font = _resolve_font()
	if font == null:
		return
	var font_size: int = _resolve_font_size()

	var ts: TextServer = TextServerManager.get_primary_interface()



	if autowrap_mode != TextServer.AUTOWRAP_OFF and size.x > 0.0:
		_draw_curved_multiline(display_text, font, font_size, ts)
		return
	if minimum_word_gap > 0.0 and size.x > 0.0:
		var layout: Dictionary = _fit_spaced_line(display_text, font, font_size, ts)
		for item: Dictionary in layout.get("items", []):
			draw_set_transform(item.origin, item.angle, Vector2.ONE * layout.scale * item.glyph_scale)
			_draw_glyph(item.glyph, item.position / item.glyph_scale, layout.raster_font_size, ts, 
				_glyph_color_override(display_text, item.glyph))
		draw_set_transform(Vector2.ZERO)
		return

	var line: = TextLine.new()
	line.add_string(display_text, font, font_size)
	var glyphs: Array = ts.shaped_text_get_glyphs(line.get_rid())

	var total_advance: = 0.0
	for g in glyphs:
		total_advance += g["advance"]
	if total_advance <= 0.0:
		return


	var effective_font_size: = font_size
	if size.x > 0.0 and total_advance > size.x:
		effective_font_size = maxi(1, int(float(font_size) * size.x / total_advance))
		line = TextLine.new()
		line.add_string(display_text, font, effective_font_size)
		glyphs = ts.shaped_text_get_glyphs(line.get_rid())
		total_advance = 0.0
		for g in glyphs:
			total_advance += g["advance"]
		if total_advance <= 0.0:
			return



	var x_scale: float = size.x if size.x > 0.0 else total_advance



	var fill_scale: = 1.0
	var offset_x: = 0.0
	if effective_font_size < font_size and size.x > 0.0 and total_advance > 0.0:
		fill_scale = size.x / total_advance
	else:
		match horizontal_alignment:
			HORIZONTAL_ALIGNMENT_CENTER:
				offset_x = (size.x - total_advance) * 0.5
			HORIZONTAL_ALIGNMENT_RIGHT:
				offset_x = size.x - total_advance

	var cumulative: = 0.0
	for g in glyphs:
		var adv: float = g["advance"]
		var glyph_w: float = adv * fill_scale
		var x: = offset_x + cumulative * fill_scale
		var t: = clampf((x + glyph_w * 0.5) / x_scale, 0.0, 1.0)
		var y: = size.y * 0.5 - (curve.sample(t) - 0.5) * amplitude * 2.0
		var glyph_offset: Vector2 = g["offset"]
		var col_override: = _glyph_color_override(display_text, g)
		if align_to_tangent:

			var pivot: = Vector2(x + glyph_w * 0.5, y) + glyph_offset
			draw_set_transform(pivot, _tangent_angle(t, x_scale))
			_draw_glyph(g, Vector2( - glyph_w * 0.5, 0.0), effective_font_size, ts, col_override)
		else:
			var pos: = Vector2(x, y) + glyph_offset
			_draw_glyph(g, pos, effective_font_size, ts, col_override)
		cumulative += adv

	if align_to_tangent:

		draw_set_transform(Vector2.ZERO)




func _fit_spaced_line(src: String, font: Font, font_size: int, ts: TextServer) -> Dictionary:
	var full_size: Dictionary = _layout_spaced_line(src, font, font_size, ts)
	if not full_size.is_empty():
		return full_size
	var low: int = 1
	var high: int = font_size - 1
	var best: Dictionary = {}
	while low <= high:
		var candidate_size: int = (low + high) / 2
		var candidate: Dictionary = _layout_spaced_line(src, font, font_size, ts, float(candidate_size) / font_size)
		if candidate.is_empty():
			high = candidate_size - 1
		else:
			best = candidate
			low = candidate_size + 1
	return best


func _layout_spaced_line(src: String, font: Font, font_size: int, ts: TextServer, text_scale: float = 1.0) -> Dictionary:
	var line: = TextLine.new()
	line.add_string(src, font, font_size, language if not language.is_empty() else TranslationServer.get_locale())
	var glyphs: Array = ts.shaped_text_get_glyphs(line.get_rid())
	var clusters: Array[Dictionary] = []
	var advance: float = 0.0
	var word: int = -1
	var after_space: bool = true
	var index: int = 0
	while index < glyphs.size():
		var first: Dictionary = glyphs[index]
		var count: int = maxi(1, int(first.count))
		var space: bool = src.substr(first.start, first.end - first.start).strip_edges().is_empty()
		if not space and after_space:
			word += 1
		after_space = space
		var parts: Array[Dictionary] = []
		var cluster_advance: float = 0.0
		for j: int in range(index, mini(index + count, glyphs.size())):
			var g: Dictionary = glyphs[j]
			var ink: Rect2 = _glyph_ink_bounds(g, font_size, ts)
			for repeat: int in int(g.repeat):
				var offset: Vector2 = g.offset + Vector2(cluster_advance, 0.0)
				var glyph_scale: float = 1.0
				var part_ink: Rect2 = ink


				if int(g.count) == 0 and is_zero_approx(float(g.advance))\
				and cluster_advance > 0.0 and offset.x + ink.position.x >= cluster_advance:
					offset.x -= cluster_advance
					if not parts.is_empty():

						glyph_scale = 0.55
						part_ink = Rect2(ink.position * glyph_scale, ink.size * glyph_scale)
						var base_ink: Rect2 = parts[0].ink
						base_ink.position += parts[0].position
						offset.x = base_ink.get_center().x - part_ink.get_center().x
						offset.y = base_ink.position.y - 4.0 - part_ink.end.y
				if ink.has_area() and not space:
					parts.append({"glyph": g, "position": offset, "ink": part_ink, "glyph_scale": glyph_scale})
				cluster_advance += float(g.advance)
		clusters.append({"x": advance, "advance": cluster_advance, "parts": parts, "word": word})
		advance += cluster_advance
		index += count
	if word < 0 or advance <= 0.0:
		return {}
	var gaps: Array[float] = []
	gaps.resize(word + 1)
	gaps.fill(0.0)
	var offset_x: float = (size.x - advance * text_scale) * 0.5

	for iteration: int in 12:
		var items: Array[Dictionary] = []
		var words: Array[Rect2] = []
		words.resize(word + 1)
		var bounds: = Rect2()
		for cluster: Dictionary in clusters:
			if cluster.parts.is_empty():
				continue
			var extra: float = 0.0
			for w: int in range(cluster.word + 1):
				extra += gaps[w]
			var center_x: float = offset_x + (cluster.x + cluster.advance * 0.5) * text_scale + extra
			var t: float = clampf(center_x / size.x, 0.0, 1.0)
			var origin: = Vector2(center_x, size.y * 0.5 - (curve.sample(t) - 0.5) * amplitude * 2.0)
			var angle: float = _tangent_angle(t, size.x) if align_to_tangent else 0.0
			for part: Dictionary in cluster.parts:
				var position: Vector2 = part.position - Vector2(cluster.advance * 0.5, 0.0)
				var local_rect: Rect2 = part.ink
				local_rect.position += position
				var rect: Rect2 = Transform2D(angle, Vector2.ONE * text_scale, 0.0, origin) * local_rect
				words[cluster.word] = words[cluster.word].merge(rect) if words[cluster.word].has_area() else rect
				bounds = bounds.merge(rect) if bounds.has_area() else rect
				items.append({"glyph": part.glyph, "position": position, "origin": origin, "angle": angle, 
					"bounds": rect, "glyph_scale": part.glyph_scale})
		var added: float = 0.0
		for w: int in range(1, words.size()):
			var deficit: float = minimum_word_gap - (words[w].position.x - words[w - 1].end.x)
			if deficit > 0.0:
				gaps[w] += deficit + 0.25
				added += deficit + 0.25
		var center_delta: float = size.x * 0.5 - bounds.get_center().x
		if added <= 0.0 and absf(center_delta) < 0.25:
			if bounds.position.x < 0.0 or bounds.end.x > size.x:
				return {}
			return {"font_size": roundi(font_size * text_scale), "raster_font_size": font_size, "scale": text_scale, 
				"items": items, "words": words, "bounds": bounds}
		offset_x += center_delta - added * 0.5
	return {}



func _glyph_ink_bounds(g: Dictionary, font_size: int, ts: TextServer) -> Rect2:
	var font_rid: RID = g.font_rid
	var glyph: int = g.index
	var key: = Vector2i(font_size, 0)
	ts.font_render_glyph(font_rid, key, glyph)
	var ink: = Rect2(ts.font_get_glyph_offset(font_rid, key, glyph), ts.font_get_glyph_size(font_rid, key, glyph))
	if not ink.has_area():
		return ink
	var outline: int = label_settings.outline_size if label_settings != null else get_theme_constant(&"outline_size")
	if _glyph_color_override(atr(text), g).a > 0.0 and digit_outline_size > 0:
		outline = digit_outline_size
	if outline_stamp_radius > 0.0:
		ink = ink.grow(outline_stamp_radius)
	elif outline > 0:
		key.y = outline
		ts.font_render_glyph(font_rid, key, glyph)
		ink = ink.merge(Rect2(ts.font_get_glyph_offset(font_rid, key, glyph), ts.font_get_glyph_size(font_rid, key, glyph)))
	var shadow_color: Color = label_settings.shadow_color if label_settings != null else get_theme_color(&"font_shadow_color")
	if shadow_color.a > 0.0:
		key.y = label_settings.shadow_size if label_settings != null else get_theme_constant(&"shadow_outline_size")
		ts.font_render_glyph(font_rid, key, glyph)
		var shadow_offset: = Vector2(label_settings.shadow_offset_x, label_settings.shadow_offset_y) if label_settings != null\
		else Vector2(get_theme_constant(&"shadow_offset_x"), get_theme_constant(&"shadow_offset_y"))
		ink = ink.merge(Rect2(ts.font_get_glyph_offset(font_rid, key, glyph) + shadow_offset, 
			ts.font_get_glyph_size(font_rid, key, glyph)))
	return ink




func _draw_curved_multiline(display_text: String, font: Font, font_size: int, ts: TextServer) -> void :
	var para: = TextParagraph.new()
	para.width = size.x
	para.break_flags = _autowrap_break_flags()
	para.add_string(display_text, font, font_size)
	var line_count: int = para.get_line_count()
	if line_count <= 0:
		return

	var line_h: float = font.get_height(font_size)
	var ascent: float = font.get_ascent(font_size)

	var block_top: float = size.y * 0.5 - line_h * float(line_count) * 0.5

	for i in line_count:
		var glyphs: Array = ts.shaped_text_get_glyphs(para.get_line_rid(i))
		var line_advance: = 0.0
		for g in glyphs:
			line_advance += g["advance"]

		var offset_x: = 0.0
		match horizontal_alignment:
			HORIZONTAL_ALIGNMENT_CENTER:
				offset_x = (size.x - line_advance) * 0.5
			HORIZONTAL_ALIGNMENT_RIGHT:
				offset_x = size.x - line_advance
		var line_baseline: float = block_top + float(i) * line_h + ascent
		var cumulative: = 0.0
		for g in glyphs:
			var adv: float = g["advance"]
			var x: = offset_x + cumulative
			var t: = clampf((x + adv * 0.5) / size.x, 0.0, 1.0)
			var y: = line_baseline - (curve.sample(t) - 0.5) * amplitude * 2.0
			var glyph_offset: Vector2 = g["offset"]
			_draw_glyph(g, Vector2(x, y) + glyph_offset, font_size, ts, 
				_glyph_color_override(display_text, g))
			cumulative += adv



func _autowrap_break_flags() -> int:
	var flags: = TextServer.BREAK_MANDATORY | TextServer.BREAK_TRIM_EDGE_SPACES
	match autowrap_mode:
		TextServer.AUTOWRAP_WORD:
			flags |= TextServer.BREAK_WORD_BOUND
		TextServer.AUTOWRAP_ARBITRARY:
			flags |= TextServer.BREAK_GRAPHEME_BOUND
		_:
			flags |= TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	return flags



func _glyph_color_override(src: String, g: Dictionary) -> Color:
	if digit_color.a <= 0.0:
		return Color(0, 0, 0, 0)
	var i: int = g.get("start", -1)
	if i < 0 or i >= src.length():
		return Color(0, 0, 0, 0)
	var ch: String = src[i]
	if _is_digit(ch):
		return digit_color


	if ch == "%" and ((i > 0 and _is_digit(src[i - 1]))\
	or (i + 1 < src.length() and _is_digit(src[i + 1]))):
		return digit_color
	return Color(0, 0, 0, 0)


static func _is_digit(ch: String) -> bool:
	return ch >= "0" and ch <= "9"




func _draw_glyph(g: Dictionary, pos: Vector2, font_size: int, ts: TextServer, 
		color_override: Color = Color(0, 0, 0, 0)) -> void :
	var font_color: Color
	var outline_size: int
	var outline_color: Color
	var shadow_color: Color
	var shadow_size: int
	var shadow_offset: Vector2
	if label_settings != null:
		font_color = label_settings.font_color
		outline_size = label_settings.outline_size
		outline_color = label_settings.outline_color
		shadow_color = label_settings.shadow_color
		shadow_size = label_settings.shadow_size
		shadow_offset = label_settings.shadow_offset
	else:
		font_color = get_theme_color(&"font_color")
		outline_size = get_theme_constant(&"outline_size")
		outline_color = get_theme_color(&"font_outline_color")
		shadow_color = get_theme_color(&"font_shadow_color")
		shadow_size = get_theme_constant(&"shadow_outline_size")
		shadow_offset = Vector2(
			get_theme_constant(&"shadow_offset_x"), 
			get_theme_constant(&"shadow_offset_y")
		)

	if color_override.a > 0.0:
		font_color = color_override
		if digit_outline_size > 0:
			outline_size = digit_outline_size

	var canvas: = get_canvas_item()
	var font_rid: RID = g["font_rid"]
	var index: int = g["index"]

	if shadow_color.a > 0.0:
		var shadow_pos: = pos + shadow_offset
		if shadow_size > 0:
			ts.font_draw_glyph_outline(font_rid, canvas, font_size, shadow_size, shadow_pos, index, shadow_color)
		ts.font_draw_glyph(font_rid, canvas, font_size, shadow_pos, index, shadow_color)

	if outline_stamp_radius > 0.0 and outline_color.a > 0.0:

		var steps: int = clampi(int(ceil(TAU * outline_stamp_radius / 2.0)), 12, 128)
		for i in steps:
			var ang: float = TAU * float(i) / float(steps)
			var off: = Vector2(cos(ang), sin(ang)) * outline_stamp_radius
			ts.font_draw_glyph(font_rid, canvas, font_size, pos + off, index, outline_color)
	elif outline_size > 0 and outline_color.a > 0.0:
		ts.font_draw_glyph_outline(font_rid, canvas, font_size, outline_size, pos, index, outline_color)

	ts.font_draw_glyph(font_rid, canvas, font_size, pos, index, font_color)




func _tangent_angle(t: float, x_scale: float) -> float:
	const DT: = 0.01
	var t0: = clampf(t - DT, 0.0, 1.0)
	var t1: = clampf(t + DT, 0.0, 1.0)
	var dy: = curve.sample(t1) - curve.sample(t0)

	var tangent: = Vector2(x_scale * (t1 - t0), - dy * amplitude * 2.0)
	return tangent.angle()


func _resolve_font() -> Font:
	if label_settings != null and label_settings.font != null:
		return label_settings.font
	return get_theme_font(&"font")


func _resolve_font_size() -> int:
	if label_settings != null and label_settings.font_size > 0:
		return label_settings.font_size
	return get_theme_font_size(&"font_size")


func _make_default_curve() -> Curve:
	var c: = Curve.new()
	c.add_point(Vector2(0.0, 0.5), 0.0, 2.0)
	c.add_point(Vector2(0.5, 1.0), 0.0, 0.0)
	c.add_point(Vector2(1.0, 0.5), -2.0, 0.0)
	return c
