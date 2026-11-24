class_name StreakBannerConfig
extends AbConfigBase







const VALUE_ORIGINAL: int = 0
const VALUE_TIERED_BLOCKING: int = 1
const VALUE_TIERED_PASSTHROUGH: int = 2

const ORIGINAL_VALUE_STR: String = "no"
const TIERED_BLOCKING_VALUE_STR: String = "yes1"
const TIERED_PASSTHROUGH_VALUE_STR: String = "yes2"


func _init() -> void :
	key = "streak_banner"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL
	group_count = 3
	timing = ABManager.TIMING_STREAK_BANNER



static func group_for_raw_string(raw_value: String) -> int:
	match raw_value:
		TIERED_BLOCKING_VALUE_STR:
			return VALUE_TIERED_BLOCKING
		TIERED_PASSTHROUGH_VALUE_STR:
			return VALUE_TIERED_PASSTHROUGH
		_:
			return VALUE_ORIGINAL



func _fetch_from_sdk() -> int:
	return group_for_raw_string(ABManager.get_ab_string(key, ORIGINAL_VALUE_STR))



func is_new_banner_enabled() -> bool:
	var group: int = value()
	return group == VALUE_TIERED_BLOCKING or group == VALUE_TIERED_PASSTHROUGH



func is_overlay_enabled() -> bool:
	return value() == VALUE_TIERED_BLOCKING



func is_input_block_enabled() -> bool:
	return value() == VALUE_TIERED_BLOCKING


func cheat_label() -> String:
	return "连胜横幅 (0=原版 1=新版拦截 2=新版不拦截)"
