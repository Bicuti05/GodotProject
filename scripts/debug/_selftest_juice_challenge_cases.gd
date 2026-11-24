extends SceneTree










const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const C = preload("res://scripts/gameplay/juice_sort/core/juice_challenge.gd")
const JuiceLevelC = preload("res://scripts/gameplay/juice_sort/core/juice_level.gd")
const CASES = preload("res://scripts/debug/juice_challenge_cases.gd")

var _failures: Array[String] = []


func _initialize() -> void :
	for i in CASES.CASES.size():
		_check(i + 1, CASES.CASES[i])
	_check_trap_detour()
	if _failures.is_empty():
		print("PASS juice_challenge_cases (%d cases)" % CASES.CASES.size())
	else:
		for f: String in _failures:
			printerr("FAIL " + f)
	quit(0 if _failures.is_empty() else 1)


func _check(n: int, c: Dictionary) -> void :
	var row: Dictionary = (c["level"] as Dictionary).duplicate(true)
	row["id"] = 9100
	var lv: JuiceLevel = JuiceLevelC.from_dict(row)
	var errs: Array[String] = lv.validate()
	if not errs.is_empty():
		_failures.append("#%d 题面不合法: %s" % [n, "; ".join(errs)])
		return
	var st: Dictionary = R.make_state(lv)
	var opening: Dictionary = C.classify(st, lv)
	if int(opening["kind"]) != C.Kind.NONE:
		_failures.append("#%d 开局就是关键点,一步之后会被页面频控按「连续」吞掉: %s" % [n, str(opening)])
	var mv: Array = c["move"]
	if R.move_info(st, int(mv[0]), int(mv[1]), int(mv[2])) <= 0:
		_failures.append("#%d 触发步 %s 不合法" % [n, str(mv)])
		return
	R.apply_move(st, lv, int(mv[0]), int(mv[1]), int(mv[2]))
	var gate: String = C.gate_reason(st, lv, 1, true)
	if gate != "":
		_failures.append("#%d 触发步之后被排除门挡掉: %s" % [n, gate])
		return
	var t0: int = Time.get_ticks_msec()
	var info: Dictionary = C.classify(st, lv, {"ms_cap": 200, "now": Time.get_ticks_msec})
	var ms: int = Time.get_ticks_msec() - t0
	var kind: String = C.kind_name(int(info["kind"]))
	if kind != String(c["kind"]):
		_failures.append("#%d 应判 %s,实得 %s (%s)" % [n, c["kind"], kind, str(info)])
		return
	if C.answer_follows(info, {"src": int(mv[0]), "dst": int(mv[2])}):
		_failures.append("#%d 陷阱正解顺着触发步走,盘面侧不会报" % n)
	var ans: Array = c["answer"]
	if kind == "TRAP":
		var got: Dictionary = info.get("answer", {})
		if got.is_empty() or [int(got["src"]), int(got["j"]), int(got["dst"])] != ans:
			_failures.append("#%d 正解记录 %s 与判定 %s 不一致" % [n, str(ans), str(got)])
	print("#%d %s ok %dms depth=%d · %s" % [n, kind, ms, int(info["depth"]), CASES.describe_move(c)])




func _check_trap_detour() -> void :
	var c: Dictionary = CASES.get_case(2)
	var row: Dictionary = (c["level"] as Dictionary).duplicate(true)
	row["id"] = 9100
	var lv: JuiceLevel = JuiceLevelC.from_dict(row)
	var trap: Dictionary = R.make_state(lv)
	var mv: Array = c["move"]
	R.apply_move(trap, lv, int(mv[0]), int(mv[1]), int(mv[2]))
	var answer_key: String = String(C.classify(trap, lv).get("answer_key", ""))
	var st: Dictionary = R.clone_state(trap)
	var expect: Array = [false, true]
	var route: Array = [[2, 2, 3], [2, 0, 1]]
	for i in route.size():
		var step: Array = route[i]
		var rec: Dictionary = R.apply_move(st, lv, int(step[0]), int(step[1]), int(step[2]))
		var cleared: bool = R.state_key(st) == answer_key\
		or (C.is_progress_move(st, rec) and bool(C.exit_alive(st, lv)["alive"]))
		if cleared != bool(expect[i]):
			_failures.append("陷阱绕路第 %d 步 %s 应%s点赞" % [i + 1, str(step), "" if expect[i] else "不"])
	var fatal: Dictionary = R.clone_state(trap)
	var rec2: Dictionary = R.apply_move(fatal, lv, 4, 3, 2)
	if C.is_progress_move(fatal, rec2) and bool(C.exit_alive(fatal, lv)["alive"]):
		_failures.append("陷阱死路(第 5 列粉 → 第 3 列)不应点赞")
	print("trap detour ok")
