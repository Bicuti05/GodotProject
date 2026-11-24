class_name HomeRankSessionStep
extends FlowStep

func get_step_name() -> String:
	return "HomeRankSession"

func should_run(ctx) -> bool:
	return is_instance_valid(ctx.home_page) and ctx.active.call()

func run(ctx) -> void :
	await ctx.home_page.finish_home_enter(ctx.active)
