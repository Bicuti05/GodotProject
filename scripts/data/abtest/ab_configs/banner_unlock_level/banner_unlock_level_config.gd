class_name BannerUnlockLevelConfig
extends AbConfigBase



const FALLBACK_UNLOCK_LEVEL: int = 1000000000
var _sdk_value_valid: bool = false


func _init() -> void :
	key = "banner_unlock_level"
	version = "1.0.10"
	default_value = FALLBACK_UNLOCK_LEVEL
	group_count = 0
	timing = ABManager.TIMING_APP_START


func init_default() -> void :
	super.init_default()
	_sdk_value_valid = false


func _fetch_from_sdk() -> int:
	var raw: int = ABManager.get_ab_int(key, -1)
	_sdk_value_valid = raw >= 0
	return raw if _sdk_value_valid else FALLBACK_UNLOCK_LEVEL


func reload_value() -> void :
	load_value_silent()
	if _sdk_value_valid:
		ABManager.dye_ab(key)


func get_unlock_level() -> int:
	return value()



func get_log_snapshot(_lifecycle_day: int = 0) -> Dictionary:
	var override_value: int = get_debug_override()
	var effective: int = override_value if override_value >= 0 else (_value if _value_loaded else default_value)
	var source: String = "调试强制覆盖" if override_value >= 0 else ("SDK已加载配置" if _sdk_value_valid else "客户端兜底（SDK未提供合法值）")
	if override_value < 0 and not _value_loaded:
		source = "SDK尚未读取，暂用客户端兜底；日志不会主动拉取配置"
	return {"effective": effective, "fallback": default_value, "source": source, "raw": str(effective), 
		"rule": "非负整数", "loaded": _value_loaded or override_value >= 0}



func peek_value() -> int:
	var override_value: int = get_debug_override()
	return override_value if override_value >= 0 else peek_sdk_value()


func peek_sdk_value() -> int:
	var raw: int = ABManager.get_ab_int(key, -1)
	return raw if raw >= 0 else FALLBACK_UNLOCK_LEVEL


func should_allow_banner(level_id: int, unlocked: bool = false) -> bool:
	return unlocked or level_id > get_unlock_level()



func set_debug_override_str(raw: String) -> bool:
	var text: String = raw.strip_edges()
	if not text.is_valid_int() or text.to_int() < 0:
		return false
	set_debug_override(text.to_int())
	return true


func get_debug_input_value_str() -> String:
	return str(get_unlock_level())


func cheat_label() -> String:
	return "Banner 解锁关号 (普通关 LEVEL > n；非负整数 n；客户端兜底 1000000000，已解锁不再受阈值影响)"


func cheat_value_str() -> String:
	var effective: int = get_unlock_level()
	var source: String = "强制" if is_debug_overridden() else ("SDK" if _sdk_value_valid else "客户端兜底")
	return "%d · %s" % [effective, source]
