class_name HardLevelBannerStyleConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_NEW: int = 1
const VALUE_FLOWER_CHARACTER: int = 2


func _init() -> void :
	key = "hard_level_banner_style"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	group_count = 3
	timing = ABManager.TIMING_HARD_LEVEL_BANNER_STYLE




func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw_value: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	match raw_value:
		"new":
			return VALUE_NEW
		"flower_character":
			return VALUE_FLOWER_CHARACTER
		"original":
			return VALUE_ORIGINAL
	return default_value


func is_new_style_enabled() -> bool:
	return value() == VALUE_NEW


func is_flower_character_enabled() -> bool:
	return value() == VALUE_FLOWER_CHARACTER


func cheat_label() -> String:
	return "困难关横幅样式 (0=原版 1=新版动画 2=花朵横幅)"
