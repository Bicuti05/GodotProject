class_name JuiceMysteryGuide
extends Node


























signal finished

const GUIDE_TEXT_KEY: = "JUICE_TUTOR_MYSTERY_REVEAL"

var _board: JuiceBoardView = null
var _layer: JuiceTutorialLayer = null

var _src: int = -1
var _j: int = -1
var _dst: int = -1
var _stopped: bool = false
var _demo_paused: bool = false











static func find_reveal_move(st: Dictionary, order: Array[int]) -> Dictionary:
	var cols: Array = st.get("cols", []) as Array
	for src: int in order:
		if src < 0 or src >= cols.size():
			continue
		var sc: Array = cols[src] as Array
		for i: int in range(sc.size() - 2, -1, -1):
			if not JuiceLevel.is_hidden(int(sc[i])):
				continue
			var j: int = i + 1
			for dst: int in order:
				if dst == src:
					continue
				if JuiceRules.move_info(st, src, j, dst) > 0:
					return {"src": src, "j": j, "dst": dst}
	return {}




func setup(board: JuiceBoardView, layer: JuiceTutorialLayer) -> void :
	_board = board
	_layer = layer




func start() -> bool:
	if _board == null or _layer == null:
		push_error("JuiceMysteryGuide: setup() 没调就 start()")
		return false
	var mv: Dictionary = find_reveal_move(_board.state(), _board.order())
	if mv.is_empty():
		return false
	_src = int(mv["src"])
	_j = int(mv["j"])
	_dst = int(mv["dst"])
	_stopped = false
	_demo_paused = false
	_connect(_board.drag_started, _on_player_took_over)
	_connect(_board.moved, _on_board_moved)
	set_process(true)

	_layer.set_text(tr(GUIDE_TEXT_KEY), false)
	_board.set_run_highlight(_src, _j, true)
	_layer.play_drag_demo(
		_board.fruit_global_pos(_src, _j), 
		_board.drop_global_pos(_dst), 
		_board.rope_bottom_global_y())
	return true



func stop() -> void :
	if _stopped:
		return
	_stopped = true
	set_process(false)
	if _board != null and is_instance_valid(_board):
		_board.set_run_highlight(0, 0, false)
		_board.clear_run_demo_pos()
		_disconnect(_board.drag_started, _on_player_took_over)
		_disconnect(_board.moved, _on_board_moved)
	if _layer != null and is_instance_valid(_layer):
		_layer.clear_all()


func is_running() -> bool:
	return not _stopped





func _on_player_took_over(_col: int, _j: int) -> void :
	_retire()




func _on_board_moved(_steps: int) -> void :
	_retire()


func _retire() -> void :
	if _stopped:
		return
	stop()
	finished.emit()




func _process(_delta: float) -> void :
	if _stopped or not is_instance_valid(_board) or not is_instance_valid(_layer):
		return


	if _board.is_busy():
		if not _demo_paused:
			_demo_paused = true
			_layer.stop_drag_demo()
			_board.clear_run_demo_pos()
		return
	if _demo_paused:
		_demo_paused = false
		_board.set_run_highlight(_src, _j, true)
	_layer.play_drag_demo(
		_board.fruit_global_pos(_src, _j), 
		_board.drop_global_pos(_dst), 
		_board.rope_bottom_global_y())
	_push_demo_to_board()




func _push_demo_to_board() -> void :
	if _board == null or not is_instance_valid(_board):
		return
	if _stopped or _layer == null or not is_instance_valid(_layer)\
	or not _layer.is_demo_playing():
		_board.clear_run_demo_pos()
		return
	var head: Vector2 = _layer.demo_head_global()
	if head == Vector2.INF:
		_board.clear_run_demo_pos()
		return
	_board.set_run_demo_pos(_src, _j, head)




func _connect(sig: Signal, target: Callable) -> void :
	if not sig.is_connected(target):
		sig.connect(target)


func _disconnect(sig: Signal, target: Callable) -> void :
	if sig.is_connected(target):
		sig.disconnect(target)
