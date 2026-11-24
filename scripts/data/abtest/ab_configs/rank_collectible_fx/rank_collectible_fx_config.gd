class_name RankCollectibleFxConfig
extends AbConfigBase

const VALUE_ORIGINAL: int = 0
const VALUE_REPLACEMENT: int = 1
const VALUE_COLUMN_COUNT: int = 2
var _cached_sdk_hit: bool = false
var _reading_preview: bool = false

func _init() -> void :
	key = "rank_collectible_fx"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	group_count = 3
	timing = ABManager.TIMING_RANK_COLLECTIBLE_ACTIVITY

func _fetch_from_sdk() -> int:

	var raw: String = ABManager.get_ab_string(key, "")
	var hit: bool = ABManager.is_ab_init_done() and not ABManager._startup_control_locked\
	and ABManager.get_group_status(key) == "valid" and raw in ["no", "yes", "column_count"]
	if not _reading_preview:
		_cached_sdk_hit = hit
	if hit and raw == "column_count":
		return VALUE_COLUMN_COUNT
	return VALUE_REPLACEMENT if hit and raw == "yes" else VALUE_ORIGINAL

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

func is_collectible_replacement_enabled() -> bool:
	return _matches_group(VALUE_REPLACEMENT) or is_column_count_enabled()

func is_column_count_enabled() -> bool:
	return _matches_group(VALUE_COLUMN_COUNT)

func is_original_collectible_enabled() -> bool:
	return _matches_group(VALUE_ORIGINAL)

func _matches_group(group: int) -> bool:
	var current: int = value()
	var override: int = get_debug_override()
	if override >= 0:
		return override == group
	return not ABManager._startup_control_locked and _cached_sdk_hit and current == group

func cheat_label() -> String:
	return "排行榜收集物 (0=原花朵 1=礼盒按目标数 2=礼盒按列长，新活动生效)"
