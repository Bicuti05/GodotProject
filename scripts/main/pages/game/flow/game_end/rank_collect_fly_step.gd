class_name RankCollectFlyStep
extends FlowStep

func get_step_name() -> String:
	return "RankCollectFly"

func should_run(ctx) -> bool:
	return not ctx.aborted and ctx.page.visible

func run(ctx) -> void :
	if not await ctx.page.play_rank_collect():
		ctx.aborted = true
