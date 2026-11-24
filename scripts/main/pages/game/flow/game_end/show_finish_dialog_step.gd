class_name ShowFinishDialogStep
extends FlowStep















func get_step_name() -> String:
	return "ShowFinishDialog"


func run(ctx) -> void :
	if ctx.aborted or not is_instance_valid(ctx.page) or not ctx.page.is_inside_tree() or not ctx.page.visible:
		ctx.aborted = true
		return
	var generation: int = ctx.page.get_end_flow_generation()
	if not await ctx.page.prepare_finish_ad_reward():
		ctx.aborted = true
		return
	if not is_instance_valid(ctx.page) or not ctx.page.is_inside_tree() or not ctx.page.visible\
	or generation != ctx.page.get_end_flow_generation():
		ctx.aborted = true
		return
	ctx.page.play_celebration()
	ctx.aborted = not await ctx.page.wait_complete_panel_shown(generation)
