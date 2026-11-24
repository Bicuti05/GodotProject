class_name PlayFinishAdRewardStep
extends FlowStep

func get_step_name() -> String:
	return "FinishPlayAdReward"

func should_run(ctx) -> bool:
	return ctx.granted and is_instance_valid(ctx.page) and is_instance_valid(ctx.panel)\
	and ctx.panel.is_ad_claim_current(ctx.generation)

func run(ctx) -> void :

	ctx.panel.begin_ad_reward_presentation(ctx.generation)
	await ctx.page.play_finish_ad_reward(ctx.panel, ctx.reward, ctx.before, ctx.after)
