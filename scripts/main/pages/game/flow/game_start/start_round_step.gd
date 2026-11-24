class_name StartRoundStep
extends FlowStep









func get_step_name() -> String:
	return "StartRound"

func should_run(ctx) -> bool:
	return not ctx.aborted

func run(ctx) -> void :
	if not await ctx.page.prepare_round_components(ctx):
		ctx.aborted = true
		return
	if ctx.page.should_run_tutorial_now(ctx.current_state):
		if not await ctx.page.start_tutorial_board(PackedInt32Array(), ctx.current_state):
			ctx.aborted = true
			return
	else:
		var started: bool = await ctx.page.start_round(ctx.current_state)
		if not started:
			ctx.aborted = true
			return
		if ctx.aborted:
			return
		ctx.page.show_fallback_toast_if_needed()
	LevelManager.prefetch_next_chapter_covers(LevelIndex.chapter_of(UserState.get_current_level()))
