class_name LevelIndex
extends RefCounted







const CHAPTER_SIZE: = 25



static func is_chapter_end(level_id: int) -> bool:
	return level_id > 0 and level_id % CHAPTER_SIZE == 0



static func is_coming_soon_boundary(level_id: int) -> bool:
	return is_chapter_end(level_id)



static func chapter_of(level_id: int) -> int:
	return (level_id - 1) / CHAPTER_SIZE + 1



static func index_of(level_id: int) -> int:
	return (level_id - 1) % CHAPTER_SIZE + 1



static func level_id_of(chapter_index: int, level_index: int) -> int:
	return (chapter_index - 1) * CHAPTER_SIZE + level_index
