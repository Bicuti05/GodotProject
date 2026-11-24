class_name ComboFullscreenFxConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_FULLSCREEN_FX: int = 1


func _init() -> void :
	key = "combo_fullscreen_fx"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	timing = ABManager.TIMING_COMBO_HAPTIC



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return VALUE_FULLSCREEN_FX if raw_value == "yes" else VALUE_ORIGINAL


func is_fullscreen_fx_enabled() -> bool:
	return value() == VALUE_FULLSCREEN_FX


func cheat_label() -> String:
	return "Combo 全屏动效 (0=原版 1=三阶段彩带边缘反馈)"
