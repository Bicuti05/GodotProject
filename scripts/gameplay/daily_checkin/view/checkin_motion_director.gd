extends Node


signal cue_fired(cue_name: String)
signal completed

var generation: = 0
var running: = false
var paused: = false
var _tweens: Array[Tween] = []

func begin() -> void :
	cancel()
	running = true

func cancel() -> void :
	generation += 1
	running = false
	paused = false
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()

func animate() -> Tween:
	_tweens = _tweens.filter( func(item: Tween) -> bool: return item.is_valid())
	var tween: = create_tween().set_ignore_time_scale(true)
	_tweens.append(tween)
	if paused:
		tween.pause()
	return tween

func at(seconds: float, cue_name: String, action: Callable) -> void :
	var current_generation: = generation
	var tween: = animate()
	tween.tween_interval(seconds)
	tween.tween_callback( func() -> void :
		if running and current_generation == generation:
			cue_fired.emit(cue_name)
			action.call()
	)

func finish() -> void :
	if not running:
		return
	running = false
	completed.emit()
	_tweens = _tweens.filter( func(tween: Tween) -> bool: return tween.is_valid() and tween.is_running())

func toggle_pause() -> void :
	if not paused:
		_tweens = _tweens.filter( func(item: Tween) -> bool: return item.is_valid() and item.is_running())
	paused = not paused
	for tween in _tweens:
		if tween.is_valid():
			if paused:
				tween.pause()
			else:
				tween.play()

func _exit_tree() -> void :
	cancel()
