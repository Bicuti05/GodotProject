class_name ResultPercentileBank
extends RefCounted



const BANK_PATH: String = "res://scripts/main/dialogs/finish/data/result_percentile_bank.json"
const NEW_BANK_PATH: String = "res://scripts/main/dialogs/finish/data/result_percentile_bank_2_0.json"
const METRICS_LOWER_IS_BETTER: Array[String] = ["time", "step"]

static var _banks: Dictionary = {}


static func _ensure_loaded(use_new_data: bool = false) -> Dictionary:
	var path: String = NEW_BANK_PATH if use_new_data else BANK_PATH
	if _banks.has(path):
		return _banks[path]
	_banks[path] = {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		SortLogger.error("ResultPercentileBank: cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		SortLogger.error("ResultPercentileBank: invalid bank %s" % path)
		return {}
	_banks[path] = parsed
	return parsed



static func lookup_percentile(metric: String, target_flower_count: int, value: float, use_new_data: bool = false) -> float:
	var bank: Dictionary = _ensure_loaded(use_new_data)
	var table: Dictionary = bank.get(metric, {})
	var thresholds: Array = table.get(str(target_flower_count), [])
	var lower_is_better: bool = METRICS_LOWER_IS_BETTER.has(metric)
	return _lookup_percentile(thresholds, value, lower_is_better, bank.get("percentiles", []))



static func lookup_streak_percentile(count: int, use_new_data: bool = false) -> float:
	var bank: Dictionary = _ensure_loaded(use_new_data)
	return _lookup_percentile(bank.get("streak", []), float(count), false, bank.get("percentiles", []))



static func has_metric_data(metric: String, target_flower_count: int, use_new_data: bool = false) -> bool:
	var bank: Dictionary = _ensure_loaded(use_new_data)
	if metric == "streak":
		return not (bank.get("streak", []) as Array).is_empty()
	var table: Dictionary = bank.get(metric, {})
	var thresholds: Array = table.get(str(target_flower_count), [])
	return not thresholds.is_empty()


static func _lookup_percentile(thresholds: Array, value: float, lower_is_better: bool, percentiles: Array) -> float:
	for i: int in thresholds.size():

		if thresholds[i] == null:
			continue
		var threshold: float = float(thresholds[i])
		if (value <= threshold if lower_is_better else value >= threshold):
			return float(percentiles[i])
	return -1.0


static func reset_cache() -> void :
	_banks.clear()
