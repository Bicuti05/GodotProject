class_name FinishExitStep
extends FlowStep

func get_step_name() -> String:
	return "FinishExit"


func should_run(ctx) -> bool:
	return ctx.next_pressed and ctx.page.visible


func run(ctx) -> void :
	await ctx.page.exit_finish_after_win(ctx.won_level)
