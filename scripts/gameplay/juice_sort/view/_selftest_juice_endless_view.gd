extends SceneTree

const BOARD: PackedScene = preload("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
var failures: Array[String] = []
var _prepared: Dictionary = {}


func _initialize() -> void :
	call_deferred("_run")


func check(value: bool, message: String) -> void :
	if not value:
		failures.append(message)
		SortLogger.error("ENDLESS_VIEW " + message)


func new_board(session: JuiceEndlessSession) -> JuiceBoardView:
	session.queue_mode = true
	if session.incoming.is_empty():
		check(session.enqueue(_queue_for(session.seed)), "装入五列预生成缓存")
	var board: JuiceBoardView = BOARD.instantiate() as JuiceBoardView
	board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	root.add_child(board)
	board.setup_endless(session)
	board.set_process(false)
	return board


func _queue_for(seed_value: int) -> Array:
	if _prepared.has(seed_value):
		return (_prepared[seed_value] as Array).duplicate(true)
	var stream: Dictionary = {"seed": seed_value, "sequence": 0}
	var entries: Array[Dictionary] = []
	for i in 5:
		var result: Dictionary = JuiceEndlessGenerator.next_stream(stream, {"now": Time.get_ticks_msec})
		if not bool(result.get("ok", false)):
			check(false, "参考盘面可预生成第%d列" % i)
			break
		entries.append(result["entry"])
		stream = result["stream"]
	_prepared[seed_value] = entries
	return entries.duplicate(true)


func advance(board: JuiceBoardView, frames: int = 240) -> void :
	for i in frames:
		board._process(1.0 / 60.0)


func _run() -> void :
	var session: = JuiceEndlessSession.new(42)
	var board: JuiceBoardView = new_board(session)
	var events: Array[String] = []
	board.settled.connect( func() -> void : events.append("settled"))
	board.won.connect( func() -> void : events.append("won"))
	board.cup_collected.connect( func(_color: int, _nth: int, _tint: Color, _rect: Rect2) -> void : events.append("cup"))
	board.endless_refill_requested.connect( func() -> void : events.append("request"))
	var opening: Array[Dictionary] = JuiceEndlessSettings.opening_moves(session.seed)
	for move: Dictionary in opening.slice(0, opening.size() - 1):
		check(board.try_move(int(move["src"]), int(move["j"]), int(move["dst"])), "开局整理移动")
		advance(board)

	var last: Dictionary = opening[-1]
	check(real_drop(board, int(last["src"]), int(last["j"]), int(last["dst"])), "玩家松手有效移动")
	check(int(session.state["done"]) == 1 and session.pending.is_empty() and session.incoming.size() == 4, 
		"松手当帧消费预生成补列")
	check( not JuiceRules.any_ready(session.state), "无尽正式收盆及mixed补列同帧不残留ready")
	check(events.count("request") == 1 and board.is_busy(), "收盆拍已入队")
	check(board._can_play() and board._replenish_column_pending(int(last["dst"])), "只保护尚未入场的新列")
	var beat: Dictionary = (board.get("_beats") as Array)[-1]
	var expected_start: float = float(beat["t0"]) + board._slam_len(int(beat["q"]), board._burst_dur(beat))
	var shift: Dictionary = (board.get("_shift_queue") as Array)[0]
	check(is_equal_approx(float(shift["start_at"]), expected_start), "补位时机与普通页一致")
	check(_move_existing(board), "收盆期间其他列可真实拖放")
	for frame in 180:
		board._process(1.0 / 60.0)
		if bool(shift.get("started", false)) and not bool(shift.get("finished", false)):
			break
	check(bool(shift.get("started", false)), "普通补位已启动")
	check(_move_existing(board), "补位期间其他列可真实拖放")
	advance(board)
	check(events.count("settled") == 1 and not board.is_busy(), "补位结束自然发一次settled")
	check(events.count("cup") == 1, "收盆只交付一次")
	check(board.sync_error() == "" and board.over() == "", "画与算一致且没有有限判胜")
	check((board.get("_order") as Array)[-1] == int(last["dst"]), "新盆从最右补位")
	check(events.count("won") == 0, "无尽不发won")
	check(int(board.get("_safe_task_id")) == -1, "无尽不启动有限关救援搜索")
	board.queue_free()
	await process_frame
	_test_continuous_collect()
	_test_death()
	await process_frame
	await _test_shared_death()
	await _test_rope()
	await _test_controller_lifecycle()
	await _test_root_dead_attempt()
	await _test_root_ready_invariant()
	if failures.is_empty():
		SortLogger.info("ENDLESS_VIEW PASS")
	quit(0 if failures.is_empty() else 1)


func _move_existing(board: JuiceBoardView) -> bool:
	for mv: Dictionary in JuiceRules.useful_moves(board.state()):
		if board._replenish_column_pending(int(mv["src"])) or board._replenish_column_pending(int(mv["dst"])):
			continue
		var trial: = JuiceEndlessSession.new(1)
		trial.state = JuiceRules.clone_state(board.state())
		var rec: Dictionary = trial.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		if not rec.is_empty() and (rec["deposits"] as Array).is_empty():
			var before: int = board.steps()
			real_drop(board, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			return board.steps() == before + 1
	return false


func _test_continuous_collect() -> void :
	var session: = JuiceEndlessSession.new(42)
	var board: JuiceBoardView = new_board(session)
	var opening: Array[Dictionary] = JuiceEndlessSettings.opening_moves(42)
	for i in opening.size():
		var mv: Dictionary = opening[i]
		check(board.try_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])), "连续收盆开局移动")
		if i < opening.size() - 1:
			advance(board)
	for frame in 180:
		board._process(1.0 / 60.0)
		if not board._replenish_column_pending(int(opening[-1]["dst"])) and not (board.get("_shift_queue") as Array).is_empty():
			break
	check( not (board.get("_shift_queue") as Array).is_empty(), "第一批补位尚在播放")
	var active: Dictionary = (board.get("_shift_queue") as Array)[0]
	for mv: Dictionary in session.last_incoming["reference_path"] as Array:
		check(board.try_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])), "补位中继续整理并收盆")
	check(int(session.state["done"]) >= 2 and session.pending.is_empty(), "连续收盆直接消费下一缓存")
	var next_beat: Dictionary = (board.get("_beats") as Array)[-1]
	check(next_beat.get("waiting_shift", {}) == active and is_inf(float(next_beat["t0"])), "新收盆先跟随当前补位")
	advance(board, 420)
	check(board.sync_error() == "" and not board.is_busy(), "连续收盆和补位最终一致")
	board.queue_free()


func real_drop(board: JuiceBoardView, src: int, j: int, dst: int, before_release: Callable = Callable()) -> bool:
	var fruit: Node2D = (board.get("_fruit_nodes")[src] as Array)[j] as Node2D
	var press: = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = board.get_global_transform().affine_inverse() * fruit.global_position
	board._gui_input(press)
	var drag: Dictionary = board.get("_drag")
	if drag.is_empty():
		return false
	var release: = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(board._col_x(dst), board.get("_lay").plank_top + 10.0) + drag["grab"]
	var motion: = InputEventMouseMotion.new()
	motion.position = release.position
	if before_release.is_valid():
		before_release.call()
	board._gui_input(motion)
	board._gui_input(release)
	return true


func _test_death() -> void :
	var session: = JuiceEndlessSession.new(1)
	session.state["cols"][0] = [5, 5, 5, 5, 5] as Array[int]
	for ci in range(1, 6):
		session.state["cols"][ci] = [ci - 1, ci - 1, ci - 1, ci - 1] as Array[int]
		session.state["jars"][ci] = ci - 1
	var board: JuiceBoardView = new_board(session)
	check(board.over() == "dead", "无任何合法移动才死亡")
	check(int(board.get("_death_task_id")) == -1 and int(board.get("_safe_task_id")) == -1, 
		"死亡也不启动有限关救援搜索")
	board.queue_free()
	session = JuiceEndlessSession.new(2)
	for ci in range(1, 6):
		session.state["jars"][ci] = 9
	board = new_board(session)
	check(board.over() == "", "花账缺少目标色但可移动时不判死")
	board.queue_free()


func _loop_session() -> JuiceEndlessSession:
	var session: = JuiceEndlessSession.new(42)

	session.state["cols"] = [[0, 0, 0] as Array[int], [0, 0, 0, 0] as Array[int], 
		[1, 1, 1, 1] as Array[int], [2, 2, 2] as Array[int], 
		[3, 3, 3] as Array[int], [4, 4, 4] as Array[int]]
	session.state["jars"] = [-1, 1, 0, 2, 3, 4] as Array[int]
	return session


func _wait_dead(board: JuiceBoardView) -> void :
	var deadline: int = Time.get_ticks_msec() + 2000
	while board.over() == "" and Time.get_ticks_msec() < deadline:
		board._process(1.0 / 60.0)
		await process_frame


func _test_shared_death() -> void :
	var session: JuiceEndlessSession = _loop_session()
	check(JuiceRules.has_any_move(session.state), "漏判夹具仍能合法来回搬动")
	var board: JuiceBoardView = new_board(session)
	await _wait_dead(board)
	check(board.over() == "dead" and board.get("_pending_dead_reason") == "loop", "无尽也由普通页后台封闭循环判死")
	board.queue_free()
	await process_frame
	var ordinary_level: JuiceLevel = JuiceLevel.from_dict({"id": 1, "capacity": 5, "targetCups": 5, 
		"initial": ["-|0,0,0", "1|0,0,0,0", "0|1,1,1,1", "2|2,2,2", "3|3,3,3", "4|4,4,4"], "incoming": []})
	board = BOARD.instantiate() as JuiceBoardView
	board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	root.add_child(board)
	board.setup(ordinary_level)
	board.set_process(false)
	await _wait_dead(board)
	check(board.over() == "dead" and board.get("_pending_dead_reason") == "loop", "相同盘面与普通游戏页判死一致")
	board.queue_free()
	await process_frame

	board = new_board(_loop_session())
	var press: = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	var fruit: Node2D = (board.get("_fruit_nodes")[0] as Array)[2]
	press.position = board.get_global_transform().affine_inverse() * fruit.global_position
	board._gui_input(press)
	check( not (board.get("_drag") as Dictionary).is_empty(), "封闭检查期间真实抓起花")
	var deadline: int = Time.get_ticks_msec() + 2000
	var task: int = int(board.get("_closed_task_id"))
	while task >= 0 and not WorkerThreadPool.is_task_completed(task) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(task >= 0 and WorkerThreadPool.is_task_completed(task), "封闭检查在后台完成")
	board._poll_closed_check()
	check(board.over() == "", "拖拽中不提前落死亡判定")
	board.set_input_enabled(false)
	await _wait_dead(board)
	check(board.over() == "dead", "取消拖拽后接收普通页封闭结论")
	board.queue_free()
	await process_frame
	board = new_board(_loop_session())
	var restarted: = JuiceEndlessSession.new(42, true)
	check(restarted.enqueue(_queue_for(42)), "重开预生成队列准备")
	board.setup_endless(restarted)
	for i in 10:
		board._process(1.0 / 60.0)
		await process_frame
	check(board.over() == "" and board._can_play(), "旧封闭结果不能判死重开的可解盘面")
	board.queue_free()
	await process_frame


func _test_rope() -> void :
	var session: = JuiceEndlessSession.new(42)
	var board: JuiceBoardView = new_board(session)
	var expected: Dictionary = JuiceRules.clone_state(session.state)
	var counts: Dictionary = JuiceEndlessSession.inventory(session.state)
	var incoming: Array = session.incoming.duplicate(true)
	var move: Dictionary = JuiceEndlessSettings.opening_moves(42)[0]
	check(board.try_move(int(move.src), int(move.j), int(move.dst)), "加绳前建立撤回记录")
	advance(board)
	check(board.add_rope(), "无尽进行中允许加绳")
	advance(board)
	check(board.has_rope() and (session.state["cols"] as Array).size() == 7
		and int(session.state["caps"][6]) == 5 and int(session.state["jars"][6]) == JuiceRules.NO_JAR, 
		"新增一根容量5的白色暂存绳")
	check( not board.add_rope() and not board.revive_with_rope(), "每局只加一次且无尽不走复活入口")
	check(JuiceRules.add_rope(expected, 5) == 6 and board.undo(), "撤回加绳前的旧操作")
	check(board.has_rope() and JuiceRules.state_key(session.state) == JuiceRules.state_key(expected)
		and session.incoming == incoming, "撤回保留绳子并恢复原盘面及补列队列")
	var moved: bool = false
	for src in JuiceEndlessSettings.COLUMNS:
		var column: Array = session.state["cols"][src]
		if not column.is_empty():
			moved = board.try_move(src, column.size() - 1, 6)
			break
	check(moved, "花朵可移到新增绳子")
	advance(board)
	check(JuiceEndlessSession.inventory(session.state) == counts, "库存统计包含新增绳子上的花朵")
	check(board.undo() and board.has_rope() and board.sync_error() == "", "使用新增绳子后撤回保持画与算一致")
	board.queue_free()
	await process_frame


func _test_controller_lifecycle() -> void :
	var board: JuiceBoardView = new_board(JuiceEndlessSession.new(42))
	var controller: = JuiceEndlessController.new()
	root.add_child(controller)
	controller.attach(board)
	var ticks: Dictionary = {"now": 1000000}
	controller.clock = func() -> int: return int(ticks["now"])
	controller.start(42, false)
	await _wait_queue(controller, 5)
	check(controller.remaining_ms() == 120000 and not board._can_play(), "入场未交接前不计时或放行")
	controller.activate_after_entry()
	ticks["now"] += 1000
	check(controller.remaining_ms() == 120000 and board._can_play(), "入场交接只放行操作，不启动计时")
	controller.pause(&"background")
	ticks["now"] += 5000
	controller.resume(&"background")
	check(controller.remaining_ms() == 120000, "未拖花前后台恢复仍等首次操作")
	controller.on_flower_touched()
	ticks["now"] += 1000
	check(controller.remaining_ms() == 119000, "首次拖花开始计时")
	controller.pause(&"menu")
	controller.pause(&"ad")
	ticks["now"] += 9000
	controller.resume(&"menu")
	check(controller.remaining_ms() == 119000 and not board._can_play(), "多暂停原因独立保留")
	controller.resume(&"ad")
	check(controller.remaining_ms() == 119000 and board._can_play(), "全部暂停解除后保留剩余时间")
	for mv: Dictionary in JuiceEndlessSettings.opening_moves(42):
		check(board.try_move(int(mv.src), int(mv.j), int(mv.dst)), "控制器实盘收盆")
		advance(board)
	var refill: Dictionary = controller.session.last_incoming.duplicate(true)
	check(controller.remaining_ms() == 122000 and int(controller.session.state["done"]) == 1, "收盆加三秒")
	check(board.undo() and int(controller.session.state["done"]) == 0 and controller.remaining_ms() == 122000, "撤回盆数但不扣已得加时")
	var last: Dictionary = JuiceEndlessSettings.opening_moves(42)[-1]
	check(board.try_move(int(last.src), int(last.j), int(last.dst)), "撤回后重新收盆")
	check(controller.remaining_ms() == 125000 and controller.session.last_incoming == refill, "重收复用原补列并再次加三秒")
	check(controller.session.incoming.size() <= 5 and controller.archive_size() <= controller.ARCHIVE_LIMIT, "活动缓存及撤回档案有界")
	check( not board.revive_with_rope(), "无尽不走绳子复活入口")
	ticks["now"] += 125000
	controller._process(0.0)
	check(controller.end_reason == "time_up" and not board._can_play(), "时间到结束")
	check( not board.add_rope(), "时间到后禁止直接加绳")
	controller.start(42)
	await _wait_queue(controller, 5)
	var path: Array = JuiceEndlessSettings.opening_moves(42)
	for collected in 40:
		for mv: Dictionary in path:
			check(board.try_move(int(mv.src), int(mv.j), int(mv.dst)), "控制器长局真实移动")
			check( not JuiceRules.any_ready(controller.session.state), "合法长局每步Session收净ready")
			advance(board)
		path = controller.session.last_incoming["reference_path"]
		await _wait_queue(controller, 5)
		check(controller.archive_size() <= controller.ARCHIVE_LIMIT and controller.session.incoming.size() == 5, "长局活动FIFO及档案保持上限")
	check(int(controller.session.state["done"]) == 40, "控制器累计盆数不受明细32上限影响")
	var frontier: int = int(controller._stream["sequence"])
	check(board.undo(32), "真实连续32步撤回")
	check(int(controller._stream["sequence"]) == frontier and controller.session.incoming.size() == 5, "多步撤回不倒退后台游标并保留固定五列")
	controller.cancel()
	while not controller._retired.is_empty():
		controller._process(0.0)
		await process_frame
	controller.queue_free()
	board.queue_free()
	await process_frame


func _wait_queue(controller: JuiceEndlessController, count: int) -> void :
	var deadline: int = Time.get_ticks_msec() + 10000
	while controller.session.incoming.size() < count and Time.get_ticks_msec() < deadline:
		await process_frame
	check(controller.session.incoming.size() >= count, "后台缓存达到目标%d列" % count)


func _root_dead_state(session: JuiceEndlessSession) -> Dictionary:
	var state: Dictionary = JuiceRules.clone_state(session.state)
	state["cols"] = []
	for color in 6:
		state["cols"].append([color, color, color] as Array[int])
	state["jars"] = [-1, 0, 1, 2, 3, 4] as Array[int]
	return state


func _test_root_dead_attempt() -> void :
	var board: JuiceBoardView = new_board(JuiceEndlessSession.new(42))
	var controller: = JuiceEndlessController.new()
	root.add_child(controller)
	controller.attach(board)
	var endings: Array[String] = []
	controller.round_finished.connect( func(_cups: int, reason: String) -> void : endings.append(reason))
	var ticks: Dictionary = {"now": 2000000}
	controller.clock = func() -> int: return int(ticks["now"])
	board.set_allow_root_swapping_enabled(true)
	board.set_play_after_dead_enabled(true)
	board.set_root_adjudication_suspended(true)
	controller.start(42, false)
	await _wait_queue(controller, 5)
	controller.session.state = _root_dead_state(controller.session)
	board.setup_endless(controller.session, controller.can_apply_board_move)
	board.set_process(false)
	check(board.over() == "" and not bool(controller.get("_time_started")), "组2中间盘未判死且未提前计时")
	board.set_root_adjudication_suspended(false)
	await _wait_dead(board)
	check(board.over() == "dead" and controller.end_reason == "" and endings.is_empty()\
	and not bool(controller.get("_time_started")), "组2初始严格死局进入尝试但等待入场后计时")
	controller.activate_after_entry()
	check(controller.can_operate_dead() and not controller.can_move()\
	and bool(controller.get("_time_started")) and controller.remaining_ms() == 120000, "稳定入场后死态可操作并启动倒计时")
	var before: String = JuiceSolver.root_closed_state_key(board.state())
	check(board.try_move(0, 0, 1) and board.steps() == 1 and board.history_size() == 1\
	and board.over() == "dead" and JuiceSolver.root_closed_state_key(board.state()) != before, "无尽死态徒手交换真实Session与历史")
	check( not board.add_rope() and not board.revive_with_rope(), "无尽死态仍禁止Rope及绳子复活")
	check(int(board.get("_death_task_id")) == -1 and int(board.get("_safe_task_id")) == -1, "无尽尝试不启动有限救援归因")
	ticks["now"] += 1000
	check(controller.remaining_ms() == 119000 and controller.end_reason == "" and endings.is_empty(), "尝试思考计时继续且不结束")
	controller.pause(&"background")
	ticks["now"] += 5000
	check( not controller.can_operate_dead() and not board._can_play(), "死态仍遵守后台暂停输入")
	controller.resume(&"background")
	check(controller.remaining_ms() == 119000 and controller.can_operate_dead(), "恢复尝试保留暂停前剩余时间")
	check(board.undo() and board.steps() == 0 and board.history_size() == 0\
	and JuiceSolver.root_closed_state_key(board.state()) == before\
	and controller.get("_dead_attempt_reason") == "" and controller.can_move(), "真实Undo清死亡并恢复生产/活局资格")
	await _wait_dead(board)
	check(controller.end_reason == "" and endings.is_empty() and controller.can_operate_dead(), "撤回仍死重新尝试而不结束整局")
	ticks["now"] += 119000
	controller._process(0.0)
	controller._process(0.0)
	check(controller.end_reason == "time_up" and endings == ["time_up"] and not board._can_play()\
	and not controller.can_operate_dead(), "尝试阶段时间到仍正常且只结束一次")
	controller.cancel()
	while not controller._retired.is_empty():
		controller._process(0.0)
		await process_frame
	controller.queue_free()
	board._cancel_closed_check()
	board.queue_free()
	await process_frame
	AudioManager.stop_sfx(&"juice_dead")


func _test_root_ready_invariant() -> void :
	var session: = JuiceEndlessSession.new(42)
	session.state["cols"][0] = [0, 0, 0, 0, 0] as Array[int]
	session.state["jars"][0] = 0
	for ci in range(1, 6):
		session.state["cols"][ci] = [] as Array[int]
		session.state["caps"][ci] = 0
		session.state["gone"][ci] = true
	var board: JuiceBoardView = BOARD.instantiate() as JuiceBoardView
	root.add_child(board)
	board.set_allow_root_swapping_enabled(true)
	board.setup_endless(session)
	board.set_process(false)
	board.ensure_root_closed_check()
	var deadline: int = Time.get_ticks_msec() + 2000
	while int(board.get("_closed_task_id")) != -1 and Time.get_ticks_msec() < deadline:
		board._poll_closed_check()
		await process_frame
	check(board.over() == "" and board.root_closed_result().get("reason") == "ready_pending_collect"\
	and int(session.state["done"]) == 0, "人工无尽ready/no_moves不误判CLOSED且不绕过FIFO真实结算")
	board._cancel_closed_check()
	board.queue_free()
	await process_frame
