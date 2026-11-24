class_name PrepareHomeSourceStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareHomeSource"

func run(ctx) -> void :
	if is_instance_valid(ctx.source) and ctx.source.has_method("begin_home_navigation"):
		await ctx.source.begin_home_navigation()
