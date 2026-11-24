extends SceneTree



var _failures: Array[String] = []
var _scene: PackedScene


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		SortLogger.error("容量文字自测失败：%s" % message)


func _verify_config() -> void :
	var cfg: SortRopeCapacityKnotsConfig = ABManager.sort_rope_capacity_knots
	var expected_calls: Array = ["get", "dye"] if SortRopeCapacityKnotsConfig.FEATURE_ENABLED else []
	_check(cfg.key == "sort_rope_capacity_knots" and cfg.version == "1.0.4", "配置注册与版本")
	_check(cfg.timing == ABManager.TIMING_ENTER_GAME and cfg.default_value == 0, "进页染色与默认对照组")
	for raw: String in ["no", "yes", "", "unknown", "1", "YES"]:
		ABManager.set("sdk_value", raw)
		var expected: int = 1 if raw == "yes" else 0
		var fresh: = SortRopeCapacityKnotsConfig.new()
		fresh.init_default()
		_check(fresh.value() == expected, "SDK 懒加载映射 %s" % raw)
		_check(fresh.peek_value() == expected, "SDK 面板实时映射 %s" % raw)
		fresh.load_value_silent()
		_check(fresh.value() == expected, "SDK 静默映射 %s" % raw)
		ABManager.set("sdk_calls", [])
		fresh.reload_value()
		_check(fresh.value() == expected, "SDK 染色映射 %s" % raw)
		_check(ABManager.get("sdk_calls") == expected_calls, "染色遵守总开关 %s" % raw)
	ABManager.set("sdk_value", "yes")
	ABManager.set("sdk_calls", [])
	ABManager.dye_at_enter_game()
	var entry_calls: Array = (ABManager.get("sdk_calls") as Array).duplicate()
	_check(cfg.is_capacity_knots_enabled() == SortRopeCapacityKnotsConfig.FEATURE_ENABLED
		and entry_calls == expected_calls, "进页功能与染色均遵守总开关")
	cfg.set_debug_override(0)
	_check( not cfg.is_capacity_knots_enabled(), "int 对照覆盖优先于 SDK yes")
	cfg.set_debug_override(1)
	_check(cfg.value() == 1 and cfg.is_capacity_knots_enabled() == SortRopeCapacityKnotsConfig.FEATURE_ENABLED, 
		"int 实验覆盖保留分组，功能遵守总开关")
	cfg.clear_debug_override()
	_check(int(ABManager.get("int_reads")) == 0, "所有路径均未调用 get_ab_int")
	ABManager.set("sdk_value", "no")
	cfg.reload_value()


func _level(capacity: int = 5, columns: int = 6) -> JuiceLevel:
	var initial: Array[String] = []
	for ci: int in columns:
		var beads: Array[String] = []
		for j: int in capacity:
			beads.append(str((ci + j) % columns))
		initial.append("%d|%s" % [ci, ",".join(beads)])
	var incoming: Array[String] = []
	for ci: int in columns - 1:
		incoming.append("x")
	return JuiceLevel.from_dict({"id": 6, "capacity": capacity, "targetCups": columns, 
		"initial": initial, "incoming": incoming})


func _board(level: JuiceLevel, viewport_width: float = 1080.0) -> JuiceBoardView:
	var board: JuiceBoardView = _scene.instantiate() as JuiceBoardView
	board.anchor_right = 0.0
	board.anchor_bottom = 0.0
	root.add_child(board)
	board.size = Vector2(viewport_width, 1624.0 if level.layout_rows == 2 else 1304.0)
	board.setup(level)
	board._cancel_closed_check()
	board.set_process(false)
	return board


func _settle(board: JuiceBoardView) -> void :
	for frame: int in 240:
		board._process(1.0 / 60.0)


func _label(board: JuiceBoardView, ci: int) -> Label:
	return (board._capacity_label_nodes[ci] as Control).get_node("Root/Label") as Label


func _verify_geometry(board: JuiceBoardView) -> void :
	board._refresh_capacity_labels()
	_check(board._capacity_label_nodes.size() == board._order.size(), "每根在场绳子对应一个数字")
	for ci: int in board._order:
		var item: Control = board._capacity_label_nodes[ci]
		var text: Label = _label(board, ci)
		var end_y: float = board._lay.rope_bottom + board._row_y(ci)
		_check(item.visible and item.position.y > end_y, "文字位于绳尾下方 ci=%d cap=%d" % [ci, board.level().capacity])
		var mask_bottom: float = board._col_capsule_rect(ci).end.y
		_check(item.position.y >= mask_bottom + JuiceRopeCapacityLabel.MASK_GAP - 0.01, 
			"容量文字位于教学/放置 mask 下沿外 ci=%d cap=%d text=%.2f mask=%.2f" % [ci, board.level().capacity, item.position.y, mask_bottom])
		_check(item.position.y + item.size.y <= board.size.y + 0.01, 
			"文字不被盘面裁切 ci=%d cap=%d bottom=%.2f board=%.2f" %
			[ci, board.level().capacity, item.position.y + item.size.y, board.size.y])
		if board.level().layout_rows == 2 and is_zero_approx(board._row_y(ci)):
			_check(item.position.y + item.size.y <= board._lay.row_pitch + 0.01, "上排文字不进入下排花盆区域")
		_check(is_equal_approx(item.position.x + item.size.x * 0.5, board._col_x(ci) + board._content_dx), "跟随实际列中心")
		_check(text.text == "%d/%d" % [(board.state()["cols"][ci] as Array).size(), board.level().capacity], "读真实盘面数量")
		_check(text.get_theme_font_size("font_size") == 56 and is_equal_approx(item.modulate.a, 0.3), "字号56、透明度30%")
		_check(text.get_theme_color("font_color").is_equal_approx(Color("557b9e")), "颜色 #557B9E")
		_check(text.mouse_filter == Control.MOUSE_FILTER_IGNORE and item.mouse_filter == Control.MOUSE_FILTER_IGNORE, "文字不挡拖拽")


func _verify_tutorial_spacing() -> void :
	var tutorial_level: JuiceLevel = JuiceTutorialScript.build_level()
	var board: JuiceBoardView = _board(tutorial_level)
	board.set_capacity_knots_enabled(true)
	board.setup(tutorial_level)
	board.set_col_marks(0, 1, [2, 3])
	_verify_geometry(board)
	for mark: JuiceColMark in board._col_mark_live:
		var ci: int = int(mark.get_meta(&"col"))
		var symbol: TextureRect = mark.get_node("Mark")
		var text: Control = board._capacity_label_nodes[ci]
		_check(symbol.visible and text.get_global_rect().position.y >= symbol.get_global_rect().end.y + JuiceRopeCapacityLabel.MASK_GAP - 0.01, 
			"教学容量文本避开对勾/叉号 ci=%d" % ci)
	var tutorial_top: float = board._capacity_label_top()
	board.clear_col_marks()
	board._refresh_capacity_labels()
	_check(is_equal_approx(board._capacity_label_top(), tutorial_top), "教学阶段收起标记时文字不跳动")
	var normal_level: JuiceLevel = _level(3, 4)
	normal_level.id = 4
	board.setup(normal_level)
	_verify_geometry(board)
	var normal_top: float = board._lay.rope_bottom + board._lay.fruit_d * JuiceLayout.TRACK_BOTTOM_FRUIT_RATIO + JuiceRopeCapacityLabel.MASK_GAP
	_check(is_equal_approx(board._capacity_label_top(), normal_top), "第4关保留正常间距，缓存复用不残留标记偏移")
	board.queue_free()
	await process_frame


func _verify_early_level_spacing() -> void :
	for level_id: int in [2, 3]:
		var level: JuiceLevel = JuiceLevel.from_dict({"id": level_id, "capacity": 3, "targetCups": 3, 
			"initial": ["-|", "0|0,0,1", "1|1,1,0"], "incoming": ["2|2,2,2", "x"]})
		var board: JuiceBoardView = _board(level)
		board.set_capacity_knots_enabled(true)
		board.setup(level)
		var initial_top: float = board._capacity_label_top()
		board._begin_drag(board._home_pos(1, 2))
		_check( not board._col_mark_live.is_empty(), "第%d关真实拖拽出现对勾" % level_id)
		_verify_geometry(board)
		for mark: JuiceColMark in board._col_mark_live:
			var symbol: TextureRect = mark.get_node("Mark")
			var label: Control = board._capacity_label_nodes[int(mark.get_meta(&"col"))]
			_check(label.get_global_rect().position.y >= symbol.get_global_rect().end.y + JuiceRopeCapacityLabel.MASK_GAP - 0.01, 
				"第%d关容量文字避开拖拽对勾" % level_id)
		board._cancel_drag()
		_check(is_equal_approx(board._capacity_label_top(), initial_top), "第%d关收起对勾时文字位置稳定" % level_id)
		board.queue_free()
		await process_frame


func _run() -> void :
	_verify_config()
	if "--config-only" in OS.get_cmdline_user_args():
		if _failures.is_empty():
			SortLogger.info("ROPE_CAPACITY_KNOTS_SELFTEST PASS")
		quit(0 if _failures.is_empty() else 1)
		return
	_scene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	await _verify_tutorial_spacing()
	await _verify_early_level_spacing()
	for sample: Vector3 in [Vector3(3, 3, 1080), Vector3(5, 6, 1080), Vector3(6, 7, 1080), Vector3(8, 7, 1080), Vector3(5, 7, 1314), Vector3(5, 7, 1755)]:
		var board: JuiceBoardView = _board(_level(int(sample.x), int(sample.y)), sample.z)
		_check( not board.get_node("CapacityLabels").visible and board._capacity_label_nodes.is_empty(), "对照组没有容量文字")
		var old_rope_bottom: float = board._lay.rope_bottom
		var old_diameter: float = board._lay.fruit_d
		board.set_capacity_knots_enabled(true)
		board.setup(board.level(), board.state())
		_verify_geometry(board)
		if old_rope_bottom + old_diameter * JuiceLayout.TRACK_BOTTOM_FRUIT_RATIO\
		+ JuiceRopeCapacityLabel.MASK_GAP + JuiceRopeCapacityLabel.HEIGHT <= board.size.y:
			_check(board._lay.rope_bottom == old_rope_bottom and board._lay.fruit_d == old_diameter, "空间充足时保留既有绳花几何")
		var child_count: int = board.get_node("CapacityLabels").get_child_count()
		var identities: Dictionary = board._capacity_label_nodes.duplicate()
		for frame: int in 20:
			board._process(1.0 / 60.0)
		_check(board.get_node("CapacityLabels").get_child_count() == child_count and board._capacity_label_nodes == identities, "每帧不重建节点")
		board.set_capacity_knots_enabled(false)
		_check( not board.get_node("CapacityLabels").visible and board._capacity_label_nodes.is_empty(), "缓存切回对照清空显示")
		board.set_capacity_knots_enabled(true)
		_check(board.get_node("CapacityLabels").get_child_count() == child_count, "再次开启复用原节点")
		board.queue_free()
		await process_frame

	var level: JuiceLevel = JuiceLevel.from_dict({"id": 7, "capacity": 3, "targetCups": 3, 
		"initial": ["-|", "0|0,0,1", "1|1,1,0"], "incoming": ["2|2,2,2", "x"]})
	var board: JuiceBoardView = _board(level)
	board.set_capacity_knots_enabled(true)
	board._begin_drag(board._home_pos(1, 2))
	board._refresh_capacity_labels()
	_check(_label(board, 1).text == "3/3", "起抓不提前扣除数量")
	board._cancel_drag()
	_check(board.try_move(1, 2, 0), "搬到空绳")
	board._process(1.0 / 60.0)
	_check(_label(board, 1).text == "2/3" and _label(board, 0).text == "1/3", "有效移动更新两串数量")
	_settle(board)
	_check(board.try_move(2, 2, 1), "凑满收盆并补货")
	_settle(board)
	_verify_geometry(board)
	_check(board.state()["done"] > 0, "确实经过收盆")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	_check(board.undo(), "撤回收盆")
	board._refresh_capacity_labels()
	_check(_label(board, 1).text == "2/3" and _label(board, 2).text == "3/3", "撤回恢复容量文字")
	_check(board.add_rope(), "加绳道具")
	_settle(board)
	var added: int = (board.state()["cols"] as Array).size() - 1
	_check(_label(board, added).text == "0/3", "新增空绳显示 0/3")
	_check(board.restore(level, snapshot), "续局恢复")
	board._refresh_capacity_labels()
	_verify_geometry(board)
	board.setup(_level())
	board._refresh_capacity_labels()
	_verify_geometry(board)
	_check(_label(board, 0).text.ends_with("/5"), "重开/换关不残留旧容量")
	board.queue_free()
	await process_frame

	var two_row_initial: Array[String] = ["-|"]
	for ci: int in 10:
		two_row_initial.append("%d|%d,%d,%d,%d" % [ci, ci, ci, (ci + 5) % 10, (ci + 5) % 10])
	var two_row: JuiceLevel = JuiceLevel.from_dict({"id": 5, "layoutRows": 2, "layoutColumns": 5, 
		"capacity": 4, "targetCups": 14, "initial": two_row_initial, 
		"incoming": ["0|0,0,5,5", "5|5,5,0,0", "1|1,1,6,6", "6|6,6,1,1"]})
	board = _board(two_row)
	var original_row_pitch: float = board._lay.row_pitch
	board.set_capacity_knots_enabled(true)
	board.setup(two_row)
	_verify_geometry(board)
	_check(is_equal_approx(board._lay.row_pitch, original_row_pitch), "容量文字保留下排货架位置")
	_check(is_equal_approx((board._capacity_label_nodes[6] as Control).position.y - (board._capacity_label_nodes[1] as Control).position.y, board._lay.row_pitch), "双排使用真实行偏移")
	_check(board.add_rope(), "双排新增空绳")
	_settle(board)
	_verify_geometry(board)
	board.queue_free()
	await process_frame
	if _failures.is_empty():
		SortLogger.info("ROPE_CAPACITY_KNOTS_SELFTEST PASS")
		quit(0)
	else:
		quit(1)
