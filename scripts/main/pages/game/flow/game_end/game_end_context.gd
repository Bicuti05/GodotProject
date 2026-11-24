class_name GameEndContext
extends RefCounted
















var page = null



var won_level: int = 0

var next_pressed: bool = false
var interstitial_checked: bool = false

var aborted: bool = false


func _init(p_page, p_won_level: int) -> void :
	page = p_page
	won_level = p_won_level
