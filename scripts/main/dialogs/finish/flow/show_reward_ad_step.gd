class_name ShowRewardAdStep
extends FlowStep

func get_step_name() -> String:
	return "FinishShowRewardAd"

func run(ctx) -> void :

	ctx.rewarded = await AdManager.show_reward_ad_and_await("finish_ad_reward")
