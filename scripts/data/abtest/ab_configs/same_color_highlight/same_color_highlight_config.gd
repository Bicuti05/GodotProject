extends AbConfigBase
class_name SameColorHighlightConfig


const VALUE_NO: int = 0
const VALUE_YES: int = 1


func _init() -> void :
	key = "same_color_highlight"
	version = "1.0.9"
	default_value = VALUE_NO
	timing = ABManager.TIMING_SAME_COLOR_HIGHLIGHT


func _fetch_from_sdk() -> int:
	return VALUE_YES if ABManager.get_ab_string(key, "") == "yes" else VALUE_NO


func is_same_color_highlight_enabled() -> bool:
	return value() == VALUE_YES


func cheat_label() -> String:
	return "拖拽同色花呼吸 (0=no 1=yes)"
