extends Node2D

var renderer: Node

func _draw() -> void :
	if is_instance_valid(renderer):
		renderer.draw_fill(get_canvas_item(), Color.WHITE)
