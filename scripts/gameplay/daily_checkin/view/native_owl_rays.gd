extends Node2D
const RAY_SCENE = preload("res://scripts/gameplay/daily_checkin/view/checkin_ray_mesh.tscn")



@export var trail_texture: Texture2D
const SOURCE_START: = 0.4
const SOURCE_UI_WIDTH: = 500.0
const UI_PIXELS_PER_NATIVE_UNIT: = 80.0
const MESH_FRAME_BUDGET_US: int = 3000
const LAYER_STYLES: = [
	{"name": "PrimaryWarmHeads", "width": 0.72, "distance": 0.95, "alpha": 0.82, "tint": Color.WHITE}, 
	{"name": "DistantThinRays", "width": 0.28, "distance": 1.08, "alpha": 0.36, "tint": Color.WHITE}, 
	{"name": "SecondaryTrails", "width": 0.55, "distance": 1.0, "alpha": 0.66, "tint": Color.WHITE}, 
]
var source: Dictionary
var mesh_layers: Array[MeshInstance2D] = []
var frame_meshes: Array = []
var stage_basis: = Transform2D.IDENTITY
var frozen_transform: = Transform2D.IDENTITY
var anchored: = false
var frame_index: = -1
var live_count: = 0
var playing: = false
var width: = 618.0
var prepared: bool = false

class RayMeshData:
	extends RefCounted
	var source: Dictionary = {}
	var frame_arrays: Array = []
	var styles: Array = []

	func load_frames() -> void :
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effect/owl_activation/rays_native.json"))
		if not parsed is Dictionary:
			return
		source = parsed
		for layer_index: int in range(source.layers.size()):
			var layer: Dictionary = source.layers[layer_index]
			var style: Dictionary = styles[layer_index]
			var frames: Array = []
			for frame: Dictionary in layer.frames:
				if frame.indices.is_empty():
					frames.append(null)
					continue
				var vertices: = PackedVector2Array()
				var uv: = PackedVector2Array()
				var colors: = PackedColorArray()
				for i: int in range(frame.vertices.size() / 3):
					var v: = Vector2(float(frame.vertices[i * 3]), - float(frame.vertices[i * 3 + 1]))
					var paired: int = i + 1 if i % 2 == 0 else i - 1
					var twin: = Vector2(float(frame.vertices[paired * 3]), - float(frame.vertices[paired * 3 + 1]))
					var center: = (v + twin) * 0.5
					vertices.append(center + (v - center) * float(style.width))
					uv.append(Vector2(1.0 - float(frame.uv[i * 2]), 1.0 - float(frame.uv[i * 2 + 1])))
					colors.append(Color(float(frame.colors[i * 4]), float(frame.colors[i * 4 + 1]), float(frame.colors[i * 4 + 2]), float(frame.colors[i * 4 + 3])) * (style.tint as Color) * Color(1, 1, 1, float(style.alpha)))
				var arrays: Array = []
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX] = vertices
				arrays[Mesh.ARRAY_TEX_UV] = uv
				arrays[Mesh.ARRAY_COLOR] = colors
				arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(frame.indices)
				frames.append(arrays)
			frame_arrays.append(frames)

func _ready() -> void :
	var loader: = RayMeshData.new()
	loader.styles = LAYER_STYLES
	var task_id: int = WorkerThreadPool.add_task(loader.load_frames)
	while not WorkerThreadPool.is_task_completed(task_id):
		await get_tree().process_frame
		if not is_inside_tree():
			return
	WorkerThreadPool.wait_for_task_completion(task_id)
	source = loader.source
	if source.is_empty():
		SortLogger.error("[DailyCheckin] failed to load ray mesh data")
		prepared = true
		return
	var add: = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	var batch_start_us: int = Time.get_ticks_usec()
	for layer_index in source.layers.size():
		var layer: Dictionary = source.layers[layer_index]
		var style: Dictionary = LAYER_STYLES[layer_index]
		var node: MeshInstance2D = RAY_SCENE.instantiate()
		node.name = "UnityTrail_" + String(layer.name) + "_" + String(style.name)
		node.texture = trail_texture
		node.material = add
		add_child(node)
		mesh_layers.append(node)
		var meshes: Array = []
		for arrays: Variant in loader.frame_arrays[layer_index]:
			if arrays == null:
				meshes.append(null)
				continue
			var mesh: = ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			meshes.append(mesh)
			if Time.get_ticks_usec() - batch_start_us >= MESH_FRAME_BUDGET_US:
				await get_tree().process_frame
				if not is_inside_tree():
					return
				batch_start_us = Time.get_ticks_usec()
		frame_meshes.append(meshes)
	reset()
	prepared = true

func wait_for_preparation() -> bool:
	while not prepared and is_inside_tree():
		await get_tree().process_frame
	return prepared and not source.is_empty()

func begin(object_width: float, canvas_basis: Transform2D = Transform2D.IDENTITY) -> void :
	reset()
	width = object_width
	stage_basis = canvas_basis
	playing = true
	show()

func sample(source_clock: float) -> void :
	if not prepared or not playing: return
	if source_clock < SOURCE_START: return
	if not anchored:
		frozen_transform = Transform2D(stage_basis.x, stage_basis.y, global_position)
		anchored = true

	global_transform = frozen_transform
	modulate.a = 1.0 - smoothstep(0.92, 1.35, source_clock)
	var next_frame: = clampi(int(floor((source_clock - SOURCE_START) * 60.0)), 0, 120)
	if next_frame == frame_index: return
	frame_index = next_frame
	live_count = 0
	for i in mesh_layers.size():
		mesh_layers[i].mesh = frame_meshes[i][frame_index]
		mesh_layers[i].scale = Vector2.ONE * UI_PIXELS_PER_NATIVE_UNIT * width / SOURCE_UI_WIDTH * float(LAYER_STYLES[i].distance)
		live_count += int(source.layers[i].frames[frame_index].count)

func reset() -> void :
	playing = false
	anchored = false
	frame_index = -1
	live_count = 0
	modulate = Color.WHITE
	transform = Transform2D.IDENTITY
	for layer in mesh_layers: layer.mesh = null
	hide()
