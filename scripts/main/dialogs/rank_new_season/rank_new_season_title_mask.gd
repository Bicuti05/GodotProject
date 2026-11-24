class_name RankNewSeasonTitleMask
extends Node2D

const FONT_SIZE: int = 104
const OUTLINE_RADIUS: float = 6.0
const OUTLINE_SAMPLES: int = 24
const PATH_ORIGIN: Vector2 = Vector2(30.082275, 70.000946)

@export var font: Font
@export var arc_points: PackedVector2Array
@export var arc_distances: PackedFloat32Array
@export var anchor_distance: float
@export var outlined: bool = false

var layout: Array[Dictionary] = []
var fit: float = 1.0
var ink_bounds: Rect2

func prepare(text: String, fit_limit: float = 1.0) -> void :
	layout.clear()
	var ts: TextServer = TextServerManager.get_primary_interface()
	var line: = TextLine.new()
	line.add_string(text, font, FONT_SIZE, TranslationServer.get_locale())
	var glyphs: Array = ts.shaped_text_get_glyphs(line.get_rid())


	var clusters: Array[Dictionary] = []
	var total: float = 0.0
	for glyph: Dictionary in glyphs:
		if clusters.is_empty() or clusters[-1].start != glyph.start or clusters[-1].end != glyph.end:
			clusters.append({"start": glyph.start, "end": glyph.end, "advance": 0.0, "parts": []})
		var cluster: Dictionary = clusters[-1]
		for repeat: int in int(glyph.repeat):
			cluster.parts.append({"glyph": glyph, "x": cluster.advance})
			cluster.advance += float(glyph.advance)
			total += float(glyph.advance)
	var available: float = 2.0 * minf(anchor_distance, arc_distances[-1] - anchor_distance)
	fit = minf(fit_limit, available / maxf(total, 0.001))
	var cursor: float = anchor_distance - total * fit * 0.5
	for cluster: Dictionary in clusters:
		var advance: float = cluster.advance * fit
		var start: Vector2 = _at_distance(cursor)
		var end: Vector2 = _at_distance(cursor + advance)
		var angle: float = (end - start).angle()
		var origin: Vector2 = PATH_ORIGIN + (start + end) * 0.5 - Vector2(advance * 0.5, 0.0).rotated(angle)
		var transform: = Transform2D(angle, Vector2.ONE * fit, 0.0, origin)
		for part: Dictionary in cluster.parts:
			layout.append({"glyph": part.glyph, "x": part.x, "transform": transform})
		cursor += advance
	_measure_ink()
	queue_redraw()

func _at_distance(distance: float) -> Vector2:
	var low: int = 0
	var high: int = arc_distances.size() - 1
	while low < high:
		var middle: int = (low + high) / 2
		if arc_distances[middle] < distance:
			low = middle + 1
		else:
			high = middle
	if low == 0:
		return arc_points[0]
	var previous: int = low - 1
	var t: float = (distance - arc_distances[previous]) / maxf(arc_distances[low] - arc_distances[previous], 0.0001)
	return arc_points[previous].lerp(arc_points[low], clampf(t, 0.0, 1.0))

func _measure_ink() -> void :
	var ts: TextServer = TextServerManager.get_primary_interface()
	ink_bounds = Rect2(PATH_ORIGIN + _at_distance(anchor_distance), Vector2.ZERO)
	for item: Dictionary in layout:
		var glyph: Dictionary = item.glyph
		if not glyph.font_rid.is_valid() or glyph.index == 0:
			continue
		var glyph_size: = Vector2i(FONT_SIZE, 0)
		var offset: Vector2 = ts.font_get_glyph_offset(glyph.font_rid, glyph_size, glyph.index) + glyph.offset + Vector2(item.x, 0.0)
		var rect: = Rect2(offset, ts.font_get_glyph_size(glyph.font_rid, glyph_size, glyph.index))
		if outlined:
			rect = rect.grow(OUTLINE_RADIUS)
		ink_bounds = ink_bounds.merge((item.transform as Transform2D) * rect)

func _draw_glyph(item: Dictionary, offset: Vector2, color: Color) -> void :
	var glyph: Dictionary = item.glyph
	if not glyph.font_rid.is_valid() or glyph.index == 0:
		return
	draw_set_transform_matrix(item.transform)
	TextServerManager.get_primary_interface().font_draw_glyph(glyph.font_rid, 
		get_canvas_item(), FONT_SIZE, Vector2(glyph.offset) + Vector2(item.x, 0.0) + offset, glyph.index, color)

func _draw() -> void :
	if outlined:
		for item: Dictionary in layout:
			for step: int in OUTLINE_SAMPLES:
				_draw_glyph(item, Vector2.from_angle(TAU * step / OUTLINE_SAMPLES) * OUTLINE_RADIUS, Color.RED)
	for item: Dictionary in layout:
		_draw_glyph(item, Vector2.ZERO, Color.GREEN if outlined else Color.WHITE)
	draw_set_transform_matrix(Transform2D.IDENTITY)
