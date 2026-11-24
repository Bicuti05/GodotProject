class_name UniKitPushModule
extends UniKitModuleBase



const PUSH_PERMISSION_TYPE_SYSTEM: int = 1
const PUSH_PERMISSION_TYPE_SYSTEM_AND_SETTING: int = 2
const PUSH_PERMISSION_TYPE_SETTING: int = 3


const PUSH_AUTH_STATUS_NOT_DETERMINED: int = 0
const PUSH_AUTH_STATUS_DENIED: int = 1
const PUSH_AUTH_STATUS_AUTHORIZED: int = 2
const PUSH_AUTH_STATUS_PROVISIONAL: int = 3












const _CONTENT_FIELDS: Dictionary = {
	"title": {"ios": true, "type": TYPE_STRING}, 
	"content": {"ios": true, "type": TYPE_STRING}, 
	"large_icon": {"ios": true, "type": TYPE_STRING}, 
	"content_image": {"ios": true, "type": TYPE_STRING}, 
	"sound": {"ios": true, "type": TYPE_STRING}, 
	"bg_color": {"ios": false, "type": TYPE_STRING}, 
	"btn_bg_color": {"ios": false, "type": TYPE_STRING}, 
	"btn_content": {"ios": false, "type": TYPE_STRING}, 
	"bg_image": {"ios": false, "type": TYPE_STRING}, 
	"vibrate": {"ios": false, "type": TYPE_BOOL}, 

	"title_night": {"ios": false, "type": TYPE_STRING}, 
	"content_night": {"ios": false, "type": TYPE_STRING}, 
	"large_icon_night": {"ios": false, "type": TYPE_STRING}, 
}

signal push_permission_done
signal push_cmd_received(cmd_json: String)



signal push_authorization_status(status: int)


var _push_permission_pending: bool = false


func request_push_permission() -> void :
	request_notification_permission(PUSH_PERMISSION_TYPE_SYSTEM, "app_start")





func request_notification_permission(type: int = PUSH_PERMISSION_TYPE_SYSTEM_AND_SETTING, position: String = "default") -> void :
	if _host._plugin == null:
		push_permission_done.emit.call_deferred()
		return
	if type == PUSH_PERMISSION_TYPE_SYSTEM and OS.has_feature("android") and not _is_android_13_or_above():
		push_permission_done.emit.call_deferred()
		return
	_push_permission_pending = true
	_host._plugin.requestPushPermission(type, position)



static func _is_android_13_or_above() -> bool:
	if not OS.has_feature("android"):
		return false
	var v: String = OS.get_version()
	if v.is_empty():
		return false
	return v.split(".")[0].to_int() >= 13






static func _can_request_for_status(status: int, type: int) -> bool:
	match status:
		PUSH_AUTH_STATUS_NOT_DETERMINED:
			return type != PUSH_PERMISSION_TYPE_SETTING
		PUSH_AUTH_STATUS_DENIED:
			return type != PUSH_PERMISSION_TYPE_SYSTEM
		PUSH_AUTH_STATUS_AUTHORIZED:
			return false
		PUSH_AUTH_STATUS_PROVISIONAL:
			return type != PUSH_PERMISSION_TYPE_SETTING
	return false


func _await_authorization_status() -> int:
	if not _host._plugin.has_signal("push_authorization_status"):
		push_error("[UniKit] plugin 未声明信号 'push_authorization_status'——原生 bridge 版本过旧,权限查询将返回保守值,请重新同步 addon")
		return -1
	_host._plugin.getPushAuthorizationStatus()

	return await push_authorization_status




func can_request_permission(type: int = PUSH_PERMISSION_TYPE_SYSTEM_AND_SETTING) -> bool:
	if _host._plugin == null:
		return false
	if OS.has_feature("android"):

		if type == PUSH_PERMISSION_TYPE_SETTING:
			return _host._plugin.isGotoSettingEnabled()


		if type == PUSH_PERMISSION_TYPE_SYSTEM and not _is_android_13_or_above():
			return false
		return not _host._plugin.isNotificationPermissionEnabled()
	var status: int = await _await_authorization_status()
	if status < 0:
		return false
	return _can_request_for_status(status, type)












func add_daily_push(push_id: String, hour_local: float, contents: Array[Dictionary], disturb_type: int = 1) -> void :
	if _host._plugin == null:
		return
	var target_hour: int = int(hour_local)
	var target_minute: int = int(round((hour_local - float(target_hour)) * 60.0))

	var local: Dictionary = Time.get_datetime_dict_from_system()

	var advance_one_day: bool = local["hour"] > target_hour or (local["hour"] == target_hour and local["minute"] >= target_minute)
	var normalized: Array[Dictionary] = _normalize_contents(contents, OS.has_feature("ios"))
	var contents_dict: Dictionary = {}
	for i: int in range(normalized.size()):

		contents_dict["%s_c%d" % [push_id, i]] = normalized[i]
	var push_data: Dictionary = {
		"push_id": push_id, 

		"local_year": local["year"], 
		"local_month": local["month"], 
		"local_day": local["day"], 
		"local_hour": target_hour, 
		"local_minute": target_minute, 
		"advance_one_day": advance_one_day, 
		"push_time_ms": 0, 
		"repeat_interval_ms": 86400000, 
		"is_infinite_repeat": true, 
		"disturb_type": disturb_type, 
		"contents": contents_dict
	}
	_host._plugin.saveLocalPush(JSON.stringify(push_data))

func remove_push(push_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.removeLocalPush(push_id)

func remove_all_pushes() -> void :
	if _host._plugin == null:
		return
	_host._plugin.removeAllLocalPush()

func set_push_enabled(enabled: bool) -> void :
	if _host._plugin == null:
		return
	_host._plugin.enablePush(enabled)

func is_push_enabled() -> bool:
	if _host._plugin == null:
		return false
	return _host._plugin.isEnablePush()




func is_notification_permission_enabled() -> bool:
	if _host._plugin == null:
		return false
	if OS.has_feature("android"):
		return _host._plugin.isNotificationPermissionEnabled()
	var status: int = await _await_authorization_status()
	return status == PUSH_AUTH_STATUS_AUTHORIZED or status == PUSH_AUTH_STATUS_PROVISIONAL


func is_goto_setting_enabled() -> bool:
	if _host._plugin == null:
		return false
	return _host._plugin.isGotoSettingEnabled()




func trigger_test_push(push_id: String, title: String, content: String, extra: Dictionary = {}) -> void :
	if _host._plugin == null:
		return
	_host._plugin.removeLocalPush(push_id)
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000)

	var content_dict: Dictionary = extra.duplicate()
	content_dict["title"] = title
	content_dict["content"] = content
	var raw: Array[Dictionary] = [content_dict]
	var normalized: Array[Dictionary] = _normalize_contents(raw, OS.has_feature("ios"))
	var push_data: Dictionary = {
		"push_id": push_id, 
		"push_time_ms": now_ms + 5000, 
		"repeat_interval_ms": 0, 
		"is_infinite_repeat": false, 
		"disturb_type": 0, 
		"contents": {"c0": normalized[0]}
	}
	_host._plugin.saveLocalPush(JSON.stringify(push_data))



func register_cmd_callback() -> void :
	if _host._plugin == null:
		return
	_host._plugin.registerCmdCallback()


func _resolve_permission() -> void :
	_push_permission_pending = false
	push_permission_done.emit()


func _on_focus_in() -> void :
	if not _push_permission_pending:
		return
	_push_permission_pending = false
	push_permission_done.emit()






func _normalize_contents(contents: Array[Dictionary], is_ios: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rejected: Dictionary = {}
	var platform_dropped: Dictionary = {}
	for raw: Dictionary in contents:
		var item: Dictionary = {}
		for k: Variant in raw:
			var key: String = str(k)
			if not _CONTENT_FIELDS.has(key):
				rejected[key] = "未知字段"
				continue
			var field: Dictionary = _CONTENT_FIELDS[key]
			if is_ios and not field["ios"]:
				platform_dropped[key] = true
				continue
			if typeof(raw[k]) != field["type"]:
				rejected[key] = "类型应为 %s,实际 %s" % [
					type_string(field["type"]), type_string(typeof(raw[k]))]
				continue




			if field["type"] == TYPE_STRING and String(raw[k]).is_empty():
				continue
			item[key] = raw[k]



		if item.is_empty():
			continue
		out.append(item)
	if not rejected.is_empty():
		push_warning("[UniKit] push content 字段被剔除:%s" % [rejected])
	if not platform_dropped.is_empty() and OS.is_debug_build():
		print("[UniKit] push content 字段 %s 仅 Android 支持,iOS 已剔除" % [platform_dropped.keys()])
	return out
