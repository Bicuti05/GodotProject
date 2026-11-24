class_name HexRevealEffect
extends Node2D


const COVER_HIDE_SEC: float = 0.3
const DURATION_SEC: float = 1.0

@onready var _shapes: Node2D = $Shapes
@onready var _animation: AnimationPlayer = $AnimationPlayer
@onready var _particles: Node2D = $Particles


func play_cell(idx: int, cell: Sprite2D) -> void :
	stop()
	position = cell.get_parent().position + cell.position
	_shapes.rotation = cell.rotation
	_shapes.scale = Vector2(-1.0 if cell.flip_h else 1.0, 1.0)
	var shape: StringName = &"Circle"
	if idx in [7, 8, 9, 14, 15, 16]:
		shape = &"Trapezoid"
	elif idx in [2, 6, 10, 13, 17, 21]:
		shape = &"Triangle"
	elif idx in [0, 1, 3, 4, 5, 11, 12, 18, 19, 20, 22, 23]:
		shape = &"TriangleOut"
	for child in _shapes.get_children():
		child.visible = child.name == shape
	visible = true
	_animation.play(&"reveal")
	_animation.advance(0.0)
	for child in _particles.get_children():
		child.start(_shapes.transform)


func stop() -> void :
	if not is_node_ready():
		return
	_animation.stop()
	for child in _particles.get_children():
		child.stop()
	visible = false


func _exit_tree() -> void :
	stop()
