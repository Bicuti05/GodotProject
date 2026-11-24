class_name SortRevealMemoryConfig
extends AbConfigBase



const VALUE_NO: int = 0
const VALUE_YES: int = 1
const ON_VALUE_STR: String = "yes"


func _init() -> void :
	key = "sort_reveal_memory"
	version = "1.0.4"
	default_value = VALUE_NO
	timing = ABManager.TIMING_REVEAL_MEMORY


func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return VALUE_YES if raw_value == ON_VALUE_STR else VALUE_NO


func is_memory_enabled() -> bool:
	return value() == VALUE_YES


func cheat_label() -> String:
	return "问号撤销记忆 (0=重新隐藏 1=保持揭开)"
