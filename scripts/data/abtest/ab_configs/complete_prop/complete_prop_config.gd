class_name CompletePropConfig
extends AbConfigBase








const VALUE_CONTROL: int = 0
const VALUE_RESET_MOVED: int = 1
const VALUE_RESET_MOVED_WITH_PROP: int = 2
const VALUE_RESET_WHITE_STYLE: int = 3

const CONTROL_VALUE_STR: String = "no_no"
const RESET_MOVED_VALUE_STR: String = "reset_no"
const RESET_MOVED_WITH_PROP_VALUE_STR: String = "reset_yes"
const RESET_WHITE_STYLE_VALUE_STR: String = "reset_replace"



func _init() -> void :
	key = "complete_prop"
	version = "1.0.10"
	default_value = VALUE_CONTROL
	group_count = 4
	timing = ABManager.TIMING_ENTER_GAME



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	if ABManager.get_group_status(key) != "valid":
		return default_value
	match ABManager.get_ab_string(key, ""):
		CONTROL_VALUE_STR:
			return VALUE_CONTROL
		RESET_MOVED_VALUE_STR:
			return VALUE_RESET_MOVED
		RESET_MOVED_WITH_PROP_VALUE_STR:
			return VALUE_RESET_MOVED_WITH_PROP
		RESET_WHITE_STYLE_VALUE_STR:
			return VALUE_RESET_WHITE_STYLE
	return default_value



func is_complete_prop_enabled() -> bool:
	var v: int = value()
	return v == VALUE_RESET_MOVED_WITH_PROP or v == VALUE_RESET_WHITE_STYLE



func is_reset_moved_to_header() -> bool:
	var v: int = value()
	return v == VALUE_RESET_MOVED or v == VALUE_RESET_MOVED_WITH_PROP\
	or v == VALUE_RESET_WHITE_STYLE



func is_reset_white_style() -> bool:
	return value() == VALUE_RESET_WHITE_STYLE



func is_reset_in_prop_bar() -> bool:
	return value() == VALUE_CONTROL


func cheat_label() -> String:
	return "完成一列道具／重开位置 (0=基线 1=重开上移 2=重开上移+道具 3=同组2且重开白底蓝标)"
