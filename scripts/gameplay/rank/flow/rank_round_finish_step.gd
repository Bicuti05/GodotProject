class_name RankRoundFinishStep
extends FlowStep

var _result: Dictionary = {}

func get_step_name() -> String:
	return "RankRoundFinish"

func should_run(ctx) -> bool:
	_result = RankManager.take_last_round_result()
	var entity: Dictionary = UserState.get_rank_current_entity()
	return not ctx.aborted and ctx.page.visible and not _result.is_empty() and RankManager.is_valid_rank_in_game() and String(_result.get("event_id", "")) == String(entity.get("event_id", ""))

func run(ctx) -> void :
	var generation: int = ctx.page.get_end_flow_generation()
	var session: Dictionary = {
		"owner": ctx.page, 
		"active": func() -> bool:
			return not ctx.aborted and ctx.page.visible and generation == ctx.page.get_end_flow_generation(), 
	}
	await RankSessionFlow.show_dialog(session, "rank_game_finish", {"result": _result})
	_result = {}
	if not RankSessionFlow.is_active(session):
		ctx.aborted = true
