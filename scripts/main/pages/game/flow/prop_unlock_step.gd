class_name PropUnlockStep
extends FlowStep




func get_step_name() -> String:
	return "PropUnlock"

func should_run(ctx) -> bool:
	if ctx.get("aborted") == true:
		return false
	if ctx.get("skip_prop_unlock") == true:
		return false
	return not LevelManager.is_end_reached()

func run(ctx) -> void :
	await ctx.page.maybe_show_prop_unlock()
