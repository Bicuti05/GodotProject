class_name ShakeV2Config
extends AbConfigBase


const VALUE_UNRESOLVED: int = -1
const VALUE_CONTROL: int = 0
const VALUE_FIRST_STYLE: int = 1
const VALUE_SECOND_STYLE: int = 2


func _init() -> void :
	key = "shake_v2"
	version = "1.0.10"
	default_value = VALUE_UNRESOLVED
	group_count = 3
	timing = ABManager.TIMING_SHAKE_V2



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return VALUE_UNRESOLVED
	var raw: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return VALUE_UNRESOLVED
	match raw:
		"default":
			return VALUE_CONTROL
		"style1_v2":
			return VALUE_FIRST_STYLE
		"style2_v2":
			return VALUE_SECOND_STYLE
	return VALUE_UNRESOLVED


func is_first_style_enabled() -> bool:
	return value() == VALUE_FIRST_STYLE


func is_second_style_enabled() -> bool:
	return value() == VALUE_SECOND_STYLE


func is_current_control() -> bool:
	return value() == VALUE_CONTROL



func get_style() -> int:
	if is_first_style_enabled():
		return 1
	if is_second_style_enabled():
		return 2
	return 0


func cheat_label() -> String:
	return "震动迭代 (0=对照 1=样式1 2=样式2)"
