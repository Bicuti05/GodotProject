extends Control



@export var font: Font
const FONT_SIZE: int = 140
const PATH_WIDTH: float = 685.0
const PATH_RISE: float = 44.0
const OUTLINE_RADIUS: float = 8.4
const BASELINE: Vector2 = Vector2(15.0, 140.0)
const SAMPLE_COUNT: int = 128

var _items: Array[Dictionary] = []
var _arc_lengths: PackedFloat32Array = PackedFloat32Array()
var _fit_scale: float = 1.0
var _display_text: String = ""


func set_title(value: String) -> void :
	if value == _display_text and not _items.is_empty():
		return
	_display_text = value
	_build_layout()
	queue_redraw()


func _point(t: float) -> Vector2:

	return Vector2(PATH_WIDTH * t, 4.0 * PATH_RISE * t * (1.0 - t))


func _parameter(distance: float) -> float:
	for i: int in range(1, _arc_lengths.size()):
		if distance <= _arc_lengths[i]:
			var fraction: float = inverse_lerp(_arc_lengths[i - 1], _arc_lengths[i], distance)
			return (float(i - 1) + fraction) / SAMPLE_COUNT
	return 1.0


func _build_layout() -> void :
	_items.clear()
	if font == null or _display_text.is_empty():
		return
	if _arc_lengths.is_empty():
		_arc_lengths.append(0.0)
		var previous: Vector2 = _point(0.0)
		for i: int in range(1, SAMPLE_COUNT + 1):
			var point: Vector2 = _point(float(i) / SAMPLE_COUNT)
			_arc_lengths.append(_arc_lengths[-1] + point.distance_to(previous))
			previous = point
	var line: TextLine = TextLine.new()
	line.add_string(_display_text, font, FONT_SIZE, TranslationServer.get_locale())
	var ts: TextServer = TextServerManager.get_primary_interface()
	var glyphs: Array = ts.shaped_text_get_glyphs(line.get_rid())
	var advance: float = line.get_line_width()
	var path_length: float = _arc_lengths[-1]
	_fit_scale = minf(1.0, (path_length - OUTLINE_RADIUS * 2.0) / maxf(1.0, advance))
	var cursor: float = (path_length - advance * _fit_scale) * 0.5
	var index: int = 0

	while index < glyphs.size():
		var count: int = maxi(1, int(glyphs[index].count))
		var width: float = 0.0
		for j: int in range(index, mini(index + count, glyphs.size())):
			width += float(glyphs[j].advance) * int(glyphs[j].repeat)
		var start_t: float = _parameter(cursor)
		var end_t: float = _parameter(cursor + width * _fit_scale)
		var midpoint: Vector2 = (_point(start_t) + _point(end_t)) * 0.5 + BASELINE
		var direction: Vector2 = _point(end_t) - _point(start_t)
		var angle: float = direction.angle() if direction.length_squared() > 0.0 else 0.0
		var offset: float = - width * 0.5
		for j: int in range(index, mini(index + count, glyphs.size())):
			var glyph: Dictionary = glyphs[j]
			for repeat: int in int(glyph.repeat):
				_items.append({"glyph": glyph, "origin": midpoint, "angle": angle, 
					"position": Vector2(offset, 0.0) + glyph.offset})
				offset += float(glyph.advance)
		cursor += width * _fit_scale
		index += count


func _draw() -> void :
	var ts: TextServer = TextServerManager.get_primary_interface()

	for item: Dictionary in _items:
		draw_set_transform(item.origin, item.angle, Vector2.ONE * _fit_scale)
		for stamp: int in 32:
			var angle: float = TAU * float(stamp) / 32.0
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * OUTLINE_RADIUS
			ts.font_draw_glyph(item.glyph.font_rid, get_canvas_item(), FONT_SIZE, 
				item.position + offset, item.glyph.index, Color(1, 0, 0, 1))
		ts.font_draw_glyph(item.glyph.font_rid, get_canvas_item(), FONT_SIZE, 
			item.position, item.glyph.index, Color(1, 0, 0, 1))
	for item: Dictionary in _items:
		draw_set_transform(item.origin, item.angle, Vector2.ONE * _fit_scale)
		ts.font_draw_glyph(item.glyph.font_rid, get_canvas_item(), FONT_SIZE, 
			item.position, item.glyph.index, Color(1, 1, 0, 1))
	draw_set_transform(Vector2.ZERO)
