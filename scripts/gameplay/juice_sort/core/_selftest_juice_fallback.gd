extends SceneTree



const PARSER: = preload("res://scripts/gameplay/juice_sort/core/juice_level_parser.gd")
const JUICE_LEVEL: = preload("res://scripts/gameplay/juice_sort/core/juice_level.gd")
const LEVEL_MODEL: = preload("res://scripts/data/level_data/level_model.gd")

class EmptyFallbackParser extends JuiceLevelParser:
	func _pick_fallback_row(_level_id: int) -> Dictionary:
		return {}


class ContentMeta extends LevelModel:
	var payload: Dictionary = {}

	func content_dict() -> Dictionary:
		return payload


func _initialize() -> void :
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(PARSER.FALLBACK_PATH))
	if not (doc is Dictionary) or String((doc as Dictionary).get("format", "")) != "juice-fallback-pool/1":
		_fail("兜底池格式不符")
		return
	var rows: Array = (doc as Dictionary).get("levels", []) as Array
	var index_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(PARSER.FALLBACK_INDEX_PATH))
	if not (index_doc is Dictionary) or String((index_doc as Dictionary).get("format", "")) != PARSER.FALLBACK_INDEX_FORMAT:
		_fail("兜底池索引格式不符")
		return
	var offsets: Array = (index_doc as Dictionary).get("offsets", []) as Array
	if rows.size() != 93:
		_fail("兜底池题数应为 93,实为 %d" % rows.size())
		return
	if offsets.size() != rows.size():
		_fail("兜底池行偏移数量与题数不一致")
		return
	var file: FileAccess = FileAccess.open(PARSER.FALLBACK_PATH, FileAccess.READ)

	var seen_unique_ids: Dictionary = {}
	for i in rows.size():
		file.seek(int(offsets[i]))
		var indexed_row: Variant = JSON.parse_string(file.get_line().strip_edges().trim_suffix(","))
		if indexed_row != rows[i]:
			_fail("兜底池第 %d 题的行偏移错误" % (i + 1))
			return
		var unique_id: String = String((rows[i] as Dictionary).get("level_unique_id", ""))
		if unique_id.is_empty():
			_fail("兜底池第 %d 题缺 level_unique_id" % (i + 1))
			return
		if seen_unique_ids.has(unique_id):
			_fail("兜底池第 %d 题的 level_unique_id 与第 %d 题重复" % [i + 1, seen_unique_ids[unique_id]])
			return
		seen_unique_ids[unique_id] = i + 1
		var row: Dictionary = (rows[i] as Dictionary).duplicate(true)
		row["id"] = 77
		var errors: Array[String] = JUICE_LEVEL.from_dict(row).validate()
		if not errors.is_empty():
			_fail("兜底池第 %d 题校验失败: %s" % [i + 1, errors[0]])
			return

	if not _test_flower_type_limit():
		return

	var invalid_row: Dictionary = (rows[0] as Dictionary).duplicate(true)
	invalid_row["whiteJar"] = true
	PARSER.set_debug_row(77, invalid_row)
	var meta: = LEVEL_MODEL.new()
	meta.level_id = 77
	meta.difficulty_type = "Hard"
	meta.level_unique_id = "server-hash-77"
	var parser: = PARSER.new()
	var fallback_result: Dictionary = {}
	var model: JuiceLevelModel = parser.parse_level(meta, fallback_result) as JuiceLevelModel
	PARSER.clear_debug_row()
	if model == null or model.juice == null or model.juice.id != 77 or not model.used_fallback:
		_fail("非法题面未切换到合法兜底题,或未沿用当前关号")
		return

	if model.level_unique_id.is_empty() or model.level_unique_id == "server-hash-77"\
	or model.level_unique_id != String(model.raw.get("level_unique_id", "")):
		_fail("校验失败切兜底后未用兜底题自身 id 覆盖 meta 的服务端 hash")
		return
	if fallback_result != {"triggered": true}:
		_fail("兜底题通过校验后才应返回成功结果")
		return
	if model.difficulty_type != "Hard":
		_fail("新开局未保留服务端困难关元数据")
		return
	var resumed: JuiceLevelModel = parser.model_from_dict(model.to_dict()) as JuiceLevelModel
	if resumed == null or resumed.juice == null or resumed.juice.id != 77 or resumed.raw != model.raw or resumed.used_fallback:
		_fail("兜底题面存档往返后不一致")
		return
	if resumed.difficulty_type != "Hard":
		_fail("困难关续局未保留难度元数据")
		return
	var absent_meta: = LEVEL_MODEL.new()
	absent_meta.level_id = 216
	absent_meta.chapter_index = 9
	absent_meta.level_index = 16
	absent_meta.use_fallback_pool = true
	if not parser.has_level_content(absent_meta):
		_fail("章内缺关的兜底元数据必须通过同步内容判据")
		return
	fallback_result.clear()
	var fallback: JuiceLevelModel = parser.parse_level(absent_meta, fallback_result) as JuiceLevelModel
	if fallback == null or fallback.juice == null or fallback.juice.id != 216\
	or not fallback.used_fallback or fallback.raw.get("id") != 216:
		_fail("章内缺关未从兜底池生成当前关号的题面")
		return
	if fallback_result != {"triggered": true}:
		_fail("章内缺关抽中合法兜底题时应返回成功结果")
		return
	if fallback.difficulty_type != "Normal":
		_fail("缺少难度元数据时未默认普通关")
		return

	if fallback.level_unique_id.is_empty() or not fallback.is_fallback_content()\
	or fallback.level_unique_id != String(fallback.raw.get("level_unique_id", "")):
		_fail("章内缺关的兜底题未携带自身的 level_unique_id")
		return
	var fallback_resumed: JuiceLevelModel = parser.model_from_dict(fallback.to_dict()) as JuiceLevelModel
	if fallback_resumed == null or fallback_resumed.juice.id != 216\
	or fallback_resumed.raw != fallback.raw or fallback_resumed.used_fallback:
		_fail("章内缺关的兜底盘面存档往返不一致")
		return
	if fallback_resumed.level_unique_id != fallback.level_unique_id\
	or not fallback_resumed.is_fallback_content():
		_fail("兜底题的 level_unique_id 必须在续局往返后保持不变")
		return
	var empty_content_meta: = LEVEL_MODEL.new()
	empty_content_meta.level_id = 217
	empty_content_meta.chapter_index = 9
	empty_content_meta.level_index = 17
	var builtin_meta: = LEVEL_MODEL.new()
	builtin_meta.level_id = 1
	builtin_meta.level_unique_id = "server-hash-1"
	builtin_meta.raw_entry = _builtin_level_entry(1, 1)
	fallback_result["empty"] = true
	var builtin: JuiceLevelModel = parser.parse_level(builtin_meta, fallback_result) as JuiceLevelModel
	if builtin == null or builtin.juice == null or builtin.juice.id != 1\
	or builtin.used_fallback or not fallback_result.is_empty():
		_fail("内置章原始条目必须经 initialLayout 解密出题,不得落兜底池")
		return
	if builtin.level_unique_id != "server-hash-1" or builtin.is_fallback_content():
		_fail("非兜底路径不得改动 meta 的服务端 hash")
		return
	if not parser.has_level_content(empty_content_meta):
		_fail("已投放的关条目缺题面时必须允许进入兜底流程")
		return
	var empty_content: JuiceLevelModel = parser.parse_level(empty_content_meta) as JuiceLevelModel
	if empty_content == null or empty_content.juice.id != 217\
	or not empty_content.used_fallback or empty_content.raw.get("id") != 217:
		_fail("已投放但服务端和随包均缺题面时应抽兜底池")
		return
	var empty_content_resumed: JuiceLevelModel = parser.model_from_dict(
		empty_content.to_dict()) as JuiceLevelModel
	if empty_content_resumed == null or empty_content_resumed.raw != empty_content.raw:
		_fail("已投放但缺题面的兜底盘面续局时必须保持原题")
		return
	var empty_parser: = EmptyFallbackParser.new()
	fallback_result.clear()
	if empty_parser.parse_level(absent_meta, fallback_result) != null\
	or fallback_result != {"empty": true}:
		_fail("兜底池不可用时不得生成可通关的空盘面")
		return
	fallback_result.clear()
	if empty_parser.parse_level(empty_content_meta, fallback_result) != null\
	or fallback_result != {"empty": true}:
		_fail("已投放关条目缺题面且兜底池不可用时不得生成空盘面")
		return
	print("[PASS] 93 道兜底题均合法且 level_unique_id 唯一；花色上限、非法题面切换与续局往返通过")
	quit(0)



func _test_flower_type_limit() -> bool:
	var parser: JuiceLevelParser = PARSER.new()
	var ten_colors: Dictionary = _flower_row(10)
	var eleven_colors: Dictionary = _flower_row(11)
	(eleven_colors["incoming"] as Array)[8] = "10|?10,10"
	var sparse_colors: Dictionary = _flower_row(2)
	(sparse_colors["initial"] as Array)[2] = "10|10,10"
	for row: Dictionary in [ten_colors, eleven_colors, sparse_colors]:
		var supported: bool = row == ten_colors
		var juice: JuiceLevel = JUICE_LEVEL.from_dict(row)
		var errors: Array[String] = juice.validate()
		if (supported and not errors.is_empty()) or ( not supported and errors.size() != 1):
			_fail("10 色应通过、超限题面应仅报花色上限错误: %s" % str(errors))
			return false
		var meta: ContentMeta = ContentMeta.new()
		meta.level_id = 77
		meta.level_unique_id = "server-flower-limit"
		meta.payload = row
		var result: Dictionary = {}
		var model: JuiceLevelModel = parser.parse_level(meta, result) as JuiceLevelModel
		if model == null or model.juice == null or model.juice.id != 77:
			_fail("花色上限检查后未生成当前关号的题面")
			return false
		if supported:
			if model.used_fallback or model.juice.types != 10 or not result.is_empty()\
			or model.level_unique_id != meta.level_unique_id:
				_fail("合法 10 色题面不应切换兜底")
				return false
			continue
		if not model.used_fallback or result != {"triggered": true}\
		or model.juice.types > 10 or not model.juice.validate().is_empty()\
		or model.level_unique_id == meta.level_unique_id\
		or model.level_unique_id != String(model.raw.get("level_unique_id", "")):
			_fail("超限花色题面未切换合法兜底题及其唯一 ID")
			return false
		if parser.model_from_dict({"level_id": 77, "raw": row}) != null:
			_fail("超限花色续局应丢弃快照，回落新开局")
			return false
		var empty_parser: EmptyFallbackParser = EmptyFallbackParser.new()
		if empty_parser.parse_level(meta, result) != null or result != {"empty": true}:
			_fail("超限花色且兜底不可用时应返回错误态，不能加载原题")
			return false
	return true


func _flower_row(type_count: int) -> Dictionary:
	var incoming: Array[String] = []
	for type_id: int in range(2, type_count):
		incoming.append("%d|%d,%d" % [type_id, type_id, type_id])
	return {"capacity": 2, "targetCups": type_count, 
		"initial": ["-|", "0|0,0", "1|1,1"], "incoming": incoming}



func _builtin_level_entry(chapter: int, level: int) -> Dictionary:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/builtin/chapter_default_1_5.json"))
	if not (doc is Dictionary):
		return {}
	for c: Variant in (doc as Dictionary).get("data", []) as Array:
		if c is Dictionary and int((c as Dictionary).get("chapterIndex", 0)) == chapter:
			for lv: Variant in (c as Dictionary).get("levels", []) as Array:
				if lv is Dictionary and int((lv as Dictionary).get("levelIndex", 0)) == level:
					return lv
	return {}


func _fail(message: String) -> void :
	printerr("[FAIL] %s" % message)
	quit(1)
