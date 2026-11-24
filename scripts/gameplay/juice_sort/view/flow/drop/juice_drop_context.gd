class_name JuiceDropContext
extends RefCounted


enum Outcome{CANCEL, BLOCKED, REJECTED, VALID}

var board = null
var src: int = -1
var j: int = -1
var target: int = -1
var outcome: int = Outcome.CANCEL
var reason: int = 0
var drag_finished: bool = false
var classified: bool = false
var handled: bool = false
var move_applied: bool = false
var root_swapped: bool = false

var long_link_geometry: Dictionary = {}
var long_link_finished: bool = false

func _init(p_board, p_src: int, p_j: int, p_target: int) -> void :
	board = p_board
	src = p_src
	j = p_j
	target = p_target
