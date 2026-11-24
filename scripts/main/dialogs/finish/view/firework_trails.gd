class_name FireworkTrails
extends Node2D





























const _MAX_POINTS: int = 32


const _MIN_SAMPLE_DIST: float = 0.5




class Ribbon extends RefCounted:
	var target: Node2D = null
	var head_width: float = 16.0
	var rgb: Color = Color.WHITE
	var head_alpha: float = 0.9
	var lifetime: float = 0.25
	var pos: PackedVector2Array = PackedVector2Array()
	var born: PackedFloat32Array = PackedFloat32Array()

	func prepare_capacity(capacity: int) -> void :
		pos.resize(capacity)
		born.resize(capacity)
		pos.clear()
		born.clear()

	func activate(next_target: Node2D, next_head_width: float, next_rgb: Color, 
			next_head_alpha: float, next_lifetime: float) -> void :
		target = next_target
		head_width = next_head_width
		rgb = next_rgb
		head_alpha = next_head_alpha
		lifetime = next_lifetime
		pos.clear()
		born.clear()


	func detach() -> void :
		target = null

	func is_done() -> bool:
		return target == null and pos.is_empty()

	func reset() -> void :
		target = null
		pos.clear()
		born.clear()


var _ribbons: Array[Ribbon] = []
var _available_ribbons: Array[Ribbon] = []
var _mesh: ImmediateMesh = null




var blend_mode: CanvasItemMaterial.BlendMode = CanvasItemMaterial.BLEND_MODE_MIX


func _ready() -> void :
	_mesh = ImmediateMesh.new()
	var mi: = MeshInstance2D.new()
	mi.name = "TrailMesh"
	mi.mesh = _mesh
	if blend_mode != CanvasItemMaterial.BLEND_MODE_MIX:
		var mat: = CanvasItemMaterial.new()
		mat.blend_mode = blend_mode
		mi.material = mat
	add_child(mi)
	set_process(true)




func prepare_pool(capacity: int) -> void :
	var total: int = _ribbons.size() + _available_ribbons.size()
	while total < capacity:
		_create_pooled_ribbon()
		total += 1


func prepare_pool_spread(capacity: int, budget_usec: int = 2000) -> void :
	var total: int = _ribbons.size() + _available_ribbons.size()
	var frame_started: int = Time.get_ticks_usec()
	while total < capacity:
		_create_pooled_ribbon()
		total += 1
		if total < capacity and Time.get_ticks_usec() - frame_started >= budget_usec:
			await get_tree().process_frame
			frame_started = Time.get_ticks_usec()


func _create_pooled_ribbon() -> void :
	var ribbon: = Ribbon.new()
	ribbon.prepare_capacity(_MAX_POINTS)
	_available_ribbons.append(ribbon)



func add_ribbon(target: Node2D, head_width: float, rgb: Color, 
		head_alpha: float, lifetime: float) -> Ribbon:
	var r: Ribbon = _available_ribbons.pop_back() if not _available_ribbons.is_empty()\
	else Ribbon.new()
	r.activate(target, head_width, rgb, head_alpha, lifetime)
	_ribbons.append(r)
	return r



func clear_all() -> void :
	for r: Ribbon in _ribbons:
		r.reset()
		_available_ribbons.append(r)
	_ribbons.clear()
	if _mesh != null:
		_mesh.clear_surfaces()


func _process(_delta: float) -> void :
	var now: float = Time.get_ticks_msec() / 1000.0
	var alive: Array[Ribbon] = []
	for r in _ribbons:
		_sample(r, now)
		_expire(r, now)
		if not r.is_done():
			alive.append(r)
		else:
			r.reset()
			_available_ribbons.append(r)
	_ribbons = alive
	_rebuild()



func _sample(r: Ribbon, now: float) -> void :
	if r.target != null and not is_instance_valid(r.target):


		r.target = null
	if r.target == null:
		return
	var p: Vector2 = r.target.global_position
	if not r.pos.is_empty():
		var last: Vector2 = r.pos[r.pos.size() - 1]
		if p.distance_squared_to(last) < _MIN_SAMPLE_DIST * _MIN_SAMPLE_DIST:
			return
	r.pos.append(p)
	r.born.append(now)
	if r.pos.size() > _MAX_POINTS:
		r.pos.remove_at(0)
		r.born.remove_at(0)



func _expire(r: Ribbon, now: float) -> void :
	while r.born.size() > 0 and now - r.born[0] > r.lifetime:
		r.pos.remove_at(0)
		r.born.remove_at(0)



func _rebuild() -> void :
	if _mesh == null:
		return
	_mesh.clear_surfaces()


	if not _has_drawable_ribbon():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in _ribbons:
		_emit_ribbon(r)
	_mesh.surface_end()


func _has_drawable_ribbon() -> bool:
	for r in _ribbons:
		var n: int = r.pos.size()
		if n < 2:
			continue
		var min_length: float = r.head_width * 0.5
		var total: float = 0.0
		var prev: Vector2 = to_local(r.pos[0])
		for i in range(1, n):
			var current: Vector2 = to_local(r.pos[i])
			total += current.distance_to(prev)
			if total >= min_length:
				return true
			prev = current
	return false


func _emit_ribbon(r: Ribbon) -> void :
	var n: int = r.pos.size()
	if n < 2:
		return

	var local: PackedVector2Array = PackedVector2Array()
	local.resize(n)
	var cum: PackedFloat32Array = PackedFloat32Array()
	cum.resize(n)
	var total: float = 0.0
	for i in n:
		local[i] = to_local(r.pos[i])
		if i > 0:
			total += local[i].distance_to(local[i - 1])
		cum[i] = total

	if total < r.head_width * 0.5:
		return
	var half: float = r.head_width * 0.5
	for i in n - 1:
		var t0: float = cum[i] / total
		var t1: float = cum[i + 1] / total
		var n0: Vector2 = _normal_at(local, i)
		var n1: Vector2 = _normal_at(local, i + 1)
		var w0: Vector2 = n0 * (half * t0)
		var w1: Vector2 = n1 * (half * t1)
		var c0: Color = Color(r.rgb.r, r.rgb.g, r.rgb.b, r.head_alpha * t0)
		var c1: Color = Color(r.rgb.r, r.rgb.g, r.rgb.b, r.head_alpha * t1)
		var a0: Vector2 = local[i] + w0
		var a1: Vector2 = local[i] - w0
		var b0: Vector2 = local[i + 1] + w1
		var b1: Vector2 = local[i + 1] - w1
		_tri(a0, c0, a1, c0, b1, c1)
		_tri(a0, c0, b1, c1, b0, c1)



func _normal_at(pts: PackedVector2Array, i: int) -> Vector2:
	var last: int = pts.size() - 1
	var dir: Vector2
	if i == 0:
		dir = pts[1] - pts[0]
	elif i == last:
		dir = pts[last] - pts[last - 1]
	else:
		dir = pts[i + 1] - pts[i - 1]
	if dir.length_squared() <= 1e-07:
		return Vector2.UP
	return dir.normalized().orthogonal()


func _tri(p0: Vector2, c0: Color, p1: Vector2, c1: Color, p2: Vector2, c2: Color) -> void :
	_mesh.surface_set_color(c0)
	_mesh.surface_add_vertex_2d(p0)
	_mesh.surface_set_color(c1)
	_mesh.surface_add_vertex_2d(p1)
	_mesh.surface_set_color(c2)
	_mesh.surface_add_vertex_2d(p2)
