class_name CompleteSfxStyleConfig
extends AbConfigBase


const VALUE_UNRESOLVED: int = -1
const VALUE_CONTROL: int = 0
const VALUE_SIMPLE: int = 1
const VALUE_RICH: int = 2


func _init() -> void :
	key = "complete_sfx_style"
	version = "1.0.10"
	default_value = VALUE_UNRESOLVED
	group_count = 3
	timing = ABManager.TIMING_COMPLETE_SFX_STYLE



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return VALUE_UNRESOLVED
	var raw: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return VALUE_UNRESOLVED
	match raw:
		"default":
			return VALUE_CONTROL
		"set1":
			return VALUE_SIMPLE
		"set2":
			return VALUE_RICH
	return VALUE_UNRESOLVED


func is_simple_style_enabled() -> bool:
	return value() == VALUE_SIMPLE


func is_rich_style_enabled() -> bool:
	return value() == VALUE_RICH


func is_current_control() -> bool:
	return value() == VALUE_CONTROL


func cheat_label() -> String:
	return "完局音效 (0=default 1=简约乐句 2=丰富乐句，两实验共用新花车音效)"
