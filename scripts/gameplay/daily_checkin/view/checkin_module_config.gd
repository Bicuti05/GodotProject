extends RefCounted

const PATH: = "res://assets/effect/daily_checkin/checkin_module_config.json"
static var cached: Dictionary = {}
static func read() -> Dictionary:
	if cached.is_empty():
		cached = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		assert (cached.get("version", 0) == 1, "Unsupported checkin presentation config")
		assert (cached.has("roles") and cached.has("ui") and cached.has("focus"))
	return cached.duplicate(true)
