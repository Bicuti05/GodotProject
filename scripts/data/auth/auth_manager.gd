extends Node













































signal cmp_completed

signal push_probe_wait_finished

signal att_status_changed(status: int)

signal push_permission_done


signal push_cmd_received(cmd_json: String)






const PUSH_PERMISSION_TYPE_SYSTEM: int = 1
const PUSH_PERMISSION_TYPE_SYSTEM_AND_SETTING: int = 2
const PUSH_PERMISSION_TYPE_SETTING: int = 3


const PUSH_PROBE_WAIT_SECONDS: float = 3.0



var _editor_auth: EditorAuth = EditorAuth.new()
var _cmp_started_msec: int = 0

var _push_probe_waiting: bool = false

var _push_probe_result: bool = false







func _use_mock() -> bool:
	return OS.has_feature("editor") or _mock_active()





func _auth_module() -> Variant:
	if _use_mock():
		return _editor_auth
	return UniKit



func _push_module() -> Variant:
	if _use_mock():
		return _editor_auth
	return UniKit.push_module



func _module_label(module: Variant) -> String:
	return "Mock" if module == _editor_auth else "UniKit"






func _mock_active() -> bool:
	return MockUnikitConfig.is_mock_enabled(OS.has_feature("editor"))


func _ready() -> void :



	_bind_signals(_editor_auth, _editor_auth, "（Mock 替身）")
	_bind_signals(UniKit, UniKit.push_module, "")





func _bind_signals(cmp_module: Variant, push_module: Variant, suffix: String) -> void :
	cmp_module.cmp_completed.connect( func() -> void :
		SortLogger.mark("CMP 流程完成%s" % suffix)
		cmp_completed.emit()
	)
	cmp_module.att_status_changed.connect( func(status: int) -> void :
		SortLogger.mark("ATT 状态变更为%s：(status=%d)" % [suffix, status])
		att_status_changed.emit(status)
	)
	push_module.push_permission_done.connect( func() -> void :
		SortLogger.mark("Push 权限请求完成%s" % suffix)
		push_permission_done.emit()
	)
	push_module.push_cmd_received.connect( func(json: String) -> void :
		SortLogger.mark("收到静默推送指令%s：(json=%s)" % [suffix, json])
		push_cmd_received.emit(json)
	)






















func initialize(progress: Callable = Callable()) -> void :
	await _report_startup_stage(progress, "privacy", false)
	SortLogger.info("[AuthManager] 调用 check_privacy_required()")
	var sdk_privacy_required: bool = check_privacy_required()
	SortLogger.info("[AuthManager] check_privacy_required 返回 %s" % sdk_privacy_required)
	if sdk_privacy_required:

		Tracker.track_dlg_show(TrackingEvents.DLG_PRIVACY)
		var privacy_dialog: Node = SceneManager.show_dlg("privacy")
		await privacy_dialog.accepted
		SceneManager.hide_page("privacy")

		Tracker.track_btn_click(TrackingEvents.BTN_AGREE, TrackingEvents.DLG_PRIVACY)
		Tracker.clear_current_dlg(TrackingEvents.DLG_PRIVACY)
		SortLogger.info("[AuthManager] 调用 agree_privacy()")
		agree_privacy()
		UserState.set_agreed_privacy()

	await _report_startup_stage(progress, "privacy", true)

	SortLogger.info("[AuthManager] 调用 init_att()")
	init_att()
	await _report_startup_stage(progress, "cmp", false)

	SortLogger.info("[AuthManager] 调用 set_push_enabled(true)")
	set_push_enabled(true)

	_cmp_started_msec = Time.get_ticks_msec()
	SortLogger.info("[AuthManager] 调用 check_cmp(on_done=_on_cmp_completed)")
	SortLogger.info("[Startup] cmp_started startup_wait=false")
	check_cmp(_on_cmp_completed)
	await _report_startup_stage(progress, "cmp", true)



func _report_startup_stage(progress: Callable, stage: String, completed: bool) -> void :
	if progress.is_valid():
		await progress.call(stage, completed)









func _on_cmp_completed() -> void :
	SortLogger.info("[Startup] cmp_callback_ms=%d startup_wait=false" % (Time.get_ticks_msec() - _cmp_started_msec))
	SortLogger.info("[AuthManager] 调用 can_show_att()")
	var can_show: bool = can_show_att()
	SortLogger.info("[AuthManager] can_show_att 返回 %s" % can_show)
	if can_show:
		SortLogger.info("[AuthManager] 调用 show_att_alert(source=launcher)")
		show_att_alert("launcher")







func _probe_can_request_push() -> bool:
	_push_probe_result = false
	_push_probe_waiting = true
	_do_probe_can_request()
	if _push_probe_waiting:
		get_tree().create_timer(PUSH_PROBE_WAIT_SECONDS).timeout.connect(_on_push_probe_wait_timeout)
		await push_probe_wait_finished
	return _push_probe_result




func _do_probe_can_request() -> void :
	_push_probe_result = await can_request_permission(PUSH_PERMISSION_TYPE_SYSTEM)
	_finish_push_probe_wait()


func _on_push_probe_wait_timeout() -> void :
	if not _push_probe_waiting:
		return
	SortLogger.info("[AuthManager] Push 权限探测超过 %s 秒未返回，按不可申请处理" % PUSH_PROBE_WAIT_SECONDS)
	_finish_push_probe_wait()


func _finish_push_probe_wait() -> void :
	if not _push_probe_waiting:
		return
	_push_probe_waiting = false
	push_probe_wait_finished.emit()





func check_privacy_required() -> bool:
	SortLogger.mark("查询是否需要展示隐私协议")
	var module: Variant = _auth_module()
	var required: bool = module.check_privacy_required()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), required])
	return required


func agree_privacy() -> void :
	SortLogger.mark("同意隐私协议")
	_auth_module().agree_privacy()




func is_privacy_agreed() -> bool:
	SortLogger.mark("查询隐私协议是否已同意")
	var module: Variant = _auth_module()
	var agreed: bool = module.is_privacy_agreed()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), agreed])
	return agreed


func init_att() -> void :
	SortLogger.mark("初始化 ATT")
	_auth_module().init_att()




func register_icm_conversion_report() -> void :
	SortLogger.mark("注册 ICM 转化上报")
	_auth_module().register_icm_conversion_report()




func check_cmp(on_done: Callable = Callable()) -> void :
	SortLogger.mark("触发 CMP 流程：(on_done=%s)" % (on_done.get_method() if on_done.is_valid() else "无"))
	if on_done.is_valid():
		cmp_completed.connect(on_done, CONNECT_ONE_SHOT)
	_auth_module().check_cmp()




func check_cmp_required() -> bool:
	SortLogger.mark("查询是否需要展示 CMP")
	var module: Variant = _auth_module()
	var required: bool = module.check_cmp_required()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), required])
	return required


func show_cmp_ui() -> void :
	SortLogger.mark("展示 CMP 界面")
	_auth_module().show_cmp_ui()




func can_show_att() -> bool:
	SortLogger.mark("查询当前是否可弹 ATT 授权框")
	var module: Variant = _auth_module()
	var can: bool = module.can_show_att()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), can])
	return can


func show_att_alert(source: String) -> void :
	SortLogger.mark("弹出 ATT 授权框：(source=%s)" % source)
	_auth_module().show_att_alert(source)




func get_att_status() -> int:
	SortLogger.mark("读取 ATT 授权状态")
	var module: Variant = _auth_module()
	var status: int = module.get_att_status()
	SortLogger.mark("%s 返回：(%d)" % [_module_label(module), status])
	return status









func track_user_permissions() -> void :

	var att_state: String = _att_state_for_tracking() if OS.has_feature("ios") else ""
	var push_state: String = await _push_state_for_tracking()
	Tracker.track_user_permissions(push_state, att_state)




func _att_state_for_tracking() -> String:
	match get_att_status():
		UniKit.ATT_STATUS_AUTHORIZED:
			return TrackingEvents.PERM_AUTHORIZED
		UniKit.ATT_STATUS_SYSTEM_DENIED, UniKit.ATT_STATUS_APP_DENIED:
			return TrackingEvents.PERM_DENIED
		_:
			return TrackingEvents.PERM_UNDETERMINED













func _push_state_for_tracking() -> String:
	var module: Variant = _push_module()
	if await module.is_notification_permission_enabled():
		return TrackingEvents.PERM_AUTHORIZED
	if await module.can_request_permission(PUSH_PERMISSION_TYPE_SYSTEM):
		return TrackingEvents.PERM_UNDETERMINED
	return TrackingEvents.PERM_DENIED


func get_localized_privacy_url(url: String) -> String:
	SortLogger.mark("获取本地化隐私链接：(url=%s)" % url)
	var module: Variant = _auth_module()
	var localized: String = module.get_localized_privacy_url(url)
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), localized])
	return localized


func request_push_permission() -> void :
	SortLogger.mark("请求推送权限")
	_push_module().request_push_permission()









func request_push_permission_once() -> bool:
	SortLogger.mark("申请推送权限：(ask_count=%d)" % UserState.get_push_ask_count())
	if UserState.get_push_ask_count() >= 1:
		SortLogger.mark("跳过推送权限申请：已申请过")
		return false
	if not await _probe_can_request_push():
		SortLogger.mark("跳过推送权限申请：此刻不可申请（不消耗 ask_count）")
		return false
	SortLogger.mark("调用 request_push_permission()")
	request_push_permission()
	await push_permission_done
	UserState.inc_push_ask_count()
	return true





func request_notification_permission(type: int = PUSH_PERMISSION_TYPE_SYSTEM_AND_SETTING, position: String = "default") -> void :
	SortLogger.mark("请求通知权限：(type=%d, position=%s)" % [type, position])
	_push_module().request_notification_permission(type, position)




func can_request_permission(type: int = PUSH_PERMISSION_TYPE_SYSTEM_AND_SETTING) -> bool:
	SortLogger.mark("查询是否可请求通知权限：(type=%d)" % type)
	var module: Variant = _push_module()
	var can: bool = await module.can_request_permission(type)
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), can])
	return can


func set_push_enabled(enabled: bool) -> void :
	SortLogger.mark("设置推送总开关：(enabled=%s)" % enabled)
	_push_module().set_push_enabled(enabled)






func add_daily_push(push_id: String, hour_local: float, contents: Array[Dictionary], disturb_type: int = 1) -> void :
	SortLogger.mark("添加每日定时推送：(push_id=%s, hour_local=%s, disturb_type=%d)" % [push_id, hour_local, disturb_type])
	_push_module().add_daily_push(push_id, hour_local, contents, disturb_type)



func remove_push(push_id: String) -> void :
	SortLogger.mark("移除定时推送：(push_id=%s)" % push_id)
	_push_module().remove_push(push_id)



func remove_all_pushes() -> void :
	SortLogger.mark("移除全部定时推送")
	_push_module().remove_all_pushes()



func is_push_enabled() -> bool:
	SortLogger.mark("查询推送总开关是否开启")
	var module: Variant = _push_module()
	var enabled: bool = module.is_push_enabled()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), enabled])
	return enabled




func is_notification_permission_enabled() -> bool:
	SortLogger.mark("查询通知权限是否已开启")
	var module: Variant = _push_module()
	var enabled: bool = await module.is_notification_permission_enabled()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), enabled])
	return enabled




func is_goto_setting_enabled() -> bool:
	SortLogger.mark("查询是否显示跳转通知设置入口")
	var module: Variant = _push_module()
	var enabled: bool = module.is_goto_setting_enabled()
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), enabled])
	return enabled





func trigger_test_push(push_id: String, title: String, content: String, extra: Dictionary = {}) -> void :
	SortLogger.mark("触发测试推送：(push_id=%s, title=%s)" % [push_id, title])
	_push_module().trigger_test_push(push_id, title, content, extra)





func register_cmd_callback() -> void :
	SortLogger.mark("注册静默推送指令回调")
	_push_module().register_cmd_callback()









func peek_privacy_required() -> bool:
	return UniKit.check_privacy_required()



func peek_cmp_required() -> bool:
	return UniKit.check_cmp_required()



func peek_att_status() -> int:
	return UniKit.get_att_status()
