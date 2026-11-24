extends Node


class ProbePanel extends FinishDialog:
	var cart_shows: int = 0
	var button_shows: int = 0
	var trace: Array[String] = []
	func _ready() -> void :
		_content_ready = true
		set_process(false)
	func _on_show(params: Dictionary) -> void :
		await show_bg()
		_game_data_enabled = bool(params["game_data_enabled"])
		_wait_then_show_reward(false)
	func reset_content() -> void :
		_presentation_generation += 1
		_reward_entrance_complete = false
		_entrance_complete = false
		_game_data_enabled = false
		_next_requested = false
		_hide_next_button()
	func _show_reward(_is_hard: bool) -> void :
		cart_shows += 1
		trace.append("cart")
	func _refresh_encouragement() -> void :
		pass
	func _layout_next_button() -> void :
		pass
	func _show_next_button() -> void :
		button_shows += 1
		trace.append("button")
		super ()


class ProbeData extends GameDataLayer:
	var shows: int = 0
	var trace: Array[String] = []
	func _ready() -> void :
		set_process(false)
	func set_data(_data: Dictionary, _hard: bool, _super_hard: bool) -> void :
		shows += 1
		trace.append("data")
	func _play_card_burst(_index: int) -> void :
		pass
	func _play_card_appear(_index: int, _generation: int) -> void :
		pass


class ProbePage extends JuiceGamePage:
	var panel: ProbePanel
	var trace: Array[String] = []
	var preparation_result: bool = true
	var preparation_waiting: bool = false
	signal preparation_released
	var exits: int = 0
	func _ready() -> void :
		set_process(false)
	func _exit_tree() -> void :
		pass
	func prepare_finish_ad_reward() -> bool:
		if preparation_waiting:
			await preparation_released
		return preparation_result
	func play_celebration() -> void :
		_complete_shown = false
		_complete_panel = panel
		panel.show()
		panel._on_show({"game_data_enabled": _finish_game_data_enabled})
		_mark_complete_shown_after_finish_entrance()
	func get_finish_game_data() -> Dictionary:
		return {"target_flower_count": 24, "elapsed_ms": 1000, "move_attempt_count": 1, 
			"win_streak_count": 1}
	func show_iq_genius_feedback() -> bool:
		return true
	func report_game_end() -> void :
		pass
	func play_win_coin_reward() -> void :
		pass
	func is_bonus_level_round() -> bool:
		return false
	func play_rank_collect() -> bool:
		return true
	func wait_finish_preparation() -> bool:
		return true
	func hide_banner_ad() -> void :
		pass
	func fade_win_flowers() -> void :
		pass
	func show_daily_first_win_checkin() -> bool:
		return true
	func prepare_mainline_timed_finish() -> bool:
		return true
	func exit_finish_after_win(_won_level: int) -> void :
		exits += 1
		trace.append("exit")


var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _check(condition: bool, message: String) -> void :
	if not condition:
		_failures.append(message)
		SortLogger.error("FinishBackground: " + message)


func _rating_requests() -> int:
	var rating: Variant = load("res://scripts/capability/rating/rating_manager.gd")
	return int(rating.test_requests)


func _make_page(stats: bool = true, timed: bool = false) -> ProbePage:
	var page_scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn")
	var instance: Variant = page_scene.instantiate()
	instance.set_script(ProbePage)
	var page: ProbePage = instance as ProbePage
	page._external_play_suspended = true
	page._end_flow_generation = 1
	page._finish_game_data_enabled = stats
	if timed:
		page.play_mode = JuiceGamePage.PlayMode.ENDLESS
		page._mainline_timed_offer = {"instance_id": "finish-background-test"}
	page.show()
	add_child(page)
	var panel_scene: PackedScene = load("res://scripts/main/dialogs/finish/finish_dialog.tscn")
	var panel: Variant = panel_scene.instantiate()
	panel.set_script(ProbePanel)
	page.add_child(panel)
	page.panel = panel as ProbePanel
	panel.trace = page.trace
	var data_scene: PackedScene = load("res://scripts/main/dialogs/finish/view/game_data_layer.tscn")
	var data: Variant = data_scene.instantiate()
	data.set_script(ProbeData)
	panel.add_child(data)
	panel._game_data = data as ProbeData
	data.trace = page.trace

	for badge: ResultBadge in data._badges:
		badge.configure(null, false)
	return page


func _drive(page: ProbePage, result: Dictionary, timed: bool = false) -> void :
	await GameEndFlow.run(page, 30 if timed else 3)
	result["done"] = true


func _wait_until(predicate: Callable, seconds: float = 8.0) -> bool:
	var timeout: SceneTreeTimer = get_tree().create_timer(seconds)
	while not predicate.call() and timeout.time_left > 0.0:
		await get_tree().process_frame
	return bool(predicate.call())


func _suspend(milliseconds: int) -> void :
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	OS.delay_msec(milliseconds)
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)


func _test_presentation(label: String, suspend_ms: int = 0, stats: bool = true, 
		timed: bool = false, repeat: bool = false) -> void :
	var page: ProbePage = _make_page(stats, timed)
	var result: Dictionary = {"done": false}
	var auth_calls: int = int(AuthManager.get("test_requests"))
	var rating_calls: int = _rating_requests()
	_drive(page, result, timed)
	_check( await _wait_until( func() -> bool: return page.panel.cart_shows == 1), label + ": 花车起播")
	_check( not page._complete_shown, label + ": 花车刚出现还未落定")
	if suspend_ms > 0:
		_suspend(suspend_ms)
	if repeat:
		await get_tree().create_timer(0.15).timeout
		_suspend(150)
	var complete: bool = await _wait_until(page.panel.is_entrance_complete)
	_check(complete, label + ": 返回后按钮入场完成")
	_check(page._complete_shown and page.panel.is_reward_entrance_complete(), label + ": 奖励入场完成")
	_check(page.panel.button_shows == 1, label + ": 按钮单次起播")
	_check(page.panel._next_button.modulate.a == 1.0 and not page.panel._next_button.disabled, 
		label + ": Continue可见且可点击")
	_check((page.panel._game_data as ProbeData).shows == (1 if stats else 0), label + ": 统计展示资格")
	_check(int(AuthManager.get("test_requests")) - auth_calls == (0 if timed else 1), label + ": 权限请求不重复")
	if complete:
		page._next_pressed = true
		_check( await _wait_until( func() -> bool: return result["done"]), label + ": 结束流程继续至出口")
		_check(page.exits == 1, label + ": 单次出口")
		_check(_rating_requests() - rating_calls == (0 if timed else 1), label + ": 评分在按钮后执行")
		var expected: Array = ["cart", "data", "button", "exit"] if stats else ["cart", "button", "exit"]
		_check(page.trace == expected, label + ": 后续展示顺序")
	else:

		page.hide()
		await _wait_until( func() -> bool: return result["done"])
	SortLogger.info("FinishBackground: %s %s" % [label, JSON.stringify({
		"complete_shown": page._complete_shown, "button_shows": page.panel.button_shows, 
		"data_shows": (page.panel._game_data as ProbeData).shows, "flow_done": result["done"]})])
	page.free()


func _test_cancel(reason: String, timed: bool = false) -> void :
	var page: ProbePage = _make_page( not timed, timed)
	var result: Dictionary = {"done": false}
	var auth_calls: int = int(AuthManager.get("test_requests"))
	var rating_calls: int = _rating_requests()
	_drive(page, result, timed)
	_check( await _wait_until( func() -> bool: return page.panel.cart_shows == 1), reason + ": 等待中取消")
	match reason:
		"page_hidden": page.hide()
		"panel_hidden": page.panel.hide_panel()
		"new_round", "timed_new_round": page._end_flow_generation += 1
		"panel_replaced": page._complete_panel = null
	_check( await _wait_until( func() -> bool: return result["done"], 1.0), reason + ": 旧流程及时退出")
	await get_tree().create_timer(RewardLayer.APPEAR_DUR + 0.1).timeout
	_check( not page._complete_shown, reason + ": 旧等待不能写新局完成状态")
	_check(page.panel.button_shows == 0 and (page.panel._game_data as ProbeData).shows == 0, 
		reason + ": 不补播旧统计和按钮")
	_check(int(AuthManager.get("test_requests")) == auth_calls and _rating_requests() == rating_calls, 
		reason + ": 不执行旧权限和评分请求")
	_check(page.exits == 0, reason + ": 不导航离开新局")
	if reason == "new_round":
		page._next_pressed = false
		page.panel.trace.clear()
		result["done"] = false
		_drive(page, result)
		_check( await _wait_until(page.panel.is_entrance_complete), "缓存复用: 新一轮正常展示")
		page._next_pressed = true
		_check( await _wait_until( func() -> bool: return result["done"]), "缓存复用: 新一轮完成出口")
		_check(page.panel.cart_shows == 2 and page.panel.button_shows == 1, "缓存复用: 旧轮不能重复起播")
	page.free()


func _test_preparation_cancel(failed: bool) -> void :
	var page: ProbePage = _make_page()
	page.preparation_result = not failed
	page.preparation_waiting = not failed
	var result: Dictionary = {"done": false}
	var auth_calls: int = int(AuthManager.get("test_requests"))
	_drive(page, result)
	if not failed:
		page._end_flow_generation += 1
		page.preparation_released.emit()
	_check( await _wait_until( func() -> bool: return result["done"], 1.0), "准备取消: 结束流程返回")
	_check(page.panel.cart_shows == 0 and page.panel.button_shows == 0, "准备取消: 不创建旧完成页展示")
	_check(int(AuthManager.get("test_requests")) == auth_calls and page.exits == 0, "准备取消: 不执行后续请求或导航")
	page.free()


func _run() -> void :
	Engine.max_fps = 60
	UserState._push_ask_count = 0
	await _test_presentation("long_background", 6500)
	if not "--repro-only" in OS.get_cmdline_user_args():
		await _test_presentation("normal")
		await _test_presentation("short_background", 2000)
		await _test_presentation("repeated_focus", 150, true, false, true)
		await _test_presentation("without_statistics", 0, false)
		await _test_presentation("timed_finish", 6500, false, true)
		for reason: String in ["page_hidden", "panel_hidden", "new_round", "panel_replaced"]:
			await _test_cancel(reason)
		await _test_cancel("timed_new_round", true)
		await _test_preparation_cancel(true)
		await _test_preparation_cancel(false)
	if _failures.is_empty():
		SortLogger.info("FINISH_BACKGROUND PASS")
	else:
		SortLogger.error("FINISH_BACKGROUND FAIL: " + JSON.stringify(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)
