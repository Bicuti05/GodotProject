class_name UniKitUserTagModule
extends UniKitModuleBase


signal luid_ready(luid: String)


signal af_data_result(af_data: Dictionary)

signal deep_link_data_result(data: Dictionary)


signal usertag_ready(data: Dictionary)

signal usertag_data_updated(json: String)


var _usertag_cache: Dictionary = {}
var _is_usertag_data_ready: bool = false
var _last_flat_tags: Dictionary = {}


var _usertag_update_listeners: Array[Callable] = []

var _usertag_key_listeners: Dictionary = {}



func get_inner_tags() -> Dictionary:
	return _usertag_cache.get("inner_tag_data", {})


func get_local_tags() -> Dictionary:
	return _usertag_cache.get("local_tag_data", {})


func get_remote_tags() -> Dictionary:
	return _usertag_cache.get("remote_tag_data", {})


func get_local_list_tags() -> Dictionary:
	return _usertag_cache.get("local_list_tag_data", {})


func get_remote_list_tags() -> Dictionary:
	return _usertag_cache.get("remote_list_tag_data", {})


func add_local_tag(key: String, value: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.addLocalTag(key, value)


func add_local_list_tag(key: String, values: Array) -> void :
	if _host._plugin == null:
		return
	_host._plugin.addLocalListTag(key, JSON.stringify(values))


func remove_local_tag(key: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.removeLocalTag(key)


func get_luid() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getLuid()


func set_luid_listener() -> void :
	if _host._plugin == null:
		return
	_host._plugin.setLuidListener()


func set_af_data_listener() -> void :
	if _host._plugin == null:
		return
	_host._plugin.setAfDataListener()


func set_deep_link_listener() -> void :
	if _host._plugin == null:
		return
	_host._plugin.setDeepLinkListener()



func add_usertag_update_listener(callback: Callable) -> void :
	if callback not in _usertag_update_listeners:
		_usertag_update_listeners.append(callback)
		if _is_usertag_data_ready:
			callback.call(_usertag_cache)


func remove_usertag_update_listener(callback: Callable) -> void :
	_usertag_update_listeners.erase(callback)



func add_usertag_key_listener(tag_key: String, callback: Callable) -> void :
	if tag_key not in _usertag_key_listeners:
		_usertag_key_listeners[tag_key] = []
	var list: Array = _usertag_key_listeners[tag_key]
	if callback not in list:
		list.append(callback)
		if _is_usertag_data_ready and tag_key in _last_flat_tags:
			callback.call(_usertag_cache)


func remove_usertag_key_listener(tag_key: String, callback: Callable) -> void :
	if tag_key in _usertag_key_listeners:
		_usertag_key_listeners[tag_key].erase(callback)


func _on_usertag_data_updated(json: String) -> void :
	var parsed: Variant = JSON.parse_string(json)
	if not parsed is Dictionary:
		return
	_usertag_cache = parsed
	emit_signal("usertag_data_updated", json)
	var new_flat: = _flatten_tags(parsed)
	if not _is_usertag_data_ready:
		_is_usertag_data_ready = true
		set_luid_listener()
		emit_signal("usertag_ready", _usertag_cache)
		_notify_update_listeners(parsed)
		_notify_key_listeners(new_flat)
	else:
		_notify_key_listeners(new_flat)
		_notify_update_listeners(parsed)
	_last_flat_tags = new_flat

func _notify_update_listeners(data: Dictionary) -> void :
	for cb in _usertag_update_listeners:
		cb.call(data)

func _notify_key_listeners(new_flat: Dictionary) -> void :
	for tag_key in _usertag_key_listeners:
		var new_val: Variant = new_flat.get(tag_key)
		var old_val: Variant = _last_flat_tags.get(tag_key)
		if new_val != old_val:
			for cb in _usertag_key_listeners[tag_key]:
				cb.call(_usertag_cache)


func _flatten_tags(data: Dictionary) -> Dictionary:
	var flat: = {}
	var inner: Variant = data.get("inner_tag_data", {})
	if inner is Dictionary:

		var comp_keys: = ["ad_value_data", "device_resolution_data", "device_category_data", "fold_status_data"]
		for comp_key in comp_keys:
			var comp: Variant = inner.get(comp_key)
			if comp is Dictionary:
				flat[comp_key] = comp.get("name", "")

		for k in inner:
			if not inner[k] is Dictionary:
				flat[k] = inner[k]

		var map_keys: = ["mo_flow_domain_data", "pm_flow_domain_data", "ua_ad_tag_data", 
			"af_push_api_ua_ad_tag_data", "af_push_api_data"]
		for map_key in map_keys:
			var map_val: Variant = inner.get(map_key, {})
			if map_val is Dictionary:
				flat.merge(map_val, true)

	var local: Variant = data.get("local_tag_data", {})
	if local is Dictionary:
		flat.merge(local, true)
	var local_list: Variant = data.get("local_list_tag_data", {})
	if local_list is Dictionary:
		for k in local_list:
			flat[k] = JSON.stringify(local_list[k])
	var remote: Variant = data.get("remote_tag_data", {})
	if remote is Dictionary:
		flat.merge(remote, true)
	var remote_list: Variant = data.get("remote_list_tag_data", {})
	if remote_list is Dictionary:
		for k in remote_list:
			flat[k] = JSON.stringify(remote_list[k])
	return flat
