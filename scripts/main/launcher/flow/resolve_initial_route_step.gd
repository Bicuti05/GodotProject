class_name ResolveInitialRouteStep
extends FlowStep


const LEVEL_PROBE_TIMEOUT: float = 3.0

func get_step_name() -> String:
	return "ResolveInitialRoute"

func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	ctx.initial_page = "game"
	ctx.initial_page_reason = "playable"
	if RankManager.has_pending_session():
		ctx.initial_page = "home"
		ctx.initial_page_reason = "rank_session"
	elif bool(LevelManager.get_next_round_descriptor()["is_special"]):
		ctx.initial_page_reason = "special"
	else:
		var level: int = UserState.get_current_level()
		if not LevelManager.is_level_state_resolved(level) or LevelManager.is_end_reached(level):
			if not LevelManager.load_resumed_level(level).is_empty():
				ctx.initial_page_reason = "resume"
			else:
				if not LevelManager.is_level_state_resolved(level):
					await LevelManager.waiting_load_data(LevelIndex.chapter_of(level), LEVEL_PROBE_TIMEOUT)
				if not LevelManager.is_level_state_resolved(level) or LevelManager.is_end_reached(level):
					ctx.initial_page = "home"
					ctx.initial_page_reason = "level_unavailable"
	SceneManager.request_page_threaded(ctx.initial_page)
	SortLogger.info("[Startup] initial_page=%s reason=%s" % [ctx.initial_page, ctx.initial_page_reason])
