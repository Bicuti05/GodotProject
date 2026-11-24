class_name SortDeadReturnToSafeStateConfig
extends AbConfigBase




const VALUE_SINGLE_STEP: int = 0
const VALUE_RETURN_TO_SAFE: int = 1
const ON_VALUE_STR: String = "yes"


func _init() -> void :
	key = "sort_dead_return_to_safe_state"
	version = "1.0.5"
	default_value = VALUE_SINGLE_STEP
	timing = ABManager.TIMING_DEAD_RETURN_TO_SAFE



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return VALUE_RETURN_TO_SAFE if raw_value == ON_VALUE_STR else VALUE_SINGLE_STEP


func is_return_to_safe_enabled() -> bool:
	return value() == VALUE_RETURN_TO_SAFE


func cheat_label() -> String:
	return "死局撤回到安全盘面 (0=单步撤销 1=一次回退多步)"
