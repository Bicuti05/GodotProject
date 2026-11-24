class_name LevelPlayTimer
extends RefCounted
























const PAUSE_BACKGROUND: = &"background"
const PAUSE_AD: = &"reward_ad"
const PAUSE_GUIDE_TUTORIAL: = &"guide_tutorial"
const PAUSE_GUIDE_MYSTERY: = &"guide_mystery"
const PAUSE_GUIDE_ROOT_SWAP: = &"guide_root_swap"
const PAUSE_GUIDE_LOCK: = &"guide_lock"
const PAUSE_GUIDE_SUNLIGHT: = &"guide_sunlight"
const PAUSE_GUIDE_PROP_UNLOCK: = &"guide_prop_unlock"


var _level_id: int = 0


var _started: bool = false
var _pauses: Dictionary = {}

var _seg_start: int = -1

var _pending_ms: int = 0

var _elapsed_ms: int = 0
var _tutorial_elapsed_ms: int = 0
var _tutorial_seg_start: int = -1

var _base_ms: int = 0


func level_id() -> int:
	return _level_id











func arm(level_id: int, base_ms: int = 0, wait_first_touch: bool = true) -> void :
	_level_id = level_id
	_base_ms = maxi(base_ms, 0)
	_started = not wait_first_touch
	_seg_start = -1
	_pending_ms = 0
	_elapsed_ms = 0
	_tutorial_elapsed_ms = 0
	_tutorial_seg_start = -1
	if _started:
		_open_segment()



func disarm() -> void :
	_close_segment()
	_level_id = 0
	_started = false




func on_flower_touched() -> void :
	if _level_id <= 0 or _started:
		return
	_started = true
	_open_segment()


func pause(reason: StringName) -> void :
	if _pauses.has(reason):
		return
	_close_segment()
	_pauses[reason] = true
	_open_segment()


func resume(reason: StringName) -> void :
	if not _pauses.has(reason):
		return
	_close_segment()
	_pauses.erase(reason)
	_open_segment()



func take_pending_ms() -> int:
	if _seg_start >= 0:
		var now: int = Time.get_ticks_msec()
		var delta: int = maxi(now - _seg_start, 0)
		_pending_ms += delta
		_elapsed_ms += delta
		_seg_start = now
	var out: int = _pending_ms
	_pending_ms = 0
	return out



func elapsed_ms() -> int:
	return _base_ms + _elapsed_ms + (maxi(Time.get_ticks_msec() - _seg_start, 0)
		if _seg_start >= 0 else 0)



func finish_elapsed_ms() -> int:
	return elapsed_ms() + _tutorial_elapsed_ms + (maxi(Time.get_ticks_msec() - _tutorial_seg_start, 0)
		if _tutorial_seg_start >= 0 else 0)


func is_running() -> bool:
	return _seg_start >= 0


func _open_segment() -> void :
	if _level_id <= 0 or not _started:
		return
	if _pauses.is_empty():
		if _seg_start < 0:
			_seg_start = Time.get_ticks_msec()
	elif _pauses.size() == 1 and _pauses.has(PAUSE_GUIDE_TUTORIAL):
		if _tutorial_seg_start < 0:
			_tutorial_seg_start = Time.get_ticks_msec()


func _close_segment() -> void :
	if _tutorial_seg_start >= 0:
		_tutorial_elapsed_ms += maxi(Time.get_ticks_msec() - _tutorial_seg_start, 0)
		_tutorial_seg_start = -1
	if _seg_start < 0:
		return
	var delta: int = maxi(Time.get_ticks_msec() - _seg_start, 0)
	_pending_ms += delta
	_elapsed_ms += delta
	_seg_start = -1
