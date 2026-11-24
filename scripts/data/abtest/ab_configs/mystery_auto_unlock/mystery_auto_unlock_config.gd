class_name MysteryAutoUnlockConfig
extends AbConfigBase


const VALUE_MANUAL: int = 0
const VALUE_AUTO_UNLOCK: int = 1


func _init() -> void :
	key = "mystery_auto_unlock"
	version = "1.0.10"
	default_value = VALUE_MANUAL
	timing = ABManager.TIMING_MYSTERY_AUTO_UNLOCK



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return VALUE_MANUAL
	var raw_value: String = ABManager.get_ab_string(key, "")

	return VALUE_AUTO_UNLOCK if raw_value == "yes" and ABManager.get_group_status(key) == "valid" else VALUE_MANUAL


func is_auto_unlock_enabled() -> bool:
	return value() == VALUE_AUTO_UNLOCK


func cheat_label() -> String:
	return "最后一盆问号自动解开 (0=no 保持现状 1=yes 解开全部问号)"
