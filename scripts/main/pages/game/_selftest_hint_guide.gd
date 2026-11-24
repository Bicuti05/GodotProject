extends SceneTree

const TRACKER: GDScript = preload("res://scripts/main/pages/game/hint_guide_tracker.gd")
var _failures: Array[String] = []


class HintBoardProbe extends RefCounted:
	var locked: bool = false
	var busy: bool = false
	var over_state: String = ""
	var active_hint: bool = false
	var active_drag: bool = false
	var rope_used: bool = false
	var attribution: int = JuiceSolver.DeathAttribution.UNKNOWN
	var shown: int = 0
	var root_result: Dictionary = {}
	var root_requests: int = 0
	var _level: JuiceLevel = JuiceLevel.from_dict({"id": 99001, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "-|0", "1|1,1"], "incoming": ["x"]})
	var _state: Dictionary = JuiceRules.make_state(_level)

	func level() -> JuiceLevel:
		return _level

	func state() -> Dictionary:
		return _state

	func last_move() -> Dictionary:
		return {}

	func is_busy() -> bool:
		return busy

	func over() -> String:
		return over_state

	func has_active_hint() -> bool:
		return active_hint

	func has_active_drag() -> bool:
		return active_drag

	func has_rope() -> bool:
		return rope_used

	func can_undo() -> bool:
		return true

	func death_attribution() -> int:
		return attribution

	func mark_hint_unwinnable() -> void :
		over_state = "dead"

	func show_hint(hint: Dictionary) -> bool:
		var mv: Dictionary = hint.get("move", {})
		if over_state != "" or mv.is_empty() or active_drag:
			return false
		if JuiceRules.move_info(_state, int(mv["src"]), int(mv["j"]), int(mv["dst"])) <= 0:
			return false
		shown += 1
		active_hint = true
		return true

	func set_hint_lock(on: bool) -> void :
		locked = on

	func root_closed_result() -> Dictionary:
		return root_result.duplicate(true)

	func ensure_root_closed_check() -> bool:
		root_requests += 1
		return false


class HintButtonProbe extends PropBtn:
	var starts: int = 0
	var stops: int = 0
	var glow: bool = false
	var glow_starts: int = 0

	func set_dead_glow(on: bool) -> void :
		if on and not glow:
			glow_starts += 1
		glow = on

	func set_dead_dialog_icon(_on: bool) -> void :
		pass

	func get_unlock_level() -> int:
		return 0

	func play_hint_guide_motion(_loop: bool = true, _preview: bool = false) -> bool:
		starts += 1
		return true

	func stop_hint_guide_motion(_immediate: bool = false) -> void :
		stops += 1


class RootEntryBoardProbe extends HintBoardProbe:
	var events: Array[String] = []
	var tutorial_demo_only: bool = false
	var play_after_dead: bool = false
	var suspended: bool = true
	var unlock_result: bool = false
	var unlock_calls: int = 0

	func can_play_after_dead() -> bool:
		return play_after_dead and over_state == "dead"

	func can_auto_unlock_mystery() -> bool:
		return true

	func auto_unlock_mystery() -> bool:
		unlock_calls += 1
		return unlock_result

	func check_over_after_auto_unlock() -> void :
		events.append("check_over")

	func set_root_adjudication_suspended(value: bool) -> void :
		suspended = value
		events.append("pause" if value else "resume")

	func set_allow_root_swapping_enabled(value: bool) -> void :
		events.append("roots_on" if value else "roots_off")

	func set_play_after_dead_enabled(value: bool) -> void :
		events.append("dead_on" if value else "dead_off")


class EconomyProbe extends RefCounted:
	var free: bool = false
	var coins: int = 0

	func get_current_level() -> int:
		return 100

	func is_prop_early_unlocked(_key: String) -> bool:
		return false

	func is_prop_free_available(_key: String) -> bool:
		return free

	func get_coins() -> int:
		return coins


func _initialize() -> void :
	call_deferred("_run")


func _check(condition: bool, message: String) -> void :
	if not condition:
		_failures.append(message)
		push_error(message)


func _run() -> void :
	var tracker: RefCounted = TRACKER.new()
	_check( not tracker.is_idle(), "New round starts below the idle threshold")
	tracker.advance(14.99, false)
	_check( not tracker.is_idle(), "14.99 seconds must not trigger")
	tracker.advance(60.0, true)
	_check( not tracker.is_idle(), "Background, guides and dialogs do not advance the clock")
	tracker.advance(0.01, false)
	_check(tracker.is_idle(), "15 seconds includes the boundary")
	tracker.advance(100.0, false)
	_check(tracker.is_idle(), "An idle window remains ready while waiting for Hint access")
	tracker.reset()
	_check( not tracker.is_idle(), "Hint click or valid placement starts a new window")
	tracker.advance(15.0, false)
	_check(tracker.is_idle(), "A later idle window reaches the threshold again")
	_check(TRACKER.has_access(true, 0, 0, 300, false), "Unlock gift free use qualifies")
	_check(TRACKER.has_access(false, 1, 0, 300, false), "Hint inventory qualifies")
	_check(TRACKER.has_access(false, 0, 300, 300, false), "Exact Hint coin price qualifies")
	_check( not TRACKER.has_access(false, 0, 299, 300, false), "One coin below Hint price must not qualify")
	_check(TRACKER.has_access(false, 0, 0, 300, true), "Ready reward ad qualifies")
	_check( not TRACKER.has_access(false, 0, 0, 300, false), "No access must not qualify")
	_check( not TRACKER.has_access(false, 0, 0, 0, false), "Invalid zero price must not grant access")
	var probe_script: GDScript = _build_probe_script()
	if probe_script != null:
		await _check_process_lifecycle(probe_script)
		await _check_idle_preflight(probe_script)
		await _check_root_hint_pending(probe_script)
		_check_root_entry_settlement()
		await _check_rope_guidance(probe_script)
		await _check_rope_only_preflight(probe_script)
		_check_rope_access(probe_script)
	if _failures.is_empty():
		print("HINT_GUIDE_SELFTEST PASS")
	else:
		print("HINT_GUIDE_SELFTEST FAIL: ", JSON.stringify(_failures))
	call_deferred("quit", 0 if _failures.is_empty() else 1)



func _build_probe_script() -> GDScript:
	var source: String = FileAccess.get_file_as_string("res://scripts/main/pages/game/juice_game_page.gd")
	var page_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript
	if page_script == null or not page_script.can_instantiate():
		_check(false, "Production game page must compile before building its probe")
		return null
	var opts: Dictionary = page_script.get_script_constant_map()["HINT_OPT"]
	var probe_script: = GDScript.new()
	var body: String = "extends Control\nconst S = preload(\"res://scripts/gameplay/juice_sort/core/juice_solver.gd\")\nconst R = preload(\"res://scripts/gameplay/juice_sort/core/juice_rules.gd\")\nconst ENDLESS_HINT = preload(\"res://scripts/gameplay/juice_sort/core/endless/juice_endless_hint_solver.gd\")\nconst HINT_TASK_NONE: int = -1\nvar _hint_task_id: int = HINT_TASK_NONE\nvar _hint_task_result: Dictionary = {}\nvar _hint_task_key: String = \"\"\nvar _hint_task_auto: bool = false\nvar _hint_task_preflight: bool = false\nvar _root_hint_pending_key: String = \"\"\nvar _hint_task_cancel: Semaphore = null\nvar _hint_task_progress: S.HintProgress = null\nvar _hint_task_version: int = -1\nvar _hint_task_latest: Dictionary = {}\nvar _hint_checked_key: String = \"\"\nvar _hint_cache_key: String = \"\"\nvar _hint_cache: Dictionary = {}\nvar _hint_plan: Array = []\nvar _hint_plan_key: String = \"\"\nvar _hint_plan_col: int = -1\nvar _hint_plan_optimal: bool = false\nvar _hint_plan_win_path: bool = false\nvar _hint_plan_root_necessary: bool = false\nvar _hint_guide_tracker: HintGuideTracker = HintGuideTracker.new()\nvar _hint_guide_checked_key: String = \"\"\nvar _hint_guide_playing: bool = false\nvar _hint_guide_background_paused: bool = false\nvar _hint_guide_skip_frame: bool = false\nvar _hint_guide_unwinnable_key: String = \"\"\nvar _rope_guide_playing: bool = false\nvar _prop_ui: Dictionary = {}\nvar _prop_ad_ready: Dictionary = {}\nvar _complete_prop_enabled: bool = false\nvar _economy = null\nvar rope_access: bool = true\nvar rope_count: int = 0\nvar _board = null\nvar _mystery_guide = null\nvar _endless_controller = null\nvar access: bool = true\nvar suspended: bool = false\nvar charged: int = 0\nvar progress_saves: int = 0\nvar empty_toasts: int = 0\nfunc is_endless() -> bool:\n\treturn false\nfunc _endless_can_use_props() -> bool:\n\treturn true\nfunc _hint_guide_has_access() -> bool:\n\treturn access\nfunc _rope_guide_has_access() -> bool:\n\treturn rope_access and _prop_ui.has(\"rope\") and not _board.has_rope()\nfunc _prop_count(_key: String) -> int:\n\treturn rope_count\nfunc _stop_undo_guide_motion_preview() -> void:\n\tpass #TODO: 本回归不播放撤回预览。\nfunc _teardown_root_swap_guide() -> void:\n\tpass #TODO: 本回归不加载互换教学。\nfunc _hint_guide_is_suspended() -> bool:\n\treturn suspended or _board == null or _board.over() != \"\" or _board.has_active_hint() or _hint_task_id != HINT_TASK_NONE or not _root_hint_pending_key.is_empty()\nfunc _on_mystery_guide_finished() -> void:\n\tpass #TODO: 参数回归不加载问号教学表现。\nfunc _save_progress(_timing: String = \"\") -> void:\n\tprogress_saves += 1\nfunc _prop_tier_ok(_btn: PropBtn) -> bool:\n\treturn access\nfunc _use_prop(_key: String) -> void:\n\tpass #TODO: 本回归不执行付费/广告分支。\nfunc _charge_prop(_key: String, _btn: PropBtn) -> void:\n\tcharged += 1\nfunc _after_prop_applied(_key: String, _was_dead: bool = false) -> void:\n\tpass #TODO: 参数回归不执行埋点和经济写盘。\n"









































































	body += "const HINT_OPT = " + JSON.stringify(opts) + "\n"
	for name: String in ["_hint_solvable", "_hint_state_key", "_hint_try_sync", "_hint_from_plan", 
			"_cache_hint", "_hint_dispatch", "_hint_poll", "_hint_poll_root_search", "_hint_settle", "_show_hint_on_board", 
			"_hint_cancel", "_hint_reap_task", "_hint_release", "_poll_hint_guide", "_stop_hint_guide", "_reset_hint_guide", 
			"_stop_rope_guide", "_clear_hint_guide_motion", "_sync_dead_prop_glows", "_dead_prop_matches_attribution"]:
		body += _function_source(source, name).replace("UserState.", "_economy.")
	body = body.replace("SceneManager.show_toast(tr(\"JUICE_PROP_HINT_EMPTY_TOAST\"))", "empty_toasts += 1")
	body += _function_source(source, "_rope_guide_has_access").replace("UserState.", "_economy.")\
	.replace("func _rope_guide_has_access(", "func _real_rope_guide_has_access(")
	probe_script.source_code = body
	if probe_script.reload() != OK:
		_check(false, "Production polling functions must compile in isolation")
		return null
	return probe_script



func _check_process_lifecycle(probe_script: GDScript) -> void :
	var probe: Control = probe_script.new()
	root.add_child(probe)
	probe.set_process(true)
	probe._hint_poll()
	_check(probe.is_processing(), "No Hint task must keep visible-page processing enabled")
	probe._hint_release()
	_check(probe.is_processing(), "Hint solver release must keep visible-page processing enabled")
	probe.hide()
	probe._hint_release()
	_check( not probe.is_processing(), "Hidden page must stop processing after solver release")
	probe.show()
	var board: = HintBoardProbe.new()
	probe._board = board
	var btn: = HintButtonProbe.new()
	probe._prop_ui = {"hint": {"btn": btn}}
	current_scene = probe
	var scene_manager: Node = root.get_node("SceneManager")

	probe._hint_dispatch()
	var dispatched: int = probe._hint_task_id
	_check(dispatched != -1 and board.locked, "Hint dispatch starts a task and locks the board")
	probe._hint_dispatch()
	_check(probe._hint_task_id == dispatched, "Repeated Hint clicks do not dispatch another task")
	await create_timer(0.16).timeout
	var loading: Node = scene_manager.get_page("loading")
	_check(loading == null or not loading.visible, "Hint never displays Loading after150ms")
	while not WorkerThreadPool.is_task_completed(dispatched):
		await process_frame
	WorkerThreadPool.wait_for_task_completion(dispatched)
	probe._hint_release()
	_check( not board.locked and probe.is_processing(), "Completed Hint unlocks without stopping page polling")
	var cancel: Semaphore = Semaphore.new()
	var finish: Semaphore = Semaphore.new()
	var task: int = WorkerThreadPool.add_task( func() -> void :
		cancel.wait()
		finish.wait())
	probe._hint_task_id = task
	probe._hint_task_cancel = cancel
	board.locked = true
	await create_timer(0.16).timeout
	loading = scene_manager.get_page("loading")
	_check(loading == null or not loading.visible, "Pending Hint also keeps Loading hidden")

	var overlay: Node = scene_manager.show_loading()
	_check(overlay != null and overlay.visible, "Another flow can still display Loading")
	var started: int = Time.get_ticks_msec()
	probe._hint_cancel()
	_check(Time.get_ticks_msec() - started < 50, "Cancel must return without waiting for the worker")
	_check(probe._hint_task_id == -1 and not board.locked, 
		"Cancel releases the task guard and unlocks immediately")
	_check(overlay.visible, "Hint cancellation leaves another flow's Loading unchanged")
	scene_manager.hide_loading()
	finish.post()
	await process_frame
	await process_frame
	probe.free()
	btn.free()


func _wait_hint(probe: Control) -> void :
	var deadline: int = Time.get_ticks_msec() + 3000
	while int(probe.get("_hint_task_id")) >= 0 and Time.get_ticks_msec() < deadline:
		probe.call("_hint_poll")
		await process_frame
	_check(int(probe.get("_hint_task_id")) == -1, "Hint work completes within the test deadline")
	if int(probe.get("_hint_task_id")) >= 0:
		probe.call("_hint_cancel")



func _result_task(probe: Control, hint: Dictionary, reachability: int, key: String = "", preflight: bool = true) -> void :
	probe.set("_hint_task_preflight", preflight)
	probe.set("_hint_task_key", probe.call("_hint_state_key") if key == "" else key)
	probe.set("_hint_task_progress", JuiceSolver.HintProgress.new())
	probe.set("_hint_task_result", {"completed": true, "hint": hint, "reachability": reachability})
	probe.set("_hint_task_id", WorkerThreadPool.add_task( func() -> void : pass))
	await _wait_hint(probe)


func _check_idle_preflight(probe_script: GDScript) -> void :
	var probe: Control = probe_script.new()
	var board: = HintBoardProbe.new()
	var btn: = HintButtonProbe.new()
	probe.set("_board", board)
	probe.set("_prop_ui", {"hint": {"btn": btn}})
	root.add_child(probe)
	probe.call("_poll_hint_guide", 14.99)
	_check(probe.get("_hint_task_id") == -1 and btn.starts == 0, "Below15s neither searches nor animates")
	probe.set("access", false)
	probe.call("_poll_hint_guide", 0.01)
	_check(probe.get("_hint_task_id") == -1, "No tool access does not dispatch preflight")
	probe.set("access", true)
	probe.call("_poll_hint_guide", 0.0)
	var task: int = probe.get("_hint_task_id")
	_check(task >= 0 and probe.get("_hint_task_preflight") and not board.locked and btn.starts == 0, 
		"Idle starts background preflight without locking input or starting motion")
	probe.call("_poll_hint_guide", 1.0)
	_check(probe.get("_hint_task_id") == task, "Pending preflight is not duplicated")
	await _wait_hint(probe)
	var hint: Dictionary = probe.get("_hint_cache")
	_check( not hint.is_empty() and board.shown == 0 and probe.get("charged") == 0, 
		"Preflight stores a real verified Hint without showing a hand or charging")
	probe.call("_poll_hint_guide", 0.0)
	_check(btn.starts == 1 and probe.get("_hint_guide_playing"), "Verified Hint enables idle motion")
	for _i: int in 5:
		probe.call("_poll_hint_guide", 0.0)
	_check(btn.starts == 1 and probe.get("_hint_task_id") == -1, "Looping motion does not rerun Hint search")
	_check(probe.call("_hint_try_sync") == hint and probe.get("_hint_task_id") == -1, 
		"Manual Hint can reuse the exact preflight result synchronously")
	probe.call("_reset_hint_guide", true)
	probe.call("_hint_cancel")

	probe.call("_hint_dispatch", false, true)
	task = probe.get("_hint_task_id")
	probe.call("_hint_dispatch")
	_check(probe.get("_hint_task_id") == task and not probe.get("_hint_task_preflight") and board.locked, 
		"Manual click adopts the pending task and locks input without a duplicate search")
	await _wait_hint(probe)
	_check(board.shown == 1 and probe.get("charged") == 1, "Adopted task shows and charges exactly once")
	board.active_hint = false
	probe.call("_hint_cancel")

	var key: String = probe.call("_hint_state_key")
	probe.set("_hint_guide_checked_key", key)
	await _result_task(probe, {}, JuiceSolver.Reachability.UNKNOWN)
	probe.call("_poll_hint_guide", 15.0)
	_check( not probe.get("_hint_guide_playing") and btn.starts == 1 and probe.get("_hint_task_id") == -1, 
		"No Hint keeps motion silent and does not retry the unchanged board")
	_check(probe.get("_hint_cache_key") == key and (probe.get("_hint_cache") as Dictionary).is_empty(), 
		"Empty preflight result also belongs to its checked board")
	probe.set("_hint_guide_checked_key", "")
	probe.call("_poll_hint_guide", 0.0)
	_check(probe.get("_hint_task_id") == -1, "An existing empty Hint cache suppresses redundant idle search")
	probe.call("_hint_cancel")
	probe.set("_hint_guide_checked_key", key)
	board.busy = true
	await _result_task(probe, hint, JuiceSolver.Reachability.WINNABLE)
	board.busy = false
	probe.call("_poll_hint_guide", 0.0)
	_check(probe.get("_hint_task_id") >= 0 and btn.starts == 1, 
		"A result discarded during board motion may retry after motion ends")
	probe.call("_hint_cancel")

	probe.call("_hint_cancel")
	board._state["caps"][0] += 1
	await _result_task(probe, hint, JuiceSolver.Reachability.WINNABLE, key)
	_check((probe.get("_hint_cache") as Dictionary).is_empty() and board.shown == 1, 
		"Board change discards stale Hint before caching or display")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE, key)
	_check(board.over() == "", "Stale death proof cannot mark a changed board dead")
	_check(probe.get("_hint_guide_unwinnable_key") == "", "Stale death proof cannot grant Rope guidance")
	probe.set("_hint_guide_checked_key", "")
	probe.call("_poll_hint_guide", 0.0)
	_check(probe.get("_hint_task_id") >= 0, "Changed board receives a fresh preflight")
	probe.call("_hint_cancel")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE)
	probe.call("_poll_hint_guide", 15.0)
	_check(board.over() == "" and btn.starts == 1 and probe.get("charged") == 1 and probe.get("progress_saves") == 0, 
		"Even a current death proof stays read only during idle preflight")
	_check((probe.get("_hint_cache") as Dictionary).is_empty() and probe.get("_hint_checked_key") == "", 
		"Preflight death result is saved as empty and does not grant normal Hint eligibility")
	_check((probe.call("_hint_try_sync") as Dictionary).is_empty() and probe.get("_hint_checked_key") == "", 
		"Reading an empty preflight cache cannot bypass the next manual Hint search")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE, "", false)
	_check(board.over() == "dead" and probe.get("charged") == 1 and probe.get("progress_saves") == 1, 
		"Only an actual Hint request may follow the existing death handling")
	probe.free()
	btn.free()


func _check_root_hint_pending(probe_script: GDScript) -> void :
	var probe: Control = probe_script.new()
	var board: = HintBoardProbe.new()
	var btn: = HintButtonProbe.new()
	board._level = JuiceLevel.from_dict({"id": 99002, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "1|1,0", "-|1"], "incoming": []})
	board._state = JuiceRules.make_state(board._level)
	board._state["allow_root_swapping"] = true
	probe.set("_board", board)
	probe.set("_prop_ui", {"hint": {"btn": btn}})
	root.add_child(probe)
	var key: String = probe.call("_hint_state_key")
	probe.call("_hint_dispatch", false, true)
	_check(probe.get("_root_hint_pending_key") == key and probe.get("_hint_task_id") == -1\
	and not board.locked and board.root_requests == 1, "实验预检等待Board同会话且不锁盘、不重复搜索")
	probe.call("_hint_dispatch")
	probe.call("_hint_dispatch")
	_check( not probe.get("_hint_task_preflight") and board.root_requests == 1 and not board.locked, 
		"反复点击接续已有请求，预检升格后仍可继续操作")
	board.root_result = {"completed": true, "status": "UNKNOWN", "continuable": true, "reason": "deadline"}
	probe.call("_hint_poll")
	_check(probe.get("_root_hint_pending_key") == key and probe.get("charged") == 0\
	and probe.get("empty_toasts") == 0 and not board.locked, "短片UNKNOWN继续等待，不报无步骤、不收费")
	board.root_result = {"completed": true, "status": "UNKNOWN", "continuable": false, 
		"recoverable": true, "reason": "state_cap"}
	probe.call("_hint_poll")
	_check(probe.get("_root_hint_pending_key") == key and not board.locked\
	and probe.get("charged") == 0, "Hint只等待同一完整搜索继续，不另建死亡搜索")
	board.root_result = {"completed": true, "status": "EXIT", "continuable": false, 
		"path": [{"src": 1, "j": 1, "dst": 0}]}
	probe.call("_hint_poll")
	_check(probe.get("_root_hint_pending_key") == "" and probe.get("_hint_task_id") >= 0, 
		"Board首盆路径复用到真实Hint回放任务")
	await _wait_hint(probe)
	_check(board.shown == 1 and probe.get("charged") == 1 and not board.locked, 
		"共享首盆路径显示成功后只扣一次，结算解除锁盘")
	board.active_hint = false
	probe.call("_hint_cancel")

	await _result_task(probe, {}, JuiceSolver.Reachability.UNKNOWN, "", false)
	_check(probe.get("empty_toasts") == 0 and probe.get("charged") == 1\
	and probe.get("_hint_cache_key") == "" and probe.get("_root_hint_pending_key") == key, 
		"实验UNKNOWN不缓存无步骤结论、消耗Hint或终止原请求")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE, "", false)
	_check(board.over() == "" and probe.get("progress_saves") == 0\
	and probe.get("_hint_guide_unwinnable_key") == "" and probe.get("empty_toasts") == 0, 
		"实验Hint回放不负责标死或生成独立死亡凭证，死亡只由Board自动证明派发")
	board.root_result = {}
	probe.call("_hint_dispatch")
	board.root_result = {"completed": true, "status": "CLOSED", "continuable": false, "closed": true}
	probe.call("_hint_poll")
	_check(probe.get("_root_hint_pending_key") == "" and board.over() == ""\
	and probe.get("charged") == 1, "共享CLOSED只释放Hint请求，由盘面原死亡链负责派发")
	board.root_result = {"completed": true, "status": "UNKNOWN", "continuable": false, "reason": "state_cap"}
	probe.call("_hint_dispatch")
	probe.call("_hint_poll")
	_check(probe.get("_root_hint_pending_key") == key and probe.get("_hint_task_id") == -1\
	and not board.locked and probe.get("empty_toasts") == 0, "任何预算未知都保留请求，不锁盘、不假装穷尽")
	board.root_result = {}
	probe.call("_hint_dispatch")
	board._state["caps"][0] += 1
	probe.call("_hint_poll")
	_check(probe.get("_root_hint_pending_key") == "" and board.shown == 1 and probe.get("charged") == 1, 
		"等待期间盘面完整指纹改变，旧请求不展示或收费")
	probe.call("_hint_dispatch")
	probe.call("_hint_cancel")
	_check(probe.get("_root_hint_pending_key") == "" and probe.get("_hint_task_key") == "" and not board.locked, 
		"等待期间取消立即清除请求及代次凭证")
	probe.free()
	btn.free()



func _check_root_entry_settlement() -> void :
	var source: String = FileAccess.get_file_as_string("res://scripts/main/pages/game/juice_game_page.gd")
	var script: = GDScript.new()
	var body: String = "extends RefCounted\nconst R = preload(\"res://scripts/gameplay/juice_sort/core/juice_rules.gd\")\nvar _board = null\nvar endless: bool = false\nvar auto_applied: bool = false\nvar auto_enabled: bool = true\nvar dyes: int = 0\nvar _level_model = null\nvar root_enabled: bool = false\nvar play_after_dead_config: bool = false\nfunc is_endless() -> bool:\n\treturn endless\nfunc _root_swapping_enabled_for_level(_level_id: int) -> bool:\n\treturn root_enabled\nfunc _on_board_mystery_auto_unlock_requested() -> bool:\n\t_board.events.append(\"auto_while_paused\" if _board.suspended else \"auto_after_resume\")\n\treturn auto_applied\nfunc _dye_auto() -> void:\n\tdyes += 1\n"



















	body += _function_source(source, "_finish_entrance_mystery_auto_unlock")
	body += _function_source(source, "_configure_root_swapping")\
	.replace("UserState.get_current_level()", "1")\
	.replace("ABManager.allow_root_swapping.should_allow_playing_after_dead(level_id)", "play_after_dead_config")
	body += _function_source(source, "check_mystery_auto_unlock")\
	.replace("ABManager.dye_at_mystery_auto_unlock()", "_dye_auto()")\
	.replace("ABManager.mystery_auto_unlock.is_auto_unlock_enabled()", "auto_enabled")
	script.source_code = body
	if script.reload() != OK:
		_check(false, "正式入场自动结算接缝可隔离编译")
		return
	var probe: RefCounted = script.new()
	var board: = RootEntryBoardProbe.new()
	probe.set("_board", board)
	probe.call("_configure_root_swapping")
	_check(board.suspended and board.events == ["pause", "roots_off", "dead_off"], 
		"旧实验入场取消后切对照也先保持暂停，不在新盘setup前解除并重判旧状态")
	board.events.clear()
	probe.call("_finish_entrance_mystery_auto_unlock", {"aborted": false})
	_check(board.events == ["auto_while_paused", "resume"] and not board.suspended, 
		"没有自动揭示也先检查正式自动机制，再解除有限局首盆判定暂停")
	board.events.clear()
	board.suspended = true
	probe.set("auto_applied", true)
	probe.call("_finish_entrance_mystery_auto_unlock", {"aborted": false})
	_check(board.events == ["auto_while_paused", "check_over", "resume"], 
		"有自动揭示时先正式结算并复核胜负，再解除实验判定暂停")
	board.events.clear()
	board.suspended = true
	probe.set("endless", true)
	probe.set("auto_applied", false)
	probe.call("_finish_entrance_mystery_auto_unlock", {"aborted": false})
	_check(board.suspended and board.events == ["auto_while_paused"], 
		"无尽共同入场收口不早于Controller正式激活解除暂停")
	probe.set("endless", false)
	board.over_state = "dead"
	board.play_after_dead = true
	var ctx: = GameMoveContext.new(null, 1)
	probe.call("check_mystery_auto_unlock", ctx)
	_check(board.unlock_calls == 0 and probe.get("dyes") == 0, 
		"组2死后徒手移动不免费自动揭示，也不重复触发该实验染色")
	board.play_after_dead = false
	board.unlock_result = true
	probe.call("check_mystery_auto_unlock", ctx)
	_check(board.unlock_calls == 1 and ctx.auto_unlock_applied, 
		"对照组原死亡态自动揭示接缝仍可生效，隔离组2新规则")
	ctx.auto_unlock_applied = true
	board.over_state = ""
	board.unlock_result = false
	probe.call("check_mystery_auto_unlock", ctx)
	_check(ctx.auto_unlock_applied, "自动收盆标志不会被没有额外揭示的结果覆盖，基础IQ仍在提交前结算")


func _check_rope_guidance(probe_script: GDScript) -> void :
	var probe: Control = probe_script.new()
	var board: = HintBoardProbe.new()
	var hint_btn: = HintButtonProbe.new()
	var rope_btn: = HintButtonProbe.new()
	probe.set("_board", board)
	probe.set("_economy", EconomyProbe.new())
	probe.set("_prop_ui", {"hint": {"btn": hint_btn}, "rope": {"btn": rope_btn}})
	root.add_child(probe)
	await _result_task(probe, {}, JuiceSolver.Reachability.UNKNOWN)
	probe.call("_poll_hint_guide", 15.0)
	_check( not rope_btn.glow and probe.get("_hint_guide_unwinnable_key") == "", 
		"An empty or timed out result cannot trigger Rope guidance")
	probe.call("_reset_hint_guide", true)
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE)
	var key: String = probe.call("_hint_state_key")
	_check(probe.get("_hint_guide_unwinnable_key") == key, "Current strict death proof is bound to the full board")
	probe.call("_poll_hint_guide", 14.99)
	_check( not rope_btn.glow, "Rope guidance still waits for the 15 second boundary")
	probe.call("_poll_hint_guide", 0.01)
	_check(rope_btn.glow and probe.get("_rope_guide_playing") and hint_btn.starts == 0, 
		"At 15 seconds a proven dead board guides Rope instead of Hint")
	_check(board.over() == "" and not board.locked and probe.get("charged") == 0 and probe.get("progress_saves") == 0, 
		"Rope guidance does not mark death, lock input, charge or save progress")
	probe.call("_sync_dead_prop_glows")
	probe.set("access", false)
	probe.call("_poll_hint_guide", 1.0)
	_check(rope_btn.glow and rope_btn.glow_starts == 1 and probe.get("_hint_task_id") == -1, 
		"Refresh and lost Hint access neither restart Rope nor dispatch another search")
	probe.set("suspended", true)
	probe.call("_poll_hint_guide", 1.0)
	_check( not rope_btn.glow and not probe.get("_rope_guide_playing"), "A dialog suspends Rope guidance immediately")
	probe.set("suspended", false)
	probe.call("_poll_hint_guide", 0.0)
	_check(rope_btn.glow, "Rope resumes from the same proof after the dialog closes")
	probe.set("_hint_guide_background_paused", true)
	probe.call("_poll_hint_guide", 10.0)
	_check( not rope_btn.glow, "Background stops Rope guidance")
	probe.set("_hint_guide_background_paused", false)
	probe.call("_poll_hint_guide", 0.0)
	probe.set("rope_access", false)
	probe.call("_poll_hint_guide", 0.0)
	_check( not rope_btn.glow, "Unavailable Rope stops guidance without falling back to Hint")
	probe.set("rope_access", true)
	board.rope_used = true
	probe.call("_poll_hint_guide", 0.0)
	_check( not rope_btn.glow, "Rope already used in this round is never guided")
	board.rope_used = false
	probe.call("_poll_hint_guide", 0.0)
	probe.call("_clear_hint_guide_motion", true)
	_check( not rope_btn.glow and not probe.get("_rope_guide_playing"), "Page visual cleanup clears Rope guidance")
	probe.call("_poll_hint_guide", 0.0)
	probe.call("_reset_hint_guide", true)
	probe.call("_poll_hint_guide", 0.0)
	_check( not rope_btn.glow, "A valid placement or prop click resets the idle window and stops Rope")
	probe.call("_poll_hint_guide", 15.0)
	probe.call("_hint_cancel")
	_check( not rope_btn.glow and probe.get("_hint_guide_unwinnable_key") == "", "Round cancellation clears motion and death proof")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE)
	board._state["caps"][0] += 1
	probe.call("_poll_hint_guide", 0.0)
	_check( not rope_btn.glow and probe.get("_hint_guide_unwinnable_key") == "", "Changed board invalidates a cached Rope proof")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE, key)
	_check(probe.get("_hint_guide_unwinnable_key") == "", "Delayed old death proof cannot restore Rope guidance")
	await _result_task(probe, {}, JuiceSolver.Reachability.UNWINNABLE)
	probe.call("_poll_hint_guide", 0.0)
	board.over_state = "dead"
	probe.call("_sync_dead_prop_glows")
	probe.call("_reset_hint_guide", true)
	_check(rope_btn.glow and not probe.get("_rope_guide_playing"), "Formal death recommendations survive idle cleanup")
	board.attribution = JuiceSolver.DeathAttribution.LAST_MOVE
	probe.call("_sync_dead_prop_glows")
	_check( not rope_btn.glow and hint_btn.starts == 0, "Formal death attribution still controls which prop is recommended")
	probe.call("_hint_cancel")
	probe.free()
	hint_btn.free()
	rope_btn.free()



func _check_rope_only_preflight(probe_script: GDScript) -> void :
	var probe: Control = probe_script.new()
	var board: = HintBoardProbe.new()
	var hint_btn: = HintButtonProbe.new()
	var rope_btn: = HintButtonProbe.new()
	probe.set("_board", board)
	probe.set("access", false)
	probe.set("rope_count", 1)
	probe.set("_prop_ui", {"hint": {"btn": hint_btn}, "rope": {"btn": rope_btn}})
	root.add_child(probe)
	probe.call("_poll_hint_guide", 15.0)
	_check(probe.get("_hint_task_id") >= 0 and probe.get("_hint_task_preflight") and not board.locked, 
		"Hint unavailable and Rope stock 1 still dispatch idle preflight without locking")
	await _wait_hint(probe)
	probe.call("_poll_hint_guide", 0.0)
	_check( not (probe.get("_hint_cache") as Dictionary).is_empty() and hint_btn.starts == 0 and not rope_btn.glow, 
		"A solvable board caches its Hint but guides neither unavailable Hint nor unnecessary Rope")
	probe.set("access", true)
	probe.call("_poll_hint_guide", 0.0)
	_check(hint_btn.starts == 1 and probe.get("_hint_task_id") == -1, 
		"Restored Hint access reuses the preflight cache without another search")
	probe.call("_hint_cancel")
	probe.call("_reset_hint_guide", true)
	probe.set("access", false)
	board._level = JuiceLevel.from_dict({"id": 99002, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0,1", "1|1,0"]})
	board._state = JuiceRules.make_state(board._level)
	probe.call("_poll_hint_guide", 14.99)
	_check(probe.get("_hint_task_id") == -1 and not rope_btn.glow, 
		"Rope-only preflight still waits until 15 seconds")
	probe.call("_poll_hint_guide", 0.01)
	_check(probe.get("_hint_task_id") >= 0, "A fresh dead board is checked while Hint stays unavailable")
	await _wait_hint(probe)
	probe.call("_poll_hint_guide", 0.0)
	_check(probe.get("_hint_guide_unwinnable_key") == probe.call("_hint_state_key") and rope_btn.glow, 
		"Real preflight proves death and starts Rope guidance without restoring Hint access")
	_check(board.over() == "" and not board.locked and probe.get("charged") == 0 and probe.get("progress_saves") == 0, 
		"Rope-only preflight does not mark death, consume props or save progress")
	for _i: int in 5:
		probe.call("_poll_hint_guide", 0.0)
	_check(rope_btn.glow_starts == 1 and probe.get("_hint_task_id") == -1, 
		"Rope-only guidance neither restarts its motion nor repeats the checked-board search")
	probe.call("_hint_cancel")
	probe.free()
	hint_btn.free()
	rope_btn.free()


func _check_rope_access(probe_script: GDScript) -> void :
	var probe: Control = probe_script.new()
	var board: = HintBoardProbe.new()
	var economy: = EconomyProbe.new()
	var btn: PropBtn = (load("res://scripts/widget/prop_btn/prop_btn.tscn") as PackedScene).instantiate()
	btn.configure(PropBtn.PropType.ROPE)
	root.add_child(btn)
	probe.set("_board", board)
	probe.set("_economy", economy)
	probe.set("_prop_ui", {"rope": {"btn": btn}})
	root.add_child(probe)
	for entry: Dictionary in [
		{"free": true, "count": 0, "coins": 0, "ad": false, "want": true}, 
		{"free": false, "count": 1, "coins": 0, "ad": false, "want": true}, 
		{"free": false, "count": 0, "coins": 1200, "ad": false, "want": true}, 
		{"free": false, "count": 0, "coins": 1199, "ad": false, "want": false}, 
		{"free": false, "count": 0, "coins": 0, "ad": true, "want": true}, 
	]:
		economy.free = bool(entry["free"])
		economy.coins = int(entry["coins"])
		probe.set("rope_count", int(entry["count"]))
		probe.set("_prop_ad_ready", {"rope": bool(entry["ad"])})
		btn.refresh(100, economy.coins, true, economy.free, int(entry["count"]), bool(entry["ad"]), true)
		_check(bool(probe.call("_real_rope_guide_has_access")) == bool(entry["want"]), 
			"Production Rope eligibility matches free, stock, 1200 coin boundary and cached ad: %s" % entry)
	btn.refresh(0, 1200, true, true, 1, true, true)
	_check( not probe.call("_real_rope_guide_has_access"), "Locked Rope cannot be guided")
	btn.refresh(100, 1200, false, true, 1, true, true)
	_check( not probe.call("_real_rope_guide_has_access"), "Disabled Rope cannot be guided")
	btn.refresh(100, 1200, true, true, 1, true, true)
	board.rope_used = true
	_check( not probe.call("_real_rope_guide_has_access"), "Used Rope fails production eligibility")
	board.rope_used = false
	btn.hide()
	_check( not probe.call("_real_rope_guide_has_access"), "Hidden Rope cannot be guided")
	probe.free()
	btn.free()


func _function_source(source: String, name: String) -> String:
	var start: int = source.find("\nfunc " + name + "(")
	if start < 0:
		start = source.find("\nstatic func " + name + "(")
	assert (start >= 0, "Missing production function: " + name)
	var end: int = source.find("\nfunc ", start + 1)
	var next_static: int = source.find("\nstatic func ", start + 1)
	if next_static >= 0 and (end < 0 or next_static < end):
		end = next_static
	return source.substr(start, end - start if end >= 0 else -1)
