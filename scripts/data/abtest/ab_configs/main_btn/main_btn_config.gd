class_name MainBtnConfig
extends AbConfigBase



const VALUE_OLD_EFFECT: int = 0
const VALUE_NEW_EFFECT: int = 1


func _init() -> void :
	key = "main_btn"
	version = "1.0.7"
	default_value = VALUE_OLD_EFFECT
	timing = ABManager.TIMING_ENTER_HOME


func _fetch_from_sdk() -> int:
	return VALUE_NEW_EFFECT if ABManager.get_ab_string(key, "") == "new" else VALUE_OLD_EFFECT


func is_new_effect_enabled() -> bool:
	return value() == VALUE_NEW_EFFECT


func cheat_label() -> String:
	return "首页按钮动效 (0=原版 1=扫光与星光)"
