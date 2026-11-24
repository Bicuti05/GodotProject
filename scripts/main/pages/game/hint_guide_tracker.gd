class_name HintGuideTracker
extends RefCounted


const IDLE_SEC: float = 15.0

var _idle_sec: float = 0.0


func reset() -> void :
	_idle_sec = 0.0


func advance(delta: float, paused: bool) -> void :
	if not paused:
		_idle_sec = minf(_idle_sec + delta, IDLE_SEC)


func is_idle() -> bool:
	return _idle_sec >= IDLE_SEC



static func has_access(free_available: bool, count: int, coins: int, price: int, ad_ready: bool) -> bool:
	return free_available or count > 0 or (price > 0 and coins >= price) or ad_ready
