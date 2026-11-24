@tool
class_name FlyTrail
extends Node2D













@export_group("外观")

@export_range(0.1, 500.0, 0.1) var head_width: float = 32.0:
	set(v):
		head_width = v
		if _line != null:
			_line.width = head_width
		_refresh_preview()

@export var head_color: Color = Color(1, 1, 1, 0.9):
	set(v):
		head_color = v
		_apply_gradient()
		_refresh_preview()

@export var tail_color: Color = Color(1, 1, 1, 0.0):
	set(v):
		tail_color = v
		_apply_gradient()
		_refresh_preview()

@export var width_curve: Curve = null:
	set(v):
		width_curve = v
		if _line != null:
			_line.width_curve = width_curve if width_curve != null else _default_width_curve()
		_refresh_preview()

@export var trail_texture: Texture2D = null:
	set(v):
		trail_texture = v
		if _line != null:
			_line.texture = trail_texture
		_refresh_preview()

@export_enum("None:0", "Tile:1", "Stretch:2") var texture_mode: int = 2:
	set(v):
		texture_mode = v
		if _line != null:
			_line.texture_mode = texture_mode as Line2D.LineTextureMode
		_refresh_preview()


@export_group("行为")

@export_range(0.05, 5.0, 0.01) var lifetime: float = 0.35

@export_range(0.0, 50.0, 0.5) var min_sample_distance: float = 2.0

@export_range(4, 512, 1) var max_points: int = 32


@export var follow_parent: bool = false



@export_range(0.0, 3.0, 0.1) var head_lead_ratio: float = 0.0


@export_group("编辑器预览")


@export var preview_in_editor: bool = true:
	set(v):
		preview_in_editor = v
		_refresh_preview()



var _target_node2d: Node2D = null
var _target_control: Control = null


var _points: Array = []
var _line: Line2D = null


func _ready() -> void :
	_line = Line2D.new()
	_line.width = head_width
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.width_curve = width_curve if width_curve != null else _default_width_curve()
	if trail_texture != null:
		_line.texture = trail_texture
		_line.texture_mode = texture_mode as Line2D.LineTextureMode
	_apply_gradient()
	add_child(_line)
	set_process(true)
	_refresh_preview()



func attach_control(ctrl: Control) -> void :
	_target_control = ctrl
	_target_node2d = null



func attach_node2d(node: Node2D) -> void :
	_target_node2d = node
	_target_control = null



func detach() -> void :
	_target_node2d = null
	_target_control = null



func clear_points() -> void :
	_points.clear()
	if _line != null:
		_line.points = PackedVector2Array()


func _process(_delta: float) -> void :
	if Engine.is_editor_hint():
		return

	if _target_node2d == null and _target_control == null and follow_parent:
		_auto_attach_parent()
	var world_pos: Vector2 = _read_target_center()
	if world_pos != Vector2.INF:
		_push_point(world_pos)
	_expire_and_rebuild()


func _auto_attach_parent() -> void :
	var p: = get_parent()
	if p is Node2D:
		_target_node2d = p
	elif p is Control:
		_target_control = p


func _read_target_center() -> Vector2:
	if _target_node2d != null and is_instance_valid(_target_node2d):
		return _target_node2d.global_position
	if _target_control != null and is_instance_valid(_target_control):

		return _target_control.get_global_rect().get_center()
	return Vector2.INF


func _push_point(pos: Vector2) -> void :
	if not _points.is_empty():
		var last: Vector2 = _points[-1]["pos"]
		if pos.distance_squared_to(last) < min_sample_distance * min_sample_distance:
			return
	var now: float = Time.get_ticks_msec() / 1000.0
	_points.append({"pos": pos, "born": now})
	if _points.size() > max_points:
		_points.pop_front()


func _expire_and_rebuild() -> void :
	var now: float = Time.get_ticks_msec() / 1000.0
	while not _points.is_empty() and now - _points[0]["born"] > lifetime:
		_points.pop_front()

	if _line == null:
		return
	if _points.size() < 2:
		_line.points = PackedVector2Array()
		return




	var arr: = PackedVector2Array()
	arr.resize(_points.size())
	var total_len: float = 0.0
	for i in _points.size():
		arr[i] = to_local(_points[i]["pos"])
		if i > 0:
			total_len += arr[i].distance_to(arr[i - 1])




	if total_len < head_width * 0.5:
		_line.points = PackedVector2Array()
		return


	if head_lead_ratio > 0.0 and _points.size() >= 2:
		var head_delta: Vector2 = arr[arr.size() - 1] - arr[arr.size() - 2]
		arr[arr.size() - 1] += head_delta * head_lead_ratio
	_line.points = arr


func _apply_gradient() -> void :
	if _line == null:
		return
	var grad: = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([tail_color, head_color])
	_line.gradient = grad


func _default_width_curve() -> Curve:
	var c: = Curve.new()
	c.add_point(Vector2(0.0, 0.0))
	c.add_point(Vector2(1.0, 1.0))
	return c



func _refresh_preview() -> void :
	if not Engine.is_editor_hint():
		return
	if _line == null:
		return
	if not preview_in_editor:
		_line.points = PackedVector2Array()
		return

	var preview_points: = PackedVector2Array()
	var count: = 24
	for i in count:
		var t: float = float(i) / float(count - 1)

		var p0: = Vector2(-100, 50)
		var p1: = Vector2(0, -80)
		var p2: = Vector2(100, -50)
		var q: = p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
		preview_points.append(q)
	_line.points = preview_points
