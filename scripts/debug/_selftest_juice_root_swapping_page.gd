extends SceneTree


const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
var failures: Array[String] = []


class MutableRootConfig extends AllowRootSwappingConfig:
	var sample: Dictionary = {"raw": "level_1", "valid": true, "value": 1}
	var sample_count: int = 0

	func get_debug_override() -> int:
		return -1

	func _read_sdk_sample() -> Dictionary:
		sample_count += 1
		return sample.duplicate()

func _initialize() -> void :
	call_deferred("_run")

func check(ok: bool, message: String) -> void :
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void :
	var host: = Node.new()
	host.name = "RootSwapPageSelftestHost"
	root.add_child(host)
	current_scene = host
	await _test_page_mode_gates()
	await _test_endless_rule_freeze()
	await _test_silent_close_next_round()
	_test_hint_root_local_cache()
	await _test_hint_grouping_plan()
	_test_hint_ordinary_plan()
	await _test_hint_restock_dispatch()
	await _test_level7_hint_death_delivery()
	host.queue_free()
	await process_frame
	print("JUICE_ROOT_SWAPPING_PAGE ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)

func _test_page_mode_gates() -> void :
	var page_script: Variant = load("res://scripts/main/pages/game/juice_game_page.gd")
	var page: Variant = page_script.new()
	var board_script: Variant = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd")
	var board: Variant = board_script.new()
	page.set("_board", board)
	var model: = JuiceLevelModel.new()
	model.juice = JuiceLevel.from_dict({"capacity": 3, "targetCups": 3, 
		"initial": ["0|1,0,2", "1|2,1,0", "2|0,2,1"], "incoming": []})
	page.set("_level_model", model)
	var user_state: Variant = root.get_node("UserState")

	var saved: Dictionary = user_state.get("_debug_ab_overrides")
	var temporary: Dictionary = saved.duplicate(true)
	user_state.set("_debug_ab_overrides", temporary)
	var combinations: int = 0
	for group in [0, 1, 2, 99]:
		temporary["allow_root_swapping"] = group
		for level_id in [1, 3, 4, 50]:
			model.level_id = level_id
			for kind: String in ["", "special_challenge"]:
				model.round_kind = kind
				for mode in [page_script.PlayMode.LEVEL, page_script.PlayMode.ENDLESS]:
					combinations += 1
					page.play_mode = mode
					var expected: bool = group in [1, 2] and level_id >= 1
					check(page._root_swapping_enabled_for_level(level_id) == expected, 
						"真实页面分组/关号/挑战/无尽门控组合一致")
					page._configure_root_swapping()
					check(bool(board.get("_allow_root_swapping_enabled")) == expected, 
						"真实页面复用不残留前一模式实验开关")
					check(bool(board.get("_play_after_dead_pending")) == (group == 2 and level_id >= 1), 
						"真实页面下局死后操作许可仅实验2且从第1关起")
	await _test_running_board_freeze(page, model, temporary)
	page.set("_board", board)
	combinations += _test_endless_null_model_gates(page, board, user_state, temporary)
	user_state.set("_debug_ab_overrides", saved)
	page.free()
	board.free()
	print("ROOT_SWAP_PAGE_GATES combinations=", combinations, " saved_override_preserved=true")


func _test_endless_null_model_gates(page: Variant, board: Variant, 
		user_state: Variant, overrides: Dictionary) -> int:
	var saved_level: int = user_state.get_current_level()
	var combinations: int = 0
	page.play_mode = page.PlayMode.ENDLESS
	page.set("_level_model", null)
	for group in [0, 1, 2, 99]:
		overrides["allow_root_swapping"] = group
		for level_id in [1, 3, 4, 50]:
			combinations += 1

			user_state.set("_current_level", level_id)
			page._configure_root_swapping()
			check(bool(board.get("_allow_root_swapping_enabled"))\
			== (group in [1, 2] and level_id >= 1), 
				"真实无尽无关卡模型时按主线进度读取同一组门槛")
			check(bool(board.get("_play_after_dead_pending")) == (group == 2 and level_id >= 1), 
				"真实无尽无模型时仅实验2注入下局死后操作许可")
	user_state.set("_current_level", saved_level)
	return combinations


func _test_running_board_freeze(page: Variant, 
		model: JuiceLevelModel, overrides: Dictionary) -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: Variant = scene.instantiate()
	board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	root.add_child(board)
	page.set("_board", board)
	model.level_id = 4
	model.round_kind = ""
	page.play_mode = page.PlayMode.LEVEL
	overrides["allow_root_swapping"] = 0
	page._configure_root_swapping()
	board.setup(model.juice)
	board.set_process(false)
	check( not bool(board.state().get("allow_root_swapping", false))\
	and not board.is_play_after_dead_enabled(), "真实对照组setup冻结互换与死后操作关闭")
	overrides["allow_root_swapping"] = 2
	check( not bool(board.get("_allow_root_swapping_enabled"))\
	and not board.is_play_after_dead_enabled(), "改分组不热切当前对照盘面")
	page._configure_root_swapping()
	check(bool(board.get("_play_after_dead_pending"))\
	and not board.is_play_after_dead_enabled()\
	and not bool(board.state().get("allow_root_swapping", false))\
	and bool(board.get("_root_adjudication_suspended")), "入场配置只注入下局许可并暂停旧盘判定")
	board.setup(model.juice)
	board.set_process(false)
	check(bool(board.state().get("allow_root_swapping", false))\
	and board.is_play_after_dead_enabled(), "真实实验2setup才冻结互换与死后操作许可")
	overrides["allow_root_swapping"] = 0
	check(bool(board.get("_allow_root_swapping_enabled"))\
	and board.is_play_after_dead_enabled(), "回对照组不热切当前实验盘面")
	page._configure_root_swapping()
	check( not bool(board.get("_play_after_dead_pending"))\
	and board.is_play_after_dead_enabled()\
	and bool(board.state().get("allow_root_swapping", false))\
	and bool(board.get("_root_adjudication_suspended")), "关闭配置不提前改本局冻结规则或恢复判定")
	board.setup(model.juice)
	board.set_process(false)
	check( not bool(board.state().get("allow_root_swapping", false))\
	and not board.is_play_after_dead_enabled(), "下一次真实setup关闭实验并恢复原死亡输入规则")
	board.set_root_adjudication_suspended(false)
	board._cancel_closed_check()
	board.queue_free()
	await process_frame


func _test_endless_rule_freeze() -> void :
	var user_state: Variant = root.get_node("UserState")
	var saved: Dictionary = user_state.get("_debug_ab_overrides")
	var temporary: Dictionary = saved.duplicate(true)
	var saved_level: int = user_state.get_current_level()
	user_state.set("_debug_ab_overrides", temporary)
	user_state.set("_current_level", 4)
	temporary["allow_root_swapping"] = 1
	var page_script: Variant = load("res://scripts/main/pages/game/juice_game_page.gd")
	var page: Variant = page_script.new()
	page.play_mode = page_script.PlayMode.ENDLESS
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: Variant = scene.instantiate()
	board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	root.add_child(board)
	page.set("_board", board)
	page._configure_root_swapping()
	var session: = JuiceEndlessSession.new(42, true)
	var queue: Array = []
	for sequence in 5:
		queue.append({"sequence": sequence, "jar": 0, "beads": [0, 1, 2, 3, 4] as Array[int]})
	check(session.enqueue(queue), "真实无尽测试装入合法固定FIFO")
	board.setup_endless(session)
	board.set_root_adjudication_suspended(false)
	board.set_process(false)
	var before: String = S._full_state_key(session.state)
	check(bool(session.state.get("allow_root_swapping", false))\
	and bool(board.state().get("allow_root_swapping", false)), 
		"页面注入经正式setup_endless保留到共享规则字典")
	check(board.try_move(1, 0, 2), "真实无尽Board执行两列根部交换")
	var rec: Dictionary = {}
	if board.history_size() > 0:
		rec = (board.get("_history") as Array)[-1]["rec"]
	check(bool(rec.get("root_swapped", false)) and session.steps == 1, 
		"无尽移动经过真实session提交互换并计一步")
	temporary["allow_root_swapping"] = 0
	for frame in 120:
		board._process(1.0 / 60.0)
	check(bool(session.state.get("allow_root_swapping", false))\
	and bool(board.get("_allow_root_swapping_enabled")), "无尽局内改实验分组不热切规则")
	check(board.undo() and S._full_state_key(session.state) == before\
	and bool(session.state.get("allow_root_swapping", false)) and session.steps == 0, 
		"真实无尽撤回恢复花串/FIFO/步骤并保留本局实验规则")
	var replay: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(session.player_snapshot())
	check(bool(replay.state.get("allow_root_swapping", false)), "无尽独占Hint快照保留本局规则")
	replay.state["allow_root_swapping"] = false
	check(bool(session.state.get("allow_root_swapping", false)), "后台快照改规则不污染玩家字典")
	page._configure_root_swapping()
	var next_session: = JuiceEndlessSession.new(42, true)
	board.setup_endless(next_session)
	board.set_process(false)
	check( not bool(next_session.state.get("allow_root_swapping", false))\
	and not R.is_root_swap(next_session.state, 1, 0, 2), 
		"关闭实验后下一次真实无尽setup恢复对照原规则")
	temporary["allow_root_swapping"] = 2
	page._configure_root_swapping()
	check(bool(board.get("_play_after_dead_pending"))\
	and not board.is_play_after_dead_enabled()\
	and not bool(board.state().get("allow_root_swapping", false)), 
		"无尽实验2配置只注入pending许可，不热切对照局active")
	var play_after_dead_session: = JuiceEndlessSession.new(42, true)
	check(play_after_dead_session.enqueue(queue), "无尽实验2冻结测试装入同一合法FIFO")
	board.setup_endless(play_after_dead_session)
	board.set_process(false)
	check(board.is_play_after_dead_enabled()\
	and bool(play_after_dead_session.state.get("allow_root_swapping", false)), 
		"正式setup_endless冻结实验2死后操作与互换许可")
	temporary["allow_root_swapping"] = 0
	page._configure_root_swapping()
	check( not bool(board.get("_play_after_dead_pending"))\
	and board.is_play_after_dead_enabled()\
	and bool(play_after_dead_session.state.get("allow_root_swapping", false)), 
		"无尽实验关闭配置不热切本局死后操作许可")
	board.setup_endless(JuiceEndlessSession.new(42, true))
	board.set_process(false)
	check( not board.is_play_after_dead_enabled()\
	and not bool(board.state().get("allow_root_swapping", false)), 
		"下局setup_endless才关闭实验2死后操作与互换许可")
	board._cancel_closed_check()
	var deadline: int = Time.get_ticks_msec() + 5000
	while board.get("_root_closed_job") != null and Time.get_ticks_msec() < deadline:
		board._poll_closed_check()
		await process_frame
	check(board.get("_root_closed_job") == null, "无尽切局的实验闭环worker有界回收")
	board._cancel_closed_check()
	user_state.set("_debug_ab_overrides", saved)
	user_state.set("_current_level", saved_level)
	page.free()
	board.queue_free()
	await process_frame
	print("ROOT_SWAP_PAGE_ENDLESS setup_flag=true runtime_swap=true undo_frozen=true next_control=true pending_active_frozen=true")


func _test_silent_close_next_round() -> void :
	var manager: Variant = root.get_node("ABManager")
	var saved_config: Variant = manager.allow_root_swapping
	var saved_ready: bool = manager._is_init_done
	var saved_locked: bool = manager._startup_control_locked
	manager._is_init_done = true
	manager._startup_control_locked = false
	var config: = MutableRootConfig.new()
	config.init_default()
	manager.allow_root_swapping = config
	var page_script: Variant = load("res://scripts/main/pages/game/juice_game_page.gd")
	var page: Variant = page_script.new()
	var model: = JuiceLevelModel.new()
	model.level_id = 4
	model.juice = JuiceLevel.from_dict({"id": 98398, "capacity": 3, "targetCups": 3, 
		"initial": ["0|1,0,2", "1|2,1,0", "2|0,2,1"], "incoming": []})
	check(model.juice.validate().is_empty(), "静默关闭实验准备的历史交换题面合法")
	page.set("_level_model", model)
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: Variant = scene.instantiate()
	board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	root.add_child(board)
	page.set("_board", board)
	for missing: bool in [false, true]:
		config.sample = {"raw": "level_1", "valid": true, "value": 1}
		config.load_value_silent()
		page._configure_root_swapping()
		board.setup(model.juice)
		board.set_root_adjudication_suspended(false)
		board.set_process(false)
		var original: Dictionary = R.clone_state(board.state())
		check(board.try_move(0, 0, 1), "开启实验的真实盘面先记录一次互换")
		var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
		check(bool(saved["undo_history"][0]["rec"]["root_swapped"]), "远端关闭前历史记录保留真实交换类型")
		config.sample = {"raw": "" if missing else "default", "valid": not missing, "value": 0}
		var samples_before: int = config.sample_count
		check(config.value() == 1 and config.sample_count == samples_before, 
			"SDK样本变化时普通读仍使用本轮冻结缓存")
		config.load_value_silent()
		check(config.value() == 0 and config.sample_count == samples_before + 1\
		and config.is_control_group() == not missing, 
			"下一局静默刷新同时更新值与来源，未命中不冒充对照身份")
		check(bool(board.state().get("allow_root_swapping", false))\
		and bool(board.get("_allow_root_swapping_enabled")), "静默刷新配置不热切已开始盘面")
		page._configure_root_swapping()
		check(board.restore(model.juice, saved), "关闭后下一次实际续局接受原花串和交换历史")
		board.set_root_adjudication_suspended(false)
		board.set_process(false)
		check( not bool(board.state().get("allow_root_swapping", false))\
		and bool(board.last_move().get("root_swapped", false)), "续局应用对照规则但保留旧交换类型")
		original["allow_root_swapping"] = false
		check(board.undo() and S._full_state_key(board.state()) == S._full_state_key(original)\
		and board.sync_error().is_empty(), "实验关闭后的旧互换撤回仍完整还原两串与节点")
		board.setup(model.juice)
		board.set_root_adjudication_suspended(false)
		board.set_process(false)
		check( not bool(board.state().get("allow_root_swapping", false)), "连关或重开的下一次摆盘恢复原规则")
	board._cancel_closed_check()
	var deadline: int = Time.get_ticks_msec() + 5000
	while board.get("_root_closed_job") != null and Time.get_ticks_msec() < deadline:
		board._poll_closed_check()
		await process_frame
	check(board.get("_root_closed_job") == null, "静默关闭测试有界回收实验后台任务")
	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	manager.allow_root_swapping = saved_config
	manager._is_init_done = saved_ready
	manager._startup_control_locked = saved_locked
	page.free()
	board.queue_free()
	await process_frame
	print("ROOT_SWAP_PAGE_SILENT_CLOSE sources=2 cached_source=true running_frozen=true next_control=true historical_swap_undo=true")



func _new_hint_page(level: JuiceLevel, state: Dictionary) -> Dictionary:
	var page_script: Variant = load("res://scripts/main/pages/game/juice_game_page.gd")
	var page: Variant = page_script.new()
	var board_script: Variant = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd")
	var board: Variant = board_script.new()
	board.set("_level", level)
	board.set("_state", R.clone_state(state))
	page.set("_board", board)
	page.play_mode = page_script.PlayMode.LEVEL
	return {"page": page, "board": board}


func _free_hint_page(fixture: Dictionary) -> void :
	fixture["page"]._hint_cancel()
	fixture["page"].free()
	fixture["board"].free()


func _same_move(left: Dictionary, right: Dictionary) -> bool:
	return not left.is_empty() and not right.is_empty()\
	and int(left["src"]) == int(right["src"]) and int(left["j"]) == int(right["j"])\
	and int(left["dst"]) == int(right["dst"])


func _test_hint_root_local_cache() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 98394, "schema": "juice-level/4", 
		"capacity": 3, "targetCups": 3, "initial": ["1|0,0", "2|1,0", "0|2"], 
		"incoming": ["-|1,2", "x"], "columnCaps": {"initial": [2, 2, 3], "incoming": [3, 0]}})
	check(level.validate().is_empty(), "提示缓存准备交换样例合法")
	var state: Dictionary = R.make_state(level)
	state["allow_root_swapping"] = true
	var route: Array = [{"src": 0, "j": 0, "dst": 2}, {"src": 1, "j": 1, "dst": 2}]
	var hint: Dictionary = S._checked_path_hint(state, level, route)
	check( not hint.is_empty() and int(hint.get("len", 0)) == 2\
	and (hint.get("path", []) as Array).size() == 2\
	and not bool(hint.get("root_necessary", false)), "互换局部路线完整交付到真实首次收盆")
	if hint.is_empty():
		return
	var fixture: Dictionary = _new_hint_page(level, state)
	var page: Variant = fixture["page"]
	var board: Variant = fixture["board"]
	var before_key: String = page._hint_state_key()

	page.set("_hint_plan_root_necessary", true)
	page._cache_hint(before_key, hint)
	var after: Dictionary = R.clone_state(state)
	var first: Dictionary = hint["move"]
	var rec: Dictionary = R.apply_move(after, level, int(first["src"]), int(first["j"]), int(first["dst"]))
	check(bool(rec.get("root_swapped", false)) and (rec["deposits"] as Array).is_empty(), 
		"缓存样例首步是无即时收盆的真实交换")
	var expected_key: String = "%d:%s" % [level.id, S._full_state_key(after)]
	check( not bool(page.get("_hint_plan_root_necessary"))\
	and (page.get("_hint_plan") as Array) == (hint["path"] as Array).slice(1), 
		"互换局部path直接缓存余路线并清掉旧必要性标记")
	check(String(page.get("_hint_plan_key")) == expected_key\
	and S._full_state_key(board.state()) == S._full_state_key(state), 
		"缓存用真实规则预测下一盘面且不改当前盘面")
	check(_same_move(page._hint_try_sync().get("move", {}), first), "原盘面仍可复用已证明首步")
	board.set("_state", after)
	var next: Dictionary = page._hint_from_plan(expected_key)
	check(_same_move(next.get("move", {}), route[1]) and int(next.get("len", 0)) == 1, 
		"实际交换后按预测盘面取到普通落盆余路线")
	check(page._hint_from_plan(before_key).is_empty(), "偏离预测状态不发旧路线")
	var changed: Dictionary = R.clone_state(after)

	changed["done"] = int(changed["done"]) + 1
	board.set("_state", changed)
	check(R.move_info(changed, 1, 1, 2) > 0 and page._hint_try_sync().is_empty(), 
		"列内容相同但收盆/补货进度变化时也拒收旧完整指纹")
	board.set("_state", after)
	check(_same_move(page._hint_try_sync().get("move", {}), route[1]), 
		"恢复精确预测盘面后同步入口缓存并交付下一步")
	var finish: Dictionary = R.clone_state(after)
	var final_rec: Dictionary = R.apply_move(finish, level, 1, 1, 2)
	check((final_rec.get("deposits", []) as Array).size() == 1\
	and int(finish["done"]) == 1\
	and (finish["cols"][2] as Array) == [1, 2], 
		"第二步真实收盆后消费补货而非停留在未落盆搜索态")
	board.set("_state", finish)
	check((page.get("_hint_plan") as Array).is_empty() and page._hint_try_sync().is_empty(), 
		"到首次收盆后局部路线耗尽，不复用旧首步")
	page._hint_cancel()
	check((page.get("_hint_cache") as Dictionary).is_empty()\
	and (page.get("_hint_plan") as Array).is_empty()\
	and String(page.get("_hint_cache_key")).is_empty()\
	and String(page.get("_hint_plan_key")).is_empty()\
	and String(page.get("_hint_checked_key")).is_empty()\
	and not bool(page.get("_hint_plan_root_necessary")), "取消清空提示及互换局部路线全部凭证")
	page._cache_hint(page._hint_state_key(), {})
	check( not bool(page.get("_hint_plan_root_necessary")), "空结果不残留交换候选标记")
	_free_hint_page(fixture)
	print("ROOT_SWAP_PAGE_HINT_CACHE delivered=2 synchronous_remaining=1 restock_key_checked=true cancel_cleared=true")


func _test_hint_grouping_plan() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 98397, "capacity": 2, "targetCups": 3, 
		"initial": ["0|", "-|1,2", "1|2,1"], "incoming": ["2|0,0", "x"]})
	check(level.validate().is_empty(), "任意位置拼满再落目标盆页面样例合法")
	var state: Dictionary = R.make_state(level)
	state["allow_root_swapping"] = true
	var fixture: Dictionary = _new_hint_page(level, state)
	var page: Variant = fixture["page"]
	var board: Variant = fixture["board"]
	var result: Dictionary = await _dispatch_hint_result(page)
	var hint: Dictionary = result.get("hint", {})
	check(bool(result.get("completed", false)) and int(hint.get("len", 0)) == 3\
	and not bool(hint.get("root_necessary", false))\
	and int(result.get("reachability", S.Reachability.UNKNOWN)) == S.Reachability.UNKNOWN, 
		"正式worker交付三步局部拼列路线，不冒充整关有解")
	var path: Array = hint.get("path", [])
	if path.size() != 3:
		_free_hint_page(fixture)
		return
	var route: Array = [{"src": 1, "j": 1, "dst": 0}, {"src": 2, "j": 1, "dst": 1}, 
		{"src": 1, "j": 0, "dst": 2}]
	page._cache_hint(page._hint_state_key(), hint)
	var current: Dictionary = R.clone_state(state)
	for i in path.size():
		board.set("_state", current)
		var delivered: Dictionary = hint if i == 0 else page._hint_try_sync()
		var mv: Dictionary = delivered.get("move", {})
		check(_same_move(mv, route[i]) and int(delivered.get("len", 0)) == path.size() - i, 
			"三步拼列路线按真实盘面连续同步交付且逐步缩短")
		if mv.is_empty():
			break
		var predicted_key: String = String(page.get("_hint_plan_key"))
		var rec: Dictionary = R.apply_move(current, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check( not rec.is_empty() and bool(rec.get("root_swapped", false)) == (i == 2), 
			"页面缓存前两步普通拼列、最后一步真实整串送目标盆")
		if i < 2:
			check((rec.get("deposits", []) as Array).is_empty()\
			and predicted_key == "%d:%s" % [level.id, S._full_state_key(current)], 
				"拼列阶段不提前收盆，完整指纹预测下一步一致")
		if i == 1:
			check((current["cols"][1] as Array) == [1, 1] and int(current["jars"][1]) == R.NO_JAR\
			and R.deposit_ready(current, 1) == 0, "同色满串允许先形成于无盆列再送到目标盆")
		if i == 2:
			check((rec.get("deposits", []) as Array).size() == 1 and int(current["done"]) == 1\
			and (current["cols"][2] as Array) == [0, 0] and int(current["jars"][2]) == 2, 
				"最后真实落盆与补货提交后才耗尽局部提示路线")
	board.set("_state", current)
	check((page.get("_hint_plan") as Array).is_empty() and page._hint_try_sync().is_empty(), 
		"三步路线到首次收盆后没有陈旧尾步或提示缓存")
	_free_hint_page(fixture)
	print("ROOT_SWAP_PAGE_GROUPING path=3 grouped_in_park=true delivered_to_target=true synchronous_cache=true")


func _test_hint_ordinary_plan() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 98395, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|0,1", "1|1,0"], "incoming": ["x"]})
	check(level.validate().is_empty(), "普通提示缓存样例合法：" + str(level.validate()))
	var route: Array = [{"src": 1, "j": 1, "dst": 0}, {"src": 2, "j": 1, "dst": 1}]
	for enabled: bool in [false, true]:
		var state: Dictionary = R.make_state(level)
		state["allow_root_swapping"] = enabled
		var hint: Dictionary = S._checked_path_hint(state, level, route)
		check( not hint.is_empty() and int(hint.get("len", 0)) == 2, "普通两步路线经真实首次收盆安全核验")
		if hint.is_empty():
			continue
		var fixture: Dictionary = _new_hint_page(level, state)
		var page: Variant = fixture["page"]
		var board: Variant = fixture["board"]

		page.set("_hint_plan_root_necessary", true)
		page._cache_hint(page._hint_state_key(), hint)
		check( not bool(page.get("_hint_plan_root_necessary")), "对照/实验普通路线均清掉交换候选标记")
		check(page._hint_from_plan("different_state").is_empty(), "普通路线也拒绝错误盘面凭证")
		var first: Dictionary = hint["move"]
		var after: Dictionary = R.clone_state(state)
		var rec: Dictionary = R.apply_move(after, level, int(first["src"]), int(first["j"]), int(first["dst"]))
		check( not bool(rec.get("root_swapped", false)), "对照/实验普通缓存首步均保持原搬移规则")
		board.set("_state", after)
		var next: Dictionary = page._hint_from_plan(page._hint_state_key())
		check(_same_move(next.get("move", {}), route[1]) and int(next.get("len", 0)) == 1, 
			"对照/实验普通路线到达预测状态均同步交付下一步")
		check(_same_move(page._hint_try_sync().get("move", {}), route[1]), "对照/实验普通同步入口均沿原路线继续")
		_free_hint_page(fixture)
	print("ROOT_SWAP_PAGE_ORDINARY_PLAN groups=2 steps=2 synchronous_remaining=1")




func _seed_root_proof(board: Variant) -> Dictionary:
	var proof: Dictionary = S.begin_root_closed_search(board.state(), board.level(), 8000, true)
	var result: Dictionary = {}
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 5000:
		result = S.advance_root_closed_search(proof, 8)
		if not bool(result.get("continuable", false)):
			break
	check(String(result.get("status", "UNKNOWN")) in ["EXIT", "CLOSED"], "页面夹具取得真实首盆结论")
	var key: String = S.root_closed_state_key(board.state())
	(board.get("_root_closed_cache") as Dictionary)[key] = {"ctx": {}, "result": result, 
		"level_identity": board.level().get_instance_id()}
	return result


func _dispatch_hint_result(page: Variant) -> Dictionary:
	if bool(page._board.state().get("allow_root_swapping", false)) and page._board.root_closed_result().is_empty():
		_seed_root_proof(page._board)
	page._hint_dispatch(false, true)
	var task: int = int(page.get("_hint_task_id"))
	check(task != -1, "正式页面预检投递真实Hint工作线程")
	if task == -1:
		return {}
	var started: int = Time.get_ticks_msec()
	while not WorkerThreadPool.is_task_completed(task) and Time.get_ticks_msec() - started < 5000:
		await process_frame
	if not WorkerThreadPool.is_task_completed(task):
		check(false, "页面Hint工作线程必须在有界时间结束")
		(page.get("_hint_task_cancel") as Semaphore).post()
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(task)
	check(task_error == OK, "真实Hint工作线程正确回收")
	var result: Dictionary = (page.get("_hint_task_result") as Dictionary).duplicate(true)
	page._hint_release()
	return result


func _test_hint_restock_dispatch() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 98396, "capacity": 2, "targetCups": 5, 
		"initial": ["0|1,1", "1|0,0", "2|2,2"], "incoming": ["x", "0|1,1", "1|0,0"]})
	check(level.validate().is_empty(), "同pair补货后重复交换样例合法")
	var state: Dictionary = R.make_state(level)
	state["allow_root_swapping"] = true
	var opening: Array = []
	R.run_deposit(state, level, opening)
	check(int(state["done"]) == 1 and bool(state["gone"][2]), "真实开局先收第三盆并消耗x补货")
	var after: Dictionary = R.clone_state(state)
	var first: Dictionary = {"src": 0, "j": 0, "dst": 1}
	var rec: Dictionary = R.apply_move(after, level, 0, 0, 1)
	check(bool(rec.get("root_swapped", false)) and (rec["deposits"] as Array).size() == 2\
	and int(after["done"]) == 3, "首步交换收两盆后同pair再次落入错盆")
	var repeated: Dictionary = {"src": 1, "j": 0, "dst": 0}
	var whole: Array = [first, repeated]
	var hint: Dictionary = S._checked_three_pot_hint(state, level, whole, level.groups_total, {})
	check( not hint.is_empty() and (hint.get("path", []) as Array).size() == 2\
	and not bool(hint.get("root_necessary", false)), 
		"真实重放验证同pair交换跨收盆完整计划，不误删为逆操作闭环")
	if hint.is_empty():
		return
	var fixture: Dictionary = _new_hint_page(level, state)
	var page: Variant = fixture["page"]
	var board: Variant = fixture["board"]
	var before_key: String = page._hint_state_key()
	page._cache_hint(before_key, hint)
	board.set("_state", after)
	board.set("_history", [{"rec": rec}])
	check(board.last_move().is_empty(), "收盆/补货后的真实last_move不禁同pair下一次交换")
	check(_same_move(page._hint_try_sync().get("move", {}), repeated), 
		"包含真实补货结果的余路线可同步交付下一次同pair交换")
	var matched: Dictionary = await _dispatch_hint_result(page)
	var matched_hint: Dictionary = matched.get("hint", {})
	check(bool(matched.get("completed", false)) and not matched_hint.is_empty()\
	and not bool(matched_hint.get("root_necessary", false))\
	and (matched_hint.get("path", []) as Array).size() == 1, 
		"补货后真实worker直接交付到下一次落盆的完整局部路线")
	check(S._full_state_key(board.state()) == S._full_state_key(after), "真实dispatch始终操作独占快照")

	page.set("_hint_cache_key", before_key)
	page.set("_hint_plan", [repeated])
	page.set("_hint_plan_key", before_key)
	check(page._hint_try_sync().is_empty(), "预测完整指纹不匹配时丢弃仍合法的旧余路线")
	var stale: Dictionary = await _dispatch_hint_result(page)
	var stale_hint: Dictionary = stale.get("hint", {})
	check(bool(stale.get("completed", false)) and not stale_hint.is_empty()\
	and not bool(stale_hint.get("root_necessary", false))\
	and not stale_hint.has("root_win_path"), 
		"旧凭证失效后真实dispatch重新搜索，不返回旧整关必要性协议")
	var final: Dictionary = R.clone_state(after)
	if not matched_hint.is_empty():
		var mv: Dictionary = matched_hint["move"]
		var final_rec: Dictionary = R.apply_move(final, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check(bool(final_rec.get("root_swapped", false)) and R.is_win(final, level), 
			"第二次同pair交换经真实执行完成五盆")
	_free_hint_page(fixture)
	print("ROOT_SWAP_PAGE_HINT_DISPATCH full_local_path=true stale_plan_discarded=true repeated_pair=2")



func _level7_live_fixture() -> Dictionary:
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 7, "capacity": 5, "targetCups": 12, 
		"initial": ["-|", "6|6,?6,?5,4", "7|6,1,?1,3", "5|5,?7,6,?7,5", 
			"1|4,?3,7,1", "3|5,7,3,1", "4|4,5,7,?4,6"], 
		"incoming": ["8|8,?8,?1,3,4", "0|0,0,?3,8,1", "9|9,1,8,0", "1|1,?9,?8,5,3", 
			"5|5,?5,9,1,0", "3|3,3,?0,5,9", "-|3,1,9,3,5"]})
	var state: Dictionary = R.make_state(level)
	state["allow_root_swapping"] = true
	state["cols"] = [[4, 4] as Array[int], [6, 6, 6, 6] as Array[int], 
		[6, 1, 1, 1, 1] as Array[int], [5, 7, 7, 7, 7] as Array[int], 
		[4, 3, 3, 3] as Array[int], [5, 7] as Array[int], [4, 5, 5, 5] as Array[int]]
	return {"level": level, "state": state}


func _hint_economy_snapshot() -> Dictionary:
	var user_state: Variant = root.get_node("UserState")
	return {"coins": user_state.get_coins(), "count": user_state.get_prop_count("hint"), 
		"reward_count": user_state.get_prop_reward_ads_count("hint"), 
		"free": user_state.is_prop_free_available("hint")}


func _settle_hint_task(page: Variant) -> Dictionary:
	var task: int = int(page.get("_hint_task_id"))
	check(task != -1, "第7关正式页面投递Hint任务")
	if task == -1:
		return {}
	var started: int = Time.get_ticks_msec()
	while not WorkerThreadPool.is_task_completed(task) and Time.get_ticks_msec() - started < 5000:
		await process_frame
	if not WorkerThreadPool.is_task_completed(task):
		check(false, "第7关Hint任务在有界时间内结束")
		(page.get("_hint_task_cancel") as Semaphore).post()
	var result: Dictionary = (page.get("_hint_task_result") as Dictionary).duplicate(true)
	page._hint_settle()
	return result


func _test_level7_hint_death_delivery() -> void :
	var data: Dictionary = _level7_live_fixture()
	var level: JuiceLevel = data["level"]
	var state: Dictionary = data["state"]
	check(level.validate().is_empty(), "第7关Hint死亡回归题面合法")
	var fixture: Dictionary = _new_hint_page(level, state)
	var page: Variant = fixture["page"]
	var board: Variant = fixture["board"]
	var result: Dictionary = _seed_root_proof(board)
	check(String(result.get("status", "UNKNOWN")) == "CLOSED", "第7关当前首盆严格无出口")
	var events: Array[String] = []
	board.dead.connect( func(reason: String) -> void : events.append(reason))

	board._mark_dead("loop")
	var economy: Dictionary = _hint_economy_snapshot()
	var used: Dictionary = (page.get("_tracking_prop_used_round") as Dictionary).duplicate(true)
	var btn: = PropBtn.new()
	btn.set("_business_state", PropBtn.PropState.COUNT)
	page.set("_prop_ui", {"hint": {"btn": btn}})
	page.set("_playfield_ready", true)
	page.set("_ui_props_ready", true)
	page._hint_dispatch(false, true)
	page._use_prop("hint")
	check(int(page.get("_hint_task_id")) == -1 and not bool(board.get("_hint_lock"))\
	and events == ["loop"] and board.over() == "dead"\
	and not bool(board.snapshot()["hint_dead"]), "自动严格死局后Hint不另搜、不锁盘、不覆盖死因")
	check(_hint_economy_snapshot() == economy\
	and (page.get("_tracking_prop_used_round") as Dictionary) == used\
	and page._hint_try_sync().is_empty(), "自动死局盘重复Hint不扣免费/库存/金币或计使用")
	btn.free()
	_free_hint_page(fixture)

	var live_level: JuiceLevel = JuiceLevel.from_dict({"id": 98393, "capacity": 2, "targetCups": 3, 
		"initial": ["0|", "-|1,2", "1|2,1"], "incoming": ["2|0,0", "x"]})
	var live: Dictionary = R.make_state(live_level)
	live["allow_root_swapping"] = true
	fixture = _new_hint_page(live_level, live)
	page = fixture["page"]
	board = fixture["board"]
	_seed_root_proof(board)
	page._hint_dispatch(false, true)
	check(int(page.get("_hint_task_id")) != -1, "活盘复用真实首盆路线投递回放")
	board._mark_dead("loop")
	await _settle_hint_task(page)
	check(board.over() == "dead" and board.get("_pending_dead_reason") == "loop"\
	and (page.get("_hint_cache") as Dictionary).is_empty()\
	and String(page.get("_hint_cache_key")).is_empty()\
	and _hint_economy_snapshot() == economy, "已终结盘面丢弃迟到Hint且不恢复缓存/扣账")
	_free_hint_page(fixture)

	fixture = _new_hint_page(live_level, live)
	page = fixture["page"]
	board = fixture["board"]
	_seed_root_proof(board)
	page._hint_dispatch(false, true)
	var rec: Dictionary = R.apply_move(board.state(), live_level, 1, 1, 0)
	check( not rec.is_empty(), "首盆Hint回放期间真实合法移动改变盘面")
	await _settle_hint_task(page)
	check(board.over() == "" and String(page.get("_hint_cache_key")).is_empty()\
	and (page.get("_hint_cache") as Dictionary).is_empty()\
	and _hint_economy_snapshot() == economy, "Hint旧首盆路线不作用于变化盘面或扣账")
	_free_hint_page(fixture)
	AudioManager.stop_sfx(&"juice_dead")
	if Toast._current != null and is_instance_valid(Toast._current):
		Toast._current.queue_free()
	await process_frame
	print("ROOT_SWAP_LEVEL7_PAGE automatic_closed=true hint_no_search=true hint_uncharged=true stale_discarded=true")
