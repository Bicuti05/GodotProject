class_name SortRopeCapacityKnotsConfig
extends AbConfigBase



const VALUE_HIDE: int = 0
const VALUE_SHOW: int = 1
const SHOW_VALUE_STR: String = "yes"

const FEATURE_ENABLED: bool = false


func _init() -> void :
	key = "sort_rope_capacity_knots"
	version = "1.0.4"
	default_value = VALUE_HIDE
	timing = ABManager.TIMING_ENTER_GAME



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return VALUE_SHOW if raw_value == SHOW_VALUE_STR else VALUE_HIDE



func reload_value() -> void :
	if FEATURE_ENABLED:
		super.reload_value()


func is_capacity_knots_enabled() -> bool:
	return FEATURE_ENABLED and value() == VALUE_SHOW


func cheat_label() -> String:
	return "绳下容量文字 (0=隐藏 1=显示)"
