class_name TrackingCommonParams
extends RefCounted






































var level_num: int = 0

var level_type: String = ""

var level_unique_id: String = ""

var chapter_index: int = 0

var game_id: String = ""

var level_index: int = 0

var level_data_source: String = ""

var difficulty_level: String = ""




func to_dict() -> Dictionary:
	return {
		TrackingEvents.K_LEVEL_NUM: level_num, 
		TrackingEvents.K_LEVEL_TYPE: level_type, 
		TrackingEvents.K_LEVEL_UNIQUE_ID: level_unique_id, 
		TrackingEvents.K_CHAPTER_INDEX: chapter_index, 
		TrackingEvents.K_GAME_ID: game_id, 
		TrackingEvents.K_LEVEL_INDEX: level_index, 
		TrackingEvents.K_LEVEL_DATA_SOURCE: level_data_source, 
		TrackingEvents.K_DIFFICULTY_LEVEL: difficulty_level, 
	}
