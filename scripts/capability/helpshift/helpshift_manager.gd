



















class_name HelpshiftManager
extends RefCounted





static func on_settings_opened() -> void :
	SortLogger.info("[HelpshiftManager] on_settings_opened: 触发 Help Center 按需初始化")
	NativeUtilManager.ensure_help_center_initialized()




static func show_help_center() -> void :
	SortLogger.info("[HelpshiftManager] show_help_center: 请求打开 Help Center")
	if OS.has_feature("editor"):
		SortLogger.info("[HelpshiftManager] show_help_center: 编辑器环境，仅提示不打开")
		SceneManager.show_toast(TranslationServer.translate("HELP_CENTER_EDITOR_TOAST"))
		return
	if not OS.has_feature("android") and not OS.has_feature("ios"):
		SortLogger.info("[HelpshiftManager] show_help_center: 非移动端，静默返回")
		return
	NativeUtilManager.record_help_center_click()
	if not NativeUtilManager.is_online():
		SortLogger.warn("[HelpshiftManager] show_help_center: 当前离线，提示连接错误并等待联网后初始化")
		SceneManager.show_toast(TranslationServer.translate("HELP_CENTER_CONNECTION_ERROR"))
		NativeUtilManager.ensure_help_center_initialized()
		return
	if not NativeUtilManager.is_help_center_initialized():
		SortLogger.warn("[HelpshiftManager] show_help_center: SDK 尚未就绪，提示加载失败并触发初始化")
		SceneManager.show_toast(TranslationServer.translate("HELP_CENTER_LOAD_FAILED"))
		NativeUtilManager.ensure_help_center_initialized()
		return
	var meta: Dictionary = {
		"userId": Tracker.get_learnings_id(), 
		"luid": UniKitManager.get_luid(), 
		"current_level": str(UserState.get_current_level()), 
		"install_days": str(UserState.get_install_days()), 
	}
	SortLogger.info("[HelpshiftManager] show_help_center: 调起 Helpshift, metadata=%s"
		%JSON.stringify(meta))
	NativeUtilManager.show_help_center(meta)


	clear_badge()










static func on_unread_count_changed(count: int) -> void :
	var last_count: int = UserState.get_help_center_unread_count()
	if count > last_count:
		UserState.set_help_center_badge(true)
		SortLogger.info("[HelpshiftManager] on_unread_count_changed: %d > %d(上次)，点亮两处红点"
			%[count, last_count])
	elif count == 0:
		UserState.set_help_center_badge(false)
		SortLogger.info("[HelpshiftManager] on_unread_count_changed: 未读归零，熄灭两处红点")
	else:
		SortLogger.info("[HelpshiftManager] on_unread_count_changed: %d <= %d(上次)，红点状态不变"
			%[count, last_count])
	UserState.set_help_center_unread_count(count)




static func should_show_badge() -> bool:
	var badge_visible: bool = UserState.should_show_help_center_badge()
	SortLogger.info("[HelpshiftManager] should_show_badge → %s" % badge_visible)
	return badge_visible


static func clear_badge() -> void :
	SortLogger.info("[HelpshiftManager] clear_badge: 熄灭两处红点")
	UserState.set_help_center_badge(false)
