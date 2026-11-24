extends AbConfigBase
class_name BonusLevel2Config











const VALUE_CONTROL: int = 0
const VALUE_EXPERIMENT: int = 1


const ON_VALUE_STR: String = "yes"

func _init() -> void :
	key = "bonus_level2.0"
	version = "1.0.8"
	default_value = VALUE_CONTROL
	timing = ABManager.TIMING_BONUS_LEVEL


func _fetch_from_sdk() -> int:
	return VALUE_EXPERIMENT if ABManager.get_ab_string(key, "") == ON_VALUE_STR else VALUE_CONTROL


func is_enabled() -> bool:
	return value() == VALUE_EXPERIMENT

func cheat_label() -> String:
	return "Bonus Level 2.0 奖励关 (0=1.0 基线 1=2.0)"
