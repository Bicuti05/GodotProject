class_name EditorUniKit
extends RefCounted











signal luid_ready(luid: String)
signal af_data_result(af_data: Dictionary)
signal deep_link_data_result(data: Dictionary)
signal usertag_ready(data: Dictionary)
signal usertag_data_updated(json: String)







func initialize(params: UniKitInitParams) -> void :
	SortLogger.info("[EditorUniKit] initialize(production_id=%s) 编辑器内跳过真实 SDK 初始化" % params.production_id)



func is_available() -> bool:
	return false



func set_account_id(_account_id: String) -> void :
	pass






func get_inner_tags() -> Dictionary:
	return {}


func get_local_tags() -> Dictionary:
	return {}


func get_remote_tags() -> Dictionary:
	return {}


func get_local_list_tags() -> Dictionary:
	return {}


func get_remote_list_tags() -> Dictionary:
	return {}


func add_local_tag(_key: String, _value: String) -> void :
	pass


func add_local_list_tag(_key: String, _values: Array) -> void :
	pass


func remove_local_tag(_key: String) -> void :
	pass



func get_luid() -> String:
	return ""


func set_luid_listener() -> void :
	pass


func set_af_data_listener() -> void :
	pass


func set_deep_link_listener() -> void :
	pass


func add_usertag_update_listener(_callback: Callable) -> void :
	pass


func remove_usertag_update_listener(_callback: Callable) -> void :
	pass


func add_usertag_key_listener(_tag_key: String, _callback: Callable) -> void :
	pass


func remove_usertag_key_listener(_tag_key: String, _callback: Callable) -> void :
	pass
