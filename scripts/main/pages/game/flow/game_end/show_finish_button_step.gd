class_name ShowFinishButtonStep
extends FlowStep


func get_step_name() -> String:
	return "ShowFinishButton"


func run(ctx) -> void :
	await ctx.page.show_finish_button()
