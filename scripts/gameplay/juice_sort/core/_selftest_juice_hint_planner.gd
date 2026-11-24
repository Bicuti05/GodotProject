extends SceneTree

const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const P = preload("res://scripts/gameplay/juice_sort/core/juice_hint_planner.gd")
var failures: Array[String] = []
var boards: int = 0
var rollbacks: int = 0
var root_swapping: bool = false

func _initialize() -> void :
	root_swapping = "--root-swapping" in OS.get_cmdline_user_args()
	_test_small_boards()

	if not root_swapping:
		_test_budget_and_three_pots()
		_test_retry_and_cancel()
		_test_death_budget()
	print("JUICE_HINT_PLANNER_SELFTEST ", "PASS" if failures.is_empty() else failures, 
		" root_swapping=", root_swapping, " boards=", boards, " rollbacks=", rollbacks)
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void :
	if not ok:
		failures.append(message)
		push_error(message)

func options(st: Dictionary, lv: JuiceLevel) -> Dictionary:
	return {"now": func() -> int: return 1, 
		"rank": func(cur: Dictionary, moves: Array, first: bool) -> void :
			S._sort_first_layer(cur, moves, {}), 
		"verify": func(path: Array, _ms: int) -> Dictionary:
			var opt: Dictionary = {}
			var hint: Dictionary = S._checked_path_hint(st, lv, path, opt)
			return {"hint": hint, "stop": opt.get("check_stop", "")}}



func bfs(root: Dictionary, lv: JuiceLevel) -> Dictionary:
	var queue: Array = [{"st": R.clone_state(root), "path": []}]
	var seen: Dictionary = {S._full_state_key(root): true}
	var cursor: int = 0
	while cursor < queue.size() and cursor < 50000:
		var node: Dictionary = queue[cursor]
		cursor += 1
		var st: Dictionary = node["st"]
		for src in (st["cols"] as Array).size():
			for j in (st["cols"][src] as Array).size():
				for dst in (st["cols"] as Array).size():
					if R.move_info(st, src, j, dst) <= 0:
						continue
					var mv: Dictionary = {"src": src, "j": j, "dst": dst}
					var nx: Dictionary = R.clone_state(st)
					var rec: Dictionary = R.apply_move(nx, lv, src, j, dst)
					var path: Array = node["path"] + [mv]
					if not (rec["deposits"] as Array).is_empty():
						if S._hint_safe_after(nx, lv, {}):
							return {"len": path.size(), "path": path}
						continue
					var key: String = S._full_state_key(nx)
					if not seen.has(key):
						seen[key] = true
						queue.append({"st": nx, "path": path})
	return {}

func compare(st: Dictionary, lv: JuiceLevel) -> void :
	st["allow_root_swapping"] = root_swapping
	var before: String = S._full_state_key(st)
	var cur: Dictionary = P.clone_search(st)
	for mv: Dictionary in P.all_moves(cur):
		var rec: Dictionary = R.apply_move(cur, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
		P.undo_search(cur, rec)
		check(S._full_state_key(cur) == before, "精确撤回恢复原始隐藏值及完整指纹")
		rollbacks += 1
	var oracle: Dictionary = bfs(st, lv)
	var opts: Dictionary = options(st, lv)
	var find: Dictionary = P.begin_find(st, lv, opts)
	while not bool(find["done"]) and int(find["expanded"]) < 200000:
		P.advance_find(find, 8, 10000)
	check(bool(find["done"]), "小盘面首解搜索结束")
	var seed: Dictionary = find["hint"]
	check(seed.is_empty() == oracle.is_empty(), "首解存在性与独立BFS相同")
	if not seed.is_empty():
		var reference: Array = []
		for slice_nodes: int in [1, 8, 32]:
			var job: Dictionary = P.begin_shortening(st, lv, seed, opts)
			var previous: int = int(seed["len"])
			while not bool(job["done"]):
				P.advance_shortening(job, slice_nodes, 10000)
				check(int(job["hint"]["len"]) <= previous, "缩短阶段路线长度单调不增加")
				previous = int(job["hint"]["len"])
			check(previous == int(oracle["len"]), "小盘面A*步数与独立BFS一致")
			if slice_nodes == 1:
				reference = job["hint"]["path"]
			else:
				check(reference == job["hint"]["path"], "分片大小不改变搜索结果")
		for limits: Dictionary in [{"shorten_nodes": 0}, {"state_cap": 0}]:
			var bounded: Dictionary = opts.duplicate()
			bounded.merge(limits, true)
			var job: Dictionary = P.begin_shortening(st, lv, seed, bounded)
			while not bool(job["done"]):
				P.advance_shortening(job, 8, 10000)
			check( not (job["hint"] as Dictionary).is_empty() and int(job["hint"]["len"]) <= int(seed["len"]), 
				"节点和内存上限不会丢掉已验证首解")
		var expired: Dictionary = P.begin_shortening(st, lv, seed, opts)
		P.advance_shortening(expired, 8, 1)
		check(bool(expired["done"]) and expired["hint"] == seed, "截止保留原已验证路线")
	check(S._full_state_key(st) == before, "所有搜索不改变输入盘面")
	boards += 1

func _test_small_boards() -> void :
	for mask in 64:
		var colors: Array[int] = []
		var count: int = 0
		for i in 6:
			var value: int = (mask >> i) & 1
			count += value
			colors.append(value)
		if count != 3 or mask in [7, 56]:
			continue
		var lv: JuiceLevel = JuiceLevel.from_dict({"capacity": 3, "targetCups": 2, 
			"initial": ["0|%d,%d,%d" % colors.slice(0, 3), "1|%d,%d,%d" % colors.slice(3, 6), "-|"], "incoming": []})
		compare(R.make_state(lv), lv)
		for ci in [0, 1]:
			for pos in [0, 1]:
				var hidden: Dictionary = R.make_state(lv)
				(hidden["cols"][ci] as Array[int])[pos] += JuiceLevel.HIDDEN_BASE
				compare(hidden, lv)
	var long_rope: JuiceLevel = JuiceLevel.from_dict({"capacity": 8, "targetCups": 2, 
		"initial": ["-|0", "0|0,0,0,0,0,0,0", "1|1,1,1,1,1,1,1,1"], "incoming": []})
	compare(R.make_state(long_rope), long_rope)

func four_pots() -> JuiceLevel:
	return JuiceLevel.from_dict({"capacity": 2, "targetCups": 4, 
		"initial": ["0|0", "1|1", "2|2", "3|3", "-|0,1", "-|2,3"], "incoming": ["x", "x", "x"]})

func _test_budget_and_three_pots() -> void :
	var lv: JuiceLevel = four_pots()
	var st: Dictionary = R.make_state(lv)
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": func() -> int: return 1, "death_first_ms": 0, "death_last_ms": 0}, result)
	var hint: Dictionary = result["hint"]
	var after: Dictionary = S._replay(st, lv, hint.get("path", []), true)
	check(int(after.get("done", 0)) == 3 and result["hint_source"] == "three_pot", "有余量仍交付三盆路线")
	check(int(result["reachability"]) == S.Reachability.UNKNOWN and not bool(hint.get("win_path", false)), 
		"三盆出路不伪装整关通关证明")
	check(int(hint.get("first_len", 0)) == 1, "三盆续搜保留最短一盆前缀")
	S.run_checked_hint_task(after, lv, {"now": func() -> int: return 1, "death_first_ms": 0, "death_last_ms": 0}, result)
	check(bool(result["hint"].get("win_path", false)), "不足三盆的续搜目标仍是实际通关")
	var elapsed: Array[int] = [0]
	var clock: Callable = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "_hint_win_dfs":
				elapsed[0] = 801
		return elapsed[0]
	S.run_checked_hint_task(st, lv, {"now": clock, "fast_ms": 0, "death_first_ms": 0, "death_last_ms": 0}, result)
	hint = result["hint"]
	after = S._replay(st, lv, hint.get("path", []), true)
	check(int(after.get("done", 0)) == 1 and result["hint_source"] == "local", "三盆续搜超时保留安全一盆")
	check(result["stop_reason"] == "resolved", "优化超时不把已找到提示标成空结果")
	elapsed[0] = 0
	clock = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "advance_shortening":
				elapsed[0] = 801
		return elapsed[0]
	S.run_checked_hint_task(st, lv, {"now": clock, "fast_ms": 0, "death_first_ms": 0, "death_last_ms": 0}, result)
	for phase: Dictionary in result["search_trace"]:
		check( not String(phase["phase"]).begins_with("three_pot"), "缩短耗尽余量后不另开三盆预算")
	check( not (result["hint"] as Dictionary).is_empty(), "缩短超时保留首解")

func _test_retry_and_cancel() -> void :
	var lv: JuiceLevel = four_pots()
	var st: Dictionary = R.make_state(lv)
	var attempts: Array[int] = [0]
	var opts: Dictionary = options(st, lv)
	var real_verify: Callable = opts["verify"]
	opts["verify"] = func(path: Array, ms: int) -> Dictionary:
		attempts[0] += 1
		return {"hint": {}, "stop": "deadline"} if attempts[0] < 3 else real_verify.call(path, ms)
	var find: Dictionary = P.begin_find(st, lv, opts)
	while not bool(find["done"]):
		P.advance_find(find, 1, 10000)
	check(attempts[0] == 3 and not (find["hint"] as Dictionary).is_empty(), "安全检查超时重试同一候选，不错误剪枝")
	var late: Array[int] = [0]
	var clock: Callable = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "_checked_path_hint":
				late[0] = 800
		return late[0]
	var mailbox: S.HintProgress = S.HintProgress.new()
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": clock, "fast_ms": 0, "progress": mailbox, 
		"death_first_ms": 0, "death_last_ms": 0}, result)
	check(int(result["elapsed_ms"]) == 800 and result["stop_reason"] == "deadline"
		and (result["hint"] as Dictionary).is_empty(), "首解验证到800ms立即结束，不续开时间片")
	check(mailbox.read().is_empty(), "未验证完的候选不发布到保护邮箱")
	S.run_checked_hint_task(st, lv, {"now": func() -> int: return 1, "progress": mailbox}, result)
	var snapshot: Dictionary = mailbox.read()
	check( not (snapshot.get("hint", {}) as Dictionary).is_empty(), "保护邮箱保留已验证路线")
	var version: int = int(snapshot["version"])
	(snapshot["hint"]["path"] as Array).clear()
	check( not (mailbox.read()["hint"]["path"] as Array).is_empty(), "读取快照不能修改工作线程的保护结果")
	check(mailbox.read(version).is_empty(), "未更新邮箱无需重复复制")
	var cancel: Semaphore = Semaphore.new()
	cancel.post()
	S.run_checked_hint_task(st, lv, {"cancel": cancel}, result)
	check(result["stop_reason"] == "cancelled" and (result["hint"] as Dictionary).is_empty(), "首解前取消不交付")
	var posted: Array[bool] = [false]
	clock = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "_hint_win_dfs" and not posted[0]:
				posted[0] = true
				cancel.post()
		return 1
	mailbox = S.HintProgress.new()
	S.run_checked_hint_task(st, lv, {"now": clock, "fast_ms": 0, "cancel": cancel, "progress": mailbox}, result)
	check(posted[0] and result["stop_reason"] == "cancelled" and (result["hint"] as Dictionary).is_empty()
		and not (mailbox.read().get("hint", {}) as Dictionary).is_empty(), "首解已发布后取消，仍不交付旧结果")


func _test_death_budget() -> void :
	var lv: JuiceLevel = four_pots()
	var st: Dictionary = R.make_state(lv)
	var original: String = S._full_state_key(st)
	var ticks: Array[int] = [0]
	var clock: Callable = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "advance_full_search":
				ticks[0] += 1
		return ticks[0]
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": clock}, result)
	var first: Dictionary = {}
	var last: Dictionary = {}
	for phase: Dictionary in result["search_trace"]:
		if phase["phase"] == "death_first":
			first = phase
		if phase["phase"] == "death_last":
			last = phase
	check(first.get("elapsed_ms", 999) == 50 and first.get("reachability", -1) == S.Reachability.UNKNOWN, 
		"首段完整搜索到50ms暂停，保留未知")
	check( not last.is_empty() and int(last.get("elapsed_ms", 999)) <= 70, 
		"末段完整搜索最多使用70ms")
	check(last.get("resumed_from", {}).get("expanded", -1) == first.get("expanded", -2)
		and last.get("resumed_from", {}).get("candidates", -1) == first.get("candidates", -2), 
		"末段沿用首段完整搜索的状态与候选游标")
	check( not (result["hint"] as Dictionary).is_empty() and int(result["elapsed_ms"]) <= 800, 
		"死亡搜索未完成时仍交付已验证提示，总时长不重置")
	ticks[0] = 0
	clock = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "advance_full_search":
				ticks[0] = 50 if ticks[0] < 50 else ticks[0] + 1
			if frame["function"] == "_checked_path_hint":
				ticks[0] = 730
		return ticks[0]
	S.run_checked_hint_task(st, lv, {"now": clock, "fast_ms": 0}, result)
	check(int(result["elapsed_ms"]) == 800 and int(result["reachability"]) == S.Reachability.UNKNOWN
		and (result["hint"] as Dictionary).is_empty(), "首解安全验证不能吃掉预留70ms或把超时判成死亡")
	check(S._full_state_key(st) == original, "两段完整搜索和Hint不修改玩家盘面")
	var cancel: Semaphore = Semaphore.new()
	var posted: Array[bool] = [false]
	clock = func() -> int:
		for frame: Dictionary in get_stack():
			if frame["function"] == "advance_full_search" and not posted[0]:
				posted[0] = true
				cancel.post()
		return 1
	var mailbox: S.HintProgress = S.HintProgress.new()
	S.run_checked_hint_task(st, lv, {"now": clock, "death_first_ms": 0, 
		"cancel": cancel, "progress": mailbox}, result)
	check(posted[0] and result["stop_reason"] == "cancelled"
		and int(result["reachability"]) == S.Reachability.UNKNOWN
		and (result["hint"] as Dictionary).is_empty() and not mailbox.read().get("hint", {}).is_empty(), 
		"末段死亡搜索取消后不交付保护快照或死亡结论")
