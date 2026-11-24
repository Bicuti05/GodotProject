class_name EditorAuth
extends RefCounted
























signal cmp_completed
signal att_status_changed(status: int)
signal push_permission_done

signal push_cmd_received(cmd_json: String)




func _mock_enabled() -> bool:
	return MockUnikitConfig.is_mock_enabled(OS.has_feature("editor"))



func check_privacy_required() -> bool:
	if not _mock_enabled():
		return false
	return MockUnikitConfig.get_mock_privacy_required() == MockUnikitConfig.MockState.TRUE


func agree_privacy() -> void :
	pass



func is_privacy_agreed() -> bool:
	return false


func init_att() -> void :
	pass



func register_icm_conversion_report() -> void :
	pass




func check_cmp() -> void :
	cmp_completed.emit.call_deferred()



func check_cmp_required() -> bool:
	if not _mock_enabled():
		return false
	return MockUnikitConfig.get_mock_cmp_required() == MockUnikitConfig.MockState.TRUE


func show_cmp_ui() -> void :
	SceneManager.show_toast("编辑器模拟 CMP UI：已展示（无真实 SDK）")




func can_show_att() -> bool:
	return get_att_status() == UniKit.ATT_STATUS_NOT_DETERMINED


func show_att_alert(_source: String) -> void :
	SceneManager.show_toast("编辑器模拟 ATT 授权框")
	att_status_changed.emit.call_deferred(UniKit.ATT_STATUS_NOT_DETERMINED)





func get_att_status() -> int:
	if not _mock_enabled():
		return UniKit.ATT_STATUS_NOT_DETERMINED
	var mock: int = MockUnikitConfig.get_mock_att_status()
	if mock == MockUnikitConfig.MockState.RESET:
		return UniKit.ATT_STATUS_NOT_DETERMINED
	return mock








func request_push_permission() -> void :
	if _mock_enabled() and MockUnikitConfig.get_mock_push_state() == MockUnikitConfig.MockState.RESET:
		MockUnikitConfig.set_mock_push_state(MockUnikitConfig.PushState.AUTHORIZED)
	var granted: bool = is_notification_permission_enabled()
	SceneManager.show_toast("编辑器模拟 Push 授权框：已授权" if granted else "编辑器模拟 Push 授权框：未授权")
	push_permission_done.emit.call_deferred()





func request_notification_permission(_type: int, _position: String) -> void :
	push_permission_done.emit.call_deferred()






func _push_state() -> int:
	if not _mock_enabled():
		return MockUnikitConfig.PushState.UNDETERMINED
	var mock: int = MockUnikitConfig.get_mock_push_state()
	if mock == MockUnikitConfig.MockState.RESET:
		return MockUnikitConfig.PushState.UNDETERMINED
	return mock



func can_request_permission(_type: int) -> bool:
	return _push_state() == MockUnikitConfig.PushState.UNDETERMINED



func add_daily_push(_push_id: String, _hour_local: float, _contents: Array[Dictionary], _disturb_type: int) -> void :
	pass



func remove_push(_push_id: String) -> void :
	pass



func remove_all_pushes() -> void :
	pass


func set_push_enabled(_enabled: bool) -> void :
	pass



func is_push_enabled() -> bool:
	return false




func is_notification_permission_enabled() -> bool:
	return _push_state() == MockUnikitConfig.PushState.AUTHORIZED



func is_goto_setting_enabled() -> bool:
	return false



func trigger_test_push(_push_id: String, _title: String, _content: String, _extra: Dictionary) -> void :
	pass



func register_cmd_callback() -> void :
	pass


func get_localized_privacy_url(url: String) -> String:
	return url
