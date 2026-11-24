class_name SameColorFlowerMergeSfxConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_SET1: int = 1
const VALUE_SET2: int = 2


func _init() -> void :
	key = "same_color_flower_merge_sfx"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	group_count = 3
	timing = ABManager.TIMING_SAME_COLOR_FLOWER_MERGE_SFX



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	match raw:
		"default":
			return VALUE_ORIGINAL
		"set1":
			return VALUE_SET1
		"set2":
			return VALUE_SET2
	return default_value


func is_merge_sfx_set1_enabled() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_SET1
	return not ABManager._startup_control_locked and value() == VALUE_SET1


func is_merge_sfx_set2_enabled() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_SET2
	return not ABManager._startup_control_locked and value() == VALUE_SET2


func cheat_label() -> String:
	return "同色花合并音效 (0=default 1=set1 2=set2)"
