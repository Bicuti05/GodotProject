class_name JuiceLegacyTutorialDirector
extends Node


























const START_DELAY: = 0.0

const ERROR_HOLD: = 1.6

const FREE_BAR_HOLD: = 1.5
const S: = preload("res://scripts/gameplay/juice_sort/tutorial/legacy/juice_legacy_tutorial_script.gd")


signal finished
signal active_rule_changed(index: int)

const STEP_RULES: Array[int] = [0, 1, 2, 2]
var _rules_mode: bool = false
var _shown_rule: int = -1

var _board: JuiceBoardView = null
var _layer: JuiceLegacyTutorialLayer = null

var _steps: Array[Dictionary] = []
var _step: int = 0
var _free: bool = false
var _dragging: bool = false
var _armed: bool = false
var _stopped: bool = false


var _owns_board_demo: bool = false

var _error_key: String = ""
var _error_until: float = 0.0
var _free_bar_until: float = 0.0
var _free_bar_expired: bool = false

var _was_busy: bool = false

var _was_returning: bool = false


var _extra_busy: Callable = Callable()


func setup(board: JuiceBoardView, layer: JuiceLegacyTutorialLayer) -> void :
	_board = board
	_layer = layer
	_steps = S.STEPS.duplicate(true)


func set_rules_mode(enabled: bool) -> void :
	_rules_mode = enabled
	_shown_rule = -1


func _show_rule(index: int) -> void :
	if _shown_rule == index:
		return
	_shown_rule = index
	active_rule_changed.emit(index)











func set_extra_busy_probe(probe: Callable) -> void :
	_extra_busy = probe


func start() -> void :
	if _board == null or _layer == null:
		SortLogger.error("JuiceLegacyTutorialDirector: setup() 没调就 start()")
		return
	_step = 0
	_free = false
	_dragging = false
	_armed = false
	_stopped = false
	_error_key = ""
	_error_until = 0.0
	_free_bar_expired = false
	_was_busy = false
	_was_returning = false
	_board.set_move_gate(_gate)
	_board.set_grab_gate(_grab_gate)
	_connect(_board.moved, _on_moved)
	_connect(_board.move_blocked, _on_move_blocked)
	_connect(_board.drag_started, _on_drag_started)
	_connect(_board.drag_ended, _on_drag_ended)
	_connect(_board.won, _on_won)
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
	_show_rule(-1)
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
		_disconnect(_board.won, _on_won)
	if _layer != null and is_instance_valid(_layer):
		_layer.clear_all()


func is_running() -> bool:
	return not _stopped







func _gate(src: int, j: int, dst: int) -> bool:
	if _free or _step >= _steps.size():
		return true
	return S.is_scripted_move(_step, src, j, dst)




func _grab_gate(col: int, j: int) -> bool:
	if _free or _step >= _steps.size():
		return true
	var accepted: bool = S.is_scripted_grab(_step, col, j)
	if not accepted and col == int(_steps[_step]["src"]) and not _anim_busy():
		_error_key = S.WRONG_GRAB
		_error_until = _now() + ERROR_HOLD
		_refresh()
	return accepted





func _on_drag_started(_col: int, _j: int) -> void :
	_dragging = true
	if _error_key == S.WRONG_GRAB:
		_error_key = ""
	_refresh()


func _on_drag_ended() -> void :
	_dragging = false

	_was_returning = _board_returning()
	_refresh()


func _on_move_blocked(src: int, j: int, dst: int) -> void :

	if _stopped or _free:
		return
	if _step >= 0 and _step < _steps.size():
		var expected: Dictionary = _steps[_step]
		if src == int(expected["src"]) and j == int(expected["j"]) and dst == int(expected["dst"]):
			return
	_error_key = S.why_key(_board.state(), src, j, dst)
	_error_until = _now() + ERROR_HOLD
	_refresh()


func _on_won() -> void :


	stop()
	finished.emit()




func _process(_delta: float) -> void :
	if _stopped:
		set_process(false)
		return
	_push_demo_to_board()
	var t: float = _now()
	var dirty: = false





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
	if _free and not _free_bar_expired and t >= _free_bar_until:
		_free_bar_expired = true
		dirty = true
	if dirty:
		_refresh()




func _push_demo_to_board() -> void :
	if _board == null or not is_instance_valid(_board):
		return

	if _free and _board.has_active_hint():
		return



	if _free or _dragging or _step < 0 or _step >= _steps.size():
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
	if _rules_mode:
		_layer.hide_text()
		if _free:
			_show_rule(-1)
		elif not _anim_busy():
			_show_rule(STEP_RULES[_step])
		return
	if _error_key != "":
		_layer.set_text(_tutorial_text(_error_key), true)
		return





	if _anim_busy():
		_layer.hide_text()
		return
	if _free:
		if _free_bar_expired:
			_layer.hide_text()
		else:
			_layer.set_text(_tutorial_text(S.FREE_DRAG if _dragging else S.FREE_IDLE), false)
		return
	var s: Dictionary = _steps[_step]
	_layer.set_text(_tutorial_text(String(s["drag" if _dragging else "idle"])), false)


func _refresh_visuals() -> void :






	if _free or not _armed or _anim_busy():
		_clear_step_visuals()
		return
	var s: Dictionary = _steps[_step]
	var src: int = int(s["src"])
	var j: int = int(s["j"])
	var dst: int = int(s["dst"])

	_board.set_run_highlight(src, j, true)

	_board.set_tutorial_pot_highlight(dst, String(s["idle"]) == "JUICE_TUTOR_STEP2")


	var errors: Array[int] = []
	for ci: int in _board.order():
		if ci != src and ci != dst:
			errors.append(ci)
	_board.set_col_marks(dst, src, errors)







	if _dragging or _board_returning():
		_stop_demo()
		return
	_layer.play_drag_demo(
		_board.fruit_global_pos(src, j), 
		_board.drop_global_pos(dst), 
		_board.rope_bottom_global_y())


func _clear_step_visuals() -> void :
	if _board != null and is_instance_valid(_board):
		_board.set_run_highlight(0, 0, false)
		_board.set_tutorial_pot_highlight(0, false)


		if not _free:
			_board.clear_col_marks()
	_stop_demo()



func _stop_demo() -> void :
	_release_board_demo()
	if _layer != null and is_instance_valid(_layer):
		_layer.stop_drag_demo()


func _enter_free() -> void :
	_free = true
	_free_bar_until = _now() + FREE_BAR_HOLD
	_free_bar_expired = false
	if _board != null and is_instance_valid(_board):
		_board.set_move_gate()
	_refresh()






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


func _tutorial_text(text_key: String) -> String:
	return tr(text_key)


func _on_moved(_move_count: int) -> void :
	if _free:
		return

	_step += 1
	_error_key = ""
	_clear_step_visuals()
	if _step >= _steps.size():
		_enter_free()
		return







	if _anim_busy():

		_was_busy = true
		_refresh()
		var deadline: float = _now() + 3.0
		while _anim_busy() and _now() < deadline:
			await get_tree().process_frame
			if _stopped or not is_inside_tree():
				return
	_refresh()
