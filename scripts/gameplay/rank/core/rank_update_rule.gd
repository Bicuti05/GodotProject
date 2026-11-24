class_name RankUpdateRule
extends RefCounted


const ENTER_THRESHOLD: int = 15
const EARLY_SECONDS: int = 900
const MEMBER_ROUNDS: int = 5
const MIN_INTERVAL: int = 2
const MAX_INTERVAL: int = 3
const MAX_MEMBERS: int = 2


static func configure_bots(bots: Array, duration_seconds: int, event_id: String, tier: int) -> void :
	var rng: = RandomNumberGenerator.new()
	rng.seed = RankFakeUserGenerator.derive_seed(event_id, tier, 0) + 93871
	var indices: Array[int] = []
	for i in bots.size():
		indices.append(i)
	for i in range(indices.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = indices[i]
		indices[i] = indices[j]
		indices[j] = swap
	var zero_count: int = mini(bots.size(), rng.randi_range(3, 5))
	var low_count: int = mini(bots.size() - zero_count, rng.randi_range(3, 8))
	for slot in indices.size():
		var bot: Dictionary = bots[indices[slot]]
		var old_final: int = int(RankFakeUserGenerator.get_collect_progress_at(bot, 48 * 3600).collect_budget)
		var old_first_target: int = int(bot.collect_first_target)
		var first_target: int = rng.randi_range(16, 20)
		if slot < zero_count:
			first_target = rng.randi_range(4, 6)
		elif slot < zero_count + low_count:
			first_target = rng.randi_range(4, 6)
		elif slot < zero_count + low_count + 20:
			first_target = rng.randi_range(10, 12)
		var initial: int = 0 if slot < zero_count else first_target
		bot["update_original_first_target"] = old_first_target
		bot["collect_first_target"] = first_target
		bot["base_collect"] = initial
		bot["initial_collect_budget"] = 0
		bot["update_duration_seconds"] = duration_seconds

		var early: int = rng.randi_range(55, 66)
		if slot < zero_count + low_count:
			early = rng.randi_range(16, 26)
		elif slot < zero_count + low_count + 20:
			early = rng.randi_range(25, 33)
		if slot >= indices.size() - 3:
			early = rng.randi_range(75, 85)
		bot["update_initial_budget"] = initial

		var final_budget: int = old_final
		bot["update_early_budget"] = mini(early, final_budget)
		bot["update_final_budget"] = maxi(final_budget, initial)
		bot["update_early_delay_seconds"] = rng.randi_range(0, 60)
		bot["update_floor_budget"] = initial


static func collect_budget_at(bot: Dictionary, elapsed_seconds: int) -> int:
	var duration: int = int(bot.update_duration_seconds)
	var elapsed: int = clampi(elapsed_seconds, 0, duration)
	var initial: int = int(bot.update_initial_budget)
	var early: int = int(bot.update_early_budget)
	var final_budget: int = int(bot.update_final_budget)
	var delay: int = int(bot.update_early_delay_seconds)
	var budget: int
	if elapsed < EARLY_SECONDS:
		var progress: float = maxf(elapsed - delay, 0) / (EARLY_SECONDS - delay)
		budget = initial + int(float(early - initial) * pow(progress, 0.65))
	else:
		budget = early + int(float(final_budget - early) * (elapsed - EARLY_SECONDS) / (duration - EARLY_SECONDS))
	budget = maxi(budget, int(bot.get("update_floor_budget", initial)))
	if elapsed >= int(bot.get("update_ready_seconds", duration + 1)):
		budget = maxi(budget, int(bot.get("update_pending_budget", initial)))
	return mini(budget, final_budget)



static func materialize(bots: Array, elapsed_seconds: int, round_finished: bool = false) -> void :
	for bot: Dictionary in bots:
		if bot.has("update_pending_budget") and elapsed_seconds >= int(bot.update_ready_seconds):
			bot["update_floor_budget"] = maxi(int(bot.update_floor_budget), int(bot.update_pending_budget))
			bot.erase("update_pending_budget")
			bot.erase("update_ready_seconds")
		elif round_finished:

			bot.erase("update_pending_budget")
			bot.erase("update_ready_seconds")



static func prepare_round(entity: Dictionary, rows: Array, elapsed_seconds: int, round_id: String, 
		my_delta: int) -> bool:
	if round_id.is_empty() or String(entity.get("update_round_id", "")) == round_id:
		return false
	var bots: Array = entity.bots
	materialize(bots, elapsed_seconds)
	entity["update_round_id"] = round_id
	var count: int = int(entity.get("scored_round_count", 0))
	var rank_pos: int = RankSettleLogic.find_my_rank_pos(rows)
	if count < 3 or rank_pos > ENTER_THRESHOLD or rank_pos < 1:
		return true
	var rng: = RandomNumberGenerator.new()
	rng.seed = (String(entity.event_id) + ":competition:" + str(count)).hash()
	var wave: Dictionary = entity.get("update_wave", {})
	if wave.is_empty():
		wave = {"members": [], "start_round": count, "next_round": count + rng.randi_range(MIN_INTERVAL, MAX_INTERVAL)}
		entity["update_wave"] = wave
	if count < int(wave.next_round):
		return true
	wave["next_round"] = count + rng.randi_range(MIN_INTERVAL, MAX_INTERVAL)
	if int(entity.get("update_stalled_rounds", 0)) >= 1:
		return true
	if wave.members.is_empty() or count - int(wave.start_round) >= MEMBER_ROUNDS:
		var members: Array[int] = []
		var candidates: Array[Dictionary] = []
		var my_collect: int = int(entity.collect_num)
		for row: Dictionary in rows:
			if not bool(row.is_me) and int(row.collect_num) < my_collect\
			and my_collect - int(row.collect_num) <= my_delta:
				candidates.append(row)

		for i in mini(candidates.size(), rng.randi_range(1, MAX_MEMBERS)):
			members.append(int(candidates[i].bot_index))
		wave["members"] = members
		wave["start_round"] = count
	var my_collect: int = int(entity.collect_num)
	for index: int in wave.members:
		var bot: Dictionary = bots[index]
		if bot.has("update_pending_budget"):
			continue
		var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, elapsed_seconds)
		var current: int = int(progress.reward_collect_num)
		var next_collect: int = current + int(progress.next_reward)
		var next_budget: int = int(progress.collect_num) + int(progress.next_target)

		if current >= my_collect or my_collect - current > my_delta\
		or next_collect >= my_collect + my_delta or next_budget > int(bot.update_final_budget):
			continue
		bot["update_pending_budget"] = next_budget
		bot["update_ready_seconds"] = elapsed_seconds + rng.randi_range(30, 90)
	return true
