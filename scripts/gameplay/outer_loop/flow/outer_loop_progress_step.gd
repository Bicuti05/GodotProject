class_name OuterLoopProgressStep
extends FlowStep


func get_step_name() -> String:
	return "OuterLoopProgress"

func should_run(_ctx) -> bool:
	return true

func run(ctx) -> void :
	await ctx.home_page.play_outer_loop_progress(ctx.level_won)
