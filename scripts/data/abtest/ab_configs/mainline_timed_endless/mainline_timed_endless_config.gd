class_name MainlineTimedEndlessConfig
extends AbConfigBase

const VALUE_KEEP_MAINLINE: int = 0
const VALUE_TIMED_CHALLENGE: int = 1

var _raw_sdk_value: String = ""
var _source_valid: bool = false


func _init() -> void :
	key = "mainline_timed_endless"
	version = "1.0.10"
	default_value = VALUE_KEEP_MAINLINE
	group_count = 2
	timing = ABManager.TIMING_MAINLINE_TIMED_ENDLESS


func _read_sdk() -> Dictionary:
	var raw: String = ABManager.get_ab_string(key, "")
	var valid: bool = ABManager.is_ab_init_done() and raw in ["no", "yes"]\
	and ABManager.get_group_status(key) == "valid"
	return {"raw": raw, "valid": valid, "group": VALUE_TIMED_CHALLENGE if valid and raw == "yes" else VALUE_KEEP_MAINLINE}


func _fetch_from_sdk() -> int:
	var sample: Dictionary = _read_sdk()
	_raw_sdk_value = String(sample["raw"])
	_source_valid = bool(sample["valid"])
	return int(sample["group"])


func is_mainline_timed_endless_enabled() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_TIMED_CHALLENGE
	value()
	return _source_valid and _raw_sdk_value == "yes"


func is_control_group() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_KEEP_MAINLINE
	value()
	return _source_valid and _raw_sdk_value == "no"


func peek_value() -> int:
	var override: int = get_debug_override()
	return override if override >= 0 else int(_read_sdk()["group"])


func cheat_label() -> String:
	return "主线限时无尽 (0=保持现状 1=30关起每10关插入)"
