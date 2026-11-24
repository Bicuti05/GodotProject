class_name RankNewSeasonDialogStep
extends FlowStep

func get_step_name() -> String:
	return "RankNewSeasonDialog"

func should_run(ctx) -> bool:
	return RankSessionFlow.is_active(ctx) and RankManager.is_unlocked() and not RankManager.is_clock_rolled_back()

func run(ctx) -> void :
	var snap: RankSnapshot = RankManager.get_current_snapshot()
	if not snap.is_valid() or snap.has_guide or RankManager.is_season_ended():
		return
	ABManager.dye_at_enter_rank()
	if not RankManager.activate_update_activity():
		return
	var first_ever: bool = RankManager.is_first_time_rank_ever()

	RankManager.mark_guide_shown()

	var info: Dictionary = RankManager.get_challenge_info_params()
	if not info.is_empty():
		Tracker.track_challenge_info(TrackingEvents.CHALLENGE_STATE_START, info, 
			TrackingEvents.CHALLENGE_POSITION_START)
	if first_ever:
		RankManager.mark_rank_ever_played()
		await RankSessionFlow.show_dialog(ctx, "rank_introduction")
	if not RankSessionFlow.is_active(ctx):
		return
	var dlg: Node = await RankSessionFlow.show_dialog(ctx, "rank_new_season", {"first_ever": first_ever})
	if not RankSessionFlow.is_active(ctx) or dlg == null or not dlg.should_open_rank_on_close():
		return
	var entity: Dictionary = UserState.get_rank_current_entity()
	var start_game: Callable = ctx.get("on_start_game", Callable())
	if not first_ever and RankManager.is_update_activity(entity) and start_game.is_valid():
		start_game.call()
	elif ctx.on_open_rank.is_valid():
		ctx.on_open_rank.call()
