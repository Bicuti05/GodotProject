class_name ErrorAnimationConfig
extends AbConfigBase

const VALUE_OLD: int = 0
const VALUE_NEW: int = 1

func _init() -> void :
	key = "error_animation"
	version = "1.0.7"
	default_value = VALUE_OLD
	timing = ABManager.TIMING_ERROR_ANIMATION

static func parse_group(raw: String) -> int:
	return VALUE_NEW if raw == "new" else VALUE_OLD

func _fetch_from_sdk() -> int:
	return parse_group(ABManager.get_ab_string(key, "old"))

func is_new_error_animation_enabled() -> bool:
	return value() == VALUE_NEW

func cheat_label() -> String:
	return "错误弹回 (0=old 原版 1=new 双花与空位提示)"
