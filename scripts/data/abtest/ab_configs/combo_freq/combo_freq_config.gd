class_name ComboFreqConfig
extends AbConfigBase


const VALUE_CONTINUOUS: int = 0
const VALUE_SPACED: int = 1


func _init() -> void :
	key = "combo_freq"
	version = "1.0.10"
	default_value = VALUE_CONTINUOUS
	timing = ABManager.TIMING_COMBO_FREQ



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return VALUE_SPACED if raw_value == "new" else VALUE_CONTINUOUS


func is_new_frequency_enabled() -> bool:
	return value() == VALUE_SPACED


func cheat_label() -> String:
	return "Combo 时机2.0 (0=连续收盆 1=间隔收盆)"
