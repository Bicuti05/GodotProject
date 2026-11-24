class_name SunlightGuideStep
extends FlowStep


func get_step_name() -> String:
	return "SunlightGuide"


func should_run(ctx) -> bool:
	return ctx.get("aborted") != true and ctx.get("skip_sunlight_guide") != true\
	and not LevelManager.is_end_reached()


func run(ctx) -> void :
	var restore = ctx.get("current_state")
	if not await ctx.page.maybe_show_sunlight_guide(restore if restore is Dictionary else {}):
		ctx.aborted = true
