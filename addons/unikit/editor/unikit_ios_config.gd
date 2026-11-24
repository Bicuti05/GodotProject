@tool
class_name UniKitIOSConfig
extends Resource



@export_group("Common（必填）")
@export var production_id: String = ""

@export_group("Analyze（必填）")
@export var analyze_key_id: String = ""
@export var analyze_secret: String = ""

@export_group("Push（必填）")
@export var push_key_id: String = ""
@export var push_secret: String = ""

@export_group("AppsFlyer（必填）")
@export var appsflyer_dev_key: String = ""
@export var app_store_id: String = ""
@export var app_store_url: String = ""

@export_group("AdMob（必填）")
@export var admob_app_id: String = ""

@export_group("广告 SDK 大版本")




@export_enum("AD6", "AD7") var ad_major_version: int = 1

@export_group("TikTok（可空）")
@export var tiktok_app_id: String = ""
@export var tiktok_secret: String = ""

func validate() -> Array[String]:
	var errors: Array[String] = []
	if production_id.is_empty(): errors.append("production_id")
	if analyze_key_id.is_empty(): errors.append("analyze_key_id")
	if analyze_secret.is_empty(): errors.append("analyze_secret")
	if push_key_id.is_empty(): errors.append("push_key_id")
	if push_secret.is_empty(): errors.append("push_secret")
	if appsflyer_dev_key.is_empty(): errors.append("appsflyer_dev_key")
	if app_store_id.is_empty(): errors.append("app_store_id")
	if app_store_url.is_empty(): errors.append("app_store_url")
	if admob_app_id.is_empty(): errors.append("admob_app_id")
	return errors
