extends SceneTree



const Tracker = preload("res://scripts/gameplay/juice_sort/core/juice_combo_tracker.gd")

var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	_test_window_boundary()
	_test_time_window()
	_test_reference_refresh()
	_test_break_and_restart()
	_test_multiple_cups_and_reset()
	_test_invalid_moves()
	_test_undo_keeps_window()
	_test_difficulty_metadata()
	if _failures.is_empty():
		print("juice combo selftest passed")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_window_boundary() -> void :
	var tracker: = Tracker.new()
	for difficulty: int in range(1, 6):
		var window: int = 5 + 5 + difficulty
		tracker.reset(5, difficulty, 0, 0)
		_expect(tracker.on_move(1, 1, 1000).is_empty(), "首盆只起连击")
		for step: int in range(2, window + 1):
			_expect(tracker.on_move(step, 1, 17000).is_empty(), "时间超窗但步数未超窗的空步不触发")
		_expect(tracker.on_move(window + 1, 2, 18000) == [2], "难度%d：超过15秒但恰好步数边界续接" % difficulty)
		tracker.reset(5, difficulty, 0, 0)
		tracker.on_move(1, 1, 1000)
		_expect(tracker.on_move(window + 2, 2, 18000).is_empty(), "难度%d：两个窗口都超过则中断" % difficulty)


func _test_time_window() -> void :
	var tracker: = Tracker.new()
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	for step: int in range(2, 13):
		tracker.on_move(step, 1, 2000)
	_expect(tracker.on_move(13, 2, 16000) == [2], "步数已超过但恰好15秒仍续接，空步不提前中断")
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	_expect(tracker.on_move(13, 2, 16001).is_empty(), "超步数且超过15秒1毫秒中断")


func _test_reference_refresh() -> void :
	var tracker: = Tracker.new()
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	_expect(tracker.on_move(13, 2, 11000) == [2], "时间路径续接第二盆")
	_expect(tracker.on_move(25, 3, 21000) == [3], "时间基准随第二盆刷新，不用首盆计时")
	_expect(tracker.on_move(34, 4, 40000) == [4], "步数基准随第三盆刷新，可从时间路径切到步数路径")


func _test_break_and_restart() -> void :
	var tracker: = Tracker.new()
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	_expect(tracker.on_move(3, 2, 2000) == [2], "连续第二盆为 combo 2")
	_expect(tracker.on_move(5, 3, 3000) == [3], "连续第三盆为 combo 3")
	for step: int in range(6, 16):
		tracker.on_move(step, 3, 19000)
	_expect(tracker.on_move(16, 4, 20000).is_empty(), "两窗超限后收盆重新起连击")
	_expect(tracker.on_move(17, 5, 21000) == [2], "打断后重新连击")


func _test_multiple_cups_and_reset() -> void :
	var tracker: = Tracker.new()
	tracker.reset(4, 2, 0, 0)
	_expect(tracker.on_move(1, 3, 1000) == [2, 3], "同一步完成多盆逐盆累计")
	_expect(tracker.on_move(20, 5, 30000) == [2], "两窗超限后的级联第一盆重起，第二盆续接")
	tracker.reset(4, 2, 10, 2)
	_expect(tracker.on_move(11, 3, 31000).is_empty(), "重置后不保留旧步数与时间连击")
	_expect(tracker.on_move(12, 4, 32000) == [2], "重置后按新走法重新计数")


func _test_invalid_moves() -> void :
	var tracker: = Tracker.new()
	tracker.reset(4, 2, 0, 0)
	tracker.on_move(1, 1, 1000)
	_expect(tracker.on_move(1, 2, 2000).is_empty(), "重复步数忽略")
	_expect(tracker.on_move(0, 2, 2000).is_empty(), "回退步数忽略")
	_expect(tracker.on_move(2, 0, 2000).is_empty(), "回退完成盆数忽略")
	_expect(tracker.on_move(2, 2, 2000) == [2], "非法输入不污染计数基准")


func _test_undo_keeps_window() -> void :
	var tracker: = Tracker.new()
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	tracker.on_move(2, 2, 2000)
	tracker.sync_done(1)
	_expect(tracker.on_move(11, 2, 18000) == [3], "撤销后同步盆数并保留9步边界及连续档位")
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	tracker.sync_done(0)

	_expect(tracker.on_move(11, 1, 17000).is_empty(), "撤销不清零累计放置，两个窗口超限仍中断")
	tracker.reset(3, 1, 0, 0)
	tracker.on_move(1, 1, 1000)
	tracker.sync_done(0)
	_expect(tracker.on_move(20, 1, 16000) == [2], "撤销保留15秒时间边界")


func _test_difficulty_metadata() -> void :

	var parser_script: GDScript = load("res://scripts/data/level_data/level_parser.gd") as GDScript
	var model_script: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_level_model.gd") as GDScript
	var juice_parser_script: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_level_parser.gd") as GDScript
	var juice_parser: LevelParser = juice_parser_script.new()
	for difficulty: int in range(1, 6):
		var meta: LevelModel = parser_script.build_level_meta(1, 1, {
			"difficulty": str(difficulty), "difficultyType": "Normal", "initialLayout": "not-decrypted", 
		})
		_expect(meta.difficulty == difficulty and not meta._content_parsed, "解析难度%d不解密题面" % difficulty)

		meta._content = {"capacity": 2, "targetCups": 2, 
			"initial": ["-|", "0|1,0", "1|0,1"], "incoming": ["x"]}
		meta._content_parsed = true
		var model: LevelModel = juice_parser.parse_level(meta)
		_expect(model != null, "正式玩法解析成功")
		if model == null:
			continue
		_expect(model.difficulty == difficulty, "玩法模型保留难度%d" % difficulty)
		_expect(model.duplicate_model().difficulty == difficulty, "模型复制保留难度%d" % difficulty)
		var saved: Dictionary = JSON.parse_string(JSON.stringify(model.to_dict())) as Dictionary
		_expect( not saved.has("raw_entry"), "存档不携带密文 entry")
		meta.raw_entry["difficulty"] = "1" if difficulty > 1 else "5"
		var restored: LevelModel = juice_parser.model_from_dict(saved)
		_expect(restored != null and restored.difficulty == difficulty, 
			"续局保留冻结难度%d，不跟随源配置变化" % difficulty)
	var old_model: LevelModel = model_script.new()
	old_model.from_dict({})
	_expect(old_model.difficulty == 1, "旧存档缺难度时默认1")
	_expect(parser_script.build_level_meta(1, 1, {}).difficulty == 1, "配置缺难度时默认1")
	_expect(parser_script.build_level_meta(1, 1, {"difficulty": 0}).difficulty == 1, "难度下限1")
	_expect(parser_script.build_level_meta(1, 1, {"difficulty": 6}).difficulty == 5, "难度上限5")


func _expect(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
