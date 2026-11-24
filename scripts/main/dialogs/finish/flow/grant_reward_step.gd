class_name GrantRewardStep
extends FlowStep

func get_step_name() -> String:
	return "FinishGrantReward"

func should_run(ctx) -> bool:
	return ctx.rewarded and not ctx.granted and is_instance_valid(ctx.panel)\
	and ctx.panel.is_ad_claim_current(ctx.generation)

func run(ctx) -> void :
	if not should_run(ctx):
		return
	ctx.granted = true
	var kind: String = String(ctx.reward["kind"])
	var count: int = int(ctx.reward["count"])
	ctx.before = UserState.get_coins() if kind == "coins" else UserState.get_prop_count(kind)
	if kind == "coins":
		UserState.add_coins(count)
	else:
		UserState.add_prop_reward_ads(kind, count)
	ctx.after = UserState.get_coins() if kind == "coins" else UserState.get_prop_count(kind)
	ctx.page.report_finish_ad_reward(kind, ctx.after - ctx.before)
