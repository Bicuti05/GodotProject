class_name SplashConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_NEW: int = 1


func _init() -> void :
	key = "splash"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	group_count = 2
	timing = ABManager.TIMING_SPLASH_ENTER



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw_value: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	return VALUE_NEW if raw_value == "new" else VALUE_ORIGINAL



func is_new_splash_enabled() -> bool:
	return value() == VALUE_NEW


func cheat_label() -> String:
	return "Splash 优化 (0=原版 1=国家名言／素材TODO)"
