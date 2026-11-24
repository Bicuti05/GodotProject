class_name GameStartContext
extends RefCounted







var page = null

var params: Dictionary = {}



var level_model: LevelModel = null

var current_state: Dictionary = {}



var aborted: bool = false

var loading: bool = false

var skip_prop_unlock: bool = false
var skip_opening_banner: bool = false
var skip_mystery_guide: bool = false
var skip_lock_guide: bool = false
var skip_sunlight_guide: bool = false
var skip_playfield_enter: bool = false

func _init(p_page, p_params: Dictionary = {}) -> void :
	page = p_page
	params = p_params
	skip_prop_unlock = p_params.get("skip_prop_unlock", false) == true
	skip_opening_banner = p_params.get("skip_opening_banner", false) == true
	skip_playfield_enter = p_params.get("skip_playfield_enter", false) == true
	skip_mystery_guide = p_params.get("skip_mystery_guide", false) == true
	skip_lock_guide = p_params.get("skip_lock_guide", false) == true
	skip_sunlight_guide = p_params.get("skip_sunlight_guide", false) == true
