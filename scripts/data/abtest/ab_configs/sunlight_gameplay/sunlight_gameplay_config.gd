extends AbConfigBase
class_name SunlightGameplayConfig

func _init() -> void :
	key = "sunlight_gameplay"
	version = "1.0.9"
	default_value = 0
	timing = ABManager.TIMING_SUNLIGHT_GAMEPLAY


func _fetch_from_sdk() -> int:
	return parse_value(ABManager.get_ab_string(key, "no"))


static func parse_value(raw: String) -> int:
	return 1 if raw == "yes" else 0


func is_sunlight_gameplay_enabled() -> bool:
	return value() == 1


func cheat_label() -> String:
	return "阳光解冻花盆 (0=no 1=yes)"
