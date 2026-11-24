extends Node
const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")


class ProbePage:
	extends JuiceGamePage
	func _ready() -> void :
		set_process(false)
	func apply_move_feedback(_steps: int) -> void :
		pass
	func queue_move_prop_refresh() -> void :
		pass
	func _refresh_prop_btns(_force: bool = false, _skip: String = "") -> void :
		pass
	func _sync_level_card() -> void :
		pass

var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _check(condition: bool, message: String) -> void :
	if not condition:
		_failures.append(message)
		SortLogger.error("EmptyColFeedback: " + message)


func _run() -> void :
	DbManager.init()
	LevelManager.register_parser(JuiceLevelParser.new())
	_test_qualification()
	_test_history_window()
	_test_white_pots_and_other_collection()
	_test_spiral_parameters()
	await _test_tutorial_and_redo()
	await _test_round_and_playback()
	if _failures.is_empty():
		SortLogger.info("EMPTY_COL_FEEDBACK_SELFTEST PASS")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _row() -> Dictionary:
	return {"id": 6, "capacity": 6, "targetCups": 3, 
		"initial": ["0|1,1", "1|1,1", "2|2,2,0,0,0,0"], 
		"incoming": ["-|0,0,1,1", "-|2,2,2,2"]}



func _prepare_no_empty_history(board: JuiceBoardView, count: int = 10) -> void :
	var cols: Array = board._state["cols"]
	var src: int = 0 if (cols[0] as Array).size() > 1 else 1
	for i in count:
		var from_col: int = src if i % 2 == 0 else 1 - src
		var dst: int = 1 - from_col
		_check(board._apply_valid_drop(from_col, (cols[from_col] as Array).size() - 1, dst), 
			"准备无空绳有效移动: %d" % i)
		_check(board._tracking_empty_rope_count(board._state) == 0, "准备移动结算后没有空绳")


func _board(row: Dictionary) -> JuiceBoardView:
	var board: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	board.size = Vector2(1080, 2340)
	add_child(board)
	board.setup(JuiceLevel.from_dict(row))
	return board


func _capture(board: JuiceBoardView) -> Array[Dictionary]:
	var captured: Array[Dictionary] = []
	board.moved.connect( func(_steps: int) -> void :
		captured.append(board.take_empty_rope_feedback())
		_check(board.take_empty_rope_feedback().is_empty(), "同一操作资格只消费一次"))
	return captured


func _test_qualification() -> void :
	var board: JuiceBoardView = _board(_row())
	_prepare_no_empty_history(board)
	var captured: Array[Dictionary] = _capture(board)
	_check(board._apply_valid_drop(0, 0, 1), "玩家搬空源绳成功")
	_check(captured.size() == 1 and not captured[0].is_empty(), "无空绳到有空绳触发")
	var operation_key: String = captured[0]["operation_key"]
	_check( not operation_key.is_empty(), "反馈资格包含稳定操作标识")
	var provider: Callable = captured[0]["rope_geometry"]
	var geometry: Dictionary = provider.call()
	_check((geometry["top"] as Vector2).y < (geometry["bottom"] as Vector2).y, "源绳顶部与尾部几何")
	board._content_dx += 45.0
	var moved_geometry: Dictionary = provider.call()
	_check(absf((moved_geometry["bottom"] as Vector2).x - (geometry["bottom"] as Vector2).x - 45.0) < 0.01, 
		"螺旋几何跟随盘面横移")
	board._visual_token_by_col[0] = -1
	_check((provider.call() as Dictionary).is_empty(), "源绳 token 失效后不跟到复用列")
	_check(board.take_empty_rope_feedback().is_empty(), "moved 返回后不遗留资格")
	board.undo()
	board._apply_valid_drop(0, 0, 1)
	_check(captured[1]["operation_key"] == operation_key, "撤销重建节点后同一操作标识不变")
	board.undo()
	board._apply_valid_drop(1, 0, 0)
	_check(captured[2]["operation_key"] != operation_key, "相同盘面的不同搬动有独立标识")
	board._cancel_closed_check()
	board.free()

	board = _board(_row())
	_prepare_no_empty_history(board)
	captured = _capture(board)
	_check(board.try_move(0, 0, 1), "直接调试移动成功")
	_check(captured.size() == 1 and captured[0].is_empty(), "非玩家入口不触发")
	board._cancel_closed_check()
	board.free()

	var row: Dictionary = _row()
	row["initial"] = ["-|", "0|1", "1|1", "2|2,2,0,0"]
	board = _board(row)
	captured = _capture(board)
	board._apply_valid_drop(1, 0, 2)
	_check(captured.size() == 1 and captured[0].is_empty(), "已有空绳不触发")
	board._cancel_closed_check()
	board.free()

	row = {"id": 6, "capacity": 2, "targetCups": 3, 
		"initial": ["0|0,1", "1|1", "2|2"], "incoming": ["-|0", "-|2"]}
	board = _board(row)
	captured = _capture(board)
	board._apply_valid_drop(0, 1, 1)
	_check(captured.size() == 1 and captured[0].is_empty(), "仅收盆/补列腾空不触发")
	board._cancel_closed_check()
	board.free()

	row = {"id": 6, "capacity": 6, "targetCups": 3, 
		"initial": ["0|1,1", "1|1,1,1,1", "2|2,2,0,0,0,0"], 
		"incoming": ["-|0,0", "-|2,2,2,2"]}
	board = _board(row)
	_prepare_no_empty_history(board)
	captured = _capture(board)
	board._apply_valid_drop(0, 0, 1)
	_check( not board.last_move_deposits().is_empty(), "搬走的花在目标绳凑满并被收集")
	_check(captured.size() == 1 and captured[0].is_empty(), "本次搬走的花被收集不反馈腾空")
	board._cancel_closed_check()
	board.free()


func _test_history_window() -> void :
	for previous_steps: int in [0, 9, 10]:
		var board: JuiceBoardView = _board(_row())
		_prepare_no_empty_history(board, previous_steps)
		var captured: Array[Dictionary] = _capture(board)
		board._apply_valid_drop(0, 0, 1)
		_check(captured.size() == 1 and captured[0].is_empty() == (previous_steps < 10), 
			"此前%d步：必须满10步，本次腾空不计入窗口" % previous_steps)
		board._cancel_closed_check()
		board.free()

	var board: JuiceBoardView = _board(_row())
	_prepare_no_empty_history(board)
	board._apply_valid_drop(0, 0, 1)
	board._apply_valid_drop(1, 3, 0)
	_prepare_no_empty_history(board, 8)
	var captured: Array[Dictionary] = _capture(board)
	board._apply_valid_drop(0, 0, 1)
	_check(captured[-1].is_empty(), "前10步的最早一步仍有空绳，不反馈")
	board.undo()
	_prepare_no_empty_history(board, 1)
	board._apply_valid_drop(0, 0, 1)
	_check( not captured[-1].is_empty(), "空绳记录移出窗口，连续10步无空绳后恢复资格")
	board.undo()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot())) as Dictionary
	_check(board.restore(JuiceLevel.from_dict(_row()), saved), "10步历史JSON往返可恢复")
	board._apply_valid_drop(0, 0, 1)
	_check( not captured[-1].is_empty(), "续局仍使用此前10步无空绳记录")
	board.undo()
	saved = JSON.parse_string(JSON.stringify(board.snapshot())) as Dictionary
	for entry: Dictionary in saved["undo_history"]:
		entry.erase("after_empty_rope_num")
	_check(board.restore(JuiceLevel.from_dict(_row()), saved), "旧撤销记录缺空绳数仍可续局")
	board._apply_valid_drop(0, 0, 1)
	_check(captured[-1].is_empty(), "旧存档未知历史不能判为无空绳")
	board.undo()
	_prepare_no_empty_history(board)
	board._apply_valid_drop(0, 0, 1)
	_check( not captured[-1].is_empty(), "旧存档新积累10步后恢复资格")
	board._cancel_closed_check()
	board.free()


func _test_white_pots_and_other_collection() -> void :
	for white_pots: int in [1, 2]:
		var row: Dictionary = _row()
		row["initial"] = ["-|1,1", "-|1,1" if white_pots == 2 else "1|1,1", "2|2,2,0,0,0,0"]
		var board: JuiceBoardView = _board(row)
		_prepare_no_empty_history(board)
		var captured: Array[Dictionary] = _capture(board)
		board._apply_valid_drop(0, 0, 1)
		_check(captured.size() == 1 and captured[0].is_empty() == (white_pots == 2), 
			"白盆%d个：有花白盆同样计数，少于2个才允许" % white_pots)
		board._cancel_closed_check()
		board.free()


	for initial_white_pots: int in [0, 1]:
		var row: Dictionary = {"id": 6, "capacity": 6, "targetCups": 3, 
			"initial": ["-|1,1" if initial_white_pots == 1 else "0|1,1", "1|1,1", "2|2,2,2,2,2,2"], 
			"incoming": ["-|0,0,1,1", "-|0,0,0,0"]}
		var board: JuiceBoardView = _board(row)
		(board._state["locks"] as Array)[2] = {"condition": JuiceLevel.LOCK_COLLECT_TYPE, "typeId": 2, "count": 1}
		board._refresh_lock_overlays()
		_prepare_no_empty_history(board)
		(board._state["locks"] as Array)[2] = {}
		board._refresh_lock_overlays()
		var captured: Array[Dictionary] = _capture(board)
		board._apply_valid_drop(0, 0, 1)
		_check(board.last_move_deposits().size() == 1 and int(board.last_move_deposits()[0]["col"]) == 2, 
			"本步只收集其他绳，未收走本次搬动的花")
		_check(captured.size() == 1 and captured[0].is_empty() == (initial_white_pots == 1), 
			"其他绳收集可保留资格，结算后白盆达到2个则排除")
		board._cancel_closed_check()
		board.free()


func _test_spiral_parameters() -> void :
	var spiral: EmptyRopeSpiralFx = load("res://scripts/gameplay/juice_sort/view/empty_rope_spiral_fx.tscn").instantiate()
	add_child(spiral)
	var geometry: Dictionary = {"top": Vector2(300, 400), "bottom": Vector2(300, 1200), "width": 220.0}
	var provider: Callable = func() -> Dictionary: return geometry
	var halfway: Dictionary = {"count": 0, "progress": 0.0}
	spiral.halfway_reached.connect( func() -> void :
		halfway["count"] += 1
		halfway["progress"] = spiral.climb_progress())
	spiral.play_rope(provider)
	spiral.set_process(false)
	_check(spiral.head_texture != null and spiral.dust_texture != null, "独立场景继承原光点和金粉素材")
	_check(spiral._cfg.beam_dur == 0.0, "空绳版没有飞向目标栏的光束段")
	_check(absf(spiral.climb_y() - 1200.0) < 0.01, "从真实绳尾起播")
	var prev_y: float = spiral.climb_y()
	var saw_back: Array[bool] = [false, false]
	for frame: int in 51:
		spiral._process(1.0 / 60.0)
		_check(spiral.climb_y() <= prev_y + 0.01, "螺旋逐帧从下到上")
		prev_y = spiral.climb_y()
		for i: int in 2:
			if spiral._heads[i].depth < -0.5:
				saw_back[i] = true
	_check(saw_back[0] and saw_back[1], "两颗光点均绕过空绳前后")
	_check(int(halfway["count"]) == 1 and float(halfway["progress"]) >= 0.5, 
		"上行过半仅发一次信号，后半段不重复")
	_check(absf(spiral.climb_y() - 400.0) < 0.01, "上行结束到真实绳顶")
	geometry["top"] = Vector2(360, 400)
	geometry["bottom"] = Vector2(360, 1200)
	var before: Vector2 = spiral._heads[0].pos
	spiral._process(0.0)
	_check(absf(spiral._heads[0].pos.x - before.x - 60.0) < 0.01, "特效跟随源绳横移")
	spiral._process(0.04)
	_check(spiral._heads[0].attached and absf(spiral._heads[0].alpha - 0.5) < 0.01, 
		"绳顶原地淡出，无光束或折返")
	var done: Dictionary = {"count": 0}
	spiral.finished.connect( func() -> void : done["count"] += 1)
	spiral._process(spiral.total_duration())
	_check( not spiral.is_running() and not spiral.visible and int(done["count"]) == 1, "播完隐藏并仅发一次结束")
	spiral.play_rope(provider)
	spiral.set_process(false)
	_check(spiral._heads[0].offs.size() <= 1, "池复用不残留光带")
	spiral.stop()
	_check(int(done["count"]) == 1 and not spiral._rope_geometry.is_valid(), "强制清理不发结束并释放几何回调")
	spiral.play_rope(provider)
	spiral.set_process(false)
	geometry.clear()
	spiral._process(0.01)
	_check( not spiral.is_running() and int(done["count"]) == 2, "源绳消失后停止并回池")
	_check(int(halfway["count"]) == 1, "中途停止与源绳消失不补发过半信号")
	spiral.free()


func _page(row: Dictionary) -> JuiceGamePage:
	var page: JuiceGamePage = load("res://scripts/main/pages/game/juice_game_page.tscn").instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {}, [], false, true)
	UserState.set_current_level(6)
	var model: = JuiceLevelModel.new()
	model.level_id = 6
	model.chapter_index = 1
	model.level_index = 6
	model.raw = row
	model.juice = JuiceLevel.from_dict(row)
	_check(model.juice.validate().is_empty(), "存档测试题面合法: %s" % str(model.juice.validate()))
	page._level_model = model
	page._board.moved.connect(page._on_board_moved)
	return page


func _test_tutorial_and_redo() -> void :
	var page: JuiceGamePage = await _page(_row())
	page._tutorial_active = true
	page.start_round({})
	_prepare_no_empty_history(page._board)
	var fx: EmptyColFeedback = page._empty_col_feedback
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx.shown_count == 0 and fx._active.is_empty() and fx._spiral_active.is_empty(), 
		"新手教学不播放空绳反馈")
	page._tutorial_active = false
	page.start_round({})
	_prepare_no_empty_history(page._board)
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx.shown_count == 1, "正式局首次符合资格的腾空默认播放一次")
	_check(fx._active.is_empty() and fx._pending_applause.size() == 1, 
		"先播放螺旋，上升到一半前不播放鼓掌")
	page._board.undo()
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx.shown_count == 1 and fx.shown_operations.size() == 1 and fx._spiral_active.size() == 1, 
		"撤回重做相同操作不重复反馈")
	page._save_progress()
	var resumed: Dictionary = LevelManager.load_resumed_level(6)
	if not _check_resume(resumed):
		page._board._cancel_closed_check()
		page.free()
		return
	var saved: Dictionary = JSON.parse_string(JSON.stringify(resumed["current_state"])) as Dictionary
	_check((saved["empty_rope_feedback_operations"] as Array).size() == 1, 
		"操作标识随快照保存并通过 JSON 往返")
	page.start_round(saved)
	page._board.undo()
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx.shown_count == 1 and fx._spiral_active.is_empty() and fx._active.is_empty(), 
		"续局恢复后撤回重做仍不重复反馈")

	page.start_round({})
	_prepare_no_empty_history(page._board)
	page._board._apply_valid_drop(0, 0, 1)
	var spiral: EmptyRopeSpiralFx = fx._spiral_active[0]
	fx.hide_now()
	spiral._process(0.5)
	_check(fx._active.is_empty() and fx._pending_applause.is_empty() and fx._spiral_pool.size() == 1, 
		"半程前清理不补播鼓掌，回池不重复")
	_check(fx.shown_count == 1 and fx.shown_operations.size() == 1, "清理不返还已消费次数和标识")
	page.start_round({})
	_prepare_no_empty_history(page._board)
	page._board._apply_valid_drop(0, 0, 1)
	spiral = fx._spiral_active[0]
	spiral.set_process(false)
	spiral._process(0.424)
	_check(fx._active.is_empty(), "过半之前保持仅螺旋")
	spiral._process(0.002)
	_check(fx._active.size() == 1 and fx._pending_applause.is_empty(), "实际上升过半后启动一次鼓掌")
	spiral._process(0.2)
	_check(fx._active.size() == 1 and fx.shown_count == 1, "继续上升不再次启动鼓掌或计次")

	page.start_round({})
	_prepare_no_empty_history(page._board)
	page._board._apply_valid_drop(0, 0, 1)
	spiral = fx._spiral_active[0]
	page._board.undo()
	spiral._process(0.5)
	_check(fx._active.is_empty() and fx._pending_applause.is_empty() and fx._spiral_active.is_empty(), 
		"半程前源绳 token 失效取消待播鼓掌")
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx.shown_count == 1 and fx._spiral_active.is_empty(), "中途取消后重做仍不返还反馈资格")

	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("empty_rope_feedback_operations")
	page.start_round(legacy)
	_check(fx.shown_count == 1 and fx.shown_operations.is_empty(), "旧存档保留次数，缺操作列表按空恢复")
	page._empty_col_feedback.hide_now()
	page._board._cancel_closed_check()
	page.free()


func _test_round_and_playback() -> void :
	var row: Dictionary = {"id": 6, "capacity": 6, "targetCups": 3, 
		"initial": ["0|1,1", "1|1,1", "-|1,1", "2|2,2,0,0,0,0"], 
		"incoming": ["-|0,0", "-|2,2,2,2"]}
	var page: JuiceGamePage = await _page(row)
	page.start_round({})
	_prepare_no_empty_history(page._board)
	var fx: EmptyColFeedback = page._empty_col_feedback
	var moves: Array = [[0, 1], [0, 2], [1, 2]]
	for i: int in moves.size():
		var count: int = i + 1
		var move: Array = moves[i]
		_check(page._board._apply_valid_drop(int(move[0]), 0, int(move[1])), "不同操作搬空源绳成功")
		_check(fx.shown_count == count and fx._active.size() == i, "螺旋起播独立计次: %d" % count)
		_check(fx._spiral_active.size() == count and fx._spiral_active[i].is_running(), 
			"不同操作独立起播螺旋: %d" % count)
		var spiral: EmptyRopeSpiralFx = fx._spiral_active[i]
		spiral.set_process(false)
		var rope_geometry: Dictionary = spiral._rope_geometry.call()
		_check(absf(spiral.climb_y() - (rope_geometry["bottom"] as Vector2).y) < 0.01, 
			"真实页面坐标转换后仍从绳尾开始")
		spiral._process(0.4)
		_check(fx._active.size() == i, "半程前不增加鼓掌实例")
		spiral._process(0.03)
		_check(fx._active.size() == count, "半程后独立重叠播放鼓掌: %d" % count)
		page._save_progress()
		var resumed: Dictionary = LevelManager.load_resumed_level(6)
		_check( not resumed.is_empty() and int(resumed["current_state"].get("empty_rope_feedback_count", 0)) == count
			and (resumed["current_state"].get("empty_rope_feedback_operations", []) as Array).size() == count, 
			"保存后次数与操作标识可续局: %d" % count)
		page._board.undo()
		_check(fx.shown_count == count, "撤销不返还次数")
		page._board._apply_valid_drop(int(move[0]), 0, int(move[1]))
		_check(fx.shown_count == count and fx._spiral_active.size() == count, "每个已播放操作重做均不重复")
		page._board.undo()
	page._board._apply_valid_drop(2, 0, 1)
	_check(fx.shown_count == 3 and fx._active.size() == 3, "第4个不同操作不播放")
	_check(fx._spiral_active.size() == 3, "螺旋与鼓掌共用三次上限")
	var duration: float = fx._active[0].get_skeleton().get_data().find_animation(&"quickShow").get_duration()
	_check(absf(duration - 0.9) < 0.001 and fx._reference_bounds.size.x > 0.0, 
		"麻将双手鼓掌quickShow动画为0.9秒，包围盒可加载")
	for spiral: EmptyRopeSpiralFx in fx._spiral_active:
		spiral.set_process(true)
	await get_tree().create_timer(maxf(duration, fx._spiral_active[0].total_duration()) + 0.1).timeout
	_check(fx._active.is_empty() and fx._pool.size() == 3, "三段鼓掌各自结束并回池")
	_check(fx._spiral_active.is_empty() and fx._spiral_pool.size() == 3, "三段螺旋各自结束并回池")
	page._save_progress()
	var resumed: Dictionary = LevelManager.load_resumed_level(6)
	if not _check_resume(resumed):
		page._board._cancel_closed_check()
		page.free()
		return
	page.start_round(resumed["current_state"])
	_check(fx.shown_count == 3 and fx.shown_operations.size() == 3 and not fx.can_show(), "真实续局恢复次数及去重记录")
	page.start_round({})
	_prepare_no_empty_history(page._board)
	_check(fx.shown_count == 0 and fx.shown_operations.is_empty() and fx.can_show(), "新局重置次数和去重记录")
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx._spiral_active.size() == 1 and fx._spiral_pool.size() == 2, "新局复用螺旋池")
	fx.hide_now()
	_check(fx._spiral_active.is_empty() and fx._spiral_pool.size() == 3 and fx.shown_count == 1, 
		"离页/后台清理螺旋且不返还次数")
	for spiral: EmptyRopeSpiralFx in fx._spiral_pool:
		_check( not spiral.is_running() and not spiral.visible, "回池实例停止处理和显示")
	page.start_round({})
	_prepare_no_empty_history(page._board)
	page._board._apply_valid_drop(0, 0, 1)
	_check(fx.shown_count == 1 and fx.shown_operations.size() == 1, 
		"新局符合资格后默认播放并记录操作，不依赖已移除的实验分组")
	_check(fx._spiral_active.size() == 1, "新局首次腾空正常起播螺旋")
	await get_tree().process_frame
	page._board._cancel_closed_check()
	page.free()


func _check_resume(resumed: Dictionary) -> bool:
	_check( not resumed.is_empty(), "存档可重建当前局")
	return not resumed.is_empty()
