class_name ShowMysteryGuideStep
extends FlowStep




func get_step_name() -> String:
	return "ShowMysteryGuide"

func should_run(ctx) -> bool:
	if ctx.get("aborted") == true:
		return false
	if ctx.get("skip_mystery_guide") == true:
		return false
	return not LevelManager.is_end_reached()

func run(ctx) -> void :
	var restore = ctx.get("current_state")
	ctx.page.maybe_show_mystery_guide(restore if restore is Dictionary else {})
