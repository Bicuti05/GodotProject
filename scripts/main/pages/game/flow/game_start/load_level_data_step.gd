class_name LoadLevelDataStep
extends FlowStep





















func get_step_name() -> String:
	return "LoadLevelData"

func should_run(ctx) -> bool:
	return not ctx.aborted

func run(ctx) -> void :



	var load_source: String = String(ctx.params.get("source", ""))
	var target: Dictionary = LevelManager.get_next_round_descriptor()
	if bool(target["is_special"]):
		var special: Dictionary = LevelManager.load_special_challenge()
		var special_model: LevelModel = ctx.page.apply_level_model(special.get("model") as LevelModel)
		ctx.level_model = special_model
		ctx.current_state = special.get("current_state", {}) as Dictionary
		ctx.params["special_reward_pending"] = bool(special.get("reward_pending", false))
		if bool(ctx.params["special_reward_pending"]):
			ctx.skip_prop_unlock = true
			ctx.skip_opening_banner = true
			ctx.skip_mystery_guide = true
			ctx.skip_lock_guide = true
		if not bool(ctx.params["special_reward_pending"]) and ctx.page.is_dead_resume(ctx.level_model, ctx.current_state):
			ctx.current_state = {}

		_report_local_load(load_source, 
			special_model.chapter_index if special_model != null else -1, 
			special_model.level_index if special_model != null else -1, 
			special_model, TrackingEvents.LEVEL_TYPE_SPECIAL_CHALLENGE)
		return

	var current_level: int = UserState.get_current_level()
	var chapter_index: int = LevelIndex.chapter_of(current_level)
	var level_index: int = LevelIndex.index_of(current_level)

	var resumed: Dictionary = LevelManager.load_resumed_level(current_level)

	if not resumed.is_empty() and LevelManager.is_resume_stale(resumed):
		SortLogger.info("[LoadLevelDataStep] 关号 %d 续局存档超过 12h,丢弃并全新开局" % current_level)
		LevelManager.clear_game_state(current_level, "clear_discard", 
			String(resumed.get("game_id", "")))
		resumed = {}
	if not resumed.is_empty():
		ctx.level_model = ctx.page.apply_level_model(resumed.get("model") as LevelModel)
		ctx.current_state = resumed.get("current_state", {}) as Dictionary

		if ctx.page.is_dead_resume(ctx.level_model, ctx.current_state):
			SortLogger.info("[LoadLevelDataStep] 关号 %d 续局快照是死局,丢弃并重开" % current_level)
			LevelManager.clear_game_state(current_level, "clear_discard", 
				String(resumed.get("game_id", "")))
			UserState.reset_win_streak()
			ctx.current_state = {}

			var restart_model: LevelModel = ctx.page.resolve_restart_model(
				current_level, ctx.level_model)
			if restart_model != ctx.level_model:
				ctx.level_model = ctx.page.apply_level_model(restart_model)

			ctx.page.prepare_dead_resume_restart()
		if not load_source.is_empty():
			_report_game_load(load_source, chapter_index, level_index, {"ok": true})
		return

	LevelManager.apply_content_level_experiments(current_level)

	var load_result: Dictionary = {"ok": true}
	if not LevelManager.check_level_exist(current_level):
		SortLogger.info("[LoadLevelDataStep] 关号 %d(第 %d 章第 %d 关)元数据未命中内存索引,强拉该章"
			%[current_level, chapter_index, level_index])
		ctx.loading = true
		SceneManager.show_loading()
		load_result = await LevelManager.waiting_load_data(chapter_index)
		if ctx.aborted:
			return
		ctx.loading = false
		SceneManager.hide_loading()
		if not bool(load_result.get("ok", false)):
			if not load_source.is_empty():
				_report_game_load(load_source, chapter_index, level_index, load_result)
			ctx.aborted = true

			await ctx.page.return_home()
			return

	var fresh: Dictionary = LevelManager.load_fresh_level(current_level)

	var fresh_model: LevelModel = fresh.get("model") as LevelModel
	if fresh_model != null:
		fresh_model = LevelManager.resolve_daily_downgrade_model(current_level, fresh_model)
	ctx.level_model = ctx.page.apply_level_model(fresh_model)
	if not load_source.is_empty():
		_report_game_load(load_source, chapter_index, level_index, load_result)










func _report_game_load(source: String, chapter_index: int, level_index: int, 
		result: Dictionary, level_type: String = TrackingEvents.LEVEL_TYPE_LEVEL, 
		use_chapter_url: bool = true) -> void :
	var ok: bool = bool(result.get("ok", false))
	var total_url: String = String(result.get("url", ""))
	if total_url.is_empty() and use_chapter_url:
		total_url = LevelManager.chapter_data_url(chapter_index)
	Tracker.send_event(TrackingEvents.EV_GAME_LOAD_MONITOR, {
		TrackingEvents.K_LEVEL_TYPE: level_type, 
		TrackingEvents.K_TOTAL_URL: total_url, 
		TrackingEvents.K_SOURCE: source, 
		TrackingEvents.K_CHAPTER_LEVEL: "%d-%d" % [chapter_index, level_index], 
		TrackingEvents.K_STATE: TrackingEvents.REQ_STATE_SUCCESS if ok else TrackingEvents.REQ_STATE_FAIL, 
		TrackingEvents.K_NET_TYPE: Tracker.net_type(), 
		TrackingEvents.K_COST_TIME: int(result.get("cost_time", 0)), 
		TrackingEvents.K_ERR_MSG: String(result.get("err_msg", "")), 
	})



func _report_local_load(source: String, chapter_index: int, level_index: int, 
		model: LevelModel, level_type: String) -> void :
	if source.is_empty():
		return
	_report_game_load(source, chapter_index, level_index, {"ok": model != null}, 
		level_type, false)
