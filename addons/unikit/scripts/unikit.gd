extends Node



signal cmp_completed

signal att_status_changed(status: int)

signal att_dismissed


const ATT_STATUS_NOT_DETERMINED: int = 0
const ATT_STATUS_AUTHORIZED: int = 1
const ATT_STATUS_SYSTEM_DENIED: int = 2
const ATT_STATUS_APP_DENIED: int = 3

var _plugin: Object = null

var analyze_module: UniKitAnalyzeModule
var ad_module: UniKitAdModule
var abtest_module: UniKitAbTestModule
var push_module: UniKitPushModule
var usertag_module: UniKitUserTagModule
var grt_module: UniKitGrtModule
var purchase_module: UniKitPurchaseModule






var _purchase_bridge: UniKitPurchaseNativeBridge

func _ready() -> void :
	analyze_module = UniKitAnalyzeModule.new(self)
	ad_module = UniKitAdModule.new(self)
	abtest_module = UniKitAbTestModule.new(self)
	push_module = UniKitPushModule.new(self)
	usertag_module = UniKitUserTagModule.new(self)
	grt_module = UniKitGrtModule.new(self)
	purchase_module = UniKitPurchaseModule.new(self)
	if Engine.has_singleton("UniKitPlugin"):
		_plugin = Engine.get_singleton("UniKitPlugin")

		_plugin.ad_init_success.connect(_on_ad_init_success)
		_plugin.ad_init_error.connect(_on_ad_init_error)
		_plugin.abtest_init.connect(_on_abtest_init)
		_plugin.abtest_updated.connect(_on_abtest_updated)
		_plugin.abtest_locsrv_result.connect(_on_abtest_locsrv_result)
		_plugin.af_callback_success.connect(_on_af_callback_success)
		_plugin.af_callback_fail.connect(_on_af_callback_fail)
		_plugin.luid_ready.connect(_on_luid_ready)
		_plugin.ad_closed.connect(_on_ad_closed)
		_plugin.ad_rewarded.connect(_on_ad_rewarded)
		_plugin.ad_error.connect(_on_ad_error)
		_plugin.ad_impression.connect(_on_ad_impression)
		_plugin.push_permission_result.connect(_on_push_permission_result)
		_plugin.push_cmd_received.connect(_on_push_cmd_received)


		if _plugin.has_signal("push_authorization_status"):
			_plugin.push_authorization_status.connect(_on_push_authorization_status)

		_plugin.cmp_completed.connect(_on_cmp_completed)



		if OS.has_feature("ios"):
			_plugin.att_status_changed.connect(_on_att_status_changed)
			_plugin.att_dismissed.connect(_on_att_dismissed)


		_connect_required("ad_will_show", _on_ad_will_show)
		_connect_required("ad_loaded", _on_ad_loaded)
		_connect_required("abtest_remote_config_ready", _on_abtest_remote_config_ready)
		_plugin.ad_is_ready.connect(_on_ad_is_ready)
		_plugin.ad_is_valid.connect(_on_ad_is_valid)
		_plugin.af_data_result.connect(_on_af_data_result)
		_plugin.deep_link_data_result.connect(_on_deep_link_data_result)
		_plugin.usertag_data_updated.connect(_on_usertag_data_updated)

		_connect_required("ltv_received", _on_ltv_received)
	else:
		push_warning("UniKitPlugin not available (non-Android platform)")












	_purchase_bridge = UniKitPurchaseNativeBridge.new(self)
	purchase_module._set_native_bridge(_purchase_bridge)
	_purchase_bridge.native_init_success.connect(_on_purchase_init_success)
	_purchase_bridge.native_init_fail.connect(_on_purchase_init_fail)
	_purchase_bridge.native_restored.connect(_on_purchase_restored)
	_purchase_bridge.native_purchase_success.connect(_on_purchase_success)
	_purchase_bridge.native_purchase_fail.connect(_on_purchase_fail)
	_purchase_bridge.native_query_success.connect(_on_purchase_query_success)
	_purchase_bridge.native_query_fail.connect(_on_purchase_query_fail)
	_purchase_bridge.native_finish_order_success.connect(_on_purchase_finish_order_success)
	_purchase_bridge.native_finish_order_fail.connect(_on_purchase_finish_order_fail)
	_purchase_bridge.native_receipt_verified.connect(_on_purchase_receipt_verified)

func is_available() -> bool:
	return _plugin != null




func _connect_required(sig: String, cb: Callable) -> void :
	if _plugin != null and _plugin.has_signal(sig):
		_plugin.connect(sig, cb)
	else:
		push_error("[UniKit] plugin 未声明信号 '%s'——原生 bridge 版本过旧，该事件将丢失，请重新同步 addon" % sig)







func initialize(params: UniKitInitParams) -> void :
	if params == null:
		push_error("[UniKit] initialize(null)：UniKitInitParams 为空")
		return


	purchase_module._snapshot_init_params(params)


	if _purchase_bridge != null:
		var all_ids: = PackedStringArray()
		all_ids.append_array(params.consumable_product_ids)
		all_ids.append_array(params.entitled_product_ids)
		all_ids.append_array(params.subscription_product_ids)
		_purchase_bridge.set_product_ids(all_ids)
	if _plugin == null:
		return
	var json: String = JSON.stringify(params.to_json_dict())
	print("[UniKit][initialize] begin productionId=%s isDebug=%s firstOpenTime=%d"
		%[params.production_id, params.is_debug, params.first_open_time_ms])
	if OS.has_feature("android"):
		_plugin.initialize(json)
	elif OS.has_feature("ios"):
		_plugin.initialize(json, is_privacy_agreed())

func check_privacy_required() -> bool:
	if _plugin == null:
		return false
	return _plugin.checkPrivacyUiRequired()

func agree_privacy() -> void :
	if _plugin == null:
		return
	_plugin.agreePrivacyPolicy()

func is_privacy_agreed() -> bool:
	if _plugin == null:
		return false
	return _plugin.isPrivacyPolicyAgreed()





func register_icm_conversion_report() -> void :
	if _plugin == null:
		return
	if not OS.has_feature("ios"):
		return
	_plugin.registerICMConversionReport()







func check_cmp(on_done: Callable = Callable()) -> void :
	if on_done.is_valid():
		cmp_completed.connect(on_done, CONNECT_ONE_SHOT)
	if _plugin == null:
		cmp_completed.emit.call_deferred()
		return
	_plugin.checkCMP()

func check_cmp_required() -> bool:
	if _plugin == null:
		return false
	return _plugin.checkCMPUiRequired()

func show_cmp_ui() -> void :
	if _plugin == null:
		return
	_plugin.showCMPUi()





func can_show_att() -> bool:
	if not OS.has_feature("ios"):
		return false
	if _plugin == null:
		return false
	return _plugin.canShowATT()








func init_att() -> void :
	if _plugin == null:
		return
	if not OS.has_feature("ios"):
		return
	_plugin.initATT()




func show_att_alert(source: String) -> void :
	if _plugin == null:
		return
	if not OS.has_feature("ios"):
		return
	_plugin.showATTAlert(source)


func get_att_status() -> int:
	if _plugin == null:
		return ATT_STATUS_NOT_DETERMINED
	if not OS.has_feature("ios"):
		return ATT_STATUS_NOT_DETERMINED
	return _plugin.getATTStatus()

func set_account_id(account_id: String) -> void :
	if _plugin == null:
		return
	_plugin.setAccountId(account_id)

func get_localized_privacy_url(url: String) -> String:
	if _plugin == null:
		return url
	return _plugin.getLocalizedPrivacyUrl(url)


















func _on_ad_init_success() -> void :
	if _plugin == null:
		push_warning("UniKit AD init_success but plugin is null")
		return
	_plugin.setAdImpressionListener()
	ad_module._is_ad_inited = true
	ad_module.ad_init_completed.emit()

func _on_ad_init_error(error: String) -> void :
	push_warning("UniKit AD init error: %s" % error)




func _on_purchase_init_success(products_json: String) -> void :
	purchase_module._on_init_succeed(products_json)

func _on_purchase_init_fail(error_json: String) -> void :
	purchase_module._on_init_failed(error_json)

func _on_purchase_restored(purchase_json: String) -> void :
	purchase_module._on_purchase_restored(purchase_json)

func _on_purchase_success(product_id: String, purchase_json: String) -> void :
	purchase_module._on_process_purchase_succeed(product_id, purchase_json)

func _on_purchase_fail(product_id: String, error_json: String) -> void :
	purchase_module._on_process_purchase_failed(product_id, error_json)

func _on_purchase_query_success(purchases_json: String) -> void :
	purchase_module._on_query_all_purchases(purchases_json)

func _on_purchase_query_fail(error_json: String) -> void :
	purchase_module._on_query_all_purchases_failed(error_json)

func _on_purchase_finish_order_success(product_id: String, token: String) -> void :
	purchase_module._on_finish_order_succeed(product_id, token)

func _on_purchase_finish_order_fail(product_id: String, error_json: String) -> void :
	purchase_module._on_finish_order_failed(product_id, error_json)

func _on_purchase_receipt_verified(receipts_json: String) -> void :
	purchase_module._on_subscription_update(receipts_json)

func _on_abtest_init(params_json: String) -> void :
	var d: Variant = JSON.parse_string(params_json)
	abtest_module.abtest_ready.emit(d if d is Dictionary else {})

func _on_abtest_updated(update_type: String, user_info_json: String) -> void :
	var d: Variant = JSON.parse_string(user_info_json)
	abtest_module.abtest_params_updated.emit(update_type, d if d is Dictionary else {})

func _on_abtest_locsrv_result(success: bool) -> void :
	abtest_module.abtest_locsrv_fetched.emit(success)

func _on_abtest_remote_config_ready() -> void :
	abtest_module.abtest_remote_config_ready.emit()

func _on_af_callback_success(data_json: String) -> void :
	var d: Variant = JSON.parse_string(data_json)
	analyze_module.af_conversion_success.emit(d if d is Dictionary else {})

func _on_af_callback_fail(msg: String) -> void :
	push_warning("UniKit AF callback fail: %s" % msg)
	analyze_module.af_conversion_fail.emit(msg)

func _on_push_permission_result(_status: int) -> void :
	push_module._resolve_permission()

func _notification(what: int) -> void :

	if what == NOTIFICATION_APPLICATION_FOCUS_IN and push_module != null and push_module._push_permission_pending:
		push_module._on_focus_in.call_deferred()

func _on_push_cmd_received(cmd_json: String) -> void :
	push_module.push_cmd_received.emit(cmd_json)

func _on_cmp_completed() -> void :
	cmp_completed.emit()

func _on_att_status_changed(status: int) -> void :
	att_status_changed.emit(status)

func _on_att_dismissed() -> void :
	att_dismissed.emit()

func _on_ad_will_show(placement_id: String) -> void :
	ad_module.ad_will_show.emit(placement_id)

func _on_ad_loaded(placement_id: String) -> void :
	ad_module.ad_loaded.emit(placement_id)

func _on_luid_ready(luid: String) -> void :
	usertag_module.luid_ready.emit(luid)

func _on_ad_closed(placement_id: String) -> void :
	ad_module.ad_closed.emit(placement_id)

func _on_ad_rewarded(placement_id: String) -> void :
	ad_module.ad_rewarded.emit(placement_id)

func _on_ad_error(placement_id: String, msg: String) -> void :
	push_warning("UniKit AD error: placement=%s, msg=%s" % [placement_id, msg])
	ad_module.ad_error_occurred.emit(placement_id, msg)

func _on_ad_impression(data_json: String) -> void :
	var data: Dictionary = JSON.parse_string(data_json)
	ad_module.ad_impression_received.emit(data)

func _on_ad_is_ready(placement_id: String, is_ready: bool) -> void :
	ad_module.ad_is_ready_result.emit(placement_id, is_ready)

func _on_ad_is_valid(placement_id: String, is_valid: bool) -> void :
	ad_module.ad_is_valid_result.emit(placement_id, is_valid)








func _on_push_authorization_status(status: int) -> void :
	push_module.push_authorization_status.emit(status)

func _on_ltv_received(ltv: float) -> void :
	grt_module.ltv_received.emit(ltv)

func _on_af_data_result(af_data_json: String) -> void :
	var d: Variant = JSON.parse_string(af_data_json)
	usertag_module.af_data_result.emit(d if d is Dictionary else {})

func _on_deep_link_data_result(data_json: String) -> void :
	var d: Variant = JSON.parse_string(data_json)
	usertag_module.deep_link_data_result.emit(d if d is Dictionary else {})

func _on_usertag_data_updated(json: String) -> void :
	usertag_module._on_usertag_data_updated(json)
