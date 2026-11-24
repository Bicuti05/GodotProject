extends SceneTree




var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :

	var page_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript
	var solver_script: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_solver.gd") as GDScript
	var board_script: GDScript = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript
	var attribution: Dictionary = solver_script.get_script_constant_map()["DeathAttribution"]
	for key: String in ["hint", "undo", "rope"]:
		_check(page_script._dead_prop_matches_attribution(key, attribution["LAST_MOVE"]) == (key == "undo"), 
			"LAST_MOVE 只推荐 Undo: %s" % key)
		_check(page_script._dead_prop_matches_attribution(key, attribution["EARLIER"]) == (key == "rope"), 
			"EARLIER 只推荐 Rope: %s" % key)
		_check(page_script._dead_prop_matches_attribution(key, attribution["UNKNOWN"]) == (key == "rope"), 
			"UNKNOWN 只推荐 Rope，未确认不能高亮 Undo: %s" % key)
	for entry: Dictionary in [
		{"args": ["1"] as Array[String], "want": attribution["LAST_MOVE"]}, 
		{"args": ["2"] as Array[String], "want": attribution["EARLIER"]}, 
		{"args": ["3"] as Array[String], "want": attribution["UNKNOWN"]}, 

		{"args": [] as Array[String], "want": -1}, 
		{"args": [""] as Array[String], "want": -1}, 
		{"args": ["4"] as Array[String], "want": -1}, 
		{"args": ["abc"] as Array[String], "want": -1}, 
		{"args": ["1", "2"] as Array[String], "want": -1}, 
	]:
		_check(page_script._sort_die_attribution(entry["args"]) == entry["want"], 
			"sort_die 参数映射: %s" % str(entry["args"]))
	for attr_name: String in ["LAST_MOVE", "EARLIER", "UNKNOWN"]:
		var board: Variant = board_script.new()
		board.set("_level", JuiceLevel.new())
		var events: Array[String] = []
		board.dead.connect( func(_reason: String) -> void : events.append("dead"))
		board.dead_attributed.connect( func(got: int, _reason: String, _steps: int) -> void :
			events.append("attributed:%d" % got))
		board.cheat_force_dead("stuck", attribution[attr_name])
		_check(events == ["dead", "attributed:%d" % attribution[attr_name]]
			and board.death_attribution() == attribution[attr_name], 
			"cheat 按 dead → dead_attributed 顺序发送 %s" % attr_name)
		_check(int(board.get("_death_task_id")) == -1, 
			"显式 %s 只模拟归因，不提交真实求解" % attr_name)
		board.free()
	await _test_sort_die_actual_attribution(page_script, attribution)
	var hint_board: Variant = board_script.new()
	var lv: JuiceLevel = JuiceLevel.new()
	lv.capacity = 2
	lv.groups_total = 1
	lv.types = 1
	hint_board.set("_level", lv)
	hint_board.set("_state", {
		"cols": [[0] as Array[int], [0] as Array[int]], 
		"jars": [0, -1] as Array[int], "caps": [2, 2] as Array[int], 
		"gone": [false, false] as Array[bool], "locks": [{}, {}], 
		"done": 0, "cups": [] as Array[int], "late_left": 0, 
		"extra_rope_used": false, 
	})
	var hint_events: Array[String] = []
	hint_board.dead.connect( func(reason: String) -> void : hint_events.append(reason))
	hint_board.dead_attributed.connect( func(_got: int, reason: String, _steps: int) -> void :
		hint_events.append("attributed:" + reason))
	hint_board.mark_hint_unwinnable()
	_check(hint_board.over() == "dead"
		and hint_events == ["hint_unwinnable", "attributed:hint_unwinnable"], 
		"Hint 已证明无解时进入正式死亡态、只发一次死亡信号，并与普通死亡一样做归因")
	_check(bool(hint_board.snapshot().get("hint_dead", false)), "提前死亡标记进入续局快照")
	hint_board.free()
	var restore_level: JuiceLevel = JuiceLevel.from_dict({
		"id": 98001, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|0,1", "1|0,1"], "incoming": [], 
	})
	var board_scene: PackedScene = load(
		"res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var live_board: Variant = board_scene.instantiate()
	root.add_child(live_board)
	live_board.setup(restore_level)
	live_board.mark_hint_unwinnable()
	var persisted: Dictionary = live_board.snapshot()
	var resumed_board: Variant = board_scene.instantiate()
	root.add_child(resumed_board)
	var resumed_reasons: Array[String] = []
	resumed_board.dead.connect( func(reason: String) -> void : resumed_reasons.append(reason))
	_check(resumed_board.restore(restore_level, persisted) and resumed_board.over() == "dead"
		and resumed_reasons == ["hint_unwinnable"], "续局恢复正式死亡态与原死亡原因")
	live_board._cancel_closed_check()
	resumed_board._cancel_closed_check()
	live_board.queue_free()
	resumed_board.queue_free()
	var previous_locale: String = TranslationServer.get_locale()
	TranslationServer.set_locale("zh_CN")
	var dialog_scene: PackedScene = load(
		"res://scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn") as PackedScene
	var dialog: Variant = dialog_scene.instantiate()
	root.add_child(dialog)
	dialog._on_show({"hint_unwinnable": true})
	var hint_text: String = (dialog.get_node("Card/Hint") as RichTextLabel).text
	_check(hint_text.contains("[color=#FB6458]其他道具[/color]")
		and not hint_text.contains("{ACCENT_OPEN}"), "Hint 提前死亡文案翻译并标红其他道具")
	dialog._on_show()
	var ordinary_text: String = (dialog.get_node("Card/Hint") as RichTextLabel).text
	var expected_copy: String = tr("JUICE_DEAD_BOOSTER_HINT").replace("%1", "").replace("%2", "")
	_check(ordinary_text == expected_copy and not ordinary_text.contains("[color=")
		and not ordinary_text.contains("其他道具"), "普通死亡文案移除占位标记并使用普通颜色")
	dialog.queue_free()
	TranslationServer.set_locale(previous_locale)

	var prop_scene: PackedScene = load("res://scripts/widget/prop_btn/prop_btn.tscn") as PackedScene
	var btn: PropBtn = prop_scene.instantiate() as PropBtn
	root.add_child(btn)
	btn.set_base_scale(Vector2(0.8, 0.8))
	var bg: Control = btn.get_node("Bg")
	var icon: Control = btn.get_node("Icon")
	var glow: Control = btn.get_node("DeadGlow")
	var badge: Control = btn.get_node("Badge")
	var badge_rect: Rect2 = badge.get_rect()
	var icon_pivot: Vector2 = icon.pivot_offset
	btn.set_dead_glow(true)
	var shake: Tween = btn.get("_dead_shake_tween") as Tween
	_check(btn.get_node("DeadGlow").visible and shake != null and shake.is_running(), 
		"亮光圈时循环晃动")
	btn.set_dead_glow(true)
	_check(btn.get("_dead_shake_tween") == shake, "重复刷新不重启晃动")
	shake.pause()
	btn._apply_dead_motion(0.53333336)
	_check(is_equal_approx(bg.scale.x, 1.1) and absf(icon.scale.x - 1.265) < 0.001
		and is_equal_approx(glow.modulate.a, 1.0), "APK 两层缩放叠加并与光晕峰值同步")
	_check(glow.modulate.is_equal_approx(PropBtn.TOOL_PROMPT_ORANGE), "死局推荐外光统一橙色")
	btn._apply_dead_motion(0.3)
	_check(is_equal_approx(icon.rotation_degrees, 15.0), "图标正向摇摆15度")
	btn._apply_dead_motion(0.46666667)
	_check(is_equal_approx(icon.rotation_degrees, -15.0), "图标反向摇摆15度")
	btn._apply_dead_motion(1.2)
	_check(is_equal_approx(bg.scale.x, 1.0) and is_equal_approx(icon.scale.x, 1.0)
		and is_zero_approx(icon.rotation) and is_zero_approx(glow.modulate.a), 
		"1.067秒后进入静止间隔且无残光")
	_check(is_zero_approx(btn.rotation) and btn.scale == Vector2(0.8, 0.8)
		and badge.get_rect() == badge_rect, "根按钮与角标不参与死局演出")
	btn.play_unlock_highlight()
	_check(btn.get("_dead_shake_tween") == null, "解锁呼吸与晃动不叠播")
	btn.stop_unlock_highlight()
	_check(btn.get("_dead_shake_tween") != null, "解锁呼吸结束后恢复死局晃动")
	btn.set_dead_glow(false)
	_check( not btn.get_node("DeadGlow").visible and btn.get("_dead_shake_tween") == null
		and is_zero_approx(btn.rotation) and btn.scale == Vector2(0.8, 0.8)
		and icon.scale == Vector2.ONE and icon.pivot_offset == icon_pivot, 
		"关闭光圈后动画停止、姿态复位")
	btn.set_dead_glow(true)
	(btn.get("_dead_shake_tween") as Tween).pause()
	btn._apply_dead_motion(0.53333336)
	btn._on_button_down()
	_check(btn.get("_dead_shake_tween") == null and not glow.visible
		and bg.scale == Vector2.ONE and icon.scale == Vector2.ONE, 
		"点击在峰值立即清理局部变换")
	btn.set_dead_glow(true)
	(btn.get("_dead_shake_tween") as Tween).pause()
	btn._apply_dead_motion(0.3)
	btn.hide()
	_check(btn.get("_dead_shake_tween") == null and not glow.visible
		and is_zero_approx(icon.rotation) and icon.pivot_offset == icon_pivot, 
		"隐藏停止死局动画并归还图标姿态")
	btn.queue_free()
	if _failures.is_empty():
		print("PASS dead prop highlight")
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
	quit(0 if _failures.is_empty() else 1)



func _test_sort_die_actual_attribution(page_script: GDScript, attribution: Dictionary) -> void :
	var rules: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_rules.gd") as GDScript
	var board_scene: PackedScene = load(
		"res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var win: JuiceLevel = JuiceLevel.from_dict({"id": 98002, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "-|0", "1|1,1"], "incoming": ["x"]})
	var dead: JuiceLevel = JuiceLevel.from_dict({"id": 98003, "capacity": 3, "targetCups": 3, 
		"initial": ["0|2,1", "1|0,0", "2|1,1"], "incoming": ["0|0,2,2", "x"]})

	var doomed: JuiceLevel = JuiceLevel.from_dict({"id": 98004, "capacity": 2, "targetCups": 2, 
		"initial": ["0|1", "1|1", "-|"], "incoming": []})
	var local: JuiceLevel = JuiceLevel.from_dict({"id": 98005, "capacity": 2, "targetCups": 3, 
		"initial": ["0|0", "1|1", "2|2", "-|0,1"], "incoming": ["x"]})
	for entry: Dictionary in [
		{"level": win, "history": true, "want": attribution["LAST_MOVE"], "async": true}, 
		{"level": dead, "history": true, "want": attribution["EARLIER"], "async": true}, 
		{"level": doomed, "history": true, "want": attribution["EARLIER"], "async": true}, 
		{"level": local, "history": true, "want": attribution["LAST_MOVE"], "async": true}, 
		{"level": win, "history": false, "want": attribution["UNKNOWN"], "async": false}, 
		{"level": win, "history": true, "want": attribution["UNKNOWN"], "async": true, 
			"cancel": true}, 
	]:
		var level: JuiceLevel = entry["level"] as JuiceLevel
		var state: Dictionary = rules.make_state(level)

		var previous: Dictionary = rules.clone_state(state)
		var history: Array[Dictionary] = []
		if bool(entry["history"]):

			var moves: Array = rules.useful_moves(state)
			_check( not moves.is_empty(), "无参归因样例有可记录的合法移动")
			if moves.is_empty():
				continue
			var move: Dictionary = moves[0]
			var rec: Dictionary = rules.apply_move(state, level, int(move["src"]), 
				int(move["j"]), int(move["dst"]))
			_check( not rec.is_empty(), "无参归因样例按真实规则记录最近一步")
			history.append({"rec": rec})
		var board: Variant = board_scene.instantiate()
		root.add_child(board)
		board.set_process(false)
		board.set("_level", level)
		board.set("_state", state)
		board.set("_history", history)
		board.set("_steps", history.size())
		var before: String = JSON.stringify(state)
		var history_before: String = JSON.stringify(history)
		var events: Array[String] = []
		board.dead.connect( func(_reason: String) -> void : events.append("dead"))
		board.dead_attributed.connect( func(got: int, _reason: String, steps: int) -> void :
			events.append("attributed:%d:%d" % [got, steps]))
		var page: Variant = page_script.new()
		page.set("_board", board)
		page._cheat_force_die([] as Array[String])
		_check(board.over() == "dead" and not events.is_empty() and events[0] == "dead", 
			"无参先进入死亡态再报告归因")
		if bool(entry["async"]):
			_check(events == ["dead"] and board.death_attribution() == attribution["UNKNOWN"]
				and int(board.get("_death_task_id")) != -1, 
				"无参提交工作线程求解，等待期间保持 UNKNOWN")
			_check((board.get("_death_task_request") as Dictionary).get("previous") == previous, 
				"无参归因任务收到实际撤回一步后的盘面")
		if bool(entry.get("cancel", false)):

			board._invalidate_death_attribution()
		var deadline: int = Time.get_ticks_msec() + 5000
		while int(board.get("_death_task_id")) != -1 and Time.get_ticks_msec() < deadline:
			board._poll_death_attribution()
			await process_frame
		_check(int(board.get("_death_task_id")) == -1, "无参归因后台任务完成并回收")
		var expected: Array[String] = ["dead"]
		if not bool(entry.get("cancel", false)):
			expected.append("attributed:%d:%d" % [int(entry["want"]), history.size()])
		_check(events == expected and board.death_attribution() == int(entry["want"]), 
			"无参按实际前一手判定且旧代次结果不回写: %s" % str(entry))
		_check(JSON.stringify(board.state()) == before
			and JSON.stringify(board.get("_history")) == history_before
			and history.size() == int(board.get("_steps")), 
			"归因只预演撤回，不修改当前盘面、历史或步数")
		page.free()
		board.free()


func _check(ok: bool, description: String) -> void :
	if not ok:
		_failures.append(description)
