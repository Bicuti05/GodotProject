class_name BonusPigSmashStep
extends FlowStep












func get_step_name() -> String:
	return "BonusPigSmash"


func should_run(ctx) -> bool:
	return ctx.page.is_bonus_level_round()


func run(ctx) -> void :
	await ctx.page.play_bonus_pig_smash()
