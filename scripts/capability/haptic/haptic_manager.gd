extends Node





const Event = HapticProfiles.Event

const _BUTTON_HAPTIC_BOUND_META: StringName = &"_btn_haptic_bound"
const _SUPPORTED_PLATFORMS: Array[String] = ["Android", "iOS"]


signal dispatched(event: int, request: int, profile: Dictionary)

signal cancelled(request: int)

signal debug_log_changed

const _DEBUG_LOG_MAX: int = 64
var _debug_log: Array[Dictionary] = []
var _debug_log_indices: Dictionary = {}
var _debug_next_slot: int = 0
var _debug_record_serial: int = 0
var _pending_debug_record: int = 0
var _active_debug_record: int = 0


var _vibrator_hardware: int = -1


var _native: HapticNative = HapticNative.new()
var _pending_event: int = -1
var _pending_priority: int = -1
var _flush_queued: bool = false

var _request_serial: int = 0
var _pending_request: int = 0
var _active_request: int = 0
var _application_active: bool = true
var _tune_config: HapticTuneConfig = HapticTuneConfig.new()
var _pending_profile: Dictionary = {}


func _ready() -> void :
	_tune_config.load_saved()
	get_tree().node_added.connect(_on_node_added)


func _process(_delta: float) -> void :
	_tune_config.tick()


func _exit_tree() -> void :
	_tune_config.finish_save()



func get_tune_config() -> HapticTuneConfig:
	return _tune_config



func play_event(event: Event) -> int:
	var priority: int = HapticProfiles.priority_of(event)
	if priority < 0:
		SortLogger.warn("HapticManager: 未登记震动事件 '%s'" % event)
		return 0

	SortLogger.info("[HapticManager] 触发震动 event=%s" % Event.keys()[event])
	if not _can_vibrate():
		_record_debug(event, priority, 0, "blocked", _debug_gate_reason())
		return 0
	var profile: Dictionary = _tune_config.get_profile(event)
	var platform: String = "android" if OS.get_name() == "Android" else "ios"
	if (profile.get(platform, {}) as Dictionary).is_empty():
		SortLogger.info("[HapticManager] 场景参数尚未配置 event=%s" % Event.keys()[event])
		_record_debug(event, priority, 0, "unconfigured", "当前平台参数为空")
		return 0
	if priority <= _pending_priority:
		SortLogger.info("[HapticManager] 被同帧更高优先级抑制 event=%s" % Event.keys()[event])
		_record_debug(event, priority, 0, "suppressed", "同级或更高优先级请求已排队")
		return 0
	_update_debug_result(_pending_debug_record, "suppressed", "被更高优先级请求替换")
	_request_serial += 1
	_pending_request = _request_serial
	_pending_event = event
	_pending_priority = priority
	_pending_profile = profile.duplicate(true)
	_pending_debug_record = _record_debug(event, priority, _pending_request, "queued", "等待提交播放层", 
		String((profile.get(platform, {}) as Dictionary).get("type", "")))
	if not _flush_queued:
		_flush_queued = true
		call_deferred("_flush_pending_event")
	return _pending_request



func cancel_event(request: int) -> void :
	if request <= 0:
		return
	if request == _pending_request:
		_update_debug_result(_pending_debug_record, "cancelled", "请求在派发前被取消")
		_clear_pending_event()
		cancelled.emit(request)
	if request == _active_request:
		_update_debug_result(_active_debug_record, "cancelled", "已派发请求被取消或替换")

		_native.cancel()
		_active_request = 0
		_active_debug_record = 0
		cancelled.emit(request)



func _cancel_all_events(reason: String = "全局清理") -> void :
	_update_debug_result(_pending_debug_record, "cancelled", reason)
	_update_debug_result(_active_debug_record, "cancelled", reason)
	_clear_pending_event()
	_native.cancel()
	_active_request = 0
	_active_debug_record = 0
	cancelled.emit(0)


func _clear_pending_event() -> void :
	_pending_event = -1
	_pending_priority = -1
	_pending_request = 0
	_pending_profile = {}
	_pending_debug_record = 0


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_application_active = false
		_cancel_all_events("进入后台")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_application_active = true


func set_enabled(enabled: bool) -> void :
	UserState.set_haptic_enabled(enabled)
	if not enabled:
		_cancel_all_events("关闭震动开关")


func is_enabled() -> bool:
	return UserState.is_haptic_enabled()



func claim_button_haptic(button: Node) -> void :
	if not is_instance_valid(button):
		return
	button.set_meta(_BUTTON_HAPTIC_BOUND_META, true)




func _can_vibrate() -> bool:
	if not _application_active or not is_enabled() or not _SUPPORTED_PLATFORMS.has(OS.get_name()):
		return false
	return _has_vibrator_hardware()






func _has_vibrator_hardware() -> bool:
	if _vibrator_hardware >= 0:
		return _vibrator_hardware == 1
	if OS.get_name() == "iOS":
		var model: String = OS.get_model_name()
		_vibrator_hardware = 0 if model.begins_with("iPad") or model.begins_with("iPod") else 1
		return _vibrator_hardware == 1
	var plugin: Object = Engine.get_singleton("VibratePlugin") if Engine.has_singleton("VibratePlugin") else null
	if plugin == null:
		_vibrator_hardware = 1
		return true
	var state: int = int(plugin.vibratorState())
	if state < 0:
		return false
	_vibrator_hardware = state
	return state == 1



func _flush_pending_event() -> void :
	_flush_queued = false
	var event: int = _pending_event
	var request: int = _pending_request
	var profile: Dictionary = _pending_profile
	var debug_record: int = _pending_debug_record
	_clear_pending_event()

	if profile.is_empty() or not _can_vibrate():
		_update_debug_result(debug_record, "blocked", _debug_gate_reason())
		return
	var platform: String = "android" if OS.get_name() == "Android" else "ios"
	var cfg: Dictionary = profile.get(platform, {})
	var waveform: bool = cfg.get("type", "") in ["waveform", "composition", "ahap", "ahap_json", "continuous"]

	if waveform or OS.get_name() == "Android":
		cancel_event(_active_request)
		_active_request = 0
	if waveform:
		_active_request = request
		_active_debug_record = debug_record

	_native.play(profile, Event.keys()[event])
	_update_debug_result(debug_record, "dispatched", "已交给播放层；非马达实测")
	dispatched.emit(event, request, profile)



func _record_debug(event: int, priority: int, request: int, result: String, reason: String, kind: String = "") -> int:
	if OS.has_feature("rel"):
		return 0
	_debug_record_serial += 1
	var record: Dictionary = {"id": _debug_record_serial, "event": event, "event_name": Event.keys()[event], 
		"time_msec": Time.get_ticks_msec(), "frame": Engine.get_process_frames(), "platform": OS.get_name(), 
		"priority": priority, "request": request, "result": result, "reason": reason, "type": kind, 
		"overridden": _tune_config.is_overridden(event), "was_dispatched": false}
	if _debug_log.size() < _DEBUG_LOG_MAX:
		_debug_log.append(record)
	else:
		_debug_log_indices.erase(_debug_log[_debug_next_slot].id)
		_debug_log[_debug_next_slot] = record
	_debug_log_indices[_debug_record_serial] = _debug_next_slot
	_debug_next_slot = (_debug_next_slot + 1) % _DEBUG_LOG_MAX
	debug_log_changed.emit()
	return _debug_record_serial


func _update_debug_result(id: int, result: String, reason: String) -> void :
	if OS.has_feature("rel") or not _debug_log_indices.has(id):
		return
	var record: Dictionary = _debug_log[int(_debug_log_indices[id])]
	record.result = result
	record.reason = reason
	if result == "dispatched":
		record.was_dispatched = true
	debug_log_changed.emit()


func _debug_gate_reason() -> String:
	if not _application_active:
		return "应用不在前台"
	if not is_enabled():
		return "震动开关关闭"
	if not _SUPPORTED_PLATFORMS.has(OS.get_name()):
		return "当前平台不支持业务震动"
	return "设备没有震动马达" if _vibrator_hardware == 0 else "设备震动能力尚未就绪"



func get_debug_log() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if OS.has_feature("rel"):
		return records
	var start: int = _debug_next_slot if _debug_log.size() == _DEBUG_LOG_MAX else 0
	for offset: int in _debug_log.size():
		records.append(_debug_log[(start + offset) % _DEBUG_LOG_MAX].duplicate())
	return records



func clear_debug_log() -> void :
	if OS.has_feature("rel"):
		return
	_debug_log.clear()
	_debug_log_indices.clear()
	_debug_next_slot = 0
	debug_log_changed.emit()


func _on_node_added(node: Node) -> void :
	if node is BaseButton:
		call_deferred("_bind_button_haptic", node)



func _bind_button_haptic(node: Variant) -> void :
	if node == null or not is_instance_valid(node) or not node is BaseButton:
		return
	var button: BaseButton = node as BaseButton
	if button.has_meta(_BUTTON_HAPTIC_BOUND_META):
		return
	button.set_meta(_BUTTON_HAPTIC_BOUND_META, true)
	button.button_down.connect( func() -> void :
		play_event(Event.BUTTON)
	)
