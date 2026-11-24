extends SceneTree









const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

const ROW: = {"capacity": 8, "targetCups": 4, "initial": ["-|2,1,2,0,2,3", "0|1,2,3", "1|0,0,0,1,3,0,3,0", "2|2,2,3,1,3,1,3", "3|1,1,2,0,2,0,1,3"], "incoming": []}

var _failures: Array[String] = []


func _initialize() -> void :
	_test_hint_solves_whole_level()
	_test_sort_lower_bound()
	_finish()


func _test_hint_solves_whole_level() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict(ROW)
	_check(lv.validate().is_empty(), "样例题面应合法:%s" % str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	var opt: Dictionary = {"deep_nodes": 20000}
	var steps: int = 0
	var guesses: int = 0
	while not R.is_win(st, lv) and steps < 200:
		var h: Dictionary = S.hint_move(st, lv, opt)
		if h.is_empty():
			break
		if bool(h.get("guess", false)):
			guesses += 1
		var mv: Dictionary = h["move"]
		if R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
			break
		steps += 1
	_check(R.is_win(st, lv), "照提示走应能通关(走了 %d 步)" % steps)
	_check(guesses == 0, "无墙钟预算下不应落到 C 层猜测(猜了 %d 次)" % guesses)


func _test_sort_lower_bound() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"capacity": 3, "targetCups": 2, 
		"initial": ["-|", "0|1,0,1", "1|0,1,0"], "incoming": []})
	var st: Dictionary = R.make_state(lv)
	_check(S.sort_lower_bound(st) > 0, "乱序盘面下界应 > 0")
	(st["cols"] as Array)[1] = [0, 0, 0] as Array[int]
	(st["cols"] as Array)[2] = [1, 1, 1] as Array[int]
	_check(S.sort_lower_bound(st) == 0, "已理顺的盘面下界应为 0")


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)


func _finish() -> void :
	if _failures.is_empty():
		print("[selftest_juice_long_rope] ALL PASS")
		quit(0)
		return
	for f: String in _failures:
		printerr("[selftest_juice_long_rope] FAIL: " + f)
	quit(1)
