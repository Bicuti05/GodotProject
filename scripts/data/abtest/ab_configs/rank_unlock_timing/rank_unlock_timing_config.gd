class_name RankUnlockTimingConfig
extends AbConfigBase


const VALUE_OLD: int = 0
const VALUE_LEVEL_15: int = 1
const VALUE_LEVEL_10: int = 2
var _cached_sdk_hit: bool = false
var _reading_preview: bool = false


func _init() -> void :
	key = "rank_unlock_timing"
	version = "1.0.10"
	default_value = VALUE_OLD
	group_count = 3
	timing = ABManager.TIMING_ENTER_HOME



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	var hit: bool = ABManager.is_ab_init_done() and not ABManager._startup_control_locked\
	and ABManager.get_group_status(key) == "valid" and raw_value in ["old", "level_15", "level_10"]
	if not _reading_preview:
		_cached_sdk_hit = hit
	if hit:
		match raw_value:
			"level_15": return VALUE_LEVEL_15
			"level_10": return VALUE_LEVEL_10
	return VALUE_OLD


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


func is_level_15_unlock_enabled() -> bool:
	return _matches_group(VALUE_LEVEL_15)


func is_level_10_unlock_enabled() -> bool:
	return _matches_group(VALUE_LEVEL_10)


func is_control_group() -> bool:
	return _matches_group(VALUE_OLD)


func _matches_group(group: int) -> bool:
	var current: int = value()
	var override: int = get_debug_override()
	if override >= 0:
		return override == group
	return not ABManager._startup_control_locked and _cached_sdk_hit and current == group


func cheat_label() -> String:
	return "排行榜解锁时机 (0=20关 1=15关 2=10关，通关后解锁)"
