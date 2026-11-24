extends SceneTree










const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const C = preload("res://scripts/gameplay/juice_sort/core/juice_challenge.gd")
const JuiceLevelC = preload("res://scripts/gameplay/juice_sort/core/juice_level.gd")
const FALLBACK_PATH: = "res://assets/game/juice_fallback_levels.json"
const MS_CAP: = 200

const MS_SLACK: = 60
const MAX_STEPS: = 150

const CLEAR_WINDOW: = 8
const HINT_OPT: = {"shallow_depth": 20, "shallow_nodes": 6000, "ms_cap": 150, 
	"deep_nodes": 20000, "deep_depth": 34}

var _failures: Array[String] = []


func _initialize() -> void :
	_test_trap()
	_test_master()
	_test_plain_opening()
	_test_gate()
	_test_hidden()
	_test_temptation()
	_test_clear()
	_test_lucky_reveal()
	_test_lucky_reveal_root_swapping()
	_scan_fallback()
	_finish()



func _level(capacity: int, initial: Array) -> JuiceLevel:
	var types: int = 0
	for col: String in initial:
		var jar: String = col.split("|")[0]
		if jar != "-":
			types += 1
	var incoming: Array = []
	for i in types - 1:
		incoming.append("x")
	var lv: JuiceLevel = JuiceLevelC.from_dict({"id": 9100, "capacity": capacity, "targetCups": types, 
		"initial": initial, "incoming": incoming})
	var errs: Array[String] = lv.validate()
	_expect(errs.is_empty(), "构造关卡不合法: %s" % "; ".join(errs))
	return lv



func _test_trap() -> void :
	var lv: JuiceLevel = _level(3, ["0|0,1,0", "-|2,2,3", "2|0,3", "1|3", "3|2,1,1"])
	var info: Dictionary = C.classify(R.make_state(lv), lv)
	_expect(int(info["kind"]) == C.Kind.TRAP, "陷阱盘面应判 TRAP,实得 %s" % str(info))
	_expect(int(info["fatal"]) >= 1 and int(info["alive"]) == 1, "陷阱盘面计数不对: %s" % str(info))

	var answer: Dictionary = info.get("answer", {})
	_expect( not answer.is_empty(), "陷阱结果应带正解: %s" % str(info))
	if not answer.is_empty():
		_expect(C.answer_follows(info, {"src": int(answer["dst"]), "dst": 99}), "正解目标列是上一步来源列时应判为顺势")
		_expect( not C.answer_follows(info, {"src": 98, "dst": 99}), "上一步与正解无关时不应判为顺势")
		_expect( not C.answer_follows(info, {}), "没有上一步时不应判为顺势")



func _test_master() -> void :
	var lv: JuiceLevel = _level(3, ["2|0", "0|2,2,0", "-|0,1,1", "1|2,1"])
	var info: Dictionary = C.classify(R.make_state(lv), lv)
	_expect(int(info["kind"]) == C.Kind.MASTER, "妙手盘面应判 MASTER,实得 %s" % str(info))
	_expect(int(info["depth"]) == 1, "妙手盘面出口深度应为 1,实得 %s" % str(info))



func _test_plain_opening() -> void :
	var lv: JuiceLevel = _level(2, ["-|", "0|1,2", "1|2,0", "2|0,1"])
	var info: Dictionary = C.classify(R.make_state(lv), lv)
	_expect(int(info["kind"]) == C.Kind.NONE, "普通开局不应触发,实得 %s" % str(info))


func _test_gate() -> void :
	var lv: JuiceLevel = _level(2, ["-|2,0", "0|1,0", "1|2,1", "2|"])
	var st: Dictionary = R.make_state(lv)
	_expect(C.gate_reason(st, lv, 1) == "opening", "开局前几步应被排除")
	_expect(C.gate_reason(st, lv, 1, true) == "", "续局不算开局,不应按开局排除")

	_expect(C.gate_reason(st, lv, 5) == "", "普通局面不应被排除")
	var two_cups: JuiceLevel = JuiceLevelC.from_dict({"id": 9102, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|1,0", "1|0,1"], "incoming": ["x"]})
	_expect(C.gate_reason(R.make_state(two_cups), two_cups, 5) == "endgame", "终局应被排除")



func _test_hidden() -> void :

	var touch: JuiceLevel = JuiceLevelC.from_dict({"id": 9101, "capacity": 2, "targetCups": 3, 
		"initial": ["-|", "0|?1,0", "1|1,2", "2|2,0"], "incoming": ["x", "x"]})
	var revealed_n: int = 0
	var ctx: Dictionary = C._make_ctx({})
	for nx: Dictionary in C._progress_outcomes(R.make_state(touch), touch):
		if nx.has(C.REVEALED_MARK):
			revealed_n += 1
			_expect(C._near_dead(nx, touch, ctx) == 0, "翻开问号的那一步不应被判死")
	_expect(revealed_n > 0, "翻开问号的走法应计入推进走法")
	var info: Dictionary

	var buried: JuiceLevel = _level(3, ["2|?2,0,3", "3|2,2,0", "-|3,1,3", "0|1", "1|0,1"])
	var plain: JuiceLevel = _level(3, ["2|2,0,3", "3|2,2,0", "-|3,1,3", "0|1", "1|0,1"])
	info = C.classify(R.make_state(buried), buried)
	var plain_info: Dictionary = C.classify(R.make_state(plain), plain)
	_expect(String(info["reason"]) == String(plain_info["reason"]) and int(info["kind"]) == int(plain_info["kind"]), 
		"问号压在底下碰不到时应与明牌同判,实得 %s vs %s" % [str(info), str(plain_info)])



func _test_lucky_reveal() -> void :
	var cases: Array = [

		["lucky", ["0|0,?2,2", "1|1,0", "2|2", "-|1,0,1"], [0, 2, 2]], 

		["other_progress", ["0|0,?2,0", "1|1,1,2", "2|0,2,1", "-|"], [0, 2, 3]], 

		["no_connect", ["0|0,?0,2", "1|1,2,1", "2|0,1", "-|2"], [0, 2, 3]], 

		["unproven", ["0|2,?0,1", "1|2,0,0", "2|1,1,2", "-|"], [0, 2, 3]], 
	]
	for c: Array in cases:
		var lv: JuiceLevel = JuiceLevelC.from_dict({"id": 9103, "capacity": 3, "targetCups": 3, 
			"initial": c[1], "incoming": ["x", "x"]})
		var mv: Array = c[2]
		var post: Dictionary = R.make_state(lv)
		var rec: Dictionary = R.apply_move(post, lv, int(mv[0]), int(mv[1]), int(mv[2]))
		_expect( not rec.is_empty() and not (rec["revealed"] as Array).is_empty(), 
			"好运问号用例 %s 的走法应合法且翻开问号" % c[0])
		if rec.is_empty():
			continue
		var pre: Dictionary = R.clone_state(post)
		R.undo_move(pre, rec, false)
		var info: Dictionary = C.lucky_reveal(pre, post, rec["revealed"], lv)
		var got: String = "lucky" if bool(info["lucky"]) else String(info["reason"])
		_expect(got == String(c[0]), "好运问号用例应判 %s,实得 %s" % [c[0], str(info)])



func _test_lucky_reveal_root_swapping() -> void :
	var cases: Array = [

		["no_connect", ["-|0,1", "0|?0,1", "1|1"]], 

		["lucky", ["-|1,1", "0|?0,1", "1|0"]], 
	]
	for c: Array in cases:
		var lv: JuiceLevel = JuiceLevelC.from_dict({"id": 9104, "capacity": 3, "targetCups": 2, 
			"initial": c[1], "incoming": ["-|0"]})
		_expect(lv.validate().is_empty(), "根部交换好运问号题面应合法: %s" % str(lv.validate()))
		for root_swapping: bool in [false, true]:
			var post: Dictionary = R.make_state(lv)
			post["allow_root_swapping"] = root_swapping
			var rec: Dictionary = R.apply_move(post, lv, 1, 1, 0)
			_expect( not rec.is_empty() and not (rec["revealed"] as Array).is_empty(), 
				"根部交换好运问号走法应合法且翻开问号")
			if rec.is_empty():
				continue
			_expect((rec["deposits"] as Array).is_empty(), "本步不能收盆，须通过页面的好运问号投递门控")
			var pre: Dictionary = R.clone_state(post)
			R.undo_move(pre, rec, false)
			var opt: Dictionary = {"now": Time.get_ticks_msec, "ms_cap": MS_CAP}

			var ctx: Dictionary = C._make_ctx(opt)
			_expect(C._stuck_without_reveal(pre, lv, ctx, {}) == 1, "不翻问号应无法种满下一盆")
			C._start_verify_phase(ctx)
			_expect(C._verify_alive(post, lv, ctx), "翻开后应能种满下一盆")
			var info: Dictionary = C.lucky_reveal(pre, post, rec["revealed"], lv, opt)
			var got: String = "lucky" if bool(info["lucky"]) else String(info["reason"])
			_expect(got == String(c[0]), "根部交换=%s 好运问号应判 %s，实得 %s"
				%[root_swapping, c[0], str(info)])



func _test_temptation() -> void :


	var st140: Dictionary = {"cols": [[0, 1001, 1], [1, 1001, 1, 1, 1], [2], [3, 2, 2, 2, 0], [0, 0, 3, 3], 
		[4, 4, 4, 4], [5, 3, 5, 2, 6]], "jars": [-1, 1, 2, 3, 0, 4, 5]}
	var alive140: float = _temptation_of(st140, 3, 1, 2)
	var fatal140: float = _temptation_of(st140, 6, 3, 2)
	_expect(alive140 - fatal140 > C.TRAP_OBVIOUS_MARGIN, 
		"第 140 关正解应明显更诱人,实得 %.2f vs %.2f" % [alive140, fatal140])

	var st115: Dictionary = {"cols": [[1, 0, 3], [3, 2, 2, 2, 2], [5, 5, 0, 0], [1, 1], [2, 7, 3, 3, 3], 
		[0, 5, 5, 1, 1], [7, 7, 7, 7]], "jars": [-1, 3, 0, 5, 2, 1, 7]}
	var alive115: float = _temptation_of(st115, 0, 0, 3)
	var fatal115: float = _temptation_of(st115, 5, 3, 3)
	_expect(alive115 - fatal115 <= C.TRAP_OBVIOUS_MARGIN, 
		"第 115 关死路应不输正解,实得 %.2f vs %.2f" % [alive115, fatal115])



func _test_clear() -> void :
	var trap: JuiceLevel = _level(3, ["0|0,1,0", "-|2,2,3", "2|0,3", "1|3", "3|2,1,1"])
	var st: Dictionary = R.make_state(trap)
	var info: Dictionary = C.classify(st, trap)
	var answer: Dictionary = info.get("answer", {})
	if answer.is_empty():
		_expect(false, "陷阱结果应带正解: %s" % str(info))
		return
	var nx: Dictionary = R.clone_state(st)
	var rec: Dictionary = R.apply_move(nx, trap, int(answer["src"]), int(answer["j"]), int(answer["dst"]))
	_expect(R.state_key(nx) == String(info.get("answer_key", "")), "走正解后的指纹应等于 answer_key")
	_expect(C.is_progress_move(nx, rec), "陷阱正解是推进走法")
	_expect(bool(C.exit_alive(nx, trap)["alive"]), "陷阱正解走完应判为出口")
	var ctx: Dictionary = C._make_ctx({})
	var fatal_n: int = 0
	for outcome: Dictionary in C._progress_outcomes(st, trap):
		if C._near_dead(outcome, trap, ctx) == 1:
			fatal_n += 1
			_expect( not bool(C.exit_alive(outcome, trap)["alive"]), "陷阱死路走完不应判为出口")
			_expect(R.state_key(outcome) != String(info["answer_key"]), "死路指纹不应等于 answer_key")
	_expect(fatal_n > 0, "陷阱盘面应有死路")

	var master: JuiceLevel = _level(3, ["2|0", "0|2,2,0", "-|0,1,1", "1|2,1"])
	var shuffles: int = 0
	for pair: Array in [[trap, st], [master, R.make_state(master)]]:
		var lv: JuiceLevel = pair[0]
		var pre: Dictionary = pair[1]
		var cols: Array = pre["cols"]
		for src in cols.size():
			var sc: Array[int] = cols[src]
			for j in sc.size():
				for dst in cols.size():
					if R.move_info(pre, src, j, dst) <= 0:
						continue
					var after: Dictionary = R.clone_state(pre)
					var r: Dictionary = R.apply_move(after, lv, src, j, dst)
					var expect_shuffle: bool = C._is_shuffle_cut(sc, j) and (r["deposits"] as Array).is_empty()\
					and (r["revealed"] as Array).is_empty()
					if expect_shuffle:
						shuffles += 1
					_expect(C.is_progress_move(after, r) != expect_shuffle, 
						"推进走法倒推与走前口径不一致: %d,%d→%d" % [src, j, dst])
	_expect(shuffles > 0, "测试盘面应至少有一步倒腾")



func _temptation_of(raw: Dictionary, src: int, j: int, dst: int) -> float:
	var cols: Array = []
	for c: Array in raw["cols"]:
		var typed: Array[int] = []
		typed.assign(c)
		cols.append(typed)
	var jars: Array[int] = []
	jars.assign(raw["jars"])
	var caps: Array[int] = []
	caps.resize(cols.size())
	caps.fill(5)
	var gone: Array[bool] = []
	gone.resize(cols.size())
	gone.fill(false)
	var locks: Array = []
	for i in cols.size():
		locks.append({})
	var st: Dictionary = {"cols": cols, "jars": jars, "caps": caps, "locks": locks, "gone": gone, "done": 0, 
		"cups": [] as Array[int], "late_left": 0, "extra_rope_used": false}
	_expect(R.move_info(st, src, j, dst) > 0, "诱惑分测试走法不合法: %d,%d→%d" % [src, j, dst])
	var nx: Dictionary = R.clone_state(st)
	var sc: Array[int] = nx["cols"][src]
	var dc: Array[int] = nx["cols"][dst]
	for i in range(j, sc.size()):
		dc.append(sc[i])
	sc.resize(j)
	nx[C.MOVE_MARK] = {"src": src, "j": j, "dst": dst}
	return C._temptation(st, nx, {})




func _scan_fallback() -> void :
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var level_n: int = int(args[0]) if args.size() > 0 else 20
	var playouts: int = int(args[1]) if args.size() > 1 else 2
	var text: String = FileAccess.get_file_as_string(FALLBACK_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_expect(false, "读不到兜底题库 %s" % FALLBACK_PATH)
		return
	var rows: Array = (parsed as Dictionary).get("levels", [])
	var rng: = RandomNumberGenerator.new()
	rng.seed = 20261010
	var all_ms: Array[int] = []
	var reasons: Dictionary = {}
	var total_trap: int = 0
	var total_master: int = 0
	var total_steps: int = 0
	var clear_stats: Dictionary = {"trap_hit": 0, "trap_miss": 0, "master_after": {}, "master_miss": {}, 
		"master_expired": 0, "aborted": 0, "ms": [] as Array[int]}
	print("level  steps  checks  trap  master   avg_ms  max_ms")
	for li in mini(level_n, rows.size()):
		var row: Dictionary = (rows[li] as Dictionary).duplicate()
		row.erase("level_unique_id")
		var lv: JuiceLevel = JuiceLevelC.from_dict(row)
		if not lv.validate().is_empty():
			continue
		for p in playouts:
			var r: Dictionary = _playout(lv, rng, all_ms, reasons, clear_stats)
			total_trap += int(r["trap"])
			total_master += int(r["master"])
			total_steps += int(r["steps"])
			print("%5d  %5d  %6d  %4d  %6d  %7.1f  %6d" % [li, int(r["steps"]), int(r["checks"]), 
				int(r["trap"]), int(r["master"]), float(r["avg_ms"]), int(r["max_ms"])])
	all_ms.sort()
	if all_ms.is_empty():
		_expect(false, "扫描没有跑出任何判定")
		return
	var p50: int = all_ms[all_ms.size() / 2]
	var p99: int = all_ms[mini(all_ms.size() - 1, int(all_ms.size() * 0.99))]
	print("== checks=%d steps=%d trap=%d master=%d | ms p50=%d p99=%d max=%d"
		%[all_ms.size(), total_steps, total_trap, total_master, p50, p99, all_ms[-1]])
	print("== NONE reasons: %s" % str(reasons))
	var budget: int = MS_CAP + C.DEFAULT_VERIFY_MS_CAP + MS_SLACK
	_expect(all_ms[-1] <= budget, "判定最坏耗时 %dms 超过预算 %d" % [all_ms[-1], budget])


	var exit_ms: Array[int] = clear_stats["ms"]
	exit_ms.sort()
	print("== clear trap hit=%d miss=%d | master after=%s miss=%s expired=%d | aborted=%d" % [
		int(clear_stats["trap_hit"]), int(clear_stats["trap_miss"]), str(clear_stats["master_after"]), 
		str(clear_stats["master_miss"]), int(clear_stats["master_expired"]), int(clear_stats["aborted"])])
	if not exit_ms.is_empty():
		print("== exit ms p50=%d max=%d" % [exit_ms[exit_ms.size() / 2], exit_ms[-1]])
		_expect(exit_ms[-1] <= budget, "出口判定最坏耗时 %dms 超过预算 %d" % [exit_ms[-1], budget])






func _playout(lv: JuiceLevel, rng: RandomNumberGenerator, all_ms: Array[int], 
		reasons: Dictionary, clear_stats: Dictionary) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	var out: Dictionary = {"steps": 0, "checks": 0, "trap": 0, "master": 0, "avg_ms": 0.0, "max_ms": 0}
	var sum_ms: int = 0
	var last: Dictionary = {}
	var armed: Dictionary = {}
	for step in MAX_STEPS:
		if R.is_win(st, lv) or not R.has_any_move(st):
			break
		if C.gate_reason(st, lv, step) == "":
			var t0: int = Time.get_ticks_msec()
			var info: Dictionary = C.classify(R.clone_state(st), lv, 
				{"now": Time.get_ticks_msec, "ms_cap": MS_CAP})
			var ms: int = Time.get_ticks_msec() - t0
			all_ms.append(ms)
			sum_ms += ms
			out["checks"] = int(out["checks"]) + 1
			out["max_ms"] = maxi(int(out["max_ms"]), ms)
			if int(info["kind"]) != C.Kind.NONE and C.answer_follows(info, last):
				info["kind"] = C.Kind.NONE
				info["reason"] = "follows_last"
			match int(info["kind"]):
				C.Kind.TRAP:
					out["trap"] = int(out["trap"]) + 1
					armed = {"step": step, "kind": C.Kind.TRAP, "answer_key": String(info["answer_key"])}
				C.Kind.MASTER:
					out["master"] = int(out["master"]) + 1
					armed = {"step": step, "kind": C.Kind.MASTER}
				_:
					var reason: String = String(info["reason"])
					reasons[reason] = int(reasons.get(reason, 0)) + 1
		var mv: Dictionary = {}
		if rng.randf() < 0.75:
			var opt: Dictionary = HINT_OPT.duplicate()
			opt["now"] = Time.get_ticks_msec
			var h: Dictionary = S.hint_move(st, lv, opt)
			if not h.is_empty() and not bool(h.get("guess", false)):
				mv = h["move"]
		if mv.is_empty():
			var cands: Array = R.useful_moves(st)
			if cands.is_empty():
				break
			mv = cands[rng.randi_range(0, cands.size() - 1)]
		last = {"src": int(mv["src"]), "dst": int(mv["dst"])}
		var rec: Dictionary = R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		if rec.is_empty():
			break
		out["steps"] = step + 1
		if not armed.is_empty():
			_judge_clear(st, lv, rec, armed, step + 1 - int(armed["step"]), clear_stats)
	if not armed.is_empty():
		clear_stats["aborted"] = int(clear_stats["aborted"]) + 1
	var checks: int = int(out["checks"])
	out["avg_ms"] = float(sum_ms) / float(checks) if checks > 0 else 0.0
	return out




func _judge_clear(st: Dictionary, lv: JuiceLevel, rec: Dictionary, armed: Dictionary, after: int, 
		stats: Dictionary) -> void :
	if int(armed["kind"]) == C.Kind.TRAP:
		var hit: bool = R.state_key(st) == String(armed["answer_key"])
		stats["trap_hit" if hit else "trap_miss"] = int(stats["trap_hit" if hit else "trap_miss"]) + 1
		armed.clear()
		return
	if not C.is_progress_move(st, rec):
		if after >= CLEAR_WINDOW:
			stats["master_expired"] = int(stats["master_expired"]) + 1
			armed.clear()
		return
	var t0: int = Time.get_ticks_msec()
	var ex: Dictionary = C.exit_alive(R.clone_state(st), lv, {"now": Time.get_ticks_msec, "ms_cap": MS_CAP})
	(stats["ms"] as Array[int]).append(Time.get_ticks_msec() - t0)
	var bucket: Dictionary = stats["master_after"] if bool(ex["alive"]) else stats["master_miss"]
	var k: Variant = after if bool(ex["alive"]) else String(ex["reason"])
	bucket[k] = int(bucket.get(k, 0)) + 1
	armed.clear()


func _expect(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)


func _finish() -> void :
	if _failures.is_empty():
		print("juice challenge selftest OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("juice challenge selftest: %s" % failure)
	quit(1)
