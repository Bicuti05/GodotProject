extends SceneTree

const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const PARSER = preload("res://scripts/gameplay/juice_sort/core/juice_level_parser.gd")
var failures: Array[String] = []

func _initialize() -> void :
	var win: JuiceLevel = winning_level()
	var dead: JuiceLevel = losing_level()
	var live_state: Dictionary = R.make_state(win)
	var dead_state: Dictionary = R.make_state(dead)
	check(R.has_any_move(dead_state) and not R.is_doomed(dead_state, dead), 
		"必死样例仍有合法移动且花账足够，必须实际搜索")
	check(S.full_reachability(live_state, win) == S.Reachability.WINNABLE, "存在通关路线")
	check(S.full_reachability(dead_state, dead) == S.Reachability.UNWINNABLE, "证明有移动但无胜路")
	check(S.full_reachability({}, dead) == S.Reachability.UNKNOWN, "未摆盘不判死")
	var search: Dictionary = S.begin_full_search(live_state, win)
	check(S.advance_full_search(search, win, {"node_cap": 0}) == S.Reachability.UNKNOWN, 
		"节点预算耗尽是未知")
	check(search["stop_reason"] == "node_cap", "准确记录节点预算退出")
	search = S.begin_full_search(dead_state, dead)
	check(S.advance_full_search(search, dead, {"state_cap": 1}) == S.Reachability.UNKNOWN, 
		"状态上限不能误判无解")
	check(search["stop_reason"] == "state_cap", "准确记录状态预算退出")
	var expanded: int = int(search["expanded"])
	check(S.advance_full_search(search, dead, {"state_cap": 128, "node_cap": 128})
		== S.Reachability.UNWINNABLE, "提高上限后不漏掉暂停的候选")
	check(int(search["expanded"]) >= expanded, "会话继续累计，未从头重算")
	check(search["stop_reason"] == "resolved", "续查得到结论后清除旧预算退出原因")
	search = S.begin_full_search(dead_state, dead)
	var value: int = S.Reachability.UNKNOWN
	for cap: int in range(1, 129):
		value = S.advance_full_search(search, dead, {"node_cap": cap, "state_cap": 128})
		if value != S.Reachability.UNKNOWN:
			break
	check(value == S.Reachability.UNWINNABLE, "逐节点续查与一次穷尽一致")
	search = S.begin_full_search(live_state, win)
	var ticks: Array[int] = [0]
	var clock: Callable = func() -> int:
		ticks[0] += 1
		return ticks[0]
	check(S.advance_full_search(search, win, {"now": clock, "ms_cap": 1})
		== S.Reachability.UNKNOWN, "墙钟预算耗尽保留会话")
	check(search["stop_reason"] == "deadline", "准确记录墙钟预算退出")
	check(S.advance_full_search(search, win) == S.Reachability.WINNABLE, "墙钟暂停后可续查")

	var hint_path: Array = S.hint_win_path(live_state, win)
	check( not hint_path.is_empty(), "提示式搜索在可解盘面找到路线")
	check(replay_wins(live_state, win, hint_path), "提示式路线按真实规则重放必通关")
	check(S.hint_win_path(dead_state, dead).is_empty(), "必死盘面提示式搜索不应找到路线")
	check(S.hint_win_path(live_state, win, {"max_routes": 0}).is_empty(), "路线预算为 0 时不搜")
	check(S._safe_candidate_has_exit(live_state, win, {}), "回溯候选：尾局确认通关出路")
	check( not S._safe_candidate_has_exit(dead_state, dead, {}), "回溯候选：无收盆出路的盘面不确认")
	_test_one_pot_dead_attribution()
	_test_one_pot_state_dedup()
	_test_safe_return_three_pot_budget()
	_test_checked_hint()
	_test_checked_hint_fallback()
	_test_checked_hint_short_route()
	_test_merge_hint_moves()
	_test_hint_three_pot_budget()
	_test_hint_immediate_death()
	_test_android_hint_death()
	_test_hint_delivery()
	var sweep: Dictionary = pool_sweep()
	check(int(sweep["total"]) > 0, "兜底池读取到题面")
	check(int(sweep["bad_replay"]) == 0, "兜底池：提示式路线重放必须通关")
	check(int(sweep["contradiction"]) == 0, "兜底池：提示式找到路线的盘面，完整搜索不能判无解")
	print("hint_win 兜底池扫描: ", sweep)
	_test_hint_pool_budget()
	print("JUICE_REACHABILITY_SELFTEST ", "PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)


func _test_hint_pool_budget() -> void :
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PARSER.FALLBACK_PATH)) as Dictionary
	var opts: Dictionary = (load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript).get_script_constant_map()["HINT_OPT"].duplicate()

	var summary: Dictionary = {"total": 0, "found": 0, "max_ms": 0, "unsafe": 0, "bad_path": 0}
	for row: Dictionary in doc["levels"]:
		var lv: JuiceLevel = JuiceLevel.from_dict(row)
		var st: Dictionary = R.make_state(lv)
		var result: Dictionary = {}
		S.run_checked_hint_task(st, lv, opts, result)
		summary["total"] += 1
		summary["max_ms"] = maxi(int(summary["max_ms"]), int(result["elapsed_ms"]))
		var hint: Dictionary = result["hint"]
		if hint.is_empty():
			continue
		summary["found"] += 1
		var next: Dictionary = R.clone_state(st)
		for mv: Dictionary in hint["path"]:
			if R.apply_move(next, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
				summary["bad_path"] += 1
				break
			if not R.is_win(next, lv) and ( not R.has_any_move(next) or S.is_closed_cycle(next, lv)):
				summary["unsafe"] += 1
				break
		check(int(next["done"]) > int(st["done"]), "兜底池Hint至少真实收一盆")
		if int(result["reachability"]) == S.Reachability.WINNABLE:
			check(int(next["done"]) >= mini(lv.groups_total, int(st["done"]) + 3), "兜底池接受路线达到后三盆目标")
	print("checked_hint 兜底池扫描: ", summary)

	check(int(summary["found"]) == int(summary["total"]), "兜底池所有可解初始盘面均有安全提示")
	check(int(summary["found"]) > 0 and int(summary["unsafe"]) == 0 and int(summary["bad_path"]) == 0, 
		"兜底池Hint真实路线合法且每一步都不会立即死亡")


static func replay_wins(st: Dictionary, level: JuiceLevel, path: Array) -> bool:
	var x: Dictionary = R.clone_state(st)
	for mv: Dictionary in path:
		if R.apply_move(x, level, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
			return false
	return R.is_win(x, level)




static func pool_sweep() -> Dictionary:
	var out: Dictionary = {"total": 0, "found": 0, "bad_replay": 0, "contradiction": 0}
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(PARSER.FALLBACK_PATH))
	if not (doc is Dictionary):
		return out
	for row_raw: Variant in (doc as Dictionary).get("levels", []) as Array:
		var row: Dictionary = (row_raw as Dictionary).duplicate(true)
		row["id"] = 77
		var lv: JuiceLevel = JuiceLevel.from_dict(row)
		if not lv.validate().is_empty():
			continue
		out["total"] = int(out["total"]) + 1
		var st: Dictionary = R.make_state(lv)
		var path: Array = S.hint_win_path(st, lv, {"max_routes": 40})
		if path.is_empty():
			continue
		out["found"] = int(out["found"]) + 1
		if not replay_wins(st, lv, path):
			out["bad_replay"] = int(out["bad_replay"]) + 1
		if S.full_reachability(st, lv, {"node_cap": 1500, "state_cap": 4000}) == S.Reachability.UNWINNABLE:
			out["contradiction"] = int(out["contradiction"]) + 1
	return out

static func winning_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 99001, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "-|0", "1|1,1"], "incoming": ["x"]})

static func losing_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 99002, "capacity": 3, "targetCups": 3, 
		"initial": ["0|2,1", "1|0,0", "2|1,1"], "incoming": ["0|0,2,2", "x"]})


func _test_one_pot_dead_attribution() -> void :
	var opts: Dictionary = {"now": func() -> int: return 1, "ms_cap": 120, "node_cap": 3000}
	var local: JuiceLevel = JuiceLevel.from_dict({"capacity": 2, "targetCups": 5, 
		"initial": ["0|0", "1|1", "2|2", {"column": "3|4", "columnType": JuiceLevel.LOCK_TYPE, 
			"columnInfo": {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 4}}, "-|0,1", "-|2,3"], 
		"incoming": ["4|3,4", "x", "x", "x"]})
	check(local.validate().is_empty(), "一盆归因样例是合法题面")
	var doomed: JuiceLevel = JuiceLevel.from_dict({"capacity": 2, "targetCups": 3, 
		"initial": ["0|0", "1|1", "2|2", "-|0,1"], "incoming": ["x"]})
	check(R.is_doomed(R.make_state(doomed), doomed), "缺花样例整关花账不足")
	var question: JuiceLevel = JuiceLevel.from_dict({"capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "1|1", "-|?0,1"], "incoming": ["x"]})
	check(question.validate().is_empty(), "问号归因样例的串尾为明牌，移动后才能揭色")
	for lv: JuiceLevel in [winning_level(), local, doomed, question]:
		var st: Dictionary = R.make_state(lv)
		var before: String = S._full_state_key(st)
		check(S.classify_dead_previous(st, lv, opts) == S.DeathAttribution.LAST_MOVE, 
			"存在安全一盆即确认一步可救活，包括整关无解、缺花与问号机制: %s" % lv.to_dict())
		check(S._full_state_key(st) == before, "一盆DFS不修改待撤回盘面或隐藏状态")
	var limited: Dictionary = opts.duplicate()
	limited["node_cap"] = 0
	check(S.classify_dead_previous(R.make_state(local), local, limited) == S.DeathAttribution.UNKNOWN, 
		"节点预算为零保持未知，不兜底整关搜索")
	var result: Dictionary = {}
	var elapsed: Array[int] = [1]
	var safety_clock: Callable = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "_hint_safe_after":
				elapsed[0] = 121
		return elapsed[0]
	S.run_death_attribution_task(R.make_state(winning_level()), winning_level(), 
		{"now": safety_clock, "ms_cap": 120}, result)
	check(result["attribution"] == S.DeathAttribution.UNKNOWN and bool(result["completed"]), 
		"找到收盆路线但安全检查超时不能判活")
	check(result.get("diagnostic", {}).get("phase") == "one_pot_dfs"
			and result.get("diagnostic", {}).get("reason") == "deadline", 
		"一盆DFS超时诊断记录实际阶段")
	result.clear()
	S.run_death_attribution_task(R.make_state(local), local, 
		{"now": opts["now"], "ms_cap": 0}, result)
	check(result["attribution"] == S.DeathAttribution.UNKNOWN, "时间预算为零保持未知")
	check(S.classify_dead_previous({}, local, opts) == S.DeathAttribution.UNKNOWN, 
		"空盘面不能误判死亡")
	var summary: Dictionary = {"total": 0, "found": 0, "unknown": 0, "earlier": 0, "max_ms": 0}
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PARSER.FALLBACK_PATH))
	for row: Dictionary in doc["levels"]:
		var lv: JuiceLevel = JuiceLevel.from_dict(row)
		var started: int = Time.get_ticks_msec()
		var value: int = S.classify_dead_previous(R.make_state(lv), lv, 
			{"now": Time.get_ticks_msec, "ms_cap": 120, "node_cap": 3000})
		summary["total"] += 1
		summary["max_ms"] = maxi(int(summary["max_ms"]), Time.get_ticks_msec() - started)
		match value:
			S.DeathAttribution.LAST_MOVE: summary["found"] += 1
			S.DeathAttribution.UNKNOWN: summary["unknown"] += 1
			S.DeathAttribution.EARLIER: summary["earlier"] += 1
	check(int(summary["found"]) > 0 and int(summary["earlier"]) == 0, 
		"可解题库的安全一盆不能被误判为无出路")
	SortLogger.info("one_pot_death 题库检查: %s" % summary)



func _test_one_pot_state_dedup() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 74, "capacity": 5, "targetCups": 12, 
		"initial": ["-|", "2|2,6,?2,0,6", "8|7,0,7,2", "7|8,?6,7", "6|?8,?8,8,0,2", "0|6,?7,0,2"], 
		"incoming": ["3|7,0,1,3,6", "1|3,?1,2,8,3", "5|3,4,?1,3,0", "2|?4,5,1,?2,5", 
			"4|2,5,1,?4,5", "0|2,2,4,1,5", "1|?1,0,?1,0,4", "-|0,1,1,0"]})
	check(lv.validate().is_empty(), "74关现场题面合法")
	var st: Dictionary = R.make_state(lv)
	var cols: Array = [[1, 1, 1, 2, 2], [3, 3, 3, 3, 0], [2], [4, 1, 1, 4], [1004, 5, 5, 5, 5], [3]]
	for ci: int in cols.size():
		(st["cols"][ci] as Array[int]).assign(cols[ci])
	(st["jars"] as Array[int]).assign([-1, 3, 4, 1, 2, 5])
	(st["cups"] as Array[int]).assign([2, 7, 0, 6, 8])
	st["done"] = 5
	st["late_left"] = 1
	var original: String = S._full_state_key(st)
	var opts: Dictionary = {"now": func() -> int: return 1, "node_cap": 36, "state_cap": 36}
	var search: Dictionary = S.begin_full_search(st, lv, true)
	check(S.advance_full_search(search, lv, opts) == S.Reachability.UNWINNABLE, 
		"一盆搜索用36节点预算穷尽现场，不重复展开其他路径上的相同盘面")
	check(int(search["expanded"]) == 36 and (search["seen"] as Dictionary).size() == 36, 
		"现场36个盘面各展开一次，问号原始编码参与去重")
	check(S.classify_dead_previous(st, lv, opts) == S.DeathAttribution.EARLIER, 
		"74关撤回一步不能收盆，确认EARLIER而非UNKNOWN")
	search = S.begin_full_search(st, lv, true)
	check(S.advance_full_search(search, lv, {"node_cap": 35}) == S.Reachability.UNKNOWN, 
		"一盆搜索差一个节点也不能当作无解证明")
	check(S.advance_full_search(search, lv, opts) == S.Reachability.UNWINNABLE
		and int(search["expanded"]) == 36, "一盆搜索提高预算后继续原会话，不重算已展开盘面")
	check(S.full_reachability(st, lv, opts) == S.Reachability.UNWINNABLE, 
		"原完整死亡搜索在同一现场仍确认无解")
	check( not S.is_closed_cycle(st, lv), "撤回一步后仍有单向移动，普通死亡规则按原口径放行")
	var dead: Dictionary = R.clone_state(st)
	R.apply_move(dead, lv, 0, 3, 2)
	check(R.has_any_move(dead) and S.is_closed_cycle(dead, lv), 
		"74关最后一步后虽有搬动，但普通死亡判定确认封闭循环")
	search = S.begin_full_search(dead, lv)
	check(S.advance_full_search(search, lv, opts) == S.Reachability.UNWINNABLE
		and (search["seen"] as Dictionary).size() == 24, "普通死亡现场24个可达盘面全部无解")
	check(S._full_state_key(st) == original, "所有搜索不修改现场盘面")

	(st["cols"][2] as Array[int]).append(5)
	(st["cols"][4] as Array[int]).pop_back()
	check(S.classify_dead_previous(st, lv, {"now": opts["now"]}) == S.DeathAttribution.LAST_MOVE, 
		"74关撤回两步后的盘面确认安全一盆，不因去重漏掉有效路线")


static func four_pot_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"capacity": 2, "targetCups": 4, 
		"initial": ["0|0", "1|1", "2|2", "3|3", "-|0,1", "-|2,3"], 
		"incoming": ["x", "x", "x"]})


func _test_safe_return_three_pot_budget() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"capacity": 2, "targetCups": 5, 
		"initial": ["0|0", "1|1", "2|2", {"column": "3|4", "columnType": JuiceLevel.LOCK_TYPE, 
			"columnInfo": {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 4}}, "-|0,1", "-|2,3"], 
		"incoming": ["4|3,4", "x", "x", "x"]})
	check(lv.validate().is_empty(), "三盆回溯样例题面合法：%s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)

	check( not R.is_doomed(st, lv), "样例不能靠花账直接判无解")
	check(S.hint_win_path(st, lv).is_empty(), "样例没有完整通关路线")
	var path: Array = S.hint_win_path(st, lv, {"goal_done": 3, "safe_hint": true})
	var after: Dictionary = S._replay(st, lv, path, true)
	check( not path.is_empty() and int(after.get("done", 0)) == 3 and not R.is_win(after, lv), 
		"回溯样例能真实收三盆且仍未通关")
	var opts: Dictionary = {"now": Time.get_ticks_msec, "ms_cap": 60, "node_cap": 0, "state_cap": 8000}
	var started: int = Time.get_ticks_msec()
	check(S._safe_candidate_has_exit(st, lv, opts), "60ms内接受三盆出路，不要求整关通关")
	check(Time.get_ticks_msec() - started <= 60, "三盆回溯候选保持60ms预算")
	if path.is_empty() or after.is_empty():
		return
	check( not S._safe_candidate_has_exit(after, lv, opts), "尾局不足三盆但无法通关时不接受")
	var tail: JuiceLevel = four_pot_level()
	var tail_state: Dictionary = R.make_state(tail)
	var tail_path: Array = S.hint_win_path(tail_state, tail, {"goal_done": 3, "safe_hint": true})
	var tail_after: Dictionary = S._replay(tail_state, tail, tail_path, true)
	check(int(tail_after["done"]) == 3 and S._safe_candidate_has_exit(tail_after, tail, opts), 
		"尾局不足三盆时确认剩余一盆通关")
	var two_pots: Dictionary = R.clone_state(st)
	var third_pot: int = (two_pots["jars"] as Array[int]).find(2)
	two_pots["locks"][third_pot] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 4}
	check( not S._safe_candidate_has_exit(two_pots, lv, opts), "只有一两盆局部出路时不能作为三盆回溯结果")
	var expired_opts: Dictionary = opts.duplicate()
	expired_opts["ms_cap"] = 0
	check( not S._safe_candidate_has_exit(st, lv, expired_opts), "预算耗尽不能接受未经验证的回溯候选")
	var moved: Dictionary = R.clone_state(st)
	var rec: Dictionary = R.apply_move(moved, lv, int(path[0]["src"]), int(path[0]["j"]), int(path[0]["dst"]))
	var result: Dictionary = {}
	S.run_safe_return_task(moved, [rec], lv, false, opts, result)
	check(bool(result.get("completed", false)) and int(result.get("steps", 0)) == 1, 
		"沿真实撤销记录回溯接受三盆出路")


func _test_hint_three_pot_budget() -> void :
	var lv: JuiceLevel = four_pot_level()
	check(lv.validate().is_empty(), "四盆截止样例合法")
	var st: Dictionary = R.make_state(lv)
	var opts: Dictionary = (load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript).get_script_constant_map()["HINT_OPT"].duplicate()
	check(int(opts["ms_cap"]) == 800 and int(opts["death_first_ms"]) == 50
		and int(opts["death_last_ms"]) == 70, "玩家Hint总预算800ms，死亡搜索前50ms后70ms")
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, opts, result)
	var hint: Dictionary = result["hint"]
	var next: Dictionary = S._replay(st, lv, hint.get("path", []), true)
	check(int(result["reachability"]) != S.Reachability.UNWINNABLE and int(next["done"]) == 3
		and not R.is_win(next, lv) and not bool(hint.get("win_path", false)), "后三盆即接受，实际关卡仍未通关")
	check(int(result["elapsed_ms"]) <= 800, "三盆及死亡搜索在800ms总预算内结束")
	_test_hint_plan(st, lv, hint)
	S.run_checked_hint_task(next, lv, opts, result)
	hint = result["hint"]
	check(bool(hint.get("win_path", false)) and replay_wins(next, lv, hint.get("path", [])), 
		"不足三盆时提示直到真实通关，目标相对当前盘面计算")

	check(replay_wins(st, lv, S.hint_win_path(st, lv)), "未注入三盆目标时仍求完整通关路线")
	opts["shorten_ms"] = 0
	S.run_checked_hint_task(st, lv, opts, result)
	check( not (result["hint"] as Dictionary).is_empty() and result["hint_source"] == "local", 
		"零优化预算仍保留一盆首解，不启动三盆")


func _test_hint_immediate_death() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"capacity": 2, "targetCups": 3, 
		"initial": ["0|0", "1|1,0", "2|2,1", "-|2"], "incoming": ["x", "x"]})
	check(lv.validate().is_empty(), "立即死亡样例题面合法")
	var st: Dictionary = R.make_state(lv)

	st["locks"][3] = {"condition": JuiceLevel.LOCK_COLLECT_COUNT, "count": 3}
	check( not R.apply_move(st, lv, 1, 1, 0).is_empty(), "先按真实规则收第一盆")
	var path: Array = [{"src": 2, "j": 1, "dst": 1}]
	var stuck: Dictionary = S._replay(st, lv, path, true)
	check(int(stuck["done"]) == 2 and not R.is_win(stuck, lv) and not R.has_any_move(stuck), 
		"样例确实一手收盆后立即无合法移动")
	check(S._checked_path_hint(st, lv, path).is_empty(), "拒绝收一盆后立即stuck的路线")
	check(S.classify_dead_previous(st, lv, {"now": func() -> int: return 1}) == S.DeathAttribution.EARLIER, 
		"一步归因拒绝唯一收盆后立即stuck的出路")
	var opts: Dictionary = {"ms_cap": 200, "max_routes": 0, "death_node_cap": 0}
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, opts, result)
	check((result["hint"] as Dictionary).is_empty() and int(result["reachability"]) == S.Reachability.UNKNOWN, 
		"局部兜底不会下发立即死亡的首步，未证明整关死亡仍为未知")

	var loop_start: Dictionary = R.clone_state(st)
	loop_start["locks"][3] = {}
	loop_start["jars"][2] = 0
	var loop_end: Dictionary = S._replay(loop_start, lv, path, true)
	check(R.has_any_move(loop_end) and S.is_closed_cycle(loop_end, lv), "样例收盆后有移动但已封闭循环")
	check(S._checked_path_hint(loop_start, lv, path).is_empty(), "局部路线也必须排除立即loop死亡")
	check(S.classify_dead_previous(loop_start, lv, {"now": func() -> int: return 1}) == S.DeathAttribution.EARLIER, 
		"一步归因拒绝收盆后立即loop的出路")
	var expired: Dictionary = {"deadline": 1, "now": func() -> int: return 2}
	check( not S._hint_safe_after(R.make_state(four_pot_level()), four_pot_level(), expired), 
		"安全验证超时不能当作已验证安全")
	check( not S.is_closed_cycle(loop_end, lv, expired) and bool(expired.get("aborted", false)), 
		"封闭循环检查遵守截止时间并明确标记未完成")

func check(ok: bool, message: String) -> void :
	if not ok:
		failures.append(message)
		push_error(message)


func _test_checked_hint() -> void :


	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 228, "capacity": 5, "targetCups": 12, 
		"initial": ["-|0,7,0,5", "5|5,1,7,8,5", "0|8,1,7,5", "1|8,0,5", "7|1,8,7,0", "8|1"], 
		"incoming": ["2|2,7,0,2,3", "0|0,2,1,2,0", "6|1,2,8,0,2", "3|6,1,4,3,6", 
			"1|6,3,0,1,3", "2|3,0,6,6,1", "4|4,4,1,2,2", "-|2,2,4,4", "x", "x", "x"]})
	check(lv.validate().is_empty() and lv.late_park == 1, "设备题面合法且后备空绳与现场一致")
	var st: Dictionary = R.make_state(lv)
	var cols: Array = [[3], [2, 2, 2, 0], [0, 2, 2], [8, 8, 8, 8], [1, 2, 8, 0], [1, 1, 1, 1, 1]]
	for i: int in cols.size():
		var col: Array[int] = []
		col.assign(cols[i])
		st["cols"][i] = col
	st["jars"] = [-1, 2, 0, 1, 6, 8] as Array[int]
	st["cups"] = [5, 0, 7] as Array[int]
	st["done"] = 3
	var hint_opts: Dictionary = (load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript).get_script_constant_map()["HINT_OPT"].duplicate()
	hint_opts["now"] = Time.get_ticks_msec
	var old_hint: Dictionary = S.hint_move(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 150})
	var losing: Dictionary = R.clone_state(st)
	R.apply_move(losing, lv, 1, 3, 4)
	check(S.full_reachability(losing, lv) == S.Reachability.UNWINNABLE, "现场第4→6列首步会走入死局")
	var result: Dictionary = {}

	hint_opts["cached_hint"] = old_hint
	S.run_checked_hint_task(st, lv, hint_opts, result)
	var hint: Dictionary = result["hint"]
	check(int(result["reachability"]) != S.Reachability.UNWINNABLE and not hint.is_empty(), "现场活局必须给安全提示")
	var next: Dictionary = R.clone_state(st)
	for mv: Dictionary in hint.get("path", []):
		check( not R.apply_move(next, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), "提示路线逐步合法")
		check(R.is_win(next, lv) or (R.has_any_move(next) and not S.is_closed_cycle(next, lv)), 
			"提示每一步不会触发立即死亡")
	check(int(next["done"]) > int(st["done"]), "提示路线至少消除一列")
	check(int(next["done"]) - int(st["done"]) >= 1, "Hint保底一盆，有余量才延长到三盆")
	_test_hint_plan(st, lv, hint)

	var cancel: Semaphore = Semaphore.new()
	cancel.post()
	var unknown_opts: Dictionary = hint_opts.duplicate()
	unknown_opts["cancel"] = cancel
	S.run_checked_hint_task(st, lv, unknown_opts, result)
	check(int(result["reachability"]) == S.Reachability.UNKNOWN and (result["hint"] as Dictionary).is_empty(), 
		"取消不误判死亡、不交付缓存猜测")

	var long_level: JuiceLevel = JuiceLevel.from_dict({"capacity": 8, "targetCups": 4, 
		"initial": ["-|2,1,2,0,2,3", "0|1,2,3", "1|0,0,0,1,3,0,3,0", "2|2,2,3,1,3,1,3", "3|1,1,2,0,2,0,1,3"], "incoming": []})
	hint_opts.erase("cached_hint")
	var long_state: Dictionary = R.make_state(long_level)
	S.run_checked_hint_task(long_state, long_level, hint_opts, result)
	hint = result["hint"]
	check( not hint.is_empty() and not bool(hint.get("guess", false)), "长绳关严格提示仍可用")
	next = R.clone_state(long_state)
	for mv: Dictionary in hint.get("path", []):
		check( not R.apply_move(next, long_level, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), "长绳严格路线逐步合法")
	check(int(next["done"]) > 0, "长绳严格提示至少收一盆")
	if bool(hint.get("win_path", false)):
		check(R.is_win(next, long_level), "长绳逐盆通关路线真实重放通关")
	else:
		check(int(result["reachability"]) != S.Reachability.UNWINNABLE, "长绳局部提示不能误判无解")


func _test_checked_hint_short_route() -> void :

	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 6, "capacity": 5, "targetCups": 10, 
		"initial": ["-|1,0,1,?3,4", "3|3,1,?0,3,0", "0|4,3,0,4", "1|4,4,0,2", "0|0,1,3,0", "4|"], 
		"incoming": ["2|6,?1,?2,0", "6|?0,2,6,6", "5|?6,0,5,2,5", "7|5,7,7,8,7", "8|5,8,7,?2,6", "-|?7,5,8,8,8", "x", "x", "x"]})
	check(lv.validate().is_empty(), "粉色短路线现场题面合法")
	var st: Dictionary = R.make_state(lv)
	var original: String = S._full_state_key(st)
	var opts: Dictionary = (load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript).get_script_constant_map()["HINT_OPT"].duplicate()
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, opts, result)
	var hint: Dictionary = result["hint"]
	var first: Dictionary = S._checked_path_hint(st, lv, hint.get("path", []))
	check( not first.is_empty() and int(first.get("col", -1)) == 5 and int(first.get("len", 999)) <= 6, 
		"先采用已验证安全的6步粉色路线，不交付19步紫色绕路")
	check(int(S._replay(st, lv, hint.get("path", []), true)["done"]) >= 1, 
		"短路线至少安全收一盆")
	check(S._full_state_key(st) == original, "验证短路线不改变玩家盘面")
	_test_hint_plan(st, lv, hint)
	var limited: Dictionary = opts.duplicate()
	limited["max_routes"] = 1
	S.run_checked_hint_task(st, lv, limited, result)
	hint = result["hint"]
	first = S._checked_path_hint(st, lv, hint.get("path", []))
	check(result["stop_reason"] == "resolved", "有限快搜预算不丢掉精确搜索已验证路线")
	check(int(result["reachability"]) != S.Reachability.UNWINNABLE and not bool(hint.get("win_path", false))
		and int(first.get("col", -1)) == 5 and int(first.get("len", 999)) <= 6, 
		"后续未验证完回退原盘面的局部路线，不交付后续盘面的候选、不判死")


func _test_checked_hint_fallback() -> void :
	var lv: JuiceLevel = winning_level()
	var st: Dictionary = R.make_state(lv)
	var opts: Dictionary = {"fast_ms": 0, "max_routes": 0, "shorten_ms": 0}
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, opts, result)
	var hint: Dictionary = result["hint"]
	check( not hint.is_empty() and (hint.get("path", []) as Array).size() == 1, 
		"快搜路线预算为零仍由精确DFS找到一步安全收盆")
	check(int(S._replay(st, lv, hint.get("path", []), true)["done"]) > 0, 
		"精确兜底确实收盆，不能用合法腾挪当Hint")
	var cancel: Semaphore = Semaphore.new()
	cancel.post()
	opts["cancel"] = cancel
	S.run_checked_hint_task(st, lv, opts, result)
	check(result["stop_reason"] == "cancelled" and (result["hint"] as Dictionary).is_empty()
		and int(result["reachability"]) != S.Reachability.UNWINNABLE, "取消不交付、不误判死局")


func _test_hint_delivery() -> void :



	var fixture: GDScript = GDScript.new()
	fixture.source_code = "extends \"res://scripts/main/pages/game/juice_game_page.gd\"\nvar effects: Array[String] = []\nvar accept_display: bool = true\nfunc _show_hint_on_board(_hint: Dictionary) -> bool:\n\teffects.append(\"show\")\n\treturn accept_display\nfunc _prop_tier_ok(_btn: PropBtn) -> bool:\n\treturn true\nfunc _charge_prop(_key: String, _btn: PropBtn) -> void:\n\teffects.append(\"charge\")\nfunc _after_prop_applied(_key: String, _was_dead: bool = false) -> void:\n\tpass\n"












	check(fixture.reload() == OK, "页面测试fixture编译通过")
	var lv: JuiceLevel = winning_level()
	var st: Dictionary = R.make_state(lv)
	var found: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"shorten_ms": 0}, found)
	for scenario: String in ["fallback", "cancelled", "stale", "display_rejected"]:
		var page: Node = fixture.new()
		var board: Node = (load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript).new()
		var btn: PropBtn = PropBtn.new()
		board._level = lv
		board._state = R.clone_state(st)
		page._board = board
		page._prop_ui = {"hint": {"btn": btn}}
		page._hint_task_key = page._hint_state_key()
		page._hint_task_cancel = Semaphore.new()
		page._hint_task_progress = S.HintProgress.new()
		page._hint_task_result = {"hint": {}, "completed": true, 
			"reachability": S.Reachability.UNKNOWN, "stop_reason": "cancelled" if scenario == "cancelled" else "resolved"}
		var mailbox: S.HintProgress = page._hint_task_progress
		var hint: Dictionary = found["hint"]
		page._hint_task_id = WorkerThreadPool.add_task( func() -> void :
			mailbox.publish(hint, "shorten", 1, 1))
		while not WorkerThreadPool.is_task_completed(page._hint_task_id):
			OS.delay_msec(1)
		if scenario == "stale":
			board._state["caps"][0] += 1
		if scenario == "display_rejected":
			page.accept_display = false
		page._hint_poll()
		var expected: Array = ["show", "charge"] if scenario == "fallback" else (["show"] if scenario == "display_rejected" else [])
		check(page.effects == expected, "保护快照、取消、完整指纹和显示成功后才扣账:%s" % scenario)
		check(page._hint_task_id == page.HINT_TASK_NONE and page._hint_task_progress == null, 
			"各出口释放任务及快照:%s" % scenario)
		board.free()
		btn.free()
		page.free()


func _test_hint_plan(st: Dictionary, lv: JuiceLevel, hint: Dictionary) -> void :
	var page: Node = (load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript).new()
	var board: Node = (load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript).new()
	board._level = lv
	board._state = R.clone_state(st)
	page._board = board
	var cached: Dictionary = page._cache_hint(page._hint_state_key(), hint)
	var deposits: int = 0
	for expected: Dictionary in hint["path"]:
		check( not cached.is_empty() and cached.get("move", {}) == expected, "连续Hint沿同一通关路线，无反向重算")
		var rec: Dictionary = R.apply_move(board._state, lv, int(expected["src"]), int(expected["j"]), int(expected["dst"]))
		check( not rec.is_empty(), "页面缓存路线每一步真实合法")
		deposits += (rec.get("deposits", []) as Array).size()
		if not R.is_win(board._state, lv):
			cached = page._hint_try_sync()
	check(deposits >= 1, "缓存路线至少收一盆，跨补货沿原计划继续")
	check(page._hint_plan.is_empty(), "已验证计划耗尽后不复用旧路线")

	board._state = R.clone_state(st)
	page._cache_hint(page._hint_state_key(), hint)
	var first: Dictionary = hint["path"][0]
	R.apply_move(board._state, lv, int(first["src"]), int(first["j"]), int(first["dst"]))
	board._state["caps"][0] += 1
	check(page._hint_try_sync().is_empty(), "容量改变使完整状态不匹配，拒绝旧计划")
	board.free()
	page.free()


func _test_merge_hint_moves() -> void :

	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 6, "capacity": 5, "targetCups": 10, "initial": ["-|1,0,1,3", "3|3,1,?0,3", "0|4,3,0,0,0", "1|4,4,0,2", "0|0,1,3", "4|4,4"], "incoming": ["2|6,?1,?2,0", "6|?0,2,6,6", "5|?6,0,5,2,5", "7|5,7,7,8,7", "8|5,8,7,?2,6", "-|?7,5,8,8,8", "x", "x", "x"]})
	var st: Dictionary = R.make_state(lv)
	var triples: Array = [[4, 2, 1], [1, 4, 0], [1, 1, 4], [4, 4, 1], [0, 3, 1], [2, 4, 4], [3, 1, 5], [5, 1, 3], [4, 4, 2], [4, 2, 0], [0, 2, 4], [3, 3, 0], [3, 0, 5], [2, 0, 3], [3, 2, 2], [3, 1, 1], [3, 0, 5], [1, 3, 2], [4, 4, 2], [4, 1, 3], [1, 2, 0], [1, 1, 3], [1, 0, 5], [0, 3, 1], [0, 1, 4], [0, 0, 3], [2, 0, 0], [0, 4, 2], [0, 3, 1], [0, 2, 2], [0, 1, 4], [5, 2, 0], [5, 1, 1], [5, 0, 4], [4, 4, 5], [4, 3, 1], [0, 0, 5], [4, 2, 0], [3, 1, 0], [3, 0, 2], [0, 4, 3], [4, 1, 0], [4, 0, 2], [1, 2, 4], [1, 1, 2], [0, 3, 4], [0, 0, 3], [1, 0, 3]]
	var path: Array = []
	for m: Array in triples:
		path.append({"src": m[0], "j": m[1], "dst": m[2]})
	check(replay_wins(st, lv, path), "中转现场原路线按真实规则通关")
	var original: String = JSON.stringify(path)
	var merged: Array = S._merge_hint_moves(st, lv, path)
	check(merged.size() < path.size() and int(merged[0]["src"]) == 4 and int(merged[0]["dst"]) == 0, 
		"现场5→2→1合并为5→1")
	check(replay_wins(st, lv, merged), "合并后完整路线仍合法并通关")
	check(JSON.stringify(path) == original, "路线整理不修改原输入路线")
	var hint_opts: Dictionary = (load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript).get_script_constant_map()["HINT_OPT"].duplicate()
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, hint_opts, result)
	var hint: Dictionary = result["hint"]
	check( not S._checked_path_hint(st, lv, hint.get("path", [])).is_empty(), 
		"玩家Hint交付真实安全的短路线")
	_test_hint_plan(st, lv, hint)

	lv = JuiceLevel.from_dict({"capacity": 4, "targetCups": 2, 
		"initial": ["-|0", "-|", "-|", "-|0"], "incoming": []})
	st = R.make_state(lv)
	path = [{"src": 0, "j": 0, "dst": 1}, {"src": 1, "j": 0, "dst": 2}, {"src": 2, "j": 0, "dst": 3}]
	merged = S._merge_hint_moves(st, lv, path)
	check(merged.size() == 1 and int(merged[0]["dst"]) == 3, "连续三步中转可合并为一步")
	check(S._full_state_key(S._replay(st, lv, path, true)) == S._full_state_key(S._replay(st, lv, merged, true)), 
		"连续合并保持完整逻辑状态")
	var expired: Callable = func() -> int: return 2
	check(S._merge_hint_moves(st, lv, path, 1, expired).size() == 3, "整理超预算保留原合法路线")

	lv = JuiceLevel.from_dict({"capacity": 3, "targetCups": 2, 
		"initial": ["-|", "0|0,0", "0|0,0"], "incoming": ["1|1,0,1"]})
	st = R.make_state(lv)
	path = [{"src": 1, "j": 1, "dst": 0}, {"src": 0, "j": 0, "dst": 2}]
	merged = S._merge_hint_moves(st, lv, path)
	var end: Dictionary = S._replay(st, lv, merged, true)
	check(merged.size() == 1 and int(end["done"]) == 1 and int(end["jars"][2]) == 1, 
		"合并允许直接收盆，且保留相同补货")
	check(S._full_state_key(end) == S._full_state_key(S._replay(st, lv, path, true)), "收盆补货后的完整状态相同")

	lv = JuiceLevel.from_dict({"capacity": 2, "targetCups": 2, 
		"initial": ["-|0", "0|0", "0|0"], "incoming": ["0|1,0"]})
	st = R.make_state(lv)
	path = [{"src": 0, "j": 0, "dst": 1}, {"src": 1, "j": 1, "dst": 2}]
	check( not S._replay(st, lv, path, true).is_empty() and R.move_info(st, 0, 0, 2) > 0, 
		"拒绝样例的原两步及直接移动都合法")
	check(S._merge_hint_moves(st, lv, path).size() == 2, "直接移动改变收盆与补货结果时不能合并")

	lv = JuiceLevel.from_dict({"capacity": 3, "targetCups": 2, 
		"initial": ["-|0", "-|", "-|0"], "incoming": []})
	st = R.make_state(lv)
	st["cols"][0][0] = JuiceLevel.HIDDEN_BASE
	path = [{"src": 0, "j": 0, "dst": 1}, {"src": 1, "j": 0, "dst": 2}]
	check( not S._replay(st, lv, path, true).is_empty(), "问号花先移空列揭色再接同色是合法路线")
	check(S._merge_hint_moves(st, lv, path).size() == 2, "问号花不能直接接非空列，不合并必要揭色步骤")

	lv = JuiceLevel.from_dict({"capacity": 4, "targetCups": 2, 
		"initial": ["-|1,0", "-|0", "-|"], "incoming": []})
	st = R.make_state(lv)
	path = [{"src": 1, "j": 1, "dst": 0}, {"src": 0, "j": 0, "dst": 2}]
	check(S._merge_hint_moves(st, lv, path).size() == 2, "第二步携带中转列原花朵时不能当作同一段合并")



func _test_android_hint_death() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 29, "capacity": 5, "targetCups": 12, 
		"initial": ["-|2,8,0,1,0", "0|0,1,?0,1,2", 
			{"column": "8|2", "columnType": "unlock", "columnInfo": {"condition": "collect_count", "count": 2}}, 
			"1|1,2,?1,0", "2|?1,8,1", "1|8,1"], 
		"incoming": ["2|2,?3,2,?1,3", "3|2,2,8,3,3", "0|3,8,2,1,2", "7|7,0,6,6,7", 
			"6|?0,6,0,7,6", "4|7,7,0,6,0", "5|4,?5,?4,5,4", "-|5,4,4,5,5"]})
	check(lv.validate().is_empty(), "Android29关现场题面合法")
	var st: Dictionary = R.make_state(lv)
	var cols: Array = [[2, 8, 0, 0, 0], [0, 1, 1, 1, 0], [2], [1, 2], [1001, 8], [8, 1, 1, 1, 2]]
	for i in cols.size():
		(st["cols"][i] as Array[int]).assign(cols[i])
	var original: String = S._full_state_key(st)
	check(R.has_any_move(st) and not S.is_closed_cycle(st, lv), "现场尚可移动，普通封闭循环判定放过")
	var search: Dictionary = S.begin_full_search(st, lv)
	check(S.advance_full_search(search, lv) == S.Reachability.UNWINNABLE
		and (search["seen"] as Dictionary).size() == 2, "完整搜索仅有两个状态且无解")
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {}, result)
	check(int(result["reachability"]) == S.Reachability.UNWINNABLE and result["stop_reason"] == "dead"
		and (result["hint"] as Dictionary).is_empty(), "Hint首段死亡搜索确认现场无解")
	check((result["search_trace"] as Array).size() == 1, "简单死亡提前结束，不再进行Hint搜索")
	S.run_checked_hint_task(st, lv, {"death_node_cap": 1}, result)
	var first: Dictionary = result["search_trace"][0]
	var last: Dictionary = {}
	for phase: Dictionary in result["search_trace"]:
		if phase["phase"] == "death_last":
			last = phase
	check(int(first["reachability"]) == S.Reachability.UNKNOWN
		and int(result["reachability"]) == S.Reachability.UNWINNABLE, 
		"首段节点预算不足时，末段继续搜索并确认无解")
	check(last.get("resumed_from", {}).get("expanded", -1) == first.get("expanded", -2), 
		"末段不从头重算现场残局")
	S.run_checked_hint_task(st, lv, {"death_node_cap": 0}, result)
	check(int(result["reachability"]) == S.Reachability.UNKNOWN and (result["hint"] as Dictionary).is_empty(), 
		"没有完整死亡证明，Hint搜不到路线也不能误判死亡")
	check(S._full_state_key(st) == original, "排查和两段证明不改变现场盘面")
	var page_script: GDScript = GDScript.new()
	page_script.source_code = "extends \"res://scripts/main/pages/game/juice_game_page.gd\"\nvar effects: Array[String] = []\nfunc _show_hint_on_board(_hint: Dictionary) -> bool:\n\teffects.append(\"show\")\n\treturn true\nfunc _charge_prop(_key: String, _btn: PropBtn) -> void:\n\teffects.append(\"charge\")\nfunc _save_progress(_timing: String = \"\") -> void:\n\teffects.append(\"persist\")\n"









	check(page_script.reload() == OK, "现场死亡交付测试fixture编译通过")
	var page: Node = page_script.new()
	var board: Node = (load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript).new()
	board._level = lv
	board._state = R.clone_state(st)
	page._board = board
	page._hint_task_key = page._hint_state_key()
	page._hint_task_cancel = Semaphore.new()
	page._hint_task_progress = S.HintProgress.new()
	var task_result: Dictionary = {"completed": false}
	page._hint_task_result = task_result
	page._hint_task_id = WorkerThreadPool.add_task(S.run_checked_hint_task.bind(R.clone_state(st), lv, {}, task_result))
	while not WorkerThreadPool.is_task_completed(page._hint_task_id):
		OS.delay_msec(1)
	page._hint_poll()
	check(board.over() == "dead" and board._pending_dead_reason == board.HINT_UNWINNABLE_REASON, 
		"完整无解结果通过真实页面收尾进入正式死亡态")
	check(page.effects == ["persist"], "现场死亡只存盘，不显示或扣费Hint")
	check(page._hint_task_id == page.HINT_TASK_NONE, "死亡收尾释放Hint任务与锁")
	board.free()
	page.free()
