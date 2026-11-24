extends SceneTree


const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
var failures: Array[String] = []

class RootCleanupProbe extends JuiceBoardView.RootClosedJob:
	var cleanup_in_main: bool = false
	var cleanup_called: bool = false

	func discard() -> void :
		cleanup_called = true
		cleanup_in_main = OS.get_thread_caller_id() == OS.get_main_thread_id()
		super.discard()

func _initialize() -> void :
	call_deferred("_run")

func check(ok: bool, message: String) -> void :
	if not ok:
		failures.append(message)
		push_error(message)

func mixed_row() -> Dictionary:
	return {"id": 98393, "capacity": 3, "targetCups": 3, 
		"initial": ["0|1,0,2", "1|2,1,0", "2|0,2,1"], "incoming": []}

func _new_board(scene: PackedScene, enabled: bool, row: Dictionary = {}) -> Variant:
	var board: Variant = scene.instantiate()
	board.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board.size = Vector2(1080, 2340)
	root.add_child(board)
	var lv: JuiceLevel = JuiceLevel.from_dict(mixed_row() if row.is_empty() else row)
	check(lv.validate().is_empty(), "盘面测试题面合法")
	board.set_allow_root_swapping_enabled(enabled)
	board.setup(lv)
	board.set_process(false)
	return board

func _drop(board: Variant, src: int, j: int, dst: int) -> JuiceDropContext:
	board.set("_drag", {"col": src, "j": j, "nodes": []})
	var ctx: = JuiceDropContext.new(board, src, j, dst)
	ctx.long_link_geometry = {"center": Vector2.ZERO, "width": 10.0}
	JuiceDropFlow.run(ctx)
	JuiceDropFlow.finish_now(ctx)
	return ctx

func _free_board(board: Variant) -> void :
	board._cancel_closed_check()
	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()

func _run() -> void :
	_test_config()
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	_test_flow_and_restore(scene)
	_test_controls(scene)
	await _test_dead_attempt_and_entry_gate(scene)
	await _test_root_ready_settlement(scene)
	await _test_root_mystery_entry_gate(scene)
	_test_tutorial_connection(scene)
	_test_connection_col_marks(scene)
	_test_empty_neighbor_drop(scene)
	_test_real_drag(scene)
	await _test_closed_cycle_delivery(scene)
	await _test_level7_closed_cycle_delivery(scene)
	await _test_root_automatic_death(scene)
	await _test_root_closed_lifecycle(scene)
	await _test_root_shared_hint_result(scene)
	await _test_root_late_cancel_cleanup(scene)
	await _wait_root_reapers()
	await process_frame
	print("JUICE_ROOT_SWAPPING_VIEW ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)

func _test_config() -> void :

	var config_script: Variant = load("res://scripts/data/abtest/ab_configs/allow_root_swapping/allow_root_swapping_config.gd")
	check(config_script.group_for_raw_string("default") == 0 and config_script.group_for_raw_string("level_1") == 1
		and config_script.group_for_raw_string("level_4") == 2, "SDK原字符串准确映射三组")
	for raw: String in ["", "unknown", "1", "2", "LEVEL_1"]:
		check(config_script.group_for_raw_string(raw) == 0, "缺失/未知/数字字符串不命中实验")
	for level_id in [0, 1, 3, 4, 50]:
		check( not config_script.allows_level(0, level_id), "对照组所有关号关闭")
		check(config_script.allows_level(1, level_id) == (level_id >= 1), "组1实际关号边界")
		check(config_script.allows_level(2, level_id) == (level_id >= 1), "组2实际关号边界")
		check( not config_script.allows_level(99, level_id), "未知非负覆盖不误开")
	var config: Variant = config_script.new()
	var user_state: Variant = root.get_node("UserState")
	var ab_manager: Variant = root.get_node("ABManager")
	check(config.version == "1.0.10" and config.group_count == 3
		and config.timing == ab_manager.TIMING_ENTER_GAME, "面板版本/三组/进页时机元信息")

	for group in [0, 1, 2, 99]:
		config.set("_value", group)
		config.set("_value_loaded", true)
		if user_state.get_debug_ab_override(config.key) < 0:
			check(config.should_allow_root_swapping(4) == (group == 1 or group == 2), "缓存走语义阈值")

func _test_flow_and_restore(scene: PackedScene) -> void :
	var board: Variant = _new_board(scene, true)
	var initial: String = S._full_state_key(board.state())
	var order: Array = (board.get("_order") as Array).duplicate()
	var pots: Dictionary = (board.get("_blender_nodes") as Dictionary).duplicate()
	var source: Array = (board.get("_fruit_nodes")[0] as Array).duplicate()
	var target: Array = (board.get("_fruit_nodes")[1] as Array).duplicate()
	var events: Array[String] = []
	board.drag_ended.connect( func() -> void : events.append("drag_ended"))
	board.move_attempted.connect( func(_info: Dictionary) -> void : events.append("attempt"))
	board.moved.connect( func(_steps: int) -> void : events.append("moved"))
	board.long_link_triggered.connect( func(_info: Dictionary) -> void : events.append("long_link"))
	board.set("_last_player_placement_msec", 0)
	var ctx: JuiceDropContext = _drop(board, 0, 0, 1)
	check(ctx.root_swapped and ctx.move_applied and board.steps() == 1, "根部松手同步交换且幂等只计一步")
	check(events == ["drag_ended", "attempt", "moved"], "信号顺序及交换不发长连接")
	check((board.get("_connection_pending") as Array).is_empty()
		and int(board.get("_last_player_placement_msec")) == 0, "交换不播连接、不推进长连接时钟")
	check(board.get("_order") == order and board.get("_blender_nodes") == pots, "花盆节点和格位固定")
	check(board.get("_fruit_nodes")[0] == target and board.get("_fruit_nodes")[1] == source, 
		"真实节点镜像交换整个花串")
	check(board.sync_error().is_empty(), "交换后状态与花节点逐项对应")
	for ci in [0, 1]:
		for flower: JuiceFruit in board.get("_fruit_nodes")[ci]:
			check(flower.col == ci and flower.top_level and flower.z_index == board.RETURN_Z, 
				"两串归位前均保留高层级和裁剪豁免")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	check(bool(saved["undo_history"][0]["rec"]["root_swapped"]), "JSON撤销历史保留交换标记")
	check(board.restore(board.level(), saved) and bool(board.last_move()["root_swapped"]), "续局恢复交换历史")
	check(board.undo() and S._full_state_key(board.state()) == initial, "续局后撤销恢复两串")
	check(board.sync_error().is_empty(), "续局撤销后节点镜像一致")
	board.set_allow_root_swapping_enabled(false)
	board.setup(board.level())
	check( not bool(board.state()["allow_root_swapping"]), "页面复用/重开清掉上一局实验开关")
	_free_board(board)

func _test_controls(scene: PackedScene) -> void :
	var board: Variant = _new_board(scene, false)
	check( not _drop(board, 0, 0, 1).move_applied and board.steps() == 0, "对照组不交换")
	_free_board(board)
	board = _new_board(scene, true)
	board.set_move_gate( func(_src: int, _j: int, _dst: int) -> bool: return false)
	var ctx: JuiceDropContext = _drop(board, 0, 0, 1)
	check(ctx.outcome == JuiceDropContext.Outcome.BLOCKED and not ctx.move_applied, "教学门控仍先于交换")
	board.set_move_gate(Callable())
	check(_drop(board, 0, 0, 0).outcome == JuiceDropContext.Outcome.CANCEL
		and _drop(board, 0, 0, -1).outcome == JuiceDropContext.Outcome.CANCEL, "同列/外部静默取消")
	check( not _drop(board, 0, 1, 1).root_swapped and board.steps() == 0, "抓非根部不误判交换")
	var old: Dictionary = board.snapshot()
	old["state"].erase("allow_root_swapping")
	old["hint_dead"] = true
	check(board.restore(board.level(), old) and board.over() == "", "规则改变后不复用旧提示死局结论")
	_free_board(board)
	var row: Dictionary = mixed_row()
	row["initial"].push_front("-|")
	board = _new_board(scene, true, row)
	ctx = _drop(board, 1, 0, 0)
	check(ctx.move_applied and not ctx.root_swapped and (board.state()["cols"][1] as Array).is_empty(), 
		"空目标保留旧整串搬移")
	_free_board(board)
	board = _new_board(scene, true, {"id": 98394, "capacity": 2, "targetCups": 4, 
		"initial": ["0|1,1", "1|0,0", "2|2,3"], "incoming": ["3|2,3", "x", "x"]})
	var initial: String = S._full_state_key(board.state())
	ctx = _drop(board, 0, 0, 1)
	check(ctx.move_applied and board.steps() == 1 and int(board.state()["done"]) == 2, 
		"交换成功走原收盆级联和步数链")
	var collected: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	check(board.restore(board.level(), collected), "收盆后续局清理动画并恢复历史")
	check(board.undo() and S._full_state_key(board.state()) == initial, "收盆交换也能撤销")
	_free_board(board)

func _test_tutorial_connection(scene: PackedScene) -> void :
	var board: Variant = _new_board(scene, true, JuiceTutorialScript.board_for())
	var previous_done: int = 0
	for step: Dictionary in JuiceTutorialScript.STEPS:
		var ctx: JuiceDropContext = _drop(board, int(step["src"]), int(step["j"]), int(step["dst"]))
		check(ctx.move_applied and not ctx.root_swapped, "每步教学松手仍走普通连接/空绳搬移")
		var current_done: int = int(board.state()["done"])
		if step.has("collect"):
			check(current_done - previous_done == (1 if bool(step["collect"]) else 0), "教学收盆与剧本collect一致")
		check(current_done >= previous_done and board.over() != "dead" and board.sync_error().is_empty(), 
			"教学逐步收盆不误判死局且节点镜像一致")
		previous_done = current_done
	check(board.steps() == JuiceTutorialScript.STEPS.size() and previous_done > 0, "完整教学剧本计步及收盆")
	_free_board(board)


func _test_connection_col_marks(scene: PackedScene) -> void :

	var row: Dictionary = {"id": 3, "capacity": 3, "targetCups": 3, 
		"initial": ["-|0", "-|", "0|1", "1|1", "2|0,2,1"], 
		"incoming": ["-|0,2", "-|2"]}
	var board: Variant = _new_board(scene, true, row)
	var st: Dictionary = board.state()
	check(R.move_info(st, 2, 0, 3) > 0 and not R.is_root_swap(st, 2, 0, 3), 
		"根部同色且装得下的夹具走普通连接")
	check(R.move_info(st, 2, 0, 4) > 0 and R.is_root_swap(st, 2, 0, 4), 
		"同色但容量不足的夹具仅允许整列交换")
	check(R.move_info(st, 2, 0, 0) > 0 and R.is_root_swap(st, 2, 0, 0), 
		"异色非空目标的夹具仅允许整列交换")
	board.set("_drag", {"col": 2, "j": 0, "nodes": []})
	board._set_rule_col_marks(2, 0)
	var guides: Array = board.get("_col_mark_spec")["guides"]
	check(guides.size() == 2 and guides.has(3) and guides.has(1), 
		"开启根部交换后只有普通连接和空列搬移保持绿框")
	check( not guides.has(2) and not guides.has(0) and not guides.has(4), 
		"原列、异色交换及同色容量交换均不铺绿底")
	var normal_mark: JuiceColMark = null
	for mark: JuiceColMark in board.get("_col_mark_live"):
		check(mark._glow.texture == mark.glow_green and mark._fill.texture == mark.fill_green, 
			"普通连接目标起抓时保持绿框绿底")
		if int(mark.get_meta(&"col")) == 3:
			normal_mark = mark
	check(normal_mark != null, "普通连接目标生成真实列标记")
	board.set("_hover_col", 3)
	board._place_drop_hover()
	if normal_mark != null:
		check(normal_mark._glow.texture == normal_mark.glow_yellow
			and normal_mark._fill.texture == normal_mark.fill_yellow
			and not board.get("_drop_hover").visible, 
			"普通根部连接悬停仍切黄框且不叠普通预览")
	for target: int in [0, 4]:
		board.set("_hover_col", target)
		board._place_drop_hover()
		check(board.get("_drop_hover").visible, 
			"整列交换目标仍保留普通悬停预览: %d" % target)
		if normal_mark != null:
			check(normal_mark._fill.texture == normal_mark.fill_green, 
				"悬停交换目标后普通连接标记恢复绿底")

	st["locks"][1] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 99}
	board.set("_drag", {"col": 0, "j": 0, "nodes": []})
	board._set_rule_col_marks(0, 0)
	check((board.get("_col_mark_spec")["guides"] as Array).is_empty()
		and (board.get("_col_mark_live") as Array).is_empty(), 
		"纯整列交换拿起时无连接绿框")
	board.set("_hover_col", 2)
	board._place_drop_hover()
	check(R.move_info(st, 0, 0, 2) > 0 and board.get("_drop_hover").visible, 
		"纯交换没有绿框也仍是合法落点并可显示普通预览")

	board.level().id = 4
	board.set("_hover_col", 1)
	board._place_drop_hover()
	check(R.move_info(st, 0, 0, 1) == 0 and not board.get("_drop_hover").visible, 
		"非法锁列没有绿底也不显示普通预览")
	board.level().id = 3
	st["locks"][1] = {}
	board.set("_drag", {"col": 4, "j": 2, "nodes": []})
	board._set_rule_col_marks(4, 2)
	guides = board.get("_col_mark_spec")["guides"]
	check(guides.size() == 3 and guides.has(1) and guides.has(2) and guides.has(3), 
		"抓非根部仍按普通同色连接及空列搬移铺绿框")
	st["locks"][3] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 99}
	board._set_rule_col_marks(4, 2)
	check( not (board.get("_col_mark_spec")["guides"] as Array).has(3), 
		"颜色容量满足的锁列也不能获得绿框")
	st["locks"][3] = {}
	for blocked_type: int in [JuiceLevel.hide_type(1), JuiceLevel.freeze_type(1)]:
		st["cols"][3][0] = blocked_type
		st["ice_mode"] = JuiceLevel.ICE_BLOCK_CONNECTION
		board._set_rule_col_marks(2, 0)
		check( not (board.get("_col_mark_spec")["guides"] as Array).has(3), 
			"问号或禁止连接的冰花即使可整列交换也不获得绿框")
	st["cols"][3][0] = 1
	board.set("_drag", {})
	board.clear_col_marks()
	board._place_drop_hover()
	check((board.get("_col_mark_live") as Array).is_empty()
		and not board.get("_drop_hover").visible, "结束拖拽清除绿黄标记和普通预览")
	_free_board(board)


func _test_empty_neighbor_drop(scene: PackedScene) -> void :

	for empty_on_right: bool in [true, false]:
		var initial: Array[String] = ["0|1,0,0", "1|0", "0|", "1|1", "1|1"]
		if not empty_on_right:
			initial = ["0|1,0,0", "1|", "0|0", "1|1", "1|1"]
		var row: Dictionary = {"id": 98397, "capacity": 3, "targetCups": 5, 
			"initial": initial, "incoming": ["-|1,1,1", "-|1,1,1", "-|0,0,0", "x"]}
		var filled: int = 1 if empty_on_right else 2
		var empty: int = 2 if empty_on_right else 1
		for enabled: bool in [false, true]:
			for settings: Dictionary in [{}, {"legal": 1.1, "invalid": 0.9}, {"legal": 1.2, "invalid": 0.8}]:
				var board: Variant = _new_board(scene, enabled, row)
				board.set_drop_settings(settings)
				var lay: Variant = board.get("_lay")
				var filled_x: float = board._col_x(filled)
				var empty_x: float = board._col_x(empty)
				var pos: = Vector2((filled_x + empty_x) * 0.5 + signf(empty_x - filled_x) * 2.0, 
					(lay.rope_visible_top + lay.rope_bottom) * 0.5)
				var label: String = "交换=%s 落位=%s 空列=%d" % [enabled, settings, empty]
				check(absf(pos.x - empty_x) < absf(pos.x - filled_x), "夹具空绳更近: " + label)
				check(board._source_neighbor_drop_target(pos, 0, 0) == -1
					and board._page_edge_drop_target(pos, 0, 0) == -1, 
					"夹具只覆盖目标重叠区，未走源邻列或页面边缘: " + label)
				check(R.move_info(board.state(), 0, 0, filled) == (3 if enabled else 0)
					and R.move_info(board.state(), 0, 0, empty) == 3, 
					"异色非空目标仅实验组可交换，空绳两组都可搬移: " + label)
				check(board._hit_column(pos, 0, 0) == empty, 
					"抓根部时空绳更近应选空绳，不能偏向异色交换目标: " + label)

				check(board._hit_column(pos, 0, 1) == (filled if settings.is_empty() else empty), 
					"普通同色连接保持 old 优先连接/new 取最近的原分组行为: " + label)
				check(_mouse_drop_at(board, 0, 0, pos), "真实鼠标抓起根部: " + label)
				check(board.steps() == 1 and int(board.last_move().get("dst", -1)) == empty
					and not bool(board.last_move().get("root_swapped", false)), 
					"真实松手执行空绳搬移而非意外交换: " + label)
				check((board.state()["cols"][0] as Array).is_empty()
					and board.state()["cols"][empty] == [1, 0, 0]
					and board.state()["cols"][filled] == [0]
					and board.sync_error().is_empty(), "真实松手花串及节点镜像正确: " + label)
				_free_board(board)


func _mouse_drop_at(board: Variant, src: int, j: int, pos: Vector2) -> bool:
	var fruit: JuiceFruit = board.get("_fruit_nodes")[src][j]
	var press: = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = board.get_global_transform().affine_inverse() * fruit.global_position
	board._gui_input(press)
	var drag: Dictionary = board.get("_drag")
	if drag.is_empty() or int(drag.get("j", -1)) != j:
		return false
	var end: Vector2 = pos + (drag["grab"] as Vector2)
	var motion: = InputEventMouseMotion.new()
	motion.position = end
	board._gui_input(motion)
	var release: = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = end
	board._gui_input(release)
	return true


func _wait_closed_check(board: Variant) -> void :
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 5000:
		board._poll_closed_check()
		if int(board.get("_closed_task_id")) == -1:
			return
		await process_frame
	check(false, "封闭检查工作线程在测试窗口内完成")


func _wait_closed_task_complete(board: Variant) -> bool:
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 5000:
		var task: int = int(board.get("_closed_task_id"))
		if task != -1 and WorkerThreadPool.is_task_completed(task):
			var result: Dictionary = board.get("_closed_task_result")
			if bool(result.get("completed", false)) and not bool(result.get("continuable", false)):
				return true
			board._poll_closed_check()
		elif task == -1:
			board._poll_closed_check()
		await process_frame
	check(false, "第7关真实封闭检查在有界时间结束")
	return false



func _level7_live_fixture() -> Dictionary:
	var row: Dictionary = {"id": 7, "capacity": 5, "targetCups": 12, 
		"initial": ["-|", "6|6,?6,?5,4", "7|6,1,?1,3", "5|5,?7,6,?7,5", 
			"1|4,?3,7,1", "3|5,7,3,1", "4|4,5,7,?4,6"], 
		"incoming": ["8|8,?8,?1,3,4", "0|0,0,?3,8,1", "9|9,1,8,0", "1|1,?9,?8,5,3", 
			"5|5,?5,9,1,0", "3|3,3,?0,5,9", "-|3,1,9,3,5"]}
	var level: JuiceLevel = JuiceLevel.from_dict(row)
	var state: Dictionary = R.make_state(level)
	state["allow_root_swapping"] = true
	state["cols"] = [[4, 4] as Array[int], [6, 6, 6, 6] as Array[int], 
		[6, 1, 1, 1, 1] as Array[int], [5, 7, 7, 7, 7] as Array[int], 
		[4, 3, 3, 3] as Array[int], [5, 7] as Array[int], [4, 5, 5, 5] as Array[int]]
	return {"row": row, "level": level, "state": state}


func _test_level7_closed_cycle_delivery(scene: PackedScene) -> void :
	var fixture: Dictionary = _level7_live_fixture()
	var level: JuiceLevel = fixture["level"]
	var state: Dictionary = fixture["state"]
	check(level.validate().is_empty(), "第7关截图题面合法")
	var board: Variant = _new_board(scene, true, fixture["row"])
	var events: Array[String] = []
	board.dead.connect( func(reason: String) -> void : events.append(reason))
	board.setup(level, R.clone_state(state))
	var before: String = S._full_state_key(board.state())
	board.set("_drag", {"col": 0, "j": 0, "nodes": []})
	if await _wait_closed_task_complete(board):
		check(bool(board.get("_closed_task_result")["closed"]), "第7关真实worker证明root盘面封闭")
		board._poll_closed_check()
		check(board.over() == "" and events.is_empty()\
		and board.get("_root_closed_cache").has(S.root_closed_state_key(board.state())), 
			"第7关证明完成时仍拖拽则延迟派发死局")
		board.set("_drag", {})
		board._poll_closed_check()
		board._check_over()
		check(board.over() == "dead" and events == ["loop"]\
		and board.get("_pending_dead_reason") == "loop", "第7关松手后沿原loop路径只派发一次死亡")
		check(bool(board.snapshot()["dead"]) and not bool(board.snapshot()["hint_dead"])\
		and S._full_state_key(board.state()) == before and board.steps() == 0\
		and board.sync_error().is_empty(), "第7关正式loop死局可保存且不改盘面或步数")
	else:
		board.set("_drag", {})

	board.setup(level, R.clone_state(state))
	if await _wait_closed_task_complete(board):
		var live_level: JuiceLevel = JuiceLevel.from_dict({"id": 98397, "capacity": 2, "targetCups": 2, 
			"initial": ["-|", "0|0,1", "1|1,0"], "incoming": ["x"]})
		var live_state: Dictionary = R.make_state(live_level)
		live_state["allow_root_swapping"] = true
		board.set("_level", live_level)
		board.set("_state", live_state)
		board._rebuild_order()
		board._rebuild_nodes()
		board._snap_all_home()
		board._poll_closed_check()
		await _wait_closed_check(board)
		check(board.over() == "" and events == ["loop"] and not bool(board.snapshot()["dead"])\
		and board.sync_error().is_empty(), "第7关旧loop结果不标死新盘面并对新状态重新检查")
	AudioManager.stop_sfx(&"juice_dead")
	_free_board(board)
	print("ROOT_SWAP_LEVEL7_VIEW closed_delivered=true drag_delayed=true stale_discarded=true")

func _test_closed_cycle_delivery(scene: PackedScene) -> void :
	var row: Dictionary = {"id": 98395, "capacity": 5, "targetCups": 6, 
		"initial": ["0|1,0,2,3,4", "1|2,1,3,4,5", "2|3,2,4,5,0", 
			"3|4,3,5,0,1", "4|5,4,0,1,2", "5|0,5,1,2,3"], "incoming": []}
	var board: Variant = _new_board(scene, true, row)
	var lv: JuiceLevel = board.level()

	var dead_state: Dictionary = R.make_state(lv)
	dead_state["cols"] = [[1, 1] as Array[int], [5, 5, 5, 5] as Array[int], 
		[2, 0, 4, 3, 3] as Array[int], [4, 4, 4] as Array[int], 
		[3, 0] as Array[int], [2, 2, 2, 2] as Array[int]]
	dead_state["jars"] = [-1, 5, 0, 4, 1, 2] as Array[int]
	var events: Array[String] = []
	board.dead.connect( func(reason: String) -> void : events.append(reason))
	board.setup(lv, R.clone_state(dead_state))
	var before: String = S._full_state_key(board.state())
	await _wait_closed_check(board)
	check(board.over() == "dead" and board.get("_pending_dead_reason") == "loop"
		and events == ["loop"], "实验纯交换循环通过真实Worker/Board只派发一次loop死亡")
	check(S._full_state_key(board.state()) == before and board.sync_error().is_empty(), 
		"后台判死不换花串、不计步、不破坏节点镜像")
	check(board.steps() == 0 and bool(board.snapshot()["dead"]), "正式死亡态可保存而非仅弹提示")

	board.set_allow_root_swapping_enabled(false)
	board.setup(lv, R.clone_state(dead_state))
	check(board.over() == "dead" and board.get("_pending_dead_reason") == "stuck"
		and events == ["loop", "stuck"], "对照组相同盘面保留原stuck判死")

	board.set_allow_root_swapping_enabled(true)
	board.setup(lv, R.clone_state(dead_state))
	var live_state: Dictionary = R.clone_state(dead_state)
	live_state["cols"][0] = [0, 0, 0, 0, 0] as Array[int]
	board.setup(lv, live_state)
	await _wait_closed_check(board)
	check(board.over() == "" and events == ["loop", "stuck"], "重开到可互换收盆的盘面不接受旧loop结果")
	check( not bool(board.snapshot()["dead"]), "实验活局不持久化死亡标记")
	_free_board(board)

func _test_real_drag(scene: PackedScene) -> void :
	var board: Variant = _new_board(scene, true)
	var fruit: JuiceFruit = board.get("_fruit_nodes")[0][0]
	var press: = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = board.get_global_transform().affine_inverse() * fruit.global_position
	board._gui_input(press)
	var drag: Dictionary = board.get("_drag")
	check( not drag.is_empty() and int(drag.get("j", -1)) == 0, "真实鼠标抓盆口花")
	if not drag.is_empty():
		var lay: Variant = board.get("_lay")
		var end: Vector2 = Vector2(board._col_x(1), lay.plank_top + 10.0) + drag["grab"]
		var motion: = InputEventMouseMotion.new()
		motion.position = end
		board._gui_input(motion)
		var release: = InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = end
		board._gui_input(release)
		check(board.steps() == 1 and bool(board.last_move().get("root_swapped", false))
			and board.sync_error().is_empty(), "真实鼠标松手经_drop_at完成交换")
	_free_board(board)


func _wait_one_root_slice(board: Variant) -> Dictionary:
	var task: int = int(board.get("_closed_task_id"))
	var started: int = Time.get_ticks_msec()
	while task != -1 and not WorkerThreadPool.is_task_completed(task)\
	and Time.get_ticks_msec() - started < 5000:
		await process_frame
	check(task != -1 and WorkerThreadPool.is_task_completed(task), "root短片在有界时间完成")
	return (board.get("_closed_task_result") as Dictionary).duplicate()


func _wait_root_reapers() -> void :
	var started: int = Time.get_ticks_msec()
	while not JuiceBoardView.RootClosedJob.retired.is_empty() and Time.get_ticks_msec() - started < 5000:
		await process_frame
	check(JuiceBoardView.RootClosedJob.retired.is_empty(), "已销毁盘面的root任务记录全部异步回收")


func _test_root_closed_lifecycle(scene: PackedScene) -> void :

	var board: Variant = _new_board(scene, false)
	var lv: JuiceLevel = board.level()
	var ticks: Array[int] = [0]
	board.set("_root_closed_budget_ms", 8)
	board.set("_root_closed_now", func() -> int: ticks[0] += 1;return ticks[0])
	board.set("_root_closed_opts", {"skip_fast_proof": true})
	board.set_allow_root_swapping_enabled(true)
	var events: Array[String] = []
	board.dead.connect( func(reason: String) -> void : events.append(reason))
	board.setup(lv)
	board.set("_drag", {"col": 0, "j": 0, "nodes": []})
	var first: Dictionary = await _wait_one_root_slice(board)
	check(first.get("reason") == "deadline" and bool(first.get("continuable", false)), "短片UNKNOWN可继续")
	var ctx: Dictionary = board.get("_root_closed_job").ctx
	board._poll_closed_check()
	var second: Dictionary = await _wait_one_root_slice(board)
	check(is_same(ctx, board.get("_root_closed_job").ctx)\
	and int(second.get("candidates", 0)) > int(first.get("candidates", 0)), "deadline沿原ctx及cursor续查")
	await _wait_closed_check(board)
	check(board.over() == "" and events.is_empty(), "切片穷尽证明在拖拽期间不派发死亡")
	board.set("_drag", {})
	board._poll_closed_check()
	board._poll_closed_check()
	check(board.over() == "dead" and events == ["loop"], "分片loop证明只派发一次")
	ctx = {}

	board.set("_root_closed_max_states", 2)
	board.setup(lv)
	board.set("_drag", {"col": 0, "j": 0, "nodes": []})
	var switched: bool = false
	var sliced: Dictionary = await _wait_one_root_slice(board)
	var slices: int = 0
	while bool(sliced.get("continuable", false)) and slices < 1000:
		var owned: Dictionary = board.get("_root_closed_job").ctx
		switched = switched or String(owned.get("method", "")) == "dfs"
		check(sliced.get("reason") != "state_cap", "生产会话不因状态阈值停止计算")
		board._poll_closed_check()
		sliced = await _wait_one_root_slice(board)
		slices += 1
	board._poll_closed_check()
	check(switched and String(board.root_closed_result().get("status", "")) == "CLOSED"\
	and events == ["loop"], "后台内存阈值后完整DFS证明，拖拽仍延迟死亡派发")

	board.set("_root_closed_max_states", 8000)
	board.setup(lv)
	var old_job: Variant = board.get("_root_closed_job")
	var old_task: int = int(board.get("_closed_task_id"))
	var b: Dictionary = R.clone_state(board.state())
	b["cols"][0] = [0, 0, 0] as Array[int]
	board.setup(lv, b)
	board.setup(lv)
	check(board.get("_root_closed_job") == old_job and int(board.get("_closed_task_id")) == old_task, 
		"A-B-A重开不等待旧worker且不投第二个worker")
	await _wait_one_root_slice(board)
	board._poll_closed_check()
	check(board.over() == "" and events == ["loop"]\
	and board.get("_root_closed_job").generation != old_job.generation, "新局A拒收旧局A结果")

	var generation: int = int(board.get("_root_closed_generation"))
	check(board.add_rope() and int(board.get("_root_closed_generation")) > generation, "加绳使旧root会话失效")
	_free_board(board)
	await process_frame
	await _wait_root_reapers()
	AudioManager.stop_sfx(&"juice_dead")
	print("ROOT_SWAP_SLICED_VIEW continuation=true cap_complete_dfs=true new_round_rejected=true reaped=true")


func _test_root_automatic_death(scene: PackedScene) -> void :
	var fixture: Dictionary = _level7_live_fixture()
	var board: Variant = _new_board(scene, true, fixture["row"])
	var events: Array[String] = []
	board.dead.connect( func(reason: String) -> void : events.append(reason))
	board.setup(fixture["level"], R.clone_state(fixture["state"]))
	board.set_process(true)
	var started: int = Time.get_ticks_msec()
	while board.over() == "" and Time.get_ticks_msec() - started < 2000:
		await process_frame
	check(board.over() == "dead" and events == ["loop"], "未点Hint也由盘面自动首盆证明及时派发loop死亡")
	print("ROOT_SWAP_AUTOMATIC_DEATH elapsed_ms=", Time.get_ticks_msec() - started, " hint_requests=0")
	_free_board(board)
	AudioManager.stop_sfx(&"juice_dead")


func _test_root_late_cancel_cleanup(scene: PackedScene) -> void :
	var level: JuiceLevel = JuiceLevel.from_dict(mixed_row())
	var state: Dictionary = R.make_state(level)
	state["allow_root_swapping"] = true
	var job: = RootCleanupProbe.new()
	job.ctx = S.begin_root_closed_search(state, level, 2)
	job.opts = {"skip_fast_proof": true}
	job.budget_ms = 500
	job.task_id = WorkerThreadPool.add_task(job.run)
	while not WorkerThreadPool.is_task_completed(job.task_id):
		await process_frame
	check(bool(job.result.get("recoverable", false)) and not job.ctx.is_empty(), "worker已结束时仍保留可恢复图以覆盖迟取消")

	job.retire(self)
	await _wait_root_reapers()
	check(job.ctx.is_empty() and job.task_id == -1 and job.cleanup_called and not job.cleanup_in_main, 
		"worker结束后再取消仍在线程清理搜索图并回收全部任务记录")

	var board: Variant = _new_board(scene, true)
	await _wait_closed_check(board)
	var stale: = RootCleanupProbe.new()
	stale.ctx = S.begin_root_closed_search(state, level, 2)
	stale.opts = {"skip_fast_proof": true}
	stale.budget_ms = 500
	stale.generation = int(board.get("_root_closed_generation")) - 1
	stale.level_identity = board.level().get_instance_id()
	stale.task_id = WorkerThreadPool.add_task(stale.run)
	while not WorkerThreadPool.is_task_completed(stale.task_id):
		await process_frame
	board.set("_root_closed_job", stale)
	board.set("_closed_task_id", stale.task_id)
	board.set("_closed_task_result", stale.result)
	board._poll_closed_check()
	await _wait_root_reapers()
	check(stale.ctx.is_empty() and stale.task_id == -1 and stale.cleanup_called and not stale.cleanup_in_main, 
		"已经完成的旧代次图被拒收后仍在线程清理")
	_free_board(board)
	AudioManager.stop_sfx(&"juice_dead")


func _test_root_shared_hint_result(scene: PackedScene) -> void :
	var board: Variant = _new_board(scene, true, {"id": 98398, "capacity": 2, "targetCups": 2, 
		"initial": ["0|1,1", "1|0,0", "-|"], "incoming": []})
	var task: int = int(board.get("_closed_task_id"))
	board.ensure_root_closed_check()
	check(int(board.get("_closed_task_id")) == task, "Hint请求复用当前root worker而非重复投递")
	check(board.root_closed_result().is_empty(), "在飞搜索图不暴露给页面")
	await _wait_closed_check(board)
	var result: Dictionary = board.root_closed_result()
	check(String(result.get("status", "")) == "EXIT" and not (result.get("path", []) as Array).is_empty(), 
		"完成的首盆证明带真实Hint路径")
	check( not result.has("ctx") and not result.has("frontier"), "共享结果只含轻量结论和路径")
	if not (result.get("path", []) as Array).is_empty():
		var replay: Dictionary = R.clone_state(board.state())
		var before_done: int = int(replay.get("done", 0))
		for move: Dictionary in result["path"]:
			check( not R.apply_move(replay, board.level(), int(move["src"]), int(move["j"]), int(move["dst"])).is_empty(), 
				"共享首盆路径每步按真实规则合法")
		check(int(replay.get("done", 0)) > before_done, "共享首盆路径真实收盆")
		result["path"][0]["src"] = -99
		check(int(board.root_closed_result()["path"][0]["src"]) >= 0, "页面修改结果副本不污染Board缓存路径")
	board.set_allow_root_swapping_enabled(false)
	board.setup(board.level())
	check(board.root_closed_result().is_empty(), "实验关闭不复用上局首盆结果")
	_free_board(board)


func _test_dead_attempt_and_entry_gate(scene: PackedScene) -> void :
	var board: Variant = _new_board(scene, false)
	var lv: JuiceLevel = board.level()
	var deaths: Array[String] = []
	board.dead.connect( func(reason: String) -> void : deaths.append(reason))
	board.set_allow_root_swapping_enabled(true)
	board.set_play_after_dead_enabled(true)
	board.set_root_adjudication_suspended(true)
	board.setup(lv)
	check(board.is_play_after_dead_enabled() and board.over() == ""\
	and not board.ensure_root_closed_check(), "入场暂停使实验组中间态不启动判死")
	board.set_play_after_dead_enabled(false)
	check(board.is_play_after_dead_enabled(), "待生效AB关闭不改变当前局死态操作资格")
	board.set_root_adjudication_suspended(false)
	await _wait_closed_check(board)
	check(board.over() == "dead" and deaths == ["loop"] and board.can_play_after_dead(), "组2严格死局保留操作资格")
	var before: String = S.root_closed_state_key(board.state())
	check(board.try_move(0, 0, 1) and board.over() == "dead" and board.steps() == 1\
	and board.history_size() == 1 and deaths == ["loop"], "死态交换真实记账但不重复死亡")
	check(S.root_closed_state_key(board.state()) != before and board.sync_error() == "", "死态交换改变真实盘面且画算一致")
	check( not board.try_move(0, 1, 1) and board.steps() == 1 and board.history_size() == 1, "死态非法切段不改计数/历史")
	board.set_input_enabled(false)
	check(board._can_play_block_reason() == "input_locked", "死态保留输入锁")
	board.set_input_enabled(true)
	board.set_entrance_lock(true)
	check(board._can_play_block_reason() == "entrance_lock", "死态保留入场锁")
	board.set_entrance_lock(false)
	board.set_hint_lock(true)
	check(board._can_play_block_reason() == "hint_lock", "死态保留Hint锁")
	board.set_hint_lock(false)
	check(board.undo() and board.steps() == 0 and board.history_size() == 0\
	and S.root_closed_state_key(board.state()) == before, "死态Undo仍还原真实历史")
	board.setup(lv)
	await _wait_closed_check(board)
	check( not board.is_play_after_dead_enabled() and not board.try_move(0, 0, 1), "组1重开冻结关闭死态移动")
	board.set_play_after_dead_enabled(true)
	board.set_allow_root_swapping_enabled(false)
	board.setup(lv)
	check( not board.is_play_after_dead_enabled(), "对照组不因死态配置打开规则")
	_free_board(board)
	await process_frame
	AudioManager.stop_sfx(&"juice_dead")


func _test_root_ready_settlement(scene: PackedScene) -> void :

	var fixture: Dictionary = _root_last_ready_fixture(false)
	var board: Variant = scene.instantiate()
	root.add_child(board)
	board.set_allow_root_swapping_enabled(true)
	board.set_root_adjudication_suspended(true)
	var events: Array[String] = []
	var consumed: Array = []
	board.moved.connect( func(_steps: int) -> void : events.append("moved"))
	board.dead.connect( func(reason: String) -> void : events.append(reason))
	board.automatic_settlement_requested.connect( func() -> void :
		events.append("automatic")
		consumed.append_array(board.last_move_deposits()))
	board.setup(fixture["level"], JuiceRules.clone_state(fixture["state"]))
	board.set_process(false)
	check(board.over() == "" and int(board.state()["done"]) == 2, "入场暂停覆盖ready/no_moves边界")
	board.set_root_adjudication_suspended(false)
	check(int(board.state()["done"]) == 3 and events == ["automatic"] and consumed.size() == 1\
	and board.steps() == 0 and board.history_size() == 0 and board.over() == "win", "真实ready自动收盆零步数同步消费且不误判stuck")
	_free_board(board)
	await process_frame


func _test_root_mystery_entry_gate(scene: PackedScene) -> void :
	var board: Variant = scene.instantiate()
	root.add_child(board)
	var fixture: Dictionary = _root_last_ready_fixture(true)
	var lv: JuiceLevel = fixture["level"]
	board.set_allow_root_swapping_enabled(true)
	board.set_play_after_dead_enabled(true)
	board.set_root_adjudication_suspended(true)
	board.setup(lv, R.clone_state(fixture["state"]))
	board.set_process(false)
	check(board.over() == "" and board.can_auto_unlock_mystery() and board.auto_unlock_mystery(), "组2先消费入场自动揭示再解除判死")
	board.set_root_adjudication_suspended(false)
	check(int(board.state()["done"]) == 3 and board.over() == "win", "入场自动揭示真实收盆不被中间stuck误杀")
	board.set_root_adjudication_suspended(true)
	board.setup(lv, R.clone_state(fixture["state"]))
	board.set("_over", "dead")
	board.set("_pending_dead_reason", "loop")
	var before: String = S.root_closed_state_key(board.state())
	check( not board.can_auto_unlock_mystery() and not board.auto_unlock_mystery()\
	and S.root_closed_state_key(board.state()) == before, "组2正式死亡后阻止独立自动问号变更")
	board.set_play_after_dead_enabled(false)
	board.set_allow_root_swapping_enabled(false)
	board.setup(lv, R.clone_state(fixture["state"]))
	board.set("_over", "dead")
	check(board.can_auto_unlock_mystery(), "对照组既有死局问号资格保持原规则")
	_free_board(board)
	await process_frame



func _root_last_ready_fixture(hidden: bool) -> Dictionary:
	var column: String = "0|?0,0,0" if hidden else "0|0,0,0"
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 98401 if hidden else 98400, 
		"capacity": 3, "targetCups": 3, "initial": [
			{"column": column, "columnType": "unlock", 
				"columnInfo": {"condition": "collect_count", "count": 2}}, 
			"1|1,1,1", "2|2,2,2"], "incoming": []})
	check(lv.validate().is_empty(), "ready/问号残局源题面合法")
	var state: Dictionary = R.make_state(lv)
	var collected: Array = []
	check(R.run_deposit(state, lv, collected) == 2 and R._unlock_pass(state).size() == 1\
	and int(state["done"]) == 2 and not R.has_any_move(state), "正式规则生成解锁后无动作最后一盆残局")
	return {"level": lv, "state": state}
