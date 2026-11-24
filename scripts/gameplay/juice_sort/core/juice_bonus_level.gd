class_name JuiceBonusLevel
extends RefCounted






const FIRST_LEVEL: int = 13

const INTERVAL: int = 10

const REWARD_COINS: int = 100
const REWARD_COINS_V2: int = 300

const REASON_NONE: String = ""
const REASON_NO_SINGLE_POT: String = "no_single_pot"
const REASON_NOT_ON_FIRST_SCREEN: String = "not_on_first_screen"

const NO_BONUS_TYPE: int = -1

const YELLOW_SLOT: int = 4



static func is_bonus_level(level: int) -> bool:
	return level >= FIRST_LEVEL and (level - FIRST_LEVEL) % INTERVAL == 0



static func reward_coins(v2: bool = false) -> int:
	return REWARD_COINS_V2 if v2 else REWARD_COINS



















static func pick_plan(level: JuiceLevel, slot_of_type: PackedInt32Array, 
		v2: bool = false, rng: RandomNumberGenerator = null) -> Dictionary:
	if level == null:
		return _skip_plan(REASON_NONE)
	if v2:
		return _pick_plan_v2(level, slot_of_type, rng)
	return _pick_plan_v1(level, slot_of_type, rng)



static func _pick_plan_v1(level: JuiceLevel, slot_of_type: PackedInt32Array, 
		rng: RandomNumberGenerator) -> Dictionary:
	var pot_counts: Dictionary = _pot_counts(level)
	var candidates: Array[int] = _single_pot_types(pot_counts)
	candidates.sort()
	var yellow_type: int = _type_of_slot(slot_of_type, YELLOW_SLOT)
	var yellow_pots: int = int(pot_counts.get(yellow_type, 0)) if yellow_type >= 0 else 0
	if yellow_pots == 1:
		return _plan(yellow_type, -1, -1)
	if candidates.is_empty():
		SortLogger.info("[BonusLevel] 本局跳过奖励关：没有只占一盆的颜色（关卡 %d，%d 种颜色）"
			%[level.id, level.types])
		return _skip_plan(REASON_NO_SINGLE_POT)
	var chosen: int = _pick_candidate(candidates, rng)
	if yellow_pots > 1:
		SortLogger.info("[BonusLevel] 金猪颜色=%d；黄盆 %d 个，黄色列显示为 %d 的颜色"
			%[chosen, yellow_pots, chosen])
		return _plan(chosen, yellow_type, chosen)
	SortLogger.info("[BonusLevel] 金猪颜色=%d（无黄色盆）" % chosen)
	return _plan(chosen, -1, -1)



static func _pick_plan_v2(level: JuiceLevel, slot_of_type: PackedInt32Array, 
		rng: RandomNumberGenerator) -> Dictionary:
	var pot_counts: Dictionary = _pot_counts(level)
	var screen_counts: Dictionary = _first_screen_pot_counts(level)
	var yellow_type: int = _type_of_slot(slot_of_type, YELLOW_SLOT)
	var yellow_pots: int = int(pot_counts.get(yellow_type, 0)) if yellow_type >= 0 else 0
	var yellow_on_screen: int = int(screen_counts.get(yellow_type, 0)) if yellow_type >= 0 else 0
	if yellow_pots == 1 and yellow_on_screen >= 1:
		return _plan(yellow_type, -1, -1)
	var candidates: Array[int] = _single_pot_candidates(pot_counts, screen_counts)
	if candidates.is_empty():
		var reason: String = REASON_NO_SINGLE_POT if _single_pot_types(pot_counts).is_empty()\
		else REASON_NOT_ON_FIRST_SCREEN
		SortLogger.info("[BonusLevel] 本局跳过奖励关：%s（关卡 %d，%d 种颜色）"
			%["没有只占一盆的颜色" if reason == REASON_NO_SINGLE_POT else "单盆颜色都不在首屏", 
				level.id, level.types])
		return _skip_plan(reason)
	var chosen: int = _pick_candidate(candidates, rng)

	if yellow_type >= 0 and yellow_pots > 0:
		SortLogger.info("[BonusLevel] 金猪颜色=%d；黄盆 %d 个（首屏 %d），黄色列显示为 %d 的颜色"
			%[chosen, yellow_pots, yellow_on_screen, chosen])
		return _plan(chosen, yellow_type, chosen)
	SortLogger.info("[BonusLevel] 金猪颜色=%d（无黄色盆）" % chosen)
	return _plan(chosen, -1, -1)




static func has_bonus_candidate(level: JuiceLevel, v2: bool = false) -> bool:
	if level == null:
		return false
	var pot_counts: Dictionary = _pot_counts(level)
	if not v2:
		return not _single_pot_types(pot_counts).is_empty()
	return not _single_pot_candidates(pot_counts, _first_screen_pot_counts(level)).is_empty()


static func _plan(type_id: int, recolor_from: int, recolor_to: int) -> Dictionary:
	return {"type": type_id, "recolor_from": recolor_from, "recolor_to": recolor_to, 
		"reason": REASON_NONE}


static func _skip_plan(reason: String) -> Dictionary:
	return {"type": NO_BONUS_TYPE, "recolor_from": -1, "recolor_to": -1, "reason": reason}



static func _pick_candidate(candidates: Array[int], rng: RandomNumberGenerator) -> int:
	var picker: RandomNumberGenerator = rng
	if picker == null:
		picker = RandomNumberGenerator.new()
		picker.randomize()
	return candidates[picker.randi_range(0, candidates.size() - 1)]



static func _single_pot_candidates(pot_counts: Dictionary, screen_counts: Dictionary) -> Array[int]:
	var candidates: Array[int] = []
	for key: Variant in pot_counts:
		if int(pot_counts[key]) != 1:
			continue
		if int(screen_counts.get(int(key), 0)) < 1:
			continue
		candidates.append(int(key))
	candidates.sort()
	return candidates



static func _single_pot_types(pot_counts: Dictionary) -> Array[int]:
	var types_with_one: Array[int] = []
	for key: Variant in pot_counts:
		if int(pot_counts[key]) == 1:
			types_with_one.append(int(key))
	return types_with_one



static func _pot_counts(level: JuiceLevel) -> Dictionary:
	var counts: Dictionary = {}
	for jar: int in level.board_jars:
		_count_pot(counts, jar)
	for entry: Dictionary in level.incoming:
		if String(entry.get("slot", "")) == JuiceLevel.SLOT_JAR:
			_count_pot(counts, int(entry.get("jar", JuiceLevel.NO_JAR)))
	return counts



static func _first_screen_pot_counts(level: JuiceLevel) -> Dictionary:
	var counts: Dictionary = {}
	for jar: int in level.board_jars:
		_count_pot(counts, jar)
	return counts


static func _count_pot(counts: Dictionary, type_id: int) -> void :
	if type_id < 0:
		return
	counts[type_id] = int(counts.get(type_id, 0)) + 1



static func _type_of_slot(slot_of_type: PackedInt32Array, slot: int) -> int:
	for type_id: int in slot_of_type.size():
		if slot_of_type[type_id] == slot:
			return type_id
	return -1



static func is_valid_bonus_type(level: JuiceLevel, bonus_type: int) -> bool:
	return level != null and bonus_type >= 0 and bonus_type < level.types
