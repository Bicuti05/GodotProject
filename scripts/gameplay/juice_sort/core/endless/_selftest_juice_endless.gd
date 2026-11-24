extends SceneTree

const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const G = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_generator.gd")
var failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func check(value: bool, message: String) -> void :
	if not value:
		failures.append(message)
		SortLogger.error("ENDLESS_CORE " + message)


func _collect(session: JuiceEndlessSession) -> void :
	for move: Dictionary in JuiceEndlessSettings.opening_moves(session.seed):
		check( not session.apply_move(int(move["src"]), int(move["j"]), int(move["dst"])).is_empty(), "模板首盆路线合法")
		if not session.pending.is_empty():
			return


func _run() -> void :
	var session: = JuiceEndlessSession.new(42)
	check((session.state["cols"] as Array).size() == 6, "六列")
	check((session.state["caps"] as Array[int]) == [5, 5, 5, 5, 5, 5], "容量全为5")
	check(_flower_count(session.state) == JuiceEndlessSettings.FLOWERS, "初始18朵")
	_test_difficulty_config()
	var patterns: Dictionary = {}
	var white_counts: Dictionary = {}
	for seed_value in 72:
		var opening: = JuiceEndlessSession.new(seed_value)
		var lengths: Array[int] = []
		for ci in 6:
			var col: Array = opening.state["cols"][ci]
			lengths.append(col.size())
			check(col.size() <= 5, "开局所有列均不超容量")
			check(JuiceEndlessSettings.normal_column(col) if col.size() >= 3 else (col.size() < 2 or col[0] != col[1]), "短列也混色且少连续色")
		check(lengths.slice(1) != [4, 4, 4, 4, 4], "彩盆不再固定各四朵")
		patterns[JSON.stringify(lengths)] = true
		white_counts[lengths[0]] = true
		check( not R.any_ready(opening.state), "开局不直接投放已满本色盆")
		var counts: Array = JuiceEndlessSession.inventory(opening.state)["flowers"].slice(0, 5)
		counts.sort()
		check(counts == [2, 3, 4, 4, 5], "开局五色且有足量首盆花")
		check(_flower_count(opening.state) == 18 and 6 * 5 - _flower_count(opening.state) == 12, "开局留十二个空位")
		_collect(opening)
		check( not opening.pending.is_empty(), "不同种子开局有实际首盆路线")
	check(patterns.size() >= 8 and white_counts.size() == 4, "花数位置多样且白绳可带0至3朵")
	_collect(session)
	check(int(session.state["done"]) == 1 and session.pending.size() == 1, "只收盆不立即补货")
	check(_flower_count(session.state) == 13, "等待补货为13朵")
	var pending_col: int = int(session.pending[0]["col"])
	check(int(session.state["caps"][pending_col]) == 0 and session.apply_move(2, 0, pending_col).is_empty(), "只保护待补货列")
	var moved: bool = false
	for mv: Dictionary in R.useful_moves(session.state):
		var trial: JuiceEndlessSession = JuiceEndlessSession.from_snapshot(session.snapshot())
		var rec: Dictionary = trial.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		if not rec.is_empty() and (rec["deposits"] as Array).is_empty():
			var actual: Dictionary = session.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			check((actual["deposits"] as Array).is_empty() and session.pending.size() == 1, "普通移动不重复收盆拍")
			moved = true
			break
	check(moved, "待补货时其他列可操作")
	var before: String = JuiceEndlessSession.snapshot_key(session.snapshot())
	var bad: Array = [{"col": pending_col, "jar": 0, "beads": [0, 0, 0, 0, 0]}]
	check(session.apply_refill(bad).is_empty(), "拒绝自动连收补货")
	check(JuiceEndlessSession.snapshot_key(session.snapshot()) == before, "失败不修改状态")
	var data: Dictionary = session.snapshot()
	var result: Dictionary = G.generate(data, {"now": Time.get_ticks_msec, "budget_ms": 1000})
	check(bool(result["ok"]), "取得实际可收盆补货: %s" % str(result))
	check(int(result["candidates"]) <= 32, "根候选与未来候选共用32批上限")
	check(JuiceEndlessSession.snapshot_key(session.snapshot()) == before, "搜索不改变真实盘面")
	if bool(result["ok"]):
		var replay: JuiceEndlessSession = JuiceEndlessSession.from_snapshot(data)
		for proof: Dictionary in result["proofs"] as Array:
			check( not replay.apply_refill(proof["refill"]).is_empty(), "证明补货合法")
			check(_flower_count(replay.state) == JuiceEndlessSettings.FLOWERS, "每次补货18朵")
			for move: Dictionary in proof["path"] as Array:
				check( not replay.apply_move(int(move["src"]), int(move["j"]), int(move["dst"])).is_empty(), "证明每步真实合法")
			check( not replay.pending.is_empty(), "证明实际收出下一盆")
		var committed: Dictionary = session.apply_refill(result["entries"])
		check( not committed.is_empty(), "正式补货可提交")
		check((committed["spawns"] as Array).size() == 1 and (committed["spawns"][0]["types"] as Array).size() == 5, 
			"补花记录使用盘面types批次契约")
		check(_flower_count(session.state) == JuiceEndlessSettings.FLOWERS and session.pending.is_empty(), "提交恢复18朵")
	var cancel: = Semaphore.new()
	cancel.post()
	result = G.generate(data, {"now": Time.get_ticks_msec, "cancel": cancel})
	check( not bool(result["ok"]) and result["reason"] == "cancelled", "取消不交付")
	var ticks: Dictionary = {"n": 0}
	var fake_now: Callable = func() -> int:
		ticks["n"] = int(ticks["n"]) + 2000
		return int(ticks["n"])
	result = G.generate(data, {"now": fake_now})
	check( not bool(result["ok"]) and result["reason"] == "no_verified_refill", "超时没有无解结论")
	_test_obligations()
	_test_multi()
	_test_bounded_history()
	_test_queue()
	_test_targeted_refill()
	_test_player_hint()
	_test_root_player_hint()
	_test_hint_death()
	if OS.get_cmdline_user_args().has("--long-run"):
		_test_stream()
	if failures.is_empty():
		SortLogger.info("ENDLESS_CORE PASS")
	quit(0 if failures.is_empty() else 1)


func _test_difficulty_config() -> void :
	for row: Array in [[0, 6.0], [10, 8.5], [19, 10.75], [20, 11.0], [21, 11.3625], 
		[39, 17.8875], [40, 18.25], [41, 18.6], [80, 32.0]]:
		check(is_equal_approx(JuiceEndlessSettings.target_score(int(row[0])), float(row[1])), 
			"新难度分界与锚点 %d" % row[0])
	check(is_equal_approx(JuiceEndlessSettings.target_score(6), 6.75)
		and is_equal_approx(JuiceEndlessSettings.target_score(24), 11.205)
		and is_equal_approx(JuiceEndlessSettings.target_score(84), 28.8), "喘息点与封顶仍降到90%")
	check(JuiceEndlessSettings.color_limit(0) == 5 and JuiceEndlessSettings.color_limit(23) == 5
		and JuiceEndlessSettings.color_limit(24) == 6 and JuiceEndlessSettings.color_limit(40) == 6
		and JuiceEndlessSettings.color_limit(48) == 7 and JuiceEndlessSettings.color_limit(200) == 10, 
		"新40盆匹配原15盆的六色范围")
	check(JuiceEndlessSettings.preferred_flower_colors(23) == 5
		and JuiceEndlessSettings.preferred_flower_colors(40) == 6
		and JuiceEndlessSettings.preferred_flower_colors(72) == 8, "在场花色偏好同步放慢")

	var tuning: = JuiceEndlessDifficultyConfig.new()
	tuning.initial_target_score = 4.0
	tuning.first_phase_pots = 10
	tuning.first_phase_target_score = 9.0
	tuning.second_phase_pots = 30
	tuning.second_phase_target_score = 15.0
	tuning.late_score_per_pot = 0.1
	tuning.max_target_score = 16.0
	tuning.recovery_interval = 0
	tuning.color_interval = 10
	tuning.max_colors = 7
	tuning.preferred_color_interval = 10
	tuning.max_preferred_colors = 6
	check(is_equal_approx(tuning.target_score(5), 6.5) and tuning.target_score(10) == 9.0
		and tuning.target_score(30) == 15.0 and tuning.target_score(40) == 16.0
		and tuning.target_score(100) == 16.0, "仅修改配置即可调整三段曲线及关闭喘息")
	check(tuning.color_limit(20) == 7 and tuning.color_limit(200) == 7
		and tuning.preferred_flower_colors(20) == 6, "颜色增长与上限均可配置")


func _test_obligations() -> void :

	var fixture: = JuiceEndlessSession.new(1)
	fixture.level = JuiceLevel.from_dict({"id": 1, "capacity": 5, "targetCups": 5, 
		"initial": ["-|", "0|0,0,1,1", "0|0,0,2,2", "1|1,1,0,0", "1|1,1,0,0", "2|2,2"], "incoming": []})
	fixture.state = R.make_state(fixture.level)
	fixture.apply_move(1, 2, 0)
	fixture.apply_move(3, 2, 1)
	fixture.apply_move(4, 3, 1)
	var high: Dictionary = fixture.snapshot()
	high["state"]["done"] = 140
	var entries: Array = [{"col": 1, "jar": 2, "beads": [0, 0, 1, 9, 2]}]
	var checked: Dictionary = JuiceEndlessSession.check_refill(high, entries)
	check( not checked.is_empty(), "10色范围允许潜伏花")
	if checked.is_empty():
		return
	check(int(checked["obligations"][9]) == 146, "潜伏色六盆内回收承诺")
	high["obligations"] = {9: 140}
	check(JuiceEndlessSession.check_refill(high, entries).is_empty(), "到期承诺不能再次顺延")
	entries[0]["jar"] = 9
	checked = JuiceEndlessSession.check_refill(high, entries)
	check( not checked.is_empty() and not (checked["obligations"] as Dictionary).has(9), "对应盆到货解除承诺")


func _test_multi() -> void :
	var session: = JuiceEndlessSession.new(7)

	session.state["cols"][1] = [0, 0, 0, 0, 0] as Array[int]
	session.state["cols"][2] = [0, 0, 0, 0, 0] as Array[int]
	session.state["jars"][1] = 0
	session.state["jars"][2] = 0
	session.state["cols"][0] = [] as Array[int]
	session.state["cols"][3] = [1, 2, 3, 4] as Array[int]
	check( not session.apply_move(3, 3, 0).is_empty(), "多盆输入可移动")
	check(session.pending.size() == 2 and int(session.state["done"]) == 2, "同一步完整摘出两盆")
	session.state["cols"][3] = [1, 1, 1, 1] as Array[int]
	session.state["jars"][3] = 1
	(session.state["cols"][4] as Array[int])[-1] = 1
	var next: Dictionary = session.apply_move(4, (session.state["cols"][4] as Array).size() - 1, 3)
	check( not next.is_empty() and (next["deposits"] as Array).size() == 1
		and session.pending.size() == 3 and int(session.state["done"]) == 3, "等待中再次收盆只增加新记录")
	var partial: Array = [{"col": 1, "jar": 1, "beads": [0, 0, 1, 1, 2]}]
	check(session.apply_refill(partial).is_empty(), "多盆批次不能部分提交")


func _test_bounded_history() -> void :
	var session: = JuiceEndlessSession.new(9)
	for i in 40:
		var cups: Array[int] = (session.state["cups"] as Array[int]).duplicate()
		session.state = R.make_state(session.level)
		session.state["done"] = i
		session.state["cups"] = cups
		session.pending.clear()
		_collect(session)
	check(int(session.state["done"]) == 40 and (session.state["cups"] as Array).size() == 32, 
		"累计盆数与有界明细独立")


func _flower_count(st: Dictionary) -> int:
	var count: int = 0
	for col: Array in st["cols"] as Array:
		count += col.size()
	return count


func _test_queue() -> void :
	var stream: Dictionary = {"seed": 42, "sequence": 0}
	var entries: Array[Dictionary] = []
	for i in 5:
		var result: Dictionary = G.next_stream(stream, {"now": Time.get_ticks_msec})
		check(bool(result.get("ok", false)), "后台参考盘面生成缓存%d" % i)
		if not bool(result.get("ok", false)):
			return
		entries.append(result["entry"])
		stream = result["stream"]
	var player: = JuiceEndlessSession.new(42, true)
	check(player.enqueue(entries) and player.incoming.size() == 5, "缓存五列")
	check( not player.enqueue(entries), "缓存不超过五列")
	var path: Array = JuiceEndlessSettings.opening_moves(42)
	for i in 5:
		for mv: Dictionary in path:
			check( not player.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), "缓存参考路线真实合法")
		check(player.incoming.size() == 4 - i and int(player.state["done"]) == i + 1
			and player.pending.is_empty() and _flower_count(player.state) == JuiceEndlessSettings.FLOWERS, "同步消费有序缓存、数量守恒")
		path = player.last_incoming["reference_path"]
	var next: Dictionary = G.next_stream(stream, {"now": Time.get_ticks_msec})
	check(bool(next.get("ok", false)) and player.enqueue([next["entry"]]), "消费后继续补缓存")
	check(int(player.incoming[0]["sequence"]) == 5, "缓存不重复、不跳序")


func _test_targeted_refill() -> void :

	var session: = JuiceEndlessSession.new(1947)
	session.state["cols"] = [[5, 5] as Array[int], [] as Array[int], [3] as Array[int], 
		[8, 8, 1] as Array[int], [4, 4, 4, 2, 2] as Array[int], [0, 0] as Array[int]]
	session.state["caps"] = [5, 0, 5, 5, 5, 5] as Array[int]
	session.state["jars"] = [-1, -1, 1, 2, 4, 3] as Array[int]
	session.state["done"] = 43
	session.obligations = {0: 45, 5: 46, 8: 46}
	session.pending.append({"col": 1, "fruit": 1, "q": 5, "nth": 42, "spawns": [], "new_rope": {}})
	var snapshot: Dictionary = session.snapshot()
	var before: String = JuiceEndlessSession.snapshot_key(snapshot)
	for attempt: int in [0, 1, 3]:
		var result: Dictionary = G.generate(snapshot, {"now": Time.get_ticks_msec, "budget_ms": 1000, "attempt": attempt})
		check(bool(result.get("ok", false)), "失败快照首次/自动/手动尝试均取得下一盆证明")
		if not bool(result.get("ok", false)):
			continue
		check(int(result["candidates"]) <= 32, "针对目标色后仍保持32批上限")
		var replay: JuiceEndlessSession = JuiceEndlessSession.from_snapshot(snapshot)
		check( not replay.apply_refill(result["entries"]).is_empty(), "修复候选仍满足库存与颜色承诺")
		for move: Dictionary in result["proofs"][0]["path"]:
			check( not replay.apply_move(int(move.src), int(move.j), int(move.dst)).is_empty(), "修复路线真实重放")
		check(int(replay.state["done"]) == 44, "修复快照实际收出第44盆")
	check(JuiceEndlessSession.snapshot_key(snapshot) == before, "生成不改变旧盘面或回收承诺")
	var rng: = RandomNumberGenerator.new()
	rng.seed = 1947
	for i in 32:
		var entries: Array = G.candidate(snapshot, rng, i)
		if entries.is_empty():
			continue
		var checked: Dictionary = JuiceEndlessSession.check_refill(snapshot, entries)
		var counts: Dictionary = JuiceEndlessSession.inventory(checked["state"])
		var ready_color: bool = false
		for color in JuiceEndlessSettings.MAX_COLORS:
			if int(counts["pots"][color]) > 0 and int(counts["flowers"][color]) >= 5:
				ready_color = true
		check(ready_color, "合格候选必有能集齐五朵的盆色，避免无目标随机补花")
	var multi: = JuiceEndlessSession.new(1947)
	multi.state["cols"] = [[] as Array[int], [0, 0, 0, 0, 0] as Array[int], [0, 0, 0, 0, 0] as Array[int], 
		[1, 2, 3] as Array[int], [1, 2, 3] as Array[int], [3, 4] as Array[int]]
	multi.state["jars"] = [-1, 0, 0, 1, 2, 3] as Array[int]
	check( not multi.apply_move(3, 2, 4).is_empty() and multi.pending.size() == 2, "两盆补列夹具真实收集")
	var batches: int = 0
	for i in 32:
		var entries: Array = G.candidate(multi.snapshot(), rng, i)
		if entries.is_empty():
			continue
		batches += 1
		var replay: JuiceEndlessSession = JuiceEndlessSession.from_snapshot(multi.snapshot())
		check(entries.size() == 2 and not replay.apply_refill(entries).is_empty()
			and _flower_count(replay.state) == 18, "多盆目标花分配仍一次提交、总数守恒")
	check(batches > 0, "多盆补列也能构造满足约束的目标候选")


func _test_player_hint() -> void :
	var player: = JuiceEndlessSession.new(42, true)
	var stream: Dictionary = {"seed": 42, "sequence": 0}
	for i in 5:
		var result: Dictionary = G.next_stream(stream, {"now": Time.get_ticks_msec})
		check(bool(result.get("ok", false)), "提示夹具预生成可交付")
		if not bool(result.get("ok", false)):
			return
		player.enqueue([result["entry"]])
		stream = result["stream"]
	var snapshot: Dictionary = player.player_snapshot()
	var solver = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_hint_solver.gd")
	for enabled: bool in [false, true]:
		snapshot["state"]["allow_root_swapping"] = enabled
		var before: String = JSON.stringify(snapshot)
		var hint: Dictionary = solver.solve(snapshot, {"now": Time.get_ticks_msec})
		check( not hint.is_empty() and not bool(hint.get("win_path", true)), "两组无尽提示只证明下一盆")
		check(JSON.stringify(snapshot) == before, "两组提示不修改玩家快照/FIFO")
		if not hint.is_empty():
			var replay: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(snapshot)
			for mv: Dictionary in hint["path"]:
				check( not replay.apply_move(int(mv.src), int(mv.j), int(mv.dst)).is_empty(), "玩家提示按真实固定FIFO重放")
			check(int(replay.state["done"]) > 0 and replay.incoming.size() < 5, "提示真正收盆并消费补列")
	var cancel: = Semaphore.new()
	cancel.post()
	check(solver.solve(snapshot, {"now": Time.get_ticks_msec, "cancel": cancel}).is_empty(), "提示取消不交付")
	check(solver.solve(snapshot, {"now": Time.get_ticks_msec, "deadline": 0}).is_empty(), "提示超时不交付")
	var sparse: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(snapshot)
	sparse.state["cols"][0] = [] as Array[int]
	for ci in range(1, 6):
		sparse.state["cols"][ci] = [ci - 1, ci - 1, ci - 1, ci - 1] as Array[int]
		sparse.state["jars"][ci] = ci - 1
	check(solver.solve(sparse.player_snapshot(), {"now": Time.get_ticks_msec}).is_empty(), "数量不足时不伪造提示或有限关通关")
	var mixed: = JuiceEndlessSession.new(42, true)
	mixed.state["cols"] = [[4, 4] as Array[int], [0, 0] as Array[int], 
		[2, 5, 2, 3, 1] as Array[int], [2, 2] as Array[int], 
		[0, 4, 2, 4, 0] as Array[int], [4, 5] as Array[int]]
	mixed.state["jars"] = [-1, 0, 4, 2, 4, 1] as Array[int]
	check(mixed.enqueue([{"sequence": 0, "jar": 0, 
		"beads": [4, 5, 1, 0, 4] as Array[int]}]), "混色周转Hint夹具固定补列")
	var mixed_snapshot: Dictionary = mixed.player_snapshot()
	var mixed_before: String = JSON.stringify(mixed_snapshot)
	var mixed_result: Dictionary = {}
	solver.run_task(mixed_snapshot, {"now": Time.get_ticks_msec}, mixed_result)
	var mixed_hint: Dictionary = mixed_result["hint"]
	check( not mixed_hint.is_empty() and int(mixed_hint.get("len", 0)) <= 6, 
		"多目标Hint在原预算内找到六步混色周转收盆路线")
	check(int(mixed_result["reachability"]) != JuiceSolver.Reachability.UNWINNABLE
		and JSON.stringify(mixed_snapshot) == mixed_before, "有解盘面不判死且搜索不改真实状态")
	if not mixed_hint.is_empty():
		var mixed_replay: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(mixed_snapshot)
		for move: Dictionary in mixed_hint["path"]:
			check( not mixed_replay.apply_move(int(move["src"]), int(move["j"]), int(move["dst"])).is_empty(), 
				"混色周转Hint每步均按玩家规则合法")
		check(int(mixed_replay.state["done"]) == 1 and mixed_replay.incoming.is_empty(), 
			"混色周转Hint真正收盆并消费固定FIFO")


func _root_hint_fixture(formed: bool) -> JuiceEndlessSession:
	var session: = JuiceEndlessSession.new(42, true)
	session.state["allow_root_swapping"] = true
	session.state["cols"] = [[] as Array[int], 
		([0, 0, 0, 0, 0] as Array[int]) if formed else ([0, 0, 0, 0] as Array[int]), 
		([1] as Array[int]) if formed else ([1, 0] as Array[int]), 
		[1, 2, 3, 4, 1] as Array[int], [2, 3, 4, 1, 2] as Array[int], [3, 4] as Array[int]]
	session.state["jars"] = [-1, 1, 0, 2, 3, 4] as Array[int]
	for sequence in 5:
		check(session.enqueue([{"sequence": sequence, "jar": 0, "beads": [1, 1, 2, 3, 4] as Array[int]}]), 
			"实验无尽夹具FIFO合法")
	check(_flower_count(session.state) == 18 and not R.any_ready(session.state), "实验夹具18朵且尚未落盆")
	return session


func _test_root_player_hint() -> void :
	var solver = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_hint_solver.gd")
	for formed: bool in [true, false]:
		var session: JuiceEndlessSession = _root_hint_fixture(formed)
		var snapshot: Dictionary = session.player_snapshot()
		var hint: Dictionary = solver.solve(snapshot, {"now": Time.get_ticks_msec})
		check( not hint.is_empty(), "无尽实验优先组满串再送盆 formed=" + str(formed))
		if hint.is_empty():
			continue
		check( not bool(hint["win_path"]) and not bool(hint["root_necessary"]), "无尽局部路线不伪报有限通关")
		check(int(hint["len"]) == (1 if formed else 2), "满串一步送盆/未满串两步先形成后送盆")
		if formed:
			check(int(hint["move"]["src"]) == 1 and int(hint["move"]["dst"]) == 2, 
				"已有满同色串抓完成列送正确花盆")
		var production: Dictionary = solver.solve(snapshot, {"now": Time.get_ticks_msec, 
			"require_complete": true, "verify_safe": false, "deadline": 0, "ms_cap": 0, 
			"preferred_path": hint["path"]})
		check( not production.is_empty() and production["path"] == hint["path"], 
			"生产首盆证明回放不受旧800ms截止影响")
		var independent: Dictionary = solver.solve(snapshot, {"now": Time.get_ticks_msec, 
			"require_complete": true, "verify_safe": false, "deadline": 0, "ms_cap": 0, 
			"state_cap": 1, "node_cap": 1})
		check( not independent.is_empty(), "生产独立首盆搜索不因状态或节点预算停止")
		var cancelled: = Semaphore.new()
		cancelled.post()
		check(solver.solve(snapshot, {"now": Time.get_ticks_msec, "require_complete": true, 
			"verify_safe": false, "preferred_path": hint["path"], "cancel": cancelled}).is_empty(), 
			"完整首盆回放仍服从取消")
		var previous: Dictionary = {}
		for move: Dictionary in hint["path"]:
			previous = session.apply_move(int(move["src"]), int(move["j"]), int(move["dst"]))
			check( not previous.is_empty(), "组列到落盆每步真实合法")
			check( not R.any_ready(session.state), "真实无尽稳定移动同帧收盆/FIFO不遗留满盆")
		check(int(session.state["done"]) == 1 and session.incoming.size() == 4\
		and _flower_count(session.state) == 18 and session.last_incoming == snapshot["incoming"][0], 
			"交换收盆消费固定队首并恢复18朵")
		check(session.undo_move(previous) and session.player_snapshot() == previous["endless_before"], 
			"无尽交换收盆撤回还原规则/FIFO/盆数")
	var empty: JuiceEndlessSession = _root_hint_fixture(true)
	empty.incoming.clear()
	var result: Dictionary = {}
	solver.run_task(empty.player_snapshot(), {"now": Time.get_ticks_msec}, result)
	check((result["hint"] as Dictionary).is_empty()\
	and int(result["reachability"]) == JuiceSolver.Reachability.UNKNOWN, "FIFO空不伪造Hint或死亡证明")

	var fallback: JuiceEndlessSession = _root_hint_fixture(true)
	for entry: Dictionary in fallback.incoming:
		entry["beads"] = [2, 3, 4, 5, 6] as Array[int]
	var fallback_data: Dictionary = fallback.player_snapshot()
	var fallback_hint: Dictionary = solver.solve(fallback_data, {"now": Time.get_ticks_msec})
	check( not fallback_hint.is_empty() and not bool(fallback_hint.get("safe_after", true)), 
		"无尽收盆后无下一盆仍交付真实首盆兜底")
	if not fallback_hint.is_empty():
		for move: Dictionary in fallback_hint["path"]:
			check( not fallback.apply_move(int(move["src"]), int(move["j"]), int(move["dst"])).is_empty(), 
				"无后续出口的首盆仍可按固定FIFO真实执行")
		var proof: Dictionary = JuiceSolver.begin_root_closed_search(fallback.state, fallback.level)
		var conclusion: Dictionary = JuiceSolver.advance_root_closed_search(proof, 8)
		check(bool(conclusion["closed"]) and int(fallback.state["done"]) == 1, 
			"兜底只承诺首盆，不冒充后续安全或有限通关")

	var expired_calls: Array[int] = [0]
	var expired_checks: Dictionary = {"deadline": 1, "now": func() -> int:
		expired_calls[0] += 1
		return 0 if expired_calls[0] == 1 else 1}
	var expired_hint: Dictionary = solver._checked_root_path(
		[{"src": 1, "j": 0, "dst": 2}], expired_checks, fallback_data)
	check( not expired_hint.is_empty() and not bool((expired_checks["check_safe"] as Callable).call(expired_checks)), 
		"无尽后续择优超时不删除首盆路线")
	var one_entry: JuiceEndlessSession = _root_hint_fixture(true)
	one_entry.incoming.resize(1)
	var one_hint: Dictionary = solver.solve(one_entry.player_snapshot(), {"now": Time.get_ticks_msec})
	check( not one_hint.is_empty(), "仅一条补列可真实收本盆，后续缓存空不拒绝Hint")
	print("ENDLESS_ROOT_HINT formed_delivery=true grouping_delivery=true fifo_replay=true undo=true")


func _test_hint_death() -> void :
	var solver = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_hint_solver.gd")
	var irreversible: = JuiceEndlessSession.new(42, true)
	irreversible.state["cols"] = [[1] as Array[int], [2, 3, 3] as Array[int], 
		[0, 0, 0, 2] as Array[int], [0, 0, 0, 0] as Array[int], 
		[5, 5, 1, 1, 1] as Array[int], [4] as Array[int]]
	irreversible.state["jars"] = [-1, 2, 0, 0, 3, 4] as Array[int]
	check(irreversible.enqueue([{"sequence": 0, "jar": 1, 
		"beads": [2, 2, 0, 2, 3] as Array[int]}]), "不可逆死局夹具固定FIFO")
	check(R.has_any_move(irreversible.state)
		and JuiceSolver._has_irreversible_move(irreversible.state)
		and not JuiceSolver.is_closed_cycle(irreversible.state, irreversible.level), 
		"仍可搬动的无解盘面不满足自动封闭循环判死")
	var snapshot: Dictionary = irreversible.player_snapshot()
	var snapshot_before: String = JSON.stringify(snapshot)
	var proof: Dictionary = {}
	solver.run_task(snapshot, {"now": Time.get_ticks_msec}, proof)
	check(int(proof["reachability"]) == JuiceSolver.Reachability.UNWINNABLE
		and String(proof["stop_reason"]) == "dead" and (proof["hint"] as Dictionary).is_empty(), 
		"无尽Hint穷尽证明不可逆死局无首盆出口，立即交付死亡结论")
	check(JSON.stringify(snapshot) == snapshot_before, "不可逆死局证明不改盘面或FIFO")
	var rescued: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(snapshot)
	check(R.add_rope(rescued.state, 5) == 6, "额外暂存绳可恢复同盘首盆出口")
	solver.run_task(rescued.player_snapshot(), {"now": Time.get_ticks_msec}, proof)
	check(int(proof["reachability"]) != JuiceSolver.Reachability.UNWINNABLE
		and not (proof["hint"] as Dictionary).is_empty(), "存在真实收盆出口时不可判死")
	for enabled: bool in [false, true]:
		var session: = JuiceEndlessSession.new(42, true)
		session.state["allow_root_swapping"] = enabled
		session.state["cols"] = [[0, 0, 0] as Array[int], [1, 1, 1] as Array[int], 
			[2, 2, 2] as Array[int], [3, 3, 3] as Array[int], [4, 4, 4] as Array[int], [5, 5, 5] as Array[int]]
		session.state["jars"] = [-1, 6, 7, 8, 9, 6] as Array[int]
		check(session.enqueue([{"sequence": 0, "jar": 0, "beads": [0, 1, 2, 3, 4] as Array[int]}]), "判死夹具补列合法")
		check(_flower_count(session.state) == 18 and R.has_any_move(session.state) == enabled, 
			"对照无合法移动、实验仅能整串交换，均保留18朵花")
		var data: Dictionary = session.player_snapshot()
		var before: String = JSON.stringify(data)
		var result: Dictionary = {}
		solver.run_task(data, {"now": Time.get_ticks_msec}, result)
		check(bool(result["completed"]) and (result["hint"] as Dictionary).is_empty()
			and int(result["reachability"]) == JuiceSolver.Reachability.UNWINNABLE, 
			"Hint严格证明无合法移动/封闭交换死局 enabled=" + str(enabled))
		check(JSON.stringify(data) == before, "Hint判死不修改真实盘面或FIFO")
		var cancel: = Semaphore.new()
		cancel.post()
		solver.run_task(data, {"now": Time.get_ticks_msec, "cancel": cancel}, result)
		check(int(result["reachability"]) == JuiceSolver.Reachability.UNKNOWN
			and String(result["stop_reason"]) == "cancelled", "取消死局检查不发布死亡证明")
		solver.run_task(data, {"now": Time.get_ticks_msec, "deadline": 0}, result)
		check(int(result["reachability"]) == JuiceSolver.Reachability.UNKNOWN, "预算已过期不发布死亡证明")
		data["incoming"] = []
		solver.run_task(data, {"now": Time.get_ticks_msec}, result)
		check(int(result["reachability"]) == JuiceSolver.Reachability.UNKNOWN, "FIFO暂空不判玩家死亡")
	var live: JuiceEndlessSession = _root_hint_fixture(true)
	var result: Dictionary = {}
	solver.run_task(live.player_snapshot(), {"now": Time.get_ticks_msec}, result)
	check( not (result["hint"] as Dictionary).is_empty()
		and int(result["reachability"]) != JuiceSolver.Reachability.UNWINNABLE, "已验证下一盆Hint不被判死拦截")
	print("ENDLESS_HINT_DEATH stuck=true closed=true cancelled=UNKNOWN expired=UNKNOWN empty_fifo=UNKNOWN")


func _test_stream() -> void :
	var stream: Dictionary = {"seed": 1947, "sequence": 0}
	var player: = JuiceEndlessSession.new(1947, true)
	for i in 5:
		var prepared: Dictionary = G.next_stream(stream, {"now": Time.get_ticks_msec})
		if not bool(prepared.get("ok", false)):
			check(false, "长局初始预生成%d" % i)
			return
		check(player.enqueue([prepared["entry"]]), "长局预填缓存")
		stream = prepared["stream"]
	var path: Array = JuiceEndlessSettings.opening_moves(1947)
	var block_steps: int = 0
	var block_colors: int = 0
	for round_index in 60:
		block_steps += path.size()
		for mv: Dictionary in path:
			check( not player.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), "连续流参考路线真实合法")
		path = player.last_incoming["reference_path"]
		check(player.incoming.size() == 4 and _flower_count(player.state) == JuiceEndlessSettings.FLOWERS, "长局消费后四列缓存和18朵花")
		var active_colors: int = 0
		for count: int in JuiceEndlessSession.inventory(player.state)["flowers"] as Array[int]:
			if count > 0:
				active_colors += 1
		block_colors += active_colors
		var next: Dictionary = G.next_stream(stream, {"now": Time.get_ticks_msec})
		if not bool(next.get("ok", false)):
			next = G.next_stream(stream, {"now": Time.get_ticks_msec, "budget_ms": 2000, "attempt": 1})
		if not bool(next.get("ok", false)):
			SortLogger.info("ENDLESS_STREAM manual_retry round=%d result=%s" % [round_index, JSON.stringify(next)])

			next = G.next_stream(stream, {"now": Time.get_ticks_msec, "budget_ms": 2000, "attempt": 3})
		if not bool(next.get("ok", false)):
			check(false, "长局后续补列未生成%d" % round_index)
			return
		check(player.enqueue([next["entry"]]) and player.incoming.size() == 5, "长局恢复五列缓存")
		stream = next["stream"]
		if round_index % 10 == 9:
			SortLogger.info("ENDLESS_STREAM done=%d queued=%d next_sequence=%d color_limit=%d avg_route=%.1f avg_colors=%.1f" % [
				int(player.state["done"]), player.incoming.size(), int(stream["sequence"]), 
				JuiceEndlessSettings.color_limit(int(player.state["done"])), float(block_steps) / 10.0, float(block_colors) / 10.0])
			block_steps = 0
			block_colors = 0
	check(int(player.state["done"]) == 60 and (player.state["cups"] as Array).size() == 32, "长局累计独立于有界明细")
