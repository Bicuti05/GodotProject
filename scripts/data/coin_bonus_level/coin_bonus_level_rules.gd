class_name CoinBonusLevelRules
extends RefCounted


const MIN_LEVEL: int = 13
const ALL_PRESET: Dictionary = {"mode": "all", "every": 3, "max_per_day": 4}
const HARD_PRESET: Dictionary = {"mode": "hard", "every": 2, "max_per_day": 3}

const MAX_JSON_INTEGER: float = 9.00719925474099e+15

static func parse_rule(raw: String) -> Dictionary:
	var json: JSON = JSON.new()
	if json.parse(raw) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if data.get("mode") not in ["hard", "all"]:
		return {}
	for key: String in ["every", "max_per_day"]:
		var number: Variant = data.get(key)
		if not (number is int or number is float):
			return {}
		var numeric: float = float(number)
		if not is_finite(numeric) or numeric < 1.0 or numeric > MAX_JSON_INTEGER or floor(numeric) != numeric:
			return {}
	return {"mode": String(data.mode), "every": int(data.every), "max_per_day": int(data.max_per_day)}

static func state_for_day(saved: Dictionary, date: String) -> Dictionary:
	if String(saved.get("date", "")) == date:
		return saved.duplicate(true)
	return {"date": date, "all_count": 0, "hard_count": 0, "rewarded": 0, 
		"control_all_rewarded": 0, "control_hard_rewarded": 0, 
		"last_assignment": (saved.get("last_assignment", {}) as Dictionary).duplicate(true), 
		"last_claimed_level": int(saved.get("last_claimed_level", 0))}

static func is_candidate(index: int, rule: Dictionary, rewarded: int) -> bool:
	return not rule.is_empty() and index > 0 and rewarded < int(rule.max_per_day)\
	and (index - 1) % (int(rule.every) + 1) == 0

static func preview(saved: Dictionary, date: String, level: int, difficulty: String, 
		rule: Dictionary, control: bool = false) -> Dictionary:
	var previous: Dictionary = saved.get("last_assignment", {}) as Dictionary
	if int(previous.get("level", 0)) == level:
		return previous.duplicate(true)
	var state: Dictionary = state_for_day(saved, date)
	var eligible: bool = level >= MIN_LEVEL
	var hard: bool = difficulty.strip_edges().to_lower() == "hard"
	var all_index: int = int(state.get("all_count", 0)) + (1 if eligible else 0)
	var hard_index: int = int(state.get("hard_count", 0)) + (1 if eligible and hard else 0)
	var all_candidate: bool = eligible and is_candidate(all_index, ALL_PRESET, int(state.get("control_all_rewarded", 0)))
	var hard_candidate: bool = eligible and hard and is_candidate(hard_index, HARD_PRESET, int(state.get("control_hard_rewarded", 0)))
	var double_coins: bool = eligible and not rule.is_empty() and (rule.mode == "all" or hard)\
	and is_candidate(all_index if rule.mode == "all" else hard_index, rule, int(state.get("rewarded", 0)))
	return {"level": level, "date": date, "rule": rule.duplicate(), "double_coins": double_coins, 
		"expose": double_coins or (control and (all_candidate or hard_candidate)), 
		"all_candidate": all_candidate, "hard_candidate": hard_candidate, 
		"all_index": all_index, "hard_index": hard_index}

static func enter(saved: Dictionary, assignment: Dictionary) -> Dictionary:
	var previous: Dictionary = saved.get("last_assignment", {}) as Dictionary
	if int(previous.get("level", 0)) == int(assignment.get("level", 0)):
		return saved.duplicate(true)
	var state: Dictionary = state_for_day(saved, String(assignment.date))
	state["all_count"] = int(assignment.get("all_index", state.get("all_count", 0)))
	state["hard_count"] = int(assignment.get("hard_index", state.get("hard_count", 0)))
	state["last_assignment"] = assignment.duplicate(true)
	return state

static func complete(saved: Dictionary, assignment: Dictionary, level: int, coins_granted: bool = true) -> Dictionary:
	var state: Dictionary = saved.duplicate(true)
	if level <= int(state.get("last_claimed_level", 0)):
		return state
	state["last_claimed_level"] = level

	if String(assignment.get("date", "")) != String(state.get("date", "")):
		return state
	if coins_granted and bool(assignment.get("double_coins", false)):
		state["rewarded"] = int(state.get("rewarded", 0)) + 1
	if bool(assignment.get("all_candidate", false)):
		state["control_all_rewarded"] = int(state.get("control_all_rewarded", 0)) + 1
	if bool(assignment.get("hard_candidate", false)):
		state["control_hard_rewarded"] = int(state.get("control_hard_rewarded", 0)) + 1
	return state
