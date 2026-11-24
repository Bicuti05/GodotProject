class_name LocationJudgeConfig
extends AbConfigBase

var _settings: Dictionary = {}

func _init() -> void :
	key = "location_judge"
	version = "1.0.7"
	default_value = 0
	timing = ABManager.TIMING_LOCATION_JUDGE

static func parse_settings(raw: String) -> Dictionary:
	var parts: = raw.strip_edges().split("_")
	if parts.size() != 2:
		return {}
	if not parts[0].is_valid_float() or not parts[1].is_valid_float():
		return {}
	var legal: = float(parts[0])
	var invalid: = float(parts[1])
	if not is_finite(legal) or not is_finite(invalid) or legal <= 0.0 or invalid <= 0.0:
		return {}
	return {"legal": legal, "invalid": invalid}

func _fetch_from_sdk() -> int:
	_settings = parse_settings(ABManager.get_ab_string(key, "old"))
	return 0 if _settings.is_empty() else 1

func get_drop_settings() -> Dictionary:
	var enabled: = value() != 0
	if not enabled:
		return {}
	if is_debug_overridden():
		return {"legal": 1.2, "invalid": 0.8}
	return _settings.duplicate()

func cheat_label() -> String:
	return "落位判定 (0=old 1=1.2_0.8)"
