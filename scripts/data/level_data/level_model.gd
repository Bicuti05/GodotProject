class_name LevelModel
extends RefCounted

const DEBUG_CSV_SOURCE_PREFIX: = "debug_csv:"








var level_id: int = 0

var round_kind: String = "level"
var challenge_instance_id: String = ""

var special_challenge_schedule: Dictionary = {}

var chapter_index: int = 0

var level_index: int = 0



var level_unique_id: String = ""

var difficulty_type: String = ""

var difficulty: int = 1

var gameplay_type: String = ""

var level_user_tags: String = "default"

var level_data_source: String = ""







var raw_entry: Dictionary = {}



var use_fallback_pool: bool = false


var _content: Dictionary = {}
var _content_parsed: bool = false








func is_super_hard() -> bool:
	return difficulty_type.strip_edges().to_lower() == "superhard"


func has_content_payload() -> bool:
	return not String(raw_entry.get("initialLayout", "")).is_empty()



func is_debug_csv_content() -> bool:
	return OS.has_feature("editor") and not OS.has_feature("rel")\
	and level_data_source.begins_with(DEBUG_CSV_SOURCE_PREFIX)







func content_dict() -> Dictionary:
	if _content_parsed:
		return _content
	_content_parsed = true
	var cipher: String = String(raw_entry.get("initialLayout", ""))
	if cipher.is_empty():
		return _content
	if is_debug_csv_content():
		var debug_payload: Variant = JSON.parse_string(cipher)
		if debug_payload is Dictionary:
			_content = debug_payload
		return _content
	var plain: String = AESDecryptor.decrypt(cipher)
	if plain.is_empty():
		push_warning("LevelModel: 第 %d 关的 initialLayout 解密失败，回落随包兜底池" % level_id)
		return _content
	var parsed: Variant = JSON.parse_string(plain)
	if not (parsed is Dictionary):
		push_warning("LevelModel: 第 %d 关的 initialLayout 解出来不是 JSON 对象，回落随包兜底池" % level_id)
		return _content
	_content = parsed
	return _content



func duplicate_model() -> LevelModel:
	var d: = LevelModel.new()
	_copy_meta_into(d)
	return d






func _copy_meta_into(dst: LevelModel) -> void :
	dst.level_id = level_id
	dst.round_kind = round_kind
	dst.challenge_instance_id = challenge_instance_id
	dst.special_challenge_schedule = special_challenge_schedule.duplicate()
	dst.chapter_index = chapter_index
	dst.level_index = level_index
	dst.difficulty_type = difficulty_type
	dst.difficulty = difficulty
	dst.gameplay_type = gameplay_type
	dst.level_user_tags = level_user_tags
	dst.level_data_source = level_data_source
	dst.level_unique_id = level_unique_id






func to_dict() -> Dictionary:
	return {
		"level_id": level_id, 
		"round_kind": round_kind, 
		"challenge_instance_id": challenge_instance_id, 
		"special_challenge_schedule": special_challenge_schedule.duplicate(), 
		"chapter_index": chapter_index, 
		"level_index": level_index, 
		"difficulty_type": difficulty_type, 
		"difficulty": difficulty, 
		"gameplay_type": gameplay_type, 
		"level_user_tags": level_user_tags, 
		"level_data_source": level_data_source, 
		"level_unique_id": level_unique_id, 
	}



func from_dict(d: Dictionary) -> void :
	level_id = int(d.get("level_id", 0))
	round_kind = String(d.get("round_kind", "level"))
	challenge_instance_id = String(d.get("challenge_instance_id", ""))
	special_challenge_schedule = (d.get("special_challenge_schedule", {}) as Dictionary).duplicate()
	chapter_index = int(d.get("chapter_index", 0))
	level_index = int(d.get("level_index", 0))
	difficulty_type = String(d.get("difficulty_type", ""))
	difficulty = clampi(int(d.get("difficulty", 1)), 1, 5)
	gameplay_type = String(d.get("gameplay_type", ""))
	level_user_tags = String(d.get("level_user_tags", "default"))
	level_data_source = String(d.get("level_data_source", ""))
	level_unique_id = String(d.get("level_unique_id", ""))


func is_special_challenge() -> bool:
	return round_kind == "special_challenge"
