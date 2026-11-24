extends SceneTree




const CH: GDScript = preload("res://scripts/gameplay/juice_sort/core/juice_challenge.gd")
const ROOT_GUIDE: GDScript = preload("res://scripts/gameplay/juice_sort/tutorial/juice_root_swap_guide.gd")

class RootGuideTestLayer extends JuiceTutorialLayer:
	var playing: bool = false
	var from_point: Vector2 = Vector2.ZERO
	var text: String = ""
	func set_text(value: String, _error: bool = false) -> void :
		text = value
	func hide_text() -> void :
		text = ""
	func play_drag_demo(from_global: Vector2, _to_global_pos: Vector2, _clamp_bottom_y: float) -> void :
		from_point = from_global
		playing = true
	func stop_drag_demo() -> void :
		playing = false
	func is_demo_playing() -> bool:
		return playing
	func is_demo_visible() -> bool:
		return false
	func demo_head_global() -> Vector2:
		return from_point if playing else Vector2.INF

var _failures: Array[String] = []

func _initialize() -> void :
	call_deferred("_run")

func _run() -> void :
	var board_scene: PackedScene = load(
		"res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: Variant = _new_board(board_scene)
	var events: Array[String] = _watch(board)
	_drop(board, 0, 0, 0)
	_check(events == ["drag_ended"], "原列取消仅发 drag_ended: %s" % str(events))
	_check(int(board.state()["done"]) == 0, "原列取消不改盘面")
	_check(int(board.get("_move_attempt_count")) == 0, "原列取消不计失败埋点")
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	_drop(board, 0, 0, -1)
	_check(events == ["drag_ended", "blank_dropped"], "空落点取消发计数信号: %s" % str(events))
	_check(board.steps() == 0, "空落点不增加盘面合法步数")
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	board.set("_drag", {"col": 0, "j": 0, "nodes": [], 
		"pos": Vector2.ZERO, "grab": Vector2.ZERO})
	var ctx: = JuiceDropContext.new(board, 0, 0, -1)
	JuiceDropFlow.run(ctx)
	JuiceDropFlow.finish_now(ctx)
	_check(ctx.handled and events == ["drag_ended", "blank_dropped"], 
		"同步兜底重复调用不重复发信号: %s" % str(events))
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	board.set_move_gate( func(_src: int, _j: int, _dst: int) -> bool: return false)
	_drop(board, 0, 0, 1)
	_check(events == ["drag_ended", "move_blocked"], "门控先于规则拒绝: %s" % str(events))
	_check(int(board.state()["done"]) == 0, "门控拒绝不改盘面")
	_check(int(board.get("_move_attempt_count")) == 0, "门控拒绝不计失败埋点")
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	var rejected: Dictionary = {"reason": -1}
	board.move_rejected.connect( func(reason: int) -> void : rejected["reason"] = reason)
	_drop(board, 0, 0, 2)
	_check(events == ["drag_ended", "move_attempted", "move_rejected"], 
		"规则拒绝先报尝试再报原因: %s" % str(events))
	_check(int(rejected["reason"]) == JuiceRules.Reject.COLOR, 
		"颜色拒绝原因不变: %s" % str(rejected))
	_check(int(board.get("_move_attempt_count")) == 1, "规则拒绝恰计一次失败埋点")
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	rejected = {"reason": -1}
	board.move_rejected.connect( func(reason: int) -> void : rejected["reason"] = reason)
	_drop(board, 0, 0, 3)
	_check(events == ["drag_ended", "move_attempted", "move_rejected"]
		and int(rejected["reason"]) == JuiceRules.Reject.FULL, 
		"容量拒绝原因与信号顺序: %s / %s" % [str(events), str(rejected)])
	_free_board(board)

	board = _new_board(board_scene, {
		"id": 98103, "capacity": 2, "targetCups": 3, 
		"initial": ["0|0", "-|0", {"column": "1|1", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 3}}, "2|2"], 
		"incoming": ["2|2", "x", "x"], 
	})
	events = _watch(board)
	rejected = {"reason": -1}
	board.move_rejected.connect( func(reason: int) -> void : rejected["reason"] = reason)
	_drop(board, 0, 0, 2)
	_check(events == ["drag_ended", "move_attempted", "move_rejected"]
		and int(rejected["reason"]) == JuiceRules.Reject.LOCKED, 
		"锁列拒绝原因与信号顺序: %s / %s" % [str(events), str(rejected)])
	_free_board(board)

	board = _new_board(board_scene, {
		"id": 98104, "capacity": 3, "targetCups": 3, 
		"initial": ["0|?0,0", "1|1", "-|", "2|2"], 
		"incoming": ["2|2", "x", "x"], 
	})
	events = _watch(board)
	rejected = {"reason": -1}
	board.move_rejected.connect( func(reason: int) -> void : rejected["reason"] = reason)
	_drop(board, 0, 0, 1)
	_check(events == ["drag_ended", "move_attempted", "move_rejected"]
		and int(rejected["reason"]) == JuiceRules.Reject.MYSTERY, 
		"问号拒绝原因与信号顺序: %s / %s / %s" %
		[str(events), str(rejected), str(board.state())])
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	_drop(board, 0, 0, 1)
	_check(events.size() >= 3 and events.slice(0, 3) == 
		["drag_ended", "move_attempted", "moved"], 
		"有效移动信号顺序: %s" % str(events))
	_check(int(board.state()["done"]) == 2 and int(board.get("_steps")) == 1, 
		"有效移动同步结算级联两盆和一步: steps=%s state=%s events=%s" %
		[str(board.get("_steps")), str(board.state()), str(events)])
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	_check(_real_drop(board, 0, 0, 1), "真实鼠标输入能抓起花串")
	_check(events.size() >= 3 and events.slice(0, 3) == 
		["drag_ended", "move_attempted", "moved"], 
		"真实鼠标松手进入 Flow: %s" % str(events))
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	board.set_move_gate( func(_src: int, _j: int, _dst: int) -> bool: return false)
	_check(board.try_move(0, 0, 1), "直接 try_move 不受玩家拖拽门控阻拦")
	_check(events.size() >= 2 and events.slice(0, 2) == ["move_attempted", "moved"], 
		"直接 try_move 不发 drag_ended: %s" % str(events))
	_free_board(board)

	board = _new_board(board_scene)
	events = _watch(board)
	var lay: Variant = board.get("_lay")
	board.set("_drag", {"col": 0, "j": 0, "nodes": [], 
		"pos": Vector2(board._col_x(1), lay.plank_top + 10.0), "grab": Vector2.ZERO})
	board.cancel_active_drag()
	_check(events == ["drag_ended"], "生命周期强制取消不判落点: %s" % str(events))
	_free_board(board)

	_test_move_and_restore(board_scene)
	_test_input_gate_ownership(board_scene)
	_test_root_swap_guide_inputs(board_scene)
	await _test_root_rule_switches(board_scene)
	await _test_undo_challenge_suppression(board_scene)
	await _test_dead_searches(board_scene)
	await _test_dead_safe_return(board_scene)
	_test_return_clipping(board_scene)
	_test_drag_head_layer(board_scene)
	_test_collect_after_shift(board_scene)
	_test_mystery_auto_unlock_collect(board_scene)

	await process_frame

	if _failures.is_empty():
		SortLogger.info("JuiceDropFlow selftest PASS")
		quit(0)
	else:
		for failure: String in _failures:
			SortLogger.error("JuiceDropFlow selftest FAIL: %s" % failure)
		quit(1)



func _test_root_rule_switches(board_scene: PackedScene) -> void :
	var live: JuiceLevel = JuiceLevel.from_dict({"id": 98140, "capacity": 3, "targetCups": 2, 
		"initial": ["0|0,0,1", "1|1,1,0", "-|"], "incoming": []})
	var closed: JuiceLevel = JuiceLevel.from_dict({"id": 98141, "capacity": 3, "targetCups": 3, 
		"initial": ["0|1,0,2", "1|2,1,0", "2|0,2,1"], "incoming": []})
	for source: int in [0, 1, 2]:
		for target: int in [0, 1, 2]:
			var label: String = "真实Board切组%d→%d: " % [source, target]
			var board: Variant = board_scene.instantiate()
			board.size = UiMetrics.viewport_size()
			root.add_child(board)
			board.set_process(false)
			board.set_root_adjudication_suspended(true)
			_set_test_root_group(board, source)
			board.setup(live)
			_check(board.show_hint({"move": {"src": 0, "j": 2, "dst": 2}}), 
				label + "旧局真实Hint表现已启动")
			var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))

			saved["hint_dead"] = true
			_set_test_root_group(board, target)
			_check(bool(board.state().get("allow_root_swapping", false)) == (source > 0)
				and board.is_play_after_dead_enabled() == (source == 2), 
				label + "待生效配置不热切当前局")
			_check(board.restore(live, saved), label + "真实JSON快照可恢复")
			_check( not board.has_active_hint()
				and bool(board.state().get("allow_root_swapping", false)) == (target > 0)
				and board.is_play_after_dead_enabled() == (target == 2), 
				label + "恢复清旧Hint并冻结目标规则")
			_check((board.over() == "dead") == (source == 0 and target == 0), 
				label + "仅同规则对照恢复旧Hint死标记")
			_free_board(board)
			await process_frame


	for source: int in [1, 2]:
		for target: int in [0, 1, 2]:
			if source == target:
				continue
			var label: String = "旧CLOSED任务%d→%d: " % [source, target]
			var board: Variant = board_scene.instantiate()
			board.size = UiMetrics.viewport_size()
			root.add_child(board)
			board.set_process(false)
			board.set_root_adjudication_suspended(true)
			_set_test_root_group(board, source)
			board.setup(closed)
			board.set_root_adjudication_suspended(false)
			if not await _wait_test_closed_task(board, label):
				_free_board(board)
				await process_frame
				continue
			_check(bool(board.get("_closed_task_result").get("closed", false))
				and board.over() == "", label + "真实搜索证明封闭，尚未交付死亡")
			var generation: int = int(board.get("_root_closed_generation"))
			board.set_root_adjudication_suspended(true)
			_set_test_root_group(board, target)
			board.setup(live)
			_check(int(board.get("_root_closed_generation")) > generation
				and board.get("_root_closed_cache").is_empty(), label + "新局清缓存并使旧代次失效")
			board._poll_closed_check()
			_check(board.over() == "" and board.root_closed_result().is_empty(), 
				label + "旧封闭结果不能污染新活局或其Hint缓存")
			board.set_root_adjudication_suspended(false)
			if await _wait_test_closed_task(board, label + "新局"):
				board._poll_closed_check()
				_check(board.over() == "" and (target == 0 or 
					String(board.root_closed_result().get("status", "")) == "EXIT"), 
					label + "新局按目标规则判活，实验Hint取得真实首盆路径")
			_free_board(board)
			await process_frame


	for source: int in [0, 1, 2]:
		var board: Variant = board_scene.instantiate()
		board.size = UiMetrics.viewport_size()
		root.add_child(board)
		board.set_process(false)
		board.set_root_adjudication_suspended(true)
		_set_test_root_group(board, source)
		board.setup(closed)
		board.set_root_adjudication_suspended(false)
		if source > 0 and await _wait_test_closed_task(board, "死态源组%d" % source):
			board._poll_closed_check()
		_check(board.over() == "dead", "死态源组%d正式判死" % source)
		var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
		for target: int in [0, 1, 2]:
			var label: String = "死态恢复%d→%d: " % [source, target]
			board.set_root_adjudication_suspended(true)
			_set_test_root_group(board, target)
			_check(board.restore(closed, saved), label + "恢复真实死亡快照")
			board.set_root_adjudication_suspended(false)
			if target > 0 and await _wait_test_closed_task(board, label):
				board._poll_closed_check()
			_check(board.over() == "dead"
				and String(board.get("_pending_dead_reason")) == ("stuck" if target == 0 else "loop")
				and board.can_play_after_dead() == (target == 2), 
				label + "目标规则重判原因，死后操作许可仅实验2")
			_check(board.try_move(0, 0, 1) == (target == 2)
				and board.over() == "dead", label + "只有实验2仍可合法互换，交换不能复活")
		_free_board(board)
		await process_frame


	var wrong_pots: JuiceLevel = JuiceLevel.from_dict({"id": 98142, "capacity": 3, "targetCups": 2, 
		"initial": ["0|1,1,1", "1|0,0,0"], "incoming": []})
	var board: Variant = _new_board(board_scene, {"id": 98142, "capacity": 3, "targetCups": 2, 
		"initial": ["0|1,1,1", "1|0,0,0"], "incoming": []})
	board.set_process(false)
	_check(board.over() == "dead", "错盆完整列对照正式判死")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	for target: int in [1, 2]:
		board.set_root_adjudication_suspended(true)
		_set_test_root_group(board, target)
		_check(board.restore(wrong_pots, saved), "错盆死态可恢复到实验%d" % target)
		board.set_root_adjudication_suspended(false)
		if await _wait_test_closed_task(board, "错盆恢复实验%d" % target):
			board._poll_closed_check()
		_check(board.over() == "" and String(board.root_closed_result().get("status", "")) == "EXIT", 
			"实验%d忽略旧对照死态并得到真实互换首盆路径" % target)
	_free_board(board)
	await process_frame


func _set_test_root_group(board: Variant, group: int) -> void :
	board.set_allow_root_swapping_enabled(group > 0)
	board.set_play_after_dead_enabled(group == 2)


func _wait_test_closed_task(board: Variant, label: String) -> bool:
	var task: int = int(board.get("_closed_task_id"))
	_check(task != -1, label + "后台判定任务已投递")
	if task == -1:
		return false
	for frame: int in range(300):
		if WorkerThreadPool.is_task_completed(task):
			return true
		await process_frame
	_check(false, label + "后台判定任务未在自测等待范围完成")
	return false


func _test_input_gate_ownership(board_scene: PackedScene) -> void :
	var board: Variant = _new_board(board_scene)
	var owned_move: Callable = func(_src: int, _j: int, _dst: int) -> bool: return true
	var owned_grab: Callable = func(_col: int, _j: int) -> bool: return true
	var external_move: Callable = func(_src: int, _j: int, _dst: int) -> bool: return false
	var external_grab: Callable = func(_col: int, _j: int) -> bool: return false
	board.set_move_gate(owned_move)
	board.set_grab_gate(owned_grab)
	_check(board.has_move_gate() and board.has_grab_gate()
		and board.has_move_gate(owned_move) and board.has_grab_gate(owned_grab)
		and not board.has_move_gate(external_move), "门控存在性默认行为保留，身份查询区分调用方")
	board.clear_owned_input_gates(owned_move, external_grab)
	_check( not board.has_move_gate() and board.has_grab_gate(owned_grab), "成对清理逐个核对身份")
	board.set_move_gate(external_move)
	board.set_grab_gate(external_grab)
	board.clear_owned_input_gates(owned_move, owned_grab)
	_check(board.has_move_gate(external_move) and board.has_grab_gate(external_grab), 
		"旧引导不能清掉外部接管后的门控")
	board.clear_owned_input_gates(external_move, external_grab)
	_check( not board.has_move_gate() and not board.has_grab_gate(), "新拥有者可以正常清理门控")
	_free_board(board)


func _test_root_swap_guide_inputs(board_scene: PackedScene) -> void :
	var row: Dictionary = {"id": 98116, "capacity": 3, "targetCups": 4, 
		"initial": ["1|0,0,0", "0|2", "2|1", "3|3", "-|"], "incoming": []}
	var board: Variant = _new_board(board_scene, row, true)
	board.set("_sway_enabled", false)
	var layer: = RootGuideTestLayer.new()
	var guide: JuiceRootSwapGuide = ROOT_GUIDE.new()
	var results: Dictionary = {"completed": 0, "finished": 0}
	guide.completed.connect( func() -> void : results["completed"] += 1)
	guide.finished.connect( func() -> void : results["finished"] += 1)
	guide.setup(board, layer)
	var mv: Dictionary = ROOT_GUIDE.find_swap(board.state(), board.order(), 0)
	_check(mv == {"src": 0, "j": 0, "dst": 1} and guide.start(mv), "真实盘面指定双列互换强制引导启动")
	_check( not _real_drop(board, 2, 0, 0) and not _real_drop(board, 0, 1, 1)
		and not board.has_active_drag(), "真实鼠标输入不能抓其他列或指定列的非首花")
	var initial: String = JuiceSolver._full_state_key(board.state())
	for target: int in [0, 2, -1]:
		_check(_real_drop(board, 0, 0, target), "指定首花可起抓后误放: %d" % target)
		_check(board.steps() == 0 and JuiceSolver._full_state_key(board.state()) == initial
			and guide.is_running() and guide.owns_input_gates()
			and results == {"completed": 0, "finished": 0}, "误放不改盘面、不结束或消费强制引导: %d" % target)
		_settle_return(board)
		guide._process(0.0)
	_check(int(board.get("_move_attempt_count")) == 0, "原列、空白及教学拒绝不增加失败埋点")
	var feedback: Array[Dictionary] = []
	board.moved.connect( func(_steps: int) -> void : feedback.append(board.move_feedback_info()))
	_check(_real_drop(board, 0, 0, 1), "真实玩家可以执行指定交换")
	_check(board.steps() == 1 and int(board.state()["done"]) == 1
		and results == {"completed": 1, "finished": 0}
		and not guide.is_running() and not board.has_move_gate() and not board.has_grab_gate(), 
		"指定真实交换当步收盆才完成，释放全部自有门控")
	_check(feedback.size() == 1 and bool(feedback[0].get("player_drop", false))
		and bool(feedback[0].get("root_swapped", false)) and int(feedback[0].get("src", -1)) == 0
		and int(feedback[0].get("j", -1)) == 0 and int(feedback[0].get("dst", -1)) == 1
		and board.move_feedback_info().is_empty(), "收盆后真实反馈保留来源坐标，调用栈结束后仍清空")
	guide.free()
	layer.free()
	_free_board(board)

	board = _new_board(board_scene, row, true)
	layer = RootGuideTestLayer.new()
	guide = ROOT_GUIDE.new()
	results["completed"] = 0
	results["finished"] = 0
	guide.completed.connect( func() -> void : results["completed"] += 1)
	guide.finished.connect( func() -> void : results["finished"] += 1)
	guide.setup(board, layer)
	_check(guide.start(ROOT_GUIDE.find_swap(board.state(), board.order(), 0)), "直接移动旁路夹具启动")
	_check(board.try_move(0, 0, 1) and int(board.state()["done"]) == 1
		and results == {"completed": 0, "finished": 1}
		and not board.has_move_gate() and not board.has_grab_gate(), 
		"真实 try_move 仍绕过拖拽门控，即使收盆也不消费首次引导")
	guide.free()
	layer.free()
	_free_board(board)

	board = _new_board(board_scene, row)
	layer = RootGuideTestLayer.new()
	guide = ROOT_GUIDE.new()
	guide.setup(board, layer)
	_check(ROOT_GUIDE.find_swap(board.state(), board.order(), 0).is_empty()
		and not guide.start({"src": 0, "j": 0, "dst": 1})
		and not board.has_move_gate() and not board.has_grab_gate(), "对照组盘面不生成交换引导或安装门控")
	_check(_real_drop(board, 0, 0, 1) and board.steps() == 0 and int(board.state()["done"]) == 0, 
		"对照组真实松手维持旧合法性，不增加双列互换")
	guide.free()
	layer.free()
	_free_board(board)


func _test_move_and_restore(board_scene: PackedScene) -> void :
	var row: Dictionary = {"id": 98109, "capacity": 3, "targetCups": 3, 
		"initial": ["0|0,1", "1|1,2", "2|0,1", "-|"], 
		"incoming": ["0|0,2,2", "x"]}
	var board: Variant = _new_board(board_scene, row)
	var initial: String = JuiceSolver._full_state_key(board.state())

	_check(board.state()["jars"] == [0, 1, 2, -1] and board._slot_of[3] == 3, 
		"开局白盆按题面保留在最右侧")
	var legacy: Dictionary = board.snapshot()
	for field: String in ["cols", "jars", "caps", "gone", "locks"]:
		var values: Array = legacy["state"][field]
		values.push_front(values.pop_back())
	var legacy_state: Dictionary = (legacy["state"] as Dictionary).duplicate(true)
	_check(board.restore(board.level(), JSON.parse_string(JSON.stringify(legacy)))
		and board.snapshot()["state"] == legacy_state and board._slot_of[0] == 0, 
		"旧版白盆左置续局原样恢复，不重排已保存盘面")
	board.setup(board.level())
	_check(board._slot_of[3] == 3 and board.state()["jars"] == [0, 1, 2, -1], 
		"重开按真实题面恢复右侧白盆")
	_check((board.state()["cols"][3] as Array).is_empty(), "测试目标确为空列")
	var feedback: Array[Dictionary] = []
	board.moved.connect( func(_steps: int) -> void : feedback.append(board.move_feedback_info()))
	var ctx: = JuiceDropContext.new(board, 0, 1, 3)
	JuiceDropFlow.run(ctx)
	_check(feedback.size() == 1 and not bool(feedback[0].get("same_color_connection", true)), "空列成功放置不误判同色合并")
	_check(board.move_feedback_info().is_empty(), "成功移动回调后清空反馈快照")
	_check(ctx.move_applied and board.steps() == 1, "有效松手同步完成移动")
	JuiceDropFlow.finish_now(ctx)
	_check(board.steps() == 1, "同步兜底不重复移动")
	_check(board.undo() and JuiceSolver._full_state_key(board.state()) == initial, 
		"撤回独立还原移动前的逻辑盘面")
	_check(board.add_rope(), "加绳独立生效")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	_check( not saved.has("reachability_check"), "新快照不保存每步通关预计算结果")

	saved["reachability_check"] = {"level_id": row["id"], 
		"last_reachability": JuiceSolver.Reachability.UNWINNABLE, "checked_key": initial}
	_check(board.restore(board.level(), saved), "旧版额外字段不影响JSON快照恢复")
	_check(board.has_rope() and board.over() == "" and not board.snapshot().has("reachability_check"), 
		"续局保留加绳效果，忽略旧无解结论")
	var operations: Array[int] = []
	board.player_operated.connect( func() -> void : operations.append(1))
	var empty_press: = InputEventMouseButton.new()
	empty_press.button_index = MOUSE_BUTTON_LEFT
	empty_press.pressed = true
	empty_press.position = Vector2(-1000, -1000)
	board._gui_input(empty_press)
	_check(operations.size() == 1 and not board.has_active_drag(), "点盘面空白仍发出操作通知")
	_free_board(board)



func _test_undo_challenge_suppression(board_scene: PackedScene) -> void :
	var row: Dictionary = {"id": 98112, "capacity": 4, "targetCups": 4, 
		"initial": ["-|", "0|0,1,2", "1|1,2,0", "2|2,0,1"], "incoming": []}
	for back_steps: int in [1, 2]:
		var board: Variant = _new_board(board_scene, row)
		board.set_process(false)
		board.set("_resumed_round", true)
		board._cancel_closed_check()
		var events: Array[int] = []
		board.challenge_detected.connect( func(kind: int, _info: Dictionary) -> void : events.append(kind))
		var key: String = JuiceRules.state_key(board.state())
		var info: Dictionary = {"kind": CH.Kind.MASTER, "kind_name": "MASTER"}
		board.get("_challenge_cache")[key] = info
		board.set("_challenge_last_key", "")
		board._start_challenge_check()
		_check(events == [CH.Kind.MASTER], "非撤销盘面仍可命中Challenge缓存")
		events.clear()

		_check(board.try_move(1, 2, 0), "Challenge撤销用例第一次移动成功")
		if back_steps == 2:
			_check(board.try_move(1, 1, 3), "Challenge撤销用例第二次移动成功")
		board._cancel_closed_check()
		var pending_task: int = int(board.get("_challenge_task_id"))
		if pending_task != -1:
			WorkerThreadPool.wait_for_task_completion(pending_task)
			board.set("_challenge_task_id", -1)

		board.set("_challenge_task_key", key)
		board.set("_challenge_task_gen", board.get("_challenge_generation"))
		board.set("_challenge_task_result", {"completed": true, "info": info})
		var task: int = WorkerThreadPool.add_task( func() -> void : return , false, "undo challenge selftest")
		board.set("_challenge_task_id", task)
		while not WorkerThreadPool.is_task_completed(task):
			await process_frame
		_check(board.undo(back_steps), "%d步撤销成功" % back_steps)
		_check(events.is_empty(), "%d步撤销不会同步触发Challenge" % back_steps)
		_check(JuiceRules.state_key(board.state()) == key, "撤销还原原盘面")
		board._poll_challenge_check()
		board._check_over()
		board._start_challenge_check()
		_check(events.is_empty() and board.get("_challenge_task_id") == -1, 
			"撤销后旧任务回传、反复胜负检查和补投均不触发Challenge")

		_check( not board.try_move(1, 2, 2), "无效移动被拒绝")
		board._start_challenge_check()
		_check(events.is_empty(), "无效移动后仍保持撤销限制")
		var next: Dictionary = JuiceRules.clone_state(board.state())
		JuiceRules.apply_move(next, board.level(), 1, 2, 0)
		board.get("_challenge_cache")[JuiceRules.state_key(next)] = info
		_check(board.try_move(1, 2, 0), "撤销后下一次有效移动成功")
		_check(events == [CH.Kind.MASTER], "下一次有效移动恢复Challenge判定")
		board.undo()
		board.setup(board.level())
		board.set("_resumed_round", true)
		board.set("_challenge_last_key", "")
		board.get("_challenge_cache")[JuiceRules.state_key(board.state())] = info
		events.clear()
		board._start_challenge_check()
		_check(events == [CH.Kind.MASTER], "新开局不继承撤销限制")
		_free_board(board)


func _test_dead_searches(board_scene: PackedScene) -> void :
	var board: Variant = _new_board(board_scene, {"id": 98111, "capacity": 3, "targetCups": 3, 
		"initial": ["0|2,1", "1|0,0", "2|1,1"], "incoming": ["0|0,2,2", "x"]})
	var moves: Array = JuiceRules.useful_moves(board.state())
	var move: Dictionary = moves[0]
	_drop(board, int(move["src"]), int(move["j"]), int(move["dst"]))
	_check(board.over() == "dead", "移除预计算后，有效松手仍直接判死")
	for frame: int in range(300):
		if board.safe_return_steps() >= 0:
			break
		await process_frame
	_check(board.safe_return_steps() >= 0, "正式死亡仍完成独立安全回退计算")
	_free_board(board)



func _test_dead_safe_return(board_scene: PackedScene) -> void :
	var row: Dictionary = {"id": 98130, "capacity": 2, "targetCups": 5, 
		"initial": ["0|0", "1|1", "2|2", {"column": "3|4", "columnType": JuiceLevel.LOCK_TYPE, 
			"columnInfo": {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 4}}, "-|0,1", "-|2,3"], 
		"incoming": ["4|3,4", "x", "x", "x"]}
	var board: Variant = _new_board(board_scene, row)
	var initial: String = JuiceSolver._full_state_key(board.state())
	var path: Array = JuiceSolver.hint_win_path(board.state(), board.level(), 
		{"goal_done": 3, "safe_hint": true})
	_check( not path.is_empty(), "回退样例存在三盆安全路线")
	for move: Dictionary in path:
		if int(board.state()["done"]) >= 2:
			break
		_drop(board, int(move["src"]), int(move["j"]), int(move["dst"]))
		for frame: int in range(300):
			if not board.is_busy():
				break
			await process_frame
	_check(int(board.state()["done"]) == 2 and board.over() == ""
		and JuiceRules.has_any_move(board.state()), "样例仍有合法移动且未提示死局")
	board._start_safe_return_search()
	_check(board.get("_safe_task_id") == -1 and board.safe_return_steps() == -1, 
		"尚未判死时不预计算安全回退")
	board.mark_hint_unwinnable()
	for frame: int in range(300):
		if board.safe_return_steps() >= 0:
			break
		await process_frame
	var steps: int = board.safe_return_steps()
	_check(board.over() == "dead" and steps > 1, "Hint判死后独立计算多步安全回退")
	board._start_safe_return_search()
	_check(board.get("_safe_task_id") == -1, "同一死局的完成结果不重复计算")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	var restored: Variant = _new_board(board_scene, row)
	_check(restored.restore(restored.level(), saved), "死局和撤销历史可续局恢复")
	for frame: int in range(300):
		if restored.safe_return_steps() >= 0:
			break
		await process_frame
	_check(restored.over() == "dead" and restored.safe_return_steps() == steps, 
		"续局根据正式死局重新计算相同安全回退距离")
	_free_board(restored)

	board.set_process(false)
	board.set("_safe_return_steps", -1)
	board._start_safe_return_search()
	var generation: int = int(board.get("_safe_return_generation"))
	var task: int = int(board.get("_safe_task_id"))
	_check(task != -1 and board.undo(), "安全回退任务在途时仍可撤回")
	_check(int(board.get("_safe_return_generation")) > generation, 
		"撤回使旧安全回退任务失效")
	for frame: int in range(300):
		if WorkerThreadPool.is_task_completed(task):
			break
		await process_frame
	board._poll_safe_return()
	_check(board.safe_return_steps() == -1, "旧回退结果不应用到撤回后的盘面")
	_check(board.restore(board.level(), saved), "还原正式死局快照")
	board.set_process(true)
	for frame: int in range(300):
		if board.safe_return_steps() >= 0:
			break
		await process_frame
	_check(board.safe_return_steps() == steps and board.undo(steps), "正式死局真实多步撤回成功")
	var restored_key: String = JuiceSolver._full_state_key(board.state())

	_check(JSON.parse_string(restored_key) == JSON.parse_string(initial), 
		"多步撤回盘面对账: steps=%d history=%d expected=%s actual=%s" % [
			steps, board.history_size(), initial, restored_key])
	_free_board(board)



func _test_drag_head_layer(board_scene: PackedScene) -> void :
	var board: Variant = _new_board(board_scene, {
		"id": 98113, "capacity": 4, "targetCups": 3, 
		"initial": ["0|0,0,0", "1|1", "2|2"], 
		"incoming": ["0|0", "1|1,1,1", "2|2,2,2", "x"], 
	})
	board.set("_sway_enabled", false)
	var flowers: Array[JuiceFruit] = board.get("_fruit_nodes")[0]
	board._begin_drag(flowers[0].position)
	_check(flowers[0].z_index > flowers[1].z_index
		and flowers[0].z_index > flowers[2].z_index, 
		"默认起抓当帧首花盖住下方所有花")
	board._update_fruits(0.2)
	_check(flowers[0].z_index > flowers[1].z_index, 
		"首花放大期间保持最高层级")
	board._cancel_drag()
	board._begin_drag(board._fruit_layer_pos(flowers[1]))
	_check(flowers[1].z_index > flowers[2].z_index, 
		"快速再次抓取由新段头取得最高层级")
	board._cancel_drag()
	_settle_return(board)
	for flower: JuiceFruit in flowers:
		_check(flower.z_index == 0 and not flower.top_level, 
			"松手归位后不残留首花高层级")
	board._begin_drag(flowers[0].position)
	_check(flowers[0].z_index > flowers[1].z_index
		and flowers[0].z_index > flowers[2].z_index, 
		"归位后再次抓取仍由首花取得最高层级")
	board._cancel_drag()
	_settle_return(board)
	_free_board(board)



func _test_return_clipping(board_scene: PackedScene) -> void :
	for offset: Vector2 in [Vector2(0, 1200), Vector2(0, -1200), 
			Vector2(-1600, 0), Vector2(1600, 0)]:
		var board: Variant = _new_board(board_scene)
		board.position = Vector2(85, 190)
		board.set("_sway_enabled", false)
		var fruit: JuiceFruit = board.get("_fruit_nodes")[0][0]
		board._begin_drag(fruit.position)
		var drag: Dictionary = board.get("_drag")
		drag["pos"] = board._fruit_layer_pos(fruit) + offset
		board._update_fruits(0.2)
		var before: Vector2 = fruit.global_position
		board._drop_at()
		_check(fruit.top_level and fruit.global_position.is_equal_approx(before), 
			"越界松手保留裁剪豁免且全局位置不跳: %s" % str(offset))
		board.set_content_offset_x(120.0)
		board._update_fruits(1.0 / 60.0)
		board._advance_return()
		_check(fruit.top_level, "未归位前持续脱离裁剪: %s" % str(offset))
		var local_pos: Vector2 = board._fruit_layer_pos(fruit)
		_check( not board._hit_fruit_in_col(local_pos, 0).is_empty(), "飞回中的花按实时局部位置可命中")
		_settle_return(board)
		_check( not fruit.top_level and fruit.z_index == 0
			and fruit.position.distance_to(board._home_pos(0, 0)) <= 1.0, 
			"整段归位后恢复普通层级及局部坐标: %s" % str(offset))
		_free_board(board)

	var board: Variant = _new_board(board_scene)
	board.set("_sway_enabled", false)
	var first: JuiceFruit = board.get("_fruit_nodes")[0][0]
	var second: JuiceFruit = board.get("_fruit_nodes")[2][0]
	board._begin_drag(first.position)
	first.global_position += Vector2(0, 1000)
	board._cancel_drag()
	board._begin_drag(second.position)
	_check(first.top_level and board.get("_return").has(first), "开始另一段拖拽不提前裁剪旧飞回花")
	board._cancel_drag()
	board._begin_drag(board._fruit_layer_pos(first))
	_check( not board.get("_return").has(first) and board.get("_return").has(second), 
		"再次抓取只摘除本段归位记录")
	board._cancel_drag()
	_settle_return(board)
	_check( not first.top_level and not second.top_level, "连续拖拽结束不残留裁剪豁免")
	_free_board(board)

	board = _new_board(board_scene)
	board.position = Vector2(85, 190)
	board.set("_sway_enabled", false)
	first = board.get("_fruit_nodes")[0][0]
	board._begin_drag(first.position)
	first.global_position += Vector2(0, 1000)
	var start_local: Vector2 = board._fruit_layer_pos(first)
	var drag: Dictionary = board.get("_drag")
	drag["pos"] = board._home_pos(1, 1)
	board._drop_at()
	var beats: Array = board.get("_beats")
	var found: bool = false
	for beat: Dictionary in beats:
		var nodes: Array = beat["nodes"]
		var index: int = nodes.find(first)
		if index < 0:
			continue
		found = true
		var lead: float = float(beat["lead"])
		_check(first.top_level and (beat["lead_from"] as PackedVector2Array)[index].is_equal_approx(start_local), 
			"收盆接管保留裁剪豁免，并按局部坐标采样起点")
		board._update_slam_nodes(beat, - lead * 0.5)
		_check(first.top_level, "收盆先归位中段不恢复裁剪")
		board._update_slam_nodes(beat, 0.0)
		var home: Vector2 = Vector2(float(beat["ghost_x"]), 
			float(board.get("_lay").first_fruit_y) + float(index) * float(board.get("_lay").gap))
		_check( not first.top_level and first.position.is_equal_approx(home), 
			"收盆先归位精确落定后才恢复裁剪")
		break
	_check(found, "有效移动收盆实际接管刚松手的花")
	_free_board(board)

	board = _new_board(board_scene)
	first = board.get("_fruit_nodes")[0][0]
	board._begin_drag(first.position)
	first.global_position += Vector2(0, 1000)
	board._cancel_drag()
	board.setup(JuiceLevel.from_dict({"id": 98110, "capacity": 2, "targetCups": 3, 
		"initial": ["0|0", "-|0", "1|1", "2|2,2"], "incoming": ["2|2", "x", "x"]}))
	_check(board.get("_return").is_empty(), "重开清除旧归位记录")
	for list: Array[JuiceFruit] in board.get("_fruit_nodes").values():
		for fruit: JuiceFruit in list:
			_check( not fruit.top_level and fruit.z_index == 0, "回池复用不残留 top_level/z")
	_free_board(board)



func _test_collect_after_shift(board_scene: PackedScene) -> void :
	for real_drop: bool in [false, true]:
		for hitch: bool in [false, true]:
			var label: String = "补位收集 drag=%s hitch=%s: " % [real_drop, hitch]
			var board: Variant = _new_board(board_scene, {
				"id": 98112, "capacity": 3, "targetCups": 3, 
				"initial": ["-|2,1,0", "0|0,0", "1|1,1", "2|2,2"], 
				"incoming": ["x", "x", "x"], 
			})
			board.set_process(false)
			board.set("_sway_enabled", false)
			var cups: Array[int] = []
			var cup_times: Array[float] = []
			var settled_events: Array[bool] = []
			board.cup_collected.connect( func(_t: int, nth: int, _c: Color, _r: Rect2) -> void :
				cups.append(nth)
				cup_times.append(float(board.get("_t"))))
			board.settled.connect( func() -> void : settled_events.append(true))
			_check(board.try_move(0, 2, 1), label + "先完成第一串")
			var active_shift: Dictionary = {}
			for frame: int in range(180):
				board._process(1.0 / 60.0)
				var shifts: Array = board.get("_shift_queue")
				if not shifts.is_empty() and bool(shifts[0]["started"]):
					active_shift = shifts[0]
					break
			_check( not active_shift.is_empty(), label + "第一批补位已开播")
			if active_shift.is_empty():
				_free_board(board)
				continue
			var shift_delay: float = float(board.get("_t")) - cup_times[0]
			_check(shift_delay >= 0.16 - 1.0 / 60.0 and shift_delay <= 0.16 + 2.0 / 60.0, 
				label + "补位在原位开花后、花盆上浮开始时启动")
			var token: int = int(board.get("_visual_token_by_col")[2])
			var original: JuiceFruit = board.get("_fruit_nodes")[2][0]
			var old_x: float = board._col_x(2)
			if real_drop:
				_check(_real_drop(board, 0, 1, 2), label + "补位中真实松手完成第二串")
			else:
				_check(board.try_move(0, 1, 2), label + "补位中直接完成第二串")
			var second: Dictionary = board.get("_beats")[-1]
			_check(board.state()["done"] == 2 and board.sync_error().is_empty(), 
				label + "等待表现时逻辑已结算且节点同步")
			board._process(0.05)
			var current_x: float = float(board.get("_visual_x")[token])
			_check( not is_equal_approx(current_x, old_x)
				and is_equal_approx(float(second["ghost_x"]), current_x)
				and is_equal_approx(original.position.x, current_x), 
				label + "已完成花串与绳一起刚性补位")
			_check( not bool(second["burst_started"]) and not bool(second["cup_sent"])
				and original.z_index == 0 and original.scale.is_equal_approx(Vector2.ONE), 
				label + "补位中不播收集且不靠提层")
			var pot: JuiceBlender = second["blender"]
			_check(is_equal_approx(pot.position.x, current_x), label + "花盆同步补位")

			_check(board.try_move(0, 0, 3), label + "等待中仍可完成另一串")
			var third: Dictionary = board.get("_beats")[-1]
			if hitch:
				board._process(1.0)
			else:
				for frame: int in range(60):
					if not (board.get("_shift_queue") as Array).has(active_shift):
						break
					board._process(1.0 / 60.0)
					if (board.get("_shift_queue") as Array).has(active_shift):
						_check( not bool(second["burst_started"]) and not bool(third["burst_started"]), 
							label + "旧补位结束前两串都等待")
			_check( not (board.get("_shift_queue") as Array).has(active_shift), label + "旧补位完成")
			_check(bool(second["burst_started"]) and bool(third["burst_started"])
				and not bool(second["cup_sent"]) and not bool(third["cup_sent"]), 
				label + "补位结束才开始收集，卡顿也不跳过表演")
			_check(is_equal_approx(float(second["ghost_x"]), float(active_shift["dst"][token])), 
				label + "收集起点为旧补位终点")
			_check(settled_events.is_empty(), label + "等待及收集期间不提前发 settled")
			for frame: int in range(300):
				if not board.is_busy():
					break
				board._process(1.0 / 60.0)
			_check( not board.is_busy() and cups == [0, 1, 2] and settled_events.size() == 1, 
				label + "连续收集最终逐盆交付且只发一次 settled: busy=%s cups=%s settled=%s" %
				[board.is_busy(), str(cups), str(settled_events)])
			_check(board.sync_error().is_empty(), label + "最终节点同步")
			_free_board(board)

	var board: Variant = _new_board(board_scene, {
		"id": 98113, "capacity": 3, "targetCups": 3, 
		"initial": ["-|2,1,0", "0|0,0", "1|1,1", "2|2,2"], "incoming": ["x", "x", "x"], 
	})
	board.set_process(false)
	board.set("_sway_enabled", false)
	_check(board.try_move(0, 2, 1), "补位末帧收集: 先完成第一串")
	for frame: int in range(180):
		board._process(1.0 / 60.0)
		if not (board.get("_shift_queue") as Array).is_empty() and board.get("_shift_queue")[0]["started"]:
			break
	var active_shift: Dictionary = board.get("_shift_queue")[0]
	var end_at: float = float(active_shift["start_at"]) + float(active_shift["dur"])
	for delay: float in (active_shift["delay"] as Dictionary).values():
		end_at = maxf(end_at, float(active_shift["start_at"]) + float(active_shift["dur"]) + delay)
	board._process(maxf(0.0, end_at - float(board.get("_t")) - 0.01))
	var dragged: JuiceFruit = board.get("_fruit_nodes")[0][1]
	_check(_real_drop(board, 0, 1, 2), "补位末帧收集: 真实松手完成第二串")
	var pending: Dictionary = board.get("_beats")[-1]
	board._process(0.02)
	_check( not (board.get("_shift_queue") as Array).has(active_shift)
		and not bool(pending["burst_started"]) and dragged.top_level, 
		"补位末帧收集: 补位结束后未归位的花继续归位，保留裁剪豁免")
	board._process(0.23)
	_check(bool(pending["burst_started"]) and not dragged.top_level, 
		"补位末帧收集: 归位完成后开始脉冲并恢复裁剪")
	board.setup(board.level())
	_check( not board.is_busy() and board.get("_beats").is_empty(), "重开清理收集等待及后续补位")
	_free_board(board)



func _test_mystery_auto_unlock_collect(board_scene: PackedScene) -> void :
	for real_drop: bool in [false, true]:
		for during_shift: bool in [false, true]:
			for enabled: bool in [false, true]:
				var label: String = "问号自动收盆 drag=%s shift=%s enabled=%s: " % [real_drop, during_shift, enabled]
				var row: Dictionary = {
					"id": 98114, "capacity": 3, "targetCups": 2, 
					"initial": ["-|0", "0|0,0", "1|?1,1,1"], "incoming": [], 
				}
				if during_shift:
					row = {
						"id": 98115, "capacity": 3, "targetCups": 3, 
						"initial": ["-|0,2", "2|2,2", "0|0,0", "1|?1,1,1"], "incoming": ["x"], 
					}
				var board: Variant = _new_board(board_scene, row)
				board.set_process(false)
				board.set("_sway_enabled", false)
				var cups: Array[int] = []
				var cup_times: Array[float] = []
				board.cup_collected.connect( func(_type: int, nth: int, _color: Color, _rect: Rect2) -> void :
					cups.append(nth)
					cup_times.append(float(board.get("_t"))))
				board.moved.connect( func(_steps: int) -> void :
					if enabled and board.can_auto_unlock_mystery():
						_check(board.auto_unlock_mystery(), label + "同步移动回调揭色并正式收盆"))
				if during_shift:
					_check(board.try_move(0, 1, 1), label + "先收第一盆启动补位")
					for frame: int in range(180):
						board._process(1.0 / 60.0)
						var shifts: Array = board.get("_shift_queue")
						if not shifts.is_empty() and bool(shifts[0]["started"]):
							break
					_check( not board.get("_shift_queue").is_empty() and board.get("_shift_queue")[0]["started"], 
						label + "补位已开播")
				var dst: int = 2 if during_shift else 1
				if real_drop:
					_check(_real_drop(board, 0, 0, dst), label + "真实松手收倒数第二盆")
				else:
					_check(board.try_move(0, 0, dst), label + "直接移动收倒数第二盆")
				var total: int = int(row["targetCups"])
				_check(board.state()["done"] == (total if enabled else total - 1)
					and board.steps() == (2 if during_shift else 1) and board.sync_error().is_empty(), 
					label + "逻辑同步结算且自动收盆不加步数")
				if enabled:
					var beats: Array = board.get("_beats")
					var preceding: Dictionary = beats[-2]
					var automatic: Dictionary = beats[-1]
					_check(is_equal_approx(float(preceding["lead"]), float(automatic["lead"])), 
						label + "同一步两批收盆共用归位等待")
					if real_drop:
						_check(float(preceding["lead"]) > 0.0, label + "真实拖拽确实产生归位等待")

				if during_shift:
					board._process(0.4)
				for frame: int in range(300):
					if not board.is_busy():
						break
					board._process(1.0 / 60.0)
				var expected: Array[int] = []
				for nth: int in range(total if enabled else total - 1):
					expected.append(nth)
				_check( not board.is_busy() and cups == expected, 
					label + "按逻辑订单槽位顺序交付: cups=%s times=%s" % [str(cups), str(cup_times)])
				if enabled and cup_times.size() >= 2:
					_check(cup_times[-1] >= cup_times[-2], label + "末盆起飞不早于前一盆")
				_free_board(board)


func _settle_return(board: Variant) -> void :
	for frame: int in range(180):
		board._update_fruits(1.0 / 60.0)
		board._advance_return()
		if board.get("_return").is_empty():
			return
	_check(false, "归位未能在180帧内结束")


func _new_board(board_scene: PackedScene, row: Dictionary = {}, allow_root_swapping: bool = false) -> Variant:
	if row.is_empty():
		row = {
		"id": 98102, "capacity": 2, "targetCups": 3, 
		"initial": ["-|0", "0|0", "1|1", "2|2,2"], 
		"incoming": ["2|2", "x", "x"], 
		}
	var level: JuiceLevel = JuiceLevel.from_dict(row)
	var board: Variant = board_scene.instantiate()
	board.size = Vector2(1080, 2340)
	root.add_child(board)
	board.set_allow_root_swapping_enabled(allow_root_swapping)
	board.setup(level)
	return board


func _watch(board: Variant) -> Array[String]:
	var events: Array[String] = []
	board.drag_ended.connect( func() -> void : events.append("drag_ended"))
	board.blank_dropped.connect( func() -> void : events.append("blank_dropped"))
	board.move_blocked.connect( func(_src: int, _j: int, _dst: int) -> void : events.append("move_blocked"))
	board.move_attempted.connect( func(_info: Dictionary) -> void : events.append("move_attempted"))
	board.move_rejected.connect( func(_reason: int) -> void : events.append("move_rejected"))
	board.moved.connect( func(_steps: int) -> void : events.append("moved"))
	return events


func _drop(board: Variant, src: int, j: int, target: int) -> void :
	var lay: Variant = board.get("_lay")
	board.set("_drag", {
		"col": src, "j": j, "nodes": [], 
		"pos": Vector2(board._col_x(target), lay.plank_top + 10.0)
			if target >= 0 else Vector2(-1000.0, -1000.0), 
		"grab": Vector2.ZERO, 
	})
	board._drop_at()


func _real_drop(board: Variant, src: int, j: int, target: int) -> bool:
	var fruit: Node2D = ((board.get("_fruit_nodes") as Dictionary)[src] as Array)[j] as Node2D
	var start: Vector2 = board.get_global_transform().affine_inverse() * fruit.global_position
	var press: = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	board._gui_input(press)
	var drag: Dictionary = board.get("_drag")
	if drag.is_empty():
		return false
	var lay: Variant = board.get("_lay")
	var end: Vector2 = (Vector2(board._col_x(target), lay.plank_top + 10.0)
		if target >= 0 else Vector2(-1000.0, -1000.0)) + drag["grab"]
	var motion: = InputEventMouseMotion.new()
	motion.position = end
	board._gui_input(motion)
	var release: = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = end
	board._gui_input(release)
	return true


func _free_board(board: Variant) -> void :
	board.set_process(false)
	board._cancel_closed_check()

	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()


func _check(condition: bool, message: String) -> void :
	if not condition:
		_failures.append(message)
