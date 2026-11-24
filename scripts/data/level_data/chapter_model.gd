class_name ChapterModel
extends RefCounted






var chapter_index: int = 0

var title: Dictionary = {}


var cover_image_path: String = ""

var thumbnail_image_path: String = ""

var level_total: int = 0


func to_dict() -> Dictionary:
	return {
		"chapter_index": chapter_index, 
		"title": title, 
		"cover_image_path": cover_image_path, 
		"thumbnail_image_path": thumbnail_image_path, 
		"level_total": level_total, 
	}


static func from_dict(d: Dictionary) -> ChapterModel:
	var m: = ChapterModel.new()
	m.chapter_index = int(d.get("chapter_index", 0))
	var raw_title: Variant = d.get("title", {})
	m.title = (raw_title as Dictionary) if raw_title is Dictionary else {}
	m.cover_image_path = String(d.get("cover_image_path", ""))
	m.thumbnail_image_path = String(d.get("thumbnail_image_path", ""))
	m.level_total = int(d.get("level_total", 0))
	return m
