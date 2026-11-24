@tool
class_name UniKitBIConfigRequester
extends RefCounted




const PLATFORM_ANDROID: = "android"
const PLATFORM_IOS: = "ios"



const AD_MAJOR_6: = 0
const AD_MAJOR_7: = 1


var ad_major_version: int = AD_MAJOR_7


const APIKEY_ADCONFIG_IOS: = "893ea460-b845-4cad-a983-75957ce9f3c4"
const APIKEY_ADCONFIG_ANDROID: = "c63cf6be-0a70-4d4c-b10f-acaafa09b3f1"
const APIKEY_USERTAG: = "893ea460-b845-4cad-a983-75957ce9f3c4"



const ANDROID_CONFIG_DIR_RELEASE: = "res://android/build/src/release/assets/config"
const ANDROID_CONFIG_DIR_DEBUG: = "res://android/build/src/debug/assets/config"

func config_name() -> String:
	return "base"

func get_url(_production_id: String, _is_debug: bool, _platform: String) -> String:
	return ""

func preprocess(content: String) -> String:
	return content

func get_save_paths(_platform: String, _is_debug: bool, _ios_config_dir: String) -> PackedStringArray:
	return PackedStringArray()

func supports_platform(_platform: String) -> bool:
	return true

func get_request_headers() -> Dictionary:
	return {}


func _android_config_dir(is_debug: bool) -> String:
	return ANDROID_CONFIG_DIR_DEBUG if is_debug else ANDROID_CONFIG_DIR_RELEASE
