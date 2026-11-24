class_name UniKitPurchaseNativeBridge
extends RefCounted











signal native_init_success(products_json: String)
signal native_init_fail(error_json: String)
signal native_restored(purchase_json: String)
signal native_purchase_success(product_id: String, purchase_json: String)
signal native_purchase_fail(product_id: String, error_json: String)





signal native_query_success(purchases_json: String)
signal native_query_fail(error_json: String)
signal native_finish_order_success(product_id: String, token: String)
signal native_finish_order_fail(product_id: String, error_json: String)


signal native_receipt_verified(receipts_json: String)


const _IOS_RESULT_CANCELLED: int = 0
const _IOS_RESULT_SUCCESS: int = 1


const _IOS_CODE_USER_CANCELLED: int = 1001





const _IOS_PRODUCT_TYPE: Dictionary = {
	0: "subscription", 
	1: "subscription", 
	2: "consumable", 
	3: "entitled", 
}

var _host: Node = null

var _product_ids: Array = []

func _init(host: Node) -> void :
	_host = host
	if _host._plugin == null:
		return
	if _is_ios():
		_connect_ios()
	else:
		_connect_android()



func _is_ios() -> bool:
	return OS.has_feature("ios")


func set_product_ids(ids: PackedStringArray) -> void :
	_product_ids = []
	for id: String in ids:
		_product_ids.append(id)








func _parse_native_json(json: String) -> Variant:
	if json.is_empty():
		return null
	return JSON.parse_string(json)



func send_purchase(params: UniKitPurchaseParams) -> void :
	if _host._plugin == null:
		return
	if _is_ios():

		if not params.old_product_id.is_empty():
			print("[UniKit] iOS 忽略 old_product_id=%s（订阅升降级由 App Store 处理）"
				%params.old_product_id)
		var extra: Dictionary = params.to_json_dict().get("extraData", {})
		_host._plugin.buyProduct(params.product_id, params.inner_order_id, JSON.stringify(extra))
	else:
		_host._plugin.purchase(JSON.stringify(params.to_json_dict()))












func send_update_subscription() -> void :
	if _host._plugin == null:
		return
	if _is_ios():
		_host._plugin.verifyReceipt()
	else:
		_host._plugin.queryAllPurchases()














func send_restore() -> void :
	if _host._plugin == null:
		return
	if _is_ios():
		_host._plugin.restorePurchase()
	else:
		_host._plugin.queryAllPurchases()

func send_finish_order(product_id: String, token: String) -> void :
	if _host._plugin == null:
		return
	if _is_ios():



		_host._plugin.finishTransaction(token)
	else:
		_host._plugin.finishOrder(product_id, token)

func query_authorized_for_payments() -> bool:
	if not _is_ios():
		return true
	if _host._plugin == null:
		return false
	return _host._plugin.isAuthorizedForPayments()



func _connect_android() -> void :

	_connect_required("purchase_init_success", _android_on_init_success)
	_connect_required("purchase_init_fail", _android_on_init_fail)
	_connect_required("purchase_restored", _android_on_restored)
	_connect_required("purchase_success", _android_on_purchase_success)
	_connect_required("purchase_fail", _android_on_purchase_fail)
	_connect_required("purchase_query_success", _android_on_query_success)
	_connect_required("purchase_query_fail", _android_on_query_fail)
	_connect_required("purchase_finish_order_success", _android_on_finish_order_success)
	_connect_required("purchase_finish_order_fail", _android_on_finish_order_fail)








func _android_on_init_success(products_json: String) -> void :
	native_init_success.emit(_android_products_to_unified(products_json))

func _android_on_init_fail(error_json: String) -> void :
	native_init_fail.emit(error_json)

func _android_on_restored(purchase_json: String) -> void :
	native_restored.emit(purchase_json)

func _android_on_purchase_success(product_id: String, purchase_json: String) -> void :
	native_purchase_success.emit(product_id, purchase_json)

func _android_on_purchase_fail(product_id: String, error_json: String) -> void :
	native_purchase_fail.emit(product_id, error_json)

func _android_on_query_success(purchases_json: String) -> void :
	native_query_success.emit(purchases_json)

func _android_on_query_fail(error_json: String) -> void :
	native_query_fail.emit(error_json)

func _android_on_finish_order_success(product_id: String, token: String) -> void :
	native_finish_order_success.emit(product_id, token)

func _android_on_finish_order_fail(product_id: String, error_json: String) -> void :
	native_finish_order_fail.emit(product_id, error_json)









func _android_products_to_unified(products_json: String) -> String:
	var arr: Variant = _parse_native_json(products_json)
	if not (arr is Array):
		push_warning("[UniKit] Android 商品 JSON 解析失败：%s" % products_json)
		return products_json
	for e: Variant in (arr as Array):
		if e is Dictionary and (e as Dictionary).has("priceAmountMicros"):
			var d: Dictionary = e
			d["price"] = float(d["priceAmountMicros"])
			d.erase("priceAmountMicros")
	return JSON.stringify(arr)



func _connect_ios() -> void :



	_connect_required("purchase_init_success", _ios_on_init_success)
	_connect_required("purchase_init_fail", _ios_on_init_fail)
	_connect_required("purchase_products_fetched", _ios_on_products_fetched)
	_connect_required("purchase_buy_completed", _ios_on_buy_completed)

	_connect_required("purchase_verify_receipt_done", _ios_on_verify_receipt_done)


	_connect_required("purchase_query_success", _ios_on_query_success)
	_connect_required("purchase_query_fail", _ios_on_query_fail)
	_connect_required("purchase_finish_order_success", _ios_on_finish_order_success)
	_connect_required("purchase_finish_order_fail", _ios_on_finish_order_fail)


func _ios_on_init_success() -> void :
	if _product_ids.is_empty():
		print("[UniKit] iOS 内购 init 成功，但商品 ID 列表为空（消费方未填三个 productList）")
		native_init_success.emit("[]")
		return
	print("[UniKit] iOS 内购 init 成功，拉取 %d 个商品的元数据" % _product_ids.size())
	_host._plugin.fetchProducts(JSON.stringify(_product_ids))

func _ios_on_products_fetched(products_json: String) -> void :
	var unified: String = _ios_products_to_unified(products_json)





	if not _product_ids.is_empty() and unified == "[]":
		push_warning("[UniKit] iOS 商品元数据拉取结果为空（要了 %d 个）——多为拉取失败而非商店真的没有商品：请检查商品是否已上架、地区是否支持、网络是否可用"
			%_product_ids.size())
	native_init_success.emit(unified)

func _ios_on_init_fail(error: String) -> void :


	native_init_fail.emit(_ios_error_to_unified(error))


func _ios_on_buy_completed(result: int, transaction_json: String, error_json: String) -> void :
	var pid: String = _ios_product_id_of(transaction_json, error_json)
	if result == _IOS_RESULT_SUCCESS:






		if _ios_is_user_purchase(transaction_json):
			native_purchase_success.emit(pid, _ios_tx_to_unified(transaction_json))
		else:



			var f: Variant = _parse_native_json(transaction_json)
			var d: Dictionary = f if f is Dictionary else {}
			print("[UniKit] iOS 补单交易（非本次主动购买）：%s token=%s，按被动到达处理"
				%[pid, _ios_uint64_to_string(d.get("id", 0))])
			native_restored.emit(_ios_tx_to_unified(transaction_json))
		return
	if result == _IOS_RESULT_CANCELLED:

		native_purchase_fail.emit(pid, _unified_error(_IOS_CODE_USER_CANCELLED, "user cancelled"))
		return
	native_purchase_fail.emit(pid, _ios_error_to_unified(error_json))



const _IOS_FINISH_ERR_NOT_CACHED: int = -2













func _ios_on_finish_order_fail(product_id: String, error_json: String) -> void :
	var d: Variant = _parse_native_json(error_json)
	if d is Dictionary and int((d as Dictionary).get("code", 0)) == _IOS_FINISH_ERR_NOT_CACHED:
		push_warning("[UniKit] iOS 结单失败：交易已不在原生缓存中（多为已结过单），不重试。%s"
			%error_json)
		return
	native_finish_order_fail.emit(product_id, _ios_error_to_unified(error_json))




func _ios_on_query_fail(error_json: String) -> void :
	native_query_fail.emit(_ios_error_to_unified(error_json))

func _ios_on_finish_order_success(product_id: String, token: String) -> void :
	native_finish_order_success.emit(product_id, token)



func _ios_products_to_unified(products_json: String) -> String:
	var arr: Variant = _parse_native_json(products_json)
	if not (arr is Array):
		push_warning("[UniKit] iOS 商品 JSON 解析失败：%s" % products_json)
		return "[]"
	var out: Array = []
	for e: Variant in arr:
		if not (e is Dictionary):
			continue
		var d: Dictionary = e
		out.append({
			"platform": "appstore", 
			"productId": str(d.get("id", "")), 

			"type": str(_IOS_PRODUCT_TYPE.get(int(d.get("type", -1)), "")), 
			"title": str(d.get("display_name", "")), 
			"description": str(d.get("description", "")), 
			"displayPrice": str(d.get("display_price", "")), 

			"price": float(d.get("price", 0.0)), 
			"priceCurrencyCode": str(d.get("currency_code", "")), 
			"subscriptionGroupId": str(d.get("subscription_group_id", "")), 
		})
	return JSON.stringify(out)








const _REFRESH_FAILED_PAYLOAD: String = "{}"













func _ios_on_verify_receipt_done(result_json: String) -> void :
	var d: Variant = _parse_native_json(result_json)
	if not (d is Dictionary) or not (d as Dictionary).has("product_receipts"):
		push_warning("[UniKit] iOS 验票失败或结果不可解析（不做权益对账）：%s" % result_json)
		native_receipt_verified.emit(_REFRESH_FAILED_PAYLOAD)
		return
	var out: Array = []
	for e: Variant in (d as Dictionary).get("product_receipts", []):
		if not (e is Dictionary):
			continue
		var r: Dictionary = e
		out.append({
			"productId": str(r.get("product_id", "")), 

			"token": str(r.get("transaction_id", "")), 
			"orderId": str(r.get("original_transaction_id", "")), 
			"purchaseTime": int(r.get("purchase_time_ms", 0)), 
			"expirationTime": int(r.get("expired_time_ms", 0)), 
		})
	native_receipt_verified.emit(JSON.stringify(out))







func _ios_on_query_success(purchases_json: String) -> void :
	var arr: Variant = _parse_native_json(purchases_json)
	if not (arr is Array):
		push_warning("[UniKit] iOS 恢复购买结果不可解析（不做权益对账）：%s" % purchases_json)
		native_query_success.emit(_REFRESH_FAILED_PAYLOAD)
		return
	var out: Array = []
	for e: Variant in arr:
		if e is Dictionary:
			out.append(_ios_tx_dict_to_unified(e))
	native_query_success.emit(JSON.stringify(out))

func _ios_tx_to_unified(tx_json: String) -> String:
	var d: Variant = _parse_native_json(tx_json)
	if not (d is Dictionary):
		push_warning("[UniKit] iOS 交易 JSON 解析失败：%s" % tx_json)
		return "{}"
	return JSON.stringify(_ios_tx_dict_to_unified(d))

func _ios_tx_dict_to_unified(d: Dictionary) -> Dictionary:
	var t: Dictionary = d
	return {
		"productId": str(t.get("product_id", "")), 
		"token": _ios_uint64_to_string(t.get("id", 0)), 
		"orderId": _ios_uint64_to_string(t.get("original_id", 0)), 
		"purchaseTime": int(t.get("purchase_date_ms", 0)), 
		"innerOrderId": str(t.get("inner_order_id", "")), 
		"signature": "", 
		"purchaseJson": "", 



		"expirationTime": int(t.get("expiration_time_ms", 0)), 
		"revocationTime": int(t.get("revocation_time_ms", 0)), 
		"subscriptionGroupId": str(t.get("subscription_group_id", "")), 
	}

func _ios_error_to_unified(error_json: String) -> String:
	if error_json.is_empty():
		return _unified_error(-1, "")
	var d: Variant = JSON.parse_string(error_json)
	if not (d is Dictionary):

		return _unified_error(-1, error_json)
	var e: Dictionary = d






	return _unified_error(int(e.get("code", -1)), str(e.get("message", "")), 
		str(e.get("reason", "")))



func _unified_error(code: int, message: String, reason_name: String = "") -> String:
	var d: Dictionary = {"errorCode": code, "errorMessage": message}
	if not reason_name.is_empty():
		d["errorReason"] = reason_name
	return JSON.stringify(d)















const _IOS_REASON_RENEWAL: int = 2

func _ios_is_user_purchase(tx_json: String) -> bool:
	var v: Variant = _parse_native_json(tx_json)
	if not (v is Dictionary):
		return true
	var d: Dictionary = v
	if d.has("is_replay"):
		return not bool(d["is_replay"])
	if int(d.get("transaction_reason", 0)) == _IOS_REASON_RENEWAL:
		return false
	return bool(d.get("is_user_purchase", true))


func _ios_product_id_of(tx_json: String, error_json: String) -> String:
	var t: Variant = _parse_native_json(tx_json)
	if t is Dictionary and not str((t as Dictionary).get("product_id", "")).is_empty():
		return str((t as Dictionary).get("product_id"))
	var e: Variant = _parse_native_json(error_json)
	if e is Dictionary:
		return str((e as Dictionary).get("product_id", ""))
	return ""




func _ios_uint64_to_string(v: Variant) -> String:
	if v is float:
		return "%d" % int(v)
	return str(v)



func _connect_required(sig: String, cb: Callable) -> void :
	if _host._plugin != null and _host._plugin.has_signal(sig):
		_host._plugin.connect(sig, cb)
	else:
		push_error("[UniKit] plugin 未声明内购信号 '%s'——原生 bridge 版本过旧，该事件将丢失" % sig)
