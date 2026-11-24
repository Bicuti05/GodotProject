class_name LevelParser
extends RefCounted










func gameplay_type() -> String:
	push_error("LevelParser.gameplay_type() 未实现")
	return ""



func fill_meta(_meta: LevelModel) -> void :
	pass




func model_from_dict(_d: Dictionary) -> LevelModel:
	push_error("LevelParser.model_from_dict() 未实现")
	return null




func parse_level(_meta: LevelModel, _fallback_result: Dictionary = {}) -> LevelModel:
	push_error("LevelParser.parse_level() 未实现")
	return null









func has_level_content(_meta: LevelModel) -> bool:
	return true









static func parse_chapter_envelope(raw_chapter: Dictionary) -> Dictionary:
	var chapter_meta: = ChapterModel.new()
	chapter_meta.chapter_index = int(raw_chapter.get("chapterIndex", 0))
	var raw_title: Variant = raw_chapter.get("title", {})
	chapter_meta.title = (raw_title as Dictionary) if raw_title is Dictionary else {}

	var raw_levels: Variant = raw_chapter.get("levels", [])
	var levels: Array = (raw_levels as Array) if raw_levels is Array else []

	chapter_meta.level_total = levels.size()

	var by_index: Dictionary = {}
	for raw_level_variant: Variant in levels:
		if not (raw_level_variant is Dictionary):
			continue
		var raw_level: Dictionary = raw_level_variant
		var level_index: int = int(raw_level.get("levelIndex", 0))
		if level_index <= 0:
			continue
		var bucket: Array[Dictionary] = by_index.get(level_index, [] as Array[Dictionary])
		bucket.append(raw_level)
		by_index[level_index] = bucket

	return {
		"chapter_meta": chapter_meta, 
		"cover_image_url": String(raw_chapter.get("cardImageUrl", "")), 
		"thumbnail_image_url": String(raw_chapter.get("cardThumbnailUrl", "")), 
		"level_candidates_by_index": by_index, 
	}




static func build_level_meta(chapter_index: int, level_index: int, raw_level: Dictionary) -> LevelModel:
	var m: = LevelModel.new()
	m.level_id = LevelIndex.level_id_of(chapter_index, level_index)
	m.chapter_index = chapter_index
	m.level_index = level_index
	m.difficulty_type = String(raw_level.get("difficultyType", ""))
	m.difficulty = clampi(int(raw_level.get("difficulty", 1)), 1, 5)
	m.gameplay_type = String(raw_level.get("gameplayType", ""))
	m.level_user_tags = String(raw_level.get("levelUserTags", "default"))
	m.level_data_source = String(raw_level.get("levelDataSource", ""))
	m.level_unique_id = String(raw_level.get("levelUniqueId", ""))


	m.raw_entry = raw_level
	return m
