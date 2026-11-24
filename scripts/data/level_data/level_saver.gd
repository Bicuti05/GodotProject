class_name LevelSaver
extends RefCounted









func load_entity(level_id: int) -> LevelEntity:
	return LevelEntity.from_row(DbManager.load_level_entity(level_id))



func load_resume_preview(level_id: int) -> Dictionary:
	var row: Dictionary = DbManager.load_level_entity(level_id)
	var state: Variant = row.get("current_state")
	return {"has_resume": state != null and String(state) not in ["", "{}", "null"], 
		"completed": int(row.get("completed", 0)) == 1, 
		"updated_at": int(row.get("updated_at", 0)), 
		"raw_level_info": String(row.get("raw_level_info")) if row.get("raw_level_info") != null else "{}"}










func save_initial(level_id: int, raw_level_info: Dictionary, initial_state: Dictionary) -> String:
	var e: = LevelEntity.for_level(level_id)
	e.game_id = LevelEntity.new_game_id()
	e.raw_level_info = raw_level_info
	e.initial_state = initial_state
	e.current_state = initial_state
	e.updated_at = _now_ms()
	DbManager.save_level_entity(e.to_row())
	return e.game_id





func save_state(level_id: int, current_state: Dictionary, play_time_delta_ms: int = 0, 
		round_ms: int = -1) -> void :
	DbManager.update_level_state(level_id, JSON.stringify(current_state), _now_ms(), 
		play_time_delta_ms, round_ms)




func add_play_time(level_id: int, delta_ms: int, round_ms: int = -1) -> bool:
	return DbManager.add_level_play_time(level_id, delta_ms, round_ms)



func load_round_play_time_ms(level_id: int) -> int:
	return DbManager.load_round_play_time_ms(level_id)



func inc_counter(level_id: int, column: String) -> bool:
	return DbManager.inc_level_counter(level_id, column)



func load_start_times(level_id: int) -> int:
	var row: Dictionary = DbManager.load_level_entity(level_id)
	if row.is_empty():
		return 0
	return int(row.get(DbManager.START_TIMES_COLUMN, 0))




func load_ztime_stats(level_id: int) -> Dictionary:
	var row: Dictionary = DbManager.load_level_entity(level_id)
	if row.is_empty():
		return {}
	var out: Dictionary = {}
	for column: String in DbManager.ZTIME_COLUMNS:
		var v: Variant = row.get(column)
		out[column] = int(v) if v != null else 0
	return out



func clear_state(level_id: int) -> bool:
	return DbManager.clear_level_state(level_id)





func mark_completed(level_id: int, statistics: Dictionary) -> bool:
	return DbManager.mark_level_completed(
		level_id, 
		int(statistics.get("score", 0)), 
		int(statistics.get("cost_time_ms", 0)), 
		_now_ms(), 
		true)




func flush() -> void :
	pass


static func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
