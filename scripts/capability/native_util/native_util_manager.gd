extends Node







const _CRASHLYTICS_LOG_CACHE_MAX: int = 20
var _crashlytics_log_cache: Array[Dictionary] = []

const _HELP_CENTER_TOAST_MIN_INTERVAL_MSEC: int = 2000
const _REVIEW_RESULT_TOAST_MIN_INTERVAL_MSEC: int = 1500

var _native_util: Object = null
var _help_center_initialized: bool = false
var _help_center_init_in_progress: bool = false
var _help_center_waiting_for_network: bool = false
var _help_center_monitoring: bool = false
var _help_center_init_toast_msec: int = 0
var _store_review_request_msec: int = 0

func _ready() -> void :
	if not Engine.has_singleton("NativeUtilPlugin"):
		push_warning("NativeUtilPlugin not available (editor/desktop)")
		return
	_native_util = Engine.get_singleton("NativeUtilPlugin")


	if _native_util.has_signal("help_center_init_completed"):
		Signal(_native_util, "help_center_init_completed").connect(_on_help_center_init_completed)
		_help_center_initialized = _native_util.isHelpCenterInitialized()
		if _native_util.hasRecentHelpCenterClick():
			ensure_help_center_initialized()
	if _native_util.has_signal("help_center_unread_count_changed"):
		Signal(_native_util, "help_center_unread_count_changed")\
		.connect(_on_help_center_unread_count_changed)


		if _help_center_initialized:
			request_help_center_unread_count()
	if OS.has_feature("android") and _native_util.has_signal("store_review_debug_completed"):
		Signal(_native_util, "store_review_debug_completed").connect(_on_store_review_debug_completed)
	for entry in _crashlytics_log_cache:
		_native_util.logCrashlyticsException(entry["message"], entry["stack"])
	_crashlytics_log_cache.clear()


func _notification(what: int) -> void :
	if what != NOTIFICATION_APPLICATION_RESUMED or _native_util == null:
		return
	if _help_center_initialized:
		request_help_center_unread_count()
	elif _native_util.hasRecentHelpCenterClick():
		ensure_help_center_initialized()




func is_online() -> bool:
	if _native_util == null:
		return true
	return _native_util.isOnline()



func set_crashlytics_user_id(user_id: String) -> void :
	if _native_util == null:
		return
	_native_util.setCrashlyticsUserId(user_id)




func set_crashlytics_key(key: String, value: String) -> void :
	if _native_util == null:
		return



	if OS.has_feature("ios") and not _native_util.has_method("setCrashlyticsKey"):
		return
	_native_util.setCrashlyticsKey(key, value)



func log_exception(message: String, stack: String = "") -> void :
	if _native_util == null:
		if _crashlytics_log_cache.size() >= _CRASHLYTICS_LOG_CACHE_MAX:
			_crashlytics_log_cache.pop_front()
		_crashlytics_log_cache.append({"message": message, "stack": stack})
		return
	_native_util.logCrashlyticsException(message, stack)




func get_first_open_time_ms() -> int:
	if _native_util == null:
		return 0
	return int(_native_util.getFirstOpenTimeMs())



func show_help_center(metadata: Dictionary) -> void :
	if _native_util == null:
		return
	_native_util.showHelpCenter(metadata)



func is_help_center_initialized() -> bool:
	return _help_center_initialized


func record_help_center_click() -> void :
	if _native_util != null:
		_native_util.recordHelpCenterClick()




func request_help_center_unread_count() -> void :
	if _native_util == null:
		return
	_native_util.requestHelpCenterUnreadCount()



func _on_help_center_unread_count_changed(count: int) -> void :
	HelpshiftManager.on_unread_count_changed(count)


func ensure_help_center_initialized() -> void :
	if _native_util == null or _help_center_initialized or _help_center_init_in_progress:
		return
	if not is_online():
		_help_center_waiting_for_network = true
		if not _help_center_monitoring:
			_watch_help_center_connection()
		return
	_help_center_waiting_for_network = false
	_help_center_init_in_progress = true
	if _show_help_center_init_toasts():
		_help_center_init_toast_msec = Time.get_ticks_msec()
		SceneManager.show_toast("Help Center 开始初始化")
	_native_util.initializeHelpCenter()


func _on_help_center_init_completed(success: bool) -> void :
	_help_center_init_in_progress = false
	_help_center_initialized = success

	if success:
		request_help_center_unread_count()
	if success and _show_help_center_init_toasts():
		var remaining_msec: int = maxi(_help_center_init_toast_msec\
		+ _HELP_CENTER_TOAST_MIN_INTERVAL_MSEC - Time.get_ticks_msec(), 0)
		if remaining_msec > 0:
			await get_tree().create_timer(float(remaining_msec) / 1000.0).timeout
		SceneManager.show_toast("Help Center 初始化完成，可以进入")
	if not success and not is_online():
		ensure_help_center_initialized()


func _show_help_center_init_toasts() -> bool:
	return OS.is_debug_build() and (OS.has_feature("android") or OS.has_feature("ios"))


func _watch_help_center_connection() -> void :
	_help_center_monitoring = true
	while _help_center_waiting_for_network and not _help_center_initialized:
		await get_tree().create_timer(1.0).timeout
		if is_online():
			_help_center_waiting_for_network = false
			ensure_help_center_initialized()
	_help_center_monitoring = false




func can_request_store_review() -> bool:
	return _native_util != null and (OS.has_feature("android")\
	or _native_util.has_method("requestStoreReview"))


func request_store_review() -> bool:
	if not can_request_store_review():
		return false
	if OS.has_feature("android") and OS.is_debug_build():
		_store_review_request_msec = Time.get_ticks_msec()
	_native_util.requestStoreReview()
	return true


func _on_store_review_debug_completed(success: bool, reason: String) -> void :
	if not OS.has_feature("android") or not OS.is_debug_build():
		return

	var remaining_msec: int = maxi(_store_review_request_msec\
	+ _REVIEW_RESULT_TOAST_MIN_INTERVAL_MSEC - Time.get_ticks_msec(), 0)
	if remaining_msec > 0:
		await get_tree().create_timer(float(remaining_msec) / 1000.0).timeout
	if success:
		SceneManager.show_toast("Google Play评分请求成功")
	else:
		SceneManager.show_toast("Google Play评分请求失败：%s" % reason)
