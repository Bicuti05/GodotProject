extends Node





























signal luid_ready(luid: String)

signal af_data_result(af_data: Dictionary)

signal deep_link_data_result(data: Dictionary)

signal usertag_ready(data: Dictionary)

signal usertag_data_updated(json: String)




var _editor_unikit: EditorUniKit = EditorUniKit.new()



func _ready() -> void :
	if OS.has_feature("editor"):
		_editor_unikit.luid_ready.connect( func(v: String) -> void : luid_ready.emit(v))
		_editor_unikit.af_data_result.connect( func(v: Dictionary) -> void : af_data_result.emit(v))
		_editor_unikit.deep_link_data_result.connect( func(v: Dictionary) -> void : deep_link_data_result.emit(v))
		_editor_unikit.usertag_ready.connect( func(v: Dictionary) -> void : usertag_ready.emit(v))
		_editor_unikit.usertag_data_updated.connect( func(v: String) -> void : usertag_data_updated.emit(v))
	else:
		UniKit.usertag_module.luid_ready.connect( func(v: String) -> void : luid_ready.emit(v))
		UniKit.usertag_module.af_data_result.connect( func(v: Dictionary) -> void : af_data_result.emit(v))
		UniKit.usertag_module.deep_link_data_result.connect( func(v: Dictionary) -> void : deep_link_data_result.emit(v))
		UniKit.usertag_module.usertag_ready.connect( func(v: Dictionary) -> void : usertag_ready.emit(v))
		UniKit.usertag_module.usertag_data_updated.connect( func(v: String) -> void : usertag_data_updated.emit(v))





func initialize(params: UniKitInitParams) -> void :
	SortLogger.mark("UniKit SDK初始化：(production_id=%s)" % params.production_id)
	if OS.has_feature("editor"):
		_editor_unikit.initialize(params)
		return
	UniKit.initialize(params)



func is_available() -> bool:
	SortLogger.mark("检查 UniKit 原生插件是否可用")
	if OS.has_feature("editor"):
		var mock_available: bool = _editor_unikit.is_available()
		SortLogger.mark("Mock 返回：(%s)" % mock_available)
		return mock_available
	var available: bool = UniKit.is_available()
	SortLogger.mark("UniKit 返回：(%s)" % available)
	return available



func set_account_id(account_id: String) -> void :
	SortLogger.mark("设置账号 ID：(account_id=%s)" % account_id)
	if OS.has_feature("editor"):
		_editor_unikit.set_account_id(account_id)
		return
	UniKit.set_account_id(account_id)






func get_inner_tags() -> Dictionary:
	SortLogger.mark("读取 SDK 内部标签")
	if OS.has_feature("editor"):
		var mock_tags: Dictionary = _editor_unikit.get_inner_tags()
		SortLogger.mark("Mock 返回：(%s)" % JSON.stringify(mock_tags))
		return mock_tags
	var tags: Dictionary = UniKit.usertag_module.get_inner_tags()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(tags))
	return tags



func get_local_tags() -> Dictionary:
	SortLogger.mark("读取本地标签")
	if OS.has_feature("editor"):
		var mock_tags: Dictionary = _editor_unikit.get_local_tags()
		SortLogger.mark("Mock 返回：(%s)" % JSON.stringify(mock_tags))
		return mock_tags
	var tags: Dictionary = UniKit.usertag_module.get_local_tags()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(tags))
	return tags



func get_remote_tags() -> Dictionary:
	SortLogger.mark("读取远端标签")
	if OS.has_feature("editor"):
		var mock_tags: Dictionary = _editor_unikit.get_remote_tags()
		SortLogger.mark("Mock 返回：(%s)" % JSON.stringify(mock_tags))
		return mock_tags
	var tags: Dictionary = UniKit.usertag_module.get_remote_tags()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(tags))
	return tags



func get_local_list_tags() -> Dictionary:
	SortLogger.mark("读取列表型本地标签")
	if OS.has_feature("editor"):
		var mock_tags: Dictionary = _editor_unikit.get_local_list_tags()
		SortLogger.mark("Mock 返回：(%s)" % JSON.stringify(mock_tags))
		return mock_tags
	var tags: Dictionary = UniKit.usertag_module.get_local_list_tags()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(tags))
	return tags



func get_remote_list_tags() -> Dictionary:
	SortLogger.mark("读取列表型远端标签")
	if OS.has_feature("editor"):
		var mock_tags: Dictionary = _editor_unikit.get_remote_list_tags()
		SortLogger.mark("Mock 返回：(%s)" % JSON.stringify(mock_tags))
		return mock_tags
	var tags: Dictionary = UniKit.usertag_module.get_remote_list_tags()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(tags))
	return tags



func add_local_tag(key: String, value: String) -> void :
	SortLogger.mark("写入本地标签：(key=%s, value=%s)" % [key, value])
	if OS.has_feature("editor"):
		_editor_unikit.add_local_tag(key, value)
		return
	UniKit.usertag_module.add_local_tag(key, value)



func add_local_list_tag(key: String, values: Array) -> void :
	SortLogger.mark("写入列表型本地标签：(key=%s, values=%s)" % [key, values])
	if OS.has_feature("editor"):
		_editor_unikit.add_local_list_tag(key, values)
		return
	UniKit.usertag_module.add_local_list_tag(key, values)



func remove_local_tag(key: String) -> void :
	SortLogger.mark("删除本地标签：(key=%s)" % key)
	if OS.has_feature("editor"):
		_editor_unikit.remove_local_tag(key)
		return
	UniKit.usertag_module.remove_local_tag(key)



func get_luid() -> String:
	SortLogger.mark("读取 Luid")
	if OS.has_feature("editor"):
		var mock_luid: String = _editor_unikit.get_luid()
		SortLogger.mark("Mock 返回：(%s)" % mock_luid)
		return mock_luid
	var luid: String = UniKit.usertag_module.get_luid()
	SortLogger.mark("UniKit 返回：(%s)" % luid)
	return luid



func set_luid_listener() -> void :
	SortLogger.mark("注册 Luid 监听")
	if OS.has_feature("editor"):
		_editor_unikit.set_luid_listener()
		return
	UniKit.usertag_module.set_luid_listener()



func set_af_data_listener() -> void :
	SortLogger.mark("注册 AF 归因监听")
	if OS.has_feature("editor"):
		_editor_unikit.set_af_data_listener()
		return
	UniKit.usertag_module.set_af_data_listener()



func set_deep_link_listener() -> void :
	SortLogger.mark("注册 DeepLink 监听")
	if OS.has_feature("editor"):
		_editor_unikit.set_deep_link_listener()
		return
	UniKit.usertag_module.set_deep_link_listener()




func add_usertag_update_listener(callback: Callable) -> void :
	SortLogger.mark("注册标签全量更新回调：(callback=%s)" % callback.get_method())
	if OS.has_feature("editor"):
		_editor_unikit.add_usertag_update_listener(callback)
		return
	UniKit.usertag_module.add_usertag_update_listener(callback)



func remove_usertag_update_listener(callback: Callable) -> void :
	SortLogger.mark("移除标签全量更新回调：(callback=%s)" % callback.get_method())
	if OS.has_feature("editor"):
		_editor_unikit.remove_usertag_update_listener(callback)
		return
	UniKit.usertag_module.remove_usertag_update_listener(callback)




func add_usertag_key_listener(tag_key: String, callback: Callable) -> void :
	SortLogger.mark("注册标签 key 变化回调：(tag_key=%s, callback=%s)" % [tag_key, callback.get_method()])
	if OS.has_feature("editor"):
		_editor_unikit.add_usertag_key_listener(tag_key, callback)
		return
	UniKit.usertag_module.add_usertag_key_listener(tag_key, callback)



func remove_usertag_key_listener(tag_key: String, callback: Callable) -> void :
	SortLogger.mark("移除标签 key 变化回调：(tag_key=%s, callback=%s)" % [tag_key, callback.get_method()])
	if OS.has_feature("editor"):
		_editor_unikit.remove_usertag_key_listener(tag_key, callback)
		return
	UniKit.usertag_module.remove_usertag_key_listener(tag_key, callback)
