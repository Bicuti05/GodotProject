extends SceneTree



















const L = preload("res://scripts/data/user_level/user_level_ladder.gd")

var _failures: Array[String] = []


func _initialize() -> void :
	_test_tag_value()
	_test_product_timeline()
	_test_promote_resets_window()
	_test_denominator_is_fixed_n()
	_test_clamp_top_and_bottom()
	_test_n5_needs_three_dirty()
	_test_four_losses()
	_test_easy_promotion()
	_test_experiment_invariants()
	_finish()



func _test_tag_value() -> void :
	_expect(L.tag_value(0) == "", "tag_value(0) 应为空串，实际 %s" % L.tag_value(0))
	_expect(L.tag_value(1) == "lv1", "tag_value(1) 应为 lv1")
	_expect(L.tag_value(5) == "lv5", "tag_value(5) 应为 lv5")
	_expect(L.tag_value(6) == "", "tag_value(6) 越界应为空串")
	_expect(int(L.initial_state()["level"]) == 2, "起步等级应为 lv2")




func _test_product_timeline() -> void :
	var st: Dictionary = L.initial_state()
	_expect(int(st["level"]) == 2, "第5关结束应为 lv2")

	st = L.settle(int(st["level"]), int(st["clean_streak"]), st["recent_dirty"] as Array, false)
	_expect(int(st["level"]) == 2, "第6关干净后仍应是 lv2（连胜 1 < n=2）")
	_expect(int(st["clean_streak"]) == 1, "第6关后连胜应为 1")

	st = L.settle(int(st["level"]), int(st["clean_streak"]), st["recent_dirty"] as Array, false)
	_expect(int(st["level"]) == 3, "第7关干净后应升到 lv3")
	_expect(int(st["clean_streak"]) == 0, "升级后连胜应清零")
	_expect((st["recent_dirty"] as Array).is_empty(), "升级后窗口应清空")

	st = L.settle(int(st["level"]), int(st["clean_streak"]), st["recent_dirty"] as Array, true)
	_expect(int(st["level"]) == 3, "第8关脏后仍应保持 lv3（1*2=2 > 3 不成立）")

	st = L.settle(int(st["level"]), int(st["clean_streak"]), st["recent_dirty"] as Array, true)
	_expect(int(st["level"]) == 2, "第9关再脏应降到 lv2（2*2=4 > 3）")
	_expect((st["recent_dirty"] as Array).is_empty(), "降级后窗口应清空")
	_expect(int(st["clean_streak"]) == 0, "降级后连胜应清零")




func _test_promote_resets_window() -> void :
	var st: Dictionary = L.settle(3, 0, [true, true], true)
	_expect(int(st["level"]) == 2, "lv3 连三脏应降到 lv2")
	st = L.settle(int(st["level"]), int(st["clean_streak"]), st["recent_dirty"] as Array, true)
	_expect(int(st["level"]) == 2, "刚降到 lv2 后再脏一关应保持 lv2（窗口已清空）")




func _test_denominator_is_fixed_n() -> void :
	var st: Dictionary = L.settle(3, 0, [], true)
	_expect(int(st["level"]) == 3, "窗口只有 1 关脏时不该降级（分母必须是 n=3）")
	_expect(L.dirty_count([true], 3) == 1, "dirty_count 应只数已有的那几关")
	_expect(L.dirty_count([true, false, true, true], 3) == 2, "dirty_count 应只看末 n 项")



func _test_clamp_top_and_bottom() -> void :
	var st: Dictionary = L.settle(5, 4, [false, false, false, false], false)
	_expect(int(st["level"]) == 5, "lv5 连赢不该越界升级")
	_expect(int(st["clean_streak"]) == L.n_of(5), "lv5 连胜应封顶在 n，不无界增长")
	st = L.settle(1, 0, [true], true)
	_expect(int(st["level"]) == 1, "lv1 再脏不该降成 lv0")




func _test_n5_needs_three_dirty() -> void :
	var two: Dictionary = L.settle(4, 0, [true, false, false, false], true)
	_expect(int(two["level"]) == 4, "lv4 窗口 2 关脏不该降（2*2=4 > 5 不成立）")
	var three: Dictionary = L.settle(4, 0, [true, true, false, false], true)
	_expect(int(three["level"]) == 3, "lv4 窗口 3 关脏应降到 lv3（3*2=6 > 5）")





func _test_four_losses() -> void :
	for level: int in [4, 5]:
		var three: Dictionary = L.settle(level, 0, [true, true], true, false, true)
		_expect(int(three["level"]) == level, "四败组 lv%d 三败应保持" % level)
		var four: Dictionary = L.settle(level, 0, [true, true, true], true, false, true)
		_expect(int(four["level"]) == level - 1, "四败组 lv%d 第四败应降档，不等五局满" % level)
		_expect((four["recent_dirty"] as Array).is_empty(), "四败降档后清窗口")
		_expect(int(four["clean_streak"]) == 0, "四败降档后清连胜")
		var slid: Dictionary = L.settle(level, 0, [true, true, true, true, false], false, false, true)
		_expect(int(slid["level"]) == level, "四败组旧败局滑出后只有三败，应保持")
		_expect((slid["recent_dirty"] as Array).size() == L.WINDOW_CAP, "窗口上限仍为五局")
	for level: int in [1, 2, 3]:
		_expect(L.settle(level, 0, [true], true, false, true) == L.settle(level, 0, [true], true), 
			"四败组 lv%d 应沿原降级规则" % level)



func _test_easy_promotion() -> void :
	var one: Dictionary = L.settle(3, 0, [], false, true)
	_expect(int(one["level"]) == 3, "累计组 lv3 一胜不升，缺少的局数不能算胜")
	var two: Dictionary = L.settle(3, 1, [false], false, true)
	_expect(int(two["level"]) == 4, "累计组 lv3 两胜不等三局满就升")
	var mixed: Dictionary = L.settle(3, 0, [false, true], false, true)
	_expect(int(mixed["level"]) == 4, "累计组 lv3 胜败胜也晋级")
	_expect(int(L.settle(3, 0, [false, true], false)["level"]) == 3, "对照组仍要求连续三胜")
	var high: Dictionary = L.settle(4, 0, [false, true, false], false, true)
	_expect(int(high["level"]) == 5, "累计组 lv4 四局中的三胜晋级")
	_expect(int(L.settle(4, 0, [false], false, true)["level"]) == 4, "累计组 lv4 两胜不升")
	_expect(int(L.settle(4, 2, [false, false], false, true)["level"]) == 5, "累计组 lv4 三胜不等五局满")
	var slid: Dictionary = L.settle(4, 0, [false, false, true, true, true], false, true)
	_expect(int(slid["level"]) == 3, "累计组旧胜局滑出后剩两胜三败，应降档")
	for level: int in [1, 2]:
		_expect(int(L.settle(level, 0, [], false, true)["level"]) == level, "低档一胜不升")
		_expect(int(L.settle(level, 1, [false], false, true)["level"]) == level + 1, "低档仍两局两胜升级")



func _test_experiment_invariants() -> void :
	for flags: Array in [[false, false], [false, true], [true, false]]:
		var easy: bool = bool(flags[0])
		var four: bool = bool(flags[1])
		_expect(int(L.settle(5, 4, [false, false, false, false], false, easy, four)["level"]) == 5, 
			"所有组 lv5 封顶")
		_expect(int(L.settle(1, 0, [true], true, easy, four)["level"]) == 1, "所有组 lv1 封底")
		var history: Array = [false, false, false, false]
		var promoted: Dictionary = L.settle(4, 4, history, false, easy, four)
		_expect(history == [false, false, false, false], "结算不得改输入窗口")
		_expect(int(promoted["level"]) == 5, "各组晋级成功")
		_expect((promoted["recent_dirty"] as Array).is_empty() and int(promoted["clean_streak"]) == 0, 
			"各组晋级清空窗口与连胜")
	for level: int in [2, 3, 4, 5]:
		var n: int = L.n_of(level)
		var history: Array = []
		for _i: int in range(n / 2):
			history.append(true)
		_expect(L.settle(level, 0, history, true, true) == L.settle(level, 0, history, true), 
			"累计组 lv%d 原降级边界不变" % level)

func _expect(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)
		print("[FAIL] %s" % msg)


func _finish() -> void :
	if _failures.is_empty():
		print("PASS")
		quit(0)
		return
	print("FAIL (%d)" % _failures.size())
	quit(1)
