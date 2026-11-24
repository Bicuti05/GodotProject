class_name JuiceTutorialDirector
extends Node


























const START_DELAY: = 0.0

const START_TEXT_DELAY: = 0.1

const STEP_GUIDE_DELAY: = 0.5

const ERROR_HOLD: = 1.6
const S: = preload("res://scripts/gameplay/juice_sort/tutorial/juice_tutorial_script.gd")


signal finished

var _board: JuiceBoardView = null
var _layer: JuiceTutorialLayer = null

var _steps: Array[Dictionary] = []
var _step: int = 0
var _completed: bool = false
var _dragging: bool = false
var _free_text_dismissed: bool = false
var _armed: bool = false
var _stopped: bool = false


var _owns_board_demo: bool = false

var _last_normal_text: String = ""
var _start_text_until: float = 0.0
var _error_key: String = ""
var _error_until: float = 0.0

var _was_busy: bool = false
var _guide_pending: bool = false
var _guide_generation: int = 0

var _was_returning: bool = false


var _extra_busy: Callable = Callable()


func setup(board: JuiceBoardView, layer: JuiceTutorialLayer) -> void :
	_board = board
	_layer = layer
	_steps = S.steps_for()











func set_extra_busy_probe(probe: Callable) -> void :
	_extra_busy = probe


func start(step: int = 0) -> void :
	if _board == null or _layer == null:
		push_error("JuiceTutorialDirector: setup() 没调就 start()")
		return
	_guide_generation += 1
	_guide_pending = false
	_step = clampi(step, 0, _steps.size() - 1)
	_completed = false
	_dragging = false
	_free_text_dismissed = false
	_armed = false
	_stopped = false
	_last_normal_text = ""
	_start_text_until = _now() + START_TEXT_DELAY
	_error_key = ""
	_error_until = 0.0
	_was_busy = false
	_was_returning = false
	_board.set_move_gate(_gate)
	_board.set_grab_gate(_grab_gate)
	_connect(_board.moved, _on_moved)
	_connect(_board.move_blocked, _on_move_blocked)
	_connect(_board.drag_started, _on_drag_started)
	_connect(_board.drag_ended, _on_drag_ended)
	_was_busy = false
	_was_returning = false
	set_process(true)

	_armed = START_DELAY <= 0.0
	_refresh()
	if _armed:
		return
	await get_tree().create_timer(START_DELAY).timeout
	if _stopped or not is_inside_tree():
		return
	_armed = true
	_refresh()



func stop() -> void :
	if _stopped:
		return
	_stopped = true
	_start_text_until = 0.0
	_guide_generation += 1
	_guide_pending = false
	set_process(false)
	if _board != null and is_instance_valid(_board):
		_board.set_move_gate()
		_board.set_grab_gate()
		_board.set_run_highlight(0, 0, false)
		_board.set_tutorial_pot_highlight(0, false)
		_board.clear_col_marks()
		_release_board_demo()
		_disconnect(_board.moved, _on_moved)
		_disconnect(_board.move_blocked, _on_move_blocked)
		_disconnect(_board.drag_started, _on_drag_started)
		_disconnect(_board.drag_ended, _on_drag_ended)
	if _layer != null and is_instance_valid(_layer):
		_layer.clear_all()


func current_step() -> int:
	return _step



func enter_free_stage() -> void :
	_guide_generation += 1
	_guide_pending = false
	_step = S.SCRIPTED_STEPS
	_clear_step_visuals()
	_refresh()


func is_running() -> bool:
	return not _stopped







func _gate(src: int, j: int, dst: int) -> bool:
	if _completed or _step >= _steps.size():
		return false
	return _is_free_stage() or S.is_scripted_move(_step, src, j, dst)




func _grab_gate(col: int, j: int) -> bool:
	if _completed or _step >= _steps.size():
		return false
	if _is_free_stage():
		return true
	var accepted: bool = S.is_scripted_grab(_step, col, j)
	if not accepted and col == int(_steps[_step]["src"]) and not _anim_busy():
		_error_key = S.WRONG_GRAB
		_error_until = _now() + ERROR_HOLD
		_refresh()
	return accepted





func _on_drag_started(_col: int, _j: int) -> void :
	_dragging = true
	if _is_free_stage():
		_free_text_dismissed = true
	if _error_key == S.WRONG_GRAB:
		_error_key = ""
	_refresh()


func _on_drag_ended() -> void :
	_dragging = false

	_was_returning = _board_returning()
	_refresh()


func _on_move_blocked(src: int, j: int, dst: int) -> void :

	if _stopped or _completed or _is_free_stage():
		return
	if _step >= 0 and _step < _steps.size():
		var expected: Dictionary = _steps[_step]
		if src == int(expected["src"]) and j == int(expected["j"]) and dst == int(expected["dst"]):
			return
	_error_key = S.why_key(_board.state(), src, j, dst)
	_error_until = _now() + ERROR_HOLD
	_refresh()




func _process(_delta: float) -> void :
	if _stopped:
		set_process(false)
		return
	_push_demo_to_board()
	_refresh_focus()
	var t: float = _now()
	var dirty: = false
	if _start_text_until > 0.0 and t >= _start_text_until:
		_start_text_until = 0.0
		dirty = true



	var busy: bool = _anim_busy()
	if busy != _was_busy:
		_was_busy = busy
		dirty = true
	var returning: bool = _board_returning()
	if returning != _was_returning:
		_was_returning = returning
		dirty = true
	if _error_key != "" and t >= _error_until:
		_error_key = ""
		dirty = true
	if dirty:
		_refresh()




func _push_demo_to_board() -> void :
	if _board == null or not is_instance_valid(_board):
		return

	if _completed or _dragging or _is_free_stage() or _step < 0 or _step >= _steps.size():
		_release_board_demo()
		return
	if _layer == null or not is_instance_valid(_layer) or not _layer.is_demo_playing():
		_release_board_demo()
		return
	var head: Vector2 = _layer.demo_head_global()
	if head == Vector2.INF:
		_release_board_demo()
		return
	var s: Dictionary = _steps[_step]
	var src: int = int(s["src"])
	var j: int = int(s["j"])
	_board.set_run_demo_pos(src, j, head)
	_owns_board_demo = true



func _release_board_demo() -> void :
	if not _owns_board_demo:
		return
	_owns_board_demo = false
	if _board != null and is_instance_valid(_board):
		_board.clear_run_demo_pos()


func _refresh() -> void :
	if _stopped or _layer == null or not is_instance_valid(_layer):
		return
	_refresh_text()
	_refresh_visuals()


func _refresh_text() -> void :
	if _start_text_until > _now():
		_layer.hide_text()
		return
	if _error_key != "":
		_layer.set_text(_tutorial_text(_error_key), true)
		return
	if _completed or (_is_free_stage() and _free_text_dismissed):
		_layer.hide_text()
		return
	var s: Dictionary = _steps[_step]
	var text_key: String = String(s["drag" if _dragging else "idle"])
	var text: String = _tutorial_text(text_key)


	if (_anim_busy() or _guide_pending) and text != _last_normal_text:
		_layer.hide_text()
		return
	_last_normal_text = text
	_layer.set_text(text, false)


func _refresh_visuals() -> void :
	if _is_free_stage():
		_board.set_run_highlight(0, 0, false)
		_board.set_tutorial_pot_highlight(0, false)
		_stop_demo()
		_refresh_focus()
		return






	if _completed or not _armed or _guide_pending or _anim_busy():
		_clear_step_visuals()
		return
	var s: Dictionary = _steps[_step]
	var src: int = int(s["src"])
	var j: int = int(s["j"])
	var dst: int = int(s["dst"])

	_board.set_run_highlight(src, j, true)
	_board.set_tutorial_target_highlight(dst, true)

	_board.set_tutorial_pot_highlight(dst, false)

	var muted_columns: Array[int] = []
	_board.set_col_marks(dst, src, muted_columns, _legal_guide_columns(src, j, dst))







	if _dragging or _board_returning():
		_stop_demo()
		_refresh_focus()
		return
	_refresh_focus()
	_layer.play_drag_demo(
		_board.fruit_global_pos(src, j), 
		_board.drop_global_pos(dst), 
		_board.rope_bottom_global_y())



func _legal_guide_columns(src: int, j: int, dst: int) -> Array[int]:
	var guides: Array[int] = []
	for ci: int in _board.order():
		if ci != src and ci != dst and JuiceRules.move_info(_board.state(), src, j, ci) > 0:
			guides.append(ci)
	return guides



func _refresh_focus() -> void :
	if _layer == null or not is_instance_valid(_layer):
		return
	if _stopped or not _layer.focus_enabled:
		_layer.clear_focus()
		return
	if _completed or _is_free_stage() or _step >= _steps.size() or not _armed or _guide_pending or _anim_busy()\
	or not bool(_steps[_step].get("focus", true)):
		_layer.clear_focus()
		return
	var s: Dictionary = _steps[_step]
	var src: int = int(s.src)
	var dst: int = int(s.dst)
	var j: int = int(s.j)
	var collecting: bool = bool(s.get("collect", false))
	var visuals: Dictionary = _board.tutorial_focus_visuals(src, j, dst, collecting)
	if visuals.is_empty():
		_layer.dim_page()
		return
	visuals["focus_pot"] = collecting
	_layer.set_focus_visuals(visuals)


func _clear_step_visuals() -> void :
	if _board != null and is_instance_valid(_board):
		_board.set_run_highlight(0, 0, false)
		_board.set_tutorial_pot_highlight(0, false)
		_board.clear_col_marks()
	_stop_demo()
	if _layer != null and is_instance_valid(_layer):
		_layer.clear_focus()



func _stop_demo() -> void :
	_release_board_demo()
	if _layer != null and is_instance_valid(_layer):
		_layer.stop_drag_demo()






func _board_returning() -> bool:
	return _board != null and is_instance_valid(_board) and _board.is_drop_returning()


func _anim_busy() -> bool:
	if _board != null and is_instance_valid(_board) and _board.is_busy():
		return true
	return _extra_busy.is_valid() and bool(_extra_busy.call())


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _connect(sig: Signal, target: Callable) -> void :
	if not sig.is_connected(target):
		sig.connect(target)


func _disconnect(sig: Signal, target: Callable) -> void :
	if sig.is_connected(target):
		sig.disconnect(target)


func _is_free_stage() -> bool:
	return _step >= 0 and _step < _steps.size() and bool(_steps[_step].get("free", false))


func _complete_tutorial() -> void :
	if not JuiceRules.is_win(_board.state(), _board.level()):
		SortLogger.error("JuiceTutorialDirector: 教学结束但花盆尚未收齐")
		return
	_completed = true
	_guide_pending = false
	_board.set_entrance_lock(true)
	_layer.hide_text()
	finished.emit()


func _tutorial_text(text_key: String) -> String:
	return tr(text_key)


func _on_moved(_move_count: int) -> void :
	if _stopped or _completed:
		return
	_guide_generation += 1
	var generation: int = _guide_generation
	_error_key = ""
	var was_pending: bool = _guide_pending
	_clear_step_visuals()
	if _is_free_stage():
		_guide_pending = false
		if JuiceRules.is_win(_board.state(), _board.level()):
			_complete_tutorial()
			return
		if was_pending:
			_guide_pending = true
		else:
			_refresh()
			return
	else:

		_guide_pending = true
		_step += 1
		if _step >= _steps.size():
			_complete_tutorial()
			return







	_was_busy = _anim_busy()
	_refresh()
	while _anim_busy() or _board_returning():
		await get_tree().process_frame
		if _stopped or not is_inside_tree() or generation != _guide_generation:
			return
	await get_tree().create_timer(STEP_GUIDE_DELAY).timeout
	if _stopped or not is_inside_tree() or generation != _guide_generation:
		return
	_guide_pending = false
	_refresh()
