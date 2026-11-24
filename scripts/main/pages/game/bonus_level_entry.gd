class_name BonusLevelEntry
extends RefCounted








static func is_v2_enabled() -> bool:
	return ABManager.is_ab_init_done() and ABManager.bonus_level2.is_enabled()





static func is_next_bonus(level: int, resumed_blob: Dictionary = {}, expose: bool = true, coin_assignment: Dictionary = {}) -> bool:

	if not resumed_blob.is_empty():
		return int(resumed_blob.get("bonus_type", JuiceBonusLevel.NO_BONUS_TYPE)) >= 0
	if not (coin_assignment.get("rule", {}) as Dictionary).is_empty() or (coin_assignment.is_empty() and ABManager.coin_bonus_level_rule.is_coin_bonus_enabled()):
		return false
	if not JuiceBonusLevel.is_bonus_level(level):
		return false


	if expose and ABManager.is_ab_init_done():
		ABManager.dye_at_bonus_level()

	var model: JuiceLevelModel = LevelManager.load_level_content(level) as JuiceLevelModel
	return model != null and JuiceBonusLevel.has_bonus_candidate(model.juice, is_v2_enabled())
