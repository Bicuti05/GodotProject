class_name JuiceEndlessController
extends Node

signal status_changed()
signal time_added(milliseconds: int)
signal round_finished(cups: int, reason: String)
const GENERATOR = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_generator.gd")
const SETTINGS = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_settings.gd")
var board: JuiceBoardView
var session: JuiceEndlessSession
var generation: int = 0
var status: String = ""
var last_result: Dictionary = {}
var _active: bool = false
var _job: Dictionary = {}
var _retired: Array[Dictionary] = []
var _stream: Dictionary = {}
var _attempt: int = 0
var _automatic_retry: bool = false
var _producer_failed: bool = false
var end_reason: String = ""

var _dead_attempt_reason: String = ""
var _elapsed_active_ms: int = 0
var _elapsed_segment_start: int = -1
var _time_started: bool = false
var _round_ready: bool = false
var _time_running: bool = false
var _deadline_ms: int = 0
var _saved_time_ms: int = SETTINGS.INITIAL_TIME_MS
var _credited_done: int = 0
var clock: Callable = Time.get_ticks_msec
var _entry_ready: bool = true
var _pause_reasons: Dictionary = {}
var _archive: Dictionary = {}
const ARCHIVE_LIMIT: int = SETTINGS.HISTORY_LIMIT * (SETTINGS.COLUMNS - 1) + SETTINGS.QUEUE_TARGET


func attach(target: JuiceBoardView) -> void :
	board = target
	board.dead.connect(_on_dead)
	board.moved.connect(_on_board_moved)
	board.settled.connect(_on_board_settled)
	board.cups_changed.connect(_on_board_cups_changed)


func start(run_seed: int, activate_on_queue: bool = true) -> void :
	cancel()
	_active = true
	_entry_ready = activate_on_queue
	_pause_reasons.clear()
	_archive.clear()
	session = JuiceEndlessSession.new(run_seed, true)
	_stream = {"seed": run_seed, "sequence": 0}
	last_result = {}
	_attempt = 0
	_automatic_retry = false
	_producer_failed = false
	end_reason = ""
	_dead_attempt_reason = ""
	_elapsed_active_ms = 0
	_elapsed_segment_start = -1
	_time_started = false
	_round_ready = false
	_time_running = false
	_saved_time_ms = SETTINGS.INITIAL_TIME_MS
	_credited_done = 0
	board.set_process(true)
	board.setup_endless(session, can_apply_board_move)
	board.set_input_enabled(false)
	_set_status("后台从初始参考盘面预生成后续5列")
	_kick_producer()


func cancel() -> void :
	_capture_elapsed_segment()
	if _time_running:
		_saved_time_ms = remaining_ms()
		_time_running = false
	generation += 1
	_active = false
	_retire_job()
	_stream = {}
	if is_instance_valid(board):
		board.set_input_enabled(false)


func _set_status(value: String) -> void :
	status = value
	status_changed.emit()


func _on_dead(reason: String) -> void :
	if not _active or end_reason != "":
		return
	if reason in ["stuck", "loop"] and board.can_play_after_dead():
		_dead_attempt_reason = reason

		_retire_job()
		_activate_if_ready()
		_refresh_status()
		return
	end_reason = reason
	cancel()
	_set_status("%s，本局结束；可以重开或退出" % end_message())
	round_finished.emit(int(session.state["done"]), end_reason)


func end_message() -> String:
	match end_reason:
		"time_up":
			return "时间到"
		"stuck":
			return "没有合法移动"
		"loop":
			return "已陷入封闭循环，无法继续收盆"
	return "无法继续收盆"


func _on_board_moved(_steps: int) -> void :
	if not _active:
		return

	on_flower_touched()
	var done: int = int(session.state["done"])
	var added_ms: int = 0
	var timer_only_paused: bool = _time_started and not _pause_reasons.is_empty() and not _is_input_paused()
	if (_time_running or timer_only_paused) and done > _credited_done:
		added_ms = (done - _credited_done) * SETTINGS.CUP_TIME_MS
		if _time_running:
			_deadline_ms += added_ms
		else:
			_saved_time_ms += added_ms
	_credited_done = done
	if added_ms > 0:
		time_added.emit(added_ms)
	_sync_queue()
	_refresh_input()
	_refresh_status()
	_kick_producer()


func _on_board_settled() -> void :
	if _active:
		_refresh_status()


func _refresh_status() -> void :
	if _dead_attempt_reason != "":
		_set_status("当前无法继续收盆；可继续尝试或撤回，计时继续")
	elif _producer_failed:
		_set_status("后台暂未找到后续补列，缓存 %d/5；可重试生成" % session.incoming.size())
	elif session.incoming.is_empty():
		_set_status("补列缓存暂空，正在后台准备；尚未判死")
	else:
		_set_status("后续缓存 %d/5 列，可继续操作；后台持续准备" % session.incoming.size())


func retry() -> void :
	if not can_retry():
		return
	_attempt += 2
	_automatic_retry = false
	_producer_failed = false
	_kick_producer()


func can_retry() -> bool:
	return _active and _dead_attempt_reason == "" and _producer_failed\
	and _job.is_empty() and session.incoming.size() < SETTINGS.QUEUE_TARGET


static func _work(data: Dictionary, opts: Dictionary, result: Dictionary) -> void :
	opts["now"] = _worker_clock.bind({"yield_at": Time.get_ticks_usec() + 6000})
	result.merge(GENERATOR.next_stream(data, opts))


static func _worker_clock(clock: Dictionary) -> int:
	if Time.get_ticks_usec() >= int(clock["yield_at"]):
		OS.delay_usec(1000)
		clock["yield_at"] = Time.get_ticks_usec() + 6000
	return Time.get_ticks_msec()


func _kick_producer() -> void :
	if not _active or _dead_attempt_reason != "" or not _job.is_empty() or _producer_failed\
	or session.incoming.size() >= SETTINGS.QUEUE_TARGET or _retired.size() >= 4:
		return
	var result: Dictionary = {}
	var cancel_signal: = Semaphore.new()
	var opts: Dictionary = {"cancel": cancel_signal, "attempt": _attempt, 
		"budget_ms": SETTINGS.RETRY_BUDGET_MS if _automatic_retry else SETTINGS.FIRST_BUDGET_MS}

	var task: int = WorkerThreadPool.add_task(_work.bind(_stream.duplicate(true), opts, result))
	_job = {"task": task, "cancel": cancel_signal, "result": result, "generation": generation}


func _poll_producer() -> void :
	if _job.is_empty() or not WorkerThreadPool.is_task_completed(int(_job["task"])):
		return
	var error: Error = WorkerThreadPool.wait_for_task_completion(int(_job["task"]))
	var token: int = int(_job["generation"])
	var result: Dictionary = _job["result"] if error == OK else {"ok": false, "reason": "task_failed"}
	_job = {}
	if not _active or token != generation:
		return
	last_result = result
	if bool(result.get("ok", false)) and JuiceEndlessSession.valid_incoming(result["entry"], int(_stream["sequence"])):
		_archive[int(result["entry"]["sequence"])] = result["entry"].duplicate(true)
		_sync_queue()
		_stream = result["stream"]
		_automatic_retry = false
		_producer_failed = false
		_attempt = 0
		_activate_if_ready()
		SortLogger.info("[EndlessQueue] sequence=%d queue=%d seed=%d score=%.1f refill=%s" % [
			int(result["entry"]["sequence"]), session.incoming.size(), session.seed, 
			float(result["score"]), JSON.stringify(result["entry"])])
		_refresh_status()
	elif not _automatic_retry:
		_automatic_retry = true
		_attempt += 1
	else:
		_producer_failed = true
		_set_status("后台暂未找到后续补列，缓存 %d/5；可重试生成" % session.incoming.size())
	_kick_producer()


func _retire_job() -> void :
	if _job.is_empty():
		return
	(_job["cancel"] as Semaphore).post()
	_retired.append(_job)
	_job = {}


func _process(_delta: float) -> void :
	if _active and _time_running and remaining_ms() <= 0:
		_finish_time_up()
	for i in range(_retired.size() - 1, -1, -1):
		var task: int = int(_retired[i]["task"])
		if WorkerThreadPool.is_task_completed(task):
			WorkerThreadPool.wait_for_task_completion(task)
			_retired.remove_at(i)
	_poll_producer()
	_kick_producer()


func remaining_ms() -> int:
	return maxi(0, _deadline_ms - int(clock.call())) if _time_running else _saved_time_ms



func elapsed_ms() -> int:
	return _elapsed_active_ms + (maxi(0, int(clock.call()) - _elapsed_segment_start) if _elapsed_segment_start >= 0 else 0)


func _capture_elapsed_segment() -> void :
	if _elapsed_segment_start >= 0:
		_elapsed_active_ms += maxi(0, int(clock.call()) - _elapsed_segment_start)
		_elapsed_segment_start = -1


func can_move() -> bool:
	if not _active or not _round_ready or _is_input_paused()\
	or board.over() != "" or _dead_attempt_reason != "":
		return false
	if remaining_ms() <= 0:
		_finish_time_up()
		return false
	return true



func can_operate_dead() -> bool:
	if not _active or not _entry_ready or not _round_ready\
	or _is_input_paused() or not board.can_play_after_dead():
		return false
	if remaining_ms() <= 0:
		_finish_time_up()
		return false
	return true


func can_apply_board_move() -> bool:
	return can_move() or can_operate_dead()


func _finish_time_up() -> void :
	if not _active or end_reason != "":
		return
	end_reason = "time_up"
	_time_running = false
	_saved_time_ms = 0
	cancel()
	board.set_process(false)
	_set_status("时间到，本局结束；可以重开或退出")
	round_finished.emit(int(session.state["done"]), end_reason)


func activate_after_entry() -> void :
	_entry_ready = true
	_activate_if_ready()


func _activate_if_ready() -> void :
	if _active and _entry_ready and ( not session.incoming.is_empty() or board.can_play_after_dead()):
		_round_ready = true
	_start_initial_dead_timer()
	_refresh_input()



func _start_initial_dead_timer() -> void :
	if _entry_ready and _dead_attempt_reason != "" and board.can_play_after_dead():
		on_flower_touched()



func on_flower_touched() -> void :
	if not _active or not _round_ready or _time_started or not _pause_reasons.is_empty():
		return
	_time_started = true
	_time_running = true
	_elapsed_segment_start = int(clock.call())
	_deadline_ms = _elapsed_segment_start + _saved_time_ms
	status_changed.emit()


func _refresh_input() -> void :
	if is_instance_valid(board):
		board.set_input_enabled(_active and _round_ready and not _is_input_paused()\
		and ( not session.incoming.is_empty() or board.can_play_after_dead()))



func _is_input_paused() -> bool:
	for blocks_input: bool in _pause_reasons.values():
		if blocks_input:
			return true
	return false


func pause(reason: StringName, timer_only: bool = false) -> void :
	if not _active or _pause_reasons.has(reason):
		return
	if _time_running:
		_capture_elapsed_segment()
		_saved_time_ms = remaining_ms()
		_time_running = false
	_pause_reasons[reason] = not timer_only
	_refresh_input()
	status_changed.emit()


func resume(reason: StringName) -> void :
	_pause_reasons.erase(reason)
	if _active and _time_started and _pause_reasons.is_empty() and not _time_running:
		_elapsed_segment_start = int(clock.call())
		_deadline_ms = _elapsed_segment_start + _saved_time_ms
		_time_running = true
	_start_initial_dead_timer()
	_refresh_input()
	status_changed.emit()


func _on_board_cups_changed() -> void :
	if not _active or session == null:
		return
	if _dead_attempt_reason != "" and board.over() == "":
		_dead_attempt_reason = ""

	_credited_done = int(session.state["done"])
	_sync_queue()
	_refresh_input()
	_refresh_status()
	_kick_producer()


func _sync_queue() -> void :
	var done: int = int(session.state["done"])
	session.incoming.clear()
	for sequence in range(done, done + SETTINGS.QUEUE_TARGET):
		if not _archive.has(sequence):
			break
		session.incoming.append(_archive[sequence].duplicate(true))
	var floor_done: int = board.endless_undo_floor()
	for sequence: int in _archive.keys():
		if sequence < floor_done:
			_archive.erase(sequence)
	assert (_archive.size() <= ARCHIVE_LIMIT)


func archive_size() -> int:
	return _archive.size()


func _exit_tree() -> void :
	cancel()

	_retired.clear()
