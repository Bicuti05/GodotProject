class_name DailyFirstRoundDowngradeConfig
extends AbConfigBase





const VALUE_NO: int = 0
const VALUE_ROUNDS_1: int = 1
const VALUE_ROUNDS_2: int = 2
const VALUE_ROUNDS_3: int = 3

const _VALUE_BY_STR: Dictionary = {
	"no": VALUE_NO, 
	"1": VALUE_ROUNDS_1, 
	"2": VALUE_ROUNDS_2, 
	"3": VALUE_ROUNDS_3, 
}


func _init() -> void :
	key = "daily_first_round_downgrade"
	version = "1.0.4"
	default_value = VALUE_NO
	group_count = 4
	timing = ABManager.TIMING_DAILY_FIRST_ROUND



func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "")
	return int(_VALUE_BY_STR.get(raw_value.strip_edges().to_lower(), VALUE_NO))



func downgrade_rounds_per_day() -> int:
	return value()


func cheat_label() -> String:
	return "每日首局降级 (0=对照 1=首关 2=前2关 3=前3关)"
