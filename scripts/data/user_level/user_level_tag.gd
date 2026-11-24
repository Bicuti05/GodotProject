class_name UserLevelTag
extends RefCounted










const TAG_KEY: = "user_level_v1"






static func on_level_completed(won_level: int) -> void :
	var dirty: bool = UserState.is_current_level_dirty()



	if not dirty and UserState.is_daily_downgrade_level(won_level):
		UserState.settle_downgraded_level_win()
		SortLogger.info("[UserLevelTag] 关 %d 是每日降难度关，干净通关不计入升级计数，等级保持 %s" % [
			won_level, _label(UserState.get_user_level())])
		return
	var old_level: int = UserState.get_user_level()
	var next: Dictionary
	if old_level <= 0:
		if won_level < UserLevelLadder.START_AT_LEVEL_NUM:

			UserState.settle_user_level(old_level, 0, [])
			return

		next = UserLevelLadder.initial_state()
	else:
		var eligible: bool = old_level >= 3 or UserState.has_reached_user_level_3()
		if eligible:

			ABManager.dye_at_difficulty_rule()
		var easy_promotion: bool = eligible and ABManager.difficulty_rule.should_use_easy_promotion()
		var four_losses: bool = eligible and ABManager.difficulty_rule.should_require_four_losses(old_level)
		next = UserLevelLadder.settle(old_level, UserState.get_user_level_clean_streak(), 
			UserState.get_user_level_recent_dirty(), dirty, easy_promotion, four_losses)
	var new_level: int = int(next["level"])
	var window: Array = next["recent_dirty"] as Array
	UserState.settle_user_level(new_level, int(next["clean_streak"]), window)
	if old_level < 3 and new_level >= 3:

		ABManager.dye_at_difficulty_rule()
	SortLogger.info("[UserLevelTag] 关 %d 结算：脏=%s, 等级 %s→%s, 连胜=%d, 窗口=%s" % [
		won_level, dirty, _label(old_level), _label(new_level), 
		int(next["clean_streak"]), window])
	if new_level != old_level:
		_push_tag(new_level)




static func reassert() -> void :
	var level: int = UserState.get_user_level()
	if level <= 0:
		return
	_push_tag(level)


static func _push_tag(level: int) -> void :
	var value: String = UserLevelLadder.tag_value(level)
	if value.is_empty():
		SortLogger.error("[UserLevelTag] 等级越界，不写标签：level=%d" % level)
		return
	UniKitManager.add_local_tag(TAG_KEY, value)



static func _label(level: int) -> String:
	var value: String = UserLevelLadder.tag_value(level)
	return value if not value.is_empty() else "未起步"
