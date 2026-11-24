extends AbConfigBase
class_name SpecialLevel2Config






const VALUE_OLD_BANK: int = 0
const VALUE_NEW_BANK: int = 1
const NEW_BANK_STR: String = "yes"

func _init() -> void :
	key = "special_level2.0"
	version = "1.0.9"
	default_value = VALUE_OLD_BANK
	timing = ABManager.TIMING_SPECIAL_LEVEL



func _fetch_from_sdk() -> int:
	var raw: String = ABManager.get_ab_string(key, "")
	return VALUE_NEW_BANK if raw == NEW_BANK_STR else VALUE_OLD_BANK


func is_special_level_v2_enabled() -> bool:
	return value() == VALUE_NEW_BANK

func cheat_label() -> String:
	return "Special Level 2.0 (0=旧题库 1=新题库)"
