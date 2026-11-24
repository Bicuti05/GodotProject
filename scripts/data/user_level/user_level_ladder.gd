class_name UserLevelLadder
extends RefCounted

















const LEVEL_MIN: = 1
const LEVEL_MAX: = 5

const START_LEVEL: = 2

const START_AT_LEVEL_NUM: = 5


const N_BY_LEVEL: = {1: 2, 2: 2, 3: 3, 4: 5, 5: 5}


const WINDOW_CAP: = 5



static func n_of(level: int) -> int:
	return int(N_BY_LEVEL.get(level, N_BY_LEVEL[START_LEVEL]))



static func tag_value(level: int) -> String:
	if level < LEVEL_MIN or level > LEVEL_MAX:
		return ""
	return "lv%d" % level




static func initial_state() -> Dictionary:
	return {"level": START_LEVEL, "clean_streak": 0, "recent_dirty": []}




static func settle(cur_level: int, clean_streak: int, recent_dirty: Array, dirty: bool, 
		easy_promotion: bool = false, high_tier_four_losses: bool = false) -> Dictionary:
	var level: int = clampi(cur_level, LEVEL_MIN, LEVEL_MAX)
	var n: int = n_of(level)
	var window: Array = recent_dirty.duplicate()
	window.append(dirty)
	while window.size() > WINDOW_CAP:
		window.pop_front()

	var streak: int = 0 if dirty else mini(clean_streak + 1, n)
	var losses: int = dirty_count(window, n)

	var wins: int = mini(window.size(), n) - losses
	var promote: bool = wins * 2 > n if easy_promotion else streak >= n
	var demote: bool = losses >= 4 if high_tier_four_losses and level in [4, 5] else losses * 2 > n
	var new_level: int = level
	if promote and level < LEVEL_MAX:
		new_level = level + 1
	elif demote and level > LEVEL_MIN:
		new_level = level - 1
	if new_level != level:


		return {"level": new_level, "clean_streak": 0, "recent_dirty": []}
	return {"level": level, "clean_streak": streak, "recent_dirty": window}



static func dirty_count(window: Array, n: int) -> int:
	var from: int = maxi(0, window.size() - n)
	var count: int = 0
	for i: int in range(from, window.size()):
		if bool(window[i]):
			count += 1
	return count
