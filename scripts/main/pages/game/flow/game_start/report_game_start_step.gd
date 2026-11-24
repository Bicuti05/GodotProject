class_name ReportGameStartStep
extends FlowStep













func get_step_name() -> String:
	return "ReportGameStart"

func should_run(ctx) -> bool:
	return not ctx.aborted

func run(ctx) -> void :
	ctx.page.setup_tracking_context(ctx.level_model, ctx.current_state)

	if bool(ctx.params.get("special_reward_pending", false)):
		return
	ctx.page.report_game_start()
