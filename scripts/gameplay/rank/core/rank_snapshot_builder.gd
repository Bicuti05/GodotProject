class_name RankSnapshotBuilder
extends RefCounted


static func build(
	entity: Dictionary, 
	now_ms: int, 
	my_nickname: String, 
	my_avatar_index: int
) -> RankSnapshot:
	var snap: = RankSnapshot.new()
	if entity.is_empty():
		return snap

	snap.event_id = String(entity.get("event_id", ""))
	snap.start_time = int(entity.get("start_time", 0))
	snap.end_time = int(entity.get("end_time", 0))
	snap.my_collect_num = int(entity.get("collect_num", 0))
	snap.start_tier = clampi(int(entity.get("start_tier", 1)), RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX)
	snap.end_tier = clampi(int(entity.get("end_tier", snap.start_tier)), RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX)
	snap.settle_state = String(entity.get("settle_state", "not_settled"))
	snap.has_receive_bonus = bool(entity.get("has_receive_bonus", false))
	snap.reward_hint = int(entity.get("reward_hint", 0))
	snap.reward_coin = int(entity.get("reward_coin", 0))
	snap.has_guide = bool(entity.get("has_guide", false))

	snap.is_ended = not bool(entity.get("update_pending_start", false)) and snap.end_time > 0 and now_ms >= snap.end_time
	snap.remain_seconds = 0 if snap.is_ended else int(maxi(snap.end_time - now_ms, 0) / 1000)
	if bool(entity.get("update_pending_start", false)):
		snap.remain_seconds = int((snap.end_time - snap.start_time) / 1000)

	var bots: Array = entity.get("bots", [])
	snap.participant_count = bots.size() + 1

	var zones: Dictionary = RankSettleLogic.compute_zone_thresholds(snap.participant_count)
	snap.upgrade_end_rank = int(zones.get("upgrade_end_rank", 0))
	snap.downgrade_start_rank = int(zones.get("downgrade_start_rank", 0))
	if snap.start_tier == RankSettleLogic.TIER_MIN:
		snap.downgrade_start_rank = 0
	if snap.start_tier == RankSettleLogic.TIER_MAX:
		snap.upgrade_end_rank = 0

	var reference_ms: int = snap.end_time if snap.is_ended else now_ms
	var elapsed_seconds: int = bot_elapsed_seconds(entity, reference_ms)

	snap.rows = RankSettleLogic.build_ranked_rows(
		snap.my_collect_num, 
		my_nickname, 
		my_avatar_index, 
		bots, 
		elapsed_seconds
	)
	var online_elapsed_seconds: int = elapsed_seconds if String(entity.get("update_mode", "old")) in ["new_24", "new_48"] else -1
	RankFakeUserGenerator.assign_online_status(snap.rows, snap.start_tier, online_elapsed_seconds)
	snap.my_rank_pos = RankSettleLogic.find_my_rank_pos(snap.rows)
	return snap



static func bot_elapsed_seconds(entity: Dictionary, reference_ms: int) -> int:
	if bool(entity.get("update_pending_start", false)):
		return 0
	var start_ms: int = int(entity.get("bot_start_time", entity.get("start_time", 0)))
	if start_ms <= 0:
		return 0
	var end_ms: int = int(entity.get("end_time", 0))
	var effective_ms: int = mini(reference_ms, end_ms) if end_ms > 0 else reference_ms
	return int(maxi(effective_ms - start_ms, 0) / 1000)


static func build_rolled_back(snap: RankSnapshot, my_delta: int) -> RankSnapshot:
	var rolled: = RankSnapshot.new()
	rolled.event_id = snap.event_id
	rolled.start_time = snap.start_time
	rolled.end_time = snap.end_time
	rolled.is_ended = snap.is_ended
	rolled.remain_seconds = snap.remain_seconds
	rolled.start_tier = snap.start_tier
	rolled.end_tier = snap.end_tier
	rolled.participant_count = snap.participant_count
	rolled.upgrade_end_rank = snap.upgrade_end_rank
	rolled.downgrade_start_rank = snap.downgrade_start_rank
	rolled.settle_state = snap.settle_state
	rolled.has_receive_bonus = snap.has_receive_bonus
	rolled.reward_hint = snap.reward_hint
	rolled.reward_coin = snap.reward_coin
	rolled.has_guide = snap.has_guide

	var delta: int = maxi(my_delta, 0)
	var rows: Array[Dictionary] = []
	for row in snap.rows:
		var copy: Dictionary = (row as Dictionary).duplicate()
		if bool(copy.get("is_me", false)):
			copy["collect_num"] = maxi(int(copy.get("collect_num", 0)) - delta, 0)
		rows.append(copy)

	rolled.rows = RankSettleLogic.resort_rows(rows)
	rolled.my_collect_num = maxi(snap.my_collect_num - delta, 0)
	rolled.my_rank_pos = RankSettleLogic.find_my_rank_pos(rolled.rows)
	return rolled


static func create_entity(
	event_id: String, 
	start_ms: int, 
	end_ms: int, 
	start_tier: int, 
	bot_count: int, 
	update_mode: String = "old"
) -> Dictionary:
	var tier: int = clampi(start_tier, RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX)
	var bots: Array[Dictionary] = RankFakeUserGenerator.generate_bots(event_id, tier, bot_count)
	if update_mode in ["new_24", "new_48"]:
		RankUpdateRule.configure_bots(bots, int((end_ms - start_ms) / 1000), event_id, tier)
	return {
		"update_mode": update_mode, 
		"update_pending_start": update_mode in ["new_24", "new_48"], 
		"event_id": event_id, 
		"start_time": start_ms, 
		"end_time": end_ms, 
		"bot_start_time": start_ms if update_mode in ["new_24", "new_48"] else 0, 
		"collect_num": 0, 
		"has_receive_bonus": false, 
		"settle_state": "not_settled", 
		"start_tier": tier, 
		"end_tier": tier, 
		"rank_pos": -1, 
		"has_guide": false, 
		"reward_hint": 0, 
		"reward_coin": 0, 
		"bots": bots, 
	}
