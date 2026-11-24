class_name JuiceComboFrequencyTracker
extends RefCounted


var _capacity: int = 0
var _target_cups: int = 0
var _last_done: int = 0
var _feedback_count: int = 0
var _remaining_skip: int = 0
var _random_skip: Callable



func _init(random_skip: Callable = Callable()) -> void :
	_random_skip = random_skip



func reset(capacity: int, target_cups: int, done: int = 0) -> void :
	_capacity = capacity
	_target_cups = target_cups
	_last_done = done
	_feedback_count = 0
	_remaining_skip = _draw_skip() if done > 0 else 0



func sync_done(done: int) -> void :
	_last_done = done


func on_move(done: int) -> Array[int]:
	var feedbacks: Array[int] = []
	if done <= _last_done:
		return feedbacks
	for cup_done: int in range(_last_done + 1, done + 1):
		var first_cup: bool = cup_done == 1 and _feedback_count == 0
		var last_cup: bool = cup_done == _target_cups
		if first_cup or last_cup or _remaining_skip == 0:
			_feedback_count += 1
			feedbacks.append(_feedback_count)
			_remaining_skip = _draw_skip()
		else:
			_remaining_skip -= 1
	_last_done = done
	return feedbacks


func _draw_skip() -> int:
	if _capacity >= 6:
		return 2
	return int(_random_skip.call()) if _random_skip.is_valid() else randi_range(2, 3)
