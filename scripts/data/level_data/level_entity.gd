class_name LevelEntity
extends RefCounted







var level_id: int = 0
var chapter_index: int = 0
var level_index: int = 0

var completed: bool = false







var statistics: Dictionary = {"score": 0, "cost_time_ms": 0, "completed_at": 0}


var raw_level_info: Dictionary = {}

var initial_state: Dictionary = {}

var current_state: Dictionary = {}







var game_id: String = ""


var updated_at: int = 0


static func for_level(level_id: int) -> LevelEntity:
	var e: = LevelEntity.new()
	e.level_id = level_id
	e.chapter_index = LevelIndex.chapter_of(level_id)
	e.level_index = LevelIndex.index_of(level_id)
	return e






static func new_game_id() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex: String = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12), 
	]


func to_row() -> Dictionary:
	return {
		"level_id": level_id, 
		"completed": 1 if completed else 0, 
		"score": int(statistics.get("score", 0)), 
		"cost_time_ms": int(statistics.get("cost_time_ms", 0)), 
		"completed_at": int(statistics.get("completed_at", 0)), 
		"updated_at": updated_at, 
		"game_id": game_id, 
		"raw_level_info": JSON.stringify(raw_level_info), 
		"initial_state": JSON.stringify(initial_state), 
		"current_state": JSON.stringify(current_state) if not current_state.is_empty() else "{}", 
	}



static func from_row(row: Dictionary) -> LevelEntity:
	if row.is_empty():
		return null
	var e: = LevelEntity.for_level(int(row.get("level_id", 0)))
	e.completed = int(row.get("completed", 0)) == 1
	e.statistics = {
		"score": int(row.get("score", 0)), 
		"cost_time_ms": int(row.get("cost_time_ms", 0)), 
		"completed_at": int(row.get("completed_at", 0)), 
	}
	e.updated_at = int(row.get("updated_at", 0))


	var game_id_raw: Variant = row.get("game_id")
	e.game_id = String(game_id_raw) if game_id_raw != null else ""
	e.raw_level_info = _parse_blob(row.get("raw_level_info"))
	e.initial_state = _parse_blob(row.get("initial_state"))
	e.current_state = _parse_blob(row.get("current_state"))
	return e


static func _parse_blob(raw: Variant) -> Dictionary:
	var text: = String(raw) if raw != null else ""
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return (parsed as Dictionary) if parsed is Dictionary else {}
