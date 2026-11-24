extends Node


class ProbePage extends JuiceGamePage:
	func _stop_undo_guide_motion_preview(_immediate: bool = true) -> void :
		pass


var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _run() -> void :
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "persist-write" in args:
		UserState.reset_all()
		UserState.settle_user_level(4, 0, [])
		UserState.settle_user_level(3, 0, [])
		_check(UserState.has_reached_user_level_4(), "写入降档后的永久标记")
	elif "persist-read" in args:
		_check(UserState.get_user_level() == 3 and UserState.has_reached_user_level_4(), "跨进程保留达4档历史")
	else:
		_test_config()
		_test_user_history()
		await _test_page_and_board()
		await _test_startup_timeout()
	if _failures.is_empty():
		SortLogger.info("GREEN_FRAME_GUIDE_SELFTEST PASS")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		SortLogger.error("GREEN_FRAME_GUIDE: " + message)


func _test_config() -> void :
	for cfg: AbConfigBase in ABManager.get_all_configs():
		_check(cfg.key != "green_frame_guide", "延长引导不再注册或出现在AB面板")


func _test_user_history() -> void :
	for tier: int in range(6):
		UserState.reset_all()
		UserState.settle_user_level(tier, 0, [])
		_check(UserState.has_reached_user_level_4() == (tier >= 4), "正常结算档位%d" % tier)
	UserState.reset_all()
	UserState.settle_user_level(3, 0, [])
	UserState.settle_user_level(4, 0, [])
	UserState.settle_user_level(3, 0, [])
	UserState._load_data()
	_check(UserState.get_user_level() == 3 and UserState.has_reached_user_level_4(), "3→4→3保存并读取")
	UserState.reset_all()
	UserState.cheat_set_user_level(5)
	UserState.cheat_set_user_level(0)
	_check(UserState.has_reached_user_level_4(), "cheat降到未分档也不清历史")
	for tier: int in range(6):
		UserState.reset_all()
		var legacy: = ConfigFile.new()
		_check(legacy.load_encrypted_pass(UserState._resolve_save_path(), UserState.SAVE_PASSWORD) == OK, "读迁移夹具")
		legacy.set_value("progress", "user_level", tier)
		legacy.erase_section_key("progress", "user_level_reached_4")
		_check(legacy.save_encrypted_pass(UserState._resolve_save_path(), UserState.SAVE_PASSWORD) == OK, "写旧存档夹具")
		UserState._load_data()
		_check(UserState.has_reached_user_level_4() == (tier >= 4), "旧存档当前档位迁移%d" % tier)
		UserState.settle_user_level(1, 0, [])
		UserState._load_data()
		_check(UserState.has_reached_user_level_4() == (tier >= 4), "迁移后降档保存%d" % tier)
	UserState.reset_all()
	_check( not UserState.has_reached_user_level_4(), "清档复位")


func _test_page_and_board() -> void :

	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: JuiceBoardView = scene.instantiate() as JuiceBoardView
	var page: JuiceGamePage = ProbePage.new()
	page._board = board

	board.tutorial_demo_only = true
	add_child(board)
	board.set_process(false)
	board.drag_started.connect(page._on_board_drag_started)
	board.set_entrance_lock(false)
	board.set_input_enabled(true)
	board.set("_sway_enabled", false)
	for group: int in range(3):
		ABManager.set("sdk_value", ["old", "tier_3", "tier_5"][group])
		for level_id: int in [1, 2, 3, 4, 9]:
			UserState.reset_all()
			UserState.set_debug_ab_override("green_frame_guide", group)
			_setup(page, level_id)
			_check(board.move_info(board._state_ref(), 0, 0, 1) > 0, "夹具有合法连接目标")
			ABManager.set("events", [])
			_grab(board, 0, 0)
			_check(ABManager.get("events") == [], "旧覆盖不再取值或染色%d/%d" % [group, level_id])
			var show: bool = level_id <= 3
			_check(board._has_col_mark_guide() == show and board._rule_col_marks == show, "首次起抓引导%d/%d" % [group, level_id])
			_check_drop_highlight(board, 0)
			if show:
				_check( not (board._col_mark_spec["guides"] as Array).has(0), "原列不作为合法目标打勾")
				for ci: int in board._col_mark_spec["guides"]:
					_check(board.move_info(board._state_ref(), 0, 0, ci) > 0, "每个绿框都合法")
				_test_selected_col_marks(board)
			var events_before_hover: Array = (ABManager.get("events") as Array).duplicate()
			_hover(board, 2)
			_check(board._drop_hover.visible == (level_id <= 3), "第4关起非法预览永久隐藏，不依赖绿框组")
			_check(ABManager.get("events") == events_before_hover, "悬停非法列不再访问SDK或染色")
			board.cancel_active_drag()
			_check( not board._rule_col_marks and board._col_mark_live.is_empty() and not board._drop_hover.visible, "取消清场")
	_test_drop_style_equivalence(page)
	_test_invalid_previews(page)
	_test_invalid_preview_reasons(page)

	UserState.set_debug_ab_override("green_frame_guide", 2)
	_setup(page, 4)
	ABManager.set("events", [])
	_check(board.move_info(board._state_ref(), 2, 0, 0) == 0, "夹具异色目标不能连接")
	_grab(board, 2, 0)
	_check( not (ABManager.get("events") as Array).has("dye") and board._col_mark_live.is_empty(), "无合法目标不染色且无目标框")
	_check_drop_highlight(board, 2)
	_hover(board, 0)
	_check( not board._drop_hover.visible, "无合法目标时非法预览也隐藏")
	board.cancel_active_drag()

	ABManager.set("events", [])
	board._begin_drag(Vector2(-1000, -1000))
	board.set_grab_gate( func(_src: int, _j: int) -> bool: return false)
	_grab(board, 0, 0)
	_check(board._drag.is_empty() and ABManager.get("events") == [], "空白与起抓门控不染色")
	board.set_grab_gate(Callable())
	board._state_ref()["locks"][0] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 99}
	_grab(board, 0, 0)
	_check(board._drag.is_empty() and ABManager.get("events") == [], "锁列起抓不染色")

	UserState.set_debug_ab_override("green_frame_guide", 0)
	_setup(page, 4)
	UserState.set_debug_ab_override("green_frame_guide", 2)
	_grab(board, 2, 0)
	_check( not board._has_col_mark_guide() and board._drop_hover.visible, "旧覆盖切换不延长且保留原列选中")
	board.cancel_active_drag()

	for group: int in range(3):
		UserState.reset_all()
		UserState.cheat_set_user_level(4)
		UserState.set_debug_ab_override("green_frame_guide", group)
		_setup(page, 20, true)
		ABManager.set("events", [])
		_grab(board, 0, 0)
		_check( not (ABManager.get("events") as Array).has("dye"), "特殊挑战不染色")
		_check( not board._has_col_mark_guide(), "特殊挑战旧覆盖%d不延长" % group)
		board.cancel_active_drag()

	UserState.reset_all()
	UserState.set_debug_ab_override("green_frame_guide", 2)
	_setup(page, 3)
	var saved: Dictionary = board.snapshot()
	_check(board.restore(board.level(), saved), "续局恢复")
	_grab(board, 0, 0)
	_test_selected_col_marks(board)
	_hover(board, 0)
	board._drop_at()
	_check(board._col_mark_live.is_empty() and not board._drop_hover.visible, "原列松手清场")
	_setup(page, 4)
	_check(board._col_mark_live.is_empty() and board._drag.is_empty(), "重建清场")
	UserState.set_debug_ab_override("green_frame_guide", 0)
	_setup(page, 4)
	_check( not board._has_col_mark_guide(), "页面复用不恢复延长引导")

	board.set_col_marks(1, 0, [2])
	var tutorial_mark: JuiceColMark = _mark_for(board, 1)
	var error_mark: JuiceColMark = _mark_for(board, 2)
	_check(tutorial_mark != null and tutorial_mark._mark.visible
		and tutorial_mark._mark.texture == tutorial_mark.mark_tick, "脚本教学仍显示对勾")
	_check(error_mark != null and error_mark._mark.visible
		and error_mark._mark.texture == error_mark.mark_cross, "脚本教学仍显示叉号")
	board.clear_col_marks()
	_setup(page, 3)
	_grab(board, 0, 0)
	_test_selected_col_marks(board)
	board.cancel_active_drag()
	_test_guide_layout(board)

	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task >= 0:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)

	board._cancel_closed_check()
	board.free()
	page.free()
	await get_tree().process_frame


func _mark_for(board: JuiceBoardView, col: int) -> JuiceColMark:
	for mark: JuiceColMark in board._col_mark_live:
		if int(mark.get_meta(&"col")) == col:
			return mark
	return null


func _test_selected_col_marks(board: JuiceBoardView) -> void :
	var target: JuiceColMark = _mark_for(board, 1)
	_check(target != null and _mark_for(board, 0) == null, "原列复用普通选中框，不重复创建列标记")
	if target == null:
		return
	_check_drop_highlight(board, 0)
	_check(target._glow.texture == target.glow_green and target._fill.texture == target.fill_green, 
		"未悬停合法目标保持绿框绿底")
	_check(target._mark.visible, "前3关绿框始终显示对勾")
	_hover(board, 1)
	_check(target._glow.texture == target.glow_yellow and target._fill.texture == target.fill_yellow
		and target._mark.visible
		and target._mark.texture == target.mark_tick, "悬停黄框沿用本关对勾显隐")
	_check( not board._drop_hover.visible, "悬停绿框时只显示黄框，不叠蓝框")

	var original_size: Vector2 = target.size
	for test_size: Vector2 in [Vector2(115.0, 500.0), Vector2(300.0, 700.0)]:
		target.size = test_size
		var scale: float = minf(1.0, test_size.x / 230.0)
		_check(is_equal_approx(target._fill.offset_left, 9.0 * scale)
			and is_equal_approx(target._fill.offset_bottom, -9.0 * scale), "黄底内缩适配胶囊尺寸")
	target.size = original_size
	for col: int in [0, 2, -1]:
		if col >= 0:
			_hover(board, col)
		else:
			_clear_hover(board)
		_check(target._glow.texture == target.glow_green and target._fill.texture == target.fill_green
			and is_zero_approx(target._fill.offset_left), "移回原列/非法列/空白恢复绿框")
		_check(target._mark.visible, "离开目标后对勾显隐不变")
		if col == 0 or (col == 2 and board.level().id <= 3):
			_check_drop_highlight(board, col)
		else:
			_check( not board._drop_hover.visible, "第4关起非法目标及空白隐藏蓝框")
	_hover(board, 1)

	_clear_hover(board)
	board._rebuild_col_marks()
	var rebuilt: JuiceColMark = _mark_for(board, 1)
	_check(rebuilt != null and rebuilt._glow.texture == rebuilt.glow_green, "池复用恢复绿色")
	_check(rebuilt != null and rebuilt._mark.visible, "池复用恢复本关对勾显隐")

	for col: int in [0, 3, 1, 0]:
		board._drag["pos"] = board._col_capsule_rect(col).get_center() + board._drag["grab"]
		board._update_hover()
		_check(board._hover_col == col, "真实拖拽命中列%d" % col)
		if col == 1:
			_check( not board._drop_hover.visible and rebuilt._glow.texture == rebuilt.glow_yellow, 
				"真实拖拽进入绿框变黄框")
		else:
			if col == 3 and board.level().id >= 4:
				_check( not board._drop_hover.visible, "真实拖拽进入非法目标隐藏预览")
			else:
				_check_drop_highlight(board, col)
			_check(rebuilt._glow.texture == rebuilt.glow_green, "离开合法目标恢复绿色")


func _check_drop_highlight(board: JuiceBoardView, col: int) -> void :
	var rect: Rect2 = board._col_capsule_rect(col)
	_check(board._drop_hover.visible and board._drop_hover.position.is_equal_approx(rect.position)
		and board._drop_hover.size.is_equal_approx(rect.size), "蓝框跟随命中列%d的位置与尺寸" % col)
	_check(board._drop_hover_fill.texture == board._normal_drop_hover_fill_texture
		and board._drop_hover_glow.texture == board._normal_drop_hover_glow_texture
		and board._drop_hover_glow.self_modulate == board._normal_drop_hover_tint, "蓝框复用普通选中底色/边框/乘色")


func _test_drop_style_equivalence(page: JuiceGamePage) -> void :
	var board: JuiceBoardView = page._board
	var original_tint: Color = board._normal_drop_hover_tint
	for new_background: bool in [false, true]:
		UserState.set_debug_ab_override("green_frame_guide", 0)
		_setup(page, 4)
		board.set_background_highlights(new_background)
		board.set_drop_hover_tint(Color(0.8, 0.9, 1.0, 0.6))
		_grab(board, 0, 0)
		_hover(board, 0)
		var fill: Texture2D = board._drop_hover_fill.texture
		var glow: Texture2D = board._drop_hover_glow.texture
		var fill_tint: Color = board._drop_hover_fill.self_modulate
		var glow_tint: Color = board._drop_hover_glow.self_modulate
		var rect: Rect2 = board._drop_hover.get_rect()
		board.cancel_active_drag()
		_setup(page, 3)
		_grab(board, 0, 0)
		_hover(board, 0)
		_check(board._drop_hover_fill.texture == fill and board._drop_hover_glow.texture == glow
			and board._drop_hover_fill.self_modulate == fill_tint and board._drop_hover_glow.self_modulate == glow_tint
			and board._drop_hover.size.is_equal_approx(rect.size), "新旧背景原列蓝框不受绿框资格影响")
		board.cancel_active_drag()
	board.set_background_highlights(false)
	board.set_drop_hover_tint(original_tint)



func _test_invalid_previews(page: JuiceGamePage) -> void :
	var board: JuiceBoardView = page._board
	for green_group: int in range(3):
		for level_id: int in [3, 4, 20]:
			for new_background: bool in [false, true]:
				UserState.reset_all()
				UserState.set_debug_ab_override("green_frame_guide", green_group)
				_setup(page, level_id, level_id == 20)
				board.set_background_highlights(new_background)
				_grab(board, 0, 0)
				_check_drop_highlight(board, 0)
				var events: Array = (ABManager.get("events") as Array).duplicate()
				var guide: bool = board._has_col_mark_guide()
				_hover(board, 1)
				var mark: JuiceColMark = _mark_for(board, 1)
				if guide:
					_check(mark != null and mark._glow.texture == mark.glow_yellow
						and not board._drop_hover.visible, "合法目标仍显示黄框，不叠普通预览")
					_check(mark != null and mark._mark.visible == (level_id <= 3), "主线及特殊挑战遵守对勾关号边界")
				else:
					_check_drop_highlight(board, 1)
				for target: int in [2, 2, 3]:
					_hover(board, target)
					_check(board._drop_hover.visible == (level_id <= 3), "首次、持续悬停及切换非法列遵守关号边界")
					if level_id <= 3:
						_check_drop_highlight(board, target)
				if guide:
					_check(mark._glow.texture == mark.glow_green, "进入非法列后合法标记恢复绿色")
				_hover(board, 1)
				if guide:
					_check(mark._glow.texture == mark.glow_yellow and not board._drop_hover.visible, 
						"从隐藏预览进入合法目标仍显示黄框")
				else:
					_check_drop_highlight(board, 1)
				_hover(board, 0)
				_check_drop_highlight(board, 0)
				_clear_hover(board)
				_check( not board._drop_hover.visible, "空白不显示预览")
				_hover(board, 2)
				_check(board._drop_hover.visible == (level_id <= 3), "离开后重新进入非法列仍遵守边界")
				_check(ABManager.get("events") == events, "所有悬停切换不访问SDK或染色")
				board.cancel_active_drag()
				_check( not board._drop_hover.visible and board._col_mark_live.is_empty(), "取消清场")

				_setup(page, level_id, level_id == 20)
				ABManager.set("events", [])
				_grab(board, 2, 0)
				_hover(board, 0)
				_check( not (ABManager.get("events") as Array).has("dye"), "无合法目标不染色绿框实验")
				_check(board._drop_hover.visible == (level_id <= 3), "无合法目标也遵守永久隐藏规则")
				board.cancel_active_drag()
	board.set_background_highlights(false)


func _test_invalid_preview_reasons(page: JuiceGamePage) -> void :
	var board: JuiceBoardView = page._board
	UserState.set_debug_ab_override("green_frame_guide", 0)
	for reason: JuiceRules.Reject in [JuiceRules.Reject.COLOR, JuiceRules.Reject.FULL, 
			JuiceRules.Reject.LOCKED, JuiceRules.Reject.MYSTERY]:
		_setup(page, 4)
		var target: int = 3 if reason == JuiceRules.Reject.FULL else 2
		if reason == JuiceRules.Reject.LOCKED:
			board._state_ref()["locks"][target] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 99}
		elif reason == JuiceRules.Reject.MYSTERY:
			board._state_ref()["cols"][0][0] = JuiceLevel.HIDDEN_BASE
		_check(JuiceRules.reject_reason(board._state_ref(), 0, 0, target) == reason, "夹具覆盖四种非法原因")
		_grab(board, 0, 0)
		_hover(board, target)
		_check( not board._drop_hover.visible, "颜色、容量、锁列与问号非法目标统一隐藏预览")
		board.cancel_active_drag()

	_setup(page, 4)
	board._last_rejected_target = 3
	board.show_capacity_error_hint(1.0)
	_check(board._drop_hover.visible
		and board._drop_hover_fill.texture == board.invalid_drop_hover_fill_texture
		and board._drop_hover_glow.texture == board.invalid_drop_hover_glow_texture, 
		"松手后的容量错误红框保持独立")
	board.clear_capacity_error_hint()
	_grab(board, 0, 0)
	_check_drop_highlight(board, 0)
	board.cancel_active_drag()


func _clear_hover(board: JuiceBoardView) -> void :
	board._hover_col = -1
	board._place_drop_hover()


func _test_guide_layout(board: JuiceBoardView) -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 3, "capacity": 2, "targetCups": 6, 
		"initial": ["-|0", "0|0", "1|1,1", "2|2,2", "3|3,3", "4|4,4", "5|5,5"], 
		"incoming": ["x", "x", "x", "x", "x"]})
	_check(level.validate().is_empty(), "七列布局夹具自洽")
	board.setup(level)
	for index: int in range(board._order.size() - 1):
		var left: Rect2 = board._col_capsule_rect(board._order[index])
		var right: Rect2 = board._col_capsule_rect(board._order[index + 1])
		var gap: float = right.position.x - left.end.x
		var base_gap: float = board._lay.col_w - board._track_rect_centered(index).size.x
		_check(gap >= minf(board.CAPSULE_GAP, base_gap) - 0.01, 
			"七列绿框间距 gap=%.3f width=%.3f col_w=%.3f widen=%.3f" % [gap, left.size.x, board._lay.col_w, board._capsule_widen()])
	board.set_capacity_knots_enabled(true)
	for level_id: int in [3, 4, 3]:
		level.id = level_id
		board.setup(level)
		var base: float = board._lay.rope_bottom + board._lay.fruit_d * JuiceLayout.TRACK_BOTTOM_FRUIT_RATIO
		_check(is_equal_approx(board._capacity_label_top() - base, 
			JuiceRopeCapacityLabel.MASK_GAP + (JuiceColMark.MARK_SIZE if level_id <= 3 else 0.0)), "容量文字只在前3关预留标记高度")
	board.set_capacity_knots_enabled(false)


func _setup(page: JuiceGamePage, level_id: int, special: bool = false) -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": level_id, "capacity": 2, "targetCups": 4, 
		"initial": ["0|0", "-|0", "1|1", "2|2,2"], "incoming": ["2|1,2", "-|2", "x"]})
	_check(level.validate().is_empty(), "夹具题面自洽: %s" % str(level.validate()))
	var model: = JuiceLevelModel.new()
	model.level_id = level_id
	model.juice = level
	model.round_kind = "special_challenge" if special else "level"
	page._level_model = model
	page._board.setup(level)


func _grab(board: JuiceBoardView, src: int, j: int) -> void :
	var fruit: JuiceFruit = board._fruit_nodes[src][j]
	board._begin_drag(board.get_global_transform().affine_inverse() * fruit.global_position)


func _hover(board: JuiceBoardView, target: int) -> void :
	board._drag["pos"] = Vector2(board._col_x(target), board._lay.plank_top + 10.0) + board._drag["grab"]

	board._hover_col = target
	board._place_drop_hover()


func _test_startup_timeout() -> void :
	UserState.clear_debug_ab_override("green_frame_guide")
	ABManager._is_init_done = false
	ABManager.set("sdk_value", "tier_5")
	_check( not await ABManager.await_ready(0.0), "SDK超时锁定fallback")
	await _test_page_and_board()
	_check(ABManager.get("events") == [], "SDK超时及晚到退役值均不读取或染色延长实验")
