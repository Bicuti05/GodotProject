class_name MainlineTimedEndlessEntry
extends RefCounted



static func prepare_offer(level: int) -> Dictionary:
	if not TimedEndlessRules.is_anchor(level):
		return {}
	if not TimedEndlessRules.supports_version(String(ProjectSettings.get_setting("application/config/version", ""))):
		return {}
	if UserState.get_pending_level_completion() == level:
		return UserState.get_pending_timed_endless_offer()
	if level <= UserState.get_timed_endless_last_anchor():
		return {}
	ABManager.dye_at_mainline_timed_endless()
	return {"after_level": level, "enabled": ABManager.mainline_timed_endless.is_mainline_timed_endless_enabled()}
