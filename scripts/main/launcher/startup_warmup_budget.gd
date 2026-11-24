class_name StartupWarmupBudget
extends RefCounted


const SLOW_FRAME_USEC: int = 33334
const RECOVERY_FRAMES: int = 2
const PREPARATION_BUDGET_USEC: int = 2000

var _host: Node
var _active: Callable
var _last_draw_usec: int = 0
var _slow_frame_pending: bool = false
var _closed: bool = false
var _stage: String = ""
var _preparation_started_usec: int = 0


func _init(host: Node, active: Callable) -> void :
	_host = host
	_active = active
	if DisplayServer.get_name() != "headless":
		RenderingServer.frame_post_draw.connect(_on_frame_drawn)


func _on_frame_drawn() -> void :
	var now: int = Time.get_ticks_usec()
	if _last_draw_usec > 0 and now - _last_draw_usec >= SLOW_FRAME_USEC:
		_slow_frame_pending = true
		SortLogger.info("[StartupWarmup] frame_stall stage=%s frame_ms=%.2f" % [
			_stage, (now - _last_draw_usec) / 1000.0])
	_last_draw_usec = now


func is_active() -> bool:
	return not _closed and is_instance_valid(_host) and _host.is_inside_tree()\
	and ( not _active.is_valid() or _active.call())




func begin_preparation(viewport: Variant, stage: String, force_frame: bool = false) -> bool:
	if not is_active() or not is_instance_valid(viewport):
		return false
	_stage = stage
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var now: int = Time.get_ticks_usec()
	if force_frame or _preparation_started_usec == 0 or now - _preparation_started_usec >= PREPARATION_BUDGET_USEC:
		await _wait_frame()
		var recovery_frames: int = RECOVERY_FRAMES if _slow_frame_pending else 0
		_slow_frame_pending = false
		for i: int in recovery_frames:
			if not is_active() or not is_instance_valid(viewport):
				return false
			await _wait_frame()
		_preparation_started_usec = Time.get_ticks_usec()
	return is_active() and is_instance_valid(viewport)



func begin_batch(viewport: Variant, stage: String) -> bool:
	if not is_active() or not is_instance_valid(viewport):
		return false
	_stage = stage
	_preparation_started_usec = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	await _wait_frame()
	var recovery_frames: int = RECOVERY_FRAMES if _slow_frame_pending else 0
	_slow_frame_pending = false
	for i: int in recovery_frames:
		if not is_active() or not is_instance_valid(viewport):
			return false
		await _wait_frame()
	if not is_active() or not is_instance_valid(viewport):
		return false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return true


func _wait_frame() -> void :
	if not is_active():
		return
	if DisplayServer.get_name() == "headless":
		await _host.get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


func close() -> void :
	_closed = true
	if RenderingServer.frame_post_draw.is_connected(_on_frame_drawn):
		RenderingServer.frame_post_draw.disconnect(_on_frame_drawn)
