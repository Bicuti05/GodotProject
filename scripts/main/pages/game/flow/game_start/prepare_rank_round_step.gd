class_name PrepareRankRoundStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareRankRound"

func should_run(ctx) -> bool:
	return not ctx.aborted and RankManager.is_unlocked()

func run(ctx) -> void :

	RankManager.ensure_profile()
	RankManager.ensure_season()
