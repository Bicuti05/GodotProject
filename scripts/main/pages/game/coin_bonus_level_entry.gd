class_name CoinBonusLevelEntry
extends RefCounted

static func today() -> String:
	return Time.get_date_string_from_system(false)




static func seconds_until_midnight() -> int:
	var time: Dictionary = Time.get_time_dict_from_system(false)
	var elapsed: int = int(time.hour) * 3600 + int(time.minute) * 60 + int(time.second)
	return maxi(86400 - elapsed, 0)


static func preview(model: LevelModel, expose: bool = false, resumed: bool = false) -> Dictionary:
	if model == null or model.is_special_challenge():
		return {}

	if expose and model.level_id >= CoinBonusLevelRules.MIN_LEVEL:
		ABManager.dye_at_coin_bonus_level()
	var saved: Dictionary = (model as JuiceLevelModel).coin_bonus_rule if model is JuiceLevelModel else {}
	var assignment: Dictionary
	if not saved.is_empty():
		assignment = saved.duplicate(true)
	elif resumed:

		assignment = UserState.get_coin_bonus_assignment(model.level_id)
		if assignment.is_empty():
			return {}
	else:
		assignment = CoinBonusLevelRules.preview(UserState.get_coin_bonus_state(), today(), 
			model.level_id, model.difficulty_type, ABManager.coin_bonus_level_rule.get_rule(), 
			ABManager.coin_bonus_level_rule.is_control_group())
	return assignment

static func enter(model: LevelModel, resumed: bool) -> Dictionary:
	var assignment: Dictionary = preview(model, true, resumed)
	if assignment.is_empty() and model != null:

		assignment = {"level": model.level_id, "date": today(), "rule": {}, "double_coins": false, "expose": false}
	if assignment.is_empty() or not UserState.commit_coin_bonus_assignment(assignment):
		return {}
	return UserState.get_coin_bonus_assignment(model.level_id)
