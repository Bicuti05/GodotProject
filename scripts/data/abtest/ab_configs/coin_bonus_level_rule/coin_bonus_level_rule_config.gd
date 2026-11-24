class_name CoinBonusLevelRuleConfig
extends AbConfigBase

var _rule: Dictionary = {}
var _raw_sdk_value: String = ""
var _source_valid: bool = false
var _last_invalid: String = ""

func _init() -> void :
	key = "coin_bonus_level_rule"
	version = "1.0.10"
	default_value = 0
	group_count = 3
	timing = ABManager.TIMING_COIN_BONUS_LEVEL

func _read_sdk() -> Dictionary:

	var raw: String = ABManager.get_ab_string(key, "")
	var valid: bool = not raw.is_empty() and ABManager.get_group_status(key) == "valid"
	var parsed: Dictionary = CoinBonusLevelRules.parse_rule(raw) if raw != "default" and valid else {}
	if valid and raw != "default" and parsed.is_empty() and raw != _last_invalid:
		_last_invalid = raw
		SortLogger.warn("双倍金币 AB 配置非法，沿用现有规则：(value=%s)" % raw)
	return {"raw": raw, "valid": valid, "rule": parsed, 
		"group": (1 if parsed.mode == "all" else 2) if not parsed.is_empty() else 0}

func _fetch_from_sdk() -> int:
	var sample: Dictionary = _read_sdk()
	_raw_sdk_value = String(sample.raw)
	_source_valid = bool(sample.valid)
	_rule = sample.rule as Dictionary
	return int(sample.group)

func _ensure_loaded() -> void :
	if not _value_loaded and ABManager.is_ab_init_done():
		load_value_silent()

func reload_value() -> void :
	load_value_silent()
	ABManager.dye_ab(key)

func is_coin_bonus_enabled() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override in [1, 2]
	_ensure_loaded()
	return _source_valid and not _rule.is_empty()

func is_control_group() -> bool:
	var override: int = get_debug_override()
	if override >= 0:
		return override == 0
	_ensure_loaded()
	return _source_valid and _raw_sdk_value == "default"

func get_rule() -> Dictionary:
	var override: int = get_debug_override()
	if override >= 0:
		if override == 1:
			return CoinBonusLevelRules.ALL_PRESET.duplicate()
		if override == 2:
			return CoinBonusLevelRules.HARD_PRESET.duplicate()
		return {}
	_ensure_loaded()
	return _rule.duplicate() if _source_valid else {}


func peek_sdk_value() -> int:
	return int(_read_sdk().group)

func peek_value() -> int:
	var override: int = get_debug_override()
	return override if override >= 0 else peek_sdk_value()

func cheat_label() -> String:
	return "双倍金币关 (0=default 1=all/3/4 2=hard/2/3)"

func cheat_value_str() -> String:
	var rule: Dictionary = get_rule()
	return ("default" if rule.is_empty() else JSON.stringify(rule)) + (" (cheat)" if is_debug_overridden() else "")
