extends SceneTree









const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

const BANK_PATH: = "res://assets/game/special_challenge_levels_v2.json"
const INDEX_PATH: = "res://assets/game/special_challenge_levels_v2_index.json"

var _failures: Array[String] = []


func _initialize() -> void :
	_test_bank()
	_test_runtime_bank()
	_test_variable_cap_rules()
	_test_out_of_order_hint()
	_test_same_type_caps()
	_test_remaining_incoming_pots()
	_finish()


func _test_runtime_bank() -> void :
	var bank: = SpecialChallengeBank.new()
	var old_case: Dictionary = bank.read_case(1, 0)
	_check( not old_case.is_empty(), "v1 旧题库仍可读取")
	var first: Dictionary = bank.read_case(1, 1)
	var second: Dictionary = bank.read_case(2, 1)
	var last: Dictionary = bank.read_case(158, 1)
	_check(bank.size(1) == SpecialChallengeRules.BANK_SIZE_V2, "v2 索引题数与循环上限一致")
	_check( not first.is_empty() and int((first["raw"] as Dictionary)["capacity"]) == 6, 
		"v2 第 1 题可按索引读取且 capacity=6")
	_check( not second.is_empty() and int((second["raw"] as Dictionary)["capacity"]) == 6, 
		"v2 第 2 题可按索引读取且 capacity=6")
	_check( not last.is_empty() and String(last.get("level_unique_id", "")) != "", 
		"v2 第 158 题可读取且有 level_unique_id")
	var first_model: JuiceLevelModel = JuiceLevelParser.new().model_from_dict(first) as JuiceLevelModel
	_check(first_model != null and first_model.level_user_tags == String(first.get("level_user_tags", ""))
		and first_model.level_user_tags.begins_with("special，双白盆短缓冲"), "v2 tag 保留到题目模型")
	_check(SpecialChallengeRules.case_number(0, SpecialChallengeRules.BANK_SIZE_V2) == 1
		and SpecialChallengeRules.case_number(157, SpecialChallengeRules.BANK_SIZE_V2) == 158
		and SpecialChallengeRules.case_number(158, SpecialChallengeRules.BANK_SIZE_V2) == 1, 
		"v2 题号按 158 循环")
	_check(SpecialChallengeRules.case_number(199) == 200
		and SpecialChallengeRules.case_number(200) == 1, 
		"v1 默认题号仍按 200 循环")
	var slot0: Dictionary = SpecialChallengeRules.level2_case_for_slot(0, 0, 0)
	var slot1: Dictionary = SpecialChallengeRules.level2_case_for_slot(1, 0, 0)
	var slot0b: Dictionary = SpecialChallengeRules.level2_case_for_slot(0, 1, 1)
	var slot1b: Dictionary = SpecialChallengeRules.level2_case_for_slot(1, 1, 1)
	_check(slot0 == {"bank": 0, "case_number": 1} and slot1 == {"bank": 1, "case_number": 1}
		and slot0b == {"bank": 0, "case_number": 2}
		and slot1b == {"bank": 1, "case_number": 2}, 
		"槽位 0/1 分别推进旧/新题库")
	var control_turns: int = 0
	var new_turns: int = 0
	var old_cases: Array[int] = []
	var new_cases: Array[int] = []
	for slot: int in [0, 1, 0, 1, 0, 1]:
		var picked: Dictionary = SpecialChallengeRules.level2_case_for_slot(
			slot, control_turns, new_turns)
		if int(picked["bank"]) == 1:
			new_cases.append(int(picked["case_number"]))
			new_turns += 1
		else:
			old_cases.append(int(picked["case_number"]))
			control_turns += 1
	_check(old_cases == [1, 2, 3] and new_cases == [1, 2, 3], 
		"六个槽位按旧1/新1/旧2/新2/旧3/新3 出题")


func _test_bank() -> void :
	var data: PackedByteArray = FileAccess.get_file_as_bytes(BANK_PATH)
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	if not (index is Dictionary):
		_failures.append("v2 index 不是对象")
		return
	if index.get("format") != "special-challenge-bank/2" or int(index.get("size", 0)) != 158:
		_failures.append("v2 index 头不符: %s" % str(index))
	var offsets: Array = index.get("offsets", [])
	var lengths: Array = index.get("lengths", [])
	if offsets.size() != 158 or lengths.size() != 158:
		_failures.append("v2 index offsets/lengths 数量不符")
		return
	var capacities: Array[int] = []
	var flower_counts: Array[int] = []
	for i in 158:
		var start: int = int(offsets[i])
		var length: int = int(lengths[i])
		if data[start] != 123:
			_failures.append("第 %d 题 offset 不指向对象" % (i + 1))
			continue
		var envelope: Variant = JSON.parse_string(data.slice(start, start + length).get_string_from_utf8())
		if not (envelope is Dictionary):
			_failures.append("第 %d 题 JSON 解析失败" % (i + 1))
			continue
		var raw: Dictionary = (envelope as Dictionary).get("raw", {}) as Dictionary
		var lv: JuiceLevel = JuiceLevel.from_dict(raw)
		var errs: Array[String] = lv.validate()
		if not errs.is_empty():
			_failures.append("第 %d 题校验失败: %s" % [i + 1, errs[0]])
			continue
		capacities.append(lv.capacity)
		flower_counts.append(lv.total_flowers)
		if i == 0:
			_check(lv.capacity == 6 and lv.total_flowers == 30 and lv.groups_total == 5, 
				"首题 capacity=6 total=30 target=5")
			_check(lv.column_caps == [4, 6, 6, 6, 6, 6, 4]
					and lv.board_jars[0] == JuiceLevel.NO_JAR and lv.board_jars[6] == JuiceLevel.NO_JAR, 
				"首题保留两端白盆与 4/6 逐列容量")
		elif i == 1:
			_check(lv.capacity == 6 and lv.total_flowers == 30, "第 2 题 capacity=6 total=30")
			_check(lv.column_caps == [4, 6, 6, 6, 6, 6, 4], 
				"第 2 题逐列容量 [4,6,6,6,6,6,4]")
	_check(capacities.size() == 158, "158 题全部通过 validate")
	_check(capacities.count(8) == 106 and capacities.count(6) == 52, "最大容量 8/6 各 106/52 题")
	_check(flower_counts.count(30) == 18 and flower_counts.count(40) == 78
		and flower_counts.count(65) == 34 and flower_counts.count(44) == 20
		and flower_counts.count(72) == 8, "总花朵数分布")


func _test_variable_cap_rules() -> void :

	var raw: Dictionary = {
		"schema": "juice-level/4", 
		"capacity": 3, 
		"targetCups": 4, 
		"initial": [
			{"column": "0|0,3", "columnType": "default", "columnInfo": {}}, 
			{"column": "1|1,3", "columnType": "default", "columnInfo": {}}, 
			{"column": "2|2,3", "columnType": "default", "columnInfo": {}}, 
		], 
		"incoming": ["3|0,1,2", "x", "x"], 
		"columnCaps": {"initial": [2, 2, 2], "incoming": [3, 0, 0]}, 
	}
	var lv: JuiceLevel = JuiceLevel.from_dict(raw)
	_check(lv.validate().is_empty(), "构造题面应合法: %s" % str(lv.validate()))
	_check(lv.capacity == 3, "单值容量取最大列容量 3")
	_check(lv.column_caps == [2, 2, 2], "初始逐列容量 [2,2,2]")
	_check(lv.incoming_caps == [3, 0, 0], "补货逐列容量 [3,0,0]")
	_check(lv.cup_caps == [2, 2, 2, 3], "每杯容量 [2,2,2,3]")
	_check(lv.total_flowers == 9, "总花朵数 9")

	var st: Dictionary = R.make_state(lv)
	_check(st["caps"] == [2, 2, 2], "make_state 使用逐列容量")
	_check(bool(st.get("varcap", false)), "逐列容量状态带 varcap 标记")


	(st["cols"] as Array)[0] = [0, 0] as Array[int]
	var log: Array = []
	R.run_deposit(st, lv, log)
	_check(int(st["done"]) == 1, "应只收集第一杯")
	_check(st["caps"] == [3, 2, 2], "补货后第一列容量更新为 3")
	_check(int((st["jars"] as Array[int])[0]) == 3, "补货后第一列机器为 3")
	_check((st["cols"] as Array)[0] == [0, 1, 2], "补货花落到第一列")

	var saved: Dictionary = JSON.parse_string(JSON.stringify(R.state_to_dict(st)))
	var restored: Dictionary = R.state_from_dict(saved, lv)
	_check( not restored.is_empty(), "逐列容量存档可还原")
	_check(restored["caps"] == [3, 2, 2], "还原后逐列容量保持")

	var other: Dictionary = R.clone_state(st)
	(other["caps"] as Array[int])[1] = 3
	_check(R.state_key(st) != R.state_key(other), "状态指纹包含逐列容量")

	var rope_state: Dictionary = R.clone_state(st)
	var ci: int = R.add_rope(rope_state, lv.capacity)
	_check(ci >= 0 and (rope_state["caps"] as Array[int])[ci] == 3, "加绳使用最大容量 3")

	_check(R.max_groups_left(st, lv) >= 0, "max_groups_left 不崩溃")


func _test_out_of_order_hint() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({
		"schema": "juice-level/4", "capacity": 3, "targetCups": 2, 
		"initial": ["0|0", "1|1,1", "-|0,1"], "incoming": ["x"], 
		"columnCaps": {"initial": [2, 3, 3], "incoming": [0]}, 
	})
	_check(lv.validate().is_empty(), "乱序收盆题面合法")
	var st: Dictionary = R.make_state(lv)
	_check( not R.apply_move(st, lv, 2, 1, 1).is_empty()
		and st["cups"] == [1], "先收题面第二列的 3 容量盆")
	_check(R.max_groups_left(st, lv) == 1 and not R.is_doomed(st, lv), 
		"第一列的 2 容量盆仍可完成，花账不能按题面顺序扣盆")
	_check(S.full_reachability(st, lv) == S.Reachability.WINNABLE, 
		"乱序收盆后的完整搜索确认可通关")
	var before: String = S._full_state_key(st)
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {}, result)
	_check(bool(result.get("completed", false))
		and int(result.get("reachability", S.Reachability.UNKNOWN)) == S.Reachability.WINNABLE, 
		"Hint 不得将乱序收盆后的活局判死")
	var hint: Dictionary = result.get("hint", {})
	_check( not hint.is_empty() and int(hint.get("len", 0)) == 1, 
		"Hint 应给出一步完成最后一盆的路线")
	_check(S._full_state_key(st) == before, "Hint 不修改原盘面")
	var replay: Dictionary = R.clone_state(st)
	for mv: Dictionary in hint.get("path", []):
		_check( not R.apply_move(replay, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
			"Hint 每一步按真实规则可执行")
	_check(R.is_win(replay, lv), "Hint 路线真实重放通关")
	var missing: Dictionary = R.clone_state(st)
	(missing["cols"][2] as Array[int]).clear()
	_check(R.is_doomed(missing, lv)
		and S.full_reachability(missing, lv) == S.Reachability.UNWINNABLE, 
		"真实缺花的逐列容量盘面仍判无解")


func _test_same_type_caps() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({
		"schema": "juice-level/4", "capacity": 3, "targetCups": 2, 
		"initial": ["0|0", "0|0,0", "-|0,0"], "incoming": ["x"], 
		"columnCaps": {"initial": [2, 3, 3], "incoming": [0]}, 
	})
	_check(lv.validate().is_empty(), "同色不同容量题面合法")
	var st: Dictionary = R.make_state(lv)
	_check( not R.apply_move(st, lv, 2, 1, 1).is_empty(), "先收同色的 3 容量盆")
	_check(R.max_groups_left(st, lv) == 1 and not R.is_doomed(st, lv), 
		"同色剩余目标按在场 2 容量盆统计，不沿用已收盆的容量")
	_check( not R.apply_move(st, lv, 2, 0, 0).is_empty() and R.is_win(st, lv), 
		"同色不同容量可按逆序收盆通关")


func _test_remaining_incoming_pots() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({
		"schema": "juice-level/4", "capacity": 3, "targetCups": 3, 
		"initial": ["0|0", "1|1,1", "-|0,1"], "incoming": ["-|2,2", "2|"], 
		"columnCaps": {"initial": [2, 3, 3], "incoming": [3, 2]}, 
	})
	_check(lv.validate().is_empty(), "延后补盆题面合法")
	var st: Dictionary = R.make_state(lv)
	_check(R.max_groups_left(st, lv) == 3, "开局统计在场盆和未来补货盆，白盆不算目标")
	_check( not R.apply_move(st, lv, 2, 1, 1).is_empty() and int(st["done"]) == 1, 
		"先收第二列后补白盆和 2 号花")
	_check(R.max_groups_left(st, lv) == 2 and not R.is_doomed(st, lv), 
		"收盆后仍计入尚未入场的 2 号盆")
	_check( not R.apply_move(st, lv, 2, 0, 0).is_empty() and int(st["done"]) == 2, 
		"再收第一列后补 2 号盆")
	_check(R.max_groups_left(st, lv) == 1 and not R.is_doomed(st, lv), 
		"已经入场的补货盆只统计一次，退休列不算目标")
	_check( not R.apply_move(st, lv, 1, 0, 0).is_empty() and R.is_win(st, lv), 
		"延后补盆路线按真实规则通关")


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)


func _finish() -> void :
	if _failures.is_empty():
		print("[selftest_juice_variable_caps] ALL PASS")
		quit(0)
		return
	for failure: String in _failures:
		printerr("[selftest_juice_variable_caps] FAIL: " + failure)
	quit(1)
