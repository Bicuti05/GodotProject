extends RefCounted
class_name AbConfigBase
















var key: String = ""
var default_value: int = 0
var timing: String = ""



var version: String = ""


var group_count: int = 2



var _value: int = 0
var _value_loaded: bool = false







func init_default() -> void :
	_value = default_value






func value() -> int:
	var ov: int = UserState.get_debug_ab_override(key)
	if ov >= 0:
		return ov
	if not _value_loaded:
		if not ABManager._is_init_done:
			return default_value
		_value = _fetch_from_sdk()
		_value_loaded = true
	return _value



func peek_value() -> int:
	var ov: int = UserState.get_debug_ab_override(key)
	if ov >= 0:
		return ov
	return _fetch_from_sdk()



func is_sdk_hit() -> bool:
	return ABManager.get_group_status(key) == "valid"



func peek_sdk_value() -> int:
	return _fetch_from_sdk()



func reload_value() -> void :
	_value = _fetch_from_sdk()
	_value_loaded = true
	ABManager.dye_ab(key)




func load_value_silent() -> void :
	_value = _fetch_from_sdk()
	_value_loaded = true





func _fetch_from_sdk() -> int:
	return ABManager.get_ab_int(key, default_value)





static func parse_dye_start_level(dye_time: String) -> int:
	var parts: PackedStringArray = dye_time.strip_edges().split("_", false)
	if parts.size() >= 2 and parts[0] == "play" and parts[1].is_valid_int():
		var lv: int = int(parts[1])
		return lv if lv > 0 else 0
	return 0





func set_debug_override(v: int) -> void :
	UserState.set_debug_ab_override(key, v)

func clear_debug_override() -> void :
	UserState.clear_debug_ab_override(key)


func is_debug_overridden() -> bool:
	return UserState.get_debug_ab_override(key) >= 0


func get_debug_override() -> int:
	return UserState.get_debug_ab_override(key)





func cheat_label() -> String:
	return key



func cheat_value_str() -> String:
	return str(value())
