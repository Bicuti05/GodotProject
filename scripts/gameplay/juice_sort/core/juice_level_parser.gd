class_name JuiceLevelParser extends LevelParser

























const FALLBACK_PATH: = "res://assets/game/juice_fallback_levels.json"
const FALLBACK_INDEX_PATH: = "res://assets/game/juice_fallback_levels_index.json"
const FALLBACK_INDEX_FORMAT: = "juice-fallback-pool-index/1"
var _fallback_offsets: Array = []
var _fallback_loaded: bool = false









static var _debug_level: int = 0
static var _debug_row: Dictionary = {}



static func set_debug_row(level: int, row: Dictionary) -> void :
	_debug_level = level
	_debug_row = row



static func clear_debug_row() -> void :
	_debug_level = 0
	_debug_row = {}



static func debug_row_level() -> int:
	return 0 if _debug_row.is_empty() else _debug_level








func gameplay_type() -> String:
	return ""







func has_level_content(meta: LevelModel) -> bool:
	if meta == null:
		return true
	return true


func fill_meta(meta: LevelModel) -> void :
	if meta == null:
		return
	if meta.difficulty_type.strip_edges().is_empty():
		meta.difficulty_type = "Normal"








func model_from_dict(d: Dictionary) -> LevelModel:
	var m: = JuiceLevelModel.new()
	m.from_dict(d)
	if m.juice == null:
		push_warning("JuiceLevelParser: 存档里的题面建不起来,丢弃快照回落新开局")
		return null
	var errs: Array[String] = m.juice.validate()
	if not errs.is_empty():
		push_warning("JuiceLevelParser: 存档里的题面校验不过,丢弃快照回落新开局:%s" % errs[0])
		return null
	return m



func parse_level(meta: LevelModel, fallback_result: Dictionary = {}) -> LevelModel:
	fallback_result.clear()
	if meta == null:
		push_error("JuiceLevelParser: parse_level 收到 null meta")
		return null


	var row: Variant = _debug_override_for(meta.level_id)

	var from_debug_csv: bool = meta.is_debug_csv_content()
	if from_debug_csv:
		row = null
	var from_fallback: bool = false
	if row == null and meta.use_fallback_pool:
		row = _pick_fallback_row(meta.level_id)
		if (row as Dictionary).is_empty():
			fallback_result["empty"] = true
			return null
		from_fallback = true
	if row == null:

		var payload: Dictionary = meta.content_dict()
		if not payload.is_empty():




			row = payload.duplicate(true)
			(row as Dictionary)["id"] = meta.level_id
	if row == null:
		if from_debug_csv:
			push_error("JuiceLevelParser: CSV 第 %d 关（%s）题面不是有效 JSON 对象，没有进入测试关"
				%[meta.level_id, meta.level_user_tags])
			return null
		push_warning("JuiceLevelParser: 第 %d 关章数据里没有题面,改用随包兜底池" % meta.level_id)
		row = _pick_fallback_row(meta.level_id)
		if (row as Dictionary).is_empty():
			fallback_result["empty"] = true
			return null
		from_fallback = true

	var raw: Dictionary = row
	var juice: = JuiceLevel.from_dict(raw)
	var errs: Array[String] = juice.validate()
	if not errs.is_empty():
		if from_debug_csv:
			push_error("JuiceLevelParser: CSV 第 %d 关（%s）题面校验不通过，没有进入测试关:\n  %s"
				%[meta.level_id, meta.level_user_tags, "\n  ".join(errs)])
			return null
		if from_fallback:
			push_error("JuiceLevelParser: 第 %d 关抽到的兜底题校验不通过:\n  %s"
				%[meta.level_id, "\n  ".join(errs)])
			fallback_result["empty"] = true
			return null
		push_warning("JuiceLevelParser: 第 %d 关题面校验不通过,改用随包兜底池:\n  %s"
			%[meta.level_id, "\n  ".join(errs)])
		raw = _pick_fallback_row(meta.level_id)
		if raw.is_empty():
			fallback_result["empty"] = true
			return null
		juice = JuiceLevel.from_dict(raw)
		errs = juice.validate()
		if not errs.is_empty():
			push_error("JuiceLevelParser: 第 %d 关抽到的兜底题校验不通过:\n  %s"
				%[meta.level_id, "\n  ".join(errs)])
			fallback_result["empty"] = true
			return null
		from_fallback = true

	var m: = JuiceLevelModel.new()
	meta._copy_meta_into(m)
	m.raw = raw
	m.juice = juice
	m.used_fallback = from_fallback
	fill_meta(m)
	if from_fallback:



		var fallback_id: String = String(raw.get("level_unique_id", ""))
		if not fallback_id.is_empty():
			m.level_unique_id = fallback_id
		fallback_result["triggered"] = true
	return m





func _pick_fallback_row(level_id: int) -> Dictionary:
	if not _fallback_loaded:
		_fallback_loaded = true
		if not FileAccess.file_exists(FALLBACK_INDEX_PATH):
			push_error("JuiceLevelParser: 兜底题库索引不存在 %s" % FALLBACK_INDEX_PATH)
			return {}
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FALLBACK_INDEX_PATH))
		if not (parsed is Dictionary):
			push_error("JuiceLevelParser: 兜底题库索引不是 JSON 对象 %s" % FALLBACK_INDEX_PATH)
			return {}
		var doc: Dictionary = parsed
		if String(doc.get("format", "")) != FALLBACK_INDEX_FORMAT or not (doc.get("offsets") is Array):
			push_error("JuiceLevelParser: 兜底题库索引格式不符 %s" % FALLBACK_INDEX_PATH)
			return {}
		_fallback_offsets = doc["offsets"]
	if _fallback_offsets.is_empty():
		push_error("JuiceLevelParser: 兜底题库为空 %s" % FALLBACK_PATH)
		return {}
	var index: int = randi_range(0, _fallback_offsets.size() - 1)
	var file: FileAccess = FileAccess.open(FALLBACK_PATH, FileAccess.READ)
	if file == null:
		push_error("JuiceLevelParser: 兜底题库打不开 %s" % FALLBACK_PATH)
		return {}
	file.seek(int(_fallback_offsets[index]))
	var line: String = file.get_line().strip_edges().trim_suffix(",")
	var picked: Variant = JSON.parse_string(line)
	if not (picked is Dictionary):
		push_error("JuiceLevelParser: 兜底题库第 %d 题不是 JSON 对象" % (index + 1))
		return {}
	var row: Dictionary = picked
	row["id"] = level_id
	print("[JuiceLevelParser] 第 %d 关使用兜底题库第 %d 题" % [level_id, index + 1])
	return row







func _debug_override_for(level_id: int) -> Variant:
	if OS.has_feature("rel") or _debug_row.is_empty() or level_id != _debug_level:
		return null
	print("[JuiceLevelParser] 第 %d 关用的是调试题面(cheat juice_json / HTTP /juice-level 灌入)" % level_id)
	return _debug_row
