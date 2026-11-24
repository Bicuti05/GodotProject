extends SceneTree






const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const JuiceLevelC = preload("res://scripts/gameplay/juice_sort/core/juice_level.gd")
const JuiceLayoutC = preload("res://scripts/gameplay/juice_sort/view/juice_layout.gd")
const JuiceSkinC = preload("res://scripts/gameplay/juice_sort/view/juice_skin.gd")

var _failures: Array[String] = []


func _initialize() -> void :
	if OS.get_cmdline_user_args().has("--initial-column-order-only"):
		_test_initial_column_order()
		_finish()
		return
	if OS.get_cmdline_user_args().has("--mystery-auto-unlock-only"):
		_test_mystery_auto_unlock()
		_test_mystery_auto_unlock_undo()
		_finish()
		return
	_test_parse_and_roundtrip()
	_test_initial_column_order()
	_test_hidden_rules()
	_test_hidden_lower_bound()
	_test_hint_shortest_with_hidden()
	_test_hint_no_idle_shuffle()
	_test_count_lock()
	_test_type_lock()
	_test_incoming_lock()
	_test_new_rope_tracking_info()
	_test_combined_level()
	_test_state_roundtrip()
	_test_reveal_memory_plain_undo()
	_test_reveal_memory_snapshot_chain()
	_test_reveal_memory_replenish()
	_test_mystery_auto_unlock()
	_test_mystery_auto_unlock_undo()
	_test_cheat_last_cup()
	_test_invalid_rows()
	_test_rope_column_limit()
	_test_eight_column_layout()
	_test_high_row_layout()
	_finish()



func _test_initial_column_order() -> void :
	for initial: Array in [
		["-|", "0|0,0", "1|1,1"], 
		["0|0,0", "-|", "1|1,1"], 
		["0|0,0", "1|1,1", "-|"], 
	]:
		var lv: JuiceLevelC = JuiceLevelC.from_dict({"capacity": 2, "targetCups": 2, 
			"initial": initial, "incoming": []})
		_expect(lv.validate().is_empty(), "不同白盆位置的题面应合法")
		_expect(lv.to_dict()["initial"] == initial, "白盆在左、中、右时都保留题面列序")
	var row: Dictionary = {"capacity": 2, "targetCups": 3, "sunlight": {"typeId": 0}, 
		"initial": ["0|0", "-|1", {"column": "1|1", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 1}}, "-|0", "2|2,2"], 
		"frozenPots": [4], "incoming": []}
	for variable_caps: bool in [false, true]:
		var data: Dictionary = row.duplicate(true)
		if variable_caps:
			data["columnCaps"] = {"initial": [2, 2, 2, 2, 2], "incoming": []}
		var original: Dictionary = data.duplicate(true)
		var lv: JuiceLevelC = JuiceLevelC.from_dict(data)
		_expect(lv.validate().is_empty(), "多白盆与锁列、冻盆组合应合法")
		_expect(data == original, "解析不修改原始题面")
		_expect(lv.board_jars == [0, -1, 1, -1, 2] and lv.initial_parks == 2, 
			"有花的多个白盆保持原位置，白盆总数不依赖前缀")
		_expect(lv.board_cols == [[0], [1], [1], [0], [2, 2]], "花串保持题面列序")
		_expect( not (lv.board_locks[2] as Dictionary).is_empty()
			and (lv.board_locks[1] as Dictionary).is_empty(), "锁信息仍绑定原第3列")
		_expect(lv.board_frozen_pots == [false, false, false, false, true], "冻盆仍绑定原第5列")
		var round: JuiceLevelC = JuiceLevelC.from_dict(JSON.parse_string(JSON.stringify(lv.to_dict())))
		_expect(round.board_jars == lv.board_jars and round.board_cols == lv.board_cols
			and round.board_locks == lv.board_locks and round.board_frozen_pots == lv.board_frozen_pots, 
			"题面JSON往返不改变列序及锁、冻结坐标")
		var st: Dictionary = R.make_state(lv)
		var before: String = R.state_key(st)
		var rec: Dictionary = R.apply_move(st, lv, 3, 0, 0)
		_expect( not rec.is_empty() and int(st["done"]) == 2, "按原列号收阳光盆并解冻收盆")
		R.undo_move(st, rec, false)
		_expect(R.state_key(st) == before and st["locks"] == lv.board_locks
			and st["frozen_pots"] == lv.board_frozen_pots, "撤销还原原列序与锁、冻结状态")
		R.apply_move(st, lv, 3, 0, 0)
		R.apply_move(st, lv, 1, 0, 2)
		_expect(R.is_win(st, lv), "按原列号完成全部目标盆")



func _auto_unlock_level(capacity: int = 3) -> JuiceLevelC:
	var zeros: PackedStringArray = []
	var ones: PackedStringArray = ["?1"]
	for _i in capacity - 1:
		zeros.append("0")
		ones.append("1")
	return JuiceLevelC.from_dict({"id": 9009, "capacity": capacity, "targetCups": 2, 
		"initial": ["-|0", "0|" + ",".join(zeros), "1|" + ",".join(ones)], "incoming": []})


func _test_mystery_auto_unlock() -> void :
	for capacity: int in [2, 3, 5]:
		var lv: JuiceLevelC = _auto_unlock_level(capacity)
		_expect(lv.validate().is_empty(), "自动解开测试题面应合法")
		var st: Dictionary = R.make_state(lv)
		_expect( not R.mystery_auto_unlock_eligible(st, lv), "非最后一盆不进入染色资格")
		_expect(R.mystery_auto_unlock_candidate(st, lv).is_empty(), "非最后一盆不触发")
		var rec: Dictionary = R.apply_move(st, lv, 0, 0, 1)
		_expect( not rec.is_empty() and int(st["done"]) == 1, "先完成倒数第二盆")
		var before: String = R.state_key(st)
		_expect( not R.mystery_auto_unlock_candidate(st, lv).is_empty(), "最后一盆一个埋藏问号应命中")
		_expect(R.state_key(st) == before, "资格查询不得修改盘面")
		var result: Dictionary = R.apply_mystery_auto_unlock(st, lv)
		_expect((result.get("revealed", []) as Array).size() == 1 and R.is_win(st, lv), "自动解开满串应正常收盆通关")
		_expect((result.get("deposits", []) as Array).size() == 1, "仅新增最后一盆收集")
		_expect(R.apply_mystery_auto_unlock(st, lv).is_empty(), "重复调用不得再次解开或收盆")

	var lv: JuiceLevelC = _auto_unlock_level()
	var base: Dictionary = R.make_state(lv)
	R.apply_move(base, lv, 0, 0, 1)
	var split: Dictionary = R.clone_state(base)
	R.apply_move(split, lv, 2, 2, 0)
	var result: Dictionary = R.apply_mystery_auto_unlock(split, lv)
	_expect( not result.is_empty() and (result["deposits"] as Array).is_empty(), "跨绳最后一盆只解开，仍需玩家合并")
	_expect( not JuiceLevelC.is_hidden(split["cols"][2][0]), "跨绳问号显示真色")
	var round: Dictionary = R.state_from_dict(JSON.parse_string(JSON.stringify(R.state_to_dict(split))), lv)
	_expect( not round.is_empty() and R.state_key(round) == R.state_key(split), "自动解开状态可续局往返")

	var multiple: Dictionary = R.clone_state(base)
	multiple["cols"][2][1] = JuiceLevelC.hide_type(1)
	result = R.apply_mystery_auto_unlock(multiple, lv)
	_expect((result.get("revealed", []) as Array).size() == 2 and R.is_win(multiple, lv), "同串多个问号全部解开并正常收盆")
	var mixed: Dictionary = R.clone_state(base)
	mixed["cols"][2][1] = JuiceLevelC.hide_type(0)
	result = R.apply_mystery_auto_unlock(mixed, lv)
	_expect((result.get("revealed", []) as Array).size() == 2 and mixed["cols"][2][0] == 1
		and mixed["cols"][2][1] == 0 and (result["deposits"] as Array).is_empty(), "不同真色问号各自恢复真色，不按目标盆改色")
	var short: Dictionary = R.clone_state(base)
	(short["cols"][2] as Array[int]).pop_back()
	result = R.apply_mystery_auto_unlock(short, lv)
	_expect( not result.is_empty() and short["cols"][2][0] == 1
		and (result["deposits"] as Array).is_empty(), "花数不足仍解开，未满盆不能收盆")
	var empty: Dictionary = R.clone_state(base)
	empty["cols"][2][0] = 1
	var empty_before: String = R.state_key(empty)
	_expect( not R.mystery_auto_unlock_eligible(empty, lv), "无问号的最后一盆不进入两组染色资格")
	_expect(R.apply_mystery_auto_unlock(empty, lv).is_empty() and R.state_key(empty) == empty_before, 
		"无问号不制造自动变更或收盆")
	lv.incoming.append({"beads": [1] as Array[int]})
	_expect( not R.mystery_auto_unlock_candidate(base, lv).is_empty(), "待补货不阻断当前盘面问号解开")
	lv.incoming.pop_back()
	lv.capacity = 4
	_expect( not R.mystery_auto_unlock_candidate(base, lv).is_empty(), "解开资格不依赖默认容量")
	lv.capacity = 3
	var different_cap: Dictionary = R.clone_state(base)
	different_cap["caps"][2] = 5
	result = R.apply_mystery_auto_unlock(different_cap, lv)
	_expect( not result.is_empty() and (result["deposits"] as Array).is_empty(), "目标盆实际容量不匹配也解开，收盆仍按实际容量")
	var locked: Dictionary = R.clone_state(base)
	locked["locks"][2] = {"condition": "collect_count", "count": 2}
	result = R.apply_mystery_auto_unlock(locked, lv)
	_expect( not result.is_empty() and not R.is_win(locked, lv) and R.is_locked(locked, 2), "解开问号不绕过锁列")
	var frozen: Dictionary = R.clone_state(base)
	frozen["cols"][2][1] = JuiceLevelC.freeze_type(1)
	result = R.apply_mystery_auto_unlock(frozen, lv)
	_expect( not result.is_empty() and not R.is_win(frozen, lv), "解开问号不绕过冰封花")
	var frozen_pot: Dictionary = R.clone_state(base)
	frozen_pot["frozen_pots"] = [false, false, true] as Array[bool]
	result = R.apply_mystery_auto_unlock(frozen_pot, lv)
	_expect( not result.is_empty() and not R.is_win(frozen_pot, lv), "解开问号不绕过冻盆")

	lv = JuiceLevelC.from_dict({"id": 9073, "capacity": 5, "targetCups": 2, 
		"initial": ["4|?4,4,4", "-|?4,4", "0|0,0,0,0,0"], "incoming": []})
	_expect(lv.validate().is_empty(), "双绳两问号残局题面应合法：%s" % str(lv.validate()))
	var two_ropes: Dictionary = R.make_state(lv)
	R.run_deposit(two_ropes, lv, [])
	result = R.apply_mystery_auto_unlock(two_ropes, lv)
	_expect((result.get("revealed", []) as Array).size() == 2
		and two_ropes["cols"][0] == [4, 4, 4] and two_ropes["cols"][1] == [4, 4]
		and (result["deposits"] as Array).is_empty(), "双绳两个问号全部解开，仍等待玩家合并")
	R.apply_move(two_ropes, lv, 1, 0, 0)
	_expect(R.is_win(two_ropes, lv), "两绳揭色后正常合并收最后一盆")


func _test_mystery_auto_unlock_undo() -> void :
	var lv: JuiceLevelC = _auto_unlock_level()
	for keep: bool in [false, true]:
		var st: Dictionary = R.make_state(lv)
		R.apply_move(st, lv, 0, 0, 1)
		var before: String = R.state_key(st)
		var rec: Dictionary = R.apply_move(st, lv, 2, 2, 0)
		var result: Dictionary = R.apply_mystery_auto_unlock(st, lv)
		rec["auto_unlock_before"] = result["before"]
		rec["auto_unlock_deposits"] = result["deposits"]
		_expect(R.undo_move(st, rec, keep) == 1, "自动解开参与问号撤销记忆的同一触达口径")
		if keep:
			_expect(st["cols"][2][0] == 1, "记忆实验开启时，撤销保持已解开真色")
		else:
			_expect(R.state_key(st) == before, "撤销先恢复自动快照，再还原真实移动")
			_expect( not R.mystery_auto_unlock_candidate(st, lv).is_empty(), "撤销后可重新检查自动解开")
	var multiple_lv: JuiceLevelC = _auto_unlock_level(5)
	for keep: bool in [false, true]:
		var multiple: Dictionary = R.make_state(multiple_lv)
		R.apply_move(multiple, multiple_lv, 0, 0, 1)
		multiple["cols"][2][1] = JuiceLevelC.hide_type(1)
		var multiple_before: String = R.state_key(multiple)
		var multiple_rec: Dictionary = R.apply_move(multiple, multiple_lv, 2, 4, 0)
		var multiple_result: Dictionary = R.apply_mystery_auto_unlock(multiple, multiple_lv)
		_expect((multiple_result.get("revealed", []) as Array).size() == 2, "本次自动变更应同时解开两个问号")
		multiple_rec["auto_unlock_before"] = multiple_result["before"]
		multiple_rec["auto_unlock_deposits"] = multiple_result["deposits"]
		_expect(R.undo_move(multiple, multiple_rec, keep) == 2, "多个自动解开的问号均参与撤销记忆触达")
		if keep:
			_expect(multiple["cols"][2] == [1, 1, 1, 1, 1], "记忆开启时多个问号撤销后都保持真色")
		else:
			_expect(R.state_key(multiple) == multiple_before, "记忆关闭时多个问号与真实移动完整还原")
			_expect((R.apply_mystery_auto_unlock(multiple, multiple_lv).get("revealed", []) as Array).size() == 2, 
				"撤销后多个问号可以再次自动解开")
	var st: Dictionary = R.make_state(lv)
	var before: String = R.state_key(st)
	var rec: Dictionary = R.apply_move(st, lv, 0, 0, 1)
	var result: Dictionary = R.apply_mystery_auto_unlock(st, lv)
	rec["auto_unlock_before"] = result["before"]
	rec["auto_unlock_deposits"] = result["deposits"]
	R.undo_move(st, rec)
	_expect(R.state_key(st) == before, "原移动收盆与自动收盆双快照应完整撤销")
	st = R.make_state(lv)
	R.apply_move(st, lv, 0, 0, 1)
	R.apply_move(st, lv, 2, 2, 0)
	st["allow_root_swapping"] = true
	before = R.state_key(st)
	rec = R.apply_move(st, lv, 2, 0, 0)
	_expect(bool(rec.get("root_swapped", false)), "埋藏问号根部可走正式整串交换")
	result = R.apply_mystery_auto_unlock(st, lv)
	rec["auto_unlock_before"] = result["before"]
	rec["auto_unlock_deposits"] = result["deposits"]
	R.undo_move(st, rec)
	_expect(R.state_key(st) == before, "自动快照兼容整串交换撤销")


func _hidden_row() -> Dictionary:
	return {
		"id": 9001, 
		"capacity": 2, 
		"targetCups": 2, 
		"initial": ["-|", "0|?1,0", "1|1"], 
		"incoming": ["-|0"], 
	}


func _locked_row(condition: String = JuiceLevelC.LOCK_COLLECT_COUNT) -> Dictionary:
	var info: Dictionary = {"condition": condition, "count": 1}
	if condition == JuiceLevelC.LOCK_COLLECT_TYPE:
		info["typeId"] = 0
	return {
		"id": 9002, 
		"capacity": 2, 
		"targetCups": 3, 
		"initial": [
			"-|", 
			"0|0", 
			{"column": "1|1,1", "columnType": "unlock", "columnInfo": info}, 
			"2|2,0", 
		], 
		"incoming": ["-|2"], 
	}


func _incoming_lock_row() -> Dictionary:
	return {
		"id": 9003, 
		"capacity": 2, 
		"targetCups": 3, 
		"initial": ["-|", "0|0", "1|1,0", "2|2,1"], 
		"incoming": [{
			"column": "-|2", 
			"columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 2}, 
		}], 
	}


func _test_parse_and_roundtrip() -> void :
	var row: Dictionary = _locked_row()
	row["initial"][1] = "0|?1,0"
	row["initial"][2]["column"] = "1|1"
	var lv: JuiceLevelC = JuiceLevelC.from_dict(row)
	_expect(lv.validate().is_empty(), "合法的问号+冰封题面应通过校验: %s" % str(lv.validate()))
	_expect(lv.board_cols[1][0] == JuiceLevelC.HIDDEN_BASE + 1, "?1 应编码为 HIDDEN_BASE+1")
	_expect( not (lv.board_locks[2] as Dictionary).is_empty(), "initial 的 unlock 信息应保留")
	var round: JuiceLevelC = JuiceLevelC.from_dict(lv.to_dict())
	_expect(round.validate().is_empty(), "机制题面往返后仍应通过校验: %s" % str(round.validate()))
	_expect(round.board_cols == lv.board_cols, "问号编码往返应一致")
	_expect(round.board_locks == lv.board_locks, "冰封条件往返应一致")


func _test_hidden_rules() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_hidden_row())
	_expect(lv.validate().is_empty(), "问号测试题应合法: %s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	var key_before: String = R.state_key(st)
	var rec: Dictionary = R.apply_move(st, lv, 1, 1, 0)
	_expect( not rec.is_empty(), "应能把问号下方的明牌移到空列")
	_expect((rec.get("revealed", []) as Array).size() == 1, "问号成为串尾时应记录一次显色")
	_expect((st["cols"][1] as Array[int])[0] == 1, "问号成为串尾时应立即变成真实类型")
	R.undo_move(st, rec)
	_expect(R.state_key(st) == key_before, "撤销应恢复问号编码与原盘面")

	var probe: Dictionary = R.make_state(lv)
	var probe_cols: Array = []
	probe_cols.append([0, JuiceLevelC.hide_type(1), 0] as Array[int])
	probe_cols.append([1] as Array[int])
	probe_cols.append([0] as Array[int])
	probe["cols"] = probe_cols
	probe["caps"] = [4, 4, 4] as Array[int]
	probe["jars"] = [0, 1, 0] as Array[int]
	probe["gone"] = [false, false, false] as Array[bool]
	probe["locks"] = [{}, {}, {}]
	_expect(R.move_info(probe, 0, 1, 1) == 0, "连接点是问号时不能接到非空同真色列")
	_expect(R.move_info(probe, 0, 1, 2) == 0, "连接点是问号时不能接到另一条非空列")
	_expect(R.reject_reason(probe, 0, 1, 1) == R.Reject.MYSTERY, "问号接非空列应归因 MYSTERY 而非 COLOR")
	probe["locks"] = [{}, {"condition": "collect_count", "count": 1}, {}]
	_expect(R.reject_reason(probe, 2, 0, 1) == R.Reject.LOCKED, "落到锁列应归因 LOCKED 而非 FULL")
	probe["locks"] = [{}, {}, {}]
	probe["cols"][2] = [] as Array[int]
	_expect(R.move_info(probe, 0, 1, 2) == 2, "连接点是问号时仍可把整段放到空列")
	probe["cols"][2] = [0] as Array[int]
	_expect(R.move_info(probe, 0, 0, 2) == 3, "问号仅在段内时不应阻止明牌连接点合并")
	probe["cols"][0] = [0, 0, 0, JuiceLevelC.hide_type(1), 0] as Array[int]
	probe["cols"][2] = [] as Array[int]
	probe["caps"] = [5, 5, 5] as Array[int]
	var has_middle_cut: bool = false
	for move: Dictionary in R.useful_moves(probe):
		if int(move["src"]) == 0 and int(move["j"]) == 1 and int(move["dst"]) == 2:
			has_middle_cut = true
			break
	_expect(has_middle_cut, "含问号列落到空列时不得用同色段剪枝漏掉中间切点")
	var hint: Dictionary = S.hint_move(st, lv)
	_expect( not hint.is_empty() and not bool(hint.get("guess", false)), 
		"含问号盘面应按真实花色找出下一盆路线")
	var path: Array = hint.get("path", [])
	_expect( not path.is_empty(), "含问号提示应带有可收盆的完整路线")
	var simulated: Dictionary = R.clone_state(st)
	for mv: Dictionary in path:
		var src: int = int(mv["src"])
		var j: int = int(mv["j"])
		var dst: int = int(mv["dst"])
		_expect(R.move_info(simulated, src, j, dst) > 0, 
			"问号提示每一步仍须遵守未显色不能拼接的规则")
		if R.apply_move(simulated, lv, src, j, dst, true).is_empty():
			break
	if not path.is_empty():
		_expect(R.deposit_ready(simulated, int(hint["col"])) > 0, 
			"问号提示路线走完应能收下一盆")
	_expect(bool(S.hint_move(st, lv, {"shallow_nodes": 0, "deep_nodes": 0}).get("guess", false)), 
		"预算耗尽时仍沿用原有 C 层猜测兜底")



func _solver_state(cols_in: Array, jars_in: Array, cap: int) -> Dictionary:
	var cols: Array = []
	var caps: Array[int] = []
	var gone: Array[bool] = []
	var locks: Array = []
	for c: Array in cols_in:
		var col: Array[int] = []
		col.assign(c)
		cols.append(col)
		caps.append(cap)
		gone.append(false)
		locks.append({})
	var jars: Array[int] = []
	jars.assign(jars_in)
	var cups: Array[int] = []
	return {"cols": cols, "jars": jars, "caps": caps, "gone": gone, "locks": locks, 
		"done": 0, "cups": cups, "late_left": 0, "extra_rope_used": false}


func _test_hidden_lower_bound() -> void :
	var q0: int = JuiceLevelC.hide_type(0)

	var st: Dictionary = _solver_state([[0, q0, 0], [0, 0, 0]], [0, JuiceLevelC.NO_JAR], 6)
	_expect(S.hint_lower_bound(st, 0) == 3, 
		"问号下界应按真实花色数供货段(清杂色 1 + 两段供货 2 = 3),实得 %d"
		%S.hint_lower_bound(st, 0))


func _test_hint_shortest_with_hidden() -> void :



	var lv: JuiceLevelC = JuiceLevelC.new()
	lv.types = 9
	lv.capacity = 6
	lv.groups_total = 12
	var st: Dictionary = _solver_state([
		[1, 1, 6, 6], [1, 1, 1], [5, 5, 5], 
		[2, JuiceLevelC.hide_type(1), 2, 2, 2, 2], [5, 0, 0, 0], [6, 6, 6, 6, 2], 
	], [JuiceLevelC.NO_JAR, 5, 6, 1, 0, 2], 6)
	var hint: Dictionary = S.hint_move(st, lv)
	_expect(bool(hint.get("optimal", false)) and int(hint.get("len", -1)) == 9, 
		"含问号盘面的提示应给出 9 步零整理路线,实得 len=%s optimal=%s"
		%[str(hint.get("len")), str(hint.get("optimal"))])
	var simulated: Dictionary = R.clone_state(st)
	for mv: Dictionary in hint.get("path", []) as Array:
		_expect( not R.apply_move(simulated, lv, int(mv["src"]), int(mv["j"]), 
			int(mv["dst"]), true).is_empty(), "最短提示的每一步都必须合法")
	_expect(R.deposit_ready(simulated, int(hint.get("col", -1))) > 0, 
		"最短提示走完应能收下一盆")
	_expect_no_idle_shuffle(st, lv, hint, "问号盘面")



func _test_hint_no_idle_shuffle() -> void :
	var lv: JuiceLevelC = JuiceLevelC.new()
	lv.types = 9
	lv.capacity = 4
	lv.groups_total = 12
	var no: int = JuiceLevelC.NO_JAR

	var st: Dictionary = _solver_state([[1, 1, 1, 1], [2, 2], []], [0, 1, no], 4)
	var hint: Dictionary = S.hint_move(st, lv)
	var mv: Dictionary = hint.get("move", {})
	_expect( not bool(hint.get("guess", false)) and int(mv.get("src", -1)) == 1
		and int(mv.get("dst", -1)) == 2, "必要的整列腾盆仍应提示,实得 %s" % str(hint))

	st = _solver_state([[1, 1, 1, 1], []], [0, 1], 4)
	mv = S.hint_move(st, lv).get("move", {})
	_expect(int(mv.get("src", -1)) == 0 and int(mv.get("dst", -1)) == 1 and int(mv.get("j", -1)) == 0, 
		"整列拖到空绳直接种满应照常提示,实得 %s" % str(mv))

	st = _solver_state([[5, 7, 5, 6], [7, 4, 3], [6, 3, 7], [4, 6, 4, 7], [5, 3], []], 
		[no, 7, 4, 3, 5, 6], 4)
	hint = S.hint_move(st, lv)
	_expect_no_idle_shuffle(st, lv, hint, "③")

	st = _solver_state([[3, 3], [0, 0, 0], [], [3, 3]], [0, 1, no, 3], 4)
	hint = S.hint_move(st, lv)
	_expect(int(hint.get("len", -1)) == 1, "多余整理不该进路线,实得 %s" % str(hint))
	_expect_no_idle_shuffle(st, lv, hint, "④")



func _expect_no_idle_shuffle(st: Dictionary, lv: JuiceLevelC, hint: Dictionary, tag: String) -> void :
	var path: Array = hint.get("path", [])
	if path.is_empty():
		return
	var pr: Dictionary = S._prune_shuffles(st, lv, path, "ready")
	_expect((pr["path"] as Array).size() == path.size(), 
		"%s 提示路线里仍有多余整理步:%s" % [tag, str(path)])


func _test_count_lock() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_locked_row())
	_expect(lv.validate().is_empty(), "累计收盆冰封题应合法: %s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	var locked_ci: int = 2
	var key_before: String = R.state_key(st)
	_expect(R.is_locked(st, locked_ci), "开局冰封应进入规则状态")
	_expect(R.move_info(st, locked_ci, 1, 0) == 0, "冰封列不能拖出")
	_expect(R.move_info(st, 3, 1, locked_ci) == 0, "冰封列不能接收")
	_expect(R.deposit_ready(st, locked_ci) == 0, "冰封满列不能收盆")
	var hint: Dictionary = S.hint_move(st, lv)
	_expect( not hint.is_empty() and not bool(hint.get("guess", false)), 
		"含冰封列的盘面应走原有搜索找出下一盆路线")
	if not hint.is_empty():
		var mv: Dictionary = hint["move"]
		_expect(int(mv["src"]) != locked_ci and int(mv["dst"]) != locked_ci, 
			"冰封列不能参与提示落子")
		var hinted: Dictionary = R.clone_state(st)
		_expect( not R.apply_move(hinted, lv, int(mv["src"]), int(mv["j"]), 
			int(mv["dst"])).is_empty() and int(hinted["done"]) == 1, 
			"照冰封提示走应按规则收下一盆")
	var rec: Dictionary = R.apply_move(st, lv, 3, 1, 1)
	_expect(int(st["done"]) == 1, "测试步应先收满一盆")
	_expect((rec.get("unlocked", []) as Array).size() == 1, "达到累计条件时应记录解锁")
	_expect( not R.is_locked(st, locked_ci), "达到累计条件后冰封应解除")
	_expect((st["cols"][locked_ci] as Array).size() == 2, 
		"同一步刚解锁的满列不应立即被级联收走")
	R.undo_move(st, rec)
	_expect(R.is_locked(st, locked_ci), "撤销应恢复冰封")
	_expect(R.state_key(st) == key_before, "撤销后含锁状态指纹应还原")

	var empty_locked: Dictionary = R.make_state(lv)
	empty_locked["locks"][0] = {"condition": "collect_count", "count": 2}
	var stats: Dictionary = R.board_stats(empty_locked)
	_expect(int(stats["slots"]) == 4, "冰封空列不能计入可用工作位")


func _test_type_lock() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_locked_row(JuiceLevelC.LOCK_COLLECT_TYPE))
	_expect(lv.validate().is_empty(), "指定花色冰封题应合法: %s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	var rec: Dictionary = R.apply_move(st, lv, 3, 1, 1)
	_expect( not rec.is_empty() and not R.is_locked(st, 2), "收满一盆 0 号花后应解除 collect_type 冰封")


func _test_incoming_lock() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_incoming_lock_row())
	_expect(lv.validate().is_empty(), "incoming 冰封题应合法: %s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	_expect( not R.is_locked(st, 1), "incoming 冰封不应提前出现在开局")
	var rec: Dictionary = R.apply_move(st, lv, 2, 1, 1)
	_expect( not rec.is_empty() and int(st["done"]) == 1, "测试步应收满第一盆")
	_expect(R.is_locked(st, 1), "incoming 批次落地后应在该列挂锁")
	_expect((st["cols"][1] as Array[int]) == ([2] as Array[int]), "incoming 花朵应先落地再挂锁")
	R.undo_move(st, rec)
	_expect( not R.is_locked(st, 1), "撤销收盆应移除 incoming 新锁")


func _test_new_rope_tracking_info() -> void :
	var row: Dictionary = _incoming_lock_row()
	var lv: JuiceLevelC = JuiceLevelC.from_dict(row)
	var st: Dictionary = R.make_state(lv)
	var rec: Dictionary = R.apply_move(st, lv, 2, 1, 1)
	var info: Dictionary = (rec["deposits"] as Array)[0]["new_rope"] as Dictionary
	_expect( not bool(info["is_empty"]) and bool(info["has_lock"])
		and not bool(info["has_question"]), "自动滑入的锁列应保留当杯的特殊玩法素材")

	row["incoming"][0] = {"column": "-|?2,1", "columnType": "unlock", 
		"columnInfo": {"condition": "collect_count", "count": 2}}
	lv = JuiceLevelC.from_dict(row)
	st = R.make_state(lv)
	rec = R.apply_move(st, lv, 2, 1, 1)
	info = (rec["deposits"] as Array)[0]["new_rope"] as Dictionary
	_expect(bool(info["has_question"]) and bool(info["has_lock"]), 
		"同列问号加锁应同时保留两种素材，供页面省略单值特殊玩法字段")

	row["incoming"][0] = "-|?2,1"
	lv = JuiceLevelC.from_dict(row)
	st = R.make_state(lv)
	rec = R.apply_move(st, lv, 2, 1, 1)
	info = (rec["deposits"] as Array)[0]["new_rope"] as Dictionary
	_expect(bool(info["has_question"]) and not bool(info["has_lock"]), 
		"自动滑入的问号列应保留问号特殊玩法素材")

	row["incoming"][0] = "-|"
	lv = JuiceLevelC.from_dict(row)
	st = R.make_state(lv)
	rec = R.apply_move(st, lv, 2, 1, 1)
	info = (rec["deposits"] as Array)[0]["new_rope"] as Dictionary
	_expect(bool(info["is_empty"]) and not bool(info["has_lock"])
		and not bool(info["has_question"]), "自动换入空绳应报空绳且不带特殊玩法")

	row["incoming"][0] = "x"
	lv = JuiceLevelC.from_dict(row)
	st = R.make_state(lv)
	rec = R.apply_move(st, lv, 2, 1, 1)
	info = (rec["deposits"] as Array)[0]["new_rope"] as Dictionary
	_expect(info.is_empty(), "收集后直接退出的列不应产生新绳索事件")


func _test_combined_level() -> void :
	var row: Dictionary = _locked_row()
	row["initial"][3] = "2|?2,0"
	var lv: JuiceLevelC = JuiceLevelC.from_dict(row)
	_expect(lv.validate().is_empty(), "问号+冰封组合题应合法: %s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	var hint: Dictionary = S.hint_move(st, lv)
	_expect( not hint.is_empty() and not bool(hint.get("guess", false)), 
		"问号与冰封并存时仍应找到真实可收盆路线")
	if not hint.is_empty():
		var mv: Dictionary = hint["move"]
		var hinted: Dictionary = R.clone_state(st)
		_expect( not R.apply_move(hinted, lv, int(mv["src"]), int(mv["j"]), 
			int(mv["dst"])).is_empty() and int(hinted["done"]) == 1, 
			"组合题提示应按正式问号、冰封规则收下一盆")
	var first: Dictionary = R.apply_move(st, lv, 3, 1, 1)
	_expect( not first.is_empty() and int(st["done"]) == 1, "组合题第一步应收满 0 号花")
	_expect((first.get("revealed", []) as Array).size() == 1, 
		"组合题第一步应让源列串尾问号显色")
	_expect((first.get("unlocked", []) as Array).size() == 1 and not R.is_locked(st, 2), 
		"组合题第一步应在级联结算后解锁满列")
	_expect((st["cols"][2] as Array[int]).size() == lv.capacity, 
		"组合题本步刚解锁的满列不能立刻收盆")
	_expect( not R.apply_move(st, lv, 3, 0, 1).is_empty() and int(st["done"]) == 2, 
		"组合题下一步应触发已解锁满列收盆")
	_expect( not R.apply_move(st, lv, 1, 0, 3).is_empty() and R.is_win(st, lv), 
		"组合题应能继续移动并完成")


func _test_state_roundtrip() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_incoming_lock_row())
	var st: Dictionary = R.make_state(lv)
	var rec: Dictionary = R.apply_move(st, lv, 2, 1, 1)
	_expect( not rec.is_empty(), "存档测试前置移动应成功")
	(st["cols"][2] as Array[int])[0] = JuiceLevelC.hide_type(1)
	var blob: Dictionary = R.state_to_dict(st)
	var restored: Dictionary = R.state_from_dict(blob, lv)
	_expect( not restored.is_empty(), "带问号和冰封的状态应可恢复")
	_expect(R.state_key(restored) == R.state_key(st), "恢复后的机制状态指纹应一致")
	_expect((R.clone_state(st)["locks"] as Array) == (st["locks"] as Array), "克隆应保留冰封状态")
	var plain_row: Dictionary = _hidden_row()
	plain_row["initial"][1] = "0|1,0"
	var plain_level: JuiceLevelC = JuiceLevelC.from_dict(plain_row)
	var old_blob: Dictionary = R.state_to_dict(R.make_state(plain_level))
	old_blob.erase("locks")
	_expect( not R.state_from_dict(old_blob, plain_level).is_empty(), "普通旧关缺少 locks 的旧存档仍应兼容读取")
	var unsafe_blob: Dictionary = blob.duplicate(true)
	unsafe_blob.erase("locks")
	_expect(R.state_from_dict(unsafe_blob, lv).is_empty(), "机制关缺少 locks 时应丢档而不是绕过冰封")


func _test_cheat_last_cup() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_locked_row())
	var original: Dictionary = R.make_state(lv)
	var before: String = R.state_key(original)
	var near_win: Dictionary = R.cheat_last_cup_state(original, lv)
	_expect( not near_win.is_empty(), "当前关应能布置只差一杯的盘面")
	if near_win.is_empty():
		return
	_expect(R.state_key(original) == before, "cheat 不能修改原盘面")
	_expect(int(near_win["done"]) == lv.groups_total - 1
		and (near_win["cups"] as Array).size() == lv.groups_total - 1, 
		"已完成杯数与列表应同步到只差一杯")
	var restored: Dictionary = R.state_from_dict(R.state_to_dict(near_win), lv)
	_expect( not restored.is_empty(), "只差最后一步的盘面应可续局")
	var last_move: Dictionary = {}
	for move: Dictionary in R.useful_moves(near_win):
		var probe: Dictionary = R.clone_state(near_win)
		var rec: Dictionary = R.apply_move(probe, lv, int(move["src"]), int(move["j"]), int(move["dst"]))
		if not rec.is_empty() and R.is_win(probe, lv):
			last_move = move
			break
	_expect( not last_move.is_empty(), "玩家应有一笔合法拖动可按正常规则通关")

	var progressed: Dictionary = R.clone_state(original)
	var collected: Array[int] = progressed["cups"] as Array[int]
	collected.append(lv.jar_seq[0])
	progressed["done"] = 1
	var progressed_near_win: Dictionary = R.cheat_last_cup_state(progressed, lv)
	_expect( not progressed_near_win.is_empty(), "已有真实杯记录时仍可布置近胜局面")
	if not progressed_near_win.is_empty():
		_expect((progressed_near_win["cups"] as Array[int])[0] == lv.jar_seq[0], 
			"已有杯记录应保持在首位")
	var one_col: Dictionary = R.clone_state(original)
	for ci in range(1, (one_col["cols"] as Array).size()):
		(one_col["gone"] as Array[bool])[ci] = true
		(one_col["caps"] as Array[int])[ci] = 0
	_expect(R.cheat_last_cup_state(one_col, lv).is_empty(), "只剩一条在场绳时应拒绝且不改盘")
	var finished: Dictionary = R.clone_state(original)
	finished["done"] = lv.groups_total
	_expect(R.cheat_last_cup_state(finished, lv).is_empty(), "已通关状态不能再布置最后一杯")


func _test_invalid_rows() -> void :
	var hidden_tail: Dictionary = _hidden_row()
	hidden_tail["initial"][1] = "0|0,?1"
	_expect( not JuiceLevelC.from_dict(hidden_tail).validate().is_empty(), "开局串尾问号必须报错")
	var incoming_tail: Dictionary = _hidden_row()
	incoming_tail["incoming"][0] = "-|?0"
	_expect( not JuiceLevelC.from_dict(incoming_tail).validate().is_empty(), "incoming 最后一朵问号必须报错")
	var unknown: Dictionary = _locked_row()
	unknown["initial"][2]["columnType"] = "frozen"
	_expect( not JuiceLevelC.from_dict(unknown).validate().is_empty(), "未知 columnType 必须报错")
	var impossible: Dictionary = _locked_row()
	impossible["initial"][2]["columnInfo"]["count"] = 3
	_expect( not JuiceLevelC.from_dict(impossible).validate().is_empty(), "通关时才满足的锁必须报错")

	var multi_type: Dictionary = _locked_row(JuiceLevelC.LOCK_COLLECT_TYPE)
	multi_type["initial"][2]["columnInfo"]["count"] = 2
	_expect( not JuiceLevelC.from_dict(multi_type).validate().is_empty(), 
		"collect_type 的 count 超过 1 必须报错(无 UI)")
	var too_many_columns: Dictionary = _hidden_row()
	for _i in 5:
		too_many_columns["initial"].append("-|")
	var column_errors: Array[String] = JuiceLevelC.from_dict(too_many_columns).validate()
	_expect("开局列数 8 > 上限 7(需为增加绳子道具预留 1 列)" in column_errors, 
		"8 列题面必须被拒绝，为增加绳子道具预留第 8 列")


func _test_rope_column_limit() -> void :
	var seven_cols: Dictionary = _empty_rope_state(7)
	_expect(R.add_rope(seven_cols, 2) == 7, "7 列盘面应能增加第 8 根绳子")
	_expect((seven_cols["cols"] as Array).size() == 8, "加绳后盘面应恰好为 8 列")
	_expect((seven_cols["cols"][7] as Array).is_empty()
		and (seven_cols["locks"][7] as Dictionary).is_empty(), 
		"道具加绳应是无特殊玩法的空绳")
	var eight_cols: Dictionary = _empty_rope_state(8)
	_expect(R.add_rope(eight_cols, 2) == -1, "8 列盘面必须拒绝增加第 9 根绳子")
	_expect((eight_cols["cols"] as Array).size() == 8, "拒绝加绳后不能改变盘面列数")


func _empty_rope_state(columns: int) -> Dictionary:
	var cols: Array = []
	var jars: Array[int] = []
	var caps: Array[int] = []
	var gone: Array[bool] = []
	var locks: Array = []
	for _i in columns:
		cols.append([] as Array[int])
		jars.append(JuiceLevelC.NO_JAR)
		caps.append(2)
		gone.append(false)
		locks.append({})
	return {
		"cols": cols, 
		"jars": jars, 
		"caps": caps, 
		"gone": gone, 
		"locks": locks, 
		"extra_rope_used": false, 
	}


func _test_eight_column_layout() -> void :
	var rect: = Rect2(Vector2.ZERO, Vector2(1080.0, 1304.0))
	var skin: JuiceSkin = JuiceSkinC.bead()
	var seven: JuiceLayout = JuiceLayoutC.new()
	seven.solve(rect, 7, 5, skin, 7)
	var eight: JuiceLayout = JuiceLayoutC.new()
	eight.solve(rect, 8, 5, skin, 7)
	_expect(is_equal_approx(eight.fruit_d, 168.0), "8 列花朵画布应为 168")
	_expect(is_equal_approx(eight.blender_display_w, 150.0), "8 列空盆画布应为 150")
	_expect(is_equal_approx(eight.col_w, 126.571426), "8 列中心间距应约为 126.57")
	_expect(is_equal_approx(eight.gap, seven.gap), "8 列纵向花距应沿用 7 列")
	_expect(is_equal_approx(eight.rope_scale_d, seven.rope_scale_d), "8 列绳粗应沿用 7 列")
	_expect(is_equal_approx(eight.rope_bottom, seven.rope_bottom), "8 列绳尾应沿用 7 列")
	_expect(is_equal_approx(eight.span(), seven.span()), "7→8 列后整排宽度必须保持不变")
	_expect(eight.problems(rect).is_empty(), "8 列布局不应越界或产生不可用触控区: %s"
		%str(eight.problems(rect)))


func _test_high_row_layout() -> void :
	var rect: = Rect2(Vector2.ZERO, Vector2(1080.0, 1304.0))
	for skin: JuiceSkin in [JuiceSkinC.bead()]:
		for columns in range(3, 9):
			var base_columns: int = mini(columns, 7)
			var five: JuiceLayout = JuiceLayoutC.new()
			five.solve(rect, columns, 5, skin, base_columns)
			for rows in range(3, 6):
				var original: JuiceLayout = JuiceLayoutC.new()
				original.solve(rect, columns, rows, skin, base_columns)
				_expect(is_equal_approx(original.gap, five.gap)
					and is_equal_approx(original.fruit_d, five.fruit_d)
					and is_equal_approx(original.first_fruit_y, five.first_fruit_y)
					and is_equal_approx(original.rope_bottom, 
							five.rope_bottom + float(rows - 5) * five.gap), 
						"%s %d 列 × %d 行原有尺寸与绳尾不得改变"
						%[skin.id, columns, rows])
			for rows in range(6, 9):
				var layout: JuiceLayout = JuiceLayoutC.new()
				layout.solve(rect, columns, rows, skin, base_columns)
				_expect(layout.problems(rect).is_empty(), 
					"%s %d 列 × %d 行布局应可用: %s"
					%[skin.id, columns, rows, str(layout.problems(rect))])
				_expect(layout.rope_bottom
					+ layout.fruit_d * JuiceLayoutC.TRACK_BOTTOM_FRUIT_RATIO
					<= rect.end.y, "%s %d 列 × %d 行胶囊下端不能被裁切"
					%[skin.id, columns, rows])
				_expect(layout.gap >= 88.0 and layout.fruit_d >= 100.0, 
					"%s %d 列 × %d 行尺寸低于拖拽布局底线: 花距 %.2f / 花 %.2f"
					%[skin.id, columns, rows, layout.gap, layout.fruit_d])
				_expect(is_equal_approx(layout.blender_top, five.blender_top)
					and is_equal_approx(layout.plank_top, five.plank_top)
					and is_equal_approx(layout.first_fruit_y - layout.fruit_d
					* skin.fruit_visual_center_offset_y_ratio, 
					five.first_fruit_y - five.fruit_d
					* skin.fruit_visual_center_offset_y_ratio), 
					"%s %d 列 × %d 行不能移动花盆/货架/第一朵布局点"
					%[skin.id, columns, rows])
				if rows == 6:
					var expected: PackedFloat32Array = _six_row_baseline(columns)
					_expect(absf(layout.fruit_d - expected[0]) < 0.001
						and absf(layout.gap - expected[1]) < 0.001
						and absf(layout.first_fruit_y - expected[2]) < 0.001
						and absf(layout.rope_bottom - expected[3]) < 0.001, 
						"%s %d→%d 列 × 6 行数值回归: %s" % [
							skin.id, base_columns, columns, str(expected)])
			if columns < 8:
				for rows in range(6, 9):
					var extra: JuiceLayout = JuiceLayoutC.new()
					extra.solve(rect, columns + 1, rows, skin, columns)
					_expect(extra.problems(rect).is_empty(), 
						"%s %d→%d 列 × %d 行加绳布局应可用: %s"
						%[skin.id, columns, columns + 1, rows, 
							str(extra.problems(rect))])
					_expect(extra.gap >= 88.0 and extra.fruit_d >= 100.0
						and extra.rope_bottom
						+ extra.fruit_d * JuiceLayoutC.TRACK_BOTTOM_FRUIT_RATIO <= rect.end.y, 
						"%s %d→%d 列 × %d 行加绳后尺寸/胶囊不得失效"
						%[skin.id, columns, columns + 1, rows])
					if rows == 6:
						var expected: PackedFloat32Array = _six_row_baseline(columns + 1)
						_expect(absf(extra.fruit_d - expected[0]) < 0.001
							and absf(extra.gap - expected[1]) < 0.001
							and absf(extra.first_fruit_y - expected[2]) < 0.001
							and absf(extra.rope_bottom - expected[3]) < 0.001, 
							"%s %d→%d 列 × 6 行加绳数值不得改变" % [
								skin.id, columns, columns + 1])


func _six_row_baseline(columns: int) -> PackedFloat32Array:
	if columns == 8:
		return PackedFloat32Array([168.0, 152.23525, 327.994999, 1240.0])
	if columns == 7:
		return PackedFloat32Array([180.0, 152.23525, 328.684999, 1240.0])
	return PackedFloat32Array([188.77171, 152.23525, 329.189372, 1240.0])



func _test_reveal_memory_plain_undo() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict(_hidden_row())
	for keep: bool in [false, true]:
		var st: Dictionary = R.make_state(lv)
		var rec: Dictionary = R.apply_move(st, lv, 1, 1, 0)
		var touched: int = R.undo_move(st, rec, keep)
		_expect(touched == 1, "撤销盖回已揭开问号应返回 1(keep=%s),实际 %d" % [keep, touched])
		var bottom: int = (st["cols"][1] as Array[int])[0]
		var want: int = 1 if keep else JuiceLevelC.hide_type(1)
		_expect(bottom == want, "keep=%s 撤销后问号位应为 %d,实际 %d" % [keep, want, bottom])
	var st2: Dictionary = R.make_state(lv)
	var rec2: Dictionary = R.apply_move(st2, lv, 2, 0, 0)
	_expect( not rec2.is_empty(), "应能把明牌移到空列")
	_expect(R.undo_move(st2, rec2, true) == 0, "没有揭开过问号的撤销应返回 0")



func _test_reveal_memory_snapshot_chain() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict({
		"id": 9010, "capacity": 3, "targetCups": 4, 
		"initial": ["-|", "0|0,0", "1|?1,2,0", "2|2,2"], 
		"incoming": [], 
	})
	for keep: bool in [false, true]:
		var st: Dictionary = R.make_state(lv)
		var rec_i: Dictionary = R.apply_move(st, lv, 2, 2, 1)
		_expect( not (rec_i["snap"] as Dictionary).is_empty(), "第一步应收盆并留快照")
		var rec_m: Dictionary = R.apply_move(st, lv, 2, 1, 3)
		_expect((rec_m.get("revealed", []) as Array).size() == 1, "第二步应揭开问号")
		_expect(R.undo_move(st, rec_m, keep) == 1, "撤销揭开那一步应返回 1(keep=%s)" % keep)
		var touched_i: int = R.undo_move(st, rec_i, keep)
		var bottom: int = (st["cols"][2] as Array[int])[0]
		if keep:
			_expect(touched_i == 1, "实验组再撤收盆那一步,快照会盖回问号,应返回 1,实际 %d" % touched_i)
			_expect(bottom == 1, "实验组连撤后问号应保持真实颜色,实际 %d" % bottom)
		else:
			_expect(touched_i == 0, "对照组问号已盖回,再撤一步应返回 0,实际 %d" % touched_i)
			_expect(bottom == JuiceLevelC.hide_type(1), "对照组连撤后应仍是问号,实际 %d" % bottom)
		_expect((st["cols"][2] as Array[int]).size() == 3, "连撤后第 2 列应恢复 3 朵")



func _test_reveal_memory_replenish() -> void :
	var lv: JuiceLevelC = JuiceLevelC.from_dict({
		"id": 9011, "capacity": 3, "targetCups": 3, 
		"initial": ["-|", "0|0,0", "1|1,0"], 
		"incoming": ["2|?2,1"], 
	})
	for keep: bool in [false, true]:
		var st: Dictionary = R.make_state(lv)
		var rec_i: Dictionary = R.apply_move(st, lv, 2, 1, 1)
		var spawns: Array = rec_i.get("hidden_spawns", [])
		_expect(spawns.size() == 1, "补货批里的问号应记一条落点,实际 %d" % spawns.size())
		var col1: Array[int] = st["cols"][1]
		_expect(col1.size() == 2 and col1[0] == JuiceLevelC.hide_type(2), "补货应落在被清空的第 1 列底部: %s" % str(col1))
		var rec_m: Dictionary = R.apply_move(st, lv, 1, 1, 2)
		_expect( not rec_m.is_empty(), "应能把补货串尾接到同色列")
		_expect((st["cols"][1] as Array[int])[0] == 2, "补货问号成为串尾应揭开")
		_expect(R.undo_move(st, rec_m, keep) == 1, "撤销揭开补货问号那一步应返回 1(keep=%s)" % keep)
		_expect(R.undo_move(st, rec_i, keep) == (0 if not keep else 1), 
			"撤到补货之前:实验组退回队列的已揭开花应计 1,对照组已盖回计 0(keep=%s)" % keep)
		if keep:
			var memory: Dictionary = st.get("reveal_memory", {})
			_expect(memory.has("0:0"), "实验组应记住第 0 杯补货的第 0 朵: %s" % str(memory))
			var round: Dictionary = R.state_from_dict(R.state_to_dict(st), lv)
			_expect( not round.is_empty() and (round.get("reveal_memory", {}) as Dictionary).has("0:0"), 
				"reveal_memory 应随存档往返")
		R.apply_move(st, lv, 2, 1, 1)
		var again: int = (st["cols"][1] as Array[int])[0]
		var want: int = 2 if keep else JuiceLevelC.hide_type(2)
		_expect(again == want, "keep=%s 再次补货该朵应为 %d,实际 %d" % [keep, want, again])
		_expect( not R.clone_state(st).has("reveal_memory"), "clone_state 不复制记忆(求解器热路径不变)")


func _expect(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)


func _finish() -> void :
	if _failures.is_empty():
		print("juice mechanics selftest OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("juice mechanics selftest: %s" % failure)
	quit(1)
