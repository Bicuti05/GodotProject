class_name RankEncourageRule
extends RefCounted


const ARG_NONE: int = 0
const ARG_RANK_DIFF: int = 1
const ARG_NEW_RANK: int = 2

const HIGHEST_TIER: int = 7

const RANK_MIN: int = 1
const RANK_MAX: int = 50

const ANY: int = -1

const _FINISH_RISE_KEYS: Array[String] = [
	"RANK_FINISH_RISE_01", "RANK_FINISH_RISE_02", "RANK_FINISH_RISE_03", "RANK_FINISH_RISE_04", "RANK_FINISH_RISE_05", 
	"RANK_FINISH_RISE_06", "RANK_FINISH_RISE_07", "RANK_FINISH_RISE_08", "RANK_FINISH_RISE_09", "RANK_FINISH_RISE_10", 
]
const _FINISH_FIRST_KEYS: Array[String] = [
	"RANK_FINISH_FIRST_01", "RANK_FINISH_FIRST_02", "RANK_FINISH_FIRST_03", "RANK_FINISH_FIRST_04", "RANK_FINISH_FIRST_05", 
	"RANK_FINISH_FIRST_06", "RANK_FINISH_FIRST_07", "RANK_FINISH_FIRST_08", "RANK_FINISH_FIRST_09", "RANK_FINISH_FIRST_10", 
]
const _FINISH_SECOND_KEYS: Array[String] = [
	"RANK_FINISH_SECOND_01", "RANK_FINISH_SECOND_02", "RANK_FINISH_SECOND_03", "RANK_FINISH_SECOND_04", "RANK_FINISH_SECOND_05", 
]
const _FINISH_THIRD_KEYS: Array[String] = [
	"RANK_FINISH_THIRD_01", "RANK_FINISH_THIRD_02", "RANK_FINISH_THIRD_03", "RANK_FINISH_THIRD_04", "RANK_FINISH_THIRD_05", 
]
const _FINISH_UPGRADE_KEYS: Array[String] = [
	"RANK_FINISH_UPGRADE_01", "RANK_FINISH_UPGRADE_02", "RANK_FINISH_UPGRADE_03", "RANK_FINISH_UPGRADE_04", "RANK_FINISH_UPGRADE_05", 
]
const _FINISH_NOCHANGE_KEYS: Array[String] = [
	"RANK_FINISH_NOCHANGE_01", "RANK_FINISH_NOCHANGE_02", "RANK_FINISH_NOCHANGE_03", "RANK_FINISH_NOCHANGE_04", "RANK_FINISH_NOCHANGE_05", 
	"RANK_FINISH_NOCHANGE_06", "RANK_FINISH_NOCHANGE_07", "RANK_FINISH_NOCHANGE_08", "RANK_FINISH_NOCHANGE_09", "RANK_FINISH_NOCHANGE_10", 
]

const _FINISH_DECLINE_KEYS: Array[String] = [
	"RANK_FINISH_DECLINE_01", "RANK_FINISH_DECLINE_02", "RANK_FINISH_DECLINE_03", "RANK_FINISH_DECLINE_04", "RANK_FINISH_DECLINE_05", 
	"RANK_FINISH_DECLINE_06", "RANK_FINISH_DECLINE_07", "RANK_FINISH_DECLINE_08", "RANK_FINISH_DECLINE_09", "RANK_FINISH_DECLINE_10", 
]

const _RULES: Array[Dictionary] = [
	{"rank_min": 1, "rank_max": 1, "must_rise": ANY, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_11_R0", "RANK_ENCOURAGE_11_R1", "RANK_ENCOURAGE_11_R2"], "arg": ARG_NONE}, 

	{"rank_min": 2, "rank_max": 3, "must_rise": 1, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_23_UP_R0", "RANK_ENCOURAGE_23_UP_R1"], "arg": ARG_NONE}, 
	{"rank_min": 2, "rank_max": 3, "must_rise": 0, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_23_NOCHANGE_R0"], "arg": ARG_NEW_RANK}, 

	{"rank_min": 4, "rank_max": 10, "must_rise": 1, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_310_UP_R0"], "arg": ARG_NONE}, 
	{"rank_min": 4, "rank_max": 10, "must_rise": 0, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_310_NOCHANGE_R0"], "arg": ARG_NONE}, 

	{"rank_min": 11, "rank_max": 15, "must_rise": 1, "diff_min": ANY, "diff_max": ANY, "highest": 0, 
		"keys": ["RANK_ENCOURAGE_1015_UP_R0"], "arg": ARG_NEW_RANK}, 
	{"rank_min": 11, "rank_max": 15, "must_rise": 1, "diff_min": ANY, "diff_max": ANY, "highest": 1, 
		"keys": ["RANK_ENCOURAGE_1015_UP_R1"], "arg": ARG_NONE}, 
	{"rank_min": 11, "rank_max": 15, "must_rise": 0, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_1015_NOCHANGE_R0"], "arg": ARG_NONE}, 

	{"rank_min": 16, "rank_max": 50, "must_rise": 1, "diff_min": 1, "diff_max": 3, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_1550_UP_14_R0"], "arg": ARG_NONE}, 
	{"rank_min": 16, "rank_max": 50, "must_rise": 1, "diff_min": 4, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_1550_UP_4MAX_R0", "RANK_ENCOURAGE_1550_UP_4MAX_R1", 
			"RANK_ENCOURAGE_1550_UP_4MAX_R2"], "arg": ARG_RANK_DIFF}, 
	{"rank_min": 16, "rank_max": 50, "must_rise": 0, "diff_min": ANY, "diff_max": ANY, "highest": ANY, 
		"keys": ["RANK_ENCOURAGE_1550_NOCHANGE_R0"], "arg": ARG_NONE}, 
]


static func resolve_finish_tip(
	old_rank: int, new_rank: int, upgrade_end_rank: int, rng: RandomNumberGenerator
) -> Dictionary:
	if old_rank < RANK_MIN or old_rank > RANK_MAX or new_rank < RANK_MIN or new_rank > RANK_MAX:
		return {"key": "", "arg": -1}
	var rise: int = old_rank - new_rank
	var keys: Array[String]
	var arg: int = -1

	if new_rank > old_rank:
		keys = _FINISH_DECLINE_KEYS
	elif new_rank == 1:
		keys = _FINISH_FIRST_KEYS
	elif rise > 0 and new_rank == 2:
		keys = _FINISH_SECOND_KEYS
	elif rise > 0 and new_rank == 3:
		keys = _FINISH_THIRD_KEYS
	elif upgrade_end_rank > 0 and old_rank > upgrade_end_rank and new_rank <= upgrade_end_rank:
		keys = _FINISH_UPGRADE_KEYS
	elif rise > 0:
		keys = _FINISH_RISE_KEYS
		arg = rise
	else:
		keys = _FINISH_NOCHANGE_KEYS
	return {"key": keys[rng.randi_range(0, keys.size() - 1)], "arg": arg}


static func should_show_finish_word(
	old_rank: int, new_rank: int, upgrade_end_rank: int, downgrade_start_rank: int
) -> bool:
	if old_rank < RANK_MIN or old_rank > RANK_MAX or new_rank < RANK_MIN or new_rank > RANK_MAX:
		return false

	if new_rank > old_rank:
		return false
	if old_rank - new_rank > 5 or new_rank <= 3:
		return true
	var left_downgrade: bool = downgrade_start_rank > 0\
	and old_rank >= downgrade_start_rank and new_rank < downgrade_start_rank
	var entered_upgrade: bool = upgrade_end_rank > 0\
	and old_rank > upgrade_end_rank and new_rank <= upgrade_end_rank
	return left_downgrade or entered_upgrade


static func should_play_top_three_confetti(old_rank: int, new_rank: int) -> bool:
	return old_rank >= RANK_MIN and old_rank <= RANK_MAX\
	and new_rank >= RANK_MIN and new_rank <= 3 and new_rank <= old_rank


static func resolve(old_rank: int, new_rank: int, tier: int, rng: RandomNumberGenerator) -> Dictionary:
	if old_rank <= 0 or new_rank <= 0:
		return {"key": "", "arg": -1}
	var old_r: int = clampi(old_rank, RANK_MIN, RANK_MAX)
	var new_r: int = clampi(new_rank, RANK_MIN, RANK_MAX)
	var risen: bool = old_r > new_r
	var diff: int = old_r - new_r
	var is_highest: bool = tier >= HIGHEST_TIER

	for rule: Dictionary in _RULES:
		if not _matches(rule, new_r, diff, risen, is_highest):
			continue
		var keys: Array = rule["keys"]
		var key: String = String(keys[rng.randi_range(0, keys.size() - 1)])
		return {"key": key, "arg": _resolve_arg(int(rule["arg"]), diff, new_r)}
	return {"key": "", "arg": -1}


static func _matches(rule: Dictionary, new_rank: int, diff: int, risen: bool, is_highest: bool) -> bool:
	if new_rank < int(rule["rank_min"]) or new_rank > int(rule["rank_max"]):
		return false
	var must_rise: int = int(rule["must_rise"])
	if must_rise != ANY and (must_rise == 1) != risen:
		return false
	if risen:
		var dmin: int = int(rule["diff_min"])
		var dmax: int = int(rule["diff_max"])
		if dmin != ANY and diff < dmin:
			return false
		if dmax != ANY and diff > dmax:
			return false
	var highest: int = int(rule["highest"])
	if highest != ANY and (highest == 1) != is_highest:
		return false
	return true


static func _resolve_arg(arg_type: int, diff: int, new_rank: int) -> int:
	match arg_type:
		ARG_RANK_DIFF:
			return diff
		ARG_NEW_RANK:
			return new_rank
		_:
			return -1
