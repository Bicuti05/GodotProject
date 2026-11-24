extends Node


var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _check(ok: bool, label: String) -> void :
	_checks += 1
	if not ok:
		_failures.append(label)
		push_error("SAME_COLOR_HIGHLIGHT: " + label)


func _run() -> void :
	UserState.reset_all()
	_test_config()
	await _test_board()
	if _failures.is_empty():
		print("SAME_COLOR_HIGHLIGHT_SELFTEST PASS checks=", _checks)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _test_config() -> void :
	var cfg: SameColorHighlightConfig = ABManager.find_config("same_color_highlight") as SameColorHighlightConfig
	_check(cfg != null and cfg.version == "1.0.9" and cfg.group_count == 2, "注册与版本")
	for raw: String in ["no", "yes", "", "unknown", "1", "YES", " yes "]:
		ABManager.set("sdk_value", raw)
		ABManager.set("events", [])
		ABManager.dye_at_same_color_highlight()
		_check(ABManager.get("events") == ["get", "dye"], "字符串先get后dye: " + raw)
		_check(cfg.is_same_color_highlight_enabled() == (raw == "yes"), "严格字符串映射: " + raw)
		ABManager.set("events", [])
		cfg.load_value_silent()
		cfg.peek_value()
		_check(ABManager.get("events") == ["get", "get"], "静默和peek不染色")
	_check(int(ABManager.get("int_reads")) == 0, "不用int SDK通道")
	ABManager.set("sdk_value", "yes")
	ABManager.set("events", [])
	var lazy: = SameColorHighlightConfig.new()
	lazy.init_default()
	_check(lazy.is_same_color_highlight_enabled() and ABManager.get("events") == ["get"], "懒加载只取字符串")
	ABManager._is_init_done = false
	ABManager.set("events", [])
	var waiting: = SameColorHighlightConfig.new()
	waiting.init_default()
	ABManager.dye_at_same_color_highlight()
	_check( not waiting.is_same_color_highlight_enabled() and ABManager.get("events") == [], "未就绪回落no且不染色")
	ABManager._is_init_done = true
	_check(waiting.is_same_color_highlight_enabled(), "就绪后可重试未缓存默认值")
	ABManager._startup_control_locked = true
	ABManager.set("events", [])
	ABManager.dye_at_same_color_highlight()
	var locked: = SameColorHighlightConfig.new()
	locked.init_default()
	_check( not locked.is_same_color_highlight_enabled() and not (ABManager.get("events") as Array).has("dye"), "启动超时锁定no且不染色")
	ABManager._startup_control_locked = false
	cfg.set_debug_override(1)
	_check(cfg.is_same_color_highlight_enabled(), "Cheat yes")
	cfg.set_debug_override(0)
	_check( not cfg.is_same_color_highlight_enabled(), "Cheat no")
	cfg.clear_debug_override()


func _test_board() -> void :
	var board: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	var page: = JuiceGamePage.new()
	page._board = board
	board.tutorial_demo_only = true
	add_child(board)
	board.set_process(false)
	board.set_input_enabled(true)
	board.set_entrance_lock(false)
	board.set_ambient_sway_enabled(false)
	board.drag_started.connect( func(_col: int, _j: int) -> void :
		page._on_same_color_highlight_pickup())
	var level: = JuiceLevel.from_dict({"id": 4, "capacity": 4, "targetCups": 3, 
		"initial": ["-|", "0|0,1,0", "0|1,?0,0", "1|0,1", "0|1,0"], "incoming": []})
	for raw: String in ["no", "yes"]:
		board.tutorial_demo_only = true
		board.setup(level)
		board._cancel_closed_check()
		board._state_ref()["locks"][4] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 99}
		ABManager.set("sdk_value", raw)
		ABManager.set("events", [])
		_grab(board, 1, 2)
		_check(ABManager.get("events") == [] and board._drag_match_highlight_fruits.is_empty(), "演示不染色或呼吸")
		board.cancel_active_drag()
		board.tutorial_demo_only = false
		_grab(board, 1, 2)
		_check(ABManager.get("events") == ["get", "dye"], "两组真实拿起统一染色")
		var target: JuiceFruit = board._fruit_nodes[2][2]
		_check(target.is_breathing_group_highlight_active() == (raw == "yes"), "实验组立即提示同色明牌")
		_check( not (board._fruit_nodes[2][1] as JuiceFruit).is_breathing_group_highlight_active(), "问号真色不提示")
		_check( not (board._fruit_nodes[3][1] as JuiceFruit).is_breathing_group_highlight_active(), "异色不提示")
		_check( not (board._fruit_nodes[4][1] as JuiceFruit).is_breathing_group_highlight_active(), "锁列不提示")
		_check( not (board._fruit_nodes[1][2] as JuiceFruit).is_breathing_group_highlight_active(), "拖动段不提示")
		if raw == "yes":
			await get_tree().create_timer(0.15).timeout
			var previous: float = target._group_highlight_scale
			_check(previous > 1.0, "呼吸有放大")
			_check(target._group_highlight_halo_texture != null, "注入烘焙柔光贴图")
			_check(target._group_highlight_halo.visible
				and float(target._group_highlight_halo_material.get_shader_parameter(
					"halo_strength")) > 0.0, "呼吸期间柔光可见且强度随进度")
			var halo_ratio: float = target._group_highlight_halo_canvas_ratio
			_check(halo_ratio > 1.0 and target._group_highlight_halo.scale.x
				<= target._body.scale.x * halo_ratio + 0.001, "柔光按烘焙画布比例缩放")
			_check(target._group_highlight_landing_particles._particles.size() == 4, "4颗CPU星点")
			board._finish_drag_for_drop()
			_check(target._breathing_group_highlight_releasing and is_equal_approx(target._group_highlight_scale, previous), "松手连续衔接保留收尾")
			await get_tree().create_timer(0.25).timeout
			_check( not target.is_breathing_group_highlight_active() and is_equal_approx(target._group_highlight_scale, 1.0), "松手0.2秒归位")
			_check( not target._group_highlight_halo.visible, "收尾后柔光隐藏")
			_grab(board, 1, 2)

			_check(target.is_breathing_group_highlight_active()\
			and not target._breathing_group_highlight_releasing, "收尾结束后重抓立即开始新一轮")
			board.cancel_active_drag()
			await get_tree().create_timer(0.25).timeout
			_check( not target.is_breathing_group_highlight_active(), "取消拖动归位")
			_grab(board, 1, 2)

			target.stop_breathing_group_highlight(true)
			_check( not target.is_breathing_group_highlight_active(), "手动停止呼吸")
			board._advance_drag_match_highlight()
			_check(target.is_breathing_group_highlight_active(), "无需等待轮次边界立即重扫呼吸")

			target._set_breathing_group_highlight_time(0.6, 2.4)
			var held_scale: float = target._group_highlight_scale
			board._finish_drag_for_drop()
			_check(target._breathing_group_highlight_releasing, "快速重抓前处于收尾")
			_grab(board, 1, 2)
			_check(target.is_breathing_group_highlight_active()\
			and not target._breathing_group_highlight_releasing, "快速重抓立即续上呼吸")
			_check(is_equal_approx(target._group_highlight_scale, held_scale)\
			and target._breathing_group_highlight_phase_offset > 0.0, 
				"快速重抓从当前状态衔接相位")
			board.set_same_color_highlight_enabled(false)
			_check(target._breathing_group_highlight_releasing, "关闭实验平滑收尾")
			board.cancel_active_drag()
			await get_tree().create_timer(0.25).timeout
			_grab(board, 1, 2)
			target.set_hint_highlight(true)
			_check( not target.is_breathing_group_highlight_active(), "Hint接管清理")
			target.set_hint_highlight(false)
			board.cancel_active_drag()
		else:
			board.cancel_active_drag()
		board.tutorial_demo_only = true
		board.setup(level)
		board._cancel_closed_check()
		_check(board._drag_match_highlight_fruits.is_empty() and not board._same_color_highlight_enabled, "换关复位开关和引用")

	board.tutorial_demo_only = false
	ABManager.set("events", [])
	board._begin_drag(Vector2(-1000, -1000))
	board.set_grab_gate( func(_src: int, _j: int) -> bool: return false)
	_grab(board, 1, 2)
	_check(ABManager.get("events") == [] and board._drag.is_empty(), "无效起抓不染色")
	board.tutorial_demo_only = true
	board.set_grab_gate(Callable())
	board.setup(level)
	board._cancel_closed_check()
	var fruit: JuiceFruit = board._fruit_nodes[2][2]
	fruit.play_breathing_group_highlight(2.4)
	fruit._landing_group_highlight_tween.kill()

	fruit._set_breathing_group_highlight_time(1.68, 2.4)
	_check(is_equal_approx(fruit._group_highlight_scale, 1.055), "呼吸峰值105.5%")

	fruit._set_breathing_group_highlight_time(0.1, 2.4)
	_check(is_equal_approx(fruit._group_highlight_scale, 
		1.0 + JuiceFruit.BREATHING_GROUP_HIGHLIGHT_SCALE
			* (0.5 - 0.5 * cos(TAU * 0.1 / 2.4))), "回绕后恢复原余弦循环")
	fruit.stop_breathing_group_highlight()
	await get_tree().create_timer(0.1).timeout
	_check(fruit._group_highlight_scale < 1.055 and fruit._group_highlight_scale >= 1.0, "收尾只缩回不再放大")
	fruit.reset_for_pool()
	_check( not fruit.is_breathing_group_highlight_active()
		and fruit._landing_group_highlight_tween == null
		and fruit._group_highlight_halo_texture == null, "回池清旧Tween与柔光引用")
	board.free()
	page.free()


func _grab(board: JuiceBoardView, col: int, j: int) -> void :
	var pos: Vector2 = board._fruit_nodes[col][j].position
	board._begin_drag(pos)
