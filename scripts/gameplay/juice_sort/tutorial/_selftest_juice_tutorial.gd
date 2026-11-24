extends SceneTree












const T: = preload("res://scripts/gameplay/juice_sort/tutorial/juice_tutorial_script.gd")
const R: = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")




var MG: GDScript = null

var _ok: = true
var _checks: = 0


func _initialize() -> void :
	MG = load("res://scripts/gameplay/juice_sort/tutorial/juice_mystery_guide.gd") as GDScript
	var lv: JuiceLevel = T.build_level()
	_chk("教学题面合法", lv.validate().is_empty(), str(lv.validate()))
	var st: Dictionary = R.make_state(lv)
	var steps: Array[Dictionary] = T.steps_for()
	_chk("每列4朵花", lv.capacity == 4)
	_chk("教学示例解法7次操作", steps.size() == 7)
	_chk("教学五列一个白盆四目标", lv.columns == 5 and lv.groups_total == 4 and lv.types == 4)
	var connect_heads: Array[int] = []
	var empty_sizes: Array[int] = []
	var expected_done: Array[int] = [0, 0, 1, 2, 2, 3, 4]
	_chk("只有一个白盆", (st.jars as Array).count(-1) == 1)
	for i: int in steps.size():
		var step: Dictionary = steps[i]
		var src: int = int(step.src)
		var j: int = int(step.j)
		var dst: int = int(step.dst)
		var segment: Array = (st.cols[src] as Array).slice(j)
		if i < 2:
			_chk("示范拿起混色段", segment.size() >= 2 and segment.any( func(t: int) -> bool: return t != int(segment[0])))
			if i < 2:
				connect_heads.append(int(segment[0]))
				var target: Array = st.cols[dst]
				_chk("混色段连接处同色", not target.is_empty() and int(target[-1]) == int(segment[0]))
		if i in [2, 4]:
			empty_sizes.append(segment.size())
			_chk("黄色整列提示配对，蓝花暂存提示空绳", String(step.idle) == ("JUICE_TUTOR_STEP2" if i == 2 else "JUICE_TUTOR_STEP3") and String(step.drag) == String(step.idle))
			_chk("目标绳实际为空", (st.cols[dst] as Array).is_empty() and not bool(st.gone[dst]))
		if i == 3:
			_chk("第二次继续引导整串红花配对红盆", src == 0 and dst == 1 and j == 0 and segment == [0, 0, 0, 0] and int(st.jars[dst]) == 0 and String(step.idle) == "JUICE_TUTOR_STEP2")
		if i == 5:
			_chk("空绳教学后自由收集剩余两盆", T.SCRIPTED_STEPS == 5 and bool(step.get("free", false)) and String(step.idle) == "JUICE_TUTOR_FREE")
		if i == 4:
			_chk("连续收齐黄盆和红盆腾出白绳再引导", int(st.done) == 2)
			_chk("空绳目标为空且在场", (st.cols[dst] as Array).is_empty() and not bool(st.gone[dst]), JSON.stringify(st.cols))
			_chk("只拿末尾蓝花腾出紫花", segment.size() == 1 and int(segment[0]) == 1 and j == (st.cols[src] as Array).size() - 1)
			_chk("蓝花暂存空白绳", int(st.jars[dst]) < 0)
		_chk("不安排白绳之间整串绕路", not (int(st.jars[src]) < 0 and int(st.jars[dst]) < 0) or (i == 4 and segment.size() == 1))
		_chk("两次混色连接与连续两次收盆保留可选聚焦标记", bool(step.get("focus", false)) == (i <= 3))
		_chk("前5步引导，后续自由收集", bool(step.get("free", false)) == (i >= T.SCRIPTED_STEPS))
		_chk("示例抓取合法", T.is_scripted_grab(i, src, j))
		_chk("指定移动门控", T.is_scripted_move(i, src, j, dst))
		_chk("非指定移动门控拒绝", not T.is_scripted_move(i, src, j, src))
		var k: int = R.move_info(st, src, j, dst)
		if not _chk("步%d规则合法" % i, k > 0, "move_info=%d" % k):
			break
		var rec: Dictionary = R.apply_move(st, lv, src, j, dst)
		if not _chk("指定移动执行成功", not rec.is_empty()):
			break
		if i == 4:
			_chk("空绳腾色后下一步接回紫花收盆", int(steps[i + 1].dst) == src and R.move_info(st, int(steps[i + 1].src), int(steps[i + 1].j), src) > 0)
		_chk("收盆步骤明确", (rec.get("deposits", []) as Array).size() == (1 if bool(step.get("collect", false)) else 0))
		_chk("步%d累计收盆数" % i, int(st.done) == expected_done[i])
		_chk("全部收齐才教学通关", R.is_win(st, lv) == (i == steps.size() - 1))
	_chk("两次连接段头颜色不同", connect_heads.size() == 2 and connect_heads[0] != connect_heads[1])
	_chk("移入空绳分别搬整串黄花和末尾蓝花", empty_sizes == [4, 1], str(empty_sizes))
	_chk("四盆全部完成", int(st.done) == lv.groups_total and lv.groups_total == 4)
	var st2: Dictionary = R.make_state(lv)
	_chk("合法但走偏 → FOLLOW", T.why_key(st2, 2, 2, 3) == "JUICE_TUTOR_WHY_FOLLOW")
	_chk("颜色接不上 → COLOR", T.why_key(st2, 2, 3, 3) == "JUICE_TUTOR_WHY_COLOR")
	_chk("目标装不下 → FULL", T.why_key(st2, 2, 0, 3) == "JUICE_TUTOR_WHY_FULL")
	var full_st: Dictionary = st2.duplicate(true)
	(full_st.cols[3] as Array).push_front(2)
	_chk("色对但装不下先判FULL", T.why_key(full_st, 2, 2, 3) == "JUICE_TUTOR_WHY_FULL")
	_chk("原地放下 → FOLLOW", T.why_key(st2, 3, 0, 3) == "JUICE_TUTOR_WHY_FOLLOW")

	_test_mystery_reveal_move()
	_test_entrance_lock(lv)
	_finish()






func _test_mystery_reveal_move() -> void :


	var lv: JuiceLevel = JuiceLevel.from_dict({
		"id": 1, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|?0,1", "1|1"], 
		"incoming": ["-|0"], 
	})
	_chk("问号题面合法", lv.validate().is_empty(), str(lv.validate()))
	var order: Array[int] = [0, 1, 2]
	var st: Dictionary = R.make_state(lv)
	var mv: Dictionary = MG.find_reveal_move(st, order)
	_chk("找得出揭开问号的一步", not mv.is_empty())
	if not mv.is_empty():
		_chk("选中的是问号所在列", int(mv["src"]) == 1, "实际 src=%d" % int(mv["src"]))
		_chk("切点在问号下方一位", int(mv["j"]) == 1, "实际 j=%d" % int(mv["j"]))
		_chk("选中的一步真的合法", 
			R.move_info(st, int(mv["src"]), int(mv["j"]), int(mv["dst"])) > 0)

		var rec: Dictionary = R.apply_move(
			st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		var revealed: Array = rec.get("revealed", []) as Array
		_chk("这一步确实显色了", revealed.size() == 1, "实际 %d 颗" % revealed.size())
		if revealed.size() == 1:
			var rv: Dictionary = revealed[0]
			_chk("显色的正是问号那一颗", 
				int(rv.get("col", -1)) == 1 and int(rv.get("index", -1)) == 0, 
				"实际 col=%d index=%d"
					%[int(rv.get("col", -1)), int(rv.get("index", -1))])


	var plain: JuiceLevel = JuiceLevel.from_dict({
		"id": 2, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|0,1", "1|1,0"], "incoming": ["x|"], 
	})
	_chk("无问号题面合法", plain.validate().is_empty(), str(plain.validate()))
	_chk("无问号 ⇒ 空字典", MG.find_reveal_move(R.make_state(plain), order).is_empty())


	var stuck: JuiceLevel = JuiceLevel.from_dict({
		"id": 3, "capacity": 2, "targetCups": 3, 
		"initial": ["0|?0,1", "1|1,2", "2|2,0"], "incoming": ["x|", "x|"], 
	})
	_chk("满盘题面合法", stuck.validate().is_empty(), str(stuck.validate()))
	_chk("下方那段无处可放 ⇒ 空字典", 
		MG.find_reveal_move(R.make_state(stuck), order).is_empty())



	var locked_st: Dictionary = R.make_state(lv)
	(locked_st["locks"] as Array)[1] = {"condition": "collect_count", "count": 2}
	_chk("冰封列里的问号不被选中", MG.find_reveal_move(locked_st, order).is_empty())




func _test_entrance_lock(lv: JuiceLevel) -> void :
	var board_script: GDScript = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd")
	var board: Node = board_script.new()
	board.set("_level", lv)
	board.set("_state", R.make_state(lv))
	_chk("正常盘面允许拖花", board._can_play())
	board.set_entrance_lock(true)
	_chk("入场锁禁止拖花", not board._can_play())
	board.set_input_enabled(false)
	board.set_input_enabled(true)
	_chk("其他流程恢复输入不能提前解除入场锁", not board._can_play())
	board.set_hint_lock(true)
	board.set_hint_lock(false)
	_chk("提示锁解除不能提前解除入场锁", not board._can_play())
	board.set_entrance_lock(false)
	_chk("页面放行后可拖花", board._can_play())
	board.set_input_enabled(false)
	_chk("入场放行不越过其他输入锁", not board._can_play())
	board.free()


func _chk(name: String, cond: bool, extra: String = "") -> bool:
	_checks += 1
	if not cond:
		_ok = false
		print("  ✗ %s%s" % [name, ("  " + extra) if extra != "" else ""])
	return cond


func _finish() -> void :
	print("—— %d 项断言 ——" % _checks)
	print("PASS" if _ok else "FAIL")
	quit(0 if _ok else 1)
