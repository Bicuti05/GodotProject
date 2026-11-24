class_name FlowStep
extends RefCounted









signal completed

var _is_done: bool = false


func should_run(_ctx) -> bool:
	return true


func run(_ctx) -> void :
	pass


func get_step_name() -> String:
	return "FlowStep"




func is_blocking() -> bool:
	return true


func is_barrier() -> bool:
	return false


func mark_done() -> void :
	_is_done = true
	completed.emit()

func is_done() -> bool:
	return _is_done
