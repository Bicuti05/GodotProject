@tool
extends EditorPlugin





const FLY_TRAIL_SCRIPT: Script = preload("res://addons/fly_trail/fly_trail.gd")
const FLY_TRAIL_ICON: Texture2D = preload("res://addons/fly_trail/icon.svg")


func _enter_tree() -> void :
	add_custom_type("FlyTrail", "Node2D", FLY_TRAIL_SCRIPT, FLY_TRAIL_ICON)


func _exit_tree() -> void :
	remove_custom_type("FlyTrail")
