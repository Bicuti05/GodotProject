@tool
extends Node

const _MOVE_THRESHOLD: float = 0.01

@export_group("Target")
@export_node_path("Node2D")
var target_path: NodePath

@export var use_self_when_no_target: bool = true
@export var use_parent_when_no_target: bool = true

@export_group("Trail Lines")
@export var trail_line_list: Array[Line2D] = []
@export var auto_collect_child_lines: bool = true
@export var recursive_collect_child_lines: bool = true

@export_group("Preview")
@export var editor_live_preview: bool = true
@export var runtime_enabled: bool = true
@export var debug_log: bool = false

@export_group("Trail Params")
@export_range(0.05, 20.0, 0.01, "suffix:s")
var trail_duration: float = 0.6

@export var use_fixed_trail_length: bool = true

@export_range(1.0, 2000.0, 1.0, "suffix:px")
var fixed_trail_length: float = 120.0

@export_range(0.1, 100.0, 0.1, "suffix:px")
var min_sample_distance: float = 2.0

@export_range(2, 512, 1)
var max_points: int = 80

@export_range(1, 64, 1)
var fast_move_fill_limit: int = 32

@export_range(0.005, 0.2, 0.001, "suffix:s")
var stationary_fill_interval: float = 0.016

@export_range(0.1, 10.0, 0.1, "suffix:px")
var shrink_stop_threshold: float = 1.0

@export_group("Debug")
@export_tool_button("Generate Test Line")
var generate_test_line_btn: Callable = _on_generate_test_line_pressed

@export_tool_button("Clear Trail")
var clear_trail_btn: Callable = _on_clear_trail_pressed

var _positions: Array[Vector2] = []
var _ages: Array[float] = []
var _last_sample_pos: Vector2 = Vector2.ZERO
var _has_sample: bool = false
var _stationary_timer: float = 0.0
var _editor_dragging: bool = false
var _prev_target_pos: Vector2 = Vector2.ZERO
var _has_prev_target_pos: bool = false
var _current_fixed_length: float = 0.0

func _enter_tree() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_setup_lines()

func _process(delta: float) -> void :
	var lines: = _get_trail_lines()
	if lines.is_empty():
		return

	var target: = _get_target_node()
	if target == null:
		return

	_setup_lines()
	_sync_lines_layering(target, lines)
	var target_position: = target.global_position
	var target_is_moving: = _is_target_moving(target_position)

	if Engine.is_editor_hint():
		if not editor_live_preview:
			return
		_sample_position(target_position, delta)
	else:
		if not runtime_enabled:
			return
		_sample_position(target_position, delta)

	if _ages.is_empty():
		return

	for i in range(_ages.size()):
		_ages[i] += delta

	if use_fixed_trail_length:
		if target_is_moving:
			_current_fixed_length = fixed_trail_length
			_trim_fixed_length_history()
		elif _current_fixed_length > 0.0:
			var shrink_speed: = fixed_trail_length / maxf(trail_duration, 0.001)
			_current_fixed_length = maxf(0.0, _current_fixed_length - shrink_speed * delta)
			if _current_fixed_length <= shrink_stop_threshold:
				clear_trail()
				return
	else:
		_trim_old_points()

	_write_line_points()

func editor_trail_dragging(dragging: bool) -> void :
	_editor_dragging = dragging
	if not dragging:
		_stationary_timer = stationary_fill_interval

func editor_force_trail_sample() -> void :
	var lines: = _get_trail_lines()
	if lines.is_empty():
		return

	var target: = _get_target_node()
	if target != null:
		_setup_lines()
		_sync_lines_layering(target, lines)
		_sample_position(target.global_position, 0.0)
		if use_fixed_trail_length and _positions.size() >= 2:
			_current_fixed_length = fixed_trail_length
		_write_line_points()

func _is_target_moving(pos: Vector2) -> bool:
	if not _has_prev_target_pos:
		_prev_target_pos = pos
		_has_prev_target_pos = true
		return false

	var moving: = _prev_target_pos.distance_to(pos) > _MOVE_THRESHOLD
	_prev_target_pos = pos
	return moving

func _get_target_node() -> Node2D:
	if target_path != NodePath():
		var target: = get_node_or_null(target_path)
		if target is Node2D:
			return target as Node2D

	if use_self_when_no_target:
		var current: = get_node_or_null(".")
		if current is Node2D:
			return current as Node2D

	if use_parent_when_no_target:
		var parent: = get_parent()
		if parent is Node2D:
			return parent as Node2D

	return null




func _power_saving() -> bool:
	if Engine.is_editor_hint():
		return false
	var ps: Node = get_tree().root.get_node_or_null(^"PowerSaver") if is_inside_tree() else null
	return ps != null and bool(ps.call(&"is_armed"))

func _sync_lines_layering(target: Node2D, lines: Array[Line2D]) -> void :
	var target_item: = target as CanvasItem
	if not _power_saving():
		for line in lines:
			line.z_as_relative = target_item.z_as_relative
			line.z_index = target_item.z_index
		return
	for line in lines:


		if line.z_as_relative != target_item.z_as_relative:
			line.z_as_relative = target_item.z_as_relative
		if line.z_index != target_item.z_index:
			line.z_index = target_item.z_index

func _sample_position(pos: Vector2, delta: float) -> void :
	if not _has_sample:
		_append_point(pos)
		_last_sample_pos = pos
		_has_sample = true
		_stationary_timer = 0.0
		return

	var distance: = _last_sample_pos.distance_to(pos)

	if distance >= min_sample_distance:
		_stationary_timer = 0.0

		var step: = maxf(min_sample_distance, 0.5)
		var count: = maxi(1, int(ceil(distance / step)))
		count = mini(count, fast_move_fill_limit)

		var from_pos: = _last_sample_pos
		for i in range(1, count + 1):
			var t: = float(i) / float(count)
			_append_point(from_pos.lerp(pos, t))

		_last_sample_pos = pos
		_trim_max_points()
		return

	if _should_append_stationary_head():
		_stationary_timer += delta
		if _stationary_timer >= stationary_fill_interval:
			_stationary_timer = 0.0
			_append_point(pos)
			_last_sample_pos = pos
			_trim_max_points()
	else:
		_stationary_timer = 0.0

func _should_append_stationary_head() -> bool:
	if use_fixed_trail_length:
		return false

	if _positions.size() < 2:
		return false
	return _get_trail_span() > shrink_stop_threshold

func _get_trail_span() -> float:
	if _positions.size() < 2:
		return 0.0
	return _positions[0].distance_to(_positions[_positions.size() - 1])

func _append_point(pos: Vector2) -> void :
	_positions.append(pos)
	_ages.append(0.0)

func _trim_max_points() -> void :
	while _positions.size() > max_points:
		_positions.pop_front()
		_ages.pop_front()

func _trim_old_points() -> void :
	while _positions.size() > 1 and _ages[1] > trail_duration:
		_positions.pop_front()
		_ages.pop_front()

	if _positions.size() == 1 and _ages[0] > trail_duration:
		clear_trail()

func _trim_fixed_length_history() -> void :
	if _positions.size() <= 2:
		return

	var remaining: = maxf(fixed_trail_length, 0.0)
	var keep_from: = 0
	var found_boundary: = false

	for i in range(_positions.size() - 1, 0, -1):
		var segment_length: = _positions[i].distance_to(_positions[i - 1])
		if is_zero_approx(segment_length):
			continue

		if remaining > segment_length:
			remaining -= segment_length
			continue

		keep_from = i - 1
		found_boundary = true
		break

	if not found_boundary:
		return

	while keep_from > 0:
		_positions.pop_front()
		_ages.pop_front()
		keep_from -= 1

func _write_line_points() -> void :
	var lines: = _get_trail_lines()
	if lines.is_empty():
		return

	if _positions.size() < 2:



		var ps_on: = _power_saving()
		for line in lines:
			if not ps_on or line.get_point_count() > 0:
				line.clear_points()
				line.queue_redraw()
		return

	var packed_global: = _build_fixed_length_points() if use_fixed_trail_length else _build_time_limited_points()

	for line in lines:
		if packed_global.size() < 2:
			line.clear_points()
			line.queue_redraw()
			continue

		var packed_local: = PackedVector2Array()
		packed_local.resize(packed_global.size())
		for i in range(packed_global.size()):
			packed_local[i] = line.to_local(packed_global[i])

		line.points = packed_local
		line.queue_redraw()

func _build_time_limited_points() -> PackedVector2Array:
	var packed_global: = PackedVector2Array()
	var first_valid: = -1
	for i in range(_ages.size()):
		if _ages[i] <= trail_duration:
			first_valid = i
			break

	if first_valid == -1:
		clear_trail()
		return packed_global

	if first_valid > 0:
		var old_pos: = _positions[first_valid - 1]
		var new_pos: = _positions[first_valid]
		var old_age: = _ages[first_valid - 1]
		var new_age: = _ages[first_valid]
		var t: = 0.0

		if not is_equal_approx(old_age, new_age):
			t = clampf((trail_duration - old_age) / (new_age - old_age), 0.0, 1.0)

		packed_global.append(old_pos.lerp(new_pos, t))

	for i in range(first_valid, _positions.size()):
		packed_global.append(_positions[i])

	return packed_global

func _build_fixed_length_points() -> PackedVector2Array:
	var packed_global: = PackedVector2Array()
	var reversed_points: Array[Vector2] = []
	var active_length: = maxf(_current_fixed_length, 0.0)

	if active_length <= 0.0:
		return packed_global

	reversed_points.append(_positions[_positions.size() - 1])

	for i in range(_positions.size() - 1, 0, -1):
		var from_pos: = _positions[i]
		var to_pos: = _positions[i - 1]
		var segment_length: = from_pos.distance_to(to_pos)

		if is_zero_approx(segment_length):
			continue

		if active_length >= segment_length:
			reversed_points.append(to_pos)
			active_length -= segment_length
		else:
			var t: = clampf(active_length / segment_length, 0.0, 1.0)
			reversed_points.append(from_pos.lerp(to_pos, t))
			break

	for i in range(reversed_points.size() - 1, -1, -1):
		packed_global.append(reversed_points[i])

	return packed_global

func _get_trail_lines() -> Array[Line2D]:
	var result: Array[Line2D] = []

	for line in trail_line_list:
		if is_instance_valid(line) and not result.has(line):
			result.append(line)

	if auto_collect_child_lines:
		_collect_child_lines(self, result)

	return result

func _collect_child_lines(node: Node, result: Array[Line2D]) -> void :
	for child in node.get_children():
		if child is Line2D:
			var line: = child as Line2D
			if not result.has(line):
				result.append(line)

		if recursive_collect_child_lines:
			_collect_child_lines(child, result)

func _setup_lines() -> void :

	if not _power_saving():
		for line in _get_trail_lines():
			line.top_level = false
			line.closed = false
			line.visible = true
		return



	for line in _get_trail_lines():
		if line.top_level:
			line.top_level = false
		if line.closed:
			line.closed = false
		if not line.visible:
			line.visible = true

func _on_generate_test_line_pressed() -> void :
	var lines: = _get_trail_lines()
	if lines.is_empty():
		_print_debug("No trail Line2D found.")
		return

	var target: = _get_target_node()
	var center: = Vector2.ZERO
	if target != null:
		center = target.global_position

	var packed_global: = PackedVector2Array([
		center + Vector2(-120.0, 0.0), 
		center, 
		center + Vector2(120.0, 0.0)
	])

	_setup_lines()
	if target != null:
		_sync_lines_layering(target, lines)

	for line in lines:
		var packed_local: = PackedVector2Array()
		packed_local.resize(packed_global.size())
		for i in range(packed_global.size()):
			packed_local[i] = line.to_local(packed_global[i])
		line.points = packed_local
		line.queue_redraw()

	_print_debug("Test line generated.")

func _on_clear_trail_pressed() -> void :
	clear_trail()

func notify_target_moved() -> void :
	var target: = _get_target_node()
	if target == null:
		return
	var pos: = target.global_position
	_sample_position(pos, 0.0)
	if use_fixed_trail_length:
		_current_fixed_length = fixed_trail_length
		_trim_fixed_length_history()
	_write_line_points()


func clear_trail() -> void :
	_positions.clear()
	_ages.clear()
	_has_sample = false
	_last_sample_pos = Vector2.ZERO
	_stationary_timer = 0.0
	_has_prev_target_pos = false
	_prev_target_pos = Vector2.ZERO
	_current_fixed_length = 0.0

	for line in _get_trail_lines():
		line.clear_points()
		line.queue_redraw()

	_print_debug("Trail cleared.")

func _print_debug(text: String) -> void :
	if debug_log:
		print("[TrailPreviewController2D] %s" % text)
