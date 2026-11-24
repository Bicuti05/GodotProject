class_name ColdStartOptimizationConfig
extends AbConfigBase

const VALUE_NO: int = 0
const VALUE_YES: int = 1
var _cached_sdk_hit: bool = false
var _cached_raw_value: String = ""
var _reading_preview: bool = false


func _init() -> void :
	key = "cold_start_optimization"
	version = "1.0.10"
	default_value = VALUE_NO
	timing = ABManager.TIMING_APP_START



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	var hit: bool = ABManager.is_ab_init_done() and not ABManager._startup_control_locked\
	and ABManager.get_group_status(key) == "valid" and raw_value in ["no", "yes"]
	if not _reading_preview:
		_cached_raw_value = raw_value
		_cached_sdk_hit = hit
	return VALUE_YES if hit and raw_value == "yes" else VALUE_NO


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


func is_cold_start_optimization_enabled() -> bool:
	var current: int = value()
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_YES
	return not ABManager._startup_control_locked and _cached_sdk_hit and current == VALUE_YES


func is_control_group() -> bool:
	var current: int = value()
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_NO
	return not ABManager._startup_control_locked and _cached_sdk_hit and current == VALUE_NO


func cheat_label() -> String:
	return "冷启动优化 (0=no 1=yes，重启生效)"
