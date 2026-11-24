extends SceneTree































const BOARD_SCENE: = "res://scripts/gameplay/juice_sort/view/juice_board_view.tscn"
const RULES: = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const FRUIT_VISIBLE_WIDTH_RATIO: = 0.68
const DROP_SLACK: = 60.0
const DROP_OVERLAP_FRUIT_RATIO: = 0.5
const DROP_TARGET_RANGE_SCALE: = 1.0

const SRC_COL: = 0
const SRC_J: = 1

var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	await _test_tutorial_hand_after_cancel()

	var board_scene: PackedScene = load(BOARD_SCENE) as PackedScene
	var level: JuiceLevel = _build_level()
	var level_errors: Array[String] = level.validate()
	_check(level_errors.is_empty(), "夹具题面必须自洽: %s" % str(level_errors))

	var board: Variant = board_scene.instantiate()
	board.size = Vector2(1080, 2340)
	root.add_child(board)
	board.setup(level)
	board.set_tutorial_pot_highlight(0, true)
	_check(board.get("_tutorial_pot_hl_col") == 0, "教学目标花盆可高亮")
	board.set_tutorial_pot_highlight(1, true)
	_check(board.get("_tutorial_pot_hl_col") == 1, "切换教学目标花盆")
	_check( not board.get("_blender_nodes")[0].get("_hint_active") and board.get("_blender_nodes")[1].get("_hint_active"), "旧花盆关闭、新花盆点亮")
	board.set_tutorial_pot_highlight(0, false)
	_check(board.get("_tutorial_pot_hl_col") == -1, "关闭清理实际高亮目标")
	board.set_tutorial_pot_highlight(999, true)
	_check(board.get("_tutorial_pot_hl_col") == -1, "非法目标不残留高亮")
	var cfg_script = load("res://scripts/data/abtest/ab_configs/location_judge/location_judge_config.gd")
	_check(cfg_script.parse_settings("1.1_0.9") == {"legal": 1.1, "invalid": 0.9}, "动态倍率保持实际值")
	for raw in ["old", "new", "", "1_0", "-1_1", "1_2_3", "NaN_1", "1_inf"]:
		_check(cfg_script.parse_settings(raw).is_empty(), "非法配置回落old: " + raw)
	_check(board.get("_location_judge_settings").is_empty(), "默认old")
	var page = load("res://scripts/main/pages/game/juice_game_page.gd").new()
	page.set("_board", board)
	var ab = root.get_node("ABManager")
	_check(ab.find_config("location_judge") != null, "配置已注册")
	for raw in ["old", "1.1_0.9", "1.2_0.8", "bad"]:
		ab.set("sdk_value", raw)
		ab.get("events").clear()
		page._on_location_judge_pickup()
		_check(ab.get("events") == ["get", "dye"], "起抓先get后dye: " + raw)
		_check(board.get("_location_judge_settings") == cfg_script.parse_settings(raw), "注入实际倍率: " + raw)
	board.tutorial_demo_only = true
	ab.get("events").clear()
	page._on_location_judge_pickup()
	_check(ab.get("events").is_empty(), "教学演示不染色")
	board.tutorial_demo_only = false
	page.set("_board", null)
	page.free()
	board.set_drop_settings({"legal": 1.2, "invalid": 0.8})

	var lay: Variant = board.get("_lay")
	var order: Array = board.get("_order") as Array
	var col_w: float = float(lay.col_w)
	var half_w: float = (col_w * 0.5
		+ float(lay.fruit_d) * FRUIT_VISIBLE_WIDTH_RATIO * 0.5) * DROP_TARGET_RANGE_SCALE
	_check(order.size() == 5, "夹具盘面应有 5 列在场,实际 %d" % order.size())


	_check(col_w > half_w, 
		"前置:列宽 %.1f 必须 > 重叠区半宽 %.1f(重叠区不该盖到隔壁列)" % [col_w, half_w])
	var pos_y: float = (float(lay.rope_visible_top) + float(lay.rope_bottom)) * 0.5
	_check(pos_y > float(lay.plank_top) and pos_y < float(lay.rope_bottom) + float(lay.gap), 
		"前置:用例的 y=%.1f 必须落在「可落点」的竖向范围内" % pos_y)



	_check(_hit(board, _pos(board, 1, 0.0, pos_y)) == 1, "正对同色列 c1 ⇒ c1")


	var mid12: float = (float(board._col_x(1)) + float(board._col_x(2))) * 0.5
	_check(_hit(board, Vector2(mid12 - 2.0, pos_y)) == 1, "同色列更近 ⇒ 同色列")
	_check(_hit(board, Vector2(mid12 + 2.0, pos_y)) == 2, "空列更近 ⇒ 空列")



	var invalid_half_w: float = (col_w * 0.5 + float(lay.fruit_d) * FRUIT_VISIBLE_WIDTH_RATIO * 0.5) * 0.8
	var lo1: float = col_w - invalid_half_w
	var hi1: float = col_w * 0.5
	_check(hi1 > lo1, "前置:相邻不合法列用例的窗口必须非空(lo=%.1f hi=%.1f)" % [lo1, hi1])
	var near_c4: float = (lo1 + hi1) * 0.5
	_check(_hit(board, _pos(board, 4, - near_c4, pos_y)) == 4, 
		"两列都不可放置时取更近的 c4(距 c4 %.1f)" % near_c4)


	var at_src: Vector2 = _pos(board, 0, 0.0, pos_y)
	_check(_hit(board, at_src) == 0, "落在源列上 ⇒ 返回源列(原地放下 = 静默取消)")


	var near_src: Vector2 = _pos(board, SRC_COL, col_w * 0.1, pos_y)
	_check(_hit(board, near_src) == SRC_COL, "中心偏移未超过20%列间距 ⇒ 保留自身列")
	var boundary: float = float(board._col_x(SRC_COL)) + col_w * 0.2
	_check(_hit(board, Vector2(boundary - 2.0, pos_y)) == SRC_COL, "同色相邻：中心偏移小于20%列间距 ⇒ 自身列")
	_check(_hit(board, Vector2(boundary + 2.0, pos_y)) == 1, "同色相邻：中心偏移超过20%列间距 ⇒ 同色列")
	_check(_hit(board, Vector2(boundary, pos_y)) == SRC_COL, "同色相邻：中心偏移等于20%列间距 ⇒ 自身列")
	var outside_same: Vector2 = _pos(board, 1, - (half_w + 2.0), pos_y)
	_check(_hit(board, outside_same) == 0, "同色列无重叠 ⇒ 自身列取消")

	var st: Dictionary = board.state()
	var saved: Array = (st["cols"][1] as Array).duplicate()
	st["cols"][1] = [] as Array[int]
	_check(_hit(board, near_src) == SRC_COL, "中心偏移未超过20% ⇒ 自身列")
	var mid01: float = (float(board._col_x(0)) + float(board._col_x(1))) * 0.5
	_check(_hit(board, Vector2(mid01 + 2.0, pos_y)) == 1, "中心已越过20%列间距 ⇒ 空列")
	_check(_hit(board, Vector2(mid01 - 2.0, pos_y)) == 1, "中心已越过20%列间距 ⇒ 空列")
	_check(_hit(board, Vector2(mid01, pos_y)) == 1, "中心位于中线 ⇒ 空列")
	_check(_hit(board, Vector2(boundary + 2.0, pos_y)) == 1, "空列相邻：中心偏移超过20%列间距 ⇒ 空列")
	_check(_hit(board, Vector2(boundary, pos_y)) == SRC_COL, "空列相邻：中心偏移等于20%列间距 ⇒ 自身列")
	_sweep(board, order, col_w, pos_y)
	st["cols"][1] = saved


	_sweep(board, order, col_w, pos_y)


	var edge_saved: Array = (board.state()["cols"][4] as Array).duplicate()
	board.state()["cols"][4] = [0] as Array[int]
	_check(_hit(board, Vector2(board.size.x, pos_y)) == 4, "右侧页面边缘 ⇒ 合法最右列")
	_check(_hit(board, Vector2(board.size.x + float(lay.fruit_d) * 0.9, float(lay.rope_bottom) + float(lay.gap) + float(lay.fruit_d) * 0.2)) == 4, "花部分越出右侧并低于绳尾 ⇒ 合法最右列")
	_check(_hit(board, Vector2(board.size.x, float(lay.plank_top) - 100.0)) != 4, "上方UI区域不吸附边缘列")
	board.state()["cols"][4] = edge_saved
	board.state()["cols"][0] = [0] as Array[int]
	_check(board._hit_column(Vector2(0.0, pos_y), 1, 0) == 0, "左侧页面边缘 ⇒ 合法最左列")
	_check(board._hit_column(Vector2( - float(lay.fruit_d) * 0.9, float(lay.rope_bottom) + float(lay.gap) + float(lay.fruit_d) * 0.2), 1, 0) == 0, "花部分越出左侧并低于绳尾 ⇒ 合法最左列")
	board.setup(_build_level())
	_test_moving_columns(board)

	board._cancel_closed_check()
	board.queue_free()
	if _failures.is_empty():
		print("PASS")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: ", f)
		quit(1)



func _test_moving_columns(board: Variant) -> void :
	board.setup(_build_level())
	board.set_process(false)
	var lay: Variant = board.get("_lay")
	var order: Array = board.get("_order") as Array
	var from: Dictionary = {}
	var visual_x: Dictionary = board.get("_visual_x") as Dictionary
	var tokens: Dictionary = board.get("_visual_token_by_col") as Dictionary
	for ci: int in order:
		from[ci] = float(board._base_x(ci)) + float(lay.col_w) * 2.0
		visual_x[int(tokens[ci])] = from[ci]
	board._snap_all_home()

	for ci: int in order:
		visual_x[int(tokens[ci])] = from[ci]
		var flowers: Array = (board.get("_fruit_nodes") as Dictionary)[ci]
		for flower: JuiceFruit in flowers:
			flower.position.x = float(from[ci])
	board._sync_last_col_x()
	board._begin_drag(board._home_pos(SRC_COL, 2))
	_check( not (board.get("_drag") as Dictionary).is_empty(), "列移动中能抓起真实花朵")
	board.set_col_marks(1, SRC_COL, [3])
	var marks: Array = (board.get("_col_mark_live") as Array).duplicate()

	var marked_cols: Array[int] = [1, 3]
	var drag: Dictionary = board.get("_drag") as Dictionary
	var fixed_pos: = Vector2(float(board._base_x(2)), float(lay.first_fruit_y))
	drag["pos"] = fixed_pos + (drag["grab"] as Vector2)
	board._update_hover()
	var initial_hover: int = int(board.get("_hover_col"))
	board._enqueue_shift(from, float(from[SRC_COL]), float(board.get("_t")))
	var shift: Dictionary = (board.get("_shift_queue") as Array)[0]
	shift["dur"] = 1.0
	for token: Variant in (shift["delay"] as Dictionary):
		(shift["delay"] as Dictionary)[token] = 0.0
	var changed: bool = false
	for frame: int in 3:
		board._process(0.2)
		var expected: int = int(board._hit_column(fixed_pos, SRC_COL, 2))
		var hover: int = int(board.get("_hover_col"))
		changed = changed or expected != initial_hover
		_check(hover == expected, "手指不动第%d帧:预览%d必须跟随实时目标%d" % [frame, hover, expected])
		var highlight: Control = board.get_node("DropHoverHighlight") as Control
		_check(highlight.visible, "移动中落点高亮可见")
		_check(is_equal_approx(highlight.position.x + highlight.size.x * 0.5, 
			float(board._col_x(expected))), "移动中落点胶囊中心跟随判定列")
		for i: int in marks.size():
			var mark: Control = marks[i] as Control
			_check(mark == (board.get("_col_mark_live") as Array)[i], "逐帧跟随不重建池化标记")
			_check(is_equal_approx(mark.position.x + mark.size.x * 0.5, 
				float(board._col_x(marked_cols[i]))), "合法/错误框跟随对应绳子")
	_check(changed, "夹具必须让固定位置的目标在列移中发生切换")
	var target: int = int(board._hit_column(fixed_pos, SRC_COL, 2))
	_check(target != SRC_COL and RULES.move_info(board.state(), SRC_COL, 2, target) > 0, 
		"松手夹具的实时目标必须合法")
	var events: Array[int] = []
	var on_move: Callable = func(_steps: int) -> void :
		var history: Array = board.get("_history") as Array
		events.append(int((history[-1] as Dictionary)["rec"]["dst"]))
	board.moved.connect(on_move)
	board._drop_at()
	board.moved.disconnect(on_move)
	_check(events == [target], "松手实际落点必须与最后一次实时预览一致")
	_check( not (board.get_node("DropHoverHighlight") as Control).visible, "松手清除落点高亮")
	board.clear_col_marks()




func _sweep(board: Variant, order: Array, col_w: float, pos_y: float) -> void :
	var lay: Variant = board.get("_lay")
	var first_x: float = float(board._col_x(int(order[0])))
	var last_x: float = float(board._col_x(int(order[order.size() - 1])))
	var ys: Array[float] = [
		pos_y, 
		float(lay.plank_top) - 40.0, 
		float(lay.rope_bottom) + float(lay.gap) + 40.0, 
	]
	var bad: int = 0
	var bad_first: String = ""
	var points: int = 0
	for y: float in ys:
		var x: float = first_x - col_w * 1.5
		while x <= last_x + col_w * 1.5:
			var pos: = Vector2(x, y)
			points += 1
			var got: int = _hit(board, pos)
			var spec: int = _oracle(board, pos)
			if got != spec:
				bad += 1
				if bad_first.is_empty():
					bad_first = "pos=(%.1f, %.1f) 盘面=%d 规格=%d" % [x, y, got, spec]
			x += 2.0
	_check(bad == 0, 
		"扫描 %d 点:盘面判定必须与规格逐点一致 —— %d 点不符,首例 %s"
			%[points, bad, bad_first])





func _oracle(board: Variant, pos: Vector2) -> int:
	var lay: Variant = board.get("_lay")
	var state: Dictionary = board.state()
	var limit: float = (float(lay.col_w) * 0.5 + float(lay.fruit_d) * FRUIT_VISIBLE_WIDTH_RATIO * DROP_OVERLAP_FRUIT_RATIO) * DROP_TARGET_RANGE_SCALE

	var flower_half: float = float(lay.fruit_d) * 0.65
	var screen_margin: float = float(lay.fruit_d)
	if pos.x >= - screen_margin and pos.x <= float(board.size.x) + screen_margin and pos.y > float(lay.plank_top) and pos.y < float(lay.rope_bottom) + float(lay.gap) + flower_half:
		var sorted_cols: Array = (board.get("_order") as Array).duplicate()
		sorted_cols.sort_custom( func(a: int, b: int) -> bool: return float(board._col_x(a)) < float(board._col_x(b)))
		var first: int = int(sorted_cols[0])
		var last: int = int(sorted_cols[-1])
		if pos.x <= float(board._col_x(first)) - float(lay.col_w) * 0.5 and RULES.move_info(state, SRC_COL, SRC_J, first) > 0:
			return first
		if pos.x >= float(board._col_x(last)) + float(lay.col_w) * 0.5 and RULES.move_info(state, SRC_COL, SRC_J, last) > 0:
			return last

	if pos.y > float(lay.plank_top) and pos.y < float(lay.rope_bottom) + float(lay.gap):
		var src_x: float = float(board._col_x(SRC_COL))
		if absf(pos.x - src_x) <= limit:
			for ci: int in (board.get("_order") as Array):
				if absi(ci - SRC_COL) == 1 and RULES.move_info(state, SRC_COL, SRC_J, ci) > 0:
					var delta: float = float(board._col_x(ci)) - src_x
					return ci if (pos.x - src_x) * delta > 0.0 and absf(pos.x - src_x) > absf(delta) * 0.2 else SRC_COL
	var candidates: Array = []
	if pos.y > float(lay.plank_top) and pos.y < float(lay.rope_bottom) + float(lay.gap):
		for ci: int in (board.get("_order") as Array):
			var distance: float = absf(pos.x - float(board._col_x(ci)))
			var legal: bool = RULES.move_info(state, SRC_COL, SRC_J, ci) > 0
			var candidate_limit: float = limit * (1.0 if ci == SRC_COL else (1.2 if legal else 0.8))
			if distance > candidate_limit:
				continue
			var rank: int = 3
			if ci == SRC_COL:
				rank = 1
			elif RULES.move_info(state, SRC_COL, SRC_J, ci) > 0:
				rank = 0
			candidates.append([rank, distance, ci])
	if candidates.is_empty():
		return _oracle_fallback(board, pos)
	candidates.sort_custom( func(a: Array, b: Array) -> bool:
		if int(a[0]) != int(b[0]):
			return int(a[0]) < int(b[0])
		if is_equal_approx(float(a[1]), float(b[1])):
			return int(a[2]) == SRC_COL and int(b[2]) != SRC_COL
		return float(a[1]) < float(b[1]))
	return int(candidates[0][2])



func _oracle_fallback(board: Variant, pos: Vector2) -> int:
	var lay: Variant = board.get("_lay")
	var best: int = -1
	var best_d: float = INF
	for ci: int in (board.get("_order") as Array):
		var dx: float = absf(pos.x - float(board._col_x(ci)))
		var legal: bool = RULES.move_info(board.state(), SRC_COL, SRC_J, ci) > 0
		var scale: float = 1.0 if ci == SRC_COL else (1.2 if legal else 0.8)
		var limit: float = (float(lay.col_w) * 0.5 + float(lay.fruit_d) * FRUIT_VISIBLE_WIDTH_RATIO * 0.5) * scale
		if dx > limit:
			continue
		var edge: float = maxf(0.0, dx - float(lay.col_w) * 0.5)
		var dy: float = 0.0
		if pos.y < float(lay.hang_top):
			dy = float(lay.hang_top) - pos.y
		elif pos.y > float(lay.rope_bottom) + float(lay.gap):
			dy = pos.y - (float(lay.rope_bottom) + float(lay.gap))
		var d: float = sqrt(edge * edge + dy * dy)
		if d < best_d:
			best_d = d
			best = ci
	return best if best_d <= DROP_SLACK else -1






func _build_level() -> JuiceLevel:
	return JuiceLevel.from_dict({
		"id": 98201, "capacity": 3, "targetCups": 5, 
		"initial": ["0|1,0,0", "1|0", "0|", "1|1", "1|1"], 
		"incoming": ["-|1,1,1", "-|1,1,1", "-|0,0,0", "x"], 
	})



func _pos(board: Variant, ci: int, dx: float, y: float) -> Vector2:
	return Vector2(float(board._col_x(ci)) + dx, y)



func _hit(board: Variant, pos: Vector2) -> int:
	return int(board._hit_column(pos, SRC_COL, SRC_J))


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)



func _test_tutorial_hand_after_cancel() -> void :
	var board = load(BOARD_SCENE).instantiate()
	root.add_child(board)
	board.size = Vector2(1080, 2340)
	var model = load("res://scripts/gameplay/juice_sort/tutorial/juice_tutorial_script.gd").build_model()
	board.setup(model.juice)
	var layer = load("res://scripts/gameplay/juice_sort/tutorial/juice_tutorial_layer.tscn").instantiate()
	root.add_child(layer)
	var director = load("res://scripts/gameplay/juice_sort/tutorial/juice_tutorial_director.gd").new()
	director.setup(board, layer)
	root.add_child(director)
	director.start()
	await create_timer(3.0).timeout
	_check(layer.is_demo_playing(), "教学手指初始出现")
	for settings in [{}, {"legal": 1.2, "invalid": 0.8}]:
		board.set_drop_settings(settings)
		for error_new in [false, true]:
			board.set_new_error_animation_enabled(error_new)
			board._begin_drag(board.get_global_transform().affine_inverse() * board.fruit_global_pos(1, 1))
			_check( not board.get("_drag").is_empty(), "教学指定花串成功拿起")
			_check( not layer.is_demo_playing(), "真实拖动时隐藏演示手指")
			board._drop_at()

			board._flush_return()
			await process_frame
			await process_frame
			_check(layer.is_demo_playing(), "原地松手后重播手指: %s/%s" % [settings, error_new])
			_check(director.get("_step") == 0, "原地松手不推进教学步骤")
	director.stop()
	director.free()
	layer.free()
	board.free()
