class_name SpecialChallengeSaver
extends RefCounted


func load_resume_preview(instance_id: String) -> Dictionary:
	var row: Dictionary = DbManager.load_special_challenge(instance_id)
	return {"raw_level_info": String(row.get("raw_level_info")) if row.get("raw_level_info") != null else "{}", 
		"updated_at": int(row.get("updated_at", 0))}


func load_session(instance_id: String) -> Dictionary:
	var row: Dictionary = DbManager.load_special_challenge(instance_id)
	if row.is_empty():
		return {}
	var result: Dictionary = {"game_id": String(row.get("game_id", "")), 
		"round_ms": int(row.get("cost_time_ms", 0)), "updated_at": int(row.get("updated_at", 0))}
	for field: String in ["raw_level_info", "initial_state", "current_state"]:
		var value: Variant = JSON.parse_string(String(row.get(field, "{}")))
		result[field] = value if value is Dictionary else {}
	return result

func save_initial(instance_id: String, model: LevelModel, state: Dictionary, 
		game_id: String = "") -> bool:
	var round_id: String = game_id if not game_id.is_empty() else LevelEntity.new_game_id()
	return DbManager.save_special_challenge({"instance_id": instance_id, 
		"game_id": round_id, "raw_level_info": JSON.stringify(model.to_dict()), 
		"initial_state": JSON.stringify(state), "current_state": JSON.stringify(state), 
		"updated_at": Time.get_unix_time_from_system() * 1000.0})

func save_state(instance_id: String, state: Dictionary, round_ms: int = -1) -> bool:
	return DbManager.update_special_challenge(instance_id, JSON.stringify(state), round_ms)

func add_play_time(instance_id: String, round_ms: int) -> bool:
	if round_ms < 0:
		return false
	return DbManager.update_special_challenge_time(instance_id, round_ms)

func complete(instance_id: String) -> bool:
	return DbManager.complete_special_challenge(instance_id)
