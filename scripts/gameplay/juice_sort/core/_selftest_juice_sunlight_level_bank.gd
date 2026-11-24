extends SceneTree

const INDEX_PATH: = "res://assets/game/juice_sunlight_levels_index.json"
const CSV_PATH: = "res://docs/gameplay/examples/juice_sunlight_levels.csv"
const EXPECTED_COUNTS: = [100, 79, 72, 100, 75]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	var manager: Node = root.get_node_or_null("LevelManager")
	_check(manager != null, "LevelManager 已安装")
	if manager == null:
		_finish()
		return
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	_check(int(index.get("count", 0)) == 426, "内置426题")
	var seen: Dictionary = {}
	for difficulty in range(1, 6):
		var ids: Array = index["tiers"][str(difficulty)]
		_check(ids.size() == EXPECTED_COUNTS[difficulty - 1], "难度%d题数准确" % difficulty)
		for position in ids.size():
			var source_id: int = int(ids[position])
			var record: Dictionary = manager.call("read_sunlight_level_by_difficulty", difficulty, position + 1)
			_check( not record.is_empty(), "难度%d第%d题能按需读取" % [difficulty, position + 1])
			if record.is_empty():
				continue
			_check( not seen.has(source_id), "原题号唯一")
			seen[source_id] = true
			_check(int(record["source_level_id"]) == source_id and int(record["difficulty"]) == difficulty
				and int(record["tier_sequence"]) == position + 1, "档内按CSV原顺序读取")
			_check(manager.call("read_sunlight_level", source_id) == record, "按题号与按档序读取同一题")
			var raw: Dictionary = record["raw"]
			var level: JuiceLevel = JuiceLevel.from_dict(raw)
			_check(level.validate().is_empty(), "题%d通过游戏校验: %s" % [source_id, str(level.validate())])
			_check(level.id == source_id and level.ice_mode == JuiceLevel.ICE_BLOCK_COLLECTION
				and level.has_sunlight(), "题号/允许连接规则/阳光未丢失")
			var roundtrip: JuiceLevel = JuiceLevel.from_dict(level.to_dict())
			_check(roundtrip.validate().is_empty() and roundtrip.to_dict() == level.to_dict(), "题面往返保持语义")
			var state: Dictionary = JuiceRules.make_state(level)
			var restored: Dictionary = JuiceRules.state_from_dict(
				JSON.parse_string(JSON.stringify(JuiceRules.state_to_dict(state))), level)
			_check( not restored.is_empty() and JuiceRules.state_key(restored) == JuiceRules.state_key(state), 
				"新题盘面快照往返保留冻结编码和模式")
			if position % 8 == 7:
				await process_frame
		_check((manager.call("read_sunlight_level_by_difficulty", difficulty, ids.size() + 1) as Dictionary).is_empty(), 
			"用完该档不擅自循环")
	_check(seen.size() == 426, "426题均读取和校验")
	for arguments: Array in [[0, 1], [6, 1], [1, 0], [1, -1]]:
		_check((manager.call("read_sunlight_level_by_difficulty", arguments[0], arguments[1]) as Dictionary).is_empty(), 
			"非法档位或序号不回落普通题")
	_check((manager.call("read_sunlight_level", 30180) as Dictionary).is_empty(), "原题号缺口不选邻题")
	_check((manager.call("read_sunlight_level", 0) as Dictionary).is_empty(), "非法原题号不读取")
	_test_repeat_and_mutation(manager)
	await _test_csv(manager)
	_test_debug_loader(manager)
	_test_export_filters()
	await process_frame
	_finish()


func _test_repeat_and_mutation(manager: Node) -> void :
	var first: Dictionary = manager.call("read_sunlight_level_by_difficulty", 1, 1)
	var second: Dictionary = manager.call("read_sunlight_level_by_difficulty", 1, 2)
	_check(int(first["source_level_id"]) == 30001 and int(second["source_level_id"]) == 30002, 
		"第1档按原表顺序取题")
	_check(manager.call("read_sunlight_level_by_difficulty", 1, 1) == first, "读取不自动推进序号")
	first["raw"]["capacity"] = 1
	_check(int((manager.call("read_sunlight_level", 30001) as Dictionary)["raw"]["capacity"]) == 6, 
		"修改返回题面不污染题库或索引")


func _test_csv(manager: Node) -> void :
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	_check(file != null, "转换后的CSV存在")
	if file == null:
		return
	file.get_csv_line()
	var rows: int = 0
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.size() <= 5:
			continue
		rows += 1
		var source_id: int = int(values[0])
		var record: Dictionary = manager.call("read_sunlight_level", source_id)
		_check(JSON.parse_string(values[5]) == record.get("raw"), "CSV关卡信息与内置题面一致")
		if rows % 8 == 0:
			await process_frame
	_check(rows == 426, "CSV保留426行")


func _test_debug_loader(manager: Node) -> void :
	var debug_script: Script = load("res://scripts/debug/juice_debug_level.gd")
	var source: Dictionary = manager.call("read_sunlight_level", 30001)
	var loaded: Dictionary = debug_script.load_sunlight_level(1, 1)
	_check(bool(loaded.get("ok", false)) and int(loaded["source_level_id"]) == 30001, 
		"调试按档序实际装载阳光题")
	var play_level: int = int(loaded["level"])
	var parser: JuiceLevelParser = JuiceLevelParser.new()
	var model: LevelModel = LevelModel.new()
	model.level_id = play_level
	model.use_fallback_pool = true
	var parsed: JuiceLevelModel = parser.parse_level(model) as JuiceLevelModel
	_check(parsed != null and not parsed.used_fallback and parsed.juice.has_sunlight()
		and parsed.juice.ice_mode == JuiceLevel.ICE_BLOCK_COLLECTION
		and parsed.juice.id == play_level, "调试入口复用真实parser，不跳原题号、不落普通兜底")
	_check((manager.call("read_sunlight_level", 30001) as Dictionary) == source, "调试改当前关号不污染原题面")
	_check( not bool(debug_script.load_sunlight_level(1, 101)["ok"]), "调试档内越界报错")
	_check( not bool(debug_script.load_sunlight_case(30180)["ok"]), "调试原题号缺口报错")
	var by_id: Dictionary = debug_script.load_sunlight_case(30475)
	_check(bool(by_id.get("ok", false)) and int(by_id["difficulty"]) == 5, "调试指定原题号可读取第5档")
	JuiceLevelParser.clear_debug_row()


func _test_export_filters() -> void :
	var presets: ConfigFile = ConfigFile.new()
	_check(presets.load("res://export_presets.cfg") == OK, "可检查导出白名单")
	for section: String in ["preset.0", "preset.1"]:
		var includes: PackedStringArray = String(presets.get_value(section, "include_filter", "")).split(",")
		_check(includes.has("assets/game/juice_sunlight_levels.json")
			and includes.has("assets/game/juice_sunlight_levels_index.json"), "两平台导出包含题库和索引")


func _check(condition: bool, label: String) -> void :
	_checks += 1
	if not condition:
		_failures.append(label)
		printerr("FAIL: " + label)


func _finish() -> void :
	print("Sunlight bank: %d assertions, 426 levels, tiers=%s" % [_checks, str(EXPECTED_COUNTS)])
	print("SUNLIGHT_LEVEL_BANK_SELFTEST PASS" if _failures.is_empty() else "SUNLIGHT_LEVEL_BANK_SELFTEST FAIL")
	quit(0 if _failures.is_empty() else 1)
