class_name JuiceComboTracker
extends RefCounted



const TIME_WINDOW_MS: int = 15000

var _window_steps: int = 0
var _last_step: int = 0
var _last_done: int = 0
var _last_cup_step: int = -1
var _last_cup_time_ms: int = -1
var _streak: int = 0



func reset(rows: int, difficulty: int, steps: int, done: int) -> void :
	_window_steps = rows + 5 + difficulty
	_last_step = steps
	_last_done = done
	_last_cup_step = -1
	_last_cup_time_ms = -1
	_streak = 0



func sync_done(done: int) -> void :
	_last_done = done



func on_move(steps: int, done: int, elapsed_ms: int) -> Array[int]:
	var combos: Array[int] = []
	if steps <= _last_step or done < _last_done:
		return combos
	var new_cups: int = done - _last_done
	_last_step = steps
	_last_done = done
	if new_cups == 0:

		return combos
	for _cup in new_cups:
		if _last_cup_step >= 0 and (steps - _last_cup_step <= _window_steps\
		or elapsed_ms - _last_cup_time_ms <= TIME_WINDOW_MS):
			_streak += 1
		else:
			_streak = 1
		_last_cup_step = steps
		_last_cup_time_ms = elapsed_ms
		if _streak >= 2:
			combos.append(_streak)
	return combos
