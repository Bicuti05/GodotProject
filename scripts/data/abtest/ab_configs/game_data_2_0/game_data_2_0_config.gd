extends AbConfigBase
class_name GameData2Config


const VALUE_NO: int = 0
const VALUE_YES: int = 1
const ON_VALUE_STR: String = "yes"


func _init() -> void :
	key = "game_data2.0"
	version = "1.0.9"
	default_value = VALUE_NO
	timing = ABManager.TIMING_GAME_DATA


func _fetch_from_sdk() -> int:
	var raw: String = ABManager.get_ab_string(key, "")
	return VALUE_YES if raw == ON_VALUE_STR else VALUE_NO


func is_new_result_data_enabled() -> bool:
	return value() == VALUE_YES


func cheat_label() -> String:
	return "统计与连胜横幅数据 (0=旧表 1=新表)"
