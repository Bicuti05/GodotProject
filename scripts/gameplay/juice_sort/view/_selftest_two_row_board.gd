extends SceneTree

const R: = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
var _failures: Array[String] = []
var _scene: PackedScene

func _initialize() -> void :
	call_deferred("_run")

func _check(ok: bool, label: String) -> void :
	if not ok:
		_failures.append(label)
	SortLogger.info("%s: %s" % ["PASS" if ok else "FAIL", label])

func _level() -> JuiceLevel:
	var initial: Array = ["-|"]
	for c: int in 10:
		var other: int = (c + 5) % 10
		initial.append("%d|%d,%d,%d,%d" % [c, c, c, other, other])
	return JuiceLevel.from_dict({"id": 5, "layoutRows": 2, "layoutColumns": 5, 
		"capacity": 4, "targetCups": 14, "initial": initial, 
		"incoming": ["0|0,0,5,5", "5|5,5,0,0", "1|1,1,6,6", "6|6,6,1,1"]})

func _board(lv: JuiceLevel, _new_style: bool):
	var board: Variant = _scene.instantiate()
	board.anchor_right = 0.0
	board.anchor_bottom = 0.0
	root.add_child(board)
	board.size = Vector2(1080, 1624 if lv.layout_rows == 2 else 1304)
	board.setup(lv)
	board._cancel_closed_check()
	board.set_process(false)
	return board

func _settle(board: Variant) -> void :
	for i: int in 240:
		board._process(1.0 / 60.0)

func _free(board: Variant) -> void :
	board._cancel_closed_check()
	for field: String in ["_death_task_id", "_closed_task_id", "_challenge_task_id"]:
		var task: Variant = board.get(field)
		if task is int and task >= 0:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()

func _run() -> void :
	_scene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	var lv: JuiceLevel = _level()
	_check(lv.validate().is_empty(), "14盆题面校验")
	_check(JuiceLevel.from_dict(lv.to_dict()).layout_rows == 2, "冻结题面保留双排")
	var proof: Array = [[1, 2, 0], [6, 2, 1], [0, 0, 6], [1, 2, 0], [6, 2, 1], [0, 0, 6], 
		[2, 2, 0], [7, 2, 2], [0, 0, 7], [1, 2, 0], [6, 2, 1], [0, 0, 6], 
		[3, 2, 0], [8, 2, 3], [0, 0, 8], [4, 2, 0], [9, 2, 4], [0, 0, 9], 
		[5, 2, 0], [10, 2, 5], [0, 0, 10]]
	var st: Dictionary = R.make_state(lv)
	for move: Array in proof:
		_check(R.move_info(st, move[0], move[1], move[2]) > 0, "证明走法 %s" % str(move))
		R.apply_move(st, lv, move[0], move[1], move[2])
	_check(R.is_win(st, lv), "21步完成全部14盆")
	for new_style: bool in [false, true]:
		var board: Variant = _board(lv, new_style)
		_check(board._slot_of[1] == 0 and board._slot_of[6] == 5 and board._slot_of[0] == 10, "两排各5盆，独立空绳")
		_check(board._second_plank.visible, "第二排使用现有货架资源")
		_check(is_equal_approx(board._plank.scale.y, 0.8), "双排木架压薄20%")
		_check(board._lay.fruit_d > 170.0 and board._lay.gap >= board._lay.fruit_d * 0.68, "缩小后的双排花朵仍清晰且可见花瓣不重叠")
		_check(board._home_pos(6, 0).y > board._home_pos(1, 3).y + board._lay.fruit_d * 0.5, "上下排花朵不重叠")
		_check(board._home_pos(6, 3).y + board._lay.fruit_d * 0.5 < board.size.y, "下排完整落在操作区域")
		_check(board._hit_fruit(board._home_pos(6, 2)).get("col", -1) == 6, "下排花朵命中")
		_check(board._hit_column(board._home_pos(6, 3), 1, 2) == 6, "跨排落点不会命中上排同X列")
		var other_x: float = board._base_x(7)
		var other_y: float = board._home_pos(7, 0).y
		_check(board.try_move(1, 2, 0), "移动到临时空绳")
		_settle(board)
		var flower: Node2D = board._fruit_nodes[6][2]
		var press: InputEventMouseButton = InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = board.get_global_transform().affine_inverse() * flower.global_position
		board._gui_input(press)
		_check( not board._drag.is_empty(), "跨排拖拽起抓")
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = Vector2(board._col_x(1), board._lay.plank_top + 10.0) + board._drag["grab"]
		board._gui_input(motion)
		var release: InputEventMouseButton = InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = motion.position
		board._gui_input(release)
		_check(board.state().done == 1, "跨排鼠标松手经现有Flow完成上排盆")
		_check(board._slot_of[1] == 4 and board._slot_of[2] == 0 and board._slot_of[6] == 5, "收上排盆只重排上排")
		_check(is_equal_approx(board._base_x(7), other_x) and is_equal_approx(board._home_pos(7, 0).y, other_y), "另一排位置不变")
		_check(board._col_x(1) > board.size.x, "新盆从对应排右侧滑入")
		_check(is_equal_approx(board._beats[-1].row_y, 0.0), "上排收盆特效保留行坐标")
		_settle(board)
		var blob: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
		var resumed: Variant = _board(lv, new_style)
		_check(resumed.restore(lv, blob), "双排续局恢复")
		_check(resumed._slot_of == board._slot_of, "续局保持各排顺序")
		_check(resumed.undo(), "续局后撤回收盆")
		_check(resumed._slot_of[1] == 0 and resumed._slot_of[6] == 5, "撤回还原原排原位置")
		_free(resumed)
		_check(board.try_move(0, 0, 6), "完成下排盆")
		_check(board._slot_of[6] == 9 and board._slot_of[7] == 5, "下排补盆滑到下排末尾")
		_check(is_equal_approx(board._beats[-1].row_y, board._lay.row_pitch), "下排幽灵和特效行坐标")
		_settle(board)
		for index: int in range(3, proof.size()):
			var move: Array = proof[index]
			_check(board.try_move(move[0], move[1], move[2]), "真实盘面走法%d" % index)
			_settle(board)
		_check(R.is_win(board.state(), lv), "双排真实交互完成14盆")
		_free(board)
		await process_frame
	var added: Variant = _board(lv, false)
	var original_slots: Dictionary = added._slot_of.duplicate()
	_check(added.add_rope(), "双排道具增加独立空绳")
	_settle(added)
	_check(added._slot_of[11] == 11 and added._row_y(11) == added._lay.row_pitch, "新增空绳放在下排左侧")
	for ci: int in original_slots:
		_check(added._slot_of[ci] == original_slots[ci], "加绳不压缩或重排已有列%d" % ci)
	var added_resume: Variant = _board(lv, false)
	_check(added_resume.restore(lv, JSON.parse_string(JSON.stringify(added.snapshot()))), "加绳后的双排续局")
	_free(added_resume)
	_free(added)
	await process_frame
	var dual_data: Dictionary = lv.to_dict()
	(dual_data["initial"] as Array).push_front("-|")
	var dual_lv: JuiceLevel = JuiceLevel.from_dict(dual_data)
	_check(dual_lv.validate().is_empty(), "每排一根独立空绳的题面合法")
	var dual_board: Variant = _board(dual_lv, false)
	_check(dual_board._slot_of[0] == 10 and dual_board._slot_of[1] == 11, "上下排白盆占独立槽位")
	_check(dual_board._row_y(1) == dual_board._lay.row_pitch, "下排白盆和空绳行坐标")
	_check(dual_board.try_move(2, 2, 1), "上排花能拖到下排空绳")
	_settle(dual_board)
	var dual_resume: Variant = _board(dual_lv, false)
	_check(dual_resume.restore(dual_lv, JSON.parse_string(JSON.stringify(dual_board.snapshot()))), "两根初始空绳续局")
	_check(dual_resume._slot_of == dual_board._slot_of, "两根空绳续局槽位一致")
	_check(dual_board.add_rope(), "两根初始空绳后仍可用加绳道具")
	_settle(dual_board)
	_check(dual_board._slot_of[12] == 12 and dual_board._lay.top_extra_rope, "道具空绳独立排在上排")
	_free(dual_resume)
	_free(dual_board)
	await process_frame

	var old: JuiceLevel = JuiceLevel.from_dict({"capacity": 4, "targetCups": 2, 
		"initial": ["-|", "0|0,0,1,1", "1|1,1,0,0"], "incoming": []})
	var old_board: Variant = _board(old, false)
	_check(old_board._lay.rows == 1 and old_board._second_plank == null, "原关卡保持单排")
	_free(old_board)
	await process_frame
	await _test_interleaved_parks(lv)
	await _test_nine_locked()
	SortLogger.info("two-row board: %d failures" % _failures.size())
	quit(0 if _failures.is_empty() else 1)



func _test_interleaved_parks(source: JuiceLevel) -> void :
	var data: Dictionary = source.to_dict()
	var initial: Array = data["initial"]
	initial.pop_front()
	initial.insert(3, "-|")
	initial.append("-|")
	var lv: JuiceLevel = JuiceLevel.from_dict(data)
	_check(lv.validate().is_empty() and lv.board_jars == [0, 1, 2, -1, 3, 4, 5, 6, 7, 8, 9, -1], 
		"中间、末尾双白盆保持原始逻辑列号")
	var board: Variant = _board(lv, false)
	_check(board._slot_of[0] == 0 and board._slot_of[5] == 4 and board._slot_of[6] == 5, 
		"彩盆按题面出现顺序分配上下排")
	_check(board._slot_of[3] == 10 and board._slot_of[11] == 11
		and board._row_y(11) == board._lay.row_pitch, "非前置白盆按出现顺序占独立槽位")
	var legacy: Dictionary = board.snapshot()
	legacy.erase("initial_slot_of")
	var legacy_order: Array[int] = [3, 11, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10]
	for field: String in ["cols", "jars", "caps", "gone", "locks"]:
		var values: Array = (legacy["state"][field] as Array).duplicate()
		for ci: int in legacy_order.size():
			legacy["state"][field][ci] = values[legacy_order[ci]]
	var legacy_state: Dictionary = (legacy["state"] as Dictionary).duplicate(true)
	var legacy_board: Variant = _board(lv, false)
	_check(legacy_board.restore(lv, JSON.parse_string(JSON.stringify(legacy)))
		and legacy_board.snapshot()["state"] == legacy_state
		and legacy_board._slot_of[0] == 10 and legacy_board._slot_of[1] == 11
		and legacy_board._slot_of[2] == 0 and legacy_board._slot_of[7] == 5, 
		"旧版双排续局保留白盆左置的逻辑列及排归属")
	var legacy_again: Variant = _board(lv, false)
	_check(legacy_again.restore(lv, JSON.parse_string(JSON.stringify(legacy_board.snapshot())))
		and legacy_again._slot_of == legacy_board._slot_of, "旧续局再次保存恢复仍保持原布局")
	legacy_board.setup(lv)
	_check(legacy_board._slot_of[3] == 10 and legacy_board._slot_of[0] == 0, 
		"旧双排重开后使用真实题面的原始列号")
	_free(legacy_again)
	_free(legacy_board)
	_check(board.try_move(0, 2, 3), "按原列号把上排花移入中间白盆")
	_settle(board)
	_check(board.try_move(6, 2, 0) and board.state().done == 1, "跨排移动按原列号完成上排盆")
	_settle(board)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	var resumed: Variant = _board(lv, false)
	_check(resumed.restore(lv, saved) and resumed._slot_of == board._slot_of, 
		"非前置白盆续局保留各排与独立槽位")
	var malformed: Dictionary = saved.duplicate(true)
	malformed["initial_slot_of"]["0"] = 10
	_check( not resumed.restore(lv, malformed), "重复的初始槽位视为坏档，不错排白盆")
	_check(resumed.undo() and resumed._slot_of[0] == 0 and resumed._slot_of[6] == 5, 
		"撤销收盆保持彩盆原所属排")
	_check(board.add_rope(), "非前置双白盆仍可增加道具空绳")
	_settle(board)
	_check(board._slot_of[12] == 12 and board._lay.top_extra_rope, "新增空绳仍使用既有独立格位")
	_free(resumed)
	_free(board)
	await process_frame


func _test_nine_locked() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"capacity": 4.0, "id": 5.0, "incoming": [], "initial": ["-|", "-|", "0|3,4,3,2", "1|1,4,1,0", "2|2,0,4,0", "3|2,1,3,0", {"column": "5|5,6,5,6", "columnInfo": {"condition": "collect_count", "count": 2.0}, "columnType": "unlock"}, "4|4,1,3,2", {"column": "6|6,5,6,5", "columnInfo": {"condition": "collect_count", "count": 3.0}, "columnType": "unlock"}, {"column": "7|7,8,7,8", "columnInfo": {"condition": "collect_type", "count": 1.0, "typeId": 5.0}, "columnType": "unlock"}, {"column": "8|8,7,8,7", "columnInfo": {"condition": "collect_type", "count": 1.0, "typeId": 6.0}, "columnType": "unlock"}], "layoutColumns": 5.0, "layoutRows": 2.0, "targetCups": 9.0})
	var proof: Array = [[4, 1, 1], [7, 3, 4], [5, 1, 0], [2, 3, 5], [5, 0, 4], [1, 1, 5], [0, 2, 1], [1, 0, 5], [2, 0, 1], [3, 3, 2], [5, 1, 2], [1, 2, 7], [5, 0, 1], [7, 1, 5], [3, 1, 7], [7, 2, 3], [1, 1, 7], [0, 0, 3], [3, 3, 0], [5, 1, 1], [5, 0, 3], [1, 0, 5], [0, 0, 5], [8, 2, 1], [8, 1, 1], [6, 3, 8], [6, 1, 8], [1, 1, 6], [8, 3, 6], [1, 0, 8], [10, 2, 1], [10, 1, 1], [9, 3, 10], [9, 1, 10], [1, 1, 9], [10, 3, 9], [1, 0, 10]]
	_check(lv.validate().is_empty(), "9盆混合锁题面合法")
	for new_style: bool in [false, true]:
		var board: Variant = _board(lv, new_style)
		_check(board._slot_of[6] == 4 and board._slot_of[7] == 5, "上排5盆下排4盆")
		_check(board._lay.rope_bottom + board._lay.row_pitch <= board.size.y, "9盆下排绳尾不裁切")
		for move: Array in proof:
			_check(board.try_move(move[0], move[1], move[2]), "9盆锁列实际走法")
			_settle(board)
			for row: int in [0, 1]:
				var xs: Array[float] = []
				for ci: int in board._order:
					if board._lay.slot_offset_y(int(board._slot_of[ci])) == (0.0 if row == 0 else board._lay.row_pitch):
						xs.append(board._col_x(ci))
				if not xs.is_empty():
					_check(absf((xs.min() + xs.max()) * 0.5 - 540.0) < 1.0, "收盆后每排独立居中")
		_check(R.is_win(board.state(), lv), "37步解开4锁并完成9盆")
		_free(board)
		await process_frame
