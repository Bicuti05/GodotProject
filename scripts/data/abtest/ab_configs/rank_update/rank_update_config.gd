class_name RankUpdateConfig
extends AbConfigBase


const VALUE_OLD: int = 0
const VALUE_NEW_24: int = 1
const VALUE_NEW_48: int = 2
var _cached_sdk_hit: bool = false
var _reading_preview: bool = false


func _init() -> void :
	key = "rank_update"
	version = "1.0.10"
	default_value = VALUE_OLD
	group_count = 3
	timing = ABManager.TIMING_ENTER_RANK



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	var hit: bool = ABManager.is_ab_init_done() and not ABManager._startup_control_locked\
	and ABManager.get_group_status(key) == "valid" and raw_value in ["old", "new_24", "new_48"]
	if not _reading_preview:
		_cached_sdk_hit = hit
	if hit:
		match raw_value:
			"new_24": return VALUE_NEW_24
			"new_48": return VALUE_NEW_48
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


func is_24_hour_activity_enabled() -> bool:
	return _matches_group(VALUE_NEW_24)


func is_48_hour_activity_enabled() -> bool:
	return _matches_group(VALUE_NEW_48)


func is_control_group() -> bool:
	return _matches_group(VALUE_OLD)


func _matches_group(group: int) -> bool:
	var current: int = value()
	var override: int = get_debug_override()
	if override >= 0:
		return override == group
	return not ABManager._startup_control_locked and _cached_sdk_hit and current == group


func cheat_label() -> String:
	return "排行榜算法 (0=旧版 1=24小时 2=48小时，新活动生效)"
