class_name OpeningBannerAfterStep
extends FlowStep



func get_step_name() -> String:
	return "OpeningBannerAfter"


func should_run(ctx) -> bool:
	if ctx.get("aborted") == true:
		return false
	if ctx.get("skip_opening_banner") == true:
		return false
	if LevelManager.is_end_reached():
		return false
	return true


func run(ctx) -> void :
	await ctx.page.show_opening_banners(ctx)
