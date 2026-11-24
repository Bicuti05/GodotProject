extends Node

var _failures: Array[String] = []


class MigrationBoard extends JuiceBoardView:
	func set_rank_collectible(type_id: int, index: int, _refresh: bool = true) -> void :
		_rank_collectible_type = type_id if index >= 0 else -1
		var color: StringName = JuiceTheme.COLOR_KEYS[_slots[type_id]] if type_id >= 0 else &""
		_skin_resources.set_rank_collectible(color, index)
		_rebuild_skin_arrays()

func _ready() -> void :
	Engine.max_fps = 60
	call_deferred("_run")

func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		print("FAIL: ", message)

func _model() -> JuiceLevelModel:
	var model: = JuiceLevelModel.new()
	model.raw = {"id": 21, "capacity": 3, "targetCups": 3, 
		"initial": ["0|0,1,1", "1|0,0,1", "2|2,2,2"], "incoming": ["x", "x"]}
	model.juice = JuiceLevel.from_dict(model.raw)
	return model

func _run() -> void :
	_test_sources()
	_test_activity()
	_test_models()
	_test_gift_style_fallbacks()
	_test_gift_ribbons()
	_test_activity_alignment()
	_test_column_count()
	_test_column_count_bots()
	_test_column_count_competition()
	await _test_gift_style_flights()
	await _test_collectible_questions()
	await _test_views()
	if _failures.is_empty():
		print("RANK_COLLECTIBLE_FX PASS")
	else:
		print(_failures)
	get_tree().quit(0 if _failures.is_empty() else 1)

func _test_sources() -> void :
	var config: RankCollectibleFxConfig = ABManager.rank_collectible_fx
	config.load_value_silent()
	_check(config.is_collectible_replacement_enabled(), "SDK yes enables replacement")
	ABManager.fx_raw = "unknown"
	config.peek_sdk_value()
	_check(config.is_collectible_replacement_enabled(), "preview does not change cached SDK source")
	config.load_value_silent()
	_check( not config.is_collectible_replacement_enabled() and not config.is_original_collectible_enabled(), "unknown is baseline")
	config.set_debug_override(1)
	_check(config.is_collectible_replacement_enabled(), "legal Cheat precedes SDK fallback")
	config.set_debug_override(9)
	_check( not config.is_collectible_replacement_enabled(), "unknown Cheat is baseline")
	config.clear_debug_override()
	ABManager.fx_raw = "no"
	config.load_value_silent()
	_check(config.is_original_collectible_enabled(), "SDK no is actual control")
	ABManager.fx_raw = "column_count"
	config.load_value_silent()
	_check(config.value() == 2 and config.is_column_count_enabled() and config.is_collectible_replacement_enabled()
		and not config.is_original_collectible_enabled(), "SDK column_count uses group two and shared gift presentation")
	ABManager.fx_raw = "yes"
	config.peek_sdk_value()
	_check(config.is_column_count_enabled(), "preview does not overwrite column-count source")
	ABManager.fx_hit = false
	config.load_value_silent()
	_check( not config.is_column_count_enabled() and not config.is_collectible_replacement_enabled(), "invalid SDK source is baseline")
	config.set_debug_override(2)
	ABManager._startup_control_locked = true
	_check(config.is_column_count_enabled(), "legal group-two Cheat precedes startup lock")
	config.clear_debug_override()
	_check( not config.is_column_count_enabled(), "startup lock cannot claim group two")
	ABManager._startup_control_locked = false
	ABManager.fx_hit = true
	ABManager.fx_raw = "no"
	config.load_value_silent()
	ABManager._startup_control_locked = true
	_check( not config.is_original_collectible_enabled(), "startup lock does not claim control identity")
	ABManager._startup_control_locked = false
	ABManager.fx_raw = "yes"
	config.load_value_silent()

func _entity(id: String) -> Dictionary:
	var now: int = RankManager._now_ms()
	return {"event_id": id, "start_time": now, "end_time": now + 172800000, 
		"has_guide": false, "has_receive_bonus": false, "update_mode": "old", "bots": []}

func _commit_entity(entity: Dictionary) -> void :
	UserState.commit_rank_entity(entity)
	RankManager.invalidate_snapshot()

func _test_activity() -> void :
	var old: Dictionary = _entity("existing")
	_commit_entity(old)
	var count: int = ABManager.fx_calls.size()
	RankManager.activate_update_activity()
	_check(RankManager.get_collectible_index() == -1 and ABManager.fx_calls.size() == count, "existing activity neither dyes nor replaces")
	var previous: Dictionary = old
	for i: int in 6:
		var next: Dictionary = _entity("new_%d" % i)
		RankManager._prepare_collectible_activity(next, previous)
		_commit_entity(next)
		_check(RankManager.get_collectible_index() == -1, "hidden creation has no new collectible")
		_check(RankManager.activate_update_activity(), "activity starts")
		_check(RankManager.get_collectible_index() == i % 5, "five collectible rotation including wraparound")
		var frozen: Dictionary = UserState.get_rank_current_entity()
		RankManager.activate_update_activity()
		_check(UserState.get_rank_current_entity() == frozen, "reentry keeps activity identity")
		previous = frozen
	var failing: Dictionary = _entity("retry")
	RankManager._prepare_collectible_activity(failing, previous)
	_commit_entity(failing)
	UserState.reject_rank_save = true

	var before: Dictionary = UserState.get_rank_current_entity()
	_check( not RankManager.activate_update_activity(), "save failure is reported")
	_check(UserState.get_rank_current_entity() == before, "save failure keeps pending activity and cycle")
	UserState.reject_rank_save = false
	_check(RankManager.activate_update_activity() and RankManager.get_collectible_index() == 1, "retry keeps same next style")
	ABManager.rank_collectible_fx.set_debug_override(0)
	_check(RankManager.get_collectible_index() == 1, "changing AB cannot replace an existing activity")
	ABManager.rank_collectible_fx.clear_debug_override()
	ABManager.rank_collectible_fx.set_debug_override(2)
	var column_activity: Dictionary = _entity("column_activity")
	column_activity["bots"] = RankFakeUserGenerator.generate_bots("column_activity", 2, 3)
	RankManager._prepare_collectible_activity(column_activity, UserState.get_rank_current_entity())
	_commit_entity(column_activity)
	UserState.reject_rank_save = true
	var before_column: Dictionary = UserState.get_rank_current_entity()
	_check( not RankManager.activate_update_activity() and UserState.get_rank_current_entity() == before_column, 
		"failed column activity start rolls back both reward mode and bot flags")
	UserState.reject_rank_save = false
	_check(RankManager.activate_update_activity(), "column activity starts")
	var frozen_column: Dictionary = UserState.get_rank_current_entity()
	_check(bool(frozen_column.collectible_column_count) and int(frozen_column.collectible_index) == 2, 
		"column activity freezes group two and continues the shared style cycle")
	for bot: Dictionary in frozen_column.bots:
		_check(bool(bot.collectible_column_count), "column reward mode applies to every bot")
	ABManager.rank_collectible_fx.set_debug_override(1)
	RankManager.activate_update_activity()
	_check(UserState.get_rank_current_entity() == frozen_column, "group-one override cannot change running group-two activity")
	var next_target: Dictionary = _entity("target_activity")
	RankManager._prepare_collectible_activity(next_target, frozen_column)
	_commit_entity(next_target)
	RankManager.activate_update_activity()
	_check( not bool(UserState.get_rank_current_entity().collectible_column_count) and RankManager.get_collectible_index() == 3, 
		"next group-one activity restores target counting and continues rotation")
	ABManager.rank_collectible_fx.clear_debug_override()
	UserState._rank_unlocked = true

func _test_column_count() -> void :
	var previous: Dictionary = UserState.get_rank_current_entity()
	var activity: Dictionary = _entity("column_round")
	activity["has_guide"] = true
	activity["collectible_index"] = 1
	activity["collectible_column_count"] = true
	_commit_entity(activity)
	var model: = JuiceLevelModel.new()
	model.raw = {"id": 21, "capacity": 6, "targetCups": 3, 
		"initial": ["0|0,0,0,0,0,0", "1|1,1,1,1,1", "2|2,2,2,2"], "incoming": ["x", "x"], 
		"columnCaps": {"initial": [6, 5, 4], "incoming": [0, 0]}}
	model.juice = JuiceLevel.from_dict(model.raw)
	_check(model.juice.validate().is_empty(), "variable-capacity column fixture is valid")

	model.rank_collectible_rule = {"type": 1, "collectible_index": 1, "season_id": "column_round"}
	var board: = JuiceBoardView.new()
	board._level = model.juice
	board._state = JuiceRules.make_state(model.juice)
	var page: = JuiceGamePage.new()
	page._level_model = model
	page._board = board
	var count: int = page._rank_collect_count(model.juice)
	_check(count == 5, "column reward uses selected pot capacity, not global capacity or target count")
	var saved: Dictionary = JSON.parse_string(JSON.stringify({"rank_collectible_rule": model.rank_collectible_rule}))
	model.rank_collectible_rule = {}
	page._restore_rank_collectible_rule(saved)
	_check(page._rank_collect_count(model.juice) == 5 and int(model.rank_collectible_rule.type) == 1, 
		"resume and restart retain selected column reward")
	ABManager.rank_collectible_fx.set_debug_override(0)
	_check(page._rank_collect_count(model.juice) == 5, "player reward ignores live AB changes")
	ABManager.rank_collectible_fx.clear_debug_override()
	var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
	var fly: RankCollectFlyLayer = load("res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn").instantiate()
	add_child(bar)
	add_child(fly)
	page._rank_round.begin({}, count, bar, fly)
	_check(page._rank_round.commit("column_win") and page._rank_round.awarded == 5
		and RankManager.get_collect_num() == 5, "production tracker commits exactly the column reward")
	_check(page._rank_round.commit("column_win") and RankManager.get_collect_num() == 5, "column score remains idempotent")
	activity["collectible_column_count"] = false
	_commit_entity(activity)
	_check(page._rank_collect_count(model.juice) == 3, "group one retains original target reward")
	activity.erase("collectible_column_count")
	_commit_entity(activity)
	_check(page._rank_collect_count(model.juice) == 3, "legacy activity retains original target reward")
	activity["collectible_column_count"] = true
	_commit_entity(activity)
	page._tutorial_active = true
	model.rank_collectible_rule = {}
	_check(page._rank_collect_count(model.juice) == 3, "tutorial without replacement retains original reward")
	page._tutorial_active = false
	model.rank_collectible_rule = {}
	model.juice.jar_seq = [0, 0, 0]
	_check(page._rank_collect_count(model.juice) == 3, "no single-pot candidate retains original reward")
	page.free()
	board.free()
	bar.queue_free()
	fly.queue_free()
	_commit_entity(previous)

func _test_column_count_bots() -> void :
	for mode: String in ["old", "new_24", "new_48"]:
		var entity: Dictionary = RankSnapshotBuilder.create_entity("column_bots", 1000, 1000 + 172800000, 3, 49, mode)
		for original: Dictionary in entity.bots:
			var bot: Dictionary = original.duplicate(true)
			bot["collectible_column_count"] = true
			for elapsed: int in [0, 1, 60, 899, 900, 3600, 86400, 172800, 10000000]:
				var control: Dictionary = RankFakeUserGenerator.get_collect_progress_at(original, elapsed)
				var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, elapsed)
				for field: String in ["collect_num", "completed_levels", "next_level_id", "next_target", "remaining_budget", "collect_budget"]:
					_check(progress[field] == control[field], "column rewards preserve %s %s at %d" % [mode, field, elapsed])
				_check(int(progress.next_reward) >= 4 and int(progress.next_reward) <= 6, "each bot completion rewards four to six")
				_check(RankFakeUserGenerator.get_collect_count_at(bot, elapsed) == int(progress.reward_collect_num), "snapshot uses actual reward")
				var restored: Dictionary = JSON.parse_string(JSON.stringify(bot))
				_check(RankFakeUserGenerator.get_collect_count_at(restored, elapsed) == int(progress.reward_collect_num), "bot rewards survive restart")
				var bonus: Dictionary = RankFakeUserGenerator.resolve_collect_level_bonus(bot, elapsed, 1)
				var original_bonus: Dictionary = RankFakeUserGenerator.resolve_collect_level_bonus(original, elapsed, 1)
				_check(bonus.budget_delta == original_bonus.budget_delta and bonus.completed_levels == original_bonus.completed_levels, 
					"catch-up consumes identical budget and simulated completions")
				_check(int(bonus.bonus) >= 4 and int(bonus.bonus) <= 6, "one catch-up completion rewards four to six")
				bot["bonus_budget"] = int(bot.get("bonus_budget", 0)) + int(bonus.budget_delta)
				if not bot.has("update_duration_seconds"):
					_check(RankFakeUserGenerator.get_collect_count_at(bot, elapsed) == int(progress.reward_collect_num) + int(bonus.bonus), 
						"catch-up score records reward once, not original budget")
				bot["bonus_budget"] = int(original.get("bonus_budget", 0))
	print("COLUMN_COUNT_BOTS: old/new_24/new_48 budgets and completion timing preserved")

func _test_column_count_competition() -> void :
	var bot: Dictionary = RankFakeUserGenerator.generate_bot("column_competition", 3, 0, {})
	RankUpdateRule.configure_bots([bot], 172800, "column_competition", 3)
	bot["collectible_column_count"] = true
	bot["update_early_budget"] = int(bot.update_initial_budget)
	bot["update_floor_budget"] = int(bot.update_initial_budget)
	var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, 0)
	var current: int = int(progress.reward_collect_num)
	var entity: Dictionary = {"event_id": "column_competition", "bots": [bot], "scored_round_count": 5, 
		"collect_num": current + 2, "update_wave": {"members": [0], "start_round": 3, "next_round": 5}}
	var rows: Array = RankSettleLogic.build_ranked_rows(int(entity.collect_num), "player", 1, [bot], 0)
	_check(RankUpdateRule.prepare_round(entity, rows, 0, "column_competition_round", 6), "column competition prepares")
	_check(bot.has("update_pending_budget"), "competition compares reduced score while using original budget")
	if bot.has("update_pending_budget"):
		_check(int(bot.update_pending_budget) == int(progress.collect_num) + int(progress.next_target), "competition advances one original-budget target")
		var ready: int = int(bot.update_ready_seconds)
		_check(ready >= 30 and ready <= 90, "competition delay remains thirty to ninety seconds")
		_check(RankFakeUserGenerator.get_collect_count_at(bot, ready - 1) == current, "competition cannot award early")
		_check(RankFakeUserGenerator.get_collect_count_at(bot, ready) - current == int(progress.next_reward), "competition awards four to six at original completion time")
		var frozen: Dictionary = entity.duplicate(true)
		_check( not RankUpdateRule.prepare_round(entity, rows, 0, "column_competition_round", 6) and entity == frozen, "competition replay does not reschedule")

func _test_models() -> void :
	var model: JuiceLevelModel = _model()
	_check(model.juice.validate().is_empty(), "valid fixture")
	_check(model.rank_collectible_candidates() == [0, 1, 2], "single-pot colors")
	_check(model.rank_collectible_candidates(1) == [0, 2], "bonus excluded")
	model.juice.jar_seq.append(1)
	_check( not model.rank_collectible_candidates().has(1), "multi-pot colors excluded")
	model = _model()
	model.rank_collectible_rule = {"type": 1, "collectible_index": 2, "season_id": "frozen"}
	var copy: JuiceLevelModel = model.duplicate_model() as JuiceLevelModel
	_check(copy.rank_collectible_rule == model.rank_collectible_rule, "model copy freezes identity")
	var restored: = JuiceLevelModel.new()
	restored.from_dict(JSON.parse_string(JSON.stringify(model.to_dict())))
	_check(int(restored.rank_collectible_rule.type) == 1 and restored.rank_collectible_candidates() == [0, 1, 2], "JSON restores type and candidates")
	model.juice.sunlight_type = 2
	_check( not model.rank_collectible_candidates().has(2), "sunlight excluded")

func _test_activity_alignment() -> void :
	var previous: Dictionary = UserState.get_rank_current_entity()
	var current: Dictionary = _entity("current_activity")
	current["has_guide"] = true
	current["update_mode"] = "new_24"
	current["collectible_index"] = 1
	_commit_entity(current)
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var model: = JuiceLevelModel.new()
	model.raw = {"id": 21, "capacity": 3, "targetCups": 3, 
		"initial": ["0|0,0", "1|1,1", "2|2,2", "-|0,1,2"], "incoming": ["x", "x"]}
	model.juice = JuiceLevel.from_dict(model.raw)
	model.rank_collectible_rule = {"type": 1, "collectible_index": 0, "season_id": "old_activity"}
	var board: = MigrationBoard.new()
	board._level = model.juice
	board._state = JuiceRules.make_state(model.juice)
	var parking_col: int = (board._state["jars"] as Array).find(JuiceLevel.NO_JAR)
	board._history.append(JuiceRules.clone_state(board._state))
	_check( not JuiceRules.apply_move(board._state, model.juice, parking_col, 2, 
		(board._state["jars"] as Array).find(2)).is_empty(), "fixture first move uses actual original column order")
	board._history.append(JuiceRules.clone_state(board._state))
	_check( not JuiceRules.apply_move(board._state, model.juice, parking_col, 1, 
		(board._state["jars"] as Array).find(1)).is_empty(), "fixture second move uses actual original column order")
	board._slots = PackedInt32Array([0, 6, 4])
	var resolver: = JuiceSkinResolver.new(base, base)
	board._skin_resources = resolver
	var state_before: Dictionary = JuiceRules.clone_state(board._state)
	var history_before: Array = board._history.duplicate(true)
	var quota: JuiceQuotaBar = load("res://scripts/gameplay/juice_sort/view/juice_quota_bar.tscn").instantiate()
	var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
	var fly: RankCollectFlyLayer = load("res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn").instantiate()
	add_child(quota)
	add_child(bar)
	add_child(fly)
	quota.setup(3)
	var page: = JuiceGamePage.new()
	page._level_model = model
	page._board = board
	page._quota = quota
	page._skin_resources = resolver
	page._rank_round.begin({"rank_round": {"season_id": "old_activity", "collectible_index": 0}}, 3, bar, fly)
	_check(page._rank_round.season_id == "current_activity" and page._rank_round.collectible_index == 1, 
		"rebound new activity ignores old round collectible index")
	page._configure_rank_collectible(true)
	page._refresh_skin_quota()
	_check(int(model.rank_collectible_rule.collectible_index) == 1 and String(model.rank_collectible_rule.season_id) == "current_activity", 
		"saved collectible rule follows current tree activity")
	_check(resolver.color_visual(&"blue", &"element").texture == base.rank_collectible_elements[1].texture, 
		"saved logical type resolves current tree artwork")
	_check(board._state == state_before and board._history == history_before, 
		"activity appearance migration preserves board and undo history")
	_check(page._rank_gift_slot == 1 and quota._texs[1] == base.rank_collectible_targets[1].texture, 
		"already collected gift retains its original order slot")
	_check(bar._icon.texture == base.rank_collectible_elements[1].texture, 
		"finish collection icon agrees with the activity")
	current["collectible_index"] = -1
	_commit_entity(current)
	page._configure_rank_collectible(true)
	page._refresh_skin_quota()
	_check(int(model.rank_collectible_rule.collectible_index) == -1 and page._rank_collectible_type == -1, 
		"current original collectible restores old replaced flowers")
	_check(quota._texs[1] == resolver.color_visual(&"blue", &"target_icon").texture, 
		"current original activity restores the already collected flower pot icon")
	current["collectible_index"] = 2
	_commit_entity(current)
	model.rank_collectible_rule = {"type": -1, "collectible_index": -1, "season_id": "original_activity"}
	page._configure_rank_collectible(true)
	_check(page._rank_collectible_type == 0 and int(model.rank_collectible_rule.collectible_index) == 2, 
		"old original round selects its remaining single-pot color for the new activity")
	var frozen: Dictionary = model.rank_collectible_rule.duplicate(true)
	page._configure_rank_collectible(true)
	_check(model.rank_collectible_rule == frozen and board._state == state_before and board._history == history_before, 
		"same activity reentry preserves migrated choice and gameplay")
	var saved_snapshot: Dictionary = JSON.parse_string(JSON.stringify({"rank_collectible_rule": frozen, 
		"rank_round": page._rank_round.snapshot()}))
	model.rank_collectible_rule = {"type": 1, "collectible_index": 0, "season_id": "old_raw_level_info"}
	page._restore_rank_collectible_rule(saved_snapshot)
	page._configure_rank_collectible(true)
	_check(int(model.rank_collectible_rule.type) == 0 and int(model.rank_collectible_rule.collectible_index) == 2, 
		"latest current snapshot overrides stale frozen model appearance")
	_check(board._state == state_before and board._history == history_before, 
		"reloading migrated snapshot does not change gameplay or history")
	current["update_mode"] = "old"
	_commit_entity(current)
	page._rank_round.begin({"rank_round": {"season_id": "old_score_activity", "collectible_index": 3}}, 3, bar, fly)
	_check(page._rank_round.season_id == "old_score_activity" and page._rank_round.collectible_index == 2, 
		"original scoring policy retains old activity while display uses current collectible")
	_check(page._rank_round.commit("old_round") and not page._rank_round.applied, 
		"display migration does not add old-activity points to original-mode activity")
	page.free()
	board.free()
	quota.queue_free()
	bar.queue_free()
	fly.queue_free()
	_commit_entity(previous)

func _test_gift_style_fallbacks() -> void :
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var expected_names: Array[String] = ["gift_elk.png", "gift_tree.png", "gift_snow.png", "gift_gingerbread.png", "gift_bell.png"]
	var pool: RankCollectElementPool = load("res://scripts/gameplay/rank/view/rank_collect_element_pool.tscn").instantiate()
	_check(base.rank_collectible_elements.size() == 5 and base.rank_collectible_targets.size() == 5, 
		"all five collectibles have matching completed gifts")
	_check(JuiceSkinResolver.validate(base, &"default", true).is_empty(), "five-gift default skin validates")
	for style: int in 5:
		_check(pool.get_texture_for_index(style) == base.rank_collectible_elements[style].texture, 
			"ranking pool and gameplay resolve the same collectible, including the fifth style")
	_check(pool.get_texture_for_index(5) == pool.fixed_texture, "invalid ranking style retains original fallback")
	pool.free()
	for id: String in ["default", "cat", "bird"]:
		var selected: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/%s.tres" % id)
		var resolver: = JuiceSkinResolver.new(base, selected)
		for style: int in 5:
			resolver.set_rank_collectible(&"red", style)
			var expected: JuiceSkinVisual = base.rank_collectible_targets[style]
			_check(expected.texture.resource_path.get_file() == expected_names[style], "gift artwork matches style")
			for field: StringName in [&"completed_container", &"target_icon", &"lock_icon"]:
				_check(resolver.color_visual(&"red", field) == expected, "%s %s selects matching gift" % [id, field])
			_check(resolver.color_visual(&"red", &"empty_container") == base.rank_collectible_container, "empty gift remains shared")
			_check(expected.content_rect == base.rank_collectible_target.content_rect
				and expected.bottom_anchor == base.rank_collectible_target.bottom_anchor, "all gift styles preserve target geometry")
	var sparse: = JuiceSkinDefinition.new()
	sparse.id = &"sparse"
	sparse.rank_collectible_targets = [null, base.rank_collectible_targets[2]]
	var resolver: = JuiceSkinResolver.new(base, sparse)
	resolver.set_rank_collectible(&"red", 1)
	_check(resolver.rank_collectible_visual(&"target_icon") == sparse.rank_collectible_targets[1], "current skin specific gift wins")
	resolver.set_rank_collectible(&"red", 0)
	_check(resolver.rank_collectible_visual(&"target_icon") == base.rank_collectible_targets[0], "null target falls back to default")
	resolver.set_rank_collectible(&"red", 3)
	_check(resolver.rank_collectible_visual(&"target_icon") == base.rank_collectible_targets[3], "short target array falls back to matching default")
	sparse.rank_collectible_target = base.rank_collectible_target
	_check(resolver.rank_collectible_visual(&"target_icon") == sparse.rank_collectible_target, "legacy current skin common target remains supported")
	_check(JuiceSkinResolver.validate(sparse, &"sparse").is_empty(), "sparse gift configuration validates")
	sparse.rank_collectible_targets = [JuiceSkinVisual.new()]
	_check( not JuiceSkinResolver.validate(sparse, &"sparse").is_empty(), "gift without texture is rejected")
	sparse.rank_collectible_targets = [null, null, null, null, null, null]
	_check( not JuiceSkinResolver.validate(sparse, &"sparse").is_empty(), "oversized gift configuration is rejected")

func _test_gift_ribbons() -> void :
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var fields: Array[StringName] = [&"rope_top", &"rope_mid", &"rope_bottom"]
	var visuals: Array[JuiceSkinVisual] = [base.rank_collectible_rope_top, base.rank_collectible_rope_mid, base.rank_collectible_rope_bottom]
	for id: String in ["default", "cat", "bird"]:
		var selected: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/%s.tres" % id)
		var resolver: = JuiceSkinResolver.new(base, selected)
		var board: = MigrationBoard.new()
		board._skin_resources = resolver
		board._slots = PackedInt32Array([0, 1])
		for style: int in 5:
			board.set_rank_collectible(0, style)
			_check(board._rank_rope_skin(0) == base and board._rank_rope_skin(1) == null
				and board._rank_rope_skin(-1) == null, "%s only selected gift column uses ribbon" % id)
			for i: int in fields.size():
				_check(resolver.color_visual(&"red", fields[i]) == visuals[i], "all five gifts share three ribbon segments")
				_check(resolver.color_visual(&"purple", fields[i]) == resolver.original_color_visual(&"purple", fields[i]), 
					"other color retains original rope")
			_check(board._rope_mid_tex(-1) == resolver.single_visual(&"parking_rope_mid").texture, "parking and drag retain white rope")

		for columns: int in [3, 5, 7, 10]:
			board._lay.solve(Rect2(0, 0, 1080, 1400), columns, 5, board._skin)
			for cap: int in [3, 4, 5]:
				for dy: float in [0.0, 0.49, 0.51, 701.4, -0.51]:
					var span: Vector2 = board._rope_reference_visible_span(0, dy, cap)
					var raw_w: float = maxf(4.0, board._lay.rope_scale_d * board._skin.rope_tex_w_ratio)
					var step: float = maxf(roundf(base.rank_collectible_rope_body_rows.y * raw_w / visuals[0].texture.get_width()), 1.0)
					var k: float = step / base.rank_collectible_rope_body_rows.y
					var joins: Vector3 = board._ribbon_join_y(span, base, k)
					var actual_top: float = joins.x + visuals[0].source_bounds.position.y\
					* (joins.y - joins.x) / base.rank_collectible_rope_body_rows.x
					var actual_bottom: float = joins.z + visuals[2].source_bounds.end.y * k
					_check(absf(actual_top - span.x) < 0.001 and absf(actual_bottom - span.y) < 0.001, 
						"ribbon visible endpoints match original column, including capacity and row shift")
					_check(is_equal_approx(joins.y, roundf(joins.y)) and joins.z > joins.y, "integer seam leaves positive tiled middle")
					var rest: float = fposmod(joins.z - joins.y, step)
					_check(rest / k <= base.rank_collectible_rope_body_rows.y, "cropped last tile remains within source rows")
		board.set_rank_collectible(-1, -1)
		_check(resolver.rank_collectible_rope_skin() == null and board._rank_rope_skin(0) == null, "clear disables ribbon geometry")
		for field: StringName in fields:
			_check(resolver.color_visual(&"red", field) == resolver.original_color_visual(&"red", field), "clear restores original rope resources")
		board.free()
	var sparse: = JuiceSkinDefinition.new()
	sparse.id = &"sparse"
	var resolver: = JuiceSkinResolver.new(base, sparse)
	resolver.set_rank_collectible(&"red", 4)
	_check(resolver.rank_collectible_rope_skin() == base, "missing ribbon falls back with its dimensions")
	sparse.rank_collectible_rope_top = visuals[0]
	_check(resolver.rank_collectible_rope_skin() == base, "incomplete trio cannot mix skin dimensions")
	_check( not JuiceSkinResolver.validate(sparse, &"sparse").is_empty(), "partial ribbon configuration is rejected")
	sparse.rank_collectible_rope_mid = visuals[1]
	sparse.rank_collectible_rope_bottom = visuals[2]
	sparse.rank_collectible_rope_body_rows = base.rank_collectible_rope_body_rows
	_check(resolver.rank_collectible_rope_skin() == sparse and JuiceSkinResolver.validate(sparse, &"sparse").is_empty(), "complete current skin ribbon wins")
	sparse.rank_collectible_rope_body_rows.y = 89.0
	_check( not JuiceSkinResolver.validate(sparse, &"sparse").is_empty(), "repeat rows outside texture are rejected")

func _test_gift_style_flights() -> void :
	var page: JuiceGamePage = load("res://scripts/main/pages/game/juice_game_page.tscn").instantiate()
	add_child(page)
	var active: Callable = func() -> bool: return true
	for style: int in [0, 1, 2, 3, 4, 1]:
		var count: int = 12 if style == 1 else 3
		var ready: bool = await page.prepare_rank_collectible_motion_preview(style, count, true, active)
		_check(ready, "gift fixture prepares")
		if not ready:
			page.queue_free()
			return
		var resources: JuiceSkinResolver = page._skin_resources
		var expected: Texture2D = resources.default_skin.rank_collectible_targets[style].texture
		_check(page._board.target_icon_for_type(0) == expected and page._board._texture_for_full_blender(0) == expected, 
			"board completion and quota icon agree with selected style")
		var source: Dictionary = {}
		var on_collect: Callable = func(_type: int, nth: int, _color: Color, rect: Rect2) -> void :
			source.rect = rect
			source.slot = nth
		page._board.cup_collected.connect(on_collect)
		_check(page._board.try_move(1, 0, 0), "selected collectible completes through real move")
		for beat: Dictionary in page._board._beats:
			for fruit: JuiceFruit in beat["nodes"]:
				_check(fruit._body.texture == resources.default_skin.rank_collectible_elements[style].texture, 
					"every element entering gift uses selected style")
		while source.is_empty() and page._board.is_busy():
			await get_tree().process_frame
		page._board.cup_collected.disconnect(on_collect)
		_check( not source.is_empty(), "completed move emits gift source")
		if source.is_empty():
			page.queue_free()
			return

		page._start_rank_gift_flight(int(source.slot), source.rect)
		var rec: Dictionary = page._cup_flights.back()
		_check(rec.tex == expected and rec.gift_visual._filled_texture == expected, "production flight uses selected filled gift")
		(rec.tw as Tween).set_speed_scale(4.0)
		await (rec.tw as Tween).finished
		_check(page._quota.filled_count() == count and page._quota._texs.back() == expected, 
			"production landing preserves count and selected quota artwork")
		_check(page._cup_flights.is_empty(), "landed gift is recycled")
		page._start_rank_gift_flight(count - 1, source.rect)
		var cancelled: Tween = page._cup_flights.back().tw
		page._cancel_cup_flights()
		_check( not cancelled.is_valid() and page._cup_flights.is_empty(), "style replay cancels old production flight")
	page.cancel_rank_motion_preview()
	page.queue_free()
	await get_tree().process_frame

func _test_views() -> void :
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var resolver: = JuiceSkinResolver.new(base, base)
	var old: Texture2D = resolver.color_visual(&"red", &"element").texture
	resolver.set_rank_collectible(&"red", 2)
	_check(resolver.color_visual(&"red", &"element").texture == base.rank_collectible_elements[2].texture, "selected color uses snow")
	_check(resolver.color_visual(&"blue", &"element").texture != base.rank_collectible_elements[2].texture, "other colors keep artwork")
	var quota: JuiceQuotaBar = load("res://scripts/gameplay/juice_sort/view/juice_quota_bar.tscn").instantiate()
	add_child(quota)
	quota.apply_skin(resolver)
	quota.setup(3)
	var gift: Texture2D = resolver.color_visual(&"red", &"target_icon").texture
	quota.push_sunlight_round_cup(1, gift, Color.WHITE)
	quota.push_sunlight_round_cup(2, old, Color.WHITE, true)
	quota.push_sunlight_round_cup(0, old, Color.WHITE)
	_check(quota._texs.size() == 3 and quota._texs[1] == gift and quota._hidden_completed_slots == [2], "out-of-order gift and bonus preserve indices")
	quota.set_cups([old] as Array[Texture2D], PackedColorArray([Color.WHITE]))
	_check(quota._texs.size() == 1 and quota._arrived_sunlight_round_cups.is_empty(), "undo clears pending arrivals")
	_test_arrival_modes(quota, old)
	var fly_layer: = Node2D.new()
	add_child(fly_layer)
	var flight: = JuiceRankGiftFlight.new()
	flight.prepare(gift)
	fly_layer.add_child(flight)
	var cancelled_tween: Tween = flight.play(Rect2(0, 100, 180, 180), func() -> Rect2: return quota.cup_global_rect(0, gift), Vector4(0.16, 0.18, 0.25, 0.45), 40.0, 0.0)
	await get_tree().process_frame
	flight.reset_now()
	_check( not flight.visible and flight.tween == null, "cancel hides gift and clears tween")
	_check( not cancelled_tween.is_valid(), "cancel kills old gift tween")
	flight.play(Rect2(0, 100, 180, 180), func() -> Rect2: return quota.cup_global_rect(0, gift), Vector4(0.01, 0.01, 0.01, 0.01), 40.0, 0.0)
	await flight.tween.finished
	_check(flight.visible and flight.position.distance_to(quota.cup_global_rect(0, gift).get_center()) < 0.01, "gift replay lands at real quota geometry")

	quota.set_cups([old, gift, old] as Array[Texture2D], PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE]))
	var board: = JuiceBoardView.new()
	board._skin_resources = resolver
	board._slots = PackedInt32Array([0, 6, 4])
	var page: = JuiceGamePage.new()
	page._board = board
	page._quota = quota
	page._rank_collectible_type = 0
	page._rank_gift_slot = 1
	page._prop_ad_in_flight = true
	page.start_endless()
	_check(page._rank_collectible_type == 0 and resolver.rank_collectible_index == 2, 
		"rejected endless entry preserves the finite round collectible")
	page._prop_ad_in_flight = false
	var source_started: int = Time.get_ticks_usec()
	for index: int in 12:
		_check(( await page._rank_collect_source(index)).distance_to(quota.cup_global_rect(1, gift).get_center()) < 0.01, "every source comes from gift")
	_check(Time.get_ticks_usec() - source_started < 100000, "visible gift source does not add a scroll wait per item")
	var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
	var collect_fly: RankCollectFlyLayer = load("res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn").instantiate()
	add_child(bar)
	add_child(collect_fly)
	var owner: = Control.new()
	add_child(owner)
	var tracker: = RankRoundTracker.new()
	tracker._bar = bar
	tracker._fly = collect_fly
	tracker._texture = base.rank_collectible_elements[2].texture
	tracker._eligible = true
	tracker.applied = true
	tracker.awarded = 12
	tracker.score_after = 32
	bar.bind_element(tracker._texture)
	var arrivals: Dictionary = {"count": 0}
	collect_fly.item_arrived.connect( func(_index: int) -> void : arrivals.count = int(arrivals.count) + 1)
	_check( await tracker.play_collect(owner, page._rank_collect_source), "real tracker completes gift collection")
	_check(int(arrivals.count) == 12 and bar.get_count() == 32, "more than eight elements preserve every arrival and final count")

	page._rank_round = tracker
	page._rules_guide_round = true
	quota.set_rules_layout_enabled(true)
	tracker._presented = false
	arrivals.count = 0
	var concurrency: Dictionary = {"max": 0}
	var monitor: Callable = func() -> void :
		concurrency.max = maxi(int(concurrency.max), collect_fly._in_flight)
	get_tree().process_frame.connect(monitor)
	_check( await page.play_rank_collect(), "rules layout and gift use the page's real collection entry")
	get_tree().process_frame.disconnect(monitor)
	_check(int(arrivals.count) == 12 and bar.get_count() == 32 and int(concurrency.max) <= 8, 
		"rules layout retains twelve gift arrivals with at most eight concurrent items")
	tracker._presented = false
	tracker.awarded = 5
	tracker.score_after = 25
	arrivals.count = 0

	var original_time_scale: float = Engine.time_scale
	Engine.time_scale = 4.0
	_check( await page.play_rank_collect(), "column-count reward uses production gift collection entry")
	Engine.time_scale = original_time_scale
	_check(int(arrivals.count) == 5 and bar.get_count() == 25, "column-count gift flies exactly five elements and awards five")
	tracker._presented = false
	tracker.awarded = 12
	tracker.score_after = 32
	arrivals.count = 0
	page._rank_collectible_type = -1
	page._rank_gift_slot = -1
	_check( await page.play_rank_collect(), "rules layout without gift preserves burst collection")
	_check(int(arrivals.count) == 8 and bar.get_count() == 32, 
		"rules burst keeps eight visual arrivals and the authoritative final count")
	page.free()
	board.free()
	owner.queue_free()
	bar.queue_free()
	collect_fly.queue_free()
	resolver.set_rank_collectible(&"", -1)
	_check(resolver.color_visual(&"red", &"element").texture == old, "clearing override restores original skin")
	quota.queue_free()
	fly_layer.queue_free()

func _test_collectible_questions() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 21, "capacity": 3, "targetCups": 3, 
		"initial": ["-|1", "0|?0,0", "1|?1,0,1", "2|2,2,2"], "incoming": ["x", "x"]})
	_check(level.validate().is_empty(), "question fixture is valid")
	var original: Dictionary = level.to_dict()
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var board: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	add_child(board)
	board.apply_skin(JuiceSkinResolver.new(base, base), false)
	board.setup(level, {}, PackedInt32Array([0, 6, 4]))
	for style: int in 5:
		board.set_rank_collectible(1, style)
		_check(int(board.state()["cols"][2][0]) == 1, "collectible question is logically revealed")
		var fruit: JuiceFruit = board._fruit_nodes[2][0]
		_check( not JuiceLevel.is_hidden(fruit.fruit_type) and fruit._body.texture == base.rank_collectible_elements[style].texture, 
			"all four styles show real artwork without a question")
		_check(JuiceLevel.is_hidden(int(board.state()["cols"][1][0])), "other flower question remains covered")
	_check(level.to_dict() == original, "original shared level is not modified")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	var restored: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	add_child(restored)
	restored.apply_skin(JuiceSkinResolver.new(base, base), false)
	_check(restored.restore(level, saved, PackedInt32Array([0, 6, 4])), "question round snapshot restores")
	restored.set_rank_collectible(1, 3)
	_check(int(restored.state()["cols"][2][0]) == 1, "resume keeps collectible revealed")
	_check(JuiceLevel.is_hidden(int(restored.state()["cols"][1][0])), "resume preserves other questions")
	_check(board.try_move(2, 2, 0), "real move with revealed collectible succeeds")
	while board.is_busy():
		await get_tree().process_frame

	(board._history.back()["rec"]["revealed"] as Array).append({"col": 2, "index": 0, "before": 1001, "type": 1})
	var touches: Dictionary = {"count": 0}
	board.revealed_undo_touched.connect( func() -> void : touches.count = int(touches.count) + 1)
	_check(board.undo(), "real collectible undo succeeds")
	_check(int(board.state()["cols"][2][0]) == 1 and int(touches.count) == 0, 
		"undo neither covers collectible nor reports it as a question-memory touch")
	var future: JuiceLevel = JuiceLevel.from_dict({"id": 21, "capacity": 3, "targetCups": 3, 
		"initial": ["-|0", "0|?0,0", "2|2,2,2"], "incoming": ["1|?1,1,1", "x"]})
	_check(future.validate().is_empty(), "future question fixture is valid")
	var future_original: Dictionary = future.to_dict()
	var shown: JuiceLevel = JuiceRules.level_with_revealed_type(future, 1)
	_check(shown != future and int(shown.incoming[0]["beads"][0]) == 1, 
		"incoming collectible question is revealed in local level only")
	_check(future.to_dict() == future_original and JuiceLevel.is_hidden(int(shown.board_cols[1][0])), 
		"future normalization preserves original level and other questions")
	var supplied: Dictionary = JuiceRules.make_state(shown)
	var supplied_move: Dictionary = JuiceRules.apply_move(supplied, shown, 0, 0, 1)
	_check( not supplied_move.is_empty() and (supplied["cups"] as Array).has(1), 
		"revealed incoming collectible follows normal supply and collection")
	for entry: Dictionary in supplied_move.get("revealed", []) as Array:
		_check(int(entry["type"]) != 1, "incoming collectible does not request question reveal animation")
	var modifiers: Dictionary = {"cols": [[1001, 2001, 1000, 1]]}
	_check(JuiceRules.reveal_type(modifiers, 1) == 1 and modifiers["cols"][0] == [1, 2001, 1000, 1], 
		"only the selected question modifier is removed; frozen and other questions remain")
	board.queue_free()
	restored.queue_free()
	await get_tree().process_frame


func _test_arrival_modes(quota: JuiceQuotaBar, texture: Texture2D) -> void :
	var board: = JuiceBoardView.new()
	board._level = _model().juice
	var page: = JuiceGamePage.new()
	page._board = board
	page._quota = quota
	page._rank_collectible_type = 0
	quota.setup(3)
	page._on_cup_flight_finished({"slot": 1, "tex": texture, "tint": Color.WHITE, 
		"spr": null, "gift_visual": null})
	_check(quota.filled_count() == 0 and quota._arrived_sunlight_round_cups.has(1), 
		"finite gift landing waits for the preceding pot")
	page._on_cup_flight_finished({"slot": 0, "tex": texture, "tint": Color.WHITE, "spr": null})
	_check(quota.filled_count() == 2 and quota._arrived_sunlight_round_cups.is_empty(), 
		"finite mixed landing commits ordinary pot and queued gift in order")
	page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	quota.setup_endless()
	for slot: int in 40:
		quota.reserve_endless_slot(slot)
		page._on_cup_flight_finished({"slot": slot, "tex": texture, "tint": Color.WHITE, 
			"spr": null, "gift_visual": null})
	_check(quota.filled_count() == 32 and quota._endless_first_slot == 8
		and quota._arrived_sunlight_round_cups.is_empty(), 
		"endless landing uses absolute indices even when a record retains a gift marker")
	page._on_cup_flight_finished({"slot": 0, "tex": texture, "tint": Color.WHITE, "spr": null})
	_check(quota.filled_count() == 32 and quota._endless_first_slot == 8, 
		"retired endless landing cannot append an old pot")
	page.free()
	board.free()
	quota.setup(3)
