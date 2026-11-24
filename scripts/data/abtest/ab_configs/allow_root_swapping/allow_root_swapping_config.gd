class_name AllowRootSwappingConfig
extends AbConfigBase

const VALUE_ORIGINAL_RULES: int = 0
const VALUE_FROM_LEVEL_ONE: int = 1
const VALUE_PLAY_AFTER_DEAD: int = 2


var _sdk_raw_value: String = ""
var _sdk_source_valid: bool = false


func _init() -> void :
	key = "allow_root_swapping"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL_RULES
	group_count = 3
	timing = ABManager.TIMING_ENTER_GAME


static func group_for_raw_string(raw: String) -> int:
	match raw:
		"default":
			return VALUE_ORIGINAL_RULES
		"level_1":
			return VALUE_FROM_LEVEL_ONE
		"level_4":
			return VALUE_PLAY_AFTER_DEAD
	return VALUE_ORIGINAL_RULES




func _read_sdk_sample() -> Dictionary:
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return {"raw": "", "valid": false, "value": default_value}
	var raw: String = ABManager.get_ab_string(key, "")
	var valid: bool = ABManager.get_group_status(key) == "valid"\
	and raw in ["default", "level_1", "level_4"]
	return {"raw": raw, "valid": valid, 
		"value": group_for_raw_string(raw) if valid else default_value}



func _fetch_from_sdk() -> int:
	var sample: Dictionary = _read_sdk_sample()
	_sdk_raw_value = sample.raw
	_sdk_source_valid = sample.valid
	return int(sample.value)


func init_default() -> void :
	super.init_default()
	_sdk_raw_value = ""
	_sdk_source_valid = false



func get_debug_override() -> int:
	return -1 if OS.has_feature("rel") else UserState.get_debug_ab_override(key)


func is_debug_overridden() -> bool:
	return get_debug_override() >= 0


func value() -> int:
	var override: int = get_debug_override()
	if override >= 0:
		return override if override < group_count else default_value
	if ABManager._startup_control_locked:
		return default_value
	if not _value_loaded:
		load_value_silent()
	return _value


func peek_sdk_value() -> int:
	return int(_read_sdk_sample().value)


func peek_value() -> int:
	var override: int = get_debug_override()
	if override >= 0:
		return override if override < group_count else default_value
	return peek_sdk_value()


func is_sdk_hit() -> bool:
	return bool(_read_sdk_sample().valid)


func load_value_silent() -> void :
	if ABManager._startup_control_locked:
		init_default()
		_value_loaded = true
		return
	if not ABManager.is_ab_init_done():
		return
	_value = _fetch_from_sdk()
	_value_loaded = true




func reload_value() -> void :
	load_value_silent()
	if ABManager._startup_control_locked or not ABManager.is_ab_init_done():
		return
	if _sdk_source_valid and not ABManager.is_dyeing(key):
		ABManager.dye_ab(key)


func is_control_group() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == VALUE_ORIGINAL_RULES
	value()
	return not ABManager._startup_control_locked and _sdk_source_valid\
	and _sdk_raw_value == "default"


static func allows_level(group: int, level: int) -> bool:
	return group in [VALUE_FROM_LEVEL_ONE, VALUE_PLAY_AFTER_DEAD] and level >= 1


func should_allow_root_swapping(level: int) -> bool:
	return allows_level(value(), level)



func should_allow_playing_after_dead(level: int) -> bool:
	return value() == VALUE_PLAY_AFTER_DEAD and level >= 1


func cheat_label() -> String:
	return "根部花串互换 (0=原规则 1=第1关起 2=第1关起且死后可操作)"
