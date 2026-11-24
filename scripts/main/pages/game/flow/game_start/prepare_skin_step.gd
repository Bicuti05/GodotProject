class_name PrepareSkinStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareSkin"

func should_run(ctx) -> bool:
	return not ctx.aborted

func run(ctx) -> void :
	if not await ctx.page.prepare_skin(ctx):
		ctx.aborted = true
