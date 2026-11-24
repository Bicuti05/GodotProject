class_name CompleteEncourageTextPicker
extends RefCounted



const BEAT_THRESHOLD: float = 40.0
const POOL_SIZE: int = 10
const METRICS: Array[String] = ["time", "step", "streak"]
const TOP_PERCENT_ENTRIES: Array[int] = [4, 7]
const IQ_ENTRIES: Array[int] = [1, 2, 4, 5]


static func get_percentiles(data: Dictionary) -> Dictionary:
	var target_flowers: int = int(data["target_flower_count"])
	var use_new_data: bool = bool(data.get("use_new_result_data", false))
	return {
		"time": ResultPercentileBank.lookup_percentile("time", target_flowers, float(data["elapsed_ms"]) / 1000.0, use_new_data), 
		"step": ResultPercentileBank.lookup_percentile("step", target_flowers, float(data["move_attempt_count"]), use_new_data), 
		"streak": ResultPercentileBank.lookup_streak_percentile(int(data["win_streak_count"]), use_new_data), 
	}


static func pick(percentiles: Dictionary, iq_replacement_metric: String = "", final_iq: float = 0.0, 
		score_boost_enabled: bool = false) -> Dictionary:
	var candidates: Array[String] = []
	var best_pct: float = BEAT_THRESHOLD
	for metric: String in METRICS:
		var pct: float = float(percentiles.get(metric, -1.0))
		if pct > best_pct:
			best_pct = pct
			candidates = [metric]
		elif pct >= BEAT_THRESHOLD and pct == best_pct:
			candidates.append(metric)
	var metric: String = "normal" if candidates.is_empty() else candidates[randi_range(0, candidates.size() - 1)]

	if metric == iq_replacement_metric and metric in ["step", "streak"]:
		if not iq_badge(final_iq, score_boost_enabled).is_empty():
			var iq_entry: int = IQ_ENTRIES[randi_range(0, IQ_ENTRIES.size() - 1)]
			return {"key": "FINISH_ENCOURAGEMENT_IQ_%d" % iq_entry, "metric": "iq", "iq": roundi(final_iq)}
		metric = "normal"
	var entry: int = randi_range(1, POOL_SIZE)
	var pct: int = 0 if metric == "normal" else int(best_pct)
	if metric in ["time", "step"] and entry in TOP_PERCENT_ENTRIES:
		pct = 100 - pct
	return {"key": "FINISH_ENCOURAGEMENT_%s_%d" % [metric.to_upper(), entry], "metric": metric, "pct": pct}



static func badge(pct: float, improved: bool) -> String:
	if improved:
		return "rise"
	if pct >= 80.0:
		return "s"
	if pct >= 60.0:
		return "a"
	if pct >= 40.0:
		return "b"
	return ""



static func iq_badge(iq: float, score_boost_enabled: bool) -> String:
	var boost: float = 20.0 if score_boost_enabled else 0.0
	if iq > 140.0 + boost:
		return "s"
	if iq > 130.0 + boost:
		return "a"
	if iq > 115.0 + boost:
		return "b"
	return ""
