extends SceneTree




const R: GDScript = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S: GDScript = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

var _failures: Array[String] = []



func _initialize() -> void :
	_test_basic_and_mapping()
	_test_not_enough()
	_test_invalid_target()
	_test_locked_columns()
	_test_hidden_flowers()
	_test_full_board_exchange()
	_test_surplus_same_color()
	_test_cascade_and_memory()
	_test_unlock_after_deposit()
	_test_missing_locks_and_extra_rope()
	_test_random_distribution()
	_test_checked_skips_dead_column()
	_test_checked_reveal_fallback()
	_test_checked_reveal_from_other_column()
	_test_checked_reveal_prefers_target_column()
	_test_checked_reveal_skips_locked_column()
	_test_checked_reveal_insufficient()
	_test_checked_all_dead_fallback()
	_test_checked_timing_fields()
	_finish()




func _level(initial: Array, capacity: int = 3, incoming: Array = [], 
		target_cups: int = 8) -> JuiceLevel:
	return JuiceLevel.from_dict({
		"capacity": capacity, "targetCups": target_cups, "initial": initial, 
		"incoming": incoming, 
	})




func _build_and_finalize(st: Dictionary, lv: JuiceLevel, ci: int) -> Dictionary:
	var built: Dictionary = R.build_complete_column_state(st, lv, ci)
	if built.is_empty():
		return {}
	var rec: Dictionary = R.finalize_complete_column(built["state"] as Dictionary, lv, 
		built["revealed_target"] as Array)
	return {"state": built["state"], "mapping": built["mapping"], "rec": rec}



func _complete(st: Dictionary, lv: JuiceLevel, ci: int, label: String) -> Dictionary:
	var before: Dictionary = st.duplicate(true)
	var got: Dictionary = _build_and_finalize(st, lv, ci)
	_check(st == before, label + "：输入完整状态不得修改")
	_check( not got.is_empty(), label + "：应成功凑满")
	if got.is_empty():
		return {}
	var mapping: Dictionary = got.get("mapping", {})
	var rearranged: Dictionary = _reconstruct(st, mapping, label, ci)
	_check(R.deposit_ready(rearranged, ci) == int((st["caps"] as Array[int])[ci]), 
		label + "：mapping 重现的结算前目标必须满盆")
	var result: Dictionary = got["state"]
	var rec: Dictionary = got["rec"]
	for field: String in ["deposits", "revealed", "unlocked", "hidden_spawns"]:
		_check(rec.has(field), label + "：rec 缺少 " + field)

	var deposits: Array = []
	R.run_deposit(rearranged, lv, deposits)
	var unlocked: Array = R._unlock_pass(rearranged) if not deposits.is_empty() else []
	var revealed: Array = R._reveal_tails(rearranged)
	_check(result == rearranged, label + "：最终状态应等于正式结算状态")
	_check(rec["deposits"] == deposits and rec["unlocked"] == unlocked\
	and rec["revealed"] == revealed\
	and rec["hidden_spawns"] == R._hidden_spawns(deposits), label + "：所有结算记录应一致")

	var expected: Array[int] = R.type_counts(st, lv.types)
	var actual: Array[int] = R.type_counts(result, lv.types)
	for dep: Dictionary in deposits:
		actual[int(dep["fruit"])] += int(dep["q"])
		for spawn: Dictionary in dep["spawns"] as Array:
			for type_id: int in spawn["types"] as Array[int]:
				expected[JuiceLevel.true_type(type_id)] += 1
	_check(actual == expected, label + "：花朵颜色与数量应守恒")
	return got



func _reconstruct(st: Dictionary, mapping: Dictionary, label: String, target_ci: int) -> Dictionary:
	var reconstructed: Dictionary = R.clone_state(st.duplicate())
	if st.has("reveal_memory"):
		reconstructed["reveal_memory"] = (st["reveal_memory"] as Dictionary).duplicate(true)
	var original: Array = st["cols"]
	var cols: Array = reconstructed["cols"]
	var seen: Dictionary = {}
	var total: int = 0
	var active: int = 0
	for ci: int in original.size():
		var is_active: bool = not (st["gone"] as Array[bool])[ci] and (st["caps"] as Array[int])[ci] > 0
		if not is_active:
			_check( not mapping.has(ci), label + "：退出列不应参加 mapping")
			continue
		active += 1
		total += (original[ci] as Array).size()
		_check(mapping.has(ci), label + "：每个在场列必须包含完整 mapping")
		if not mapping.has(ci):
			continue
		var remapped: Array[int] = []
		var addresses: Array = mapping[ci]
		for origin: Dictionary in addresses:
			var source_ci: int = int(origin.get("col", -1))
			var index: int = int(origin.get("index", -1))
			var valid: bool = source_ci >= 0 and source_ci < original.size()
			valid = valid and index >= 0 and index < (original[source_ci] as Array).size()
			_check(valid, label + "：原花位置必须有效")
			if not valid:
				continue
			var key: String = "%d:%d" % [source_ci, index]
			_check( not seen.has(key), label + "：同一原花不得重复分配")
			seen[key] = true
			remapped.append(int((original[source_ci] as Array)[index]))
			if JuiceLevel.is_hidden(remapped.back()):
				_check(source_ci == ci or source_ci == target_ci, 
					label + "：未显色花只能留在原列，或作为目标列杂色搬走")
		_check(remapped.size() <= (st["caps"] as Array[int])[ci], label + "：任何列不可超容量")
		if R.is_locked(reconstructed, ci):
			_check(remapped == original[ci], label + "：锁列原花与顺序不得变动")
		cols[ci] = remapped
	_check(mapping.size() == active and seen.size() == total, label + "：mapping 必须不重不漏覆盖原花")
	_check(R.type_counts(reconstructed, 16) == R.type_counts(st, 16), label + "：结算前重排应严格守恒")
	return reconstructed



func _reject(st: Dictionary, lv: JuiceLevel, ci: int, label: String) -> void :
	var before: Dictionary = st.duplicate(true)
	_check(_build_and_finalize(st, lv, ci).is_empty(), label + "：必须失败")
	_check(st == before, label + "：失败不得修改任何输入字段")



func _test_basic_and_mapping() -> void :
	var lv: JuiceLevel = _level(["-|2", "0|0,1", "1|0,1,0", "2|2,1"])
	var st: Dictionary = R.make_state(lv)
	st["reveal_memory"] = {"4:1": true}
	var got: Dictionary = _complete(st, lv, 1, "基本调配")
	if got.is_empty():
		return
	_check((got["mapping"] as Dictionary)[1] == [
		{"col": 1, "index": 0}, {"col": 2, "index": 0}, {"col": 2, "index": 2}, 
	], "目标应保留原同色并按原索引抽取来源明牌")
	_check((got["rec"]["deposits"] as Array).size() == 1, "基本调配应收一盆")
	(got["state"]["reveal_memory"] as Dictionary)["new"] = true
	_check( not (st["reveal_memory"] as Dictionary).has("new"), "返回状态的记忆应独立深拷贝")



func _test_not_enough() -> void :
	var lv: JuiceLevel = _level(["-|", "0|0,1", "1|1,0"], 3, ["2|0,0,0"])
	_reject(R.make_state(lv), lv, 1, "在场同色不足，即使未来足量")



func _test_invalid_target() -> void :
	var lv: JuiceLevel = _level(["-|0,0", "0|0,1", "1|1"])
	var st: Dictionary = R.make_state(lv)
	_reject(st, lv, -1, "负列号")
	_reject(st, lv, 3, "越界列号")
	_reject(st, lv, 0, "白盆")
	_reject({}, lv, 0, "空状态")
	_reject(st, null, 1, "无题面")
	var probe: Dictionary = st.duplicate(true)
	(probe["gone"] as Array[bool])[1] = true
	_reject(probe, lv, 1, "退出盆")
	probe = st.duplicate(true)
	(probe["caps"] as Array[int])[1] = 0
	_reject(probe, lv, 1, "零容量")
	(probe["caps"] as Array[int])[1] = 2
	_reject(probe, lv, 1, "容量与题面不符")
	probe = st.duplicate(true)
	(probe["cols"] as Array)[1] = [0, 1, 1, 0] as Array[int]
	_reject(probe, lv, 1, "目标已超容量")
	probe = st.duplicate(true)
	(probe["locks"] as Array)[1] = {"condition": "collect_count", "count": 1}
	_reject(probe, lv, 1, "目标锁列")
	probe = st.duplicate(true)

	probe = st.duplicate(true)
	(probe["cols"] as Array)[1] = [JuiceLevel.hide_type(1), 0] as Array[int]
	var hidden_got: Dictionary = _complete(probe, lv, 1, "目标杂色问号花搬走")
	if not hidden_got.is_empty():
		_check((hidden_got["rec"]["revealed"] as Array).size() == 1, 
			"搬走的问号花应在串尾显色")
		_check(int((hidden_got["rec"]["revealed"] as Array)[0]["type"]) == 1, 
			"串尾显色应写回问号真色")
	probe = st.duplicate(true)
	(probe["cols"] as Array)[1] = [JuiceLevel.hide_type(0), 0] as Array[int]
	hidden_got = _complete(probe, lv, 1, "目标同真色问号花搬走")
	if not hidden_got.is_empty():
		_check((hidden_got["rec"]["revealed"] as Array).size() == 1, 
			"同真色问号花也不计入数量，搬走后同样显色")



func _test_locked_columns() -> void :
	var lv: JuiceLevel = _level(["-|", "0|0,1", "1|0,0", "2|2,0,0"])
	var st: Dictionary = R.make_state(lv)
	(st["locks"] as Array)[2] = {"condition": "collect_count", "count": 7}
	var got: Dictionary = _complete(st, lv, 1, "跳过锁列来源")
	if not got.is_empty():
		_check(got["mapping"][2] == [{"col": 2, "index": 0}, {"col": 2, "index": 1}], 
			"锁列 mapping 应保留原花")
		_check(got["mapping"][1] == [
			{"col": 1, "index": 0}, {"col": 3, "index": 1}, {"col": 3, "index": 2}, 
		], "目标只能从未锁列拿花")
	(st["locks"] as Array)[3] = {"condition": "collect_count", "count": 7}
	_reject(st, lv, 1, "锁列里同色足量也不参与")



func _test_hidden_flowers() -> void :
	var lv: JuiceLevel = _level(["-|", "0|0", "1|?1,0,0", "2|2"])
	var st: Dictionary = R.make_state(lv)
	var got: Dictionary = _complete(st, lv, 1, "来源串尾自然显色")
	if not got.is_empty():
		_check(got["mapping"][2] == [{"col": 2, "index": 0}], "问号花应留在来源原列")
		_check(got["state"]["cols"][2] == [1], "抽走所有尾部明牌后问号应显色")
		_check(got["rec"]["revealed"] == [
			{"col": 2, "index": 0, "before": JuiceLevel.hide_type(1), "type": 1}, 
		], "正式显色记录应包含原问号值")
	lv = _level(["-|", "0|0", "1|?0,0", "2|2"])
	_reject(R.make_state(lv), lv, 1, "来源问号同真色不得计入足量")
	lv = _level(["-|", "0|0", "1|0,?1,0,2"], 4)
	st = R.make_state(lv)
	(st["cols"] as Array)[1] = [0, 0] as Array[int]
	got = _complete(st, lv, 1, "来源中部问号保留")
	if not got.is_empty():
		_check(got["state"]["cols"][2] == [JuiceLevel.hide_type(1), 2], 
			"抽走问号两侧明牌仍不应搬走或提前揭开中部问号")





func _test_full_board_exchange() -> void :
	var lv: JuiceLevel = _level(["0|1,0,1", "1|0,1,0"])
	var st: Dictionary = R.make_state(lv)
	_check(int(R.board_stats(st)["free"]) == 0, "满盘交换用例必须没有原空位")
	var got: Dictionary = _complete(st, lv, 0, "满盘交换")
	if not got.is_empty():
		_check(got["mapping"][1] == [
			{"col": 1, "index": 1}, {"col": 0, "index": 0}, {"col": 0, "index": 2}, 
		], "抽同色腾出的空位应容纳目标的两朵杂色")
		_check((got["rec"]["deposits"] as Array).size() == 2, "交换后两盆凑满应都正式收走")



func _test_surplus_same_color() -> void :
	var lv: JuiceLevel = _level(["-|0,0", "0|0,0", "1|0,0,1"])
	var got: Dictionary = _complete(R.make_state(lv), lv, 1, "多余同色不动")
	if not got.is_empty():
		_check(got["mapping"][0] == [{"col": 0, "index": 1}], "最低列号只取一朵恰足所需")
		_check(got["mapping"][2] == [
			{"col": 2, "index": 0}, {"col": 2, "index": 1}, {"col": 2, "index": 2}, 
		], "后续列多余同色不得移动")
	lv = _level(["-|1", "0|0,0,0", "1|1"])
	got = _complete(R.make_state(lv), lv, 1, "目标已经满同色")
	if not got.is_empty():
		_check((got["rec"]["deposits"] as Array).size() == 1, "已满目标也应直接走正式收盆")
	lv = _level(["-|0,0,0", "0|", "1|1"])
	_complete(R.make_state(lv), lv, 1, "空彩盆也可凑满")



func _test_cascade_and_memory() -> void :
	var lv: JuiceLevel = _level(["-|0", "0|0,0", "2|2"], 3, ["1|?1,1,1", "2|?2,2"])
	var st: Dictionary = R.make_state(lv)
	st["reveal_memory"] = {"0:0": true}
	var got: Dictionary = _complete(st, lv, 1, "记忆推动补货级联")
	if got.is_empty():
		return
	var deposits: Array = got["rec"]["deposits"]
	_check(deposits.size() == 2, "已见问号补货应直接明牌，从而连续收两盆")
	_check(got["state"]["done"] == 2 and got["state"]["cups"] == [0, 1], "级联杯序应正式维护")
	_check(got["state"]["cols"][1] == [JuiceLevel.hide_type(2), 2], "未见问号补货应继续隐藏")
	_check(got["rec"]["hidden_spawns"] == [{"col": 1, "index": 0, "key": "1:0"}], 
		"hidden_spawns 仅记录未见的补货问号，不重复记录记忆中明牌")
	_check(got["mapping"][1] == [
		{"col": 1, "index": 0}, {"col": 1, "index": 1}, {"col": 0, "index": 0}, 
	], "级联 mapping 必须仍指向最初的原花，不含补货花")



func _test_unlock_after_deposit() -> void :
	var lv: JuiceLevel = _level(["-|0", "0|0,0", "1|1,1,1"])
	var st: Dictionary = R.make_state(lv)
	(st["locks"] as Array)[2] = {"condition": "collect_count", "count": 1}
	var got: Dictionary = _complete(st, lv, 1, "收盆后解锁")
	if not got.is_empty():
		_check(got["state"]["done"] == 1 and R.deposit_ready(got["state"], 2) == 3, 
			"刚解锁的满列保留到下一步收盆")
		_check((got["rec"]["unlocked"] as Array).size() == 1, "应返回解锁记录")
	lv = _level(["-|0", "0|0,0", "1|1,1,1"])
	st = R.make_state(lv)
	(st["locks"] as Array)[2] = {"condition": "collect_type", "typeId": 0, "count": 1}
	got = _complete(st, lv, 1, "按颜色收盆解锁")
	if not got.is_empty():
		_check( not R.is_locked(got["state"], 2), "收足指定颜色后应正式解锁")



func _test_missing_locks_and_extra_rope() -> void :
	var lv: JuiceLevel = _level(["-|", "0|0,0", "1|1"])
	var st: Dictionary = R.make_state(lv)
	st.erase("locks")
	_reject(st, lv, 1, "缺锁字段且不足量")
	(st["cols"] as Array)[0] = [0] as Array[int]
	_complete(st, lv, 1, "缺锁字段也不修改输入")
	st = R.make_state(lv)
	var extra_ci: int = R.add_rope(st, lv.capacity)
	_check(extra_ci == 3, "应增加末尾额外绳")
	(st["cols"] as Array)[extra_ci] = [0] as Array[int]
	(st["caps"] as Array[int])[0] = 0
	(st["gone"] as Array[bool])[0] = true
	var got: Dictionary = _complete(st, lv, 1, "额外绳参与且退出列跳过")
	if not got.is_empty():
		_check(bool(got["state"]["extra_rope_used"]), "返回状态应保留已使用额外绳")
		_check( not (got["mapping"] as Dictionary).has(0) and (got["mapping"] as Dictionary).has(extra_ci), 
			"mapping 应包括额外绳而排除退出列")



func _test_random_distribution() -> void :
	var lv: JuiceLevel = _level(["-|", "0|0,1,2", "1|0,0", "2|2"])
	var st: Dictionary = R.make_state(lv)
	seed(2026)
	var first: Dictionary = _complete(st, lv, 1, "固定随机种子")
	seed(2026)
	var again: Dictionary = _build_and_finalize(st, lv, 1)
	_check(first == again, "同一 seed 应重现完全相同的重排与结算")
	var variants: Dictionary = {}
	for value: int in 12:
		seed(value)
		var got: Dictionary = _complete(st, lv, 1, "随机分配 %d" % value)
		if not got.is_empty():
			variants[str(got["mapping"])] = true
	_check(variants.size() > 1, "不同 seed 应允许目标杂色进入不同未锁空位")



func _test_checked_skips_dead_column() -> void :
	var lv: JuiceLevel = _level(["1|1", "0|0,1", "2|1,2", "0|0,3"], 2, ["1|1"], 2)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1, 2, 3])
	_check( not got.is_empty(), "首选列致死后应找到其它方案")
	if got.is_empty():
		return
	_check(int(got["target"]) != 0, "不应选择消除后卡死的首列")
	_check( not bool(got["fallback"]), "存在安全列时不得回退到最低风险方案")



func _test_checked_reveal_fallback() -> void :
	var lv: JuiceLevel = _level(["1|?1,1", "0|0"], 2, ["0|0,0"], 2)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1])
	_check( not got.is_empty(), "常规列全死时应走揭问号兜底")
	if got.is_empty():
		return
	_check(int(got["target"]) == 0 and not bool(got["fallback"]), 
		"应选中揭问号的目标列且不标记回退")
	var reveals: Array = got["rec"]["revealed"]
	_check(reveals.size() == 1 and int(reveals[0]["col"]) == 0
		and int(reveals[0]["type"]) == 1, "应记录目标列问号揭开")




func _test_checked_reveal_from_other_column() -> void :
	var lv: JuiceLevel = _level(["0|", "1|0,0", "1|?0,?0,2"], 3, ["2|2,2,3"], 2)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1, 2])
	_check( not got.is_empty(), "问号在其它列时应跨列揭问号凑满")
	if got.is_empty():
		return
	_check(int(got["target"]) == 0 and not bool(got["fallback"]), "应选中空彩盆且不标记回退")
	var reveals: Array = got["rec"]["revealed"]
	_check(reveals.size() == 1 and int(reveals[0]["col"]) == 0
		and int(reveals[0]["index"]) == 2 and int(reveals[0]["type"]) == 0, 
		"只揭缺口所需的其它列问号，并记录在目标列重排后的位置")
	var mapping: Dictionary = got["mapping"]
	_check(mapping[0] == [
		{"col": 1, "index": 0}, {"col": 1, "index": 1}, {"col": 2, "index": 0}, 
	], "目标列 mapping 应含被搬入的问号")
	_check(mapping[2] == [{"col": 2, "index": 1}, {"col": 2, "index": 2}], 
		"未参与凑满的问号与明牌仍留在原列")
	_check((got["state"]["cols"] as Array)[2] == [JuiceLevel.hide_type(0), 2], 
		"未参与凑满的问号必须保持问号")



func _test_checked_reveal_prefers_target_column() -> void :
	var lv: JuiceLevel = _level(["0|?0", "1|0,0", "1|?0,2"], 3, ["2|2,2,3"], 2)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1, 2])
	_check( not got.is_empty(), "目标列内问号应可凑满")
	if got.is_empty():
		return
	_check(int(got["target"]) == 0 and not bool(got["fallback"]), "应选中目标列")
	var reveals: Array = got["rec"]["revealed"]
	_check(reveals.size() == 1 and int(reveals[0]["col"]) == 0
		and int(reveals[0]["index"]) == 0, "只揭目标列内那一朵问号")
	_check((got["state"]["cols"] as Array)[2] == [JuiceLevel.hide_type(0), 2], 
		"其它列问号不得被搬动或揭开")



func _test_checked_reveal_skips_locked_column() -> void :
	var lv: JuiceLevel = _level(["0|", "1|0", "1|?0"], 2, [], 8)
	var st: Dictionary = R.make_state(lv)
	(st["locks"] as Array)[2] = {"condition": "collect_count", "count": 7}
	var got: Dictionary = S.complete_column_checked(st, lv, [0, 1, 2])
	_check(got.is_empty(), "锁列里的问号不得被抽取")



func _test_checked_reveal_insufficient() -> void :
	var lv: JuiceLevel = _level(["0|0,?0", "1|1,?1", "2|2"], 3, [], 8)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1, 2])
	_check(got.is_empty(), "问号真色也不足时不得强行消除")



func _test_checked_all_dead_fallback() -> void :
	var lv: JuiceLevel = _level(["1|1", "0|0,1", "2|2"], 2, ["1|1"], 2)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1, 2])
	_check( not got.is_empty(), "全部致死时仍应返回最低风险方案")
	if got.is_empty():
		return
	_check(bool(got["fallback"]), "全部致死应标记 fallback")
	_check(String(got.get("dead_reason", "")) != "", "应记录死因")



func _test_checked_timing_fields() -> void :
	var lv: JuiceLevel = _level(["1|1", "0|0,1", "2|1,2", "0|0,3"], 2, ["1|1"], 2)
	var got: Dictionary = S.complete_column_checked(R.make_state(lv), lv, [0, 1, 2, 3])
	_check( not got.is_empty(), "计时用例需要一次成功调配")
	if got.is_empty():
		return
	var timing: Dictionary = got.get("timing", {})
	for field: String in ["build_us", "finalize_us", "check_us", "total_us", 
			"tried_cols", "placements", "closed_checks", "budget_hit"]:
		_check(timing.has(field), "timing 缺少 " + field)
	_check(int(timing.get("total_us", -1)) >= 0, "总耗时不得为负")
	_check(int(timing.get("placements", 0)) >= 2, "应逐候选尝试杂色落位")



func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)



func _finish() -> void :
	if _failures.is_empty():
		SortLogger.info("COMPLETE_COLUMN_CORE_SELFTEST PASS")
		quit(0)
		return
	for failure: String in _failures:
		SortLogger.error("COMPLETE_COLUMN_CORE_SELFTEST FAIL: " + failure)
	quit(1)
