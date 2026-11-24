class_name HapticPreview
extends VBoxContainer


const COLORS: Array[Color] = [Color("73ddc4"), Color("8cb8f0"), Color("baa4e8"), Color("e7bf84")]
const PULSE: Color = Color("73ddc4")
const WAVE_COLORS: Array[Color] = [Color("8cb8f0"), Color("baa4e8"), Color("e7bf84"), Color("73ddc4"), Color("e8a4ce"), Color("b8d882")]
const PRIMITIVE_COLORS: Array[Color] = [Color("8cb8f0"), Color("e7bf84"), Color("73ddc4"), Color("baa4e8"), Color("e8a4ce"), Color("b8d882"), Color("83d4e0"), Color("b8c1cc")]
const PRIMITIVE_NAMES: Array[String] = ["Click", "Tick", "Spin", "Thud", "SlowRise", "QuickRise", "QuickFall", "LowTick"]
const GRID: Color = Color(0.27, 0.31, 0.38, 0.45)
const MUTED: Color = Color("81909c")
const TEXT: Color = Color("dce5ea")
const PLAYHEAD: Color = Color("f2faf7")
@export var plot_font: Font
@onready var _plot: Control = $PlotScroll / Plot
@onready var _caption: Label = $Header / Headings / Caption
@onready var _total: Label = $Header / Summary / Total
@onready var _detail: Label = $Header / Summary / Detail
@onready var _subtitle: Label = $Header / Headings / Subtitle
var _display_max: float = 255.0
var _chart_style: StyleBoxFlat = StyleBoxFlat.new()


var _data: Dictionary = {}
var _generation: int = 0
var _task_generation: int = 0
var _task: int = -1
var _job: Dictionary = {}
var _pending: Dictionary = {}
var _started_usec: int = 0
var _progress: float = -1.0
var _geometry: Dictionary = {}
var _geometry_size: Vector2 = Vector2.ZERO
var _last_cfg: Dictionary = {}
var _last_platform: String = "android"


func _ready() -> void :
	_chart_style.bg_color = Color(0.045, 0.06, 0.075, 1)
	_chart_style.border_color = Color(0.25, 0.29, 0.34, 1)
	_chart_style.set_border_width_all(1)
	_plot.draw.connect(_draw_plot)
	_plot.resized.connect(_on_plot_resized)
	visibility_changed.connect(_on_visibility_changed)
	set_process(false)


func set_effect(cfg: Dictionary, platform: String) -> void :
	stop_playhead()
	_display_max = 255.0 if platform == "android" else 1.0
	_generation += 1
	_last_cfg = cfg.duplicate(true)
	_last_platform = platform
	_pending = {"cfg": _last_cfg.duplicate(true), "platform": platform}
	_geometry = {}
	_data = {}
	_caption.text = "震动轨道"
	_plot.queue_redraw()
	_start_pending()


func _start_pending() -> void :
	if _task >= 0 or _pending.is_empty():
		return
	_task_generation = _generation
	_job = {}
	_task = WorkerThreadPool.add_task(_build_job.bind(_pending.cfg, _pending.platform, _plot.size, _job))
	_pending = {}
	set_process(true)


static func _build_job(cfg: Dictionary, platform: String, plot_size: Vector2, result: Dictionary) -> void :
	result.data = read_preview_data(cfg, platform)
	result.geometry = _build_geometry(result.data, plot_size)
	result.size = plot_size



static func read_preview_data(cfg: Dictionary, platform: String) -> Dictionary:
	if cfg.get("type") == "ahap":
		var file: FileAccess = FileAccess.open(String(cfg.get("file", "")), FileAccess.READ)
		if file != null and file.get_length() <= HapticTuneConfig.MAX_BYTES:
			cfg["json"] = file.get_as_text()
	return build_preview_data(cfg, platform)


func _process(_delta: float) -> void :
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		if _task_generation == _generation:
			_data = _job.data
			_geometry = _job.geometry
			_geometry_size = _job.size
			_update_summary()
			var primitive_count: int = _data.get("primitives", []).size()
			_plot.custom_minimum_size.x = primitive_count * 208 + 112 if primitive_count > 0 else 0
			_plot.custom_minimum_size.y = 380 if primitive_count > 0 else 320 + _geometry.tracks.size() * 150
			_plot.queue_redraw()
		_start_pending()
	if _started_usec > 0 and not _data.is_empty():
		if not is_visible_in_tree() or not _data.known_time or _data.duration_ms <= 0:
			stop_playhead()
		else:
			var elapsed: float = float(Time.get_ticks_usec() - _started_usec) / 1000.0
			_progress = clampf(elapsed / _data.duration_ms, 0, 1)
			_plot.queue_redraw()
			if elapsed >= _data.duration_ms:
				_started_usec = 0
	set_process(_task >= 0 or not _pending.is_empty() or _started_usec > 0)


func start_playhead(_mode: String = "演示") -> void :
	if not is_visible_in_tree():
		return
	_started_usec = Time.get_ticks_usec()
	_progress = 0
	set_process(true)


func stop_playhead() -> void :
	_started_usec = 0
	_progress = -1
	if is_node_ready():
		_plot.queue_redraw()
		set_process(_task >= 0 or not _pending.is_empty())


func _on_visibility_changed() -> void :
	if not is_visible_in_tree():
		stop_playhead()


func _on_plot_resized() -> void :
	if _last_cfg.is_empty():
		return
	_generation += 1
	_geometry = {}
	_pending = {"cfg": _last_cfg.duplicate(true), "platform": _last_platform}
	_start_pending()


func get_preview_data() -> Dictionary:
	return _data.duplicate(true)


func _update_summary() -> void :
	_caption.text = "震动轨道"
	_subtitle.text = "时间 / 振动强度" if _data.sequence.is_empty() else "类型 / 顺序 / 已知参数"
	_total.text = "%.0f ms" % _data.duration_ms if _data.known_time else "--"
	var count: int = 0
	var peak: float = 0
	for segment: Dictionary in _data.segments:
		if segment.strength > 0:
			count += 1
		peak = maxf(peak, segment.strength)
	if _data.known_strength and not _data.segments.is_empty():
		var peak_text: String = str(roundi(peak * _display_max)) if _display_max > 1 else "%.2f" % peak
		_detail.text = "%d 次振动 · 峰值%s" % [count, peak_text]
	else:
		_detail.text = "由系统决定"
	if not _data.get("primitives", []).is_empty():
		_subtitle.text = "原语顺序 / 力度系数"
		_detail.text = "%d 段原语 · 时长未知" % _data.primitives.size()
	if not _data.get("system", {}).is_empty():
		_subtitle.text = "系统预设 / 类型示意"


func _exit_tree() -> void :

	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)


static func _segment(data: Dictionary, start: float, end: float, strength: float, label: String, instant: bool = false) -> void :
	var color: Color = MUTED if strength <= 0 else WAVE_COLORS[data.segments.size() % WAVE_COLORS.size()]
	data.segments.append({"start_ms": start, "end_ms": end, "strength": clampf(strength, 0, 1), "label": label, "instant": instant, "color": color})
	data.duration_ms = maxf(data.duration_ms, end)



static func build_preview_data(cfg: Dictionary, platform: String) -> Dictionary:
	var data: Dictionary = {"title": "时间 / 强度", "duration_ms": 0.0, "known_time": true, 
		"known_strength": true, "segments": [], "curves": [], "sequence": [], "primitives": [], "system": {}}
	match String(cfg.get("type", "")):
		"oneshot":
			var amplitude: float = float(cfg.get("amplitude", -1))
			data.known_strength = amplitude >= 0
			_segment(data, 0, float(cfg.get("duration_msec", 0)), amplitude / 255.0 if amplitude >= 0 else 0.5, "单次")
		"waveform":
			var time: float = 0
			var timings: Array = cfg.get("timings_msec", [])
			var amplitudes: Array = cfg.get("amplitudes", [])
			for index: int in mini(64, mini(timings.size(), amplitudes.size())):
				var end: float = time + float(timings[index])
				_segment(data, time, end, float(amplitudes[index]) / 255.0, str(index + 1))
				time = end
			data.title = "分段波形 · %.0f ms" % time
		"continuous", "transient":
			var instant: bool = cfg.type == "transient"
			_segment(data, 0, 0 if instant else float(cfg.get("duration", 0)) * 1000.0, float(cfg.get("intensity", 0)), "瞬态" if instant else "持续", instant)
			data.known_time = not instant
			if instant:
				data.title = "瞬态 · 起点 / 强度"
		"ahap", "ahap_json":
			var document: Variant = JSON.parse_string(String(cfg.get("json", "")))
			if not document is Dictionary or not document.get("Pattern") is Array:
				data.known_time = false
				return data
			var latest_instant: float = -1
			for entry: Variant in document.Pattern.slice(0, 128):
				if not entry is Dictionary:
					continue
				if entry.get("Event") is Dictionary:
					var event: Dictionary = entry.Event
					if event.get("EventType") not in ["HapticContinuous", "HapticTransient"]:
						continue
					var instant: bool = event.EventType == "HapticTransient"
					var start: float = float(event.get("Time", 0)) * 1000.0
					var intensity: float = 1
					for parameter: Variant in event.get("EventParameters", []):
						if parameter is Dictionary and parameter.get("ParameterID") == "HapticIntensity":
							intensity = float(parameter.get("ParameterValue", 1))
					intensity *= float(cfg.get("intensity_scale", 1))
					var end: float = start + (0.0 if instant else float(event.get("EventDuration", 0)) * 1000.0)
					_segment(data, start, end, intensity, str(data.segments.size() + 1), instant)
					if instant:
						latest_instant = maxf(latest_instant, start)
				if entry.get("ParameterCurve") is Dictionary and data.curves.size() < 8:
					var curve: Dictionary = entry.ParameterCurve
					var points: Array = curve.get("ParameterCurveControlPoints", [])
					var sampled: Array[Vector2] = []
					for index: int in mini(32, points.size()):
						var source_index: int = index * (points.size() - 1) / maxi(1, mini(32, points.size()) - 1)
						var point: Variant = points[source_index]
						if point is Dictionary:
							var time: float = (float(curve.get("Time", 0)) + float(point.get("Time", 0))) * 1000.0
							sampled.append(Vector2(time, float(point.get("ParameterValue", 0))))
							data.duration_ms = maxf(data.duration_ms, time)
					data.curves.append({"name": String(curve.get("ParameterID", "")), "points": sampled})
			data.known_time = data.duration_ms > latest_instant and data.duration_ms > 0
			data.title = "AHAP 事件 · %.0f ms" % data.duration_ms if data.known_time else "AHAP · 事件起点 / 强度"
		"composition":
			data.title = "原语 · 顺序 / 力度 / 停顿"
			data.known_time = false
			var primitives: Array = cfg.get("primitives", [])
			var delays: Array = cfg.get("delays_msec", [])
			var scales: Array = cfg.get("scales_percent", [])
			for index: int in mini(64, mini(primitives.size(), mini(delays.size(), scales.size()))):
				data.sequence.append("原语%d · 力度%.2f · 停顿%dms" % [primitives[index], float(scales[index]) / 100.0, delays[index]])
				var id: int = int(primitives[index])
				var color_index: int = clampi(id - 1, 0, PRIMITIVE_COLORS.size() - 1)
				data.primitives.append({"id": id, "name": PRIMITIVE_NAMES[color_index], "scale": float(scales[index]) / 100.0, "delay_ms": int(delays[index]), "color": PRIMITIVE_COLORS[color_index]})
		_:
			data.title = "系统反馈 · 类型"
			data.known_time = false
			data.known_strength = false
			var label: String = String(cfg.get("type", "未知效果"))
			if cfg.has("style"):
				label += " · " + str(cfg.style)
			if cfg.has("kind"):
				label += " · " + str(cfg.kind)
			var color: Color = COLORS[0]
			match String(cfg.get("type", "")):
				"impact":
					var index: int = clampi(int(cfg.get("style", 1)), 0, 4)
					label = "Impact · " + ["Light", "Medium", "Heavy", "Soft", "Rigid"][index]
					color = [WAVE_COLORS[3], WAVE_COLORS[0], WAVE_COLORS[2], WAVE_COLORS[1], WAVE_COLORS[4]][index]
				"notification":
					var index: int = clampi(int(cfg.get("kind", 0)), 0, 2)
					label = "Notification · " + ["Success", "Warning", "Error"][index]
					color = [WAVE_COLORS[3], WAVE_COLORS[5], WAVE_COLORS[2]][index]
				"selection":
					label = "Selection"
					color = WAVE_COLORS[3]
			data.system = {"label": label, "color": color}
			data.sequence.append(label)
	if platform == "android" and not data.segments.is_empty():
		data.title += " · 振幅0~255"
	return data



func get_plot_geometry() -> Dictionary:
	return _geometry if _geometry_size == _plot.size else {}



static func _curve_tracks(data: Dictionary) -> Array[Dictionary]:
	var names: Dictionary = {"HapticIntensityControl": "强度控制", "HapticSharpnessControl": "锐度控制", "HapticAttackTimeControl": "起音控制", "HapticDecayTimeControl": "衰减控制", "HapticReleaseTimeControl": "释放控制", "Envelope": "包络 / 其他控制"}
	var tracks: Array[Dictionary] = []
	for curve: Dictionary in data.get("curves", []):
		var group: String = curve.name if curve.name in ["HapticIntensityControl", "HapticSharpnessControl"] else "Envelope"
		var existing: int = -1
		for index: int in tracks.size():
			if tracks[index].name == group:
				existing = index
				break
		var minimum: float = 0.0 if curve.name == "HapticIntensityControl" else -1.0

		for point: Vector2 in curve.points:
			if point.y < 0:
				minimum = -1.0
		if existing >= 0:
			tracks[existing].minimum = minf(tracks[existing].minimum, minimum)
			if not curve.name in tracks[existing].members:
				tracks[existing].members.append(curve.name)
		else:
			tracks.append({"name": group, "members": [curve.name], "title": String(names.get(group, group)), "minimum": minimum, "maximum": 1.0})
	return tracks


static func _curve_fill(points: PackedVector2Array, baseline: float) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	if points.is_empty():
		return polygon
	polygon.append(Vector2(points[0].x, baseline))
	for point: Vector2 in points:
		if point != polygon[polygon.size() - 1]:
			polygon.append(point)
	var end: Vector2 = Vector2(points[points.size() - 1].x, baseline)
	if end != polygon[polygon.size() - 1]:
		polygon.append(end)
	if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty():
		return PackedVector2Array()
	return polygon


static func _build_geometry(data: Dictionary, plot_size: Vector2) -> Dictionary:
	var tracks: Array[Dictionary] = _curve_tracks(data)
	var area: Rect2 = Rect2(84, 44, maxf(plot_size.x - 112, 1), maxf(plot_size.y - 140, 1))
	var main_height: float = maxf((area.size.y - tracks.size() * 52.0) / (1.0 + tracks.size() * 0.65), 1)
	var main: Rect2 = Rect2(area.position, Vector2(area.size.x, main_height))
	if not data.get("primitives", []).is_empty():

		main.position.y += 48
		main.size.y = maxf(main.size.y - 48, 1)
	var cursor: float = main.end.y
	for index: int in tracks.size():
		var rect: Rect2 = Rect2(area.position.x, cursor + 52, area.size.x, maxf(main_height * 0.65, 1))
		tracks[index].rect = rect
		cursor = rect.end.y
	var extent: float = maxf(float(data.get("duration_ms", 0)), 1)
	var segments: Array[Rect2] = []
	for segment: Dictionary in data.get("segments", []):
		var start: float = main.position.x + main.size.x * segment.start_ms / extent
		var end: float = main.position.x + main.size.x * segment.end_ms / extent
		segments.append(Rect2(start, main.end.y - main.size.y * segment.strength, maxf(0, end - start), main.size.y * segment.strength))
	var curves: Array[PackedVector2Array] = []
	var curve_fills: Array[PackedVector2Array] = []
	for source: Dictionary in data.get("curves", []):
		var track: Dictionary = {}
		for candidate: Dictionary in tracks:
			if source.name in candidate.members:
				track = candidate
				break
		var points: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in source.points:
			var value: float = (clampf(point.y, track.minimum, track.maximum) - track.minimum) / (track.maximum - track.minimum)
			points.append(Vector2(track.rect.position.x + track.rect.size.x * point.x / extent, track.rect.end.y - value * track.rect.size.y))
		curves.append(points)
		var baseline: float = track.rect.end.y - (0.0 - track.minimum) / (track.maximum - track.minimum) * track.rect.size.y
		curve_fills.append(_curve_fill(points, baseline) if source.name == "HapticIntensityControl" else PackedVector2Array())
	var primitive_blocks: Array[Rect2] = []
	var primitive_list: Array = data.get("primitives", [])
	var slot_width: float = main.size.x / maxi(primitive_list.size(), 1)
	for index: int in primitive_list.size():
		var primitive: Dictionary = primitive_list[index]
		var strength: float = clampf(primitive.scale, 0, 1)
		primitive_blocks.append(Rect2(main.position.x + index * slot_width + 6, main.end.y - main.size.y * strength, maxf(slot_width - 12, 1), main.size.y * strength))
	var marker_width: float = minf(480, maxf(1, main.size.x - 32))
	var marker_height: float = minf(104, main.size.y)
	var system_block: Rect2 = Rect2(main.get_center() - Vector2(marker_width, marker_height) / 2, Vector2(marker_width, marker_height))
	return {"area": area, "main": main, "extent": extent, "segments": segments, "curves": curves, "curve_fills": curve_fills, "tracks": tracks, "bottom": cursor, "primitive_blocks": primitive_blocks, "system_block": system_block}


func _draw_axes(rect: Rect2, title: String, minimum: float, maximum: float, values_known: bool = true) -> void :
	_plot.draw_style_box(_chart_style, rect)
	_plot.draw_string(plot_font, Vector2(rect.position.x, rect.position.y - 16), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 30, TEXT)
	for index: int in 3:
		var fraction: float = index / 2.0
		var y: float = rect.end.y - rect.size.y * fraction
		_plot.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), GRID, 1)
		if values_known:
			var value: float = minimum + fraction * (maximum - minimum)
			var text: String = str(roundi(value)) if maximum > 1 or is_equal_approx(value, roundf(value)) else "%.1f" % value
			_plot.draw_string(plot_font, Vector2(8, y + 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, MUTED)
	_plot.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), MUTED, 1.5)
	_plot.draw_line(Vector2(rect.position.x, rect.end.y), rect.end, MUTED, 1.5)


func _draw_primitive_blocks(geometry: Dictionary) -> void :
	var main: Rect2 = geometry.main
	_draw_axes(main, "力度系数 (Scale)", 0, 1)
	for index: int in _data.primitives.size():
		var primitive: Dictionary = _data.primitives[index]
		var rect: Rect2 = geometry.primitive_blocks[index]
		var color: Color = primitive.color
		if rect.size.y > 0:
			_plot.draw_rect(rect, Color(color, 0.62))
			_plot.draw_rect(rect, color, false, 2)
		else:
			_plot.draw_line(Vector2(rect.position.x, main.end.y), rect.end, color, 3)
		var label: String = "%02d %s" % [index + 1, primitive.name]
		_plot.draw_string(plot_font, Vector2(rect.position.x, main.position.y - 52), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 28, color)
		_plot.draw_string(plot_font, Vector2(rect.position.x, main.end.y + 34), "Scale %.2f" % primitive.scale, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26, TEXT)
		_plot.draw_string(plot_font, Vector2(rect.position.x, main.end.y + 70), "停顿 %d ms" % primitive.delay_ms, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 25, MUTED)


func _draw_plot() -> void :
	if _data.is_empty() or plot_font == null or _plot.size.x < 160 or _plot.size.y < 100:
		return
	var geometry: Dictionary = get_plot_geometry()
	if geometry.is_empty():
		return
	var main: Rect2 = geometry.main
	var extent: float = geometry.extent
	if not _data.get("primitives", []).is_empty():
		_draw_primitive_blocks(geometry)
		return
	if not _data.get("system", {}).is_empty():
		_plot.draw_style_box(_chart_style, main)
		var marker: Rect2 = geometry.system_block
		var color: Color = _data.system.color
		_plot.draw_rect(marker, Color(color, 0.15))
		_plot.draw_rect(marker, color, false, 2)
		_plot.draw_rect(Rect2(marker.position, Vector2(marker.size.x, 5)), color)
		_plot.draw_string(plot_font, Vector2(marker.position.x + 16, marker.get_center().y + 12), _data.system.label, HORIZONTAL_ALIGNMENT_CENTER, marker.size.x - 32, 32, TEXT)
		return
	if _data.segments.is_empty() and _data.curves.is_empty():
		_plot.draw_style_box(_chart_style, main)
		for index: int in mini(3, _data.sequence.size()):
			_plot.draw_string(plot_font, Vector2(main.position.x + 12, main.position.y + 28 + index * 40), _data.sequence[index], HORIZONTAL_ALIGNMENT_LEFT, main.size.x - 24, 30, TEXT)
		if _data.sequence.size() > 3:
			_plot.draw_string(plot_font, Vector2(main.position.x + 12, main.position.y + 148), "另有%d段" % (_data.sequence.size() - 3), HORIZONTAL_ALIGNMENT_LEFT, main.size.x - 24, 26, MUTED)
		_plot.draw_string(plot_font, Vector2(main.position.x, _plot.size.y - 18), "时间 (ms) · 由系统决定", HORIZONTAL_ALIGNMENT_LEFT, main.size.x, 28, MUTED)
		return
	var title: String = "振幅 (0~255)" if _display_max > 1 else "强度 (0~1)"
	if not _data.known_strength:
		title = "强度 · 系统决定"
	_draw_axes(main, title, 0, _display_max, _data.known_strength)
	for track: Dictionary in geometry.tracks:
		_draw_axes(track.rect, track.title, track.minimum, track.maximum)
	for index: int in _data.segments.size():
		var segment: Dictionary = _data.segments[index]
		var rect: Rect2 = geometry.segments[index]
		if segment.instant:
			_plot.draw_line(Vector2(rect.position.x, main.end.y), rect.position, segment.color, 4, true)
			_plot.draw_circle(rect.position, 4, segment.color)
		elif segment.strength <= 0:
			_plot.draw_line(Vector2(rect.position.x, main.end.y), Vector2(rect.end.x, main.end.y), MUTED, 3)
		else:
			var active: bool = _progress >= 0 and _progress * extent >= segment.start_ms and _progress * extent < segment.end_ms
			_plot.draw_rect(rect, Color(segment.color, 0.78 if active else 0.62))
			_plot.draw_rect(rect, segment.color, false, 2)
		if not segment.instant:
			var label: String = "静默" if segment.strength <= 0 else "%02d" % (index + 1)
			var width: float = plot_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			if rect.size.x >= width + 8:
				var y: float = maxf(main.position.y + 30, rect.position.y - 8)

				if segment.strength > 0 and y >= rect.position.y:
					_plot.draw_rect(Rect2(rect.get_center().x - width / 2 - 6, y - 26, width + 12, 32), Color(0.045, 0.06, 0.075, 0.94))
				_plot.draw_string(plot_font, Vector2(rect.position.x, y), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 30, segment.color)
	for index: int in geometry.curves.size():
		var points: PackedVector2Array = geometry.curves[index]
		if points.size() >= 2:
			if not geometry.curve_fills[index].is_empty():
				_plot.draw_colored_polygon(geometry.curve_fills[index], Color(COLORS[index % COLORS.size()], 0.18))
			_plot.draw_polyline(points, COLORS[index % COLORS.size()], 3, true)
	if _data.duration_ms > 0:
		for index: int in 5:
			var x: float = main.position.x + main.size.x * index / 4.0
			_plot.draw_line(Vector2(x, geometry.bottom), Vector2(x, geometry.bottom + 7), MUTED, 1)
			var text: String = "%.0f ms" % (extent * index / 4.0)
			var width: float = minf(180, main.size.x / 4.0)
			var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT if index == 0 else (HORIZONTAL_ALIGNMENT_RIGHT if index == 4 else HORIZONTAL_ALIGNMENT_CENTER)
			var label_x: float = x if index == 0 else (x - width if index == 4 else x - width / 2)
			_plot.draw_string(plot_font, Vector2(label_x, geometry.bottom + 38), text, alignment, width, 30, MUTED)
	_plot.draw_string(plot_font, Vector2(main.position.x, geometry.bottom + 78), "时间 (ms)", HORIZONTAL_ALIGNMENT_LEFT, main.size.x, 28, MUTED)
	if _progress >= 0:
		var x: float = main.position.x + main.size.x * _progress
		_plot.draw_line(Vector2(x, main.position.y), Vector2(x, geometry.bottom), PLAYHEAD, 3, true)
