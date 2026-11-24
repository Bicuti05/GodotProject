class_name IqDataConfig
extends AbConfigBase


const VALUE_NO: int = 0
const VALUE_REPLACE_MOVES: int = 1
const VALUE_REPLACE_STREAK: int = 2


func _init() -> void :
	key = "IQ_data"
	version = "1.0.10"
	default_value = VALUE_NO
	group_count = 3
	timing = ABManager.TIMING_IQ_DATA


func _fetch_from_sdk() -> int:
	match ABManager.get_ab_string(key, ""):
		"replace_moves":
			return VALUE_REPLACE_MOVES
		"replace_streak":
			return VALUE_REPLACE_STREAK
	return VALUE_NO


func is_iq_data_enabled() -> bool:
	return value() in [VALUE_REPLACE_MOVES, VALUE_REPLACE_STREAK]


func should_replace_steps() -> bool:
	return value() == VALUE_REPLACE_MOVES


func should_replace_streak() -> bool:
	return value() == VALUE_REPLACE_STREAK


func cheat_label() -> String:
	return "完成页IQ输出 (0=原统计 1=替换步数 2=替换连胜)"
