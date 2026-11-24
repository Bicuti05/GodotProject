extends SceneTree

const LevelC = preload("res://scripts/gameplay/juice_sort/core/juice_level.gd")
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const HP = preload("res://scripts/gameplay/juice_sort/core/juice_hint_planner.gd")
const Challenge = preload("res://scripts/gameplay/juice_sort/core/juice_challenge.gd")

const EXAMPLES_PATH: = "res://docs/gameplay/examples/juice-sunlight-ice-levels.json"

var _failures: Array[String] = []
var _checks: int = 0


func _initialize() -> void :
	_test_encoding()
	_test_ice_modes()
	_test_ice_only_blocks_collection()
	var doc: Dictionary = _load_examples()
	if not doc.is_empty():
		_test_verification_cases(doc.get("verificationCases", []) as Array)
		_test_rejected_cases(doc.get("rejectedCases", []) as Array)
		var candidate_levels: Array = doc.get("levels", []) as Array
		_test_candidate_levels(candidate_levels)
		if OS.get_cmdline_user_args().has("--candidate-levels") and not candidate_levels.is_empty():
			_test_melted_roundtrip(candidate_levels[0])
	_test_regressions()
	_finish()


func _load_examples() -> Dictionary:
	if not FileAccess.file_exists(EXAMPLES_PATH):
		_fail("缺少验收数据 %s" % EXAMPLES_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXAMPLES_PATH))
	if not (parsed is Dictionary):
		_fail("验收数据不是 JSON 对象")
		return {}
	return parsed


func _test_encoding() -> void :
	_check(LevelC.is_hidden(1000) and not LevelC.is_hidden(2000), "隐藏编码只覆盖 1000..1999")
	_check(LevelC.is_frozen(2000) and not LevelC.is_frozen(3000), "冻结编码只覆盖 2000..2999")
	_check(LevelC.true_type(2006) == 6, "冻结真实类型减去 FROZEN_BASE")
	_check(LevelC.freeze_type(6) == 2006, "freeze_type 生成 iN 编码")
	_check(LevelC.encode_col(0, [2000, 1001, 2] as Array[int]) == "0|i0,?1,2", "列串导出 iN/?N")
	var bad_mixed: LevelC = LevelC.from_dict({
		"id": 9001, "capacity": 3, "targetCups": 2, "sunlight": {"typeId": 2}, 
		"initial": ["-|?i2", "2|2,2", "0|0,0"], "incoming": [], 
	})
	_check( not bad_mixed.validate().is_empty(), "?iN 组合编码应被拒绝")


func _test_ice_modes() -> void :
	var base: Dictionary = {
		"id": 1004, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|2", "-|0", "-|1", "0|i0,0", "2|2,2", "1|1,1"], "incoming": [], 
	}
	var legacy: LevelC = LevelC.from_dict(base)
	_check(legacy.ice_mode == LevelC.ICE_BLOCK_COLLECTION and not legacy.to_dict().has("iceMode"), 
		"缺省题面保持当前规则和原导出形态")
	for invalid: Variant in [null, true, 1, "", "unknown", {}, []]:
		var bad_row: Dictionary = base.duplicate(true)
		bad_row["iceMode"] = invalid
		_check( not LevelC.from_dict(bad_row).validate().is_empty(), "非法 iceMode 被拒绝: %s" % str(invalid))
	for mode: String in [LevelC.ICE_BLOCK_CONNECTION, LevelC.ICE_BLOCK_COLLECTION]:
		var row: Dictionary = base.duplicate(true)
		row["iceMode"] = mode
		var level: LevelC = LevelC.from_dict(row)
		_check(level.validate().is_empty() and level.ice_mode == mode, "%s 题面合法" % mode)
		_check(LevelC.from_dict(level.to_dict()).ice_mode == mode, "%s 导出往返保留模式" % mode)
		var varying: Dictionary = row.duplicate(true)
		varying["schema"] = "juice-level/4"
		varying["columnCaps"] = {"initial": [3, 3, 3, 3, 3, 3], "incoming": []}
		var variable_level: LevelC = LevelC.from_dict(varying)
		_check(variable_level.validate().is_empty() and LevelC.from_dict(variable_level.to_dict()).ice_mode == mode, 
			"%s 逐列容量题面往返保留模式" % mode)
		var model_script: Script = load("res://scripts/gameplay/juice_sort/core/juice_level_model.gd")
		var model: Variant = model_script.new()
		model.from_dict({"raw": row})
		var rebuilt: Variant = model_script.new()
		rebuilt.from_dict(model.to_dict())
		_check(rebuilt.raw["iceMode"] == mode and rebuilt.juice.ice_mode == mode, 
			"模型原题面往返保留模式，无需新增路由")
		var state: Dictionary = R.make_state(level)
		var initial_key: String = R.state_key(state)
		var shuffle: Dictionary = R.clone_state(state)
		(shuffle["cols"][2] as Array[int]).clear()
		var before_cut: bool = Challenge._is_shuffle_cut(shuffle["cols"][3], 1, shuffle)
		var cut_rec: Dictionary = R.apply_move(shuffle, level, 3, 1, 2, true)
		_check(before_cut == (mode == LevelC.ICE_BLOCK_COLLECTION)
			and Challenge.is_progress_move(shuffle, cut_rec) == not before_cut, 
			"%s 同色冰边界的推进/倒腾分析前后一致" % mode)
		_check(R.clone_state(state)["ice_mode"] == mode, "%s 克隆保留模式" % mode)
		var opposite: Dictionary = R.clone_state(state)
		opposite["ice_mode"] = LevelC.ICE_BLOCK_COLLECTION if mode == LevelC.ICE_BLOCK_CONNECTION\
		else LevelC.ICE_BLOCK_CONNECTION
		_check(R.state_key(opposite) != initial_key, "相同盘面不同模式指纹不同")
		var saved: Dictionary = R.state_to_dict(state)
		var restored: Dictionary = R.state_from_dict(JSON.parse_string(JSON.stringify(saved)), level)
		_check( not restored.is_empty() and R.state_key(restored) == initial_key, "%s JSON续局保留模式" % mode)
		var old_blob: Dictionary = saved.duplicate(true)
		old_blob.erase("iceMode")
		_check(R.state_from_dict(old_blob, level).is_empty() == (mode == LevelC.ICE_BLOCK_CONNECTION), 
			"旧存档只兼容当前默认规则")
		for invalid_saved: Variant in [opposite["ice_mode"], "unknown", null, 1]:
			var bad_saved: Dictionary = saved.duplicate(true)
			bad_saved["iceMode"] = invalid_saved
			_check(R.state_from_dict(bad_saved, level).is_empty(), "%s 拒绝模式不符/损坏存档" % mode)
		var assembly: Dictionary = R.apply_move(state, level, 1, 0, 3)
		_check( not assembly.is_empty() and int(state["done"]) == 0, 
			"%s 普通端点可携内部冰，满冰列不收" % mode)
		var sunshine: Dictionary = R.apply_move(state, level, 0, 0, 4)
		_check(int(state["done"]) == 2 and _same_array(state["cups"], [2, 0]), 
			"%s 阳光同一步融冰级联" % mode)
		_check( not R.state_from_dict(R.state_to_dict(state), level).is_empty(), "%s 融冰后可续局" % mode)
		R.undo_move(state, sunshine, true)
		_check(int(state["cols"][3][0]) == LevelC.FROZEN_BASE and state["ice_mode"] == mode, 
			"%s 问号记忆撤销仍回冻并保留模式" % mode)
		R.undo_move(state, assembly)
		_check(R.state_key(state) == initial_key, "%s 撤销回开局" % mode)
		_test_mode_connections(row, mode)


func _test_mode_connections(row: Dictionary, mode: String) -> void :
	var strict: bool = mode == LevelC.ICE_BLOCK_CONNECTION
	for variant: String in ["frozen_source", "frozen_target", "both_frozen"]:
		var probe: Dictionary = row.duplicate(true)
		probe["initial"][1] = "-|0" if variant == "frozen_target" else "-|i0"
		probe["initial"][3] = "0|0,0" if variant == "frozen_source" else "0|0,i0"
		var level: LevelC = LevelC.from_dict(probe)
		_check(level.validate().is_empty(), "%s/%s 配平题合法" % [mode, variant])
		var state: Dictionary = R.make_state(level)
		var expected: int = 0 if strict else 1
		_check(R.move_info(state, 1, 0, 3) == expected and R.move_info(state, 3, 1, 1) == expected, 
			"%s/%s 冰端点双向连接" % [mode, variant])
		_check(R.reject_reason(state, 1, 0, 3) == (R.Reject.FROZEN if strict else R.Reject.NONE), 
			"%s/%s 拒绝原因" % [mode, variant])
		var empty_target: Dictionary = R.clone_state(state)
		(empty_target["cols"][2] as Array[int]).clear()
		_check(R.move_info(empty_target, 3, 1, 2) == 1, "%s 冰可移到空列" % mode)
		_check(_useful_move_exists(state, 1, 0, 3) == not strict, "%s 快速枚举遵循模式" % mode)
		var enumerated: Array = HP.all_moves(state)
		for move: Dictionary in R.useful_moves(state):
			_check(R.move_info(state, int(move["src"]), int(move["j"]), int(move["dst"])) > 0, 
				"%s 枚举只含真实合法走法" % mode)
		_check(R.has_any_move(state) == not enumerated.is_empty(), "%s 快速可移动判据与全枚举一致" % mode)
		var no_deposit: Dictionary = R.clone_state(state)
		R.apply_move(no_deposit, level, 0, 0, 4, true)
		_check(int(no_deposit["done"]) == 0 and no_deposit["ice_mode"] == mode, 
			"%s no_deposit 不融冰/不改模式" % mode)
		R.apply_move(state, level, 0, 0, 4)
		_check(R.move_info(state, 1, 0, 3) == 1, "%s 融冰后恢复普通连接" % mode)
		var route: Array = S.hint_win_path(R.make_state(level), level, {
			"max_routes": 500, "width": 8, "route_nodes": 1000, "route_depth": 15, 
		})
		_check( not route.is_empty(), "%s/%s 小题提示找到通关路线" % [mode, variant])
		var replay: Dictionary = R.make_state(level)
		for move: Dictionary in route:
			_check( not R.apply_move(replay, level, int(move["src"]), int(move["j"]), int(move["dst"])).is_empty(), 
				"%s 提示路线遵循模式" % mode)
		_check(R.is_win(replay, level), "%s 小题提示路线可通关" % mode)
	var constrained: Dictionary = R.make_state(LevelC.from_dict(row))
	constrained["cols"] = [[2000] as Array[int], [0] as Array[int], [2000] as Array[int], 
		[2] as Array[int], [1] as Array[int], [1] as Array[int]]
	constrained["caps"] = [2, 1, 1, 1, 1, 1] as Array[int]
	_check(R.has_any_move(constrained) == not strict and R.useful_moves(constrained).is_empty() == strict, 
		"仅剩接冰端点时快速判据准确")


func _test_verification_cases(cases: Array) -> void :
	_check(cases.size() == 3, "验收 case 数量")
	for case_data: Dictionary in cases:
		var case_name: String = String(case_data.get("name", ""))
		var row: Dictionary = case_data.get("level", {})
		var level: LevelC = LevelC.from_dict(row)
		var errors: Array[String] = level.validate()
		_check(errors.is_empty(), "%s 题面校验通过: %s" % [case_name, str(errors)])
		if not errors.is_empty():
			continue
		var state: Dictionary = R.make_state(level)
		_test_probes(case_name, state, case_data.get("probes", []) as Array)
		var last_rec: Dictionary = {}
		for step_data: Dictionary in case_data.get("steps", []) as Array:
			var src: int = int(step_data["src"])
			var segment_start: int = int(step_data["j"])
			var dst: int = int(step_data["dst"])
			var no_deposit: bool = bool(step_data.get("no_deposit", false))
			last_rec = R.apply_move(state, level, src, segment_start, dst, no_deposit)
			_check( not last_rec.is_empty(), "%s 步骤合法" % case_name)
		_test_expected_deposits(case_name, last_rec.get("deposits", []) as Array, 
			case_data.get("expectedDeposits", []) as Array)
		_test_probes(case_name, state, case_data.get("probesAfterSteps", []) as Array)
		_test_expected_after(case_name, state, case_data.get("expectedAfter", {}))
		if case_name == "sunlight-melts-all-and-cascades":
			_test_undo_and_roundtrip(row, level, last_rec)
		elif case_name == "singleton-ice-same-color-connection":
			_check(R.reject_reason(R.make_state(level), 0, 0, 4) == R.Reject.NONE, 
				"同色冰段顶可以连接普通花")
			_check(R.reject_reason(R.make_state(level), 4, 1, 0) == R.Reject.NONE, 
				"普通花可以连接同色冰尾")


func _test_ice_only_blocks_collection() -> void :
	var level: LevelC = LevelC.from_dict({
		"id": 1004, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|2", "-|0", "-|1", "0|i0,0", "2|2,2", "1|1,1"], "incoming": [], 
	})
	_check(level.validate().is_empty(), "冰只阻止消除测试题合法")
	var state: Dictionary = R.make_state(level)
	var before: String = R.state_key(state)
	_check(R.move_info(state, 1, 0, 3) == 1, "普通花可接同色含冰列")
	_check(_useful_move_exists(state, 1, 0, 3), "候选走法包含接入含冰列")
	var assembled: Dictionary = R.apply_move(state, level, 1, 0, 3)
	_check( not assembled.is_empty() and (assembled["deposits"] as Array).is_empty(), "接满冰列不会消除")
	_check(_same_array(state["cols"][3], [2000, 0, 0]) and R.deposit_ready(state, 3) == 0, 
		"同色冰列保留盘面和冻结编码")
	_check(R.progress_at(state, 3) == 3 and int(state["done"]) == 0, "冰列同色进度已满而收集进度不变")
	var saved: Dictionary = R.state_from_dict(R.state_to_dict(state), level)
	_check( not saved.is_empty() and R.state_key(saved) == R.state_key(state), "接满冰列可存档恢复")
	var sunlight: Dictionary = R.apply_move(state, level, 0, 0, 4)
	_check(_same_array(state["cups"], [2, 0]) and int(state["done"]) == 2, 
		"阳光消除后同一步融冰并消除已满冰列")
	_test_expected_deposits("冰列等待阳光", sunlight["deposits"], [
		{"cid": 4, "color": 2, "q": 3, "k": 0, "sun": true, 
			"melted": [{"cid": 3, "index": 0, "before": 2000, "type": 0}], "spawns": []}, 
		{"cid": 3, "color": 0, "q": 3, "k": 1, "sun": false, "melted": [], "spawns": []}, 
	])
	R.undo_move(state, sunlight, true)
	_check(_same_array(state["cols"][3], [2000, 0, 0]) and int(state["done"]) == 0, 
		"撤销阳光后接满冰列重新冻结且不消除")
	R.undo_move(state, assembled)
	_check(R.state_key(state) == before, "撤销连接恢复开局")
	var connection_state: Dictionary = R.make_state(level)
	connection_state["cols"][1] = [2000] as Array[int]
	connection_state["cols"][3] = [2000] as Array[int]
	_check(R.move_info(connection_state, 1, 0, 3) == 1, "同色冰与冰可以连接")
	connection_state["cols"][3] = [0] as Array[int]
	_check(R.move_info(connection_state, 1, 0, 3) == 1, "同色冰可连接普通花")
	connection_state["cols"][3] = [1] as Array[int]
	_check(R.reject_reason(connection_state, 1, 0, 3) == R.Reject.COLOR, "异色冰连接按颜色拒绝")
	connection_state["cols"][3] = [1000] as Array[int]
	_check(R.move_info(connection_state, 1, 0, 3) == 0, "冰不能绕过目标问号限制")
	connection_state["cols"][1] = [1000] as Array[int]
	connection_state["cols"][3] = [2000] as Array[int]
	_check(R.reject_reason(connection_state, 1, 0, 3) == R.Reject.MYSTERY, "问号仍不能连接冰尾")


func _test_probes(case_name: String, state: Dictionary, probes: Array) -> void :
	for probe: Dictionary in probes:
		var expected: int = int(probe["expectedK"])
		var actual: int = R.move_info(state, int(probe["src"]), int(probe["j"]), int(probe["dst"]))
		_check(actual == expected, "%s probe %d→%d j=%d 期望 %d 实为 %d" % [
			case_name, int(probe["src"]), int(probe["dst"]), int(probe["j"]), expected, actual])


func _test_expected_deposits(case_name: String, actual: Array, expected: Array) -> void :
	_check(actual.size() == expected.size(), "%s 收集事件数量" % case_name)
	if actual.size() != expected.size():
		return
	for index in actual.size():
		var got: Dictionary = actual[index]
		var want: Dictionary = expected[index]
		_check(int(got["col"]) == int(want["cid"]), "%s 第 %d 杯 col" % [case_name, index])
		_check(int(got["fruit"]) == int(want["color"]), "%s 第 %d 杯 fruit" % [case_name, index])
		_check(int(got["q"]) == int(want["q"]), "%s 第 %d 杯 q" % [case_name, index])
		_check(int(got["nth"]) == int(want["k"]), "%s 第 %d 杯 nth" % [case_name, index])
		_check(bool(got.get("sun", false)) == bool(want.get("sun", false)), "%s 第 %d 杯 sun" % [case_name, index])
		var got_melted: Array = got.get("melted", []) as Array
		var want_melted: Array = want.get("melted", []) as Array
		_check(got_melted.size() == want_melted.size(), "%s 第 %d 杯 melted 数量" % [case_name, index])
		if got_melted.size() == want_melted.size():
			for melt_index in got_melted.size():
				var got_melt: Dictionary = got_melted[melt_index]
				var want_melt: Dictionary = want_melted[melt_index]
				_check(int(got_melt["col"]) == int(want_melt["cid"])
					and int(got_melt["index"]) == int(want_melt["index"])
					and int(got_melt["before"]) == int(want_melt["before"])
					and int(got_melt["type"]) == int(want_melt["type"]), 
					"%s 第 %d 杯第 %d 个融冰坐标" % [case_name, index, melt_index])
		_check((got.get("spawns", []) as Array).size() == (want.get("spawns", []) as Array).size(), 
			"%s 第 %d 杯 spawns" % [case_name, index])


func _test_expected_after(case_name: String, state: Dictionary, expected: Dictionary) -> void :
	if expected.is_empty():
		return
	_check(_same_array(state["cols"], expected["cols"]), "%s 最终 cols" % case_name)
	_check(_same_array(state["jars"], expected["jars"]), "%s 最终 jars" % case_name)
	_check(_same_array(state["caps"], expected["caps"]), "%s 最终 caps" % case_name)
	_check(_same_array(state["gone"], expected["gone"]), "%s 最终 gone" % case_name)
	_check(_same_locks(state["locks"], expected["locks"]), "%s 最终 locks" % case_name)
	_check(_same_value(int(state["done"]), expected["done"]), "%s 最终 done" % case_name)
	_check(_same_array(state["cups"], expected["cups"]), "%s 最终 cups" % case_name)
	_check(_same_value(int(state["late_left"]), expected["late_left"]), "%s 最终 late_left" % case_name)


func _test_undo_and_roundtrip(row: Dictionary, level: LevelC, rec: Dictionary) -> void :
	var state: Dictionary = R.make_state(level)
	var initial_key: String = R.state_key(state)
	var initial_blob: Dictionary = R.state_to_dict(state)
	var restored_initial: Dictionary = R.state_from_dict(initial_blob, level)
	_check( not restored_initial.is_empty() and R.state_key(restored_initial) == initial_key, 
		"融冰前冻结编码可续局")
	var no_sun_row: Dictionary = row.duplicate(true)
	no_sun_row.erase("sunlight")
	var no_sun_level: LevelC = LevelC.from_dict(no_sun_row)
	_check(R.state_from_dict(initial_blob, no_sun_level).is_empty(), "无 sunlight 的题面拒绝冻结存档")
	var clone: Dictionary = R.clone_state(state)
	_check(R.state_key(clone) == initial_key, "clone_state 保留冻结编码")
	var normal_state: Dictionary = R.clone_state(state)
	(normal_state["cols"] as Array)[2][1] = LevelC.true_type(int((normal_state["cols"] as Array)[2][1]))
	_check(R.state_key(normal_state) != initial_key, "state_key 区分冻结与普通状态")
	_check(R.deposit_ready(state, 2) == 0, "含冰满列不可收集")
	_check( not rec.is_empty(), "最小验证题有落子记录")
	if rec.is_empty():
		return
	var undo_state: Dictionary = R.make_state(level)
	var undo_rec: Dictionary = R.apply_move(undo_state, level, 0, 0, 1)
	R.undo_move(undo_state, undo_rec, true)
	_check(R.state_key(undo_state) == initial_key, "keep_revealed 撤销仍重新冻冰")
	_check(int((undo_state["cols"] as Array)[2][1]) == 2000, "撤销恢复 i0 编码")
	var sun_col: int = _find_sun_col(state, level)
	_check(sun_col >= 0, "最小验证题存在阳光收集器")
	if sun_col >= 0:
		_check(S.hint_lower_bound(state, sun_col, level) == 0, "阳光状态下界保守为 0")
		var candidates: Array = S.group_candidates(state, level)
		_check( not candidates.is_empty() and int(candidates[0]["col"]) == sun_col, 
			"尚有冰时提示优先阳光")
	_check(HP.lower_bound(state, level) == 0, "HintPlanner 阳光状态下界为 0")
	var no_deposit_level: LevelC = LevelC.from_dict({
		"id": 9002, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|", "-|2", "2|2,2", "0|0,i0,1", "1|1,1,0"], "incoming": [], 
	})
	var no_deposit_state: Dictionary = R.make_state(no_deposit_level)
	var no_deposit_rec: Dictionary = R.apply_move(no_deposit_state, no_deposit_level, 3, 2, 0, true)
	_check( not no_deposit_rec.is_empty() and (no_deposit_rec["deposits"] as Array).is_empty(), 
		"no_deposit 不收阳光不融冰")
	_check(int((no_deposit_state["cols"] as Array)[3][1]) == 2000, "no_deposit 保留冻结编码")


func _test_rejected_cases(cases: Array) -> void :
	for case_data: Dictionary in cases:
		var level: LevelC = LevelC.from_dict(case_data.get("level", {}))
		var errors: Array[String] = level.validate()
		var expected: String = String(case_data.get("expectedErrorContains", ""))
		var matched: bool = false
		for message: String in errors:
			if expected in message:
				matched = true
				break
		_check( not errors.is_empty() and matched, "%s 应被拒绝: %s" % [
			String(case_data.get("name", "")), str(errors)])
	var bad_sunlight: LevelC = LevelC.from_dict({
		"id": 9003, "capacity": 3, "targetCups": 3, 
		"sunlight": {"typeId": 2, "unknown": true}, 
		"initial": ["-|2", "2|2,2", "0|0,i0,0", "1|1,1,1"], "incoming": [], 
	})
	_check( not bad_sunlight.validate().is_empty(), "sunlight 未知字段应被拒绝")
	var out_of_range: LevelC = LevelC.from_dict({
		"id": 9004, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 10}, 
		"initial": ["-|2", "2|2,2", "0|0,i0,0", "1|1,1,1"], "incoming": [], 
	})
	_check( not out_of_range.validate().is_empty(), "sunlight.typeId 超 MAX_TYPES 应被拒绝")
	var white_jar: LevelC = LevelC.from_dict({
		"id": 9005, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, "whiteJar": true, 
		"initial": ["-|2", "2|2,2", "0|0,i0,0", "1|1,1,1"], "incoming": [], 
	})
	_check( not white_jar.validate().is_empty(), "whiteJar 阳光题应被拒绝")


func _test_candidate_levels(levels: Array) -> void :
	_check(levels.size() == 12, "候选阳光题数量")
	for row: Dictionary in levels:
		var level: LevelC = LevelC.from_dict(row)
		var errors: Array[String] = level.validate()
		_check(errors.is_empty(), "第 %d 题校验通过: %s" % [level.id, str(errors)])
		if not errors.is_empty():
			continue
		var encoded: Dictionary = level.to_dict()
		_check(_same_array(encoded["initial"], row["initial"]), "第 %d 题 initial 往返" % level.id)
		_check(_same_array(encoded["incoming"], row["incoming"]), "第 %d 题 incoming 往返" % level.id)
		var roundtrip: LevelC = LevelC.from_dict(encoded)
		_check(roundtrip.validate().is_empty(), "第 %d 题 to_dict 再解析" % level.id)
		_check(roundtrip.sunlight_type == level.sunlight_type, "第 %d 题 sunlight 往返" % level.id)
		if not OS.get_cmdline_user_args().has("--candidate-levels"):
			continue
		var state: Dictionary = R.make_state(level)
		var initial_key: String = R.state_key(state)
		var search_stats: Dictionary = {}
		var path: Array = S.hint_win_path(state, level, {
			"max_routes": 20000, "width": 8, "route_nodes": 30000, "route_depth": 50, 
			"stats": search_stats, 
		})
		_check( not path.is_empty(), "第 %d 题找到完整通关路线 %s" % [level.id, 
			"" if not path.is_empty() else str(search_stats)])
		if path.is_empty():
			continue
		var recs: Array = []
		for move: Dictionary in path:
			var rec: Dictionary = R.apply_move(state, level, int(move["src"]), int(move["j"]), int(move["dst"]))
			if rec.is_empty():
				break
			recs.append(rec)
		_check(recs.size() == path.size() and R.is_win(state, level), "第 %d 题通关" % level.id)
		for index in range(recs.size() - 1, -1, -1):
			R.undo_move(state, recs[index], false)
		_check(R.state_key(state) == initial_key, "第 %d 题撤销回开局" % level.id)


func _test_melted_roundtrip(row: Dictionary) -> void :
	var level: LevelC = LevelC.from_dict(row)
	var state: Dictionary = R.make_state(level)
	var path: Array = S.hint_win_path(state, level, {
		"max_routes": 20000, "width": 8, "route_nodes": 30000, "route_depth": 50, 
	})
	_check( not path.is_empty(), "续局验证题找到通关路线")
	if path.is_empty():
		return
	var sun_seen: bool = false
	for move: Dictionary in path:
		var rec: Dictionary = R.apply_move(state, level, int(move["src"]), int(move["j"]), int(move["dst"]))
		if rec.is_empty():
			break
		for deposit: Dictionary in rec.get("deposits", []) as Array:
			if bool(deposit.get("sun", false)):
				sun_seen = true
				break
		if sun_seen:
			break
	_check(sun_seen and int(state["done"]) < level.groups_total, "到达非终局融冰盘面")
	if not sun_seen:
		return
	var blob: Dictionary = R.state_to_dict(state)
	var restored: Dictionary = R.state_from_dict(blob, level)
	_check( not restored.is_empty() and R.state_key(restored) == R.state_key(state), 
		"融冰后非终局逻辑盘面可续局")


func _test_regressions() -> void :
	var ordinary: LevelC = LevelC.from_dict({
		"id": 9101, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|0,0", "1|1"], "incoming": ["-|1"], 
	})
	_check(ordinary.validate().is_empty(), "普通题回归")
	var hidden: LevelC = LevelC.from_dict({
		"id": 9102, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|?1,0", "1|1"], "incoming": ["-|0"], 
	})
	_check(hidden.validate().is_empty(), "问号题回归")
	var locked: LevelC = LevelC.from_dict({
		"id": 9103, "capacity": 2, "targetCups": 3, 
		"initial": ["-|", "0|0", {
			"column": "1|1,1", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 1}, 
		}, "2|2,0"], "incoming": ["-|2"], 
	})
	_check(locked.validate().is_empty(), "整列锁题回归")
	var empty_target: LevelC = LevelC.from_dict({
		"id": 9104, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|i0", "0|", "2|2,2", "0|0,0", "1|1,1"], "incoming": [], 
	})
	var empty_state: Dictionary = R.make_state(empty_target)
	_check(R.move_info(empty_state, 0, 0, 1) == 1, "冰可落到空的目标列")
	_check(R.has_any_move(empty_state), "冰到空列是合法走法")
	_check(_useful_move_exists(empty_state, 0, 0, 1), "useful_moves 保留冰到空列")
	var carry: LevelC = LevelC.from_dict({
		"id": 9105, "capacity": 4, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|", "0|0,i0,1", "0|0", "2|2,2", "1|1,1"], "incoming": [], 
	})
	var carry_state: Dictionary = R.make_state(carry)
	_check(R.move_info(carry_state, 1, 0, 2) == 3, "普通起点可携带内部冰连接同色非空列")
	var frozen_state: Dictionary = R.make_state(LevelC.from_dict({
		"id": 9106, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|i0", "-|", "2|2,2", "0|0,0", "1|1,1"], "incoming": [], 
	}))
	var thawed: Dictionary = R.clone_state(frozen_state)
	(thawed["cols"] as Array)[0][0] = 0
	_check(R.state_key(frozen_state) != R.state_key(thawed), "状态指纹区分冻结与普通")
	_check(S._has_sunlight_state(frozen_state, LevelC.from_dict({
		"id": 9106, "capacity": 3, "targetCups": 3, 
		"initial": ["-|i0", "-|", "2|2,2", "0|0,0", "1|1,1"], "incoming": [], 
	})) == true, "无 sunlight 题面也能从冻结编码识别机制")


func _useful_move_exists(state: Dictionary, src: int, segment_start: int, dst: int) -> bool:
	for move: Dictionary in R.useful_moves(state):
		if int(move["src"]) == src and int(move["j"]) == segment_start and int(move["dst"]) == dst:
			return true
	return false


func _find_sun_col(state: Dictionary, level: LevelC) -> int:
	var jars: Array[int] = state["jars"]
	for index in jars.size():
		if jars[index] == level.sunlight_type:
			return index
	return -1


func _same_locks(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in actual.size():
		if not (actual[index] is Dictionary) or not (expected[index] is Dictionary):
			return false
		if (actual[index] as Dictionary).size() != (expected[index] as Dictionary).size():
			return false
	return true


func _same_array(actual: Variant, expected: Variant) -> bool:
	if not (actual is Array) or not (expected is Array):
		return false
	var actual_array: Array = actual
	var expected_array: Array = expected
	if actual_array.size() != expected_array.size():
		return false
	for index in actual_array.size():
		if not _same_value(actual_array[index], expected_array[index]):
			return false
	return true


func _same_value(actual: Variant, expected: Variant) -> bool:
	if actual is Array and expected is Array:
		return _same_array(actual, expected)
	if (actual is int or actual is float) and (expected is int or expected is float):
		return is_equal_approx(float(actual), float(expected))
	return actual == expected


func _check(condition: bool, label: String) -> void :
	_checks += 1
	if not condition:
		_fail(label)


func _fail(label: String) -> void :
	_failures.append(label)
	print("  ✗ %s" % label)


func _finish() -> void :
	print("—— %d 项断言 ——" % _checks)
	if _failures.is_empty():
		print("PASS")
		quit(0)
	else:
		print("FAIL")
		quit(1)
