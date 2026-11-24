class_name GrtEvaluator
extends RefCounted


















static func evaluate(definitions: Array, snapshot: Dictionary, sent: Dictionary) -> Array[String]:
	var hits: Array[String] = []
	var living_days: int = int(snapshot.get("living_days", -1))
	var hours_since_first_open: float = float(snapshot.get("hours_since_first_open", -1.0))
	var completed: int = int(snapshot.get("completed_level_count", 0))
	var round_level: int = int(snapshot.get("round_level", 0))
	var inter_shows: int = int(snapshot.get("inter_shows", 0))
	var reward_shows: int = int(snapshot.get("reward_shows", 0))
	var ltv: float = float(snapshot.get("ltv", 0.0))
	var ltv_available: bool = bool(snapshot.get("ltv_available", false))
	var new_install_batches: Dictionary = snapshot.get("new_install_batches", {})

	for raw_def in definitions:
		var def: Dictionary = raw_def
		var batch_id: String = String(def.get(GrtEventDefinition.KEY_BATCH_ID, ""))
		if not bool(new_install_batches.get(batch_id, false)):
			continue
		var event_name: String = String(def.get(GrtEventDefinition.KEY_NAME, ""))
		if sent.has(batch_id + ":" + event_name):
			continue
		if not _window_ok(def, living_days, hours_since_first_open):
			continue
		if not _metric_ok(def, completed, round_level, inter_shows, reward_shows, ltv, ltv_available):
			continue
		hits.append(event_name)
	return hits



static func _window_ok(def: Dictionary, living_days: int, hours_since_first_open: float) -> bool:
	var window: String = String(def.get(GrtEventDefinition.KEY_WINDOW, ""))
	if window == GrtEventDefinition.WINDOW_LIVING_DAYS:
		if living_days < 0:
			return false
		return living_days <= int(def.get(GrtEventDefinition.KEY_MAX_LIVING_DAYS, 0))
	if window == GrtEventDefinition.WINDOW_HOURS_24:
		if hours_since_first_open < 0.0:
			return false
		return hours_since_first_open <= 24.0
	return false



static func _metric_ok(def: Dictionary, completed: int, round_level: int, inter_shows: int, reward_shows: int, 
		ltv: float, ltv_available: bool) -> bool:
	var metric: String = String(def.get(GrtEventDefinition.KEY_METRIC, ""))
	match metric:
		GrtEventDefinition.METRIC_INTER:
			return inter_shows >= int(def.get(GrtEventDefinition.KEY_THRESHOLD, 0))
		GrtEventDefinition.METRIC_REWARD:
			return reward_shows >= int(def.get(GrtEventDefinition.KEY_THRESHOLD, 0))
		GrtEventDefinition.METRIC_REWARD_OR_INTER:
			return inter_shows + reward_shows >= int(def.get(GrtEventDefinition.KEY_THRESHOLD, 0))
		GrtEventDefinition.METRIC_LEVELPASS:
			return completed >= int(def.get(GrtEventDefinition.KEY_THRESHOLD, 0))
		GrtEventDefinition.METRIC_LTV_LEVELPASS:
			if not ltv_available:
				return false
			var ltv_threshold: float = float(def.get(GrtEventDefinition.KEY_LTV_THRESHOLD, 0.0))
			var level_threshold: int = int(def.get(GrtEventDefinition.KEY_LEVEL_THRESHOLD, 0))
			return ltv + 1e-09 >= ltv_threshold and completed >= level_threshold
		GrtEventDefinition.METRIC_LEVELPASS_REWARD:
			var need_level: int = int(def.get(GrtEventDefinition.KEY_LEVEL_THRESHOLD, 0))
			var need_reward: int = int(def.get(GrtEventDefinition.KEY_REWARD_THRESHOLD, 0))
			return round_level >= 1 and round_level <= need_level and reward_shows >= need_reward
	return false
