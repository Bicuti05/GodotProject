extends SceneTree

const TIMER_SCRIPT: = preload("res://scripts/main/pages/game/level_play_timer.gd")


func _initialize() -> void :
	call_deferred("_run")



func _advance_segment(timer: Variant, field: String) -> void :
	assert (int(timer.get(field)) >= 0 and Time.get_ticks_msec() > 0)
	timer.set(field, Time.get_ticks_msec() - 1)


func _run() -> void :
	var timer: Variant = TIMER_SCRIPT.new()
	timer.arm(1)
	timer.pause(timer.PAUSE_GUIDE_TUTORIAL)
	assert (timer.finish_elapsed_ms() == 0)
	assert (timer._tutorial_seg_start == -1)
	timer.on_flower_touched()

	_advance_segment(timer, "_tutorial_seg_start")
	assert (timer.finish_elapsed_ms() >= 1)
	assert (timer.elapsed_ms() == 0 and timer.take_pending_ms() == 0)
	timer.pause(timer.PAUSE_BACKGROUND)
	var frozen_ms: int = timer.finish_elapsed_ms()
	assert (timer._tutorial_seg_start == -1)
	await create_timer(0.02).timeout
	assert (timer.finish_elapsed_ms() == frozen_ms)
	timer.pause(timer.PAUSE_AD)
	timer.resume(timer.PAUSE_BACKGROUND)
	assert (timer._tutorial_seg_start == -1)
	timer.resume(timer.PAUSE_AD)
	assert (timer._tutorial_seg_start >= 0)
	_advance_segment(timer, "_tutorial_seg_start")
	timer.pause(timer.PAUSE_GUIDE_MYSTERY)
	assert (timer.finish_elapsed_ms() >= frozen_ms + 1)
	assert (timer._tutorial_seg_start == -1)
	timer.resume(timer.PAUSE_GUIDE_MYSTERY)
	_advance_segment(timer, "_tutorial_seg_start")
	timer.resume(timer.PAUSE_GUIDE_TUTORIAL)
	var tutorial_ms: int = timer._tutorial_elapsed_ms
	assert (tutorial_ms >= frozen_ms + 2)
	assert (timer._tutorial_seg_start == -1 and timer.is_running())

	_advance_segment(timer, "_seg_start")
	timer.disarm()
	assert (timer.elapsed_ms() >= 1)
	assert (timer.finish_elapsed_ms() == timer.elapsed_ms() + tutorial_ms)
	assert (timer.take_pending_ms() == timer.elapsed_ms())
	assert (timer.take_pending_ms() == 0)
	frozen_ms = timer.finish_elapsed_ms()
	await create_timer(0.02).timeout
	assert (timer.finish_elapsed_ms() == frozen_ms)

	timer.arm(2, 5000, false)
	timer.pause(timer.PAUSE_GUIDE_LOCK)
	assert (timer.finish_elapsed_ms() == timer.elapsed_ms())
	assert (timer.finish_elapsed_ms() >= 5000 and timer.finish_elapsed_ms() < 6000)
	timer.resume(timer.PAUSE_GUIDE_LOCK)
	timer.resume(timer.PAUSE_GUIDE_LOCK)
	_advance_segment(timer, "_seg_start")
	timer.disarm()
	assert (timer.finish_elapsed_ms() == timer.elapsed_ms() and timer.elapsed_ms() >= 5001)
	timer.arm(1)
	assert (timer.finish_elapsed_ms() == 0 and not timer.is_running())
	print("LEVEL_PLAY_TIMER_SELFTEST PASS")
	quit()
