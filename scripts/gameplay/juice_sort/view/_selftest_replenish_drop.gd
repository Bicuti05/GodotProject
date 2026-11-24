extends SceneTree


var _failures: Array[String] = []
var _scene: PackedScene


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, label: String) -> void :
	if not ok:
		_failures.append(label)
		SortLogger.error("REPLENISH_DROP: " + label)


func _new_board(incoming: Array = ["3|3,3,3,2", "x", "x"]) -> Variant:
	var board: Variant = _scene.instantiate()
	board.anchor_right = 0.0
	board.anchor_bottom = 0.0
	root.add_child(board)
	board.size = Vector2(1080, 1304)
	board.setup(JuiceLevel.from_dict({
		"id": 99201, "capacity": 4, "targetCups": 4, 
		"initial": ["0|0,0,0", "-|0", "1|1,1,1,2", "2|2,2,1", "-|3"], 
		"incoming": incoming, 
	}))
	board._cancel_closed_check()
	board.set_process(false)
	return board


func _free_board(board: Variant) -> void :
	board._cancel_closed_check()
	for field: String in ["_death_task_id", "_challenge_task_id"]:
		var task: int = board.get(field)
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()


func _test_rope_prop() -> void :
	var board: Variant = _new_board()
	_check(board.try_move(2, 2, 0) and not board.is_busy(), "道具测试先产生无收集移动历史")
	board._cancel_closed_check()
	var old_columns: int = (board._state["cols"] as Array).size()
	var done_before: int = int(board._state["done"])
	var events: Dictionary = {"cups": 0, "settled": 0}
	board.cup_collected.connect( func(_t: int, _n: int, _c: Color, _r: Rect2) -> void : events["cups"] += 1)
	board.settled.connect( func() -> void : events["settled"] += 1)
	_check(board.add_rope(), "加绳道具成功")
	board._cancel_closed_check()
	var ci: int = old_columns
	_check(board.has_rope() and (board._state["cols"] as Array).size() == old_columns + 1
		and (board._state["cols"][ci] as Array).is_empty() and board._order[-1] == ci, 
		"加绳只追加一根白色空列")
	var pot: JuiceBlender = board._blender_nodes[ci]
	_check(board._col_x(ci) > board.size.x and pot.get_parent() == board._blender_layer
		and pot.modulate.a == 1.0, "道具花盆由屏右滑入，不借层或原位淡入")
	_check( not board.add_rope(), "每局最多加绳一次")
	var snapshot: Dictionary = board.snapshot()
	var resumed: Variant = _new_board()
	_check(resumed.restore(board._level, snapshot) and resumed.has_rope()
		and not resumed.add_rope() and resumed.sync_error() == "", 
		"滑入期间快照恢复保留道具已使用与规则，不保存动效进度")
	_free_board(resumed)
	for frame: int in 600:
		board._process(1.0 / 60.0)
		if not board.is_busy():
			break
	_check( not board.is_busy() and int(events["settled"]) == 1
		and is_equal_approx(board._col_x(ci), board._base_x(ci)), "道具滑入到位后恰好一次settled")
	_check(int(board._state["done"]) == done_before and int(events["cups"]) == 0
		and board.sync_error() == "", "加绳不伪造收集，节点与模型一致")
	_check(board.undo() and board.has_rope() and board._order[-1] == ci
		and (board._state["cols"] as Array).size() == old_columns + 1
		and board.sync_error() == "", "撤销旧移动后额外绳仍保留")
	board.setup(board._level)
	_check( not board.has_rope() and board._legacy_replenish_pending.is_empty(), "重开恢复道具可用并清补列状态")
	_free_board(board)
	var dead: Variant = _new_board()
	dead._over = "dead"
	_check(dead.revive_with_rope() and dead._over == "" and dead.has_rope(), "死局加绳复活")
	var dead_ci: int = (dead._state["cols"] as Array).size() - 1
	_check(dead._col_x(dead_ci) > dead.size.x, "死局加绳同样由屏右滑入")
	_free_board(dead)


func _test_cascade_and_theme() -> void :
	var board: Variant = _new_board()
	board.setup(JuiceLevel.from_dict({"id": 99202, "capacity": 2, "targetCups": 3, 
		"initial": ["0|0", "-|0", "2|2"], "incoming": ["1|1,1", "-|2"]}))
	_check(board.try_move(0, 0, 1) and int(board._state["done"]) == 2, 
		"级联重复收同列仍同步结算两盆")
	_check(board.sync_error() == "", "级联规则与新节点一致")
	board.setup(board._level)
	_check(board._legacy_replenish_pending.is_empty(), "重开清理级联待入场节点")
	_free_board(board)
	var themed: Variant = _new_board()
	var slots: = PackedInt32Array([3, 2, 1, 0])
	var default_skin: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	themed.apply_skin(JuiceSkinResolver.new(default_skin, default_skin), false)
	themed.setup(themed._level, {}, slots)
	var snapshot: Dictionary = themed.snapshot()
	_check(themed.restore(themed._level, snapshot, slots) and themed._slots == slots
		and themed.skin_resources().active_skin.id == &"default" and themed.sync_error() == "", "续局保留配色与默认皮肤")
	_free_board(themed)


func _test_static_lock() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_lock_overlay.tscn")
	var overlay: JuiceLockOverlay = scene.instantiate()
	root.add_child(overlay)
	overlay.set_geometry(400.0, 200.0, 1300.0, 230.0)
	overlay.show_count(3)
	_check(overlay._vine0.visible and overlay._vine1.visible and overlay._num.visible
		and not overlay._flower.visible and overlay._badge.scale == Vector2.ONE, 
		"锁列立即显示两段藤条及完整木牌／数字")
	overlay.set_geometry(500.0, 220.0, 800.0, 230.0)
	_check(overlay._vine0.visible and not overlay._vine1.visible
		and overlay._badge.modulate.a == 1.0, "锁列复用不留第二段藤条或半透明木牌")
	overlay.show_flower(overlay._flower.texture)
	_check(overlay._flower.visible and not overlay._num.visible, "锁列按类型切换条件花／数字")
	overlay.queue_free()


func _run() -> void :
	_scene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	_test_legacy_replenish_visibility()
	_test_rope_prop()
	_test_cascade_and_theme()
	_test_static_lock()
	await process_frame
	SortLogger.info("REPLENISH_DROP_RESULT: %d failures" % _failures.size())
	quit(0 if _failures.is_empty() else 1)



func _test_legacy_replenish_visibility() -> void :
	var board: Variant = _new_board()
	_check(board.try_move(0, 0, 2), "原版收盆产生待入场花列")
	board._cancel_closed_check()
	var token: int = int(board._visual_token_by_col[2])
	var flowers: Array = board._fruit_nodes[2]
	var hidden: bool = true
	for flower: JuiceFruit in flowers:
		hidden = hidden and not flower.visible
	_check(hidden and flowers.size() == 4, "补列创建当帧全部隐藏,模型和节点数量保持")
	var shift: Dictionary = board._shift_queue[0]
	var starts_at: float = float(shift["start_at"]) + float(shift["delay"][token])
	board._process(starts_at - float(board._t) - 0.001)
	hidden = true
	for flower: JuiceFruit in flowers:
		hidden = hidden and not flower.visible
	_check(hidden, "补列自身延迟结束前保持隐藏")
	var waited_hidden: bool = true
	for frame: int in 600:
		board._process(1.0 / 60.0)
		if flowers[0].visible:
			break
		for flower: JuiceFruit in flowers:
			waited_hidden = waited_hidden and not flower.visible
	_check(waited_hidden, "飞盆暂停列移期间补列仍隐藏")
	var shown: bool = true
	for flower: JuiceFruit in flowers:
		shown = shown and flower.visible
	_check(shown and board._col_x(2) > board._base_x(2), "滑入首帧显示,仍沿原曲线移动")
	for frame: int in 600:
		board._process(1.0 / 60.0)
		if not board.is_busy():
			break
	_check( not board.is_busy() and board.sync_error() == "", "原版补列正常收尾且模型一致")
	board.setup(board._level)
	var rebuilt: bool = true
	for list: Array in board._fruit_nodes.values():
		for flower: JuiceFruit in list:
			rebuilt = rebuilt and flower.visible
	_check(rebuilt and board._legacy_replenish_pending.is_empty(), "重开池复用不遗留隐藏状态")
	_free_board(board)
