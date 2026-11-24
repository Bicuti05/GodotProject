extends Node
const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")


class ProbePage extends JuiceGamePage:
	var blocked: bool = false
	var hint_dispatches: int = 0
	var hint_shows: int = 0
	var prop_charges: int = 0
	var prop_ads: int = 0
	var progress_saves: int = 0
	func _ready() -> void :
		set_process(false)
	func _process(_delta: float) -> void :
		pass
	func _hint_dispatch(_auto: bool = false, _preflight: bool = false) -> void :
		hint_dispatches += 1
	func _show_hint_on_board(_hint: Dictionary) -> bool:
		hint_shows += 1
		return true
	func _charge_prop(_key: String, _btn: PropBtn) -> void :
		prop_charges += 1
	func _use_prop_via_ad(_key: String) -> void :
		prop_ads += 1
	func _save_progress(_timing: String = "") -> void :
		progress_saves += 1
	func _after_prop_applied(_key: String, _was_dead: bool = false) -> void :
		pass
	func _undo_guide_motion_preview_blocked() -> bool:
		return blocked
	func _ui_button_is_ready(_key: String) -> bool:
		return false
	func _hint_guide_is_suspended() -> bool:
		return _hint_guide_background_paused or blocked
	func _hint_guide_has_access() -> bool:
		return true

class ProbeBoard extends JuiceBoardView:
	var model: JuiceLevel
	var over_state: String = ""
	var undo_steps: Array[int] = []
	var hint_deaths: int = 0
	func _ready() -> void :
		set_process(false)
	func level() -> JuiceLevel:
		return model
	func over() -> String:
		return over_state
	func mark_hint_unwinnable() -> void :
		hint_deaths += 1
		over_state = "dead"
	func undo(back_steps: int = 1) -> bool:
		undo_steps.append(back_steps)
		return true

var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _run() -> void :
	_check(ABManager.find_config("undo_guide") == null, "必死态撤回引导实验不再注册")
	_check(ABManager.find_config("hint_guide") == null, "Hint闲置引导成为默认行为，不再注册实验")
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"Board": ProbeBoard})
	var board: ProbeBoard = page._board as ProbeBoard
	board.model = JuiceLevel.from_dict({"id": UserState.get_current_level(), "capacity": 3, 
		"targetCups": 3, "initial": ["0|2,1", "1|0,0", "2|1,1"], "incoming": ["0|0,2,2", "x"]})
	board.player_operated.connect(page._stop_undo_guide_motion_preview)
	var button: PropBtn = load("res://scripts/widget/prop_btn/prop_btn.tscn").instantiate()
	page.add_child(button)
	button.configure(PropBtn.PropType.UNDO)
	button.refresh(100, 10000, true, false, 1, false, true)
	page._prop_ui = {"undo": {"btn": button}}
	_check( not button.is_undo_guide_motion_playing(), "撤回引导仅由手动预览触发")
	_check( not board.has_signal("undo_guide_requested"), "盘面不再派发自动引导请求")
	await _test_hint_independent_result(page, board)
	_test_safe_return_steps(page, board)

	_start_preview(button)
	board.note_player_operation()
	_check( not button.is_undo_guide_motion_playing(), "盘面操作停止手动预览")
	_start_preview(button)
	page._on_prop_pressed("undo")
	_check( not button.is_undo_guide_motion_playing(), "道具点击停止预览，不要求效果生效")
	_start_preview(button)
	page._on_reset_pressed()
	_check( not button.is_undo_guide_motion_playing(), "点击重开停止预览，不等确认")
	_start_preview(button)
	page._back_btn.disabled = true
	page._on_back_pressed()
	_check( not button.is_undo_guide_motion_playing(), "返回入口先停止预览再检查按钮状态")
	_test_background_guides(page, board, button)
	page.free()
	if _failures.is_empty():
		SortLogger.info("UNDO_GUIDE_PAGE_SELFTEST PASS")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _start_preview(button: PropBtn) -> void :
	_check(button.play_undo_guide_motion(true), "撤回手动预览仍可循环播放")



func _test_hint_independent_result(page: ProbePage, board: ProbeBoard) -> void :
	board._state = JuiceRules.make_state(board.model)
	var button: PropBtn = load("res://scripts/widget/prop_btn/prop_btn.tscn").instantiate()
	page.add_child(button)
	button.configure(PropBtn.PropType.HINT)
	page._prop_ui["hint"] = {"btn": button}
	page._playfield_ready = true
	page._ui_props_ready = true
	for tier: Dictionary in [
		{"free": true, "count": 0, "coins": 0, "ad": false, "state": PropBtn.PropState.FREE}, 
		{"free": false, "count": 1, "coins": 0, "ad": false, "state": PropBtn.PropState.COUNT}, 
		{"free": false, "count": 0, "coins": 10000, "ad": false, "state": PropBtn.PropState.COIN}, 
		{"free": false, "count": 0, "coins": 0, "ad": true, "state": PropBtn.PropState.AD}, 
	]:
		button.refresh(100, tier["coins"], true, tier["free"], tier["count"], tier["ad"], true)
		_check(button.get_business_state() == tier["state"], "Hint回归覆盖真实经济档位")
		board.over_state = ""
		page._hint_cancel()
		page._use_prop("hint")
		_check(board.over_state == "", "Hint点击先求解，不依赖旧预计算结果判死")
	_check(page.hint_dispatches == 4 and page.prop_charges == 0 and page.prop_ads == 0, 
		"各档位先提交Hint自身求解，不提前扣账或进广告")
	button.refresh(100, 10000, true, false, 1, false, true)
	for auto: bool in [false, true]:
		board.over_state = ""
		await _settle_hint_probe(page, {}, auto, false, JuiceSolver.Reachability.UNWINNABLE)
	_check(board.hint_deaths == 2 and page.progress_saves == 2, 
		"手动及自动Hint只用自身无解结论判死并保存")
	_check(page.hint_shows == 0 and page.prop_charges == 0 and page.prop_ads == 0, 
		"Hint自身确认无解时不展示或消费道具")
	board.over_state = ""
	await _settle_hint_probe(page, {}, false, true, JuiceSolver.Reachability.UNWINNABLE)
	_check(board.hint_deaths == 2 and board.over_state == "", "盘面指纹改变后丢弃旧Hint无解结果")
	await _settle_hint_probe(page, {}, true)
	_check(board.hint_deaths == 2 and board.over_state == "", "预算耗尽UNKNOWN不能判死")
	await _settle_hint_probe(page, {"move": {}, "path": []}, false)
	_check(page.hint_shows == 1 and page.prop_charges == 1 and board.over_state == "", 
		"Hint自身取得有效路线后先展示成功再消费")
	page._hint_cancel()
	page._playfield_ready = false
	page._ui_props_ready = false
	page._prop_ui.erase("hint")
	button.free()


func _settle_hint_probe(page: ProbePage, hint: Dictionary, auto: bool, stale: bool = false, 
		reachability: int = JuiceSolver.Reachability.UNKNOWN) -> void :
	page._hint_task_progress = JuiceSolver.HintProgress.new()
	page._hint_task_version = -1
	page._hint_task_latest = {}
	page._hint_task_result = {"completed": true, "hint": hint, 
		"reachability": reachability, "stop_reason": "budget"}
	page._hint_task_key = page._hint_state_key() + (":stale" if stale else "")
	page._hint_task_auto = auto
	page._hint_task_id = WorkerThreadPool.add_task( func() -> void : pass)
	while not WorkerThreadPool.is_task_completed(page._hint_task_id):
		await get_tree().process_frame
	page._hint_settle()
	page.set_process(false)


func _test_safe_return_steps(page: JuiceGamePage, board: ProbeBoard) -> void :
	var config: SortDeadReturnToSafeStateConfig = ABManager.sort_dead_return_to_safe_state
	var previous: int = config.get_debug_override()
	board.set("_safe_return_steps", 3)
	for group: int in [0, 1]:
		config.set_debug_override(group)
		board.over_state = ""
		_check(page._dead_undo_back_steps() == 1, "普通撤回两组均退一步")
		board.over_state = "dead"
		_check(page._dead_undo_back_steps() == (3 if group == 1 else 1), 
			"正式死亡态按实验分组使用独立安全回退结果")
	config.set_debug_override(1)
	board.over_state = "win"
	_check(page._dead_undo_back_steps() == 1, "已通关盘面不使用安全回退步数")
	board.over_state = "dead"
	for steps: int in [-1, 0, 1]:
		board.set("_safe_return_steps", steps)
		_check(page._dead_undo_back_steps() == 1, "未完成/未找到/单步结果沿用单步撤回")
	board.set("_safe_return_steps", 3)
	_check(page._apply_prop("undo") and board.undo_steps == [3], 
		"正式死局撤回仅调用一次并传入多步")
	board.over_state = ""
	_check(page._apply_prop("undo") and board.undo_steps == [3, 1], 
		"普通撤回不使用残留安全回退步数")
	board.set("_safe_return_steps", -1)
	if previous >= 0:
		config.set_debug_override(previous)
	else:
		config.clear_debug_override()


func _test_background_guides(page: JuiceGamePage, board: ProbeBoard, undo_btn: PropBtn) -> void :
	page._back_btn.disabled = false
	_start_preview(undo_btn)
	for notification: int in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		page._notification(notification)
		_check(undo_btn.is_undo_guide_motion_playing(), "后台通知保留撤回手动预览")
	for notification: int in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		page._notification(notification)
		_check(undo_btn.is_undo_guide_motion_playing(), "回前台撤回手动预览继续播放")
	board.note_player_operation()
	_check( not undo_btn.is_undo_guide_motion_playing(), "回前台后玩家操作仍结束手动预览")

	var hint_btn: PropBtn = load("res://scripts/widget/prop_btn/prop_btn.tscn").instantiate()
	page.add_child(hint_btn)
	hint_btn.configure(PropBtn.PropType.HINT)
	hint_btn.refresh(100, 10000, true, false, 1, false, true)
	page._prop_ui["hint"] = {"btn": hint_btn}

	board.model = JuiceLevel.from_dict({"id": UserState.get_current_level(), "capacity": 2, 
		"targetCups": 2, "initial": ["0|0", "-|0", "1|1,1"], "incoming": ["x"]})
	board._state = JuiceRules.make_state(board.model)
	var result: Dictionary = {}
	JuiceSolver.run_checked_hint_task(JuiceRules.clone_state(board._state), board.model, {}, result)
	_check( not (result["hint"] as Dictionary).is_empty(), "后台动效回归具有实际可用Hint")
	page._cache_hint(page._hint_state_key(), result["hint"])
	page._hint_guide_tracker.reset()
	page._hint_guide_tracker.advance(15.0, false)
	page._hint_guide_skip_frame = false
	page._poll_hint_guide(0.0)
	var motion: PropBtn = hint_btn
	var elapsed: float = motion._hint_prompt_time
	_check(page._hint_guide_playing and motion.is_hint_guide_motion_playing(), "Hint默认正式循环已播放")
	for notification: int in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		page._notification(notification)
		page._poll_hint_guide(60.0)
		_check(page._hint_guide_playing and motion.is_hint_guide_motion_playing() and is_equal_approx(motion._hint_prompt_time, elapsed), 
			"后台通知和轮询保留Hint原动效进度")
	for notification: int in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		page._notification(notification)
		page._poll_hint_guide(60.0)
		page._poll_hint_guide(0.0)
		_check(page._hint_guide_playing and motion.is_hint_guide_motion_playing() and is_equal_approx(motion._hint_prompt_time, elapsed), 
			"回前台Hint继续原进度，不重新起播")
	page._on_hint_guide_button_down()
	_check( not motion.is_hint_guide_motion_playing() and not page._hint_guide_tracker.is_idle(), 
		"回前台后点击Hint仍停止动效、重置窗口")
	page._hint_guide_tracker.advance(14.0, false)
	page._notification(NOTIFICATION_APPLICATION_PAUSED)
	page._poll_hint_guide(60.0)
	page._notification(NOTIFICATION_APPLICATION_RESUMED)
	page._poll_hint_guide(60.0)
	_check( not page._hint_guide_tracker.is_idle(), "后台与恢复首帧不累计Hint闲置时间")
	page._hint_guide_tracker.advance(15.0, false)
	page._hint_guide_skip_frame = false
	page._poll_hint_guide(0.0)
	_start_preview(undo_btn)
	page._poll_hint_guide(0.0)
	_check(motion.is_hint_guide_motion_playing() and undo_btn.is_undo_guide_motion_playing(), 
		"撤回手动预览不按已关闭实验抢占 Hint 闲置窗口")
	board.note_player_operation()
	page._reset_hint_guide(true)


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		SortLogger.error(message)
