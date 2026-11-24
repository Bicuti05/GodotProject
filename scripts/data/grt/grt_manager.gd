extends Node









const LTV_UNIT_SCALE: float = 1.0

const HOURS_24_MSEC: int = 24 * 60 * 60 * 1000


var _editor_grt: EditorGrt = EditorGrt.new()

var _ltv_value: float = 0.0
var _ltv_available: bool = false

var _ltv_request_in_flight: bool = false
var _ltv_request_pending: bool = false

var _background_ltv_requested: bool = false

var _first_open_time_ms: int = 0

var _round_level: int = 0

var _anchors_ready: bool = false

var _batch_ids: Array[String] = []
var _batch_definitions: Dictionary = {}
var _batch_by_event: Dictionary = {}

var _evaluating: bool = false


var _debug_completed_level_override: int = -1
var _debug_hours_override: float = -1.0


func _ready() -> void :
	_refresh_batch_cache()
	AdManager.ad_real_shown.connect(_on_ad_real_shown)
	AdManager.ad_impression_received.connect(_on_ad_impression_received)
	if OS.has_feature("editor"):
		_editor_grt.ltv_received.connect(_on_ltv_received)
	else:
		UniKit.grt_module.ltv_received.connect(_on_ltv_received)

	LevelManager.special_challenge_completed.connect(_on_special_challenge_completed)


func _notification(what: int) -> void :

	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_background_ltv_requested = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if _batch_ids.is_empty() or _background_ltv_requested:
			return
		_background_ltv_requested = true
		_request_ltv()





func ensure_all_batch_anchors() -> void :

	var first_app_version: String = UserState.get_first_app_version()
	_anchors_ready = true
	for batch_id in _batch_ids:
		var batch: Dictionary = _batch_definitions[batch_id]
		var minimum: String = String(batch.get(GrtEventDefinition.KEY_MIN_FIRST_APP_VERSION, ""))
		var anchor: int = GrtEventDefinition.anchor_for_version(first_app_version, minimum)
		if anchor == GrtEventDefinition.ANCHOR_UNSET:

			_anchors_ready = false
			continue
		if UserState.get_grt_new_install_anchor(batch_id) != anchor:
			UserState.set_grt_new_install_anchor(batch_id, anchor)
			SortLogger.info("[GrtManager] batch=%s anchor=%d（first_app_version=%s, minimum=%s）"
				%[batch_id, anchor, first_app_version, minimum])


func _ensure_anchors_ready() -> void :
	if not _anchors_ready:
		ensure_all_batch_anchors()





func set_round_level(level: int) -> void :
	_round_level = maxi(0, level)




func evaluate_level_milestones() -> void :
	SortLogger.mark("求值 GRT 里程碑：完局或退出")
	_evaluate_and_send()
	_request_ltv()




func _on_special_challenge_completed(_instance_id: String) -> void :
	evaluate_level_milestones()



func _on_ad_real_shown(placement_id: String, position: String) -> void :
	var is_reward: bool
	if placement_id == AdManager.AD_PLACEMENT_ID_REWARD:
		is_reward = true
	elif placement_id == AdManager.AD_PLACEMENT_ID_INTERSTITIAL:
		is_reward = false
	else:
		return
	UserState.record_grt_ad_show(is_reward)
	SortLogger.mark("求值 GRT 里程碑：广告展示：(placement_id=%s, position=%s, is_reward=%s)"
		%[placement_id, position, is_reward])
	_evaluate_and_send()



func _on_ad_impression_received(_data: Dictionary) -> void :
	_request_ltv()



func _on_ltv_received(ltv: float) -> void :
	_ltv_value = ltv * LTV_UNIT_SCALE
	_ltv_available = true
	SortLogger.mark("GRT LTV 返回：(raw=%s, scaled=%s)" % [ltv, _ltv_value])
	_evaluate_and_send()
	_ltv_request_in_flight = false
	if _ltv_request_pending:
		_ltv_request_pending = false
		_request_ltv()




func _evaluate_and_send() -> void :
	if _evaluating:
		return
	_evaluating = true
	_ensure_anchors_ready()
	var snapshot: Dictionary = _build_snapshot()
	var sent: Dictionary = UserState.get_grt_sent_events()
	var hits: Array[String] = GrtEvaluator.evaluate(GrtEventTable.EVENTS, snapshot, sent)
	if not hits.is_empty():
		var keys: Array[String] = []
		for event_name in hits:
			var batch_id: String = String(_batch_by_event.get(event_name, ""))
			keys.append(batch_id + ":" + event_name)

			Tracker.send_grt_event(event_name)
		UserState.mark_grt_events_sent(keys)
		SortLogger.info("[GrtManager] 命中 %d 条 GRT 事件：%s"
			%[hits.size(), ", ".join(PackedStringArray(hits))])
	_evaluating = false


func _build_snapshot() -> Dictionary:
	var first_app_version: String = UserState.get_first_app_version()
	var new_install_batches: Dictionary = {}
	for batch_id in _batch_ids:
		var batch: Dictionary = _batch_definitions[batch_id]
		var minimum: String = String(batch.get(GrtEventDefinition.KEY_MIN_FIRST_APP_VERSION, ""))
		var version_anchor: int = GrtEventDefinition.anchor_for_version(first_app_version, minimum)

		var version_allowed: bool = version_anchor == GrtEventDefinition.ANCHOR_NEW
		if OS.has_feature("editor") and version_anchor == GrtEventDefinition.ANCHOR_UNSET:
			version_allowed = true
		new_install_batches[batch_id] = version_allowed and (
			UserState.get_grt_new_install_anchor(batch_id) == GrtEventDefinition.ANCHOR_NEW)
	return {
		"living_days": _living_days(), 
		"hours_since_first_open": _hours_since_first_open(), 
		"completed_level_count": _completed_level_count(), 
		"round_level": _round_level, 
		"inter_shows": UserState.get_grt_inter_show_count(), 
		"reward_shows": UserState.get_grt_reward_show_count(), 
		"ltv": _ltv_value, 
		"ltv_available": _ltv_available, 
		"new_install_batches": new_install_batches, 
	}



func _completed_level_count() -> int:
	if _debug_completed_level_override >= 0:
		return _debug_completed_level_override
	return UserState.get_completed_level_count()



func _living_days() -> int:
	return UserState.get_install_days()



func _hours_since_first_open() -> float:
	if _debug_hours_override >= 0.0:
		return _debug_hours_override
	if _first_open_time_ms <= 0:
		return -1.0
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	return float(now_ms - _first_open_time_ms) / float(HOURS_24_MSEC) * 24.0





func _request_ltv() -> void :
	if _ltv_request_in_flight:
		_ltv_request_pending = true
		return
	if not OS.has_feature("editor") and not UniKitManager.is_available():

		return
	_ltv_request_in_flight = true
	SortLogger.mark("请求 GRT LTV")
	if OS.has_feature("editor"):
		_editor_grt.get_ltv()
	else:
		UniKit.grt_module.get_ltv()





func _refresh_batch_cache() -> void :
	_batch_ids.clear()
	_batch_definitions.clear()
	_batch_by_event.clear()
	for raw_batch in GrtEventTable.BATCHES:
		var batch: Dictionary = raw_batch
		var batch_id: String = String(batch.get(GrtEventDefinition.KEY_BATCH_ID, ""))
		_batch_ids.append(batch_id)
		_batch_definitions[batch_id] = batch
	for raw_def in GrtEventTable.EVENTS:
		var def: Dictionary = raw_def
		_batch_by_event[String(def.get(GrtEventDefinition.KEY_NAME, ""))] = String(
			def.get(GrtEventDefinition.KEY_BATCH_ID, ""))



func set_debug_completed_level(level: int) -> void :
	_debug_completed_level_override = maxi(-1, level)



func set_debug_hours(hours: float) -> void :
	_debug_hours_override = -1.0 if hours < 0.0 else hours



func set_first_open_time_ms(value: int) -> void :
	_first_open_time_ms = maxi(0, value)



func set_debug_ltv(ltv: float) -> void :
	_ltv_value = ltv * LTV_UNIT_SCALE
	_ltv_available = true
	_evaluate_and_send()



func force_evaluate() -> void :
	_evaluate_and_send()



func rearm_anchors() -> void :
	_anchors_ready = false
	ensure_all_batch_anchors()



func debug_state() -> Dictionary:
	return {
		"living_days": _living_days(), 
		"hours_since_first_open": _hours_since_first_open(), 
		"completed_level_count": _completed_level_count(), 
		"round_level": _round_level, 
		"first_app_version": UserState.get_first_app_version(), 
		"batches": GrtEventTable.BATCHES, 
		"new_install_batches": _build_snapshot()["new_install_batches"], 
		"inter_shows": UserState.get_grt_inter_show_count(), 
		"reward_shows": UserState.get_grt_reward_show_count(), 
		"ltv": _ltv_value, 
		"ltv_available": _ltv_available, 
		"ltv_request_in_flight": _ltv_request_in_flight, 
		"ltv_request_pending": _ltv_request_pending, 
		"anchors": UserState.get_grt_new_install_anchors(), 
		"sent_count": UserState.get_grt_sent_events().size(), 
		"definition_count": GrtEventTable.EVENTS.size(), 
	}


func ensure_all_batch_anchors_spread(active: Callable, progress: Callable) -> bool:

	var first_app_version: String = UserState.get_first_app_version()
	_anchors_ready = true
	var completed: int = 0
	for batch_id in _batch_ids:
		if not active.call():
			_anchors_ready = false
			return false
		completed += 1
		progress.call(float(completed - 1) / maxi(1, _batch_ids.size()))
		await get_tree().process_frame
		if not active.call():
			_anchors_ready = false
			return false
		var batch: Dictionary = _batch_definitions[batch_id]
		var minimum: String = String(batch.get(GrtEventDefinition.KEY_MIN_FIRST_APP_VERSION, ""))
		var anchor: int = GrtEventDefinition.anchor_for_version(first_app_version, minimum)
		if anchor == GrtEventDefinition.ANCHOR_UNSET:

			_anchors_ready = false
			continue
		if UserState.get_grt_new_install_anchor(batch_id) != anchor:
			if not UserState.set_grt_new_install_anchor(batch_id, anchor):
				_anchors_ready = false
				return false
			SortLogger.info("[GrtManager] batch=%s anchor=%d（first_app_version=%s, minimum=%s）"
				%[batch_id, anchor, first_app_version, minimum])

	return true
