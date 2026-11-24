class_name JuiceCsvTestBank
extends Node


const REQUIRED_HEADERS: = ["章节", "关卡", "levelUserTags", "关卡信息"]

var _picker: FileDialog
var _message: AcceptDialog
var _last_path: String = ""
var _group_counts: Dictionary = {}
var _loading: bool = false
var _switching: bool = false
var _generation: int = 0
var _title_timer: Timer
var _original_window_title: String = ""


func _ready() -> void :
	if not OS.has_feature("editor") or OS.has_feature("rel"):
		return
	_title_timer = Timer.new()
	_title_timer.wait_time = 0.5
	_title_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_title_timer.timeout.connect(_update_window_title)
	add_child(_title_timer)


func _exit_tree() -> void :
	_restore_window_title()


func _update_window_title() -> void :
	var level: int = UserState.get_current_level()
	var page: Node = SceneManager.get_page("game")
	if page != null and bool(page.get("visible")):
		var model: LevelModel = page.get("_level_model") as LevelModel
		if model != null:

			level = model.level_id
	var title: String = "%s · %s · 第 %d 关" % [_original_window_title, _last_path.get_file(), level]
	if get_tree().root.title != title:
		get_tree().root.title = title


func _restore_window_title() -> void :
	if _title_timer == null or _title_timer.is_stopped():
		return
	_title_timer.stop()
	get_tree().root.title = _original_window_title


func import_dropped_files(files: PackedStringArray) -> void :
	if not _available():
		return
	if files.size() != 1:
		_show_message("请每次拖入一个 CSV 测试题库文件。")
		return
	var path: String = files[0]
	if path.get_extension().to_lower() != "csv" or DirAccess.dir_exists_absolute(path):
		_show_message("请拖入 CSV 测试题库文件，不支持文件夹或其他文件格式。")
		return
	await import_file(path)


func choose_file() -> void :
	if not _available() or _loading or _switching:
		return
	if _picker == null:
		_picker = FileDialog.new()
		_picker.title = "选择测试题库 CSV"
		_picker.access = FileDialog.ACCESS_FILESYSTEM
		_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_picker.filters = PackedStringArray(["*.csv ; CSV 关卡表"])
		_picker.use_native_dialog = true
		_picker.process_mode = Node.PROCESS_MODE_ALWAYS
		_picker.file_selected.connect(_on_file_selected)
		add_child(_picker)
	if not _last_path.is_empty():
		_picker.current_path = _last_path
	_picker.popup_centered_ratio(0.8)


func _available() -> bool:
	if not OS.has_feature("editor") or OS.has_feature("rel"):
		SceneManager.show_toast("CSV 题库测试仅在 Godot 编辑器运行的客户端可用")
		return false
	if _loading or _switching:
		SceneManager.show_toast("正在导入或切换测试题库，请稍候")
		return false
	return true


func _on_file_selected(path: String) -> void :
	await import_file(path)


func import_file(path: String) -> void :
	if not _available():
		return
	if _has_pending_special():
		return
	_loading = true
	_generation += 1
	var generation: int = _generation
	var job: Dictionary = {}
	SceneManager.show_toast("正在读取 CSV 测试题库")
	var task: int = WorkerThreadPool.add_task(_read_job.bind(path, job))
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	_loading = false
	if generation != _generation:
		return
	var result: Dictionary = job["result"]
	if not bool(result["ok"]):
		_show_message(String(result["message"]))
		return
	if _has_pending_special():
		return
	var candidates: Dictionary = result["candidates"]
	var levels: Array = result["levels"]
	var first_level: int = int(levels[0])

	var user_tags: Dictionary = {}
	var tag_value: String = UserLevelLadder.tag_value(UserState.get_user_level())
	if not tag_value.is_empty():
		user_tags[UserLevelTag.TAG_KEY] = tag_value
	var first: Dictionary = LevelProvider.pick(candidates[first_level], user_tags)
	var meta: LevelModel = LevelParser.build_level_meta(
		LevelIndex.chapter_of(first_level), LevelIndex.index_of(first_level), first)
	if JuiceLevelParser.new().parse_level(meta) == null:
		_show_message("第 %d 关（%s）题面校验失败，题库未切换。请查看 Godot 输出中的具体原因。"
			%[first_level, meta.level_user_tags])
		return
	_switching = true
	SceneManager.hide_all_dialogs()

	SceneManager.hide_page("game")
	JuiceDebugLevel.clear()
	var installed: bool = await LevelManager.cheat_set_csv_levels(candidates, String(result["title"]))
	_switching = false
	if not installed:
		_show_message("测试题库切换失败，请查看 Godot 输出；原题库来源保留。")
		SceneManager.show_page("home")
		return
	_last_path = path
	_group_counts = result["group_counts"]
	UserState.cheat_jump_to_level(first_level)

	if first_level == 1:
		UserState.set_tutorial_done(true)
	SceneManager.show_page("game")
	SceneManager.hide_page("home")
	if _title_timer.is_stopped():
		_original_window_title = get_tree().root.title
	_title_timer.start()
	_update_window_title()
	SortLogger.info("[CsvTest] 已导入 %s，%d 关 / %d 道题，能力档保持 lv%d" % [
		String(result["title"]), levels.size(), int(result["row_count"]), UserState.get_user_level()])
	SceneManager.show_toast("已导入 %d 关 / %d 道题，从第 %d 关开始，按当前能力自动选题"
		%[levels.size(), int(result["row_count"]), first_level])


func _has_pending_special() -> bool:
	if UserState.has_special_challenge() or UserState.get_special_challenge_offer_after() > 0:
		_show_message("当前有未完成或待领取的特殊挑战，请完成并领取后再导入测试题库。")
		return true
	return false


func stop() -> void :
	if not OS.has_feature("editor") or OS.has_feature("rel"):
		return
	if _switching:
		SceneManager.show_toast("正在切换题库，请完成后再结束测试")
		return
	_generation += 1
	var status: Dictionary = LevelManager.cheat_csv_level_status()
	if not bool(status["active"]):
		SceneManager.show_toast("已取消导入" if _loading else "当前没有启用 CSV 测试题库")
		return
	_switching = true
	SceneManager.hide_all_dialogs()
	SceneManager.hide_page("game")
	var stopped: bool = await LevelManager.cheat_set_csv_levels({})
	_switching = false
	if stopped:
		_group_counts = {}
		_restore_window_title()
		SortLogger.info("[CsvTest] 已结束测试，恢复正式题库；开发存档进度和能力保留")
		SceneManager.show_toast("已结束题库测试，恢复正式题库；进度和能力保留")
	else:
		_show_message("结束测试失败，请查看 Godot 输出后重试。")
	SceneManager.show_page("home")


func show_status() -> void :
	if not OS.has_feature("editor") or OS.has_feature("rel"):
		return
	var status: Dictionary = LevelManager.cheat_csv_level_status()
	if not bool(status["active"]):
		_show_message("正在导入 CSV" if _loading else "当前没有启用 CSV 测试题库。")
		return
	var levels: Array = status["levels"]
	var lines: Array[String] = [String(status["title"]), 
		"覆盖 %d 关（%d～%d），共 %d 道题" % [levels.size(), int(levels[0]), int(levels[-1]), _row_count()], 
		"当前关号：%d；能力：%s" % [UserState.get_current_level(), 
			UserLevelLadder.tag_value(UserState.get_user_level()) if UserState.get_user_level() > 0 else "未起步"], 
		"分组：%s" % str(_group_counts)]
	var page: Node = SceneManager.get_page("game")
	var model: LevelModel = page.get("_level_model") as LevelModel if page != null and bool(page.get("visible")) else null
	if model != null:
		lines.append("正在玩的题：%s\n题目ID：%s\n来源：%s" % [
			model.level_user_tags, model.level_unique_id, model.level_data_source])
	else:
		var meta: LevelModel = LevelManager.get_level_model(
			LevelIndex.chapter_of(UserState.get_current_level()), LevelIndex.index_of(UserState.get_current_level()))
		if meta != null:
			lines.append("下次新开局命中：%s\n题目ID：%s" % [meta.level_user_tags, meta.level_unique_id])
	lines.append("通关会更新进度与能力；重开和道具按现有规则处理。\n表内缺少对应能力组时回落 default。表外关号使用正式题库。\n跳关：level 关号；切换能力：user_level 0～5。")
	_show_message("\n\n".join(lines))


func _row_count() -> int:
	var count: int = 0
	for value: int in _group_counts.values():
		count += value
	return count


func _show_message(message: String) -> void :
	if _message == null:
		_message = AcceptDialog.new()
		_message.title = "CSV 测试题库"
		_message.dialog_autowrap = true
		_message.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_message)
		_message.get_ok_button().text = "关闭"
	_message.dialog_text = message
	_message.popup_centered_ratio(0.75)


static func _read_job(path: String, job: Dictionary) -> void :
	job["result"] = read_csv(path)



static func read_csv(path: String) -> Dictionary:
	var stream: FileAccess = FileAccess.open(path, FileAccess.READ)
	if stream == null:
		return _failure("无法读取 CSV：%s" % path)
	var headers: PackedStringArray = stream.get_csv_line()
	var columns: Dictionary = {}
	for i: int in headers.size():
		var header: String = headers[i].trim_prefix("").strip_edges()
		if columns.has(header):
			return _failure("CSV 表头重复：%s" % header)
		columns[header] = i
	for header: String in REQUIRED_HEADERS:
		if not columns.has(header):
			return _failure("CSV 缺少表头：%s" % header)
	var candidates: Dictionary = {}
	var group_counts: Dictionary = {}
	var record: int = 1
	var row_count: int = 0
	while stream.get_position() < stream.get_length():
		var cells: PackedStringArray = stream.get_csv_line()
		record += 1
		if cells.size() == 1 and cells[0].strip_edges().is_empty():
			continue
		if cells.size() != headers.size():
			return _failure("CSV 第 %d 条记录有 %d 列，表头为 %d 列（请检查引号与逗号）"
				%[record, cells.size(), headers.size()])
		var visible: String = _cell(cells, columns, "显示", "1")
		if visible == "0":
			continue
		if visible not in ["", "1"]:
			return _failure("CSV 第 %d 条记录的显示字段须为0或1" % record)
		var chapter_text: String = _cell(cells, columns, "章节")
		var level_text: String = _cell(cells, columns, "关卡")
		if not chapter_text.is_valid_int() or int(chapter_text) <= 0\
		or not level_text.is_valid_int() or int(level_text) < 1 or int(level_text) > LevelIndex.CHAPTER_SIZE:
			return _failure("CSV 第 %d 条记录的章节须为正整数、关卡须为1～25" % record)
		var tags: String = _cell(cells, columns, "levelUserTags")
		if tags.is_empty():
			tags = "default"
		if not _valid_tags(tags):
			return _failure("CSV 第 %d 条记录的能力标签不合法：%s" % [record, tags])
		var difficulty_type: String = _cell(cells, columns, "难度等级", "Normal")
		if difficulty_type not in ["Normal", "Hard", "SuperHard"]:
			return _failure("CSV 第 %d 条记录的难度等级须为Normal、Hard或SuperHard" % record)
		var difficulty: String = _cell(cells, columns, "难度n", "1")
		if not difficulty.is_valid_int() or int(difficulty) < 1 or int(difficulty) > 5:
			return _failure("CSV 第 %d 条记录的难度n须为1～5" % record)
		var layout: String = _cell(cells, columns, "关卡信息")
		if layout.is_empty():
			return _failure("CSV 第 %d 条记录缺少关卡信息" % record)
		var chapter_index: int = int(chapter_text)
		var level_index: int = int(level_text)
		var level_id: int = LevelIndex.level_id_of(chapter_index, level_index)
		var bucket: Array[Dictionary] = candidates.get(level_id, [] as Array[Dictionary])
		for entry: Dictionary in bucket:
			if String(entry["levelUserTags"]) == tags or _tags_overlap(String(entry["levelUserTags"]), tags):
				return _failure("CSV 第 %d 条记录的第%d关能力分组重复或重叠：%s" % [record, level_id, tags])
		var unique_id: String = _cell(cells, columns, "图片ID")
		bucket.append({"chapterIndex": chapter_index, "levelIndex": level_index, 
			"levelUserTags": tags, "difficultyType": difficulty_type, "difficulty": int(difficulty), 
			"levelUniqueId": unique_id if not unique_id.is_empty() else layout.md5_text(), 
			"levelDataSource": LevelModel.DEBUG_CSV_SOURCE_PREFIX + path.get_file(), "initialLayout": layout})
		candidates[level_id] = bucket
		group_counts[tags] = int(group_counts.get(tags, 0)) + 1
		row_count += 1
	if candidates.is_empty():
		return _failure("CSV 没有可测试的关卡（显示=0的记录不导入）")
	var levels: Array = candidates.keys()
	levels.sort()
	for level_id: int in levels:
		var bucket: Array[Dictionary] = candidates[level_id]
		if LevelProvider.pick(bucket, {}).is_empty():
			return _failure("CSV 第%d关缺少 default 候选，无法为未起步或未覆盖能力的用户选题" % level_id)
	return {"ok": true, "candidates": candidates, "levels": levels, "group_counts": group_counts, 
		"row_count": row_count, "title": path.get_file()}


static func _cell(cells: PackedStringArray, columns: Dictionary, name: String, fallback: String = "") -> String:
	return cells[int(columns[name])].strip_edges() if columns.has(name) else fallback


static func _valid_tags(tags: String) -> bool:
	if tags == "default":
		return true
	var parts: PackedStringArray = tags.split(":", true, 1)
	if parts.size() != 2 or parts[0] != UserLevelTag.TAG_KEY:
		return false
	var values: PackedStringArray = parts[1].split(",", true)
	var seen: Dictionary = {}
	for value: String in values:
		if value not in ["lv1", "lv2", "lv3", "lv4", "lv5"] or seen.has(value):
			return false
		seen[value] = true
	return not values.is_empty()


static func _tags_overlap(a: String, b: String) -> bool:
	if a == "default" or b == "default":
		return false
	var allowed: PackedStringArray = a.get_slice(":", 1).split(",")
	for value: String in b.get_slice(":", 1).split(","):
		if allowed.has(value):
			return true
	return false


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
