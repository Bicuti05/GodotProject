extends AbConfigBase
class_name RevivePromptStyleConfig





const VALUE_DEFAULT: int = 0
const VALUE_REDESIGNED: int = 1

const DEFAULT_VALUE_STR: String = "default"
const REDESIGNED_VALUE_STR: String = "redesigned"


func _init() -> void :
	key = "revive_prompt_style"
	version = "1.0.10"
	default_value = VALUE_DEFAULT
	timing = ABManager.TIMING_DEAD_REVIVE_PROMPT



func _fetch_from_sdk() -> int:
	var s: String = ABManager.get_ab_string(key, DEFAULT_VALUE_STR)
	return VALUE_REDESIGNED if s == REDESIGNED_VALUE_STR else VALUE_DEFAULT



func is_revive_prompt_redesigned() -> bool:
	return value() == VALUE_REDESIGNED


func cheat_label() -> String:
	return "死局复活提示样式 (0=default 1=redesigned)"
