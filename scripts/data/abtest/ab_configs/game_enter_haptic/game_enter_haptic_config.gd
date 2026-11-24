class_name GameEnterHapticConfig
extends AbConfigBase


const VALUE_UNRESOLVED: int = -1
const VALUE_NO: int = 0
const VALUE_YES: int = 1


func _init() -> void :
	key = "game_enter_haptic"
	version = "1.0.10"
	default_value = VALUE_UNRESOLVED
	group_count = 2
	timing = ABManager.TIMING_GAME_ENTER_HAPTIC



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return VALUE_UNRESOLVED
	var raw: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return VALUE_UNRESOLVED
	match raw:
		"no":
			return VALUE_NO
		"yes":
			return VALUE_YES
	return VALUE_UNRESOLVED


func should_play_enter_haptic() -> bool:
	return value() == VALUE_YES


func is_current_control() -> bool:
	return value() == VALUE_NO


func cheat_label() -> String:
	return "进游戏页震动 (0=no 1=yes)"
