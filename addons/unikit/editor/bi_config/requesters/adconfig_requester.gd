@tool
class_name UniKitAdConfigRequester
extends UniKitBIConfigRequester

func config_name() -> String:
	return "adconfig"




func get_url(production_id: String, is_debug: bool, platform: String) -> String:
	var tag: = "-test" if is_debug else ""
	var api_key: = APIKEY_ADCONFIG_IOS if platform == PLATFORM_IOS else APIKEY_ADCONFIG_ANDROID
	var path: = "v6/production/%s/strategies" if ad_major_version == AD_MAJOR_6\
	else "v7/production/%s/fallback/strategies"
	return "https://api%s.learnings.ai/adconfig/%s?apiKey=%s"\
	%[tag, path % production_id.strip_edges(), api_key]





func preprocess(content: String) -> String:
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[adconfig] 响应非 JSON object: %s" % content.substr(0, 200))
		return ""
	if typeof(parsed.get("data")) != TYPE_DICTIONARY:
		push_error("[adconfig] 响应无 data object: %s" % content.substr(0, 200))
		return ""
	return JSON.stringify(parsed["data"])

func get_save_paths(platform: String, is_debug: bool, ios_config_dir: String) -> PackedStringArray:
	if platform == PLATFORM_ANDROID:
		return PackedStringArray([_android_config_dir(is_debug).path_join("ad_config.json")])
	return PackedStringArray([ios_config_dir.rstrip("/").path_join("adconfigs.bundle/ad_config.json")])
