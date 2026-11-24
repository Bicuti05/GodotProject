class_name UniKitPurchaseTransaction
extends RefCounted




var product_id: String = ""


var token: String = ""
var order_id: String = ""
var purchase_time_ms: int = 0

var inner_order_id: String = ""

var signature: String = ""


var purchase_json: String = ""


var expiration_time_ms: int = 0
var revocation_time_ms: int = 0




var subscription_group_id: String = ""


var is_active_purchase: bool = false

static func from_dict(d: Dictionary) -> UniKitPurchaseTransaction:
	var t: = UniKitPurchaseTransaction.new()
	t.product_id = str(d.get("productId", ""))
	t.token = str(d.get("token", ""))
	t.order_id = str(d.get("orderId", ""))
	t.purchase_time_ms = int(d.get("purchaseTime", 0))
	t.inner_order_id = str(d.get("innerOrderId", ""))
	t.signature = str(d.get("signature", ""))
	t.purchase_json = str(d.get("purchaseJson", ""))
	t.expiration_time_ms = int(d.get("expirationTime", 0))
	t.revocation_time_ms = int(d.get("revocationTime", 0))
	t.subscription_group_id = str(d.get("subscriptionGroupId", ""))
	return t



static func from_json(json: String) -> UniKitPurchaseTransaction:
	var d: Variant = JSON.parse_string(json)
	if d is Dictionary:
		return from_dict(d)
	push_warning("[UniKit] 内购交易 JSON 解析失败：%s" % json)
	return UniKitPurchaseTransaction.new()
