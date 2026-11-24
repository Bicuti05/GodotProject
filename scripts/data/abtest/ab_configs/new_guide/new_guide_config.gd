class_name NewGuideConfig
extends AbConfigBase


const VALUE_NO: int = 0
const VALUE_SHOW_RULES: int = 1
const VALUE_FOUR_GUIDE: int = 2
var _cached_sdk_hit: bool = false
var _reading_preview: bool = false


func _init() -> void :
	key = "new_guide"
	version = "1.0.10"
	default_value = VALUE_NO
	group_count = 3
	timing = ABManager.TIMING_NEW_GUIDE


static func parse_sdk_value(raw_value: String) -> int:
	match raw_value:
		"no": return VALUE_NO
		"show_rules": return VALUE_SHOW_RULES
		"4guide": return VALUE_FOUR_GUIDE
	return -1



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	var parsed: int = parse_sdk_value(raw_value)
	var hit: bool = ABManager.is_ab_init_done() and not ABManager._startup_control_locked\
	and ABManager.get_group_status(key) == "valid" and parsed >= 0
	if not _reading_preview:
		_cached_sdk_hit = hit
	return parsed if hit else VALUE_NO


func peek_value() -> int:
	_reading_preview = true
	var result: int = super.peek_value()
	_reading_preview = false
	return result


func peek_sdk_value() -> int:
	_reading_preview = true
	var result: int = super.peek_sdk_value()
	_reading_preview = false
	return result


func _matches(expected: int) -> bool:
	var current: int = value()
	var override: int = get_debug_override()
	if override >= 0:
		return override == expected
	return not ABManager._startup_control_locked and _cached_sdk_hit and current == expected


func is_four_goal_tutorial_enabled() -> bool:
	return _matches(VALUE_FOUR_GUIDE)


func is_rules_group() -> bool:
	return _matches(VALUE_SHOW_RULES)


func is_control_group() -> bool:
	return _matches(VALUE_NO)


func cheat_label() -> String:
	return "新手教学 (0=原版 1=常驻规则栏 2=四目标教学)"
