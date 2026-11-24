class_name HapticThumbnail
extends HBoxContainer


const _PLATFORMS: Array[String] = ["android", "ios"]
const _BASE_HEIGHT: float = 280.0
const _TRACK_HEIGHT: float = 88.0
@export var plot_font: Font
@onready var _plots: Dictionary = {"android": $Android, "ios": $Ios}

var _profile: Dictionary = {}
var _data: Dictionary = {}
var _geometry: Dictionary = {}
var _sizes: Dictionary = {}
var _generation: int = 0
var _task_generation: int = 0
var _task: int = -1
var _job: Dictionary = {}
var _dirty: bool = false
var _chart_style: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void :
	_chart_style.bg_color = Color(0.045, 0.06, 0.075, 1)
	_chart_style.border_color = Color(0.25, 0.29, 0.34, 1)
	_chart_style.set_border_width_all(1)
	_chart_style.set_corner_radius_all(12)
	for platform: String in _PLATFORMS:
		var plot: Control = _plots[platform]
		plot.draw.connect(_draw_plot.bind(platform))
		plot.resized.connect(_queue_build)
	visibility_changed.connect(_start_pending)
	set_process(false)
	_start_pending.call_deferred()


func set_profile(profile: Dictionary) -> void :
	if _profile == profile:
		return
	_generation += 1
	_profile = profile.duplicate(true)
	_data = {}
	_geometry = {}
	_queue_build()


func _queue_build() -> void :
	_dirty = true
	if is_node_ready():
		_start_pending()


func _start_pending() -> void :
	if not is_node_ready() or not is_visible_in_tree() or not _dirty or _task >= 0 or _profile.is_empty():
		return
	_dirty = false
	_task_generation = _generation
	var sizes: Dictionary = {}
	for platform: String in _PLATFORMS:
		sizes[platform] = (_plots[platform] as Control).size
	_job = {}
	_task = WorkerThreadPool.add_task(_build_job.bind(_profile.duplicate(true), _data.duplicate(true), sizes, _job))
	set_process(true)


static func _build_job(profile: Dictionary, cached: Dictionary, sizes: Dictionary, result: Dictionary) -> void :
	result.data = cached
	result.geometry = {}
	result.sizes = sizes
	for platform: String in _PLATFORMS:
		if not result.data.has(platform):
			result.data[platform] = HapticPreview.read_preview_data(profile.get(platform, {}), platform)
		result.geometry[platform] = _build_geometry(result.data[platform], sizes[platform])


func _process(_delta: float) -> void :
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		if _task_generation == _generation:
			_data = _job.data
			_geometry = _job.geometry
			_sizes = _job.sizes
			for platform: String in _PLATFORMS:
				var plot: Control = _plots[platform]
				plot.custom_minimum_size.y = _geometry[platform].height
				plot.tooltip_text = _data[platform].title
				plot.queue_redraw()
		_start_pending()
	set_process(_task >= 0)


func get_preview_data(platform: String) -> Dictionary:
	return (_data.get(platform, {}) as Dictionary).duplicate(true)


func get_plot_geometry(platform: String) -> Dictionary:
	return (_geometry.get(platform, {}) as Dictionary).duplicate(true)


func _exit_tree() -> void :
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)


static func _build_geometry(data: Dictionary, plot_size: Vector2) -> Dictionary:
	var tracks: Array[Dictionary] = HapticPreview._curve_tracks(data)
	var main: Rect2 = Rect2(54, 80, maxf(plot_size.x - 70, 1), maxf(plot_size.y - 126 - tracks.size() * _TRACK_HEIGHT, 1))
	var extent: float = maxf(float(data.duration_ms), 1)
	var segments: Array[Rect2] = []
	for segment: Dictionary in data.segments:
		segments.append(Rect2(main.position.x + main.size.x * segment.start_ms / extent, 
			main.end.y - main.size.y * segment.strength, 
			main.size.x * (segment.end_ms - segment.start_ms) / extent, main.size.y * segment.strength))
	var bottom: float = main.end.y
	for track: Dictionary in tracks:
		track.rect = Rect2(main.position.x, bottom + 36, main.size.x, _TRACK_HEIGHT - 36)
		bottom = track.rect.end.y
	var curves: Array[PackedVector2Array] = []
	var fills: Array[PackedVector2Array] = []
	for curve: Dictionary in data.curves:
		for track: Dictionary in tracks:
			if curve.name not in track.members:
				continue
			var points: PackedVector2Array = PackedVector2Array()
			for point: Vector2 in curve.points:
				var value: float = (clampf(point.y, track.minimum, track.maximum) - track.minimum) / (track.maximum - track.minimum)
				points.append(Vector2(main.position.x + main.size.x * point.x / extent, track.rect.end.y - track.rect.size.y * value))
			curves.append(points)
			var baseline: float = track.rect.end.y - (0.0 - track.minimum) / (track.maximum - track.minimum) * track.rect.size.y
			fills.append(HapticPreview._curve_fill(points, baseline) if curve.name == "HapticIntensityControl" else PackedVector2Array())
			break
	return {"main": main, "extent": extent, "segments": segments, "tracks": tracks, "curves": curves, 
		"fills": fills, "bottom": bottom, "height": _BASE_HEIGHT + tracks.size() * _TRACK_HEIGHT}


func _draw_axes(plot: Control, rect: Rect2, title: String, minimum: float, maximum: float, known: bool = true) -> void :
	plot.draw_style_box(_chart_style, rect)
	plot.draw_string(plot_font, Vector2(rect.position.x, rect.position.y - 12), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 24, HapticPreview.TEXT)
	for index: int in 3:
		var fraction: float = index / 2.0
		var y: float = rect.end.y - rect.size.y * fraction
		plot.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), HapticPreview.GRID, 1)
		if known:
			var value: float = minimum + fraction * (maximum - minimum)
			var text: String = str(roundi(value)) if maximum > 1 or is_equal_approx(value, roundf(value)) else "%.1f" % value
			plot.draw_string(plot_font, Vector2(4, y + 8), text, HORIZONTAL_ALIGNMENT_LEFT, 44, 22, HapticPreview.MUTED)
	plot.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), HapticPreview.MUTED, 1.5)
	plot.draw_line(Vector2(rect.position.x, rect.end.y), rect.end, HapticPreview.MUTED, 1.5)


func _draw_plot(platform: String) -> void :
	var plot: Control = _plots[platform]
	if plot_font == null or plot.size.x < 100:
		return
	plot.draw_style_box(_chart_style, Rect2(Vector2.ZERO, plot.size))
	plot.draw_string(plot_font, Vector2(12, 32), "Android" if platform == "android" else "iOS", HORIZONTAL_ALIGNMENT_LEFT, 132, 30, HapticPreview.TEXT)
	if not _data.has(platform) or _sizes.get(platform, Vector2.ZERO) != plot.size:
		plot.draw_string(plot_font, Vector2(12, 80), "正在加载...", HORIZONTAL_ALIGNMENT_LEFT, plot.size.x - 24, 26, HapticPreview.MUTED)
		return
	var data: Dictionary = _data[platform]
	var geometry: Dictionary = _geometry[platform]
	var main: Rect2 = geometry.main
	var total: String = "%.0f ms" % data.duration_ms if data.known_time else "时长未知"
	plot.draw_string(plot_font, Vector2(plot.size.x - 156, 32), total, HORIZONTAL_ALIGNMENT_RIGHT, 144, 26, HapticPreview.PULSE)
	if not data.system.is_empty():
		plot.draw_rect(main, Color(data.system.color, 0.15))
		plot.draw_rect(main, data.system.color, false, 2)
		plot.draw_string(plot_font, Vector2(main.position.x + 8, main.get_center().y + 8), data.system.label, HORIZONTAL_ALIGNMENT_CENTER, main.size.x - 16, 26, HapticPreview.TEXT)
		_draw_footer(plot, geometry, "系统反馈 / 类型示意")
		return
	if not data.primitives.is_empty():
		_draw_axes(plot, main, "力度 (Scale)", 0, 1)
		var slot: float = main.size.x / data.primitives.size()
		for index: int in data.primitives.size():
			var primitive: Dictionary = data.primitives[index]
			var height: float = main.size.y * primitive.scale
			var rect: Rect2 = Rect2(main.position.x + index * slot + 2, main.end.y - height, maxf(slot - 4, 1), height)
			plot.draw_rect(rect, Color(primitive.color, 0.62))
			plot.draw_rect(rect, primitive.color, false, 1.5)
		_draw_footer(plot, geometry, "原语顺序 / 时长未知")
		return
	if data.segments.is_empty() and data.curves.is_empty():
		_draw_footer(plot, geometry, "无可绘制数据")
		return
	var maximum: float = 255.0 if platform == "android" else 1.0
	var axis_title: String = "振幅 (0~255)" if platform == "android" else "强度 (0~1)"
	_draw_axes(plot, main, axis_title if data.known_strength else "强度 / 系统决定", 0, maximum, data.known_strength)
	for index: int in data.segments.size():
		var segment: Dictionary = data.segments[index]
		var rect: Rect2 = geometry.segments[index]
		if segment.instant:
			plot.draw_line(Vector2(rect.position.x, main.end.y), rect.position, segment.color, 3, true)
			plot.draw_circle(rect.position, 3, segment.color)
		elif segment.strength <= 0:
			plot.draw_line(Vector2(rect.position.x, main.end.y), Vector2(rect.end.x, main.end.y), HapticPreview.MUTED, 3)
			if rect.size.x >= 56:
				plot.draw_string(plot_font, Vector2(rect.position.x, main.end.y - 8), "静默", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, HapticPreview.MUTED)
		else:
			plot.draw_rect(rect, Color(segment.color, 0.62))
			plot.draw_rect(rect, segment.color, false, 1.5)
			if rect.size.x >= 44:
				var y: float = maxf(main.position.y + 24, rect.position.y - 6)
				if y >= rect.position.y:
					plot.draw_rect(Rect2(rect.get_center().x - 20, y - 20, 40, 26), _chart_style.bg_color)
				plot.draw_string(plot_font, Vector2(rect.position.x, y), "%02d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, segment.color)
	for track: Dictionary in geometry.tracks:
		_draw_axes(plot, track.rect, track.title, track.minimum, track.maximum)
	for index: int in geometry.curves.size():
		var points: PackedVector2Array = geometry.curves[index]
		if points.size() >= 2:
			var color: Color = HapticPreview.COLORS[index % HapticPreview.COLORS.size()]
			if not geometry.fills[index].is_empty():
				plot.draw_colored_polygon(geometry.fills[index], Color(color, 0.18))
			plot.draw_polyline(points, color, 2, true)
	if data.duration_ms > 0:
		for index: int in 3:
			var x: float = main.position.x + main.size.x * index / 2.0
			var width: float = minf(110, main.size.x / 2.0)
			var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT if index == 0 else (HORIZONTAL_ALIGNMENT_RIGHT if index == 2 else HORIZONTAL_ALIGNMENT_CENTER)
			var label_x: float = x if index == 0 else (x - width if index == 2 else x - width / 2)
			plot.draw_string(plot_font, Vector2(label_x, geometry.bottom + 34), "%.0f ms" % (data.duration_ms * index / 2.0), alignment, width, 22, HapticPreview.MUTED)
	else:
		_draw_footer(plot, geometry, "起点 0 ms / 时长未知" if not data.known_time else "时间 (ms)")


func _draw_footer(plot: Control, geometry: Dictionary, text: String) -> void :
	plot.draw_string(plot_font, Vector2(12, geometry.bottom + 34), text, HORIZONTAL_ALIGNMENT_CENTER, plot.size.x - 24, 24, HapticPreview.MUTED)
