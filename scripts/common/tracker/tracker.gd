extends Node





































signal af_conversion_success(data: Dictionary)

signal af_conversion_fail(error: String)



var _current_scr: String = ""


var _current_dlg: String = ""


func _ready() -> void :
	UniKit.analyze_module.af_conversion_success.connect( func(d: Dictionary) -> void : af_conversion_success.emit(d))
	UniKit.analyze_module.af_conversion_fail.connect( func(e: String) -> void : af_conversion_fail.emit(e))







const GRT_PLATFORMS: Array[String] = ["learnings", "firebase", "appsflyer", "facebook"]









func send_event(
	event_name: String, 
	params: Dictionary = {}, 
	common: TrackingCommonParams = null, 
	platforms: Array = ["learnings"]
) -> void :
	var merged: Dictionary = params.duplicate()
	if common != null:
		merged.merge(common.to_dict(), true)
	SortLogger.mark("发送埋点事件：(event_name=%s, params=%s, platforms=%s)"
		%[event_name, JSON.stringify(merged), platforms])
	UniKit.analyze_module.send_event(event_name, merged, platforms)




func send_grt_event(event_name: String) -> void :
	SortLogger.mark("发送 GRT 里程碑事件：(event_name=%s)" % event_name)
	send_event(event_name, {}, null, GRT_PLATFORMS)




func track_scr_show(scr_name: String) -> void :
	send_event(TrackingEvents.EV_SCR_SHOW, {
		TrackingEvents.K_SCR_NAME: scr_name, 
		TrackingEvents.K_SOURCE: _current_scr, 
	})
	_current_scr = scr_name
	_current_dlg = ""




func track_scr_return(scr_name: String, closed_scr_names: Array[String]) -> void :
	if not _current_dlg.is_empty() or not closed_scr_names.has(_current_scr):
		return
	track_scr_show(scr_name)






func track_dlg_show(dlg_name: String, source: String = "", set_as_current: bool = true) -> void :
	send_event(TrackingEvents.EV_DLG_SHOW, {
		TrackingEvents.K_DLG_NAME: dlg_name, 
		TrackingEvents.K_TIMING: str(int(Time.get_unix_time_from_system() * 1000.0)), 
		TrackingEvents.K_SOURCE: source if not source.is_empty() else _current_scr, 
	})
	if set_as_current:
		_current_dlg = dlg_name



func clear_current_dlg(dlg_name: String) -> void :
	if _current_dlg == dlg_name:
		_current_dlg = ""






func track_btn_click(btn_name: String, source: String = "", level_unique_id: String = "") -> void :
	var params: Dictionary = {
		TrackingEvents.K_BTN_NAME: btn_name, 
		TrackingEvents.K_SOURCE: source if not source.is_empty() else _topmost_container(), 
	}
	if not level_unique_id.is_empty():
		params[TrackingEvents.K_LEVEL_UNIQUE_ID] = level_unique_id
	send_event(TrackingEvents.EV_BTN_CLICK, params)





func track_sw_click(sw_name: String, state: String, source: String = "") -> void :
	send_event(TrackingEvents.EV_SW_CLICK, {
		TrackingEvents.K_SW_NAME: sw_name, 
		TrackingEvents.K_STATE: state, 
		TrackingEvents.K_SOURCE: source if not source.is_empty() else _topmost_container(), 
	})




func track_user_permissions(push_state: String, att_state: String) -> void :
	var params: Dictionary = {
		TrackingEvents.K_PUSH_STATE: push_state, 
	}
	if OS.has_feature("ios"):
		params[TrackingEvents.K_ATT_STATE] = att_state
	send_event(TrackingEvents.EV_USER_PERMISSIONS, params)






func track_challenge_info(state: String, params: Dictionary, position: String = "") -> void :
	var payload: Dictionary = {
		TrackingEvents.K_EVENT_ID: String(params.get(TrackingEvents.K_EVENT_ID, "")), 

		TrackingEvents.K_LEVEL_NUM: int(params.get(TrackingEvents.K_LEVEL_NUM, 0)), 
		TrackingEvents.K_LEFT_TIME: int(params.get(TrackingEvents.K_LEFT_TIME, 0)), 
		TrackingEvents.K_CHALLENGE_ITEM: String(params.get(TrackingEvents.K_CHALLENGE_ITEM, "")), 
		TrackingEvents.K_ITEM_NUM: int(params.get(TrackingEvents.K_ITEM_NUM, 0)), 
		TrackingEvents.K_CHALLENGE_RANK: int(params.get(TrackingEvents.K_CHALLENGE_RANK, -1)), 
		TrackingEvents.K_CHALLENGE_LEVEL: int(params.get(TrackingEvents.K_CHALLENGE_LEVEL, 0)), 
		TrackingEvents.K_CHALLENGE_STATE: state, 
		TrackingEvents.K_START_DT: String(params.get(TrackingEvents.K_START_DT, "")), 
		TrackingEvents.K_END_DT: String(params.get(TrackingEvents.K_END_DT, "")), 
	}
	if not position.is_empty():
		payload[TrackingEvents.K_CHALLENGE_POSITION] = position
	send_event(TrackingEvents.EV_CHALLENGE_INFO, payload)



func current_source() -> String:
	return _topmost_container()




func _topmost_container() -> String:
	return _current_dlg if not _current_dlg.is_empty() else _current_scr










static func build_err_code(prefix: String, code: int) -> String:
	return "%s%d" % [prefix, code]







func net_type() -> String:
	return TrackingEvents.NET_ONLINE if NativeUtilManager.is_online() else TrackingEvents.NET_OFFLINE





func get_learnings_id() -> String:
	SortLogger.mark("读取埋点设备唯一 ID")
	var id: String = UniKit.analyze_module.get_learnings_id()
	SortLogger.mark("UniKit 返回：(%s)" % id)
	return id



func get_uuid() -> String:
	SortLogger.mark("读取设备 UUID")
	var uuid: String = UniKit.analyze_module.get_uuid()
	SortLogger.mark("UniKit 返回：(%s)" % uuid)
	return uuid





func set_user_property(key: String, value: String) -> void :
	SortLogger.mark("设置用户属性：(key=%s, value=%s)" % [key, value])
	UniKit.analyze_module.set_user_property(key, value)






func set_event_property(key: String, value: String) -> void :
	SortLogger.mark("设置事件属性：(key=%s, value=%s)" % [key, value])
	UniKit.analyze_module.set_event_property(key, value)
