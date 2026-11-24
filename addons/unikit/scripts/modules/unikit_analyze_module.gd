class_name UniKitAnalyzeModule
extends UniKitModuleBase



signal af_conversion_success(data: Dictionary)

signal af_conversion_fail(error: String)






func send_event(
	event_name: String, 
	params: Dictionary = {}, 
	platforms: Array = [], 
	value_to_sum: float = 0.0
) -> void :
	if _host._plugin == null:
		return
	var _platforms: Array = platforms if not platforms.is_empty() else ["learnings"]
	_host._plugin.sendEvent(event_name, JSON.stringify(params), JSON.stringify(_platforms), value_to_sum)


func get_learnings_id() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getLearningsId()


func get_uuid() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getUUID()


func set_user_property(key: String, value: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.setUserProperty(key, value)


func set_event_property(key: String, value: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.setEventProperty(key, value)
