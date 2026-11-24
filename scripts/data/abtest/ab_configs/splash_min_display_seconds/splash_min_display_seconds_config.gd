class_name SplashMinDisplaySecondsConfig
extends AbConfigBase


const FALLBACK_DISPLAY_MSEC: int = 2000

const VALUE_DEFAULT: int = 0
const VALUE_MIN_3_4_SECONDS: int = 1
const VALUE_MIN_3_8_SECONDS: int = 2
const VALUE_MIN_4_2_SECONDS: int = 3


func _init() -> void :
	key = "splash_min_display_seconds"
	version = "1.0.10"
	default_value = FALLBACK_DISPLAY_MSEC
	group_count = 4
	timing = ABManager.TIMING_ENTER_SPLASH




func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw_value: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	return _parse_display_msec(raw_value)



static func _parse_display_msec(raw_value: String) -> int:
	if not raw_value.is_valid_float():
		return FALLBACK_DISPLAY_MSEC
	var seconds: float = raw_value.to_float()
	var msec: float = seconds * 1000.0

	if not is_finite(msec) or msec <= 0.0 or msec >= 9.223372e+18:
		return FALLBACK_DISPLAY_MSEC
	return ceili(msec)


func is_extended_display_enabled() -> bool:
	return get_min_display_msec() > FALLBACK_DISPLAY_MSEC



func get_min_display_msec() -> int:
	var override_value: int = get_debug_override()
	if override_value >= 0:
		match override_value:
			VALUE_MIN_3_4_SECONDS:
				return 3400
			VALUE_MIN_3_8_SECONDS:
				return 3800
			VALUE_MIN_4_2_SECONDS:
				return 4200
		return FALLBACK_DISPLAY_MSEC
	return value()


func cheat_label() -> String:
	return "Splash 最短展示 (0=2秒 1=3.4秒 2=3.8秒 3=4.2秒，重启生效)"
