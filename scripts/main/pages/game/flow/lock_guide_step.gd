class_name LockGuideStep
extends FlowStep





func get_step_name() -> String:
	return "LockGuide"

func should_run(ctx) -> bool:
	if ctx.get("aborted") == true:
		return false
	if ctx.get("skip_lock_guide") == true:
		return false
	return not LevelManager.is_end_reached()

func run(ctx) -> void :
	var restore = ctx.get("current_state")
	await ctx.page.maybe_show_lock_guide(restore if restore is Dictionary else {})
