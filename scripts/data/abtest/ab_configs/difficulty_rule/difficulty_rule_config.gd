class_name DifficultyRuleConfig
extends AbConfigBase


const VALUE_ORIGINAL: int = 0
const VALUE_FOUR_LOSSES: int = 1
const VALUE_EASY_PROMOTION: int = 2


func _init() -> void :
	key = "difficulty_rule"
	version = "1.0.9"
	default_value = VALUE_ORIGINAL
	group_count = 3
	timing = ABManager.TIMING_DIFFICULTY_RULE



func _fetch_from_sdk() -> int:
	match ABManager.get_ab_string(key, ""):
		"lv4_lv5_4_losses":
			return VALUE_FOUR_LOSSES
		"easy_promotion":
			return VALUE_EASY_PROMOTION
	return VALUE_ORIGINAL


func should_require_four_losses(level: int) -> bool:
	return level in [4, 5] and value() == VALUE_FOUR_LOSSES


func should_use_easy_promotion() -> bool:
	return value() == VALUE_EASY_PROMOTION


func cheat_label() -> String:
	return "难度升降档 (0=原规则 1=高档4败降级 2=累计胜场晋级)"
