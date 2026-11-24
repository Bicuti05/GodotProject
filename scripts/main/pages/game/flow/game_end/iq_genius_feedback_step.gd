class_name IqGeniusFeedbackStep
extends FlowStep


func get_step_name() -> String:
	return "IqGeniusFeedback"


func run(ctx) -> void :
	if not await ctx.page.show_iq_genius_feedback():
		ctx.aborted = true
