extends SceneTree

const PAGE: PackedScene = preload("res://scripts/main/pages/game/juice_game_page.tscn")
const PROGRESS: PackedScene = preload("res://scripts/main/pages/game/iq_progress_bar.tscn")
var failures: Array[String] = []

func _initialize() -> void :
	call_deferred("_run")

func check(value: bool, message: String) -> void :
	if not value:
		failures.append(message)
		SortLogger.error("ENDLESS_PAGE " + message)

func _wait_ready(page: JuiceGamePage) -> void :
	var deadline: int = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		if page.endless_session() != null and page._endless_controller.can_move():
			return
		await process_frame
	check(false, "正式游戏页无尽入场与首条补列准备完成")

func _dispose(page: JuiceGamePage) -> void :
	page.stop_endless()
	while page._endless_controller != null and not page._endless_controller._retired.is_empty():
		await process_frame
	page.queue_free()
	await process_frame

func _normal_move(page: JuiceGamePage) -> bool:
	for mv: Dictionary in JuiceRules.useful_moves(page._board.state()):
		var trial: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(page.endless_session().player_snapshot())
		var rec: Dictionary = trial.apply_move(int(mv.src), int(mv.j), int(mv.dst))
		if not rec.is_empty() and (rec["deposits"] as Array).is_empty():
			return page._board.try_move(int(mv.src), int(mv.j), int(mv.dst))
	return false

func _test_hint_death() -> void :
	var page: JuiceGamePage = PAGE.instantiate() as JuiceGamePage
	page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	page.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(page)
	page.start_endless(42, true)
	await _wait_ready(page)
	var session: JuiceEndlessSession = page.endless_session()

	session.state["allow_root_swapping"] = false
	session.state["cols"] = [[0, 0, 0] as Array[int], [1, 1, 1] as Array[int], 
		[2, 2, 2] as Array[int], [3, 3, 3] as Array[int], [4, 4, 4] as Array[int], [5, 5, 5] as Array[int]]
	session.state["jars"] = [-1, 6, 7, 8, 9, 6] as Array[int]
	page._board._rebuild_nodes()
	page._board._snap_all_home()

	page._board.set_process(false)
	UserState.set_prop_count("hint", 3)
	await page._refresh_prop_btns(true)
	var coins_before: int = UserState.get_coins()
	var level_before: int = UserState.get_current_level()
	var finished: Array = []
	page.endless_finished.connect( func(cups: int, reason: String) -> void : finished.append([cups, reason]))
	page._on_prop_pressed("hint")
	check(page._hint_task_id >= 0 and page._board.over() == "", "点击Hint启动独立死局检查")
	var deadline: int = Time.get_ticks_msec() + 3000
	while page._hint_task_id >= 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	check(page._board.over() == "dead" and finished.size() == 1
		and page._endless_controller.end_reason == JuiceBoardView.HINT_UNWINNABLE_REASON, 
		"Hint死局证明经共用死亡入口结束无尽且仅一次")
	check(UserState.get_prop_count("hint") == 3 and UserState.get_coins() == coins_before, 
		"Hint判死不扣道具或金币")
	check(UserState.get_current_level() == level_before and not page._win_committed, 
		"Hint判死不触发有限关通关")
	await _dispose(page)


func _test_rope_prop(page: JuiceGamePage) -> void :
	UserState.mark_prop_unlock_shown("rope")
	UserState.consume_prop_free_use("rope")
	UserState.set_prop_count("rope", 2)
	var coins: int = UserState.get_coins()
	var expected: Dictionary = JuiceRules.clone_state(page.endless_session().state)
	check(_normal_move(page), "绳子道具前建立真实撤回记录")
	for frame in 180:
		page._board._process(1.0 / 60.0)
	await page._refresh_prop_btns(true)
	page._use_prop("rope")
	check(page._board.has_rope() and (page.endless_session().state["cols"] as Array).size() == 7, 
		"无尽通过真实道具入口增加白色绳子")
	check(UserState.get_prop_count("rope") == 1 and UserState.get_coins() == coins, 
		"绳子效果成功才扣一次库存，不额外扣金币")
	for frame in 180:
		page._board._process(1.0 / 60.0)
	check(JuiceRules.add_rope(expected, 5) == 6 and page._board.undo(), "撤回使用绳子前的真实移动")
	check(page._board.has_rope() and JuiceRules.state_key(page.endless_session().state) == JuiceRules.state_key(expected), 
		"撤回不丢失已消费道具增加的绳子")
	page._use_prop("rope")
	check(UserState.get_prop_count("rope") == 1 and (page.endless_session().state["cols"] as Array).size() == 7, 
		"重复使用绳子不加列、不扣库存")



func _test_fill_pot_entrance_reuse(page: JuiceGamePage) -> void :
	var fill: PropBtn = page._prop_ui["fill_pot"]["btn"] as PropBtn
	var original_focus: int = fill.focus_mode
	var rope: PropBtn = page._prop_ui["rope"]["btn"] as PropBtn
	var rope_focus: int = rope.focus_mode
	for mode: int in [JuiceGamePage.PlayMode.LEVEL, JuiceGamePage.PlayMode.ENDLESS, 
			JuiceGamePage.PlayMode.LEVEL]:
		page.play_mode = mode as JuiceGamePage.PlayMode
		page._freeze_complete_prop_group()
		page._prepare_ui_entrance()
		var button_count: int = 0
		for entry: Dictionary in page._ui_entrance_entries:
			if bool(entry["grow"]):
				button_count += 1
		check(button_count == 4, "普通/无尽入场只编排四颗实际道具按钮 mode=%d" % mode)
		page._play_ui_entrance()
		var deadline: int = Time.get_ticks_msec() + 3000
		while page._ui_entrance_tween != null and Time.get_ticks_msec() < deadline:
			await process_frame
		check(page._ui_props_ready and page._ui_entrance_entries.is_empty()
			and fill.mouse_filter == Control.MOUSE_FILTER_STOP and fill.focus_mode == original_focus, 
			"入场完成恢复完成一列触摸，缓存切回普通关不残留输入锁 mode=%d" % mode)
		check(rope.mouse_filter == Control.MOUSE_FILTER_STOP and rope.focus_mode == rope_focus
			and not rope.disabled, "绳子在普通/无尽入场后恢复触摸与焦点 mode=%d" % mode)
	page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	page._freeze_complete_prop_group()


func _test_timed_title_and_fill_pot() -> void :
	var old_group: int = ABManager.complete_prop.get_debug_override()
	var old_locale: String = TranslationServer.get_locale()
	ABManager.complete_prop.set_debug_override(2)
	UserState.set_current_level(50)
	UserState.set_coins(2000)
	UserState.mark_prop_unlock_shown("fill_pot")
	UserState.grant_prop_free_uses(["fill_pot"])
	UserState.consume_prop_free_use("fill_pot")
	UserState.set_prop_count("fill_pot", 2)
	var page: JuiceGamePage = PAGE.instantiate() as JuiceGamePage
	page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	page.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(page)
	page.start_endless(42, true)
	await _wait_ready(page)
	await _test_fill_pot_entrance_reuse(page)
	check(page._complete_prop_enabled and (page._prop_ui["fill_pot"]["btn"] as Control).visible, 
		"无尽起局冻结实验道具开关")
	for width: float in [1080.0, 1400.0]:
		page.size = Vector2(width, 2340.0)
		for locale: String in TranslationServer.get_loaded_locales():
			TranslationServer.set_locale(locale)
			page._layout()
			page._sync_level_card()
			var title: Rect2 = page._level_label.get_global_rect()
			check( not title.intersects(page._coin_hud.get_global_rect())
				and not title.intersects(page._back_btn.get_global_rect()), "限时标题避开金币与返回按钮 " + locale)
			var font: Font = page._level_label.get_theme_font("font")
			check(font.get_string_size(page._level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 
				page._level_label.get_theme_font_size("font_size")).x <= title.size.x, 
				"限时标题译文完整适配 " + locale)
	TranslationServer.set_locale(old_locale)
	for group: int in [0, 1, 2, 3]:
		ABManager.complete_prop.set_debug_override(group)
		page._freeze_complete_prop_group()
		page._layout()
		page._apply_tutorial_visibility()
		check((page._prop_ui["fill_pot"]["btn"] as Control).visible == (group >= 2), 
			"限时完成一列按实验分组显隐 %d" % group)
		check( not page._reset_btn.visible and not page._header_reset_btn.visible, 
			"实验分组不恢复无尽重开 %d" % group)
	ABManager.complete_prop.set_debug_override(2)
	page._freeze_complete_prop_group()
	page._layout()
	var controller: JuiceEndlessController = page._endless_controller
	var ticks: Dictionary = {"now": Time.get_ticks_msec()}
	controller.clock = func() -> int: return int(ticks["now"])
	controller.on_flower_touched()
	controller._deadline_ms = int(ticks["now"]) + 120000
	var remaining: int = controller.remaining_ms()
	var coins: int = UserState.get_coins()
	page.pause_endless(&"menu")
	check( not page._prop_effect_available("fill_pot") and not page._apply_prop("fill_pot"), 
		"暂停时完成一列拒绝效果")
	page.resume_endless(&"menu")
	await page._refresh_prop_btns(true)
	var session: JuiceEndlessSession = page.endless_session()
	var state_ref: Dictionary = session.state
	var first_entry: Dictionary = session.incoming[0].duplicate(true)
	var incoming_count: int = session.incoming.size()
	page._use_prop("fill_pot")
	check(int(session.state["done"]) == 1 and page._quota._count.text == "1", "真实完成一列同步收盆")
	check(UserState.get_prop_count("fill_pot") == 1 and UserState.get_coins() == coins, 
		"完成一列成功才扣一次库存")
	check(controller.remaining_ms() == remaining + 3000 and page._time_bonus.text == "+3s", 
		"完成一列走共用收盆加3秒")
	check(session.last_incoming == first_entry and session.incoming.size() == incoming_count - 1, 
		"完成一列仅消费固定队首，不重随机补货")
	check(is_same(session.state, state_ref) and is_same(session.state, page._board.state()), 
		"完成一列保持Session与Board共持盘面字典")
	var flower_count: int = 0
	for col: Array in session.state["cols"]:
		flower_count += col.size()
	check(flower_count == JuiceEndlessSettings.FLOWERS and not page._win_committed, 
		"完成一列补回18朵花，不提交普通通关")
	page._use_prop("fill_pot")
	check(UserState.get_prop_count("fill_pot") == 1, "动画期间连点不重复扣库存")
	for frame: int in 240:
		page._board._process(1.0 / 60.0)
	check(page._board.sync_error() == "", "完成一列调配收盆补位后节点与状态一致")

	var empty_queue: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(session.player_snapshot())
	empty_queue.incoming.clear()
	var before: String = JSON.stringify(empty_queue.player_snapshot())
	check(empty_queue.complete_column(page._board.order()).is_empty()
		and JSON.stringify(empty_queue.player_snapshot()) == before, "补列为空时完成一列失败且不修改状态")
	var no_target: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(session.player_snapshot())
	(no_target.state["jars"] as Array[int]).fill(9)
	before = JSON.stringify(no_target.player_snapshot())
	check(no_target.complete_column(page._board.order()).is_empty()
		and JSON.stringify(no_target.player_snapshot()) == before, "凑不满任一盆时调配失败且不修改队列")
	var multiple: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(session.player_snapshot())
	var fixture: JuiceLevel = JuiceLevel.from_dict({"id": 101, "capacity": 5, "targetCups": 5, 
		"initial": ["-1|", "0|0,0,0,0,0", "1|1,1,1,1,1", "2|2,2,2,2,2", "3|3", "4|4,0"], "incoming": []})
	multiple.state = JuiceRules.make_state(fixture)
	multiple.incoming.resize(2)
	before = JSON.stringify(multiple.player_snapshot())
	check(multiple.complete_column([0, 1, 2, 3, 4, 5]).is_empty()
		and JSON.stringify(multiple.player_snapshot()) == before, "三盆待收而FIFO只有两条时不部分提交")

	UserState.set_prop_count("fill_pot", 0)
	await page._refresh_prop_btns(true)
	page._use_prop("fill_pot")
	check(UserState.get_coins() == coins - 1200 and int(session.state["done"]) == 2, 
		"无尽完成一列复用1200金币即买即用")
	for frame: int in 240:
		page._board._process(1.0 / 60.0)
	AdManager.set("test_endless_ready", true)
	await page._refresh_prop_btns(true)
	page._use_prop("fill_pot")
	var ad_deadline: int = Time.get_ticks_msec() + 3000
	while not page._prop_ad_in_flight and Time.get_ticks_msec() < ad_deadline:
		await process_frame
	check(page._prop_ad_in_flight and int(session.state["done"]) == 2, "完成一列广告不立即放效果")
	AdManager.emit_signal("test_endless_ad_closed")
	while page._prop_ad_in_flight and Time.get_ticks_msec() < ad_deadline:
		await process_frame
	check(UserState.get_prop_count("fill_pot") == 1 and int(session.state["done"]) == 2
		and UserState.get_coins() == coins - 1200, "完成一列广告只补一次库存且不扣金币")
	AdManager.set("test_endless_ready", false)
	ABManager.complete_prop.set_debug_override(0)
	page._freeze_complete_prop_group()
	check( not page._apply_prop("fill_pot"), "对照组不能绕过按钮直接使用完成一列")
	controller._deadline_ms = int(ticks["now"])
	controller._process(0.0)
	check( not page._apply_prop("fill_pot"), "限时结束后拒绝完成一列")
	page.stop_endless()
	page.play_mode = JuiceGamePage.PlayMode.LEVEL
	page._sync_level_card()
	check(page._level_label.position == Vector2.ZERO
		and page._level_label.size.x == page._level_block.size.x
		and page._level_label.get_theme_font_size("font_size") == 64, 
		"切回普通关恢复原关号布局与字号")
	await _dispose(page)
	if old_group >= 0:
		ABManager.complete_prop.set_debug_override(old_group)
	else:
		ABManager.complete_prop.clear_debug_override()


func _run() -> void :
	await _test_timed_title_and_fill_pot()
	if OS.get_cmdline_user_args().has("--timed-props-only"):
		if failures.is_empty():
			SortLogger.info("ENDLESS_PAGE PASS")
		quit(0 if failures.is_empty() else 1)
		return
	_test_countdown_progress()
	await process_frame
	UserState.set_current_level(50)
	UserState.set_coins(2000)
	for key: String in ["hint", "undo"]:
		UserState.mark_prop_unlock_shown(key)
		UserState.consume_prop_free_use(key)
		UserState.set_prop_count(key, 3)
	var level_before: int = UserState.get_current_level()
	var coins_before: int = UserState.get_coins()
	var page: JuiceGamePage = PAGE.instantiate() as JuiceGamePage
	page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	page.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(page)
	page.start_endless(42, true)
	await _wait_ready(page)
	await _test_endless_banner(page)
	check(page._components_ready and page._playfield_ready, "复用正式页组件及入场交接")
	check(page._quota._count.text == "0" and not page._iq_progress.get_node("Marks").visible, "只显示总盆数，无IQ数字")
	check((page._prop_ui["rope"]["btn"] as Control).visible, "无尽显示绳子按钮")
	check( not page._reset_btn.visible and not page._header_reset_btn.visible, "无尽隐藏所有重开按钮")
	check(is_equal_approx(page._quota.size.x, JuiceQuotaBar.MAX_W), "无尽订单栏从开局即满宽")
	page._layout()
	check((page._prop_ui["rope"]["btn"] as Control).visible, "重复布局保留绳子按钮")
	page._apply_tutorial_visibility()
	check((page._prop_ui["rope"]["btn"] as Control).visible, "通用教学显隐保留无尽绳子按钮")
	await _test_rope_prop(page)
	var controller: JuiceEndlessController = page._endless_controller
	var time_notifications: Array[int] = []
	controller.time_added.connect( func(milliseconds: int) -> void : time_notifications.append(milliseconds))
	check( not page._time_bonus.visible and page._time_bonus.self_modulate.a == 0.0, "新局加时文字默认隐藏")
	check(page._time_bonus.get_theme_font_size("font_size") == 40
		and page._time_bonus.get_theme_color("font_color").is_equal_approx(Color.html("22B667")), "加时文字使用设计字号与绿色")
	check(page._time_bonus.size == Vector2(100, 40), "加时文字保持100×40设计框")
	var ticks: Dictionary = {"now": Time.get_ticks_msec()}
	controller.clock = func() -> int: return int(ticks["now"])
	controller.on_flower_touched()
	controller._deadline_ms = int(ticks["now"]) + 120000
	page._refresh_endless_hud()
	check(is_equal_approx(page._iq_progress._display_width, 414.0), "120秒条满")
	ticks["now"] += 60000
	page._process(0.0)
	check(is_equal_approx(page._iq_progress._display_width, 207.0), "时间条线性减少且不显示秒数")
	ticks["now"] += 1
	page._process(0.0)
	check(absf(page._iq_progress._display_width - 414.0 * 59999.0 / 120000.0) < 0.0001, 
		"同一秒内按真实毫秒刷新时间条")
	page.pause_endless(&"menu")
	var remaining: int = controller.remaining_ms()
	var paused_width: float = page._iq_progress._display_width
	ticks["now"] += 20000
	page._process(0.0)
	check(page._iq_progress._display_width == paused_width, "菜单暂停时条宽冻结")
	page.resume_endless(&"menu")
	check(controller.remaining_ms() == remaining, "菜单暂停不消耗时间")
	page._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ticks["now"] += 10000
	page._process(0.0)
	check(page._iq_progress._display_width == paused_width, "后台暂停时条宽冻结")
	page._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(controller.remaining_ms() == remaining, "后台暂停不消耗时间")
	var hint_before: int = UserState.get_prop_count("hint")
	page._on_prop_pressed("hint")
	var deadline: int = Time.get_ticks_msec() + 3000
	while page._hint_task_id >= 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	check(page._board.has_active_hint() and UserState.get_prop_count("hint") == hint_before - 1, "无尽真实Hint证明后才扣库存")
	var last: Dictionary
	for move: Dictionary in JuiceEndlessSettings.opening_moves(42):
		check(page._board.try_move(int(move.src), int(move.j), int(move.dst)), "正式页真实收盆")
		for frame in 180:
			page._board._process(1.0 / 60.0)
	check(page._quota._count.text == "1" and controller.remaining_ms() == remaining + 3000, "盆数同步加一且加时三秒")
	check(time_notifications == [3000] and page._time_bonus.visible and page._time_bonus.text == "+3s", "真实收盆加时后通知并显示+3s")
	var first_bonus: Tween = page._time_bonus_tween
	controller._on_board_moved(0)
	check(time_notifications == [3000] and page._time_bonus_tween == first_bonus, "重复移动回调不重复加时或重播提示")
	_test_time_bonus_animation(page)
	var refill: Dictionary = controller.session.last_incoming.duplicate(true)
	var undo_before: int = UserState.get_prop_count("undo")
	page._use_prop("undo")
	check(page._quota._count.text == "0" and UserState.get_prop_count("undo") == undo_before - 1, "正式Undo扣真实库存并回退盆数")
	check(controller.remaining_ms() == remaining + 3000, "撤回保留已得时间")
	check(time_notifications == [3000] and not page._time_bonus.visible, "撤回不请求加时提示")
	last = JuiceEndlessSettings.opening_moves(42)[-1]
	check(page._board.try_move(int(last.src), int(last.j), int(last.dst)), "正式页重新收盆")
	check(controller.session.last_incoming == refill and controller.remaining_ms() == remaining + 6000, "重收复用固定补列并再次加时")
	check(time_notifications == [3000, 3000] and page._time_bonus.visible, "撤回后重收正常再次播放加时提示")
	for frame in 180:
		page._board._process(1.0 / 60.0)
	page._use_prop("undo")

	UserState.set_prop_count("undo", 0)
	page._refresh_prop_btns()
	check(_normal_move(page), "金币撤回前真实移动")
	page._refresh_prop_btns()
	page._use_prop("undo")
	check(UserState.get_coins() == coins_before - 400, "金币即买即用沿用正式价格")
	check(UserState.get_current_level() == level_before and not page._win_committed, "无尽不触发主线通关")

	page._cancel_cup_flights()
	page._quota.setup_endless()
	page._quota.set_collected_count(40)
	for i in 8:
		page._quota.push_cup(null, Color.RED)
	check(page._quota.filled_count() == 8 and page._quota._count.text == "40", "保留已收盆记录、总计独立于显示窗口")
	page._on_cups_changed()

	UserState.set_coins(0)
	UserState.set_prop_count("hint", 0)
	AdManager.set("test_endless_ready", true)
	AdManager.set("test_endless_reward", true)
	page._on_endless_time_added(3000)
	var previous_bonus: Tween = page._time_bonus_tween
	page.start_endless(42, true)
	await _wait_ready(page)
	check( not page._time_bonus.visible and page._time_bonus_tween == null
		and not previous_bonus.is_valid(), "重开取消上一局加时动画")
	check( not page._board.has_rope() and (page.endless_session().state["cols"] as Array).size() == 6, 
		"重开恢复六列及本局加绳资格")
	UserState.set_prop_count("rope", 0)
	await page._refresh_prop_btns(true)
	page._use_prop("rope")
	var rope_ad_deadline: int = Time.get_ticks_msec() + 3000
	while not page._prop_ad_in_flight and Time.get_ticks_msec() < rope_ad_deadline:
		await process_frame
	check(page._prop_ad_in_flight and not page._board.has_rope(), "绳子广告只补库存，不立即加绳")
	AdManager.emit_signal("test_endless_ad_closed")
	while page._prop_ad_in_flight:
		await process_frame
	check(UserState.get_prop_count("rope") == 1 and not page._board.has_rope(), "无尽绳子广告只补一次库存")
	await page._refresh_prop_btns(true)
	page._use_prop("hint")
	deadline = Time.get_ticks_msec() + 3000
	while not page._prop_ad_in_flight and Time.get_ticks_msec() < deadline:
		await process_frame
	check(page._prop_ad_in_flight and not controller._time_running, "道具广告期间暂停计时")
	remaining = controller.remaining_ms()
	ticks["now"] += 10000
	AdManager.emit_signal("test_endless_ad_closed")
	while page._prop_ad_in_flight:
		await process_frame
	check(controller.remaining_ms() == remaining and UserState.get_prop_count("hint") == 3, "广告补三次库存、不立即放效果")


	page._hint_cache_key = ""
	page._hint_plan_key = ""
	hint_before = UserState.get_prop_count("hint")
	page._use_prop("hint")
	check(_normal_move(page), "提示期间调试移动改变盘面")
	deadline = Time.get_ticks_msec() + 3000
	while page._hint_task_id >= 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	check(UserState.get_prop_count("hint") == hint_before, "过期提示不扣库存")
	var finished: Array = []
	page.endless_finished.connect( func(cups: int, reason: String) -> void : finished.append([cups, reason]))
	page._on_endless_time_added(3000)
	previous_bonus = page._time_bonus_tween
	ticks["now"] += controller.remaining_ms()
	controller._process(0.0)
	controller._process(0.0)
	check(finished.size() == 1 and page._endless_mask.visible and controller.end_reason == "time_up", "超时只结束一次并显示正式页遮罩")
	check( not page._time_bonus.visible and page._time_bonus_tween == null
		and not previous_bonus.is_valid(), "结束时立即取消加时动画")
	undo_before = UserState.get_prop_count("undo")
	page._use_prop("undo")
	page._use_prop("rope")
	check(UserState.get_prop_count("undo") == undo_before and not page._board.add_rope(), "结束后禁止道具与加绳")
	await _dispose(page)
	await _test_hint_death()

	var source: JuiceGamePage = PAGE.instantiate() as JuiceGamePage
	source.play_mode = JuiceGamePage.PlayMode.ENDLESS
	root.add_child(source)
	await source.prepare_for_display( func() -> bool: return true)
	source.play_mode = JuiceGamePage.PlayMode.LEVEL
	source._apply_tutorial_visibility()
	check((source._prop_ui["rope"]["btn"] as Control).visible, "普通模式仍显示加绳按钮")
	source._quota.setup(5)
	var source_level: JuiceLevel = JuiceLevel.from_dict({"id": 50, "capacity": 5, "targetCups": 5, "initial": JuiceEndlessSettings.initial_layout(42), "incoming": []})
	source._board.setup(source_level)
	source.play_mode = JuiceGamePage.PlayMode.ENDLESS
	source._on_endless_time_added(3000)
	previous_bonus = source._time_bonus_tween
	source.play_mode = JuiceGamePage.PlayMode.LEVEL
	source._sync_level_card()
	source._on_endless_time_added(3000)
	check( not source._time_bonus.visible and source._time_bonus_tween == null
		and not previous_bonus.is_valid(), "普通模式恢复时清加时提示且拒绝起播")
	check(source._board.over() == "", "来源是仍在进行的有限关卡")
	source._board.set_process(false)
	source._iq_round.reset(true, 5, 0)
	source._refresh_iq_header(false)
	source._play_timer.arm(50, 1000, false)
	var source_board: String = JSON.stringify(source._board.snapshot())
	var source_width: float = source._iq_progress._display_width
	var source_material: ShaderMaterial = source._iq_progress._glow_material
	var source_mask: Variant = source_material.get_shader_parameter("mask_uv_rect")
	var cache: Dictionary = SceneManager.get("_page_cache")
	var previous_source: Variant = cache.get("game")
	cache["game"] = source

	var preview: CanvasLayer = load("res://scripts/debug/ui/juice_endless_preview.gd").new()
	root.add_child(preview)
	paused = false
	preview.open(77)
	var source_time: int = source._play_timer.elapsed_ms()
	await _wait_ready(preview._page)
	check(JSON.stringify(source._board.snapshot()) == source_board and source._play_timer.elapsed_ms() == source_time, "试玩保持来源盘面并暂停原局计时")
	check(source._iq_progress._display_width == source_width and source_material.get_shader_parameter("mask_uv_rect") == source_mask, "时间条不修改来源IQ材质或进度")
	check(paused and preview._page.is_endless(), "Debug正式页独立实例可在暂停树内准备")
	preview.close()
	check( not paused and not source._external_play_suspended, "退出恢复暂停状态与来源计时器")
	check(JSON.stringify(source._board.snapshot()) == source_board and source._iq_progress._display_width == source_width, "退出来源页原样恢复")
	var token_deadline: int = Time.get_ticks_msec() + 3000
	while is_instance_valid(preview) and Time.get_ticks_msec() < token_deadline:
		await process_frame
	check( not is_instance_valid(preview), "退出后取消任务并收回实例")
	if previous_source == null:
		cache.erase("game")
	else:
		cache["game"] = previous_source
	source.queue_free()
	await process_frame

	preview = load("res://scripts/debug/ui/juice_endless_preview.gd").new()
	root.add_child(preview)
	paused = true
	preview.open(88)
	preview.close()
	var early_deadline: int = Time.get_ticks_msec() + 5000
	while is_instance_valid(preview) and Time.get_ticks_msec() < early_deadline:
		await process_frame
	check(paused and not is_instance_valid(preview), "准备阶段退出可取消且保留原暂停状态")
	paused = false
	await _test_play_after_dead()
	if failures.is_empty():
		SortLogger.info("ENDLESS_PAGE PASS")
	quit(0 if failures.is_empty() else 1)



func _test_play_after_dead() -> void :
	var old_override: int = ABManager.allow_root_swapping.get_debug_override()
	ABManager.allow_root_swapping.set_debug_override(2)
	UserState.set_current_level(50)
	UserState.mark_prop_unlock_shown("undo")
	UserState.consume_prop_free_use("undo")
	UserState.set_prop_count("undo", 3)
	var page: JuiceGamePage = PAGE.instantiate() as JuiceGamePage
	page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	page.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(page)
	page.start_endless(42, true)
	await _wait_ready(page)
	var board: JuiceBoardView = page._board
	var controller: JuiceEndlessController = page._endless_controller
	check(board.is_play_after_dead_enabled() and not bool(board.get("_root_adjudication_suspended")), 
		"组2跳过入场也在Controller激活后解除判定暂停")
	page._complete_prop_enabled = true
	var ticks: Dictionary = {"now": Time.get_ticks_msec()}
	controller.clock = func() -> int: return int(ticks["now"])
	controller.on_flower_touched()
	controller._deadline_ms = int(ticks["now"]) + 120000
	var finished: Array = []
	var deaths: Array[String] = []
	page.endless_finished.connect( func(cups: int, reason: String) -> void : finished.append([cups, reason]))
	board.dead.connect( func(reason: String) -> void : deaths.append(reason))

	var fixture: JuiceLevel = JuiceLevel.from_dict({"id": 99005, "capacity": 5, "targetCups": 6, 
		"initial": ["0|0,0,0,0,1", "1|1,1,1,1,2", "2|2,2,2,2,0", 
			"0|0,0,0,0,2", "1|1,1,1,1,0", "2|2,2,2,2,1"], "incoming": []})
	board.set_root_adjudication_suspended(true)
	controller.session.state = JuiceRules.make_state(fixture)
	controller.session.state["allow_root_swapping"] = true
	board.setup_endless(controller.session, controller.can_apply_board_move)
	board.set_entrance_lock(false)
	board.set_input_enabled(true)
	check(board.try_move(0, 0, 1), "判定暂停期间先建立真实整列交换撤销历史")
	board.set_root_adjudication_suspended(false)
	var deadline: int = Time.get_ticks_msec() + 10000
	while board.over() != "dead" and Time.get_ticks_msec() < deadline:
		await process_frame

	while deaths.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(board.over() == "dead" and deaths.size() == 1 and finished.is_empty()
		and controller.end_reason == "" and not page._endless_mask.visible, 
		"严格首盆CLOSED只交付死亡尝试，不结束组2无尽或显示结束蒙层")
	check( not controller.can_move() and controller.can_operate_dead() and page._endless_can_use_props(), 
		"组2死态保留独立操作资格，不冒充活局")
	var remaining: int = controller.remaining_ms()
	ticks["now"] += 1000
	controller._process(0.0)
	check(controller.remaining_ms() == remaining - 1000, "死态倒计时继续推进")
	check( not page._prop_effect_available("hint") and not page._prop_effect_available("rope")
		and not page._prop_effect_available("fill_pot") and page._prop_effect_available("undo"), 
		"无尽死亡只开放有历史的Undo，道具禁用和有限关不混用")
	check(board.try_move(0, 0, 1), "组2严格死态仍允许真实整列交换")
	for frame in 180:
		board._process(1.0 / 60.0)
	check(board.over() == "dead" and deaths.size() == 1 and finished.is_empty(), 
		"死后合法交换保留dead且不重复交付死亡/结束")
	page.pause_endless(&"menu")
	check( not controller.can_operate_dead() and not board.try_move(0, 0, 1), "死态仍尊重菜单暂停")
	page.resume_endless(&"menu")
	var undo_before: int = UserState.get_prop_count("undo")
	await page._refresh_prop_btns(true)
	page._use_prop("undo")
	check(UserState.get_prop_count("undo") == undo_before - 1 and board.over() == "", 
		"死态Undo真实恢复历史、清死亡状态且只扣一次库存")
	check(controller.can_move() and controller.end_reason == "", "真实撤销后恢复活局控制器资格")
	ticks["now"] += controller.remaining_ms()
	controller._process(0.0)
	controller._process(0.0)
	check(finished.size() == 1 and controller.end_reason == "time_up", "死亡尝试后的超时仍只结束一次")
	await _dispose(page)
	if old_override >= 0:
		ABManager.allow_root_swapping.set_debug_override(old_override)
	else:
		ABManager.allow_root_swapping.clear_debug_override()


func _test_time_bonus_animation(page: JuiceGamePage) -> void :
	var animation: Tween = page._time_bonus_tween
	animation.pause()
	var rest_y: float = page._timer_label.position.y + (page._timer_label.size.y - page._time_bonus.size.y) * 0.5
	check(is_equal_approx(page._time_bonus.position.x, 
		page._timer_label.position.x + page._timer_label.size.x + 4.0), "加时提示位于真实时间框右侧")
	var coin_pill: Control = page.get_node("Header/CoinHud/Pill") as Control
	check( not page._time_bonus.get_global_rect().intersects(coin_pill.get_global_rect()), 
		"加时提示与顶部金币底板不重叠")
	check(is_equal_approx(page._time_bonus.position.y, rest_y + 18.0)
		and page._time_bonus.self_modulate.a == 0.0, "浮入起点在下方且透明")
	animation.custom_step(0.1)
	check(is_equal_approx(page._time_bonus.self_modulate.a, 0.75)
		and is_equal_approx(page._time_bonus.position.y, rest_y + 4.5), "浮入使用0.2秒二次缓出")
	animation.custom_step(0.1)
	check(is_equal_approx(page._time_bonus.self_modulate.a, 1.0)
		and is_equal_approx(page._time_bonus.position.y, rest_y), "浮入结束到达时间框中央")
	animation.custom_step(0.6)
	check(is_equal_approx(page._time_bonus.self_modulate.a, 1.0)
		and is_equal_approx(page._time_bonus.position.y, rest_y), "停留0.6秒不继续漂移")
	animation.custom_step(0.125)
	check(is_equal_approx(page._time_bonus.self_modulate.a, 0.75)
		and is_equal_approx(page._time_bonus.position.y, rest_y - 4.5), "退出使用0.25秒二次缓入并向上淡出")
	animation.custom_step(0.125)
	check( not page._time_bonus.visible and page._time_bonus_tween == null
		and page._time_bonus.self_modulate.a == 0.0, "自然结束隐藏并清动画句柄")
	page._on_endless_time_added(3000)
	animation = page._time_bonus_tween
	animation.pause()
	animation.custom_step(0.1)
	page._on_endless_time_added(3000)
	check( not animation.is_valid() and page._time_bonus_tween != animation
		and page._time_bonus.self_modulate.a == 0.0 and page._time_bonus_offset_y == 18.0, 
		"连续收盆取消旧动画并从下方重新播放")
	animation = page._time_bonus_tween
	page._on_endless_time_added(0)
	check(page._time_bonus_tween == animation, "零加时不请求动画")
	page._hide_round_view()
	check( not page._time_bonus.visible and page._time_bonus_tween == null
		and not animation.is_valid(), "离页复位后旧Tween不能恢复文字")
	page._on_endless_time_added(3000)
	check( not page._time_bonus.visible, "隐藏页拒绝起播")
	page.show()
	page._board.show()
	page._on_endless_time_added(3000)
	check(page._time_bonus.visible and page._time_bonus_tween != null, "取消后重新显示可正常起播")
	page._reset_time_bonus()


func _test_countdown_progress() -> void :
	var bar: IqProgressBar = PROGRESS.instantiate() as IqProgressBar
	bar.set_countdown_progress(0.625)
	root.add_child(bar)
	bar.show()
	check(is_equal_approx(bar._display_width, 258.75), "入树前设置的倒计时比例保留")
	check( not bar._fill_clip.visible and not bar.get_node("Marks").visible, 
		"无尽隐藏IQ填充、光和刻度")
	check(is_equal_approx(bar._countdown_fill.size.x, 414.0)
		and is_equal_approx(bar._countdown_fill.size.x / bar._countdown_fill.size.y, 413.0 / 25.0), 
		"原图等比适配现有填充槽")
	check(is_equal_approx(bar._countdown_fill.position.y + bar._countdown_fill.size.y * 0.5, 105.0), 
		"新填充保留现有槽的竖向中心")
	var other: IqProgressBar = PROGRESS.instantiate() as IqProgressBar
	other.set_countdown_progress(1.0)
	root.add_child(other)
	check(bar._countdown_material != other._countdown_material, "无尽材质按实例独享")
	var samples: Array[Dictionary] = [
		{"fraction": 1.5, "weights": Vector3(1, 0, 0)}, 
		{"fraction": 1.0, "weights": Vector3(1, 0, 0)}, 
		{"fraction": 0.75, "weights": Vector3(1, 0, 0)}, 
		{"fraction": 0.6875, "weights": Vector3(0.8426953305796029, 0.15730466942039714, 0)}, 
		{"fraction": 0.625, "weights": Vector3(0.5, 0.5, 0)}, 
		{"fraction": 0.5, "weights": Vector3(0, 1, 0)}, 
		{"fraction": 0.375, "weights": Vector3(0, 1, 0)}, 
		{"fraction": 0.25, "weights": Vector3(0, 1, 0)}, 
		{"fraction": 0.1875, "weights": Vector3(0, 0.8426953305796029, 0.15730466942039714)}, 
		{"fraction": 0.125, "weights": Vector3(0, 0.5, 0.5)}, 
		{"fraction": 0.0, "weights": Vector3(0, 0, 1)}, 
		{"fraction": -0.1, "weights": Vector3(0, 0, 1)}, 
	]
	for sample: Dictionary in samples:
		var fraction: float = float(sample["fraction"])
		bar.set_countdown_progress(fraction)
		var weights: Vector3 = bar._countdown_material.get_shader_parameter("color_weights")
		check(weights.distance_to(sample["weights"]) < 1e-05, "Figma分色和Bezier缓动 %s" % fraction)
		check(is_equal_approx(bar._countdown_fill.scale.x, clampf(fraction, 0.0, 1.0))
			and bar._countdown_fill.scale.y == 1.0 and bar._countdown_fill.position.x == 9.0, 
			"横向缩放保持左端不动 %s" % fraction)
		check(bar._countdown_fill.visible == (fraction > 0.0), "0进度完整隐藏 %s" % fraction)
	check(other._countdown_material.get_shader_parameter("color_weights") == Vector3(1, 0, 0), 
		"一局变红不污染另一局绿色")
	bar.set_countdown_progress(0.125)
	bar.set_countdown_progress(0.625)
	check(bar._countdown_material.get_shader_parameter("color_weights").is_equal_approx(Vector3(0.5, 0.5, 0)), 
		"加时跨色段按新比例同步回涨")
	bar.set_countdown_progress(0.375)
	bar.hide()
	bar.show()
	check(is_equal_approx(bar._display_width, 155.25) and bar._countdown_fill.scale.x == 0.375, 
		"隐藏后恢复倒计时，不切回IQ进度")
	bar.size.x = 216.0
	bar._layout_progress()
	check(is_equal_approx(bar._countdown_fill.size.x, 207.0)
		and is_equal_approx(bar._countdown_fill.size.x / bar._countdown_fill.size.y, 413.0 / 25.0), 
		"局部尺寸改变保留素材比例")
	bar.set_iq(90.0, false)
	check(bar._fill_clip.visible and bar.get_node("Marks").visible and not bar._countdown_fill.visible
		and is_equal_approx(bar._display_width, 171.0), "返回普通IQ恢复原填充及刻度")
	bar.set_countdown_progress(1.0)
	check(bar._countdown_fill.scale.x == 1.0
		and bar._countdown_material.get_shader_parameter("color_weights") == Vector3(1, 0, 0), 
		"新局恢复满条绿色")
	bar.queue_free()
	other.queue_free()
	var before_ready: IqProgressBar = PROGRESS.instantiate() as IqProgressBar
	before_ready.set_countdown_progress(0.25)
	before_ready.set_iq(90.0, false)
	root.add_child(before_ready)
	check( not before_ready._countdown_mode and before_ready._fill_clip.visible, 
		"入树前无尽切回IQ不访问未就绪节点")
	before_ready.queue_free()

func _show_banner_for_test(page: JuiceGamePage, state: Dictionary) -> void :
	state.ok = await page.show_endless_opening_banner(page._endless_context)
	state.done = true



func _test_endless_banner(page: JuiceGamePage) -> void :
	var banner: GameStartBanner = page._start_banner
	var state: Dictionary = {"done": false, "ok": false}
	_show_banner_for_test(page, state)
	check(banner.visible and banner._timed.visible, "无尽开局横幅复用正式缓存组件")
	check(banner._timed_panel.size == Vector2(1000, 700), "开局弹窗1000×700")
	check(is_equal_approx(banner._timed_design.scale.x, banner._timed_design.scale.y), "装饰和文字等比放大")
	var scrim: ColorRect = banner.get_node("Root/Timed/Scrim") as ColorRect
	check(scrim.color == Color(0, 0, 0, 0.8) and scrim.mouse_filter == Control.MOUSE_FILTER_STOP, 
		"蒙层为80%纯黑且拦截触摸")
	check(page._opening_banner_input_locked and not page._board._input_enabled, 
		"横幅期间锁住盘面")
	check( not page._endless_controller._time_started and page._endless_controller.remaining_ms() == 120000, 
		"横幅展示不启动倒计时")
	var saved_locale: String = TranslationServer.get_locale()
	for locale: String in ["zh_CN", "en", "pt_BR", "id", "fil", "es", "ru", "de", "ja", "fr", "ko", "it", "pl", "tr", "uk", "zh_TW", "th", "ms", "vi", "ro", "nl", "nb", "fi", "el", "sv", "hu", "bn", "ta", "ur"]:
		TranslationServer.set_locale(locale)
		banner._refresh_timed_text()
		check(banner._timed_title.text != String(GameStartBanner.TIMED_TITLE_KEY)
			and banner._timed_body.text != String(GameStartBanner.TIMED_BODY_KEY), "横幅译文存在 %s" % locale)
		banner._timed_body.clip_text = false
		check(banner._timed_body.get_minimum_size().y <= GameStartBanner.TIMED_BODY_RECT.size.y + 1.0, 
			"说明文字完整放入设计框 %s" % locale)
		banner._timed_body.clip_text = true
		check(banner._timed_outline.text == banner._timed_title.text
			and banner._timed_shadow_mask.text == banner._timed_title.text, "标题多层文字同步 %s" % locale)
	TranslationServer.set_locale(saved_locale)
	banner.hide_now()
	while not state.done:
		await process_frame
	check( not state.ok and not banner.visible and not banner._timed.visible
		and not page._opening_banner_input_locked, "取消横幅后清蒙层并复位输入锁")
