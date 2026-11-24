class_name PrepareCoinBonusLevelStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareCoinBonusLevel"

func should_run(ctx) -> bool:
	return not ctx.aborted

func run(ctx) -> void :
	if not ctx.page.prepare_coin_bonus_level(ctx.current_state):
		ctx.aborted = true
		await ctx.page.return_home()
