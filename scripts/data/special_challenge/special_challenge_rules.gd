class_name SpecialChallengeRules
extends RefCounted


const BANK_SIZE: int = 200

const BANK_SIZE_V2: int = 158
const FIRST_ANCHOR: int = 27
const INTERVAL: int = 10


static func default_schedule() -> Dictionary:
	return {"first_anchor": FIRST_ANCHOR, "interval": INTERVAL}

static func schedule_for_platform(platform: String) -> Dictionary:
	return {"first_anchor": 17, "interval": 10 if platform == "iOS" else 5}


static func current_schedule() -> Dictionary:
	return schedule_for_platform(OS.get_name())

static func is_anchor(level: int, first_anchor: int = FIRST_ANCHOR, interval: int = INTERVAL) -> bool:
	return first_anchor > 0 and interval > 0 and level >= first_anchor and (level - first_anchor) % interval == 0

static func case_number(completed: int, bank_size: int = BANK_SIZE) -> int:
	return posmod(completed, maxi(1, bank_size)) + 1




static func level2_case_for_slot(slot: int, control_turns: int, new_turns: int) -> Dictionary:
	if slot == 1:
		return {"bank": 1, "case_number": case_number(new_turns, BANK_SIZE_V2)}
	return {"bank": 0, "case_number": case_number(control_turns, BANK_SIZE)}


static func reward_for_roll(roll: int) -> Dictionary:
	if roll < 40:
		return {"coins": 300, "undo": 1, "hint": 1, "rope": 0}
	if roll < 60:
		return {"coins": 0, "undo": 0, "hint": 0, "rope": 1}
	return {"coins": 0, "undo": 2, "hint": 1, "rope": 0}

static func multiplied_reward(reward: Dictionary, multiplier: int) -> Dictionary:
	var result: Dictionary = {}
	for kind: String in ["coins", "undo", "hint", "rope"]:
		result[kind] = int(reward.get(kind, 0)) * multiplier
	return result
