class_name RankCatchUpRule
extends RefCounted


const ENTER_THRESHOLD: int = 5
const MIN_PICKS: int = 2
const MAX_PICKS: int = 3
const MIN_COMPLETED_LEVELS: int = 1
const MAX_COMPLETED_LEVELS: int = RankFakeUserGenerator.MAX_CATCH_UP_COMPLETED_LEVELS
const P_ONE_COMPLETED_LEVEL: float = 0.75
const WINDOW_ROUNDS: int = 2
const RULES_VERSION: int = 2


static func resolve(
	rows: Array, 
	rank_before: int, 
	my_delta: int, 
	rng: RandomNumberGenerator, 
	bots: Array, 
	elapsed_seconds: int, 
	scored_round_count: int = 0, 
	wave: Dictionary = {}
) -> Dictionary:
	var state: Dictionary = wave.duplicate(true)
	var picks: Array[Dictionary] = []
	var growth_rounds: Dictionary = {}
	if my_delta <= 0:
		return {"wave": state, "picks": picks, "growth_rounds": growth_rounds}
	if int(state.get("rules_version", 0)) == 1:

		for member: Dictionary in state.members:
			member["target_levels"] = mini(int(member.target_levels), MAX_COMPLETED_LEVELS)
			member["first_levels"] = mini(int(member.first_levels), int(member.target_levels))
		state["rules_version"] = RULES_VERSION
	elif int(state.get("rules_version", 0)) != RULES_VERSION:
		state.clear()
	if state.is_empty():
		var rank_after: int = RankSettleLogic.find_my_rank_pos(rows)
		var entered_before: bool = rank_before > 0 and rank_before <= ENTER_THRESHOLD
		var entered_after: bool = rank_after > 0 and rank_after <= ENTER_THRESHOLD
		if not entered_before and not entered_after:
			return {"wave": state, "picks": picks, "growth_rounds": growth_rounds}
		state = _start_wave(rows, my_delta, rng, bots, elapsed_seconds, scored_round_count)
	if state.is_empty():
		return {"wave": state, "picks": picks, "growth_rounds": growth_rounds}

	var deadline: bool = scored_round_count - int(state.start_round) >= WINDOW_ROUNDS - 1

	for member: Dictionary in state.members:
		var bot_index: int = int(member.bot_index)
		if bot_index < 0 or bot_index >= bots.size():
			continue
		var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bots[bot_index], elapsed_seconds)
		if int(progress.completed_levels) > int(member.get("observed_completed_levels", member.start_completed_levels)):
			growth_rounds[bot_index] = scored_round_count
		var achieved: int = maxi(int(progress.completed_levels) - int(member.start_completed_levels), 0)
		var required: int = int(member.target_levels) if deadline else int(member.first_levels)
		var missing: int = maxi(required - achieved, 0)
		member["observed_completed_levels"] = int(progress.completed_levels) + missing
		if missing == 0:
			continue
		var bonus: Dictionary = RankFakeUserGenerator.resolve_collect_level_bonus(bots[bot_index], elapsed_seconds, missing)
		bonus["bot_index"] = bot_index
		picks.append(bonus)
		growth_rounds[bot_index] = scored_round_count

	return {"wave": {} if deadline else state, "picks": picks, "growth_rounds": growth_rounds}


static func _start_wave(
	rows: Array, 
	my_delta: int, 
	rng: RandomNumberGenerator, 
	bots: Array, 
	elapsed_seconds: int, 
	scored_round_count: int
) -> Dictionary:
	var my_collect: int = 0
	for row: Dictionary in rows:
		if bool(row.get("is_me", false)):
			my_collect = int(row.get("collect_num", 0))
			break
	var collect_before: int = maxi(my_collect - my_delta, 0)
	var candidates: Array[Dictionary] = []
	for row: Dictionary in rows:

		if bool(row.get("is_me", false)) or int(row.get("collect_num", 0)) >= collect_before:
			continue
		var bot_index: int = int(row.get("bot_index", -1))
		if bot_index < 0 or bot_index >= bots.size():
			continue
		candidates.append({"bot_index": bot_index, "gap": absi(int(row.get("collect_num", 0)) - my_collect)})

	_shuffle_candidates(candidates, rng)
	candidates.sort_custom( func(a: Dictionary, b: Dictionary) -> bool: return int(a.gap) < int(b.gap))
	candidates.resize(mini(candidates.size(), MAX_PICKS))
	_shuffle_candidates(candidates, rng)
	var take: int = mini(candidates.size(), rng.randi_range(MIN_PICKS, MAX_PICKS))
	if take == 0:
		return {}
	var members: Array[Dictionary] = []
	for i in take:
		var bot_index: int = int(candidates[i].bot_index)
		var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bots[bot_index], elapsed_seconds)
		var target_levels: int = MIN_COMPLETED_LEVELS if rng.randf() < P_ONE_COMPLETED_LEVEL else MAX_COMPLETED_LEVELS

		var first_levels: int = rng.randi_range(0, MIN_COMPLETED_LEVELS)
		var last_growth: int = int(bots[bot_index].get("last_catch_up_growth_round", scored_round_count - 1))
		if scored_round_count - last_growth >= WINDOW_ROUNDS:
			first_levels = maxi(first_levels, MIN_COMPLETED_LEVELS)
		members.append({
			"bot_index": bot_index, 
			"start_completed_levels": int(progress.completed_levels), 
			"target_levels": target_levels, 
			"first_levels": first_levels, 
			"observed_completed_levels": int(progress.completed_levels), 
		})
	return {"rules_version": RULES_VERSION, "start_round": scored_round_count, "members": members}


static func _shuffle_candidates(candidates: Array[Dictionary], rng: RandomNumberGenerator) -> void :
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Dictionary = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
