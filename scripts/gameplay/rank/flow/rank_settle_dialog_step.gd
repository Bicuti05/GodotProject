class_name RankSettleDialogStep
extends FlowStep

func get_step_name() -> String:
	return "RankSettleDialog"

func should_run(ctx) -> bool:
	return RankSessionFlow.is_active(ctx) and RankManager.is_unlocked()

func run(ctx) -> void :
	RankManager.ensure_season()
	var result: Dictionary = RankManager.check_rank_end()
	if not bool(result.get("has_ended", false)):
		return
	if int(result.end_tier) > int(result.start_tier):
		await RankSessionFlow.show_dialog(ctx, "rank_season_win", {
			"end_tier": result.end_tier, "rank_pos": result.rank_pos}, 
			func(win: Node) -> bool: return win.presentation_finished)
	if not RankSessionFlow.is_active(ctx):
		return
	await RankSessionFlow.show_dialog(ctx, "rank_change", result)
	if RankSessionFlow.is_active(ctx):
		RankManager.ensure_season()
