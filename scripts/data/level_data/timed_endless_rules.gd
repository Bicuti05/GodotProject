class_name TimedEndlessRules
extends RefCounted

const FIRST_ANCHOR: int = 30
const INTERVAL: int = 10
const ENCOURAGEMENT_KEYS: Array[String] = [
	"TIMED_CHALLENGE_ENCOURAGEMENT_1", "TIMED_CHALLENGE_ENCOURAGEMENT_2", 
	"GAME_STREAK_BLOOMING", "TIMED_CHALLENGE_ENCOURAGEMENT_4", 
	"TIMED_CHALLENGE_ENCOURAGEMENT_5", "TIMED_CHALLENGE_ENCOURAGEMENT_6", 
	"TIMED_CHALLENGE_ENCOURAGEMENT_7", "TIMED_CHALLENGE_ENCOURAGEMENT_8", 
	"TIMED_CHALLENGE_ENCOURAGEMENT_9", "TIMED_CHALLENGE_ENCOURAGEMENT_10", 
]


static func is_anchor(level: int) -> bool:
	return level >= FIRST_ANCHOR and (level - FIRST_ANCHOR) % INTERVAL == 0


static func supports_version(version: String) -> bool:
	var parts: PackedStringArray = version.split(".")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	return int(parts[0]) > 1 or (int(parts[0]) == 1 and (int(parts[1]) > 0\
	or (int(parts[1]) == 0 and int(parts[2]) >= 10)))


static func result(cups: int, rng: RandomNumberGenerator) -> Dictionary:
	var count: int = maxi(0, cups)
	var percentile: float = 0.0
	if count > 20:
		percentile = rng.randf_range(95.0, 100.0)
	elif count > 10:
		percentile = float(count) * rng.randf_range(4.4, 4.7)
	return {"cups": count, "percentile": snappedf(percentile, 0.1), 
		"encouragement_key": ENCOURAGEMENT_KEYS[rng.randi_range(0, ENCOURAGEMENT_KEYS.size() - 1)]}
