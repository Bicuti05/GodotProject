class_name ComboSfxStyleConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_SET1: int = 1


func _init() -> void :
	key = "combo_sfx_style"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	timing = ABManager.TIMING_COMBO_SFX_STYLE



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw_value: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	return VALUE_SET1 if raw_value == "set1" else VALUE_ORIGINAL


func is_new_combo_sfx_enabled() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_SET1
	return not ABManager._startup_control_locked and value() == VALUE_SET1


func cheat_label() -> String:
	return "Combo 音效 (0=default 1=set1，消除与花盆上飞)"
