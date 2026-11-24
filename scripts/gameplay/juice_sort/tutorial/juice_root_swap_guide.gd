class_name JuiceRootSwapGuide
extends Node




signal finished
signal shown
signal completed

var _board: JuiceBoardView = null
var _layer: JuiceTutorialLayer = null
var _can_play: Callable = Callable()
var _move: Dictionary = {}
var _running: bool = false
var _shown: bool = false
var _owns_layer_demo: bool = false
var _owns_board_demo: bool = false
var _owns_source_highlight: bool = false
var _move_gate: Callable = Callable()
var _grab_gate: Callable = Callable()
var _start_steps: int = -1
var _start_done: int = -1
var _start_level: JuiceLevel = null
var _start_state_key: String = ""


func _init() -> void :
	set_process(false)




static func find_swap(st: Dictionary, order: Array[int], completed_col: int) -> Dictionary:
	if not bool(st.get("allow_root_swapping", false)) or not order.has(completed_col):
		return {}
	var cols: Array = st.get("cols", [])
	var caps: Array = st.get("caps", [])
	var jars: Array = st.get("jars", [])
	var gone: Array = st.get("gone", [])
	if completed_col < 0 or completed_col >= cols.size()\
	or caps.size() != cols.size() or jars.size() != cols.size()\
	or gone.size() != cols.size():
		return {}
	var sc: Array = cols[completed_col]
	if sc.is_empty() or int(caps[completed_col]) <= 0\
	or sc.size() != int(caps[completed_col]):
		return {}
	var color: int = int(sc[0])
	if color < 0 or color >= JuiceLevel.HIDDEN_BASE or int(jars[completed_col]) == color:
		return {}
	for raw: int in sc:
		if raw != color or JuiceLevel.is_hidden(raw) or JuiceLevel.is_frozen(raw):
			return {}

	var rule_state: Dictionary = st.duplicate()
	for dst: int in order:
		if dst == completed_col or dst < 0 or dst >= cols.size()\
		or int(jars[dst]) != color or (cols[dst] as Array).is_empty():
			continue
		if not JuiceRules.is_root_swap(rule_state, completed_col, 0, dst)\
		or JuiceRules.move_info(rule_state, completed_col, 0, dst) <= 0:
			continue
		var swapped_cols: Array = cols.duplicate()
		swapped_cols[dst] = sc
		var collected_state: Dictionary = rule_state.duplicate()
		collected_state["cols"] = swapped_cols
		if JuiceRules.deposit_ready(collected_state, dst) > 0:
			return {"src": completed_col, "j": 0, "dst": dst}
	return {}


func setup(board: JuiceBoardView, layer: JuiceTutorialLayer, 
		can_play: Callable = Callable()) -> void :
	stop()
	_board = board
	_layer = layer
	_can_play = can_play



func start(mv: Dictionary) -> bool:
	stop()
	_shown = false
	if not _instances_valid() or not _is_valid_move(mv) or _board.has_active_drag()\
	or _has_foreign_input_gate():
		return false
	_move = {"src": int(mv.get("src", -1)), "j": 0, "dst": int(mv.get("dst", -1))}
	_start_steps = _board.steps()
	_start_done = int(_board.state().get("done", 0))
	_start_level = _board.level()
	_start_state_key = JuiceRules.state_key(_board.state())
	_move_gate = _allow_move
	_grab_gate = _allow_grab
	_running = true
	_board.set_move_gate(_move_gate)
	_board.set_grab_gate(_grab_gate)
	if not _board.drag_started.is_connected(_on_player_took_over):
		_board.drag_started.connect(_on_player_took_over)
	if not _board.moved.is_connected(_on_board_moved):
		_board.moved.connect(_on_board_moved)
	set_process(true)
	_refresh_demo()
	return true



func stop() -> void :
	_running = false
	set_process(false)
	_release_visuals()
	if is_instance_valid(_board):
		_board.clear_owned_input_gates(_move_gate, _grab_gate)
		if _board.drag_started.is_connected(_on_player_took_over):
			_board.drag_started.disconnect(_on_player_took_over)
		if _board.moved.is_connected(_on_board_moved):
			_board.moved.disconnect(_on_board_moved)
	_move = {}
	_move_gate = Callable()
	_grab_gate = Callable()
	_start_steps = -1
	_start_done = -1
	_start_level = null
	_start_state_key = ""


func is_running() -> bool:
	return _running


func owns_input_gates() -> bool:
	return _running and is_instance_valid(_board) and _move_gate.is_valid()\
	and _grab_gate.is_valid() and _board.has_move_gate(_move_gate)\
	and _board.has_grab_gate(_grab_gate)


func move() -> Dictionary:
	return _move.duplicate()


func _exit_tree() -> void :
	stop()


func _process(_delta: float) -> void :
	if not _running:
		return
	if not _instances_valid() or not owns_input_gates()\
	or _board.level() != _start_level or _board.steps() != _start_steps\
	or JuiceRules.state_key(_board.state()) != _start_state_key\
	or not _is_valid_move(_move):
		_retire()
		return
	_refresh_demo()


func _instances_valid() -> bool:
	return is_instance_valid(_board) and is_instance_valid(_layer)


func _is_valid_move(mv: Dictionary) -> bool:
	if int(mv.get("j", -1)) != 0:
		return false
	var src: int = int(mv.get("src", -1))
	var dst: int = int(mv.get("dst", -1))
	var visible: Array[int] = _board.order()
	if not visible.has(src) or not visible.has(dst):
		return false

	var pair: Array[int] = [src, dst]
	var current: Dictionary = find_swap(_board.state(), pair, src)
	return not current.is_empty() and int(current["dst"]) == dst


func _has_foreign_input_gate() -> bool:
	return (_board.has_move_gate() and ( not _move_gate.is_valid() or not _board.has_move_gate(_move_gate)))\
	or (_board.has_grab_gate() and ( not _grab_gate.is_valid() or not _board.has_grab_gate(_grab_gate)))


func _refresh_demo() -> void :

	if _board.is_busy() or _has_foreign_input_gate()\
	or ( not _can_play.is_null() and ( not _can_play.is_valid() or not bool(_can_play.call()))):
		_release_visuals()
		return
	var src: int = int(_move["src"])
	var dst: int = int(_move["dst"])
	if not _owns_source_highlight:
		_board.set_run_highlight(src, 0, true)
		_owns_source_highlight = true
	if not _owns_layer_demo:
		_layer.set_text(tr("GUIDE_ROOT_SWAP"))
		_owns_layer_demo = true
	if _board.has_active_drag() or _board.is_drop_returning():
		_stop_demo()
		return
	_layer.play_drag_demo(_board.fruit_global_pos(src, 0), 
		_board.fruit_global_pos(dst, 0), _board.rope_bottom_global_y())
	_owns_layer_demo = true
	var head: Vector2 = _layer.demo_head_global() if _layer.is_demo_playing() else Vector2.INF
	if head == Vector2.INF:
		_release_board_demo()
	else:
		_board.set_run_demo_pos(src, 0, head)
		_owns_board_demo = true

		if not _shown and _layer.is_demo_visible():
			_shown = true
			shown.emit()


func _release_board_demo() -> void :
	if _owns_board_demo and is_instance_valid(_board):
		_board.clear_run_demo_pos()
	_owns_board_demo = false


func _stop_demo() -> void :
	if _owns_layer_demo and is_instance_valid(_layer) and _layer.is_demo_playing():
		_layer.stop_drag_demo()
	_release_board_demo()


func _release_visuals() -> void :
	if _owns_layer_demo and is_instance_valid(_layer):
		_layer.stop_drag_demo()
		_layer.hide_text()
	_owns_layer_demo = false
	_release_board_demo()
	if _owns_source_highlight and is_instance_valid(_board):
		_board.set_run_highlight(0, 0, false)
	_owns_source_highlight = false


func _on_player_took_over(_col: int, _j: int) -> void :
	if _running:
		_stop_demo()


func _on_board_moved(steps: int) -> void :
	if not _running or not is_instance_valid(_board):
		return

	if steps == _start_steps and _board.steps() == _start_steps\
	and _board.level() == _start_level and JuiceRules.state_key(_board.state()) == _start_state_key:
		return
	var info: Dictionary = _board.move_feedback_info()
	var expected: bool = bool(info.get("player_drop", false))\
	and bool(info.get("root_swapped", false))\
	and int(info.get("src", -1)) == int(_move["src"])\
	and int(info.get("j", -1)) == 0\
	and int(info.get("dst", -1)) == int(_move["dst"])\
	and steps == _start_steps + 1 and _board.steps() == steps\
	and _board.level() == _start_level\
	and int(_board.state().get("done", 0)) > _start_done
	if not expected:
		_retire()
		return
	stop()
	completed.emit()


func _allow_grab(col: int, j: int) -> bool:
	return _running and col == int(_move["src"]) and j == 0


func _allow_move(src: int, j: int, dst: int) -> bool:
	return _running and src == int(_move["src"]) and j == 0 and dst == int(_move["dst"])


func _retire() -> void :
	if not _running:
		return
	stop()
	finished.emit()
