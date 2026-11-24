class_name RankFakeUserGenerator
extends RefCounted


const TIER_SLOPE: Array[float] = [0.0, 2.3, 3.55, 4.8, 6.55, 8.3, 10.15, 12.0]

const HEAD_FAST_HOURS: float = 12.0

const P_DELAYED: float = 0.2
const INITIAL_MAX_COMPLETED_LEVELS: int = 7

const INITIAL_LEVEL_WEIGHTS: PackedInt32Array = [4, 8, 8, 13, 11, 0, 3]
const MIN_CONTENDERS: int = 4
const MAX_CONTENDERS: int = 6
const MAX_CATCH_UP_COMPLETED_LEVELS: int = 2
const ACTIVITY_RULES_VERSION: int = 2
const ACTIVITY_BLOCK_HOURS: float = 4.0
const ACTIVITY_CYCLE_HOURS: float = 24.0
const _ACTIVITY_SEED_SALT: int = 131071
const _SEASON_SEED_SALT: int = 524287


const COLLECT_TARGET_COUNTS: PackedInt32Array = [10, 11, 12, 13, 14, 15, 16]

const LEVEL_TARGET_COUNTS: PackedInt32Array = [
	12, 13, 12, 14, 10, 12, 12, 11, 13, 11, 12, 11, 11, 12, 10, 
	12, 12, 11, 12, 10, 12, 11, 10, 12, 10, 12, 10, 11, 12, 10, 
	12, 11, 10, 12, 10, 12, 10, 10, 12, 10, 12, 10, 10, 12, 10, 
	12, 11, 10, 12, 10, 12, 11, 10, 12, 10, 12, 13, 10, 12, 10, 
	12, 10, 10, 12, 11, 14, 11, 10, 12, 10, 12, 12, 10, 12, 10, 
	12, 12, 10, 14, 10, 13, 12, 12, 12, 10, 12, 10, 12, 13, 11, 
	12, 12, 12, 12, 10, 13, 12, 12, 12, 10, 14, 12, 10, 12, 10, 
]
const FIRST_LEVEL_ID: int = 21
const FIRST_LEVEL_TARGET_COUNT: int = 12
const COLLECT_RULES_VERSION: int = 2
const COLLECT_BLOCK_TOTAL: int = 91
const _COLLECT_SEED_SALT: int = 65537
const _COLLECT_START_SEED_SALT: int = 262147
const _COLUMN_COLLECT_SEED_SALT: int = 786433
const INITIAL_FIRST_TARGET_COUNTS: PackedInt32Array = [9, 10, 11, 12]

const START_LEVEL_TARGET_COUNTS: PackedInt32Array = [
	3, 7, 10, 11, 12, 10, 11, 11, 12, 13, 10, 11, 12, 11, 11, 
	13, 13, 10, 12, 10, 12, 13, 12, 14, 10, 12, 11, 11, 13, 11, 
	12, 11, 11, 11, 10, 12, 12, 10, 11, 10, 12, 11, 11, 10, 10, 
	12, 10, 12, 11, 10, 12, 11, 10, 10, 10, 12, 10, 11, 10, 10, 
	12, 10, 11, 10, 10, 12, 11, 11, 10, 10, 12, 11, 10, 10, 10, 
	12, 13, 13, 10, 10, 12, 10, 11, 10, 11, 14, 11, 11, 10, 10, 
	12, 12, 13, 10, 10, 12, 12, 11, 10, 10, 13, 12, 10, 12, 10, 
	12, 10, 11, 12, 11, 12, 12, 10, 12, 10, 13, 12, 11, 12, 10, 
	14, 12, 11, 10, 10, 
]

static var _level_prefix: PackedInt32Array = []
static var _start_level_prefix: PackedInt32Array = []

const AVATAR_POOL_SIZE: int = 33

const VISIBLE_AVATARS: PackedInt32Array = [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 
]


static func random_avatar_index(rng: RandomNumberGenerator) -> int:
	return VISIBLE_AVATARS[rng.randi_range(0, VISIBLE_AVATARS.size() - 1)]


static func derive_seed(event_id: String, tier: int, bot_index: int) -> int:
	var base: int = 0
	var digits: String = ""
	for i in event_id.length():
		var c: String = event_id[i]
		if c >= "0" and c <= "9":
			digits += c
	if not digits.is_empty():
		base = digits.to_int()
	else:
		base = _stable_hash(event_id)
	return base + tier * 7919 + bot_index * 104729


static func _stable_hash(text: String) -> int:
	var h: int = 2166136261
	for i in text.length():
		h = (h ^ text.unicode_at(i)) * 16777619
		h = h & 2147483647
	return h


static func generate_bot(event_id: String, tier: int, bot_index: int, used_nicknames: Dictionary) -> Dictionary:
	var safe_tier: int = clampi(tier, 1, TIER_SLOPE.size() - 1)
	var seed_value: int = derive_seed(event_id, safe_tier, bot_index)
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_value

	var slope_base: float = TIER_SLOPE[safe_tier]
	var roll: float = rng.randf()
	var bot: Dictionary = {
		"slope": slope_base, 
		"delay_hours": 0.0, 
		"fast_mult": 1.0, 
		"slow_mult": 1.0, 
		"extra_mult": 1.0, 
	}

	if roll < P_DELAYED:
		bot["kind"] = "delayed"
		bot["delay_hours"] = rng.randf_range(8.0, 28.0)
		bot["slope"] = slope_base * _positive_gauss(rng, 1.0, 0.18)
	else:
		bot["kind"] = "regular"
		bot["slope"] = slope_base * _positive_gauss(rng, 1.0, 0.18)

	bot["avatar_index"] = random_avatar_index(rng)
	bot["nickname"] = _pick_nickname(rng, used_nicknames, safe_tier)
	bot["online_seed"] = (seed_value + _ONLINE_SEED_SALT) & 2147483647
	bot["bonus"] = 0
	bot["bonus_budget"] = 0
	bot["collect_seed"] = (seed_value + _COLLECT_SEED_SALT) & 2147483647
	bot["collect_rules_version"] = COLLECT_RULES_VERSION
	var start_rng: = RandomNumberGenerator.new()
	start_rng.seed = seed_value + _COLLECT_START_SEED_SALT
	bot["collect_start_level_id"] = start_rng.randi_range(1, START_LEVEL_TARGET_COUNTS.size())
	bot["collect_first_target"] = INITIAL_FIRST_TARGET_COUNTS[start_rng.randi_range(0, INITIAL_FIRST_TARGET_COUNTS.size() - 1)]
	bot["base_collect"] = int(bot["collect_first_target"])
	return bot


static func generate_bots(event_id: String, tier: int, count: int) -> Array[Dictionary]:
	var bots: Array[Dictionary] = []
	var used: Dictionary = {}
	for i in maxi(count, 0):
		bots.append(generate_bot(event_id, tier, i, used))
	var rng: = RandomNumberGenerator.new()
	rng.seed = derive_seed(event_id, tier, 0) + _SEASON_SEED_SALT
	var indices: Array[int] = []
	for i in bots.size():
		indices.append(i)
	for i in range(indices.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = indices[i]
		indices[i] = indices[j]
		indices[j] = swap
	var zero_count: int = mini(MAX_ZERO_COLLECT_BOTS, maxi(bots.size() - 1, 0))
	var positive_levels: PackedInt32Array = []
	for i in INITIAL_MAX_COMPLETED_LEVELS:
		for _slot in INITIAL_LEVEL_WEIGHTS[i]:
			positive_levels.append(i + 1)
	for i in indices.size():
		var levels: int = 0
		if i >= zero_count:
			var slot: int = floori(float(i - zero_count) * positive_levels.size() / (indices.size() - zero_count))
			levels = positive_levels[slot]
		var bot: Dictionary = bots[indices[i]]
		var budget: int = 0
		for _level in levels:
			budget += int(_get_bot_collect_progress(bot, budget, int(bot["collect_seed"])).next_target)
		bot["base_collect"] = budget
		var progress: Dictionary = _get_bot_collect_progress(bot, budget, int(bot["collect_seed"]))
		bot["initial_collect_budget"] = rng.randi_range(0, int(progress.next_target) - 1)
	prepare_activity_rules(bots, event_id, tier, 0)
	return bots


const MAX_ZERO_COLLECT_BOTS: int = 2


static func prepare_activity_rules(bots: Array, event_id: String, tier: int, elapsed_seconds: int) -> bool:
	var pending: Array[Dictionary] = []
	var existing_contenders: int = 0
	var changed: bool = false
	for i in bots.size():
		var bot: Dictionary = bots[i]
		if int(bot.get("activity_rules_version", 0)) == 1:

			if bool(bot.get("is_contender", false)):
				var origin_growth: float = _get_growth_at(bot, elapsed_seconds)
				bot["activity_origin_growth_micros"] = int(round(origin_growth * 1000000.0))
				bot["activity_origin_seconds"] = elapsed_seconds
				bot["fast_mult"] = 2.5
				bot["slow_mult"] = 1.0
			bot["activity_rules_version"] = ACTIVITY_RULES_VERSION
			changed = true
		if int(bot.get("activity_rules_version", 0)) == ACTIVITY_RULES_VERSION:
			existing_contenders += 1 if bool(bot.get("is_contender", false)) else 0
			continue
		pending.append({"index": i, "collect_num": get_collect_count_at(bot, elapsed_seconds)})
	if pending.is_empty():
		return changed
	var rng: = RandomNumberGenerator.new()
	rng.seed = derive_seed(event_id, tier, 0) + _SEASON_SEED_SALT
	var contender_count: int = mini(bots.size(), rng.randi_range(MIN_CONTENDERS, MAX_CONTENDERS))

	for i in range(pending.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Dictionary = pending[i]
		pending[i] = pending[j]
		pending[j] = swap
	pending.sort_custom( func(a: Dictionary, b: Dictionary) -> bool: return int(a.collect_num) > int(b.collect_num))
	for i in pending.size():
		var index: int = int(pending[i].index)
		var bot: Dictionary = bots[index]
		var origin_growth: float = _get_growth_at(bot, elapsed_seconds)
		var contender: bool = i < maxi(contender_count - existing_contenders, 0)
		bot["is_contender"] = contender
		var bot_rng: = RandomNumberGenerator.new()
		bot_rng.seed = derive_seed(event_id, tier, index) + _ACTIVITY_SEED_SALT
		if contender:
			bot["kind"] = "head"
			bot["slope"] = TIER_SLOPE[clampi(tier, 1, TIER_SLOPE.size() - 1)] * bot_rng.randf_range(0.985, 1.015)
			bot["delay_hours"] = 0.0
			bot["fast_mult"] = 2.5
			bot["slow_mult"] = 1.0
			bot["extra_mult"] = 1.0
		elif String(bot.get("kind", "regular")) in ["head", "super_head"]:
			bot["kind"] = "regular"
		var weights: PackedInt32Array = PackedInt32Array([90, 94, 98, 102, 106, 110]) if contender else PackedInt32Array([45, 65, 85, 115, 135, 155])
		for j in range(weights.size() - 1, 0, -1):
			var picked: int = bot_rng.randi_range(0, j)
			var swap: int = weights[j]
			weights[j] = weights[picked]
			weights[picked] = swap
		var activity_prefix: PackedInt32Array = [0]
		for weight: int in weights:
			activity_prefix.append(activity_prefix[-1] + weight)
		bot["activity_prefix"] = activity_prefix

		bot["activity_slope_micros"] = int(round(float(bot.get("slope", 0.0)) * 1000000.0))
		bot["activity_delay_seconds"] = int(round(float(bot.get("delay_hours", 0.0)) * 3600.0))
		bot["activity_phase_seconds"] = bot_rng.randi_range(0, 86399)
		bot["activity_origin_seconds"] = elapsed_seconds
		bot["activity_origin_growth_micros"] = int(floor(origin_growth * 1000000.0))
		bot["activity_rules_version"] = ACTIVITY_RULES_VERSION
	return true


static func get_collect_count_at(bot: Dictionary, elapsed_seconds: int) -> int:
	return int(get_collect_progress_at(bot, elapsed_seconds).reward_collect_num)




static func _collect_reward_for_progress(bot: Dictionary, progress: Dictionary, seed_value: int) -> int:
	if not bool(bot.get("collectible_column_count", false)):
		return int(progress.collect_num)
	var levels: int = int(progress.completed_levels)
	var rewards: PackedInt32Array = [4, 5, 6]
	var rng: = RandomNumberGenerator.new()
	rng.seed = (seed_value + _COLUMN_COLLECT_SEED_SALT) & 2147483647
	for i in range(rewards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = rewards[i]
		rewards[i] = rewards[j]
		rewards[j] = swap
	@warning_ignore("integer_division")
	var count: int = levels / rewards.size() * 15
	for i in levels % rewards.size():
		count += rewards[i]
	return count


static func _get_legacy_collect_count_at(bot: Dictionary, elapsed_seconds: int) -> int:
	if bot.is_empty():
		return 0
	var base: int = int(bot.get("base_collect", 0))
	var bonus: int = maxi(int(bot.get("bonus", 0)), 0)
	var gained: float = _get_growth_at(bot, elapsed_seconds)
	if bool(bot.get("random_initial_collect", false)):

		var gained_budget: int = maxi(int(gained - float(bot.get("collect_origin_growth", 0.0))), 0)
		return base + get_completed_collect(float(gained_budget + int(bot.get("bonus_budget", 0))), _get_collect_seed(bot))
	if not bot.has("collect_seed"):
		return base + maxi(int(gained), 0) + bonus
	var budget: float = maxf(gained - float(bot.get("collect_origin_growth", 0.0)), 0.0)
	return base + int(_get_fallback_collect_progress(budget, int(bot["collect_seed"])).collect_num) + bonus


static func _get_collect_seed(bot: Dictionary, seed_value: int = 0) -> int:
	if bot.has("collect_seed"):
		return int(bot["collect_seed"])
	if bot.has("online_seed"):
		return (int(bot["online_seed"]) + _COLLECT_SEED_SALT - _ONLINE_SEED_SALT) & 2147483647
	return (seed_value + _COLLECT_SEED_SALT) & 2147483647


static func get_collect_progress_at(bot: Dictionary, elapsed_seconds: int) -> Dictionary:
	var seed_value: int = _get_collect_seed(bot)
	var budget: int = 0
	if bot.has("update_duration_seconds"):
		budget = RankUpdateRule.collect_budget_at(bot, elapsed_seconds)
	elif int(bot.get("collect_rules_version", 0)) == COLLECT_RULES_VERSION and not bool(bot.get("random_initial_collect", false)):
		var growth: float = _get_growth_at(bot, elapsed_seconds)
		var gained: int = maxi(int(growth - float(bot.get("collect_origin_growth", 0.0))), 0)
		budget = int(bot.get("base_collect", 0)) + int(bot.get("initial_collect_budget", 0)) + gained + int(bot.get("bonus_budget", 0))
	else:

		var legacy: int = _get_legacy_collect_count_at(bot, elapsed_seconds)
		var progress: Dictionary = get_collect_progress(float(legacy), seed_value)
		budget = int(progress.collect_num)
		if legacy > budget:
			budget += int(progress.next_target)
	var progress: Dictionary = _get_bot_collect_progress(bot, budget, seed_value)
	progress["collect_budget"] = budget
	progress["collect_seed"] = seed_value
	progress["reward_collect_num"] = _collect_reward_for_progress(bot, progress, seed_value)
	progress["next_reward"] = int(progress.next_target)
	if bool(bot.get("collectible_column_count", false)):
		var next: Dictionary = {"completed_levels": int(progress.completed_levels) + 1}
		progress["next_reward"] = _collect_reward_for_progress(bot, next, seed_value) - int(progress.reward_collect_num)
	return progress


static func _get_bot_collect_progress(bot: Dictionary, budget: int, seed_value: int) -> Dictionary:
	if bot.has("update_original_first_target"):
		var first_target: int = int(bot.collect_first_target)
		var start_level: int = int(bot.collect_start_level_id)
		var original_first: int = int(bot.update_original_first_target)
		if budget < first_target:
			return {"collect_num": 0, "completed_levels": 0, "next_level_id": start_level, 
				"next_target": first_target, "remaining_budget": maxi(budget, 0)}
		var original: Dictionary = _get_independent_collect_progress(budget, seed_value, start_level, original_first)
		var bridge: Dictionary = _get_independent_collect_progress(first_target, seed_value, start_level, original_first)
		if int(original.collect_num) >= first_target:
			original["completed_levels"] = int(original.completed_levels) - int(bridge.completed_levels) + 1
			return original

		return {"collect_num": first_target, "completed_levels": 1, "next_level_id": int(bridge.next_level_id), 
			"next_target": int(bridge.collect_num) + int(bridge.next_target) - first_target, 
			"remaining_budget": budget - first_target}
	if bot.has("collect_start_level_id"):
		return _get_independent_collect_progress(budget, seed_value, int(bot["collect_start_level_id"]), int(bot["collect_first_target"]))
	return get_collect_progress(float(budget), seed_value)


static func _get_independent_collect_progress(budget: int, seed_value: int, start_level_id: int, first_target: int) -> Dictionary:
	if _start_level_prefix.is_empty():
		_start_level_prefix.append(0)
		for target: int in START_LEVEL_TARGET_COUNTS:
			_start_level_prefix.append(_start_level_prefix[-1] + target)
	var available: int = maxi(budget, 0)
	if available < first_target:
		return {"collect_num": 0, "completed_levels": 0, "next_level_id": start_level_id, 
			"next_target": first_target, "remaining_budget": available}

	var origin: int = _start_level_prefix[start_level_id]
	var official_total: int = first_target + _start_level_prefix[-1] - origin
	if available < official_total:
		var low: int = start_level_id
		var high: int = START_LEVEL_TARGET_COUNTS.size()
		while low < high:
			@warning_ignore("integer_division")
			var middle: int = (low + high + 1) / 2
			if first_target + _start_level_prefix[middle] - origin <= available:
				low = middle
			else:
				high = middle - 1
		var count: int = first_target + _start_level_prefix[low] - origin
		return {"collect_num": count, "completed_levels": 1 + low - start_level_id, 
			"next_level_id": low + 1, "next_target": START_LEVEL_TARGET_COUNTS[low], 
			"remaining_budget": available - count}
	var progress: Dictionary = _get_fallback_collect_progress(float(available - official_total), seed_value)
	progress["collect_num"] = int(progress.collect_num) + official_total
	progress["completed_levels"] = int(progress.completed_levels) + 1 + START_LEVEL_TARGET_COUNTS.size() - start_level_id
	progress["next_level_id"] = start_level_id + int(progress.completed_levels)
	return progress


static func prepare_collect_rules(bot: Dictionary, seed_value: int, elapsed_seconds: int) -> bool:
	if int(bot.get("collect_rules_version", 0)) == COLLECT_RULES_VERSION and not bool(bot.get("random_initial_collect", false)):
		return false

	var collect_seed: int = _get_collect_seed(bot, seed_value)
	var legacy: int = _get_legacy_collect_count_at(bot, elapsed_seconds)
	var progress: Dictionary = get_collect_progress(float(legacy), collect_seed)
	var count: int = int(progress.collect_num)
	if legacy > count:
		count += int(progress.next_target)
	bot["collect_seed"] = collect_seed
	bot["base_collect"] = count
	bot["collect_origin_growth"] = float(maxi(int(_get_growth_at(bot, elapsed_seconds)), 0))
	bot["bonus_budget"] = 0
	bot["collect_rules_version"] = COLLECT_RULES_VERSION
	bot.erase("random_initial_collect")
	return true


static func get_completed_collect(budget: float, seed_value: int) -> int:
	return int(get_collect_progress(budget, seed_value).collect_num)


static func get_collect_progress(budget: float, seed_value: int) -> Dictionary:
	if _level_prefix.is_empty():
		_level_prefix.append(0)
		for target: int in LEVEL_TARGET_COUNTS:
			_level_prefix.append(_level_prefix[-1] + target)
	var available: int = maxi(int(budget), 0)
	var official_total: int = _level_prefix[-1]
	if available < official_total:
		var low: int = 0
		var high: int = LEVEL_TARGET_COUNTS.size()
		while low < high:
			@warning_ignore("integer_division")
			var middle: int = (low + high + 1) / 2
			if _level_prefix[middle] <= available:
				low = middle
			else:
				high = middle - 1
		return {
			"collect_num": _level_prefix[low], 
			"completed_levels": low, 
			"next_level_id": FIRST_LEVEL_ID + low, 
			"next_target": LEVEL_TARGET_COUNTS[low], 
			"remaining_budget": available - _level_prefix[low], 
		}

	var progress: Dictionary = _get_fallback_collect_progress(float(available - official_total), seed_value)
	progress["collect_num"] = int(progress.collect_num) + official_total
	progress["completed_levels"] = int(progress.completed_levels) + LEVEL_TARGET_COUNTS.size()
	progress["next_level_id"] = FIRST_LEVEL_ID + int(progress.completed_levels)
	return progress


static func _get_fallback_collect_progress(budget: float, seed_value: int) -> Dictionary:

	var block_index: int = int(floor(budget / float(COLLECT_BLOCK_TOTAL)))
	var completed: int = block_index * COLLECT_BLOCK_TOTAL
	var completed_levels: int = block_index * COLLECT_TARGET_COUNTS.size()
	var targets: PackedInt32Array = COLLECT_TARGET_COUNTS.duplicate()
	var rng: = RandomNumberGenerator.new()
	rng.seed = (seed_value + block_index * 104729) & 2147483647
	for i in range(targets.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = targets[i]
		targets[i] = targets[j]
		targets[j] = swap
	for target: int in targets:
		if float(completed + target) > budget:
			return {
				"collect_num": completed, 
				"completed_levels": completed_levels, 
				"next_target": target, 
				"remaining_budget": int(budget) - completed, 
			}
		completed += target
		completed_levels += 1
	return {}


static func resolve_collect_level_bonus(bot: Dictionary, elapsed_seconds: int, completed_levels: int) -> Dictionary:
	var levels: int = clampi(completed_levels, 0, MAX_CATCH_UP_COMPLETED_LEVELS)
	if levels == 0:
		return {}
	var progress: Dictionary = get_collect_progress_at(bot, elapsed_seconds)
	var budget: int = int(progress.collect_num)
	var seed_value: int = int(progress.collect_seed)

	for _i in levels:
		budget += int(_get_bot_collect_progress(bot, budget, seed_value).next_target)
	var bonus: Dictionary = resolve_collect_bonus(bot, elapsed_seconds, budget - int(progress.collect_budget))
	bonus["completed_levels"] = levels
	return bonus


static func resolve_collect_bonus(bot: Dictionary, elapsed_seconds: int, rolled_bonus: int) -> Dictionary:
	if rolled_bonus <= 0:
		return {}
	var progress: Dictionary = get_collect_progress_at(bot, elapsed_seconds)
	var before: int = int(progress.reward_collect_num)
	var seed_value: int = int(progress.collect_seed)
	var after: Dictionary = _get_bot_collect_progress(bot, int(progress.collect_budget) + rolled_bonus, seed_value)
	return {
		"bonus": _collect_reward_for_progress(bot, after, seed_value) - before, 
		"budget_delta": rolled_bonus, 
	}


static func _get_growth_at(bot: Dictionary, elapsed_seconds: int) -> float:
	if int(bot.get("activity_rules_version", 0)) in [1, ACTIVITY_RULES_VERSION]:
		var origin: int = int(bot.get("activity_origin_seconds", 0))
		return float(bot.get("activity_origin_growth_micros", 0)) / 1000000.0 + (_get_activity_growth_at(bot, maxi(elapsed_seconds, origin)) - _get_activity_growth_at(bot, origin))
	return _get_legacy_growth_at(bot, elapsed_seconds)


static func _get_activity_growth_at(bot: Dictionary, elapsed_seconds: int) -> float:
	var hours: float = float(maxi(elapsed_seconds, 0)) / 3600.0
	var slope: float = float(bot["activity_slope_micros"]) / 1000000.0
	var active: float = _get_activity_hours(bot, hours)
	match String(bot.get("kind", "regular")):
		"delayed":
			var delay: float = float(bot["activity_delay_seconds"]) / 3600.0
			return slope * maxf(active - _get_activity_hours(bot, minf(hours, delay)), 0.0)
		"head", "super_head":
			var fast: float = _get_activity_hours(bot, minf(hours, HEAD_FAST_HOURS))
			return slope * (fast * float(bot.get("fast_mult", 1.0)) + (active - fast) * float(bot.get("slow_mult", 1.0))) * float(bot.get("extra_mult", 1.0))
	return slope * active


static func _get_activity_hours(bot: Dictionary, hours: float) -> float:
	var phase: float = float(bot.get("activity_phase_seconds", 0)) / 3600.0
	var prefix: PackedInt32Array = bot["activity_prefix"]
	return _get_activity_integral(prefix, hours + phase) - _get_activity_integral(prefix, phase)


static func _get_activity_integral(prefix: PackedInt32Array, hours: float) -> float:

	var cycles: int = int(floor(hours / ACTIVITY_CYCLE_HOURS))
	var remainder: float = hours - float(cycles) * ACTIVITY_CYCLE_HOURS
	var block: int = mini(int(remainder / ACTIVITY_BLOCK_HOURS), prefix.size() - 2)
	var weight: int = prefix[block + 1] - prefix[block]
	return float(cycles) * ACTIVITY_CYCLE_HOURS + float(prefix[block]) * ACTIVITY_BLOCK_HOURS / 100.0 + (remainder - float(block) * ACTIVITY_BLOCK_HOURS) * float(weight) / 100.0


static func _get_legacy_growth_at(bot: Dictionary, elapsed_seconds: int) -> float:
	if elapsed_seconds <= 0:
		return 0.0

	var hours: float = float(elapsed_seconds) / 3600.0
	var slope: float = float(bot.get("slope", 0.0))
	var gained: float = 0.0

	match String(bot.get("kind", "regular")):
		"delayed":
			var delay: float = float(bot.get("delay_hours", 0.0))
			if hours > delay:
				gained = slope * (hours - delay)
		"head", "super_head":
			var fast_mult: float = float(bot.get("fast_mult", 1.0))
			var slow_mult: float = float(bot.get("slow_mult", 1.0))
			var extra: float = float(bot.get("extra_mult", 1.0))
			if hours <= HEAD_FAST_HOURS:
				gained = slope * fast_mult * hours
			else:
				gained = slope * fast_mult * HEAD_FAST_HOURS\
				+ slope * slow_mult * (hours - HEAD_FAST_HOURS)
			gained *= extra
		_:
			gained = slope * hours

	return maxf(gained, 0.0)


static func _positive_gauss(rng: RandomNumberGenerator, mean: float, deviation: float) -> float:
	return maxf(rng.randfn(mean, deviation), 0.1)


static func _pick_nickname(rng: RandomNumberGenerator, used_nicknames: Dictionary, tier: int) -> String:
	var pool: PackedStringArray = RankNicknamePool.for_tier(tier)
	var pool_size: int = pool.size()
	if used_nicknames.size() < pool_size:
		var start: int = rng.randi_range(0, pool_size - 1)
		for offset in pool_size:
			var name: String = pool[(start + offset) % pool_size]
			if not used_nicknames.has(name):
				used_nicknames[name] = true
				return name
	var fallback: String = "Player_%s" % random_nickname_suffix(rng)
	used_nicknames[fallback] = true
	return fallback


const _SUFFIX_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

static func random_nickname_suffix(rng: RandomNumberGenerator) -> String:
	var out: String = ""
	for _i in 6:
		out += _SUFFIX_CHARS[rng.randi_range(0, _SUFFIX_CHARS.length() - 1)]
	return out


const _ONLINE_SEED_SALT: int = 23063

const _ONLINE_LEGACY_SALT: int = 5381

const ONLINE_KEY_NOW: String = "RANK_ONLINE_NOW"
const ONLINE_KEY_MINUTES_AGO: String = "RANK_ONLINE_MINUTES_AGO"
const ONLINE_KEY_HOURS_MINUTES_AGO: String = "RANK_ONLINE_HOURS_MINUTES_AGO"

const TIER_ONLINE_WINDOW_MINUTES: Array[int] = [0, 100, 90, 75, 60, 45, 41, 36]

const ONLINE_NOW_MINUTES: int = 30
const NEIGHBOR_RADIUS: int = 2



static func assign_online_status(rows: Array, tier: int, activity_elapsed_seconds: int = -1) -> void :
	var safe_tier: int = clampi(tier, 1, TIER_ONLINE_WINDOW_MINUTES.size() - 1)
	var window: int = TIER_ONLINE_WINDOW_MINUTES[safe_tier]
	var my_index: int = -1

	for i in rows.size():
		var row: Dictionary = rows[i]
		if bool(row.get("is_me", false)):
			my_index = i
			row["online_text_key"] = ""
			row["online_minutes"] = 0
			continue
		if bool(row.get("boost_hit", false)):
			row["online_text_key"] = ONLINE_KEY_NOW
			row["online_minutes"] = 0
			continue
		var rng: = RandomNumberGenerator.new()
		rng.seed = int(row.get("online_seed", 0)) + _ONLINE_LEGACY_SALT
		var minutes: int = rng.randi_range(0, maxi(window, 1))
		if activity_elapsed_seconds >= 0:
			minutes = mini(minutes, int(activity_elapsed_seconds / 60))
		row["online_minutes"] = minutes
		row["online_text_key"] = ONLINE_KEY_NOW if minutes < ONLINE_NOW_MINUTES\
		else ONLINE_KEY_MINUTES_AGO

	if my_index >= 0:
		_ensure_neighbor_online(rows, my_index)


static func _ensure_neighbor_online(rows: Array, my_index: int) -> void :
	var neighbors: Array[int] = []
	for offset in range( - NEIGHBOR_RADIUS, NEIGHBOR_RADIUS + 1):
		if offset == 0:
			continue
		var idx: int = my_index + offset
		if idx < 0 or idx >= rows.size():
			continue
		if bool(rows[idx].get("is_me", false)):
			continue
		if String(rows[idx].get("online_text_key", "")) == ONLINE_KEY_NOW:
			return
		neighbors.append(idx)
	if neighbors.is_empty():
		return
	var rng: = RandomNumberGenerator.new()
	rng.seed = my_index + 1
	var picked: int = neighbors[rng.randi_range(0, neighbors.size() - 1)]
	rows[picked]["online_text_key"] = ONLINE_KEY_NOW
	rows[picked]["online_minutes"] = 0
