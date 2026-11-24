@tool
class_name UniKitUserTagRequester
extends UniKitBIConfigRequester

func config_name() -> String:
	return "usertag"

func supports_platform(platform: String) -> bool:
	return platform == PLATFORM_IOS

func get_url(production_id: String, _is_debug: bool, _platform: String) -> String:
	return "https://api.learnings.ai/usertag/low_perf_devices/%s?apiKey=%s" % [production_id, APIKEY_USERTAG]

func get_request_headers() -> Dictionary:

	var app_name: = str(ProjectSettings.get_setting("application/config/name", "godot"))
	var app_ver: = str(ProjectSettings.get_setting("application/config/version", "0"))
	return {"x-learnings-caller": "%s-%s" % [app_name, app_ver]}

func get_save_paths(platform: String, _is_debug: bool, ios_config_dir: String) -> PackedStringArray:
	if platform != PLATFORM_IOS:
		return PackedStringArray()
	return PackedStringArray([ios_config_dir.rstrip("/").path_join("UserTagLowPerfDevice.json")])
