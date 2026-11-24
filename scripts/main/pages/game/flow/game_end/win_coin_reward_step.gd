class_name WinCoinRewardStep
extends FlowStep




func get_step_name() -> String:
	return "WinCoinReward"


func run(ctx) -> void :
	await ctx.page.play_win_coin_reward()
