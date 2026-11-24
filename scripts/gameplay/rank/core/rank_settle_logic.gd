class_name RankSettleLogic
extends RefCounted


const TIER_MIN: int = 1
const TIER_MAX: int = 7

const DEFAULT_PARTICIPANT_COUNT: int = 50

const REDUCED_PARTICIPANT_MAX: int = 20
const REDUCED_PROMOTE_COUNT: int = 6
const REDUCED_DEMOTE_COUNT: int = 4
const DEFAULT_PROMOTE_COUNT: int = 15
const DEFAULT_DEMOTE_COUNT: int = 10

const REWARD_HINT_BY_RANK: Dictionary = {1: 5, 2: 3, 3: 2}
const REWARD_COIN_TABLE: Array[Array] = [
	[300, 200, 100], 
	[500, 300, 200], 
	[800, 500, 300], 
	[1000, 600, 400], 
	[1200, 700, 500], 
	[1500, 900, 600], 
	[2000, 1200, 800], 
]


static func compute_zone_thresholds(participant_count: int) -> Dictionary:
	var total: int = maxi(participant_count, 1)
	var promote: int = DEFAULT_PROMOTE_COUNT
	var demote: int = DEFAULT_DEMOTE_COUNT
	if total <= REDUCED_PARTICIPANT_MAX:
		promote = REDUCED_PROMOTE_COUNT
		demote = REDUCED_DEMOTE_COUNT
	promote = mini(promote, total)
	var downgrade_start: int = total - demote + 1
	if downgrade_start <= promote:
		downgrade_start = promote + 1
	return {
		"upgrade_end_rank": promote, 
		"downgrade_start_rank": downgrade_start, 
	}


static func build_ranked_rows(
	my_collect_num: int, 
	my_nickname: String, 
	my_avatar_index: int, 
	bots: Array, 
	elapsed_seconds: int
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in bots.size():
		var bot: Dictionary = bots[i]
		rows.append({
			"rank_pos": 0, 
			"is_me": false, 
			"collect_num": RankFakeUserGenerator.get_collect_count_at(bot, elapsed_seconds), 
			"nickname": String(bot.get("nickname", "")), 
			"avatar_index": int(bot.get("avatar_index", 1)), 
			"online_seed": int(bot.get("online_seed", 0)), 
			"online_text_key": "", 
			"online_minutes": 0, 
			"tie_key": i, 
			"bot_index": i, 
			"boost_hit": int(bot.get("bonus", 0)) > 0, 
		})
	rows.append({
		"rank_pos": 0, 
		"is_me": true, 
		"collect_num": maxi(my_collect_num, 0), 
		"nickname": my_nickname, 
		"avatar_index": my_avatar_index, 
		"online_seed": 0, 
		"online_text_key": "", 
		"online_minutes": 0, 
		"tie_key": -1, 
		"bot_index": -1, 
		"boost_hit": false, 
	})

	rows.sort_custom(_compare_rows)
	for idx in rows.size():
		rows[idx]["rank_pos"] = idx + 1
	return rows


static func _compare_rows(a: Dictionary, b: Dictionary) -> bool:
	var ca: int = int(a.get("collect_num", 0))
	var cb: int = int(b.get("collect_num", 0))
	if ca != cb:
		return ca > cb
	var ma: bool = bool(a.get("is_me", false))
	var mb: bool = bool(b.get("is_me", false))
	if ma != mb:
		return mb
	return int(a.get("tie_key", 0)) < int(b.get("tie_key", 0))


static func resort_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	rows.sort_custom(_compare_rows)
	for idx in rows.size():
		rows[idx]["rank_pos"] = idx + 1
	return rows


static func find_my_rank_pos(rows: Array) -> int:
	for row in rows:
		if bool(row.get("is_me", false)):
			return int(row.get("rank_pos", -1))
	return -1


static func compute_tier_after(
	rank_pos: int, 
	start_tier: int, 
	upgrade_end_rank: int, 
	downgrade_start_rank: int
) -> int:
	var tier: int = clampi(start_tier, TIER_MIN, TIER_MAX)
	if rank_pos < 1:
		return tier
	if upgrade_end_rank > 0 and rank_pos <= upgrade_end_rank:
		return mini(tier + 1, TIER_MAX)
	if downgrade_start_rank > 0 and rank_pos >= downgrade_start_rank:
		return maxi(tier - 1, TIER_MIN)
	return tier


static func get_reward(rank_pos: int, tier: int) -> Dictionary:
	if rank_pos < 1 or rank_pos > 3:
		return {"hint": 0, "coin": 0}
	var hint: int = int(REWARD_HINT_BY_RANK.get(rank_pos, 0))
	var t: int = clampi(tier, TIER_MIN, TIER_MAX)
	var coin: int = int(REWARD_COIN_TABLE[t - 1][rank_pos - 1])
	return {"hint": hint, "coin": coin}
