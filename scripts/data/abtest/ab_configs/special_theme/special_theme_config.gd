class_name SpecialThemeConfig
extends AbConfigBase


const VALUE_DEFAULT: int = 0
const VALUE_SPECIAL: int = 1
const VALUE_SPECIAL_AND_ENDING_TWO: int = 2

func _init() -> void :
	key = "special_theme"
	version = "1.0.10"
	default_value = VALUE_DEFAULT
	group_count = 3
	timing = ABManager.TIMING_SPECIAL_THEME

func _fetch_from_sdk() -> int:
	match ABManager.get_ab_string(key, ""):
		"yes_special": return VALUE_SPECIAL
		"yes_special_2": return VALUE_SPECIAL_AND_ENDING_TWO
	return VALUE_DEFAULT


func should_dye_on_level_enter(level: int, is_special: bool) -> bool:
	return is_special or (level >= 12 and level % 10 == 2)

func should_use_theme(level: int, is_special: bool) -> bool:
	match value():
		VALUE_SPECIAL: return is_special
		VALUE_SPECIAL_AND_ENDING_TWO: return should_dye_on_level_enter(level, is_special)
	return false

func cheat_label() -> String:
	return "盘面主题 (0=默认 1=Special 2=Special＋12/22/32…)"
