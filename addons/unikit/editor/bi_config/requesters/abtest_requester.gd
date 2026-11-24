@tool
class_name UniKitABTestRequester
extends UniKitBIConfigRequester

func config_name() -> String:
	return "abtest"

func get_url(production_id: String, is_debug: bool, _platform: String) -> String:
	var tag: = "-test" if is_debug else ""
	return "https://api%s.learnings.ai/pm/abtest/v6.1/production/%s/params?versionCode=0&expOriginType=A" % [tag, production_id]

func preprocess(content: String) -> String:
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		push_error("[abtest] 响应无 data 字段: %s" % content.substr(0, 200))
		return ""
	return JSON.stringify(parsed["data"])

func get_save_paths(platform: String, is_debug: bool, ios_config_dir: String) -> PackedStringArray:
	if platform == PLATFORM_ANDROID:
		return PackedStringArray([_android_config_dir(is_debug).path_join("abtest_config.json")])
	var fname: = "ABTest_Debug.json" if is_debug else "ABTest.json"
	return PackedStringArray([ios_config_dir.rstrip("/").path_join(fname)])
