class_name SpecialChallengeRewardStep
extends FlowStep

func get_step_name() -> String:
	return "SpecialChallengeReward"

func should_run(ctx) -> bool:
	return ctx.page.is_special_challenge()

func run(ctx) -> void :
	if not await ctx.page.await_special_challenge_reward():
		ctx.aborted = true
