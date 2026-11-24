class_name BgmTestConfig
extends AbConfigBase


const VALUE_NO: int = 0
const VALUE_BGM1: int = 1
const VALUE_BGM2: int = 2
const VALUE_BGM3: int = 3


func _init() -> void :
	key = "bgm_test"
	version = "1.0.10"
	default_value = VALUE_NO
	group_count = 4
	timing = ABManager.TIMING_BGM_SCENE



func _fetch_from_sdk() -> int:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return default_value
	var raw_value: String = ABManager.get_ab_string(key, "")
	if ABManager.get_group_status(key) != "valid":
		return default_value
	match raw_value:
		"bgm1":
			return VALUE_BGM1
		"bgm2":
			return VALUE_BGM2
		"bgm3":
			return VALUE_BGM3
		"no":
			return VALUE_NO
	return default_value


func is_bgm_enabled() -> bool:
	return value() in [VALUE_BGM1, VALUE_BGM2, VALUE_BGM3]


func get_music_id() -> StringName:
	match value():
		VALUE_BGM1:
			return &"bgm1"
		VALUE_BGM2:
			return &"bgm2"
		VALUE_BGM3:
			return &"bgm3"
	return &""


func cheat_label() -> String:
	return "BGM (0=no 1=bgm1 2=bgm2 3=bgm3，进页生效)"
