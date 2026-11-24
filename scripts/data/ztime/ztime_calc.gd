class_name ZtimeCalc
extends RefCounted








const HINT_WEIGHT: = 10.0
const UNDO_WEIGHT: = 5.0
const ROPE_WEIGHT: = 20.0
const DEAD_WEIGHT: = 30.0

const MAX_BUCKET: = 5



static func raw_score(play_time_ms: int, hint_used: int, undo_used: int, rope_used: int, 
		dead_times: int, targets: int, capacity: int) -> float:
	if targets <= 0 or capacity <= 0:
		return 0.0
	return raw_score_scaled(play_time_ms, hint_used, undo_used, rope_used, dead_times, 
		targets * capacity)




static func raw_score_scaled(play_time_ms: int, hint_used: int, undo_used: int, rope_used: int, 
		dead_times: int, normalizer: int) -> float:
	if normalizer <= 0:
		return 0.0
	var total: float = float(play_time_ms) / 1000.0\
	+ hint_used * HINT_WEIGHT + undo_used * UNDO_WEIGHT + rope_used * ROPE_WEIGHT\
	+ dead_times * DEAD_WEIGHT
	return total / float(normalizer)



static func bucket(raw: float) -> int:
	return clampi(ceili(raw), 0, MAX_BUCKET)
