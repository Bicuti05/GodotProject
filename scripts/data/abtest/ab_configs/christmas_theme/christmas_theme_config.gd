class_name ChristmasThemeConfig
extends AbConfigBase


const VALUE_CURRENT: int = 0
const VALUE_CHRISTMAS: int = 1


func _init() -> void :
	key = "christmas_theme"
	version = "1.0.10"
	default_value = VALUE_CURRENT
	group_count = 2
	timing = ABManager.TIMING_APP_START



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw_value: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	return VALUE_CHRISTMAS if raw_value == "yes" else VALUE_CURRENT


func is_christmas_theme_enabled() -> bool:
	return value() == VALUE_CHRISTMAS


func cheat_label() -> String:
	return "圣诞页面主题 (0=当前表现 1=圣诞主题)"
