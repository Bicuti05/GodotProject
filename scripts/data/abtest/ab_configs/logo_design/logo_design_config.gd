class_name LogoDesignConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_NEW_LOGO: int = 1


func _init() -> void :
	key = "logo_design"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	timing = ABManager.TIMING_LOGO_DESIGN



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return VALUE_NEW_LOGO if raw_value == "yes" else VALUE_ORIGINAL



func is_new_logo_enabled() -> bool:
	return value() == VALUE_NEW_LOGO


func cheat_label() -> String:
	return "Splash Logo 设计 (0=原版 1=新版资源TODO)"
