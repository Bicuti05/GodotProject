class_name GameMoveContext
extends RefCounted


var page = null
var steps: int = 0

var automatic_only: bool = false
var auto_unlock_applied: bool = false

var sync_settlement_done: bool = false

func _init(p_page, p_steps: int, p_automatic_only: bool = false) -> void :
	page = p_page
	steps = p_steps
	automatic_only = p_automatic_only
