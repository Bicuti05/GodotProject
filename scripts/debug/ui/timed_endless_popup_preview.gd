extends PageScene


@onready var _start: GameStartBanner = $Views / Start
@onready var _finish: TimedEndlessRewardDialog = $Views / Finish
@onready var _clock_flight: TimedClockFlight = $Views / ClockFlight
@onready var _clock_target: TextureRect = $Views / ClockTarget
@onready var _panel: PanelContainer = $Panel
@onready var _demo_claim: Button = $Panel / Margin / Rows / DemoClaim
@onready var _status: Label = $Panel / Margin / Rows / Status
var _source_page: Variant = null
var _opened: bool = false
var _previous_paused: bool = false
var _generation: int = 0
var _mode: String = "start"
var _layout_queued: bool = false
var _audio_enabled: bool = true
var _alarm_hidden: bool = false
var _alarm_alpha: float = 1.0
var _has_target: bool = false
var _demo_collecting: bool = false


func _ready() -> void :
	get_viewport().size_changed.connect(_queue_layout)
	_panel.minimum_size_changed.connect(_queue_layout)

	_ignore_input(_finish)
	hide()
	_queue_layout()


func _on_show(params: Dictionary = {}) -> void :
	if OS.has_feature("rel"):
		hide()
		return
	if not _opened:
		_previous_paused = get_tree().paused
		_source_page = SceneManager.get_page("game")
		if is_instance_valid(_source_page) and _source_page.visible:
			if _source_page.is_endless():
				_source_page.pause_endless(&"timed_popup_preview")
			else:
				_source_page._play_timer.pause(&"timed_popup_preview")
		_opened = true
	get_tree().paused = true
	_audio_enabled = bool(params.get("motion_audio", true))
	_mode = String(params.get("mode", "flow"))
	show()
	replay()


func show_flow() -> void :
	_mode = "flow"
	replay()


func show_start() -> void :
	_mode = "start"
	replay()


func show_finish() -> void :
	_mode = "end"
	replay()


func replay() -> void :
	if not _opened:
		return
	_stop_views()
	var generation: int = _generation
	var active: Callable = func() -> bool: return _valid(generation)
	if _mode in ["start", "flow"]:
		_has_target = is_instance_valid(_source_page) and _source_page.is_visible_in_tree()\
		and is_instance_valid(_source_page._timer_alarm)
		if _mode == "flow" and not _has_target:
			_status.text = "全流程需先进入局内并等待UI装配完成；这里不伪造计时目标。也可单独看开局/结束弹窗。"
			return
		if _has_target:
			_sync_clock_target()
			_alarm_alpha = _source_page._timer_alarm.modulate.a
			_source_page._timer_alarm.modulate.a = 0.0
			_alarm_hidden = true
			_status.text = "开局→保留闹钟→飞到真实Level旁 · 不启动无尽/不改存档"
		else:
			_status.text = "只看开局弹窗 · 先进入局内，可预览飞到真实Level位置"
		var carrier: TimedClockFlight = _clock_flight if _has_target else null
		var target: TextureRect = _clock_target if _has_target else null
		await _start.show_timed_challenge(carrier, target, active, _audio_enabled)
		if not active.call():
			return
		if _mode == "start":
			_status.text = "已落位 · 同一闹钟继续待机 · 点重播或切换结束" if _has_target else "开局播放完成 · 点重播或切换结束"
			return
		_status.text = "演示：闹钟已落位，跳过实际游玩，接着看结算"
		await get_tree().create_timer(0.6, true).timeout
		if not active.call():
			return
	_status.text = "结束 · 入场后持续待机 / 演示12盆与55.2% / 不发奖"
	_finish.show()

	await _finish._on_show({"result": {"reason": "time_up", "cups": 12, 
		"coins": 120, "percentile": 55.2, "encouragement_key": "GAME_STREAK_BLOOMING"}, "motion_audio": _audio_enabled})
	if not active.call():
		return
	_ignore_input(_finish)
	_demo_claim.show()
	_demo_claim.disabled = false
	_status.text = "结束完整入场 · 可演示领取退出 · 不发奖"
	if _mode == "flow":
		_status.text = "演示成绩 / 跳过游玩 · 1.1秒后自动演示领取退出，不发奖"
		await get_tree().create_timer(1.1, true).timeout
		if active.call() and _finish.visible and not _demo_collecting:
			demo_claim()


func demo_claim() -> void :
	if _demo_collecting or not _opened or not _finish.visible or _demo_claim.disabled:
		return
	_demo_collecting = true
	_demo_claim.disabled = true
	var generation: int = _generation

	await _finish.close_after_claim()
	if _valid(generation):
		_demo_collecting = false
		_demo_claim.hide()
		_status.text = "全流程播放完成 · 重播再看 / 关闭恢复游戏" if _mode == "flow" else "结束弹窗已退出 · 可重播"



func _ignore_input(node: Node) -> void :
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		(node as Control).focus_mode = Control.FOCUS_NONE
	for child: Node in node.get_children():
		_ignore_input(child)


func _stop_views() -> void :
	_generation += 1
	_demo_collecting = false
	_demo_claim.hide()
	_demo_claim.disabled = true
	_has_target = false
	_clock_flight.reset_now()
	_restore_alarm()
	if is_instance_valid(_start):
		_start.hide_now()
	if is_instance_valid(_finish):
		_finish.hide_panel()


func _valid(generation: int) -> bool:
	return _opened and visible and generation == _generation and ( not _has_target or (is_instance_valid(_source_page) and _source_page.visible and is_instance_valid(_source_page._timer_alarm)))


func _sync_clock_target() -> void :
	if not is_instance_valid(_source_page):
		return
	var rect: Rect2 = _source_page.clock_preview_target_rect()
	_clock_target.position = rect.position
	_clock_target.size = rect.size


func _restore_alarm() -> void :
	if _alarm_hidden and is_instance_valid(_source_page) and is_instance_valid(_source_page._timer_alarm):
		_source_page._timer_alarm.modulate.a = _alarm_alpha
	_alarm_hidden = false


func _queue_layout() -> void :
	if _layout_queued:
		return
	_layout_queued = true
	_layout.call_deferred()


func _layout() -> void :
	_layout_queued = false
	if _has_target:
		_sync_clock_target()
	var view: Vector2 = UiMetrics.viewport_size()
	_panel.size = Vector2(view.x - 32.0, _panel.get_combined_minimum_size().y)
	_panel.position = Vector2(16.0, view.y - UiMetrics.safe_insets().y - _panel.size.y - 12.0)


func close() -> void :
	SceneManager.hide_page("timed_endless_popup_preview")


func _on_hide() -> void :
	_stop_views()
	hide()
	_restore_pause()


func _restore_pause() -> void :
	if _opened:
		_opened = false
		get_tree().paused = _previous_paused
		if is_instance_valid(_source_page):
			if _source_page.is_endless():
				_source_page.resume_endless(&"timed_popup_preview")
			else:
				_source_page._play_timer.resume(&"timed_popup_preview")
		_source_page = null


func _on_back_request() -> void :
	close()


func _exit_tree() -> void :
	_generation += 1
	_restore_alarm()
	_restore_pause()
