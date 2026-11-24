extends Node
const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")


class ProbePage extends JuiceGamePage:
	func _ready() -> void :
		set_process(false)

class ProbeAB extends "res://scripts/frame/abtest/ab_manager.gd":
	var reads: int = 0
	var int_reads: int = 0
	var dyes: int = 0
	func get_ab_string(_key: String, fallback: String = "") -> String:
		reads += 1
		return fallback
	func get_ab_int(_key: String, fallback: int = 0) -> int:
		int_reads += 1
		return fallback
	func dye_ab(_key: String) -> void :
		dyes += 1

var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _run() -> void :

	ABManager.set_script(ProbeAB)
	ABManager._register_configs()
	var sdk_node: Node = ABManager
	var sdk: ProbeAB = sdk_node as ProbeAB
	var page: JuiceGamePage = load("res://scripts/main/pages/game/juice_game_page.tscn").instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page)
	var board: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	page.add_child(board)
	page._board = board
	board.size = Vector2(1080, 2340)
	var step: = ValidDropStep.new()
	for sdk_ready: bool in [false, true]:
		sdk._is_init_done = sdk_ready
		_setup_board(board)
		_drop(step, board, 0, 0, 1)
		_check( not board._connection_pending.is_empty(), "SDK 就绪与否均默认排队普通连接反馈")
		board._clear_all_burst_state()

		_setup_board(board, true)
		_drop(step, board, 0, 0, 1)
		_check( not board._beats.is_empty(), "直接收集正常排队整列完成动画")
		_check(board._connection_pending.is_empty() and board._connection_effects.is_empty(), 
			"直接收集只播整列完成，不叠加连接反馈")

	_setup_board(board)
	_drop(step, board, 0, 0, 3)
	_check(board._connection_pending.is_empty(), "成功移到空绳不播放双花连接反馈")
	_setup_board(board)
	_drop(step, board, 0, 0, 2)
	_check(board._connection_pending.is_empty(), "异色失败不播放连接反馈")
	_setup_board(board, true, "1")
	_drop(step, board, 0, 0, 1)
	_check( not board._connection_pending.is_empty(), "满列但不匹配目标盆仍播放连接")
	board._clear_all_burst_state()
	_setup_board(board)
	var cancelled: = JuiceDropContext.new(board, 0, 0, 1)
	cancelled.handled = true
	cancelled.outcome = JuiceDropContext.Outcome.VALID
	step.run(cancelled)
	_check(board._connection_pending.is_empty(), "已取消松手不排队连接反馈")
	_check(sdk.reads == 0 and sdk.int_reads == 0 and sdk.dyes == 0, 
		"默认连接反馈不读取 AB 分组、不染色")

	for task_field: String in ["_closed_task_id", "_challenge_task_id"]:
		var task_id: int = int(board.get(task_field))
		if task_id >= 0:
			WorkerThreadPool.wait_for_task_completion(task_id)
			board.set(task_field, -1)
	page.free()
	if _failures.is_empty():
		SortLogger.info("LINK_ANIMATION_SELFTEST PASS")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _setup_board(board: JuiceBoardView, full: bool = false, jar: String = "0") -> void :
	board.setup(JuiceLevel.from_dict({"id": 98120, "capacity": 4, "targetCups": 3, 
		"initial": ["-|0", jar + ("|0,0,0" if full else "|0"), "1|1", "2|"], "incoming": []}))


func _drop(step: ValidDropStep, board: JuiceBoardView, src: int, j: int, dst: int) -> void :
	var ctx: = JuiceDropContext.new(board, src, j, dst)
	ctx.outcome = JuiceDropContext.Outcome.VALID
	step.run(ctx)


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		SortLogger.error(message)
