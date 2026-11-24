class_name LongLinkConfig
extends AbConfigBase


const VALUE_NO: int = 0
const VALUE_YES: int = 1


func _init() -> void :
	key = "long_link"
	version = "1.0.8"
	default_value = VALUE_NO
	timing = ABManager.TIMING_LONG_LINK



func _fetch_from_sdk() -> int:
	return VALUE_YES if ABManager.get_ab_string(key, "") == "yes" else VALUE_NO


func is_long_link_enabled() -> bool:
	return value() == VALUE_YES


func cheat_label() -> String:
	return "思考10秒后放置表情 (0=no 关闭 1=yes 开启)"
