extends SceneTree


const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const P = preload("res://scripts/gameplay/juice_sort/core/juice_hint_planner.gd")
var failures: Array[String] = []

func _initialize() -> void :
	_test_rules()
	_test_connection_priority_and_tutorial()
	_test_undo_and_save()
	_test_search()
	_test_closed_cycles()
	_test_runtime_closed_search()
	_test_first_pot_delivery_and_preference()
	_test_first_pot_compression()
	_test_first_pot_state_cap_resume()
	_test_first_pot_complete_dfs()
	_test_first_pot_ready_trigger()
	_test_permutation_closed_cycles()
	_test_empty_permutation_cycles()
	_test_large_permutation_cycles()
	_test_local_grouping_policy()
	_test_grouping_after_retired_slots()
	_test_grouping_with_locked_slots()
	_test_level12_locked_hint_regression()
	_test_level14_deposit_exit_regression()
	_test_ordinary_deposit_exit_boundaries()
	_test_level87_hint_regression()
	_test_level87_video_cycle()
	_test_hint_priority()
	_test_hint_continuity()
	_test_enabled_properties()
	_test_baseline_compatibility()
	print("JUICE_ROOT_SWAPPING_CORE ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void :
	if not ok:
		failures.append(message)
		push_error(message)

func mixed_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 98391, "capacity": 3, "targetCups": 3, 
		"initial": ["0|1,0,2", "1|2,1,0", "2|0,2,1"], "incoming": []})

func winning_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 98392, "capacity": 2, "targetCups": 3, 
		"initial": ["0|1,1", "1|0,0", "2|2,2"], "incoming": []})

func enabled_state(lv: JuiceLevel) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	st["allow_root_swapping"] = true
	return st

func _test_rules() -> void :
	var lv: JuiceLevel = mixed_level()
	check(lv.validate().is_empty(), "测试题面花朵账配平")
	var baseline: Dictionary = R.make_state(lv)
	var st: Dictionary = enabled_state(lv)
	check(R.move_info(baseline, 0, 0, 1) == 0, "关闭实验仍拒绝满列拼接")
	check(R.move_info(st, 0, 0, 1) == 3, "非同色混串、满列允许根部交换")
	for src in 3:
		for j in range(1, 3):
			for dst in 3:
				check(R.move_info(st, src, j, dst) == R.move_info(baseline, src, j, dst), 
					"非根部切点始终保持原规则")
	check(R.move_info(st, 0, 0, 0) == 0 and R.move_info(st, 0, 0, -1) == 0, 
		"同列和越界不能交换")
	check(R.has_any_move(st) and not R.has_any_move(baseline), "死局同步识别根部交换")
	check(R.useful_moves(st).size() == 6, "全满异色列恰有6个有向根部操作")
	var original: String = S._full_state_key(st)
	var jars: Array = (st["jars"] as Array).duplicate()
	var caps: Array = (st["caps"] as Array).duplicate()
	var rec: Dictionary = R.apply_move(st, lv, 0, 0, 1)
	check(bool(rec.get("root_swapped", false)) and st["cols"][0] == baseline["cols"][1]
		and st["cols"][1] == baseline["cols"][0], "交换完整花串，不倒序、不拼接")
	check(st["jars"] == jars and st["caps"] == caps, "花盆和容量固定")
	R.undo_move(st, rec)
	check(S._full_state_key(st) == original, "无收集交换精确撤销")
	for side in [0, 1]:
		var narrow: Dictionary = enabled_state(lv)
		narrow["caps"][side] = 2
		check(R.move_info(narrow, 0, 0, 1) == 0, "任一接收绳容量不足都拒绝")
		check(R.reject_reason(narrow, 0, 0, 1) == R.Reject.FULL, "双向容量错误统一反馈")
		var locked: Dictionary = enabled_state(lv)
		locked["locks"][side] = {"condition": "collect_count", "count": 3}
		check(R.move_info(locked, 0, 0, 1) == 0, "源或目标锁列不交换")
		var retired: Dictionary = enabled_state(lv)
		retired["gone"][side] = true
		check(R.move_info(retired, 0, 0, 1) == 0, "源或目标已退出不交换")
	var empty: Dictionary = enabled_state(lv)
	(empty["cols"][1] as Array[int]).clear()
	check( not R.is_root_swap(empty, 0, 0, 1), "空列仍是搬移不是交换")
	rec = R.apply_move(empty, lv, 0, 0, 1, true)
	check( not bool(rec["root_swapped"]) and (empty["cols"][0] as Array).is_empty()
		and (empty["cols"][1] as Array).size() == 3, "空列完整搬移兼容")
	var partial: Dictionary = enabled_state(lv)
	partial["cols"][0] = [0, 1] as Array[int]
	partial["cols"][1] = [1] as Array[int]
	rec = R.apply_move(partial, lv, 0, 1, 1, true)
	check( not rec.is_empty() and not bool(rec["root_swapped"])
		and partial["cols"][0] == [0] and partial["cols"][1] == [1, 1], "非根部继续同色拼接")

func _test_connection_priority_and_tutorial() -> void :
	var lv: JuiceLevel = mixed_level()
	var st: Dictionary = enabled_state(lv)
	st["cols"][0] = [0, 0] as Array[int]
	st["cols"][1] = [0] as Array[int]
	check( not R.is_root_swap(st, 0, 0, 1) and R.move_info(st, 0, 0, 1) == 2, 
		"根部同色且容量足够时优先原连接规则")
	var rec: Dictionary = R.apply_move(st, lv, 0, 0, 1, true)
	check( not bool(rec["root_swapped"]) and st["cols"][0] == [] and st["cols"][1] == [0, 0, 0], 
		"两朵接一朵形成满串而非互换")
	R.undo_move(st, rec)
	check(st["cols"][0] == [0, 0] and st["cols"][1] == [0], "根部连接按普通搬移撤销")
	st["cols"][1] = [0, 0] as Array[int]
	check(R.is_root_swap(st, 0, 0, 1) and R.move_info(st, 0, 0, 1) == 2, 
		"同色但拼接容量不足时仍允许整串交换")
	st["cols"][0] = [0] as Array[int]
	st["cols"][1] = [1] as Array[int]
	check(R.is_root_swap(st, 0, 0, 1) and R.move_info(st, 0, 0, 1) == 1, 
		"不同色且双方装得下时允许交换")
	st["cols"][0] = [0, 1] as Array[int]
	st["cols"][1] = [0] as Array[int]
	check( not R.is_root_swap(st, 0, 0, 1), "杂色花串原本可连接时也不覆盖旧规则")
	lv = JuiceTutorialScript.build_level()
	st = enabled_state(lv)
	var expected_collected: int = 0
	for index in JuiceTutorialScript.STEPS.size():
		var step: Dictionary = JuiceTutorialScript.STEPS[index]
		var control: Dictionary = R.clone_state(st)
		control["allow_root_swapping"] = false
		var control_rec: Dictionary = R.apply_move(control, lv, int(step["src"]), int(step["j"]), int(step["dst"]))
		rec = R.apply_move(st, lv, int(step["src"]), int(step["j"]), int(step["dst"]))
		check( not rec.is_empty() and not bool(rec.get("root_swapped", false)), "教学指定步骤保持原搬移")

		expected_collected += int(step.get("collect", (control_rec["deposits"] as Array).size()))
		check(int(st["done"]) == expected_collected and st["cols"] == control["cols"], 
			"教学每步收盆与脚本/原连接规则一致")
		if not R.is_win(st, lv):
			check(R.has_any_move(st) and not S.is_closed_cycle(st, lv), "教学每步后可继续，不误入循环死局")
	check(expected_collected > 0 and int(st["done"]) == expected_collected, 
		"完整教学按当前STEPS累计收盆，不硬编码题面容量或旧步骤数")

func _test_undo_and_save() -> void :
	var lv: JuiceLevel = winning_level()
	check(lv.validate().is_empty(), "收集测试题面合法")
	var st: Dictionary = enabled_state(lv)
	var before: String = S._full_state_key(st)
	var rec: Dictionary = R.apply_move(st, lv, 0, 0, 1)
	check(bool(rec["root_swapped"]) and (rec["deposits"] as Array).size() == 3
		and R.is_win(st, lv), "一次交换走正常级联收盆和通关")
	R.undo_move(st, rec)
	check(S._full_state_key(st) == before, "收盆快照还原后再逆交换")
	var decoded: Dictionary = R.state_from_dict(JSON.parse_string(JSON.stringify(R.state_to_dict(st))), lv)
	check( not decoded.is_empty() and S._full_state_key(decoded) == before, "JSON续局保留规则与盘面")
	var old: Dictionary = R.state_to_dict(st)
	old.erase("allow_root_swapping")
	check( not bool(R.state_from_dict(old, lv)["allow_root_swapping"]), "老存档缺规则字段默认关闭")
	check(bool(R.clone_state(st)["allow_root_swapping"]), "求解深拷贝保留实验规则")
	var control: Dictionary = R.clone_state(st)
	control["allow_root_swapping"] = false
	check(R.state_key(control) != R.state_key(st), "规则差异隔离缓存指纹")

	lv = mixed_level()
	for keep: bool in [false, true]:
		st = enabled_state(lv)
		st["cols"][0][2] = JuiceLevel.HIDDEN_BASE + 2
		st["cols"][1][2] = JuiceLevel.HIDDEN_BASE
		before = S._full_state_key(st)
		rec = R.apply_move(st, lv, 0, 0, 1, true)
		check((rec["revealed"] as Array).size() == 2, "交换后两列隐藏尾走正常显色")
		check(R.undo_move(st, rec, keep) == 2, "两串问号按交换后的列号映射统计")
		if keep:
			check(st["cols"][0][2] == 2 and st["cols"][1][2] == 0, "记忆组两个原花串都保留真色")
		else:
			check(S._full_state_key(st) == before, "对照组两个原花串都重新盖住")

func _test_search() -> void :
	var lv: JuiceLevel = mixed_level()
	var st: Dictionary = enabled_state(lv)
	var before: String = S._full_state_key(st)
	for mv: Dictionary in P.all_moves(st):
		var cur: Dictionary = P.clone_search(st)
		var rec: Dictionary = R.apply_move(cur, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
		P.undo_search(cur, rec)
		check(S._full_state_key(cur) == before, "提示搜索所有交换可精确回滚")
	check(P.lower_bound(st, lv) == 0 and S.hint_lower_bound(st, 0, lv) == 0
		and S.sort_lower_bound(st) == 0, "实验不套用单向拼接下界误剪枝")
	var forbid: Dictionary = {"src": 1, "dst": 0, "k": 3, "root_swapped": true}
	check(S.is_forbidden(st, {"src": 0, "j": 0, "dst": 1}, forbid)
		and S.is_forbidden(st, {"src": 1, "j": 0, "dst": 0}, forbid), "交换逆操作与抓取方向无关")
	check( not S.is_forbidden(st, {"src": 1, "j": 1, "dst": 0}, forbid), "交换忌讳不误伤部分搬移")
	S.move_score(st, {"src": 0, "j": 0, "dst": 1})
	S.group_score(st, {"src": 0, "j": 0, "dst": 1}, 0)
	check(S._full_state_key(st) == before, "交换评分不污染输入")
	lv = winning_level()
	st = enabled_state(lv)
	var path: Array = [{"src": 0, "j": 0, "dst": 1}]
	var hint: Dictionary = S._checked_path_hint(st, lv, path)
	check( not hint.is_empty() and int(hint["len"]) == 1 and bool(hint["win_path"]), 
		"交换路线通过真实重放并作为可通关提示")
	check(S.group_score(st, path[0], 0) > 0.0 and S.group_score(st, path[0], 1) > 0.0, 
		"评分同时识别源盆与目标盆的收集收益")

func screenshot_state(lv: JuiceLevel) -> Dictionary:
	var st: Dictionary = enabled_state(lv)
	st["cols"] = [[1, 1] as Array[int], [5, 5, 5, 5] as Array[int], 
		[2, 0, 8, 3, 3] as Array[int], [8, 8, 8] as Array[int], 
		[3, 0] as Array[int], [2, 2, 2, 2] as Array[int]]
	st["jars"] = [-1, 5, 0, 8, 1, 2] as Array[int]
	st["caps"] = [5, 5, 5, 5, 5, 5] as Array[int]
	st["gone"] = [false, false, false, false, false, false] as Array[bool]
	st["locks"] = [{}, {}, {}, {}, {}, {}]
	st["done"] = 4
	st["cups"] = [4, 6, 7, 1] as Array[int]
	return st


func exhaustive_closed(st: Dictionary, lv: JuiceLevel, cap: int = 4000) -> Dictionary:
	if R.any_ready(st):
		return {"closed": false, "no_deposit": false, "states": 1}
	var keys: Dictionary = {S._full_state_key(st): 0}
	var states: Array[Dictionary] = [R.clone_state(st)]
	var reverse: Array = [[] as Array[int]]
	var index: int = 0
	while index < states.size():
		for mv: Dictionary in R.useful_moves(states[index]):
			var next: Dictionary = R.clone_state(states[index])
			R.apply_move(next, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
			if R.any_ready(next):
				return {"closed": false, "no_deposit": false, "states": states.size()}
			var key: String = S._full_state_key(next)
			if not keys.has(key):
				if states.size() >= cap:
					return {"unknown": true, "states": states.size()}
				keys[key] = states.size()
				states.append(next)
				reverse.append([] as Array[int])
			(reverse[int(keys[key])] as Array[int]).append(index)
		index += 1
	var reached: Dictionary = {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		for prior: int in reverse[queue.pop_back()]:
			if not reached.has(prior):
				reached[prior] = true
				queue.append(prior)
	return {"closed": reached.size() == states.size(), "no_deposit": true, "states": states.size()}

func _test_closed_cycles() -> void :
	var lv: JuiceLevel = mixed_level()
	var st: Dictionary = screenshot_state(lv)
	var before: String = S._full_state_key(st)
	var truth: Dictionary = exhaustive_closed(st, lv)
	check(bool(truth.get("closed", false)) and int(truth["states"]) == 720, 
		"用户第4关截图真实穷尽720排列，全部无法合并或收盆且互相可达")
	check(S.is_closed_cycle(st, lv), "实验纯互换720状态死局不再漏判")
	check(S._full_state_key(st) == before, "死局检查不修改真实盘面")
	for mechanism: String in ["hidden", "frozen", "lock", "sunlight"]:
		var special: Dictionary = R.clone_state(st)
		var special_level: JuiceLevel = mixed_level()
		match mechanism:
			"hidden": special["cols"][0][0] = JuiceLevel.HIDDEN_BASE + 1
			"frozen": special["cols"][0][0] = JuiceLevel.FROZEN_BASE + 1
			"lock": special["locks"][0] = {"condition": "collect_count", "count": 5}
			"sunlight": special_level.sunlight_type = 1
		check( not S._is_root_swap_only_cycle(special, special_level), "特殊机制不套纯交换证明：" + mechanism)
	var control: Dictionary = R.clone_state(st)
	control["allow_root_swapping"] = false
	check( not R.has_any_move(control), "截图对照组仍走原无合法移动判死")
	var expired: Dictionary = {"now": func() -> int: return 10, "deadline": 1, "clock_every": 1}
	check( not S.is_closed_cycle(st, lv, expired) and bool(expired.get("aborted", false)), 
		"超时仍返回未知，不把取消当死局证明")

	st = enabled_state(lv)
	st["cols"] = [[0, 0] as Array[int], [1, 0] as Array[int], [2] as Array[int]]
	st["caps"] = [2, 2, 3] as Array[int]
	st["jars"] = [1, 2, 0] as Array[int]
	check( not S.is_closed_cycle(st, lv), "变容量交换后可把0段接到大容量列，不误判纯交换死局")
	R.apply_move(st, lv, 0, 0, 2, true)
	check(R.move_info(st, 1, 1, 2) == 1 and not R.is_root_swap(st, 1, 1, 2), 
		"换到大容量后确实出现普通连接出口")
	lv = winning_level()
	st = enabled_state(lv)
	check( not S.is_closed_cycle(st, lv), "满纯色串错盆但交换可收盆时不判死")

	lv = mixed_level()
	var exhaustive_count: int = 0
	for shape in 64:
		for jars in 8:
			st = enabled_state(lv)
			for ci in 3:
				var pair: int = (shape >> (ci * 2)) & 3
				st["cols"][ci] = [pair & 1, (pair >> 1) & 1] as Array[int]
				st["caps"][ci] = 2
				st["jars"][ci] = (jars >> ci) & 1
			truth = exhaustive_closed(st, lv)
			check(S.is_closed_cycle(st, lv) == bool(truth["closed"]), 
				"满串小盘面生产判据与独立穷尽真值一致")
			var runtime: Dictionary = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
			check(String(runtime["status"]) == ("CLOSED" if bool(truth["no_deposit"]) else "EXIT"), 
				"runtime分片判据与满串独立穷尽真值一致")
			exhaustive_count += 1
	var rng: = RandomNumberGenerator.new()
	rng.seed = 393939
	var checked: int = 0
	for sample in 160:
		st = enabled_state(lv)
		for ci in 3:
			st["caps"][ci] = rng.randi_range(2, 3)
			st["jars"][ci] = rng.randi_range(-1, 2)
			var col: Array[int] = []
			for _i in rng.randi_range(0, st["caps"][ci]):
				col.append(rng.randi_range(0, 2))
			st["cols"][ci] = col
		truth = exhaustive_closed(st, lv, 1500)
		if not bool(truth.get("unknown", false)):
			check(S.is_closed_cycle(st, lv) == bool(truth["no_deposit"]), 
				"随机混串/空列/变容量：判死必须有真实封闭图证明")
			var runtime: Dictionary = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
			check(String(runtime["status"]) == ("CLOSED" if bool(truth["no_deposit"]) else "EXIT"), 
				"runtime混串/空列/变容量与独立穷尽真值一致")
			checked += 1
	check(checked >= 100, "随机独立穷尽覆盖至少100盘")
	print("ROOT_SWAP_CYCLE_ORACLE exhaustive=", exhaustive_count, " random=", checked, " screenshot=720")



func level19_visible_state(lv: JuiceLevel) -> Dictionary:
	var st: Dictionary = enabled_state(lv)
	st["cols"] = [[1] as Array[int], [2] as Array[int], [] as Array[int], [] as Array[int], 
		[3, 0, 0, 0] as Array[int], [3, 3, 3] as Array[int], [JuiceLevel.HIDDEN_BASE + 2, 4] as Array[int]]
	st["caps"] = [4, 4, 4, 4, 4, 4, 4] as Array[int]
	st["jars"] = [-1, 3, 0, 1, 2, 4, 0] as Array[int]
	st["gone"] = [false, false, false, false, false, false, false] as Array[bool]
	st["locks"] = [{}, {}, {"condition": "collect_type", "typeId": 5, "count": 1}, 
		{"condition": "collect_type", "typeId": 3, "count": 1}, {}, {}, {}]
	return st


func _test_runtime_closed_search() -> void :
	var lv: JuiceLevel = mixed_level()
	var st: Dictionary = level19_visible_state(lv)
	var before: String = S.root_closed_state_key(st)
	var ctx: Dictionary = S.begin_root_closed_search(st, lv)
	check(String(ctx["phase"]) == "initial" and int(ctx["expanded"]) == 0, 
		"begin只初始化，严格证明不在主线程执行")
	var result: Dictionary = S.advance_root_closed_search(ctx)
	check(String(result["status"]) == "CLOSED" and String(result["reason"]) == "swap_only"
		and bool(result["closed"]) and bool(result["completed"]) and not bool(result["continuable"]), 
		"第19关锁门/被压问号投影严格快证，不受真实排列枚举耗时影响")
	check(S.root_closed_state_key(st) == before, "runtime快证不修改玩家盘面")
	st["cols"][2] = [JuiceLevel.HIDDEN_BASE + 5] as Array[int]
	check(S._root_inert_swap_only_cycle(st, lv), "锁列尾问号显色不会提供首盆出口")
	for mechanism: String in ["tail_hidden", "frozen", "frozen_pot", "sunlight", "unknown_lock", "empty"]:
		var special: Dictionary = R.clone_state(st)
		var special_level: JuiceLevel = mixed_level()
		match mechanism:
			"tail_hidden": special["cols"][0][0] = JuiceLevel.HIDDEN_BASE + 1
			"frozen": special["cols"][0][0] = JuiceLevel.FROZEN_BASE + 1
			"frozen_pot": special["frozen_pots"] = [true, false, false, false, false, false, false] as Array[bool]
			"sunlight": special_level.sunlight_type = 1
			"unknown_lock": special["locks"][2] = {"condition": "future_mechanic", "count": 1}
			"empty": (special["cols"][0] as Array).clear()
		check( not S._root_inert_swap_only_cycle(special, special_level), "惰性快证保守回退：" + mechanism)
	lv = winning_level()
	st = enabled_state(lv)
	st["jars"][2] = -1
	check( not R.any_ready(st) and not S._root_inert_swap_only_cycle(st, lv), 
		"错盆满纯色串可交换收盆，不能仅因当前无普通移动判死")
	result = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(String(result["status"]) == "EXIT" and not bool(result["closed"]), "真实交换收盆出口返回EXIT")
	st["cols"][0] = [1, JuiceLevel.HIDDEN_BASE + 1] as Array[int]
	check( not S._root_inert_swap_only_cycle(st, lv), "未锁自由端问号不得当作不变花串")
	result = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(String(result["status"]) == "EXIT", "交换显色后形成满纯色串的真实出口不误杀")
	lv = mixed_level()
	st = enabled_state(lv)
	st["cols"] = [[0, 0] as Array[int], [1, 0] as Array[int], [2] as Array[int]]
	st["caps"] = [2, 2, 3] as Array[int]
	st["jars"] = [1, 2, 0] as Array[int]
	check( not S._root_inert_swap_only_cycle(st, lv), "任意排列下的大容量普通切点必须阻止快证")
	result = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(String(result["status"]) == "EXIT", "变容量准备交换后的真实出口返回EXIT")
	st = enabled_state(lv)
	st["cols"] = [[0, 1] as Array[int], [1, 0] as Array[int], [] as Array[int]]
	st["caps"] = [2, 2, 2] as Array[int]
	st["jars"] = [0, 1, -1] as Array[int]
	st["gone"][2] = true
	check( not S._root_inert_swap_only_cycle(st, lv), "gone但容量仍正的异常空列不能被快证忽略")
	result = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(String(result["status"]) == "EXIT", "异常退休空列仍按真实move_info保留可搬入出口")

	st = enabled_state(lv)
	var whole: Dictionary = S.advance_root_closed_search(S.begin_root_closed_search(st, lv), 8, 
		{"skip_fast_proof": true})
	ctx = S.begin_root_closed_search(st, lv)
	var ticks: Array[int] = [0]
	var clock: Callable = func() -> int:
		ticks[0] += 1
		return ticks[0]
	var slices: int = 0
	var previous_states: int = 0
	var previous_candidates: int = 0
	while slices < 1000:
		result = S.advance_root_closed_search(ctx, 8, {"now": clock, "skip_fast_proof": true})
		slices += 1
		check(int(result["states"]) >= previous_states and int(result["candidates"]) >= previous_candidates, 
			"短片续算累计状态和切点不清零")
		previous_states = int(result["states"])
		previous_candidates = int(result["candidates"])
		if not bool(result["continuable"]):
			break
		check(String(result["status"]) == "UNKNOWN" and String(result["reason"]) == "deadline"
			and not bool(result["closed"]), "时间片不足只返回可续UNKNOWN")
	check(slices > 1 and String(result["status"]) == "CLOSED"
		and int(result["candidates"]) == int(whole["candidates"]), "真实图续算不漏边也不重跑已处理切点")
	ctx = S.begin_root_closed_search(st, lv, 1)
	result = S.advance_root_closed_search(ctx, 8, {"skip_fast_proof": true})
	check(String(result["status"]) == "UNKNOWN" and String(result["reason"]) == "state_cap"
		and not bool(result["continuable"]) and int(result["states"]) == 1, 
		"累计上限触顶终止UNKNOWN，不每帧无限重投")
	check(S.advance_root_closed_search(ctx) == result, "终止UNKNOWN不会在下一片重跑")
	var control: Dictionary = R.clone_state(st)
	control["allow_root_swapping"] = false
	result = S.advance_root_closed_search(S.begin_root_closed_search(control, lv))
	check(String(result["status"]) == "UNKNOWN" and not bool(result["continuable"]), 
		"对照组不会进入新增runtime判死入口")

	lv = level7_cycle_level()
	st = level7_cycle_state(lv)
	ctx = S.begin_root_closed_search(st, lv)
	ticks[0] = 0
	slices = 0
	while slices < 1000:
		result = S.advance_root_closed_search(ctx, 8, {"now": clock})
		slices += 1
		if not bool(result["continuable"]):
			break
	check(slices > 1 and String(result["status"]) == "CLOSED" and String(result["reason"]) == "permutation"
		and int(result["states"]) == 2, "第7关可续超图保留两形态证明，不能退化到10080排列超过8000")

func level7_cycle_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 7, "capacity": 5, "targetCups": 12, 
		"initial": ["-|", "6|6,?6,?5,4", "7|6,1,?1,3", "5|5,?7,6,?7,5", 
			"1|4,?3,7,1", "3|5,7,3,1", "4|4,5,7,?4,6"], 
		"incoming": ["8|8,?8,?1,3,4", "0|0,0,?3,8,1", "9|9,1,8,0", 
			"1|1,?9,?8,5,3", "5|5,?5,9,1,0", "3|3,3,?0,5,9", "-|3,1,9,3,5"]})

func level7_cycle_state(lv: JuiceLevel) -> Dictionary:
	var st: Dictionary = enabled_state(lv)
	st["cols"] = [[4, 4] as Array[int], [6, 6, 6, 6] as Array[int], 
		[6, 1, 1, 1, 1] as Array[int], [5, 7, 7, 7, 7] as Array[int], 
		[4, 3, 3, 3] as Array[int], [5, 7] as Array[int], [4, 5, 5, 5] as Array[int]]
	return st

func _test_permutation_closed_cycles() -> void :
	var lv: JuiceLevel = level7_cycle_level()
	check(lv.validate().is_empty(), "第7关完整真实题面合法，保留后备问号")
	var st: Dictionary = level7_cycle_state(lv)
	var before: String = S._full_state_key(st)
	var opts: Dictionary = {"now": Time.get_ticks_msec, "deadline": Time.get_ticks_msec() + 120, 
		"state_cap": 2}
	check(S.is_closed_cycle(st, lv, opts) and not bool(opts.get("aborted", false)), 
		"第7关10080排列合并后仅2形态，120ms且2状态预算内严格证明死局")
	check(S._full_state_key(st) == before, "合并证明不更改玩家盘面或实验开关")
	var limited: Dictionary = {"state_cap": 1}
	check( not S.is_closed_cycle(st, lv, limited) and bool(limited.get("aborted", false)), 
		"尚有第二形态未遍历时不得因状态预算耗尽判死")
	var ticks: Array[int] = [0]
	var interrupted: Dictionary = {"now": func() -> int:
		ticks[0] += 1
		return 100 if ticks[0] >= 50 else 0, "deadline": 10}
	check( not S.is_closed_cycle(st, lv, interrupted) and bool(interrupted.get("aborted", false)), 
		"合并图枚举中途超时不得提交不完整的死局证明")
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800, 
		"forbid": {"src": 3, "dst": 5, "k": 3, "root_swapped": false}}, result)
	check(int(result["reachability"]) == S.Reachability.UNWINNABLE
		and String(result["stop_reason"]) == "dead" and (result["hint"] as Dictionary).is_empty(), 
		"第7关正式Hint返回已证明无解，不再空Hint却UNKNOWN")
	var cancel: = Semaphore.new()
	cancel.post()
	result = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "cancel": cancel}, result)
	check(int(result["reachability"]) == S.Reachability.UNKNOWN and String(result["stop_reason"]) == "cancelled", 
		"取消Hint不得发布合并图死局结果")
	var control: Dictionary = R.clone_state(st)
	control["allow_root_swapping"] = false
	var truth: Dictionary = exhaustive_closed(control, lv)
	check(bool(truth["closed"]) and int(truth["states"]) == 4 and S.is_closed_cycle(control, lv), 
		"第7关对照仍按原4状态强连通规则证明死局")
	for mechanism: String in ["hidden", "frozen", "lock", "sunlight", "variable", "retired", "frozen_pot", "empty"]:
		var special: Dictionary = R.clone_state(st)
		var special_level: JuiceLevel = level7_cycle_level()
		match mechanism:
			"hidden": special["cols"][0][0] = JuiceLevel.HIDDEN_BASE + 4
			"frozen": special["cols"][0][0] = JuiceLevel.FROZEN_BASE + 4
			"lock": special["locks"][0] = {"condition": "collect_count", "count": 1}
			"sunlight": special_level.sunlight_type = 4
			"variable": special["caps"][0] = 6
			"retired": special["gone"][0] = true
			"frozen_pot": special["frozen_pots"] = [true, false, false, false, false, false, false] as Array[bool]
			"empty": (special["cols"][0] as Array).clear()
		check( not S._root_permutation_closed_without_deposit(special, special_level, {}), 
			"不满足排列对称条件时回退真实搜索：" + mechanism)

	for capacity: int in [3, 5]:
		lv = JuiceLevel.from_dict({"id": 98407, "capacity": capacity, 
			"targetCups": 2 if capacity == 3 else 3, 
			"initial": ["-|0,0", "1|1,0", "0|1,1"] if capacity == 3
				else ["-|0,0,0", "0|1,1,1,0", "1|2,2,2,0"], 
			"incoming": ["x"] if capacity == 3 else ["2|1,1,2,2", "x"]})
		check(lv.validate().is_empty(), "普通连接后换位收盆的反例题面合法")
		st = enabled_state(lv)
		check( not R.any_ready(st) and not S.is_closed_cycle(st, lv), 
			"合并图不得误判经普通连接后才能换位收盆的活盘")
		R.apply_move(st, lv, 1, capacity - 2, 0, true)
		if capacity == 5:
			R.apply_move(st, lv, 2, 3, 0, true)
		check( not R.any_ready(st) and S._root_permutation_has_deposit(st), 
			"满纯色串仍在错盆时必须识别可换位收集出口")
		R.apply_move(st, lv, 0, 0, 2 if capacity == 3 else 1, true)
		check(R.any_ready(st), "反例真实根部交换后能收盆")
	print("ROOT_SWAP_PERMUTATION_CYCLE level7=2 control=4 counterexamples=2")


func _test_empty_permutation_cycles() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 98487, "capacity": 3, "targetCups": 2, 
		"initial": ["-|", "0|0,1", "1|1,0"], "incoming": ["-|0,1"]})
	check(lv.validate().is_empty(), "含空列排列证明题面合法：" + str(lv.validate()))
	var st: Dictionary = enabled_state(lv)
	var before: String = S.root_closed_state_key(st)
	var truth: Dictionary = exhaustive_closed(st, lv)
	check(bool(truth.get("no_deposit", false)) and int(truth["states"]) == 54, 
		"独立实际图54态穷尽证明含空列死局")
	check(S._root_can_merge_permutations(st, lv) and S._root_permutation_closed_without_deposit(st, lv, {}), 
		"空列不会使等容量无机制盘面退出排列证明")
	var search: Dictionary = S.begin_root_closed_search(st, lv)
	var result: Dictionary = S.advance_root_closed_search(search)
	check(String(result["status"]) == "CLOSED" and String(result["reason"]) == "insufficient_stock"
		and int(result["states"]) == 1, "含空列库存上界不足直接严格判死，不枚举10内容态或54排列")
	check(S.root_closed_state_key(st) == before, "含空列证明不修改玩家盘面")
	check( not S._root_has_deposit_exit(st, lv, {}), "无下一盆的死局不能伪造出口见证")
	var ticks: Array[int] = [0]
	var clock: Callable = func() -> int:
		ticks[0] += 1
		return ticks[0]
	search = S.begin_root_closed_search(st, lv)
	var slices: int = 0
	while slices < 2000:
		result = S.advance_root_closed_search(search, 8, {"now": clock})
		slices += 1
		if not bool(result["continuable"]):
			break
		check( not bool(result["closed"]), "含空列商图分片未完成只发布UNKNOWN")
	check(String(result["status"]) == "CLOSED" and int(result["states"]) == 1, 
		"库存充分证明不受分片时钟影响且不启动排列搜索")
	lv = JuiceLevel.from_dict({"id": 98488, "capacity": 2, "targetCups": 2, 
		"initial": ["-|", "0|0,1", "1|1,0"], "incoming": ["x", "x"]})
	st = enabled_state(lv)
	truth = exhaustive_closed(st, lv)
	check( not bool(truth["no_deposit"]), "同花串容量2的独立实际图确有收盆出口")
	search = S.begin_root_closed_search(st, lv)
	result = S.advance_root_closed_search(search)
	check(String(result["status"]) == "EXIT" and String(search["phase"]) == "permutation"
		and not (result["path"] as Array).is_empty(), 
		"含空列商图直接生成真实首盆路径，不从头回实际排列图")
	print("ROOT_SWAP_EMPTY_PERMUTATION actual=54 stock_proof=1 live_witness=EXIT")



func level87_hint_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 87, "capacity": 5, "targetCups": 11, 
		"initial": ["-|8,8,3,5,0", "1|1,1,0,1", "3|5,5,5,0,1", "5|3,8,3,8,3", "8|", "0|0,0,1"], 
		"incoming": ["7|4,6,3,7,5", "0|2,8,6,7,7", "2|0,7,2,7,4", "6|4,1,0,6,2", 
			"4|6,1,2,4,0", "1|6,1,1,0,2", "-|4,1,0", "x", "x", "x"]})


func level87_hint_state(lv: JuiceLevel, enabled: bool) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	st["cols"] = [[8, 8] as Array[int], [4, 6, 3, 7, 5] as Array[int], 
		[3, 3, 3, 8, 8] as Array[int], [3, 5] as Array[int], [5, 5, 5] as Array[int], 
		[2, 8, 6, 7, 7] as Array[int]]
	st["jars"] = [-1, 7, 3, 5, 8, 0] as Array[int]
	st["done"] = 2
	st["cups"] = [1, 0] as Array[int]
	st["allow_root_swapping"] = enabled
	return st


func _test_level87_hint_regression() -> void :
	var lv: JuiceLevel = level87_hint_level()
	check(lv.validate().is_empty(), "第87关正式lv4题面配平且合法")
	var normal: Dictionary = {}
	S.run_checked_hint_task(level87_hint_state(lv, false), lv, {"now": Time.get_ticks_msec, "ms_cap": 800}, normal)
	var st: Dictionary = level87_hint_state(lv, true)
	var before: String = S.root_closed_state_key(st)
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800}, result)
	var hint: Dictionary = result["hint"]
	check( not (normal["hint"] as Dictionary).is_empty() and not hint.is_empty()
		, "第87关对照及实验800ms预算都可交付真实局部Hint")
	check(S.root_closed_state_key(st) == before, "第87关求提示不改玩家盘面")
	if not hint.is_empty():
		check( not bool(hint.get("root_necessary", true)) and int(hint["len"]) > 0, 
			"第87关实验交付普通缓存可消费的局部收盆路径")
		for mv: Dictionary in hint["path"]:
			var rec: Dictionary = R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			check( not rec.is_empty(), "第87关局部路线逐步实验真实重放")
		check(int(st["done"]) == 3, "第87关局部路线实际完成首次收盆")
		before = S.root_closed_state_key(st)
		check(S._root_has_deposit_exit(st, lv, {}), 
			"首次收盆后局部搜索仍有真实下一盆出口，且不递归安全校验")
		check(S.root_closed_state_key(st) == before, "出口证据只在副本重放")
	check( not S._root_has_deposit_exit(st, lv, 
		{"now": func() -> int: return 10, "deadline": 1}), "出口见证超时不能放行")
	var complete: Dictionary = level87_hint_state(lv, true)
	var followed: Array = _follow_hints(complete, lv, "第87关正式lv4", 100)
	check(R.is_win(complete, lv), "第87关从正式截图起连续局部Hint完成全部补货")
	print("ROOT_SWAP_LEVEL87_HINT control_ms=", normal["elapsed_ms"], " experiment_ms=", result["elapsed_ms"], 
		" steps=", hint.get("len", 0), " source=", result["hint_source"], " whole_steps=", followed.size())




func level87_video_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 98489, "capacity": 5, "targetCups": 11, 
		"initial": ["-|4,6,6", "3|3,3,3", "7|3,3,7,7,7", "0|0,7,7,4", "9|9,9,9", "6|4,1,0,6"], 
		"incoming": ["0|0,0,0,0,0", "0|0,0,0,0,0", "5|5,5,5,5,5", "8|8,8,8,8,8", 
			"1|0,0,0,1,1", "4|1,1,4,4,6", "-|6,9,9", "x", "x", "x"]})



func level87_video_state(lv: JuiceLevel) -> Dictionary:
	var st: Dictionary = enabled_state(lv)
	st["cols"] = [[4, 6, 6] as Array[int], [3, 3, 3] as Array[int], 
		[3, 3, 7, 7, 7] as Array[int], [0, 7, 7, 4] as Array[int], 
		[9, 9, 9] as Array[int], [4, 1, 0, 6] as Array[int]]
	st["jars"] = [-1, 3, 7, 0, 9, 6] as Array[int]
	st["caps"] = [5, 5, 5, 5, 5, 5] as Array[int]
	st["gone"] = [false, false, false, false, false, false] as Array[bool]
	st["locks"] = [{}, {}, {}, {}, {}, {}]
	st["done"] = 4
	st["cups"] = [0, 0, 5, 8] as Array[int]
	return st


func _test_level87_video_cycle() -> void :
	var lv: JuiceLevel = level87_video_level()
	check(lv.validate().is_empty(), "视频视觉关系独立题面配平，不套用截图lv4后备：" + str(lv.validate()))
	var st: Dictionary = level87_video_state(lv)
	var before: String = S.root_closed_state_key(st)
	var started: int = Time.get_ticks_msec()
	var search: Dictionary = S.begin_root_closed_search(st, lv)
	var result: Dictionary = S.advance_root_closed_search(search)
	var elapsed: int = Time.get_ticks_msec() - started
	check(String(result["status"]) == "CLOSED" and String(result["reason"]) == "permutation", 
		"第87关视频末盘面通过排列商图完整证明，无需枚举实际排列")
	check(int(result["states"]) < 80 and S.root_closed_state_key(st) == before, 
		"视频死局商图在80态内完成，保留玩家状态")
	print("ROOT_SWAP_LEVEL87_VIDEO states=", result["states"], " expanded=", result["expanded"], 
		" candidates=", result["candidates"], " runtime_ms=", elapsed)


func oracle_win(st: Dictionary, lv: JuiceLevel) -> int:
	var pending: Array[Dictionary] = [R.clone_state(st)]
	var seen: Dictionary = {JSON.stringify(R.state_to_dict(st)): true}
	var index: int = 0
	while index < pending.size():
		var cur: Dictionary = pending[index]
		index += 1
		if R.is_win(cur, lv):
			return S.Reachability.WINNABLE
		var cols: Array = cur["cols"]
		for src in cols.size():
			for j in (cols[src] as Array).size():
				for dst in cols.size():
					if R.move_info(cur, src, j, dst) <= 0:
						continue
					var after: Dictionary = R.clone_state(cur)
					R.apply_move(after, lv, src, j, dst)
					var key: String = JSON.stringify(R.state_to_dict(after))
					if seen.has(key):
						continue
					if seen.size() >= 16000:
						return S.Reachability.UNKNOWN
					seen[key] = true
					pending.append(after)
	return S.Reachability.UNWINNABLE

func _test_hint_priority() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 98393, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0,1", "1|1,0", "-|"], "incoming": ["x", "x"]})
	var checked: int = 0
	var necessary: int = 0
	var ordinary_wins: int = 0
	var deaths: int = 0
	for shape in 16:
		var bits: int = 0
		for i in 4:
			bits += (shape >> i) & 1
		if bits != 2:
			continue
		for jars in 9:
			var st: Dictionary = enabled_state(lv)
			st["cols"] = [[shape & 1, (shape >> 1) & 1] as Array[int], 
				[(shape >> 2) & 1, (shape >> 3) & 1] as Array[int], [] as Array[int]]
			st["jars"] = [jars % 3 - 1, jars / 3 - 1, 1] as Array[int]
			var ordinary: Dictionary = R.clone_state(st)
			ordinary["allow_root_swapping"] = false
			var normal_truth: int = oracle_win(ordinary, lv)
			var experimental_truth: int = oracle_win(st, lv)
			check(normal_truth != S.Reachability.UNKNOWN and experimental_truth != S.Reachability.UNKNOWN, 
				"独立小盘全图BFS必须完成")
			var before: String = S._full_state_key(st)
			var result: Dictionary = {}
			S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec}, result)
			var hint: Dictionary = result["hint"]
			check(S._full_state_key(st) == before, "玩家Hint不改真实盘面")
			if experimental_truth == S.Reachability.UNWINNABLE:
				check(int(result["reachability"]) != S.Reachability.WINNABLE, 
					"整关无解小盘不能因局部收盆Hint被标为整关WINNABLE")
				if int(result["reachability"]) == S.Reachability.UNWINNABLE:
					check(hint.is_empty(), "严格无首次收盆出口证明不交付Hint")
				deaths += 1
			else:
				check( not hint.is_empty(), "小盘有解必须返回已验证提示")
				if not hint.is_empty():
					var after: Dictionary = R.clone_state(st)
					var has_swap: bool = false
					for mv: Dictionary in hint["path"]:
						var rec: Dictionary = R.apply_move(after, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
						check( not rec.is_empty(), "Hint每一步真实规则合法")
						has_swap = has_swap or bool(rec.get("root_swapped", false))
					check(oracle_win(after, lv) == S.Reachability.WINNABLE, "Hint不会将可赢小盘带入无解")
					if normal_truth == S.Reachability.WINNABLE:
						check( not bool(hint.get("root_necessary", true)), "实验局部路径不依赖普通整关无解证明")
						ordinary_wins += 1
					elif has_swap:
						check( not bool(hint.get("root_necessary", true)) and int(after["done"]) > int(st["done"]), 
							"互换局部完整路线必须真实收盆并供普通缓存消费")
						necessary += 1
			checked += 1

	lv = winning_level()
	var required: Dictionary = enabled_state(lv)
	var control: Dictionary = R.clone_state(required)
	control["allow_root_swapping"] = false
	check(oracle_win(control, lv) == S.Reachability.UNWINNABLE
		and oracle_win(required, lv) == S.Reachability.WINNABLE, "独立全图证明错盆互换必要且可通关")
	var required_result: Dictionary = {}
	S.run_checked_hint_task(required, lv, {"now": Time.get_ticks_msec}, required_result)
	var required_hint: Dictionary = required_result["hint"]
	check( not required_hint.is_empty() and not bool(required_hint.get("root_necessary", true))
		and int(required_hint.get("len", 0)) == 1, "现有纯色满列优先送盆且返回局部缓存路径")
	if not required_hint.is_empty():
		var mv: Dictionary = required_hint["move"]
		var rec: Dictionary = R.apply_move(required, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check(bool(rec.get("root_swapped", false)) and R.is_win(required, lv), "必要互换真实执行完成整关")
		necessary += 1

	lv = JuiceLevel.from_dict({"id": 98394, "schema": "juice-level/4", "capacity": 3, "targetCups": 3, 
		"initial": ["1|0,0", "2|1,0", "0|2"], "incoming": ["-|1,2", "x"], 
		"columnCaps": {"initial": [2, 2, 3], "incoming": [3, 0]}})
	check(lv.validate().is_empty(), "必要准备步变容量题面花账配平：" + str(lv.validate()))
	required = enabled_state(lv)
	control = R.clone_state(required)
	control["allow_root_swapping"] = false
	check(oracle_win(control, lv) == S.Reachability.UNWINNABLE
		and oracle_win(required, lv) == S.Reachability.WINNABLE, "独立全图确认准备互换是整关唯一出路")
	S.run_checked_hint_task(required, lv, {"now": Time.get_ticks_msec}, required_result)
	required_hint = required_result["hint"]
	check( not required_hint.is_empty() and not bool(required_hint.get("root_necessary", true)), 
		"生产800ms预算支持含准备互换的局部收盆路径")
	if not required_hint.is_empty():
		var mv: Dictionary = required_hint["move"]
		var after: Dictionary = R.clone_state(required)
		var rec: Dictionary = R.apply_move(after, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check(bool(rec.get("root_swapped", false)) and (rec["deposits"] as Array).is_empty()
			and oracle_win(after, lv) == S.Reachability.WINNABLE, "准备互换不收盆但保留整关通关路线")
		necessary += 1
	var whole: Array = [{"src": 0, "j": 0, "dst": 2}, {"src": 1, "j": 1, "dst": 2}, 
		{"src": 2, "j": 1, "dst": 0}, {"src": 2, "j": 0, "dst": 1}, {"src": 0, "j": 0, "dst": 1}]
	var loop: Array = [{"src": 0, "j": 0, "dst": 1}, {"src": 1, "j": 0, "dst": 0}]
	var clean: Dictionary = S._checked_path_hint(required, lv, loop + whole, {})
	check( not clean.is_empty() and int(clean["move"]["dst"]) == 2
		and int(clean["len"]) == 2, "局部验算必须剔除无意义互换/逆互换闭环并止于首盆")
	check(ordinary_wins > 0 and necessary > 0 and deaths > 0, "全图真值覆盖普通优先/必要互换/实验无解")

	lv = JuiceLevel.from_dict({"id": 5, "capacity": 5, "targetCups": 12, 
		"initial": ["-|0,5,7,8", "6|6,2,7,0", "2|5,0,6,2", "5|5,0,8", "0|8,8,5", "8|8,6,6,2", "7|7,7,0,5"], 
		"incoming": ["4|4,4,2,7,6", "1|1,1,2,4,6", "3|1,6,3,4", "6|6,3,5,4,2", "5|5,5,6,3,1", "2|2,2,1,5,3", "-|2,5,3,2,6", "x", "x", "x", "x"]})
	var st: Dictionary = enabled_state(lv)
	st["cols"] = [[7, 7, 7, 0] as Array[int], [6, 6, 6, 6] as Array[int], [2, 2, 2] as Array[int], 
		[5, 5, 0, 0, 0] as Array[int], [8, 8, 5, 5] as Array[int], [8, 8, 8] as Array[int], [0, 5, 7] as Array[int]]
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec}, result)
	var hint: Dictionary = result["hint"]
	check( not hint.is_empty(), "截图在生产800ms预算内返回实验局部收盆路线")
	if not hint.is_empty():
		for mv: Dictionary in hint["path"]:
			var rec: Dictionary = R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			check( not rec.is_empty(), "截图整条实验缓存路线真实合法")
		check(int(st["done"]) == 1, "截图路线确实完成第一盆")
	lv = winning_level()
	st = enabled_state(lv)
	var mailbox: S.HintProgress = S.HintProgress.new()
	var cancel: Semaphore = Semaphore.new()
	cancel.post()
	S.run_checked_hint_task(st, lv, {"cancel": cancel, "progress": mailbox}, result)
	check(result["stop_reason"] == "cancelled" and (result["hint"] as Dictionary).is_empty()
		and int(result["reachability"]) == S.Reachability.UNKNOWN, "取消绝不误判死/漏出互换Hint")
	var ticks: Array[int] = [0]
	var clock: Callable = func() -> int:
		ticks[0] += 1
		return ticks[0]
	S.run_checked_hint_task(st, lv, {"now": clock, "ms_cap": 1, "progress": mailbox}, result)
	check((result["hint"] as Dictionary).is_empty() and int(result["reachability"]) == S.Reachability.UNKNOWN, 
		"证明预算不足不猜互换、不扣道具、不判死")
	var frozen: Dictionary = R.clone_state(st)
	frozen["frozen_pots"] = [true, false, false] as Array[bool]
	check( not S._is_root_swap_only_cycle(frozen, lv), "冰盆不套无机制快捷证明")
	check(S._full_state_key(st) != S._full_state_key(frozen), "实验冰盆状态隔离完整搜索/Hint缓存")
	print("ROOT_SWAP_HINT_ORACLE cases=", checked, " ordinary=", ordinary_wins, 
		" necessary=", necessary, " dead=", deaths, " screenshot_steps=", int(hint.get("len", 0)))



func _follow_hints(st: Dictionary, lv: JuiceLevel, label: String, max_steps: int = 40) -> Array:
	var plan: Array = []
	var forbid: Dictionary = {}
	var seen: Dictionary = {}
	var moves: Array = []
	for step in max_steps:
		if R.is_win(st, lv):
			return moves
		var key: String = S._full_state_key(st)
		check( not seen.has(key), label + "连续Hint不得回到旧盘面")
		if seen.has(key):
			return moves
		seen[key] = true
		if plan.is_empty():
			var result: Dictionary = {}
			S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800, 
				"forbid": forbid, "require_complete": true, "verify_safe": false}, result)
			check(S._full_state_key(st) == key, label + "搜索不修改玩家盘面")
			var hint: Dictionary = result["hint"]
			check( not hint.is_empty(), label + "有解盘面必须继续交付Hint：" + str(result["stop_reason"]))
			if hint.is_empty():
				return moves
			plan = (hint["path"] as Array).duplicate(true)
		var mv: Dictionary = plan.pop_front()
		var rec: Dictionary = R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check( not rec.is_empty(), label + "交付动作合法")
		if rec.is_empty():
			return moves
		moves.append({"move": mv, "root_swapped": rec["root_swapped"], "done": st["done"]})
		forbid = {} if not (rec["deposits"] as Array).is_empty() else {
			"src": rec["dst"], "dst": rec["src"], "k": rec["k"], "root_swapped": rec["root_swapped"]}
	check(R.is_win(st, lv), label + "连续Hint必须在预算步数内完成整关")
	return moves


func _test_hint_continuity() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 98401, "capacity": 3, "targetCups": 3, 
		"initial": ["0|2,2,0", "1|0,1,2", "2|1,0"], "incoming": ["-|1", "x"]})
	check(lv.validate().is_empty(), "循环Hint均匀容量题面有效")
	var st: Dictionary = enabled_state(lv)
	var uniform: Array = _follow_hints(st, lv, "均匀容量循环复现")
	check(R.is_win(st, lv), "均匀容量旧两状态循环现在能通关")
	lv = JuiceLevel.from_dict({"id": 98394, "schema": "juice-level/4", "capacity": 3, "targetCups": 3, 
		"initial": ["1|0,0", "2|1,0", "0|2"], "incoming": ["-|1,2", "x"], 
		"columnCaps": {"initial": [2, 2, 3], "incoming": [3, 0]}})
	st = enabled_state(lv)
	var variable: Array = _follow_hints(st, lv, "变容量准备互换")
	check(R.is_win(st, lv), "必要准备交换后逐次Hint能完成补货后的整关")

	lv = JuiceLevel.from_dict({"id": 6, "capacity": 5, "targetCups": 10, 
		"initial": ["-|8,1,4,7", "7|7", "4|1,?7,0,?4,0", "1|?8,?0,1,7", "8|?0,8", "0|1,?8,?4,7"], 
		"incoming": ["5|5,0,?0,?8,5", "0|0,5,5,?0,4", "6|6,2,5,1,2", "3|0,3,6,?3,4", 
			"2|3,6,0,?3,2", "-|3,6,?2,?6,2", "x", "x", "x"]})
	check(lv.validate().is_empty(), "第6关候选题面有效")
	st = enabled_state(lv)
	st["done"] = 4
	st["cups"] = [7, 8, 1, 0] as Array[int]
	st["cols"] = [[5, 5, 5, 5] as Array[int], [2, 2] as Array[int], [5, 0, 0, 0] as Array[int], 
		[6, 6] as Array[int], [4, 4, 4, 4, 4] as Array[int], [0, 3, 3] as Array[int]]
	st["jars"] = [-1, 4, 5, 0, 6, 3] as Array[int]
	var screenshot: Array = _follow_hints(st, lv, "第6关截图")
	check(R.is_win(st, lv) and not screenshot.is_empty(), "截图首盆收集及后续补货全部可完成")
	if not screenshot.is_empty():
		var first: Dictionary = screenshot[0]["move"]
		check(int(first["src"]) == 4 and int(first["dst"]) == 1 and int(screenshot[0]["done"]) == 5, 
			"截图必须提示第5列换到第2列立即收粉盆")
		var swaps: int = 0
		for entry: Dictionary in screenshot:
			swaps += int(entry["root_swapped"])
		check(swaps >= 1, "截图完整局部路线支持实际送盆互换")

	lv = JuiceLevel.from_dict({"id": 98402, "capacity": 3, "targetCups": 2, 
		"initial": [{"column": "-|", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 1}}, "0|0,1", "1|1,1"], 
		"incoming": ["-|0"], "columnCaps": {"initial": [2, 2, 3], "incoming": [2]}})
	check(lv.validate().is_empty(), "必要撤回题面有效")
	st = enabled_state(lv)
	var rec: Dictionary = R.apply_move(st, lv, 1, 0, 2)
	var forbid: Dictionary = {"src": rec["dst"], "dst": rec["src"], "k": rec["k"], "root_swapped": true}
	var checks: Dictionary = {"now": Time.get_ticks_msec, "deadline": Time.get_ticks_msec() + 800, "forbid": forbid}
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "forbid": forbid}, result)
	var hint: Dictionary = result["hint"]
	check( not hint.is_empty(), "必要撤回若有真实收盆进展可交付且不误判死")
	if not hint.is_empty():
		check(S.is_forbidden(st, hint["move"], forbid), "现有纯色满列优先逆交换落盆，收盆进展不会构成来回循环")
		for mv: Dictionary in hint["path"]:
			check( not R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
				"必要撤回完整路线真实合法")
		check(int(st["done"]) > 0, "必要撤回完整局部路径真实收盆")
		_follow_hints(st, lv, "必要撤回后续")
		check(R.is_win(st, lv), "必要撤回后连续局部Hint可通关")
	print("ROOT_SWAP_HINT_CONTINUITY uniform=", uniform.size(), " variable=", variable.size(), 
		" screenshot=", screenshot.size(), " forced_reverse=", not hint.is_empty())


func _test_enabled_properties() -> void :
	var lv: JuiceLevel = mixed_level()
	var rng: = RandomNumberGenerator.new()
	rng.seed = 390011
	var transitions: int = 0
	var original_moves: int = 0
	var swaps: int = 0
	for sample in 300:
		var control: Dictionary = R.make_state(lv)
		for ci in 3:
			control["caps"][ci] = rng.randi_range(2, 3)
			control["jars"][ci] = rng.randi_range(-1, 2)
			var col: Array[int] = []
			for _i in rng.randi_range(0, control["caps"][ci]):
				col.append(rng.randi_range(0, 2))
			control["cols"][ci] = col
		if sample % 7 == 0:
			control["locks"][1] = {"condition": "collect_count", "count": 10}
		if sample % 11 == 0 and not (control["cols"][0] as Array).is_empty():
			control["cols"][0][0] += JuiceLevel.HIDDEN_BASE
		var st: Dictionary = R.clone_state(control)
		st["allow_root_swapping"] = true
		var before: String = S._full_state_key(st)
		var moves: Array = R.useful_moves(st)
		var enumerated: int = 0
		for src in range(-1, 4):
			for j in range(-1, 4):
				for dst in range(-1, 4):
					var old_k: int = R.move_info(control, src, j, dst)
					var new_k: int = R.move_info(st, src, j, dst)
					if old_k > 0:
						check(new_k == old_k and not R.is_root_swap(st, src, j, dst), 
							"实验所有原合法操作保留原搬移，不能被交换覆盖")
					if new_k > 0:
						enumerated += 1
						if old_k == 0:
							check(j == 0 and R.is_root_swap(st, src, j, dst), 
								"实验新增合法操作严格只有根部互换")
		check(enumerated == moves.size() and R.has_any_move(st) == (enumerated > 0), 
			"实验枚举和有无合法移动与逐边界规则一致")
		for mv: Dictionary in moves:
			var cur: Dictionary = R.clone_state(st)
			var rec: Dictionary = R.apply_move(cur, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
			check( not rec.is_empty(), "实验枚举每一步均能实际应用")
			if bool(rec.get("root_swapped", false)):
				swaps += 1
			else:
				var original: Dictionary = R.clone_state(control)
				var old_rec: Dictionary = R.apply_move(original, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
				check(without_root_fields(cur) == without_root_fields(original)
					and without_root_fields(rec) == without_root_fields(old_rec), "实验普通操作状态/记录与对照组一致")
				original_moves += 1
			P.undo_search(cur, rec)
			check(S._full_state_key(cur) == before, "实验搜索回滚精确还原每个随机操作")
			cur = R.clone_state(st)
			rec = R.apply_move(cur, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			R.undo_move(cur, rec)
			check(S._full_state_key(cur) == before, "实验实际收盆/显色后撤销精确还原")
			transitions += 1
	check(swaps > 100 and original_moves > 100, "随机矩阵同时覆盖足量交换与普通操作")
	print("ROOT_SWAP_ENABLED_PROPERTIES states=300 boundaries=37500 transitions=", transitions, 
		" swaps=", swaps, " ordinary=", original_moves)


func without_root_fields(value: Variant) -> Variant:
	if value is Dictionary:
		var out: Dictionary = {}
		for key: Variant in value:
			if key not in ["allow_root_swapping", "root_swapped"]:
				out[key] = without_root_fields(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item: Variant in value:
			out.append(without_root_fields(item))
		return out
	return value


func _test_baseline_compatibility() -> void :
	var baseline_dir: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline-dir="):
			baseline_dir = arg.trim_prefix("--baseline-dir=")
	if baseline_dir.is_empty():
		return
	var old_r: Variant = load(baseline_dir.path_join("juice_rules.gd"))
	var old_s: Variant = load(baseline_dir.path_join("juice_solver.gd"))
	check(old_r != null and old_s != null, "加载独立原dev代码作为对照真值")
	if old_r == null or old_s == null:
		return
	var lv: JuiceLevel = mixed_level()
	var rng: = RandomNumberGenerator.new()
	rng.seed = 390010
	var transitions: int = 0
	var hints: int = 0
	for sample in 500:
		var st: Dictionary = R.make_state(lv)
		for ci in 3:
			st["caps"][ci] = rng.randi_range(2, 3)
			st["jars"][ci] = rng.randi_range(-1, 2)
			var col: Array[int] = []
			for _i in rng.randi_range(0, st["caps"][ci]):
				col.append(rng.randi_range(0, 2))
			st["cols"][ci] = col
		if sample % 5 == 0:
			st["locks"][1] = {"condition": "collect_count", "count": 10}
		if sample % 7 == 0 and not (st["cols"][0] as Array).is_empty():
			st["cols"][0][0] += JuiceLevel.HIDDEN_BASE
		if sample % 11 == 0 and not (st["cols"][2] as Array).is_empty():
			st["cols"][2][0] += JuiceLevel.FROZEN_BASE
		var moves: Array = R.useful_moves(st)
		check(moves == old_r.useful_moves(st) and R.has_any_move(st) == old_r.has_any_move(st), 
			"对照组合法走法与原dev逐项一致")
		check(S.is_closed_cycle(st, lv) == old_s.is_closed_cycle(st, lv), "对照组封闭判死与原dev一致")
		check(S.hint_lower_bound(st, 0, lv) == old_s.hint_lower_bound(st, 0, lv)
			and S.sort_lower_bound(st) == old_s.sort_lower_bound(st), "对照组提示下界保持原dev")
		check( not S._is_root_swap_only_cycle(st, lv), "对照组永不启用新封闭判据")
		for src in range(-1, 4):
			for j in range(-1, 4):
				for dst in range(-1, 4):
					check(R.move_info(st, src, j, dst) == old_r.move_info(st, src, j, dst)
						and R.reject_reason(st, src, j, dst) == old_r.reject_reason(st, src, j, dst), 
						"对照组含非法边界的合法性/拒绝原因一致")
		for mv: Dictionary in moves:
			check(S.move_score(st, mv) == old_s.move_score(st, mv)
				and S.group_score(st, mv, 0) == old_s.group_score(st, mv, 0), "对照组走法评分一致")
			var current: Dictionary = R.clone_state(st)
			var original: Dictionary = old_r.clone_state(st)
			var rec: Dictionary = R.apply_move(current, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			var old_rec: Dictionary = old_r.apply_move(original, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			check(without_root_fields(current) == without_root_fields(original)
				and without_root_fields(rec) == without_root_fields(old_rec), "对照组移动/收盆/显色/解锁记录一致")
			R.undo_move(current, rec)
			old_r.undo_move(original, old_rec)
			check(without_root_fields(current) == without_root_fields(original), "对照组撤销精确一致")
			transitions += 1

		if sample % 16 == 0 and not R.any_ready(st):
			var opts: Dictionary = {"node_cap": 300, "max_depth": 8, "width": 3}
			check(S.hint_move(st, lv, opts.duplicate(true)) == old_s.hint_move(st, lv, opts.duplicate(true)), 
				"对照组确定性提示输出与原dev一致")
			hints += 1
	check(hints >= 20, "对照组至少20个有效盘面的提示差分")
	_test_baseline_checked_hint(old_s)
	print("ROOT_SWAP_BASELINE_DIFF states=500 boundaries=62500 transitions=", transitions, " hints=", hints)



func _test_baseline_checked_hint(old_s: Variant) -> void :
	var cases: int = 0
	var found: int = 0
	for shape in 16:
		var ones: int = 0
		for i in 4:
			ones += (shape >> i) & 1
		if ones != 2:
			continue
		for mechanism in 3:
			var a: Array[int] = [shape & 1, (shape >> 1) & 1]
			var b: Array[int] = [(shape >> 2) & 1, (shape >> 3) & 1]
			var prefix: String = ["", JuiceLevel.HIDDEN_CHAR, JuiceLevel.FROZEN_CHAR][mechanism]
			var a_prefix: String = "" if mechanism == 2 and a[0] == 0 else prefix
			var b_prefix: String = "" if mechanism == 2 and b[0] == 0 else prefix
			var raw: Dictionary = {"id": 98410 + cases, "capacity": 2, "targetCups": 2, 
				"initial": ["-|", "0|%s%d,%d" % [a_prefix, a[0], a[1]], 
					"1|%s%d,%d" % [b_prefix, b[0], b[1]]], "incoming": ["x"]}
			if mechanism == 2:

				raw["sunlight"] = {"typeId": 0}
			var lv: JuiceLevel = JuiceLevel.from_dict(raw)
			check(lv.validate().is_empty(), "对照Hint正式入口差分题面合法：" + str(lv.validate()))
			var st: Dictionary = R.make_state(lv)
			var deposits: Array = []
			R.run_deposit(st, lv, deposits)
			for explicit_false: bool in [false, true]:
				if explicit_false:
					st["allow_root_swapping"] = false
				var current: Dictionary = {}
				var original: Dictionary = {}
				var ticks: Array[int] = [0]
				var clock: Callable = func() -> int:
					ticks[0] += 1
					return ticks[0]
				var opts: Dictionary = {"now": clock, "ms_cap": 800, 
					"forbid": {"src": 1, "dst": 0, "k": 1}}
				S.run_checked_hint_task(st, lv, opts, current)
				ticks[0] = 0
				old_s.run_checked_hint_task(st, lv, opts, original)
				check(without_root_fields(current["hint"]) == without_root_fields(original["hint"]), 
					"对照组正式800ms Hint路径/长度/目标与原dev一致")
				check(current["reachability"] == original["reachability"], "对照组正式Hint可达性结论一致")
				cases += 1
				found += int( not (current["hint"] as Dictionary).is_empty())
	check(found > 0 and cases == 36, "正式入口差分覆盖有提示路径及缺开关/显式false")
	print("ROOT_SWAP_BASELINE_CHECKED_HINT cases=", cases, " found=", found, " path_differences=0")


func _test_large_permutation_cycles() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 9876100, "capacity": 5, "targetCups": 7, 
		"initial": ["0|0,1,1,1", "1|3,1,1,1", "2|4,1,1,1", "3|0,2,2,2", "4|3,2,2,2", "1|4,2,2,2"], 
		"incoming": ["2|0,0,0,3,3", "-|3,4,4,4,1", "-|2", "x", "x", "x"]})
	check(lv.validate().is_empty(), "100内容态真闭fixture题面配平")
	var st: Dictionary = enabled_state(lv)
	var before: String = S._full_state_key(st)
	check(S._root_permutation_closed_without_deposit(st, lv, {}), "实验独立压缩预算可证明超过80内容态的真闭图")
	var search: Dictionary = S.begin_root_closed_search(st, lv, 8000, true)
	var started: int = Time.get_ticks_usec()
	var slices: int = 0
	var result: Dictionary = {}
	while not bool(search["done"]):
		result = S.advance_root_closed_search(search, 8, {"now": Time.get_ticks_msec})
		slices += 1
	var cpu_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	check(result["status"] == "CLOSED" and result["reason"] == "permutation"
		and int(result["states"]) == 100, "runtime完整穷尽100内容态，避免枚举72,000排列")
	search = S.begin_root_closed_search(st, lv, 80)
	result = S.advance_root_closed_search(search, 8)
	check(result["status"] == "UNKNOWN", "整个runtime任务状态预算耗尽仍UNKNOWN")
	check(S._full_state_key(st) == before, "大压缩图证明不修改真实盘面")
	print("ROOT_SWAP_LARGE_PERMUTATION states=100 actual=72000 cpu_ms=", cpu_ms, " slices=", slices)


func _test_local_grouping_policy() -> void :

	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 9876201, "capacity": 2, "targetCups": 3, 
		"initial": ["1|0,0", "0|1", "2|2", "-|1,2"], "incoming": ["x", "x"]})
	check(lv.validate().is_empty(), "现成满纯列优先fixture有效")
	var st: Dictionary = enabled_state(lv)
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec}, result)
	var hint: Dictionary = result["hint"]
	check( not hint.is_empty() and int(hint["move"]["src"]) == 0
		and int(hint["move"]["dst"]) == 1 and int(hint["len"]) == 1, 
		"现有同色满列优先一步真实互换到正确盆")
	if not hint.is_empty():
		check( not bool(hint["win_path"]) and int(result["reachability"]) == S.Reachability.UNKNOWN, 
			"局部收盆不冒充整关WINNABLE")

	lv = JuiceLevel.from_dict({"id": 9876202, "capacity": 3, "targetCups": 2, 
		"initial": ["-|0,0", "1|1,1,0", "0|1"], "incoming": ["x"]})
	check(lv.validate().is_empty(), "错盆组列再落盆fixture有效")
	st = enabled_state(lv)
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec}, result)
	hint = result["hint"]
	check( not hint.is_empty() and int(hint["len"]) == 2, "完整局部Hint包含拼列与落盆两步")
	if not hint.is_empty():
		var first: Dictionary = hint["path"][0]
		var second: Dictionary = hint["path"][1]
		check(int(first["src"]) == 1 and int(first["j"]) == 2 and int(first["dst"]) == 0, 
			"优先在白盆已有两花基础上拼满同色列")
		check(int(second["src"]) == 0 and int(second["dst"]) == 2 and bool(second["root_swapped"]), 
			"拼满后最后一步送入正确花盆")
		for mv: Dictionary in hint["path"]:
			check( not R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), "组列路线真实合法")
		check(int(st["done"]) == 1, "组列到落盆路径确实完成首次收盆")

	lv = JuiceLevel.from_dict({"id": 9876203, "schema": "juice-level/4", "capacity": 3, "targetCups": 2, 
		"initial": ["1|0,0", "0|1", "-|"], "incoming": ["-|1,1"], "columnCaps": {"initial": [3, 2, 3], "incoming": [3]}})
	check(lv.validate().is_empty(), "不同源/目标容量的现成纯列fixture有效")
	st = enabled_state(lv)
	hint = S._root_try_direct_hint(st, st, lv, [], {})
	check( not hint.is_empty() and int(hint["move"]["src"]) == 0 and int(S._replay(st, lv, hint["path"], true)["done"]) == 1, 
		"源未装满自身容量仍可互换到同色目标容量收盆")

	st = enabled_state(lv)
	st["frozen_pots"] = [false, true, false] as Array[bool]
	check(S._root_try_direct_hint(st, st, lv, [], {}).is_empty(), "冰盆不因明牌同色完成列被强行收集")
	st = enabled_state(lv)
	st["cols"][0] = [1000, 1000] as Array[int]
	check(S._root_try_direct_hint(st, st, lv, [], {}).is_empty(), "问号未显色不能冒充完成列")
	var called: Array[int] = [0]
	var hook: Callable = func(path: Array, _opts: Dictionary) -> Dictionary:
		called[0] += 1
		return {"injected": path.size()}
	var injected: Dictionary = S._checked_root_local_hint(st, lv, [{"src": 0, "j": 0, "dst": 1}], {"check_path": hook})
	check(called[0] == 1 and int(injected["injected"]) == 1, "Endless真实session路径校验可注入且不走有限收盆")
	var win_lv: JuiceLevel = winning_level()
	var win_st: Dictionary = enabled_state(win_lv)
	var budget: Dictionary = {"now": func() -> int: return 5, "deadline": 1, "check_deadline": 10}
	var checked: Dictionary = S._checked_root_local_hint(win_st, win_lv, [{"src": 1, "j": 0, "dst": 0}], budget)
	check( not checked.is_empty() and bool(checked["win_path"]), "已找到的路径使用全局剩余预算完成校验")
	check((S._find_root_local_hint(win_st, win_lv, budget)["hint"] as Dictionary).is_empty(), 
		"校验剩余预算不能延长搜索阶段deadline")
	print("ROOT_SWAP_LOCAL_GROUPING priority=ready assemble=anywhere safety=real callback=endless")


func _test_grouping_after_retired_slots() -> void :

	var lv: JuiceLevel = mixed_level()
	var st: Dictionary = enabled_state(lv)
	st["caps"] = [4, 4, 4] as Array[int]
	st["cols"] = [[1, 0, 0] as Array[int], [2, 0, 0] as Array[int], [3, 1, 1] as Array[int]]
	st["jars"] = [0, -1, -1] as Array[int]
	check(S._root_group_lower_bound(st, lv) == 3, "无现成0色根段时组列评分计清杂色和两次供货")
	for position in 4:
		var retired: Dictionary = R.clone_state(st)
		(retired["caps"] as Array).insert(position, 0)
		(retired["cols"] as Array).insert(position, [] as Array[int])
		(retired["jars"] as Array).insert(position, -1)
		(retired["gone"] as Array).insert(position, true)
		(retired["locks"] as Array).insert(position, {})
		check(S._root_group_lower_bound(retired, lv) == 3, 
			"首/中/末已移除槽不改变活列容量与候选位置评分")
	st["caps"][1] = 3
	check(S._root_group_lower_bound(st, lv) == 0, "真实活列变容量仍保守退化评分")
	st["gone"] = [true, true, true] as Array[bool]
	st["caps"] = [0, 0, 0] as Array[int]
	check(S._root_group_lower_bound(st, lv) == 0, "没有活列时不建立组列容量")

	lv = JuiceLevel.from_dict({"id": 6, "capacity": 5, "targetCups": 10, 
		"initial": ["-|8,1,4,7", "7|7", "4|1,?7,0,?4,0", "1|?8,?0,1,7", "8|?0,8", "0|1,?8,?4,7"], 
		"incoming": ["5|5,0,?0,?8,5", "0|0,5,5,?0,4", "6|6,2,5,1,2", "3|0,3,6,?3,4", 
			"2|3,6,0,?3,2", "-|3,6,?2,?6,2", "x", "x", "x"]})
	check(lv.validate().is_empty(), "移除槽后段回归原题花账配平")
	st = enabled_state(lv)
	st["done"] = 7
	st["cups"] = [7, 8, 0, 1, 4, 5, 0] as Array[int]
	st["caps"] = [5, 5, 5, 5, 5, 0] as Array[int]
	st["gone"] = [false, false, false, false, false, true] as Array[bool]
	st["jars"] = [-1, 2, 3, 6, -1, -1] as Array[int]
	st["cols"] = [[3, 6, 3] as Array[int], [3, 6] as Array[int], [1003, 2] as Array[int], 
		[6, 2, 2] as Array[int], [3, 6, 1002, 1006, 2] as Array[int], [] as Array[int]]
	var before: String = S._full_state_key(st)

	var search: Dictionary = S._find_root_local_hint(st, lv, {"now": func() -> int: return 0, 
		"deadline": 1, "ordinary_only": true, "node_cap": 32, "state_cap": 256})
	check( not (search["hint"] as Dictionary).is_empty(), "移除槽后简单首盆在有限搜索内仍可找到")
	check(S._full_state_key(st) == before, "移除槽后搜索不修改玩家快照")
	for _batch in 3:
		var result: Dictionary = {}
		S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800}, result)
		var hint: Dictionary = result["hint"]
		check( not hint.is_empty(), "连续Hint支持每次收盆后更多槽位移除")
		if hint.is_empty():
			break
		var previous_done: int = int(st["done"])
		for mv: Dictionary in hint["path"]:
			check( not R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
				"移除槽后的Hint每步按实际规则合法重放")
		check(int(st["done"]) > previous_done, "移除槽后的完整Hint路线真实收盆")
	check(R.is_win(st, lv), "后段连续Hint真实完成余下三盆")
	print("ROOT_SWAP_RETIRED_SLOTS positions=all search=bounded continuation=win")


func _test_grouping_with_locked_slots() -> void :
	var lv: JuiceLevel = mixed_level()
	var st: Dictionary = enabled_state(lv)
	st["caps"] = [4, 4, 4] as Array[int]
	st["jars"] = [0, -1, -1] as Array[int]
	st["cols"] = [[1, 0, 0] as Array[int], [2, 0, 0] as Array[int], [] as Array[int]]
	check(S._root_group_lower_bound(st, lv) == 2, "可用空列组色只需两次供货")
	st["locks"][2] = {"condition": "collect_count", "count": 1}
	check(S._root_group_lower_bound(st, lv) == 3, "锁柜空列不能作为低成本组列位置")
	st["cols"] = [[1, 0] as Array[int], [2, 0] as Array[int], [0, 0] as Array[int]]
	check(S._root_group_lower_bound(st, lv) == S.LB_IMPOSSIBLE, "锁柜花不能作为首盆前可用库存")
	st["cols"] = [[] as Array[int], [0, 0] as Array[int], [0, 0] as Array[int]]
	st["locks"] = [{"condition": "collect_count", "count": 1}, {}, {}]
	check(S._root_group_lower_bound(st, lv) == S.LB_IMPOSSIBLE, "目标盆全在锁柜时不奖励该花色")
	st["jars"][1] = 0
	check(S._root_group_lower_bound(st, lv) == 1, "同色另有可用目标盆时仍参与组列评分")
	var before: String = JSON.stringify(st)
	S._root_group_lower_bound(st, lv)
	check(JSON.stringify(st) == before, "锁柜评分不改变输入快照")
	st["caps"][0] = 3
	check(S._root_group_lower_bound(st, lv) == 0, "未退场的锁列变容量仍保留保守退化")
	st["caps"][0] = 4
	st.erase("locks")
	before = JSON.stringify(st)
	check(S._root_group_lower_bound(st, lv) == 1 and JSON.stringify(st) == before, 
		"旧快照缺锁数组时评分纯查询且不补写状态")
	print("ROOT_SWAP_LOCKED_GROUPING stock=available targets=available slots=available query=pure")


func _test_level12_locked_hint_regression() -> void :

	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 12, "capacity": 4, "targetCups": 12, 
		"initial": ["-|5,7,?2,1", "1|1", 
			{"column": "2|2,9,7,4", "columnType": "unlock", 
				"columnInfo": {"condition": "collect_type", "typeId": 6, "count": 1}}, 
			{"column": "9|7,9,5,4", "columnType": "unlock", 
				"columnInfo": {"condition": "collect_type", "typeId": 1, "count": 1}}, 
			"5|?2,4,1", "7|9,5", "4|4,1"], 
		"incoming": ["6|9,5,9,6", "9|?9,6,9,2", "3|6,7,?6,9", "5|5,3,?8,2", 
			"8|2,8,3,5", "2|2,8,5,3", "-|3,5,2,8", "x", "x", "x", "x"]})
	check(lv.validate().is_empty(), "第12关锁柜回归原题配平合法")
	var st: Dictionary = enabled_state(lv)
	var before: String = S._full_state_key(st)
	var first: Dictionary = S._find_root_local_hint(st, lv, {"now": func() -> int: return 0, 
		"deadline": 1, "ordinary_only": true, "verify_safe": false, "node_cap": 3, "state_cap": 128})
	var hint: Dictionary = first["hint"]
	check( not hint.is_empty() and int(hint.get("len", 0)) == 3, "第12关三次补蓝直接收第2列蓝盆")
	check(S._full_state_key(st) == before, "第12关搜索保持玩家初始盘面")
	if hint.is_empty():
		return
	for mv: Dictionary in hint["path"]:
		check(int(mv["dst"]) == 1 and int(mv["head"]) == 1 and not bool(mv["root_swapped"]), 
			"开局优先把尾蓝接到现有蓝花下")
		check( not R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
			"第12关补蓝每步真实合法")
	check(int(st["done"]) == 1 and not R.is_locked(st, 3) and R.is_locked(st, 2), 
		"收蓝按真实规则解锁蓝条件柜，保留另一锁柜")
	var continuation: Dictionary = S._find_root_local_hint(st, lv, {"now": func() -> int: return 0, 
		"deadline": 1, "ordinary_only": true, "verify_safe": false, "node_cap": 12, "state_cap": 128})
	check( not (continuation["hint"] as Dictionary).is_empty(), "收蓝后12节点内找到真实下一盆出口")
	st = enabled_state(lv)
	for _batch in lv.groups_total:
		var result: Dictionary = {}
		before = S._full_state_key(st)
		S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800, 
			"require_complete": true, "verify_safe": false}, result)
		hint = result["hint"]
		check(S._full_state_key(st) == before, "正式第12关完整首盆Hint不改玩家快照")
		check( not hint.is_empty(), "第12关连续生产Hint提供真实首盆路线")
		if hint.is_empty():
			break
		if int(st["done"]) == 0:
			check(int(hint["len"]) == 3 and int(hint["col"]) == 1, "正式开局Hint交付三步收蓝路线")
		var previous_done: int = int(st["done"])
		for mv: Dictionary in hint["path"]:
			check( not R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
				"第12关正式Hint路线按真实规则重放")
		check(int(st["done"]) > previous_done, "第12关每条完整Hint路线都真实收盆")
		if R.is_win(st, lv):
			break
	check(R.is_win(st, lv), "第12关连续Hint通过锁柜与退场补货完成全关")
	print("ROOT_SWAP_LEVEL12_LOCKED first=blue continuation=bounded replay=win")



func level14_hint_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 14, "capacity": 5, "targetCups": 11, 
		"initial": ["-|3,?7,?3,0,7", "5|5,0,?3,1,5", "7|", 
			{"column": "3|7,0,1,3,1", "columnType": "unlock", 
				"columnInfo": {"condition": "collect_type", "typeId": 5, "count": 1}}, 
			"1|1,?5,?1,5", "0|?1,?7,1", "1|?0,1,5"], 
		"incoming": ["2|?0,3,7,?2,6", "6|?2,1,6,6,2", "4|1,2,6,6,2", 
			"2|2,4,4,0,0", "0|2,2,0,4,4", "-|4,0,0,2,2", "x", "x", "x", "x"]})


func level14_hint_state(lv: JuiceLevel) -> Dictionary:
	var st: Dictionary = enabled_state(lv)

	for mv: Array in [[1, 4, 2], [4, 3, 2], [6, 2, 2], [4, 2, 5], 
			[4, 1, 2], [1, 3, 4], [5, 2, 4], [6, 1, 4]]:
		check( not R.apply_move(st, lv, int(mv[0]), int(mv[1]), int(mv[2])).is_empty(), 
			"第14关截图前置每步真实合法")
	return st


func _test_level14_deposit_exit_regression() -> void :
	var lv: JuiceLevel = level14_hint_level()
	check(lv.validate().is_empty(), "第14关原题花朵配平合法")
	var st: Dictionary = level14_hint_state(lv)
	check(int(st["done"]) == 1 and st["cups"] == [1] and R.is_locked(st, 3)
		and st["cols"] == [[3, 1007, 1003, 0, 7], [5, 0, 3], [5, 5, 5, 5], 
			[7, 0, 1, 3, 1], [1000, 3, 7, 1002, 6], [1001, 7], [0]], 
		"第14关重建匹配截图的已收蓝/四橙/锁紫柜盘面")
	var before: String = JSON.stringify(st)
	var orange_path: Array = [{"src": 1, "j": 1, "dst": 6}, {"src": 2, "j": 0, "dst": 1}]
	var after: Dictionary = R.clone_state(st)
	for mv: Dictionary in orange_path:
		check( not R.apply_move(after, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
			"第14关两步收橙路线真实合法")
	check(int(after["done"]) == 2 and after["cups"] == [1, 5] and not R.is_locked(after, 3), 
		"第14关收橙按真实规则解锁紫柜")
	var after_before: String = JSON.stringify(after)
	check(S._root_has_deposit_exit(after, lv, 
		{"now": Time.get_ticks_msec, "deadline": Time.get_ticks_msec() + 800}), 
		"第14关收橙后的80ms窗口应找到真实下一盆出口")
	check(JSON.stringify(after) == after_before, "第14关出口检查不改收橙后盘面")
	var first: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800}, first)
	var hint: Dictionary = first["hint"]
	check( not hint.is_empty() and int(hint.get("len", 0)) == 2 and int(hint.get("col", -1)) == 1, 
		"第14关正式800ms入口交付已有两步收橙Hint")
	check(JSON.stringify(st) == before, "第14关正式Hint不改玩家冻结快照")
	if hint.is_empty():
		return
	for _retry in 2:
		var result: Dictionary = {}
		S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800}, result)
		check( not (result["hint"] as Dictionary).is_empty()
			and int((result["hint"] as Dictionary).get("len", 0)) == 2 and JSON.stringify(st) == before, 
			"第14关同盘反复Hint无需搬花即可保持两步收橙")
	var expired: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": func() -> int: return 10, "deadline": 1}, expired)
	check((expired["hint"] as Dictionary).is_empty() and int(expired["reachability"]) == S.Reachability.UNKNOWN, 
		"第14关任务已过期不得放行Hint或发布无解")
	var cancel: Semaphore = Semaphore.new()
	cancel.post()
	var cancelled: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "cancel": cancel}, cancelled)
	check((cancelled["hint"] as Dictionary).is_empty() and String(cancelled["stop_reason"]) == "cancelled", 
		"第14关任务取消不得发布旧Hint")
	var states: Dictionary = {}
	var steps: int = 0
	while steps < 80 and not R.is_win(st, lv):
		var key: String = S._full_state_key(st)
		check( not states.has(key), "第14关每次只走Hint首步也不能循环")
		if states.has(key):
			break
		states[key] = true
		var result: Dictionary = {}
		before = JSON.stringify(st)
		S.run_checked_hint_task(st, lv, {"now": Time.get_ticks_msec, "ms_cap": 800, 
			"require_complete": true, "verify_safe": false}, result)
		hint = result["hint"]
		check( not hint.is_empty() and JSON.stringify(st) == before, "第14关逐步Hint连续可用且不改盘面")
		if hint.is_empty():
			break
		var mv: Dictionary = hint["move"]
		var rec: Dictionary = R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check( not rec.is_empty(), "第14关Hint首步按真实规则合法")
		if rec.is_empty():
			break
		steps += 1
	check(R.is_win(st, lv), "第14关逐次单步Hint通过锁柜/问号/退场完成11盆")
	print("ROOT_SWAP_LEVEL14_EXIT first_ms=", first["elapsed_ms"], " first=orange steps=", steps, " replay=win")


func _test_ordinary_deposit_exit_boundaries() -> void :
	var lv: JuiceLevel = level14_hint_level()
	var st: Dictionary = level14_hint_state(lv)
	R.apply_move(st, lv, 1, 1, 6)
	R.apply_move(st, lv, 2, 0, 1)
	var before: String = JSON.stringify(st)
	check(S._root_ordinary_deposit_exit(st, lv, {}) and JSON.stringify(st) == before, 
		"普通出口必须真实收下一盆且不改输入")
	for old_locks: Variant in [null, []]:
		var legacy: Dictionary = st.duplicate(true)
		if old_locks == null:
			legacy.erase("locks")
		else:
			legacy["locks"] = old_locks
		before = JSON.stringify(legacy)
		check(S._root_ordinary_deposit_exit(legacy, lv, {}) and JSON.stringify(legacy) == before, 
			"普通见证规范化缺失/短锁数组只能写局部副本")
	check( not S._root_ordinary_deposit_exit(st, lv, {"now": func() -> int: return 10, "deadline": 1}), 
		"普通出口启动前过期不得放行")
	var calls: Array[int] = [0]
	var clock: Callable = func() -> int:
		calls[0] += 1
		return 0
	check(S._root_ordinary_deposit_exit(st, lv, {"now": clock, "deadline": 1}) and calls[0] > 1, 
		"下一盆见证搜索与真实重放沿用调用方时钟")
	var expire_at: int = calls[0]
	calls[0] = 0
	clock = func() -> int:
		calls[0] += 1
		return 1 if calls[0] >= expire_at else 0
	check( not S._root_ordinary_deposit_exit(st, lv, {"now": clock, "deadline": 1}), 
		"普通见证实际收盆后才过期也不得放行")
	var cancel: Semaphore = Semaphore.new()
	calls[0] = 0
	clock = func() -> int:
		calls[0] += 1
		if calls[0] == 20:
			cancel.post()
		return 0
	var result: Dictionary = {}
	S.run_checked_hint_task(level14_hint_state(lv), lv, {"now": clock, "cancel": cancel}, result)
	check(String(result["stop_reason"]) == "cancelled" and (result["hint"] as Dictionary).is_empty()
		and int(result["reachability"]) == S.Reachability.UNKNOWN, 
		"下一盆见证中途取消须丢弃候选并保持UNKNOWN")
	lv = JuiceLevel.from_dict({"id": 98491, "capacity": 3, "targetCups": 2, 
		"initial": ["0|0", {"column": "-|0,0", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_type", "typeId": 0, "count": 1}}, "1|1,?1,1"], 
		"incoming": ["x"]})
	check(lv.validate().is_empty(), "锁柜出口反例题面合法：" + str(lv.validate()))
	st = enabled_state(lv)
	check( not S._root_ordinary_deposit_exit(st, lv, {}), "锁柜供货和目标盆不能伪造普通出口")
	lv = JuiceLevel.from_dict({"id": 98492, "capacity": 3, "targetCups": 2, 
		"initial": ["-|", "0|0,0,0", "1|1,1,1"], "incoming": ["x"]})
	check(lv.validate().is_empty(), "已ready空路线反例题面合法：" + str(lv.validate()))
	st = enabled_state(lv)
	check(R.any_ready(st) and not S._root_ordinary_deposit_exit(st, lv, {}), 
		"已经ready但普通路线为空时不能伪造新增收盆记录")
	print("ROOT_SWAP_ORDINARY_EXIT_BOUNDARIES legacy=readonly deadline=guarded cancel=UNKNOWN")



func _test_first_pot_delivery_and_preference() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 9888820, "capacity": 2, "targetCups": 3, 
		"initial": ["1|0,0", "0|1,2", "2|2,1"], "incoming": []})
	check(lv.validate().is_empty(), "首盆后真死兜底题面合法")
	var st: Dictionary = enabled_state(lv)
	var path: Array = [{"src": 0, "j": 0, "dst": 1}]
	var checked: Dictionary = S._checked_root_local_hint(st, lv, path, {})
	check( not checked.is_empty(), "真实首盆不能因之后无下一盆被安全检查拒收")
	var after: Dictionary = R.clone_state(st)
	R.apply_move(after, lv, 0, 0, 1)
	check(S.advance_root_closed_search(S.begin_root_closed_search(after, lv))["status"] == "CLOSED", 
		"兜底路线真实收盆后确实无下一盆")
	var board: Dictionary = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(board["status"] == "EXIT" and not (board["path"] as Array).is_empty(), 
		"同盘自动判定有首盆出口并给出可重放路径")
	var result: Dictionary = {}
	S.run_checked_hint_task(st, lv, {"preferred_path": board["path"], "now": func() -> int: return 0, 
		"deadline": 1, "require_complete": true, "verify_safe": false}, result)
	check( not (result["hint"] as Dictionary).is_empty() and result["stop_reason"] == "resolved"
		and result["reachability"] == S.Reachability.UNKNOWN, 
		"生产preferred路径即使后续CLOSED也交付当前首盆，不推翻自动EXIT")
	var wrong_paths: Array = [[{"src": 0, "j": 0, "dst": 0}], [{"src": 0, "j": 0, "dst": 2}]]
	for wrong: Array in wrong_paths:
		result = {}
		S.run_checked_hint_task(st, lv, {"preferred_path": wrong, "now": func() -> int: return 1000, 
			"deadline": 1, "node_cap": 1, "state_cap": 1, 
			"require_complete": true, "verify_safe": false}, result)
		check( not (result["hint"] as Dictionary).is_empty() and result["stop_reason"] == "resolved"
			and result["first_pot_status"] == "EXIT", 
			"错误或未收盆preferred不能永久UNKNOWN，必须回退完整首盆搜索")
		var replay: Dictionary = R.clone_state(st)
		var collected: bool = false
		for mv: Dictionary in (result["hint"] as Dictionary).get("path", []):
			var rec: Dictionary = R.apply_move(replay, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			check( not rec.is_empty(), "错误preferred回退路线每步真实合法")
			collected = collected or not (rec["deposits"] as Array).is_empty()
		check(collected, "错误preferred回退路线真实收盆")
	var failed_cancel: = Semaphore.new()
	failed_cancel.post()
	result = {}
	S.run_checked_hint_task(st, lv, {"preferred_path": wrong_paths[0], "now": Time.get_ticks_msec, 
		"require_complete": true, "verify_safe": false, "cancel": failed_cancel}, result)
	check((result["hint"] as Dictionary).is_empty() and result["stop_reason"] == "cancelled"
		and int(result["routes"]) == 0, "错误preferred遇取消立即退出，不启动回退搜索")

	lv = JuiceLevel.from_dict({"id": 9888815, "capacity": 3, "targetCups": 4, "incoming": [], 
		"initial": ["-|3,0,3", "0|1,2,0", "1|0,1,3", "2|2,2", "3|1"]})
	check(lv.validate().is_empty(), "生产首盆与可选安全择优题面合法")
	st = enabled_state(lv)
	board = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	path = board["path"]
	after = R.clone_state(st)
	for mv: Dictionary in path:
		check( not R.apply_move(after, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), 
			"自动首解每步真实合法")
	check(path.size() == 3 and S.advance_root_closed_search(S.begin_root_closed_search(after, lv))["status"] == "CLOSED", 
		"自动首解三步收2后真实CLOSED")
	result = {}
	var progress: S.HintProgress = S.HintProgress.new()
	S.run_checked_hint_task(st, lv, {"preferred_path": path, "now": func() -> int: return 0, 
		"deadline": 1, "progress": progress, "require_complete": true, "verify_safe": false}, result)
	var hint: Dictionary = result["hint"]
	check( not hint.is_empty() and int(hint["len"]) == path.size() and int(hint["col"]) == 3
		and not hint.has("safe_after"), "生产使用同一首盆见证，立即交付三步首解，不等待未来择优")
	result = {}
	S.run_checked_hint_task(st, lv, {"preferred_path": path, "now": func() -> int: return 0, 
		"deadline": 1, "verify_safe": true}, result)
	hint = result["hint"]
	check( not hint.is_empty() and bool(hint.get("safe_after", false)) and int(hint["col"]) == 4, 
		"显式有界择优仍能选择收3后可继续的真实方案")
	after = R.clone_state(st)
	for mv: Dictionary in hint.get("path", []):
		check( not R.apply_move(after, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty(), "择优首盆真实重放")
	check(S.advance_root_closed_search(S.begin_root_closed_search(after, lv))["status"] == "EXIT", 
		"安全优先有下一盆可达性见证而非评分猜测")

	var clock_value: Array[int] = [0]
	var saw_first: Array[bool] = [false]
	progress = S.HintProgress.new()
	var safety: Callable = func(_ranking: Dictionary) -> bool:
		saw_first[0] = not progress.read().is_empty()
		clock_value[0] = 100
		return false
	result = {}
	S.run_checked_hint_task(st, lv, {"preferred_path": path, "now": func() -> int: return clock_value[0], 
		"deadline": 10, "progress": progress, "check_safe": safety, "verify_safe": true}, result)
	check(saw_first[0] and not (result["hint"] as Dictionary).is_empty()
		and int((result["hint"] as Dictionary)["len"]) == path.size() and result["stop_reason"] == "resolved", 
		"首次FOUND先publish，未来择优超时仍交付已经保存的首盆")

	clock_value[0] = 0
	var safety_calls: Array[int] = [0]
	var slow_clock: Callable = func() -> int:
		clock_value[0] += 200
		return clock_value[0]
	result = {}
	S.run_checked_hint_task(st, lv, {"preferred_path": path, "now": slow_clock, 
		"ms_cap": 1, "deadline": 1, "require_complete": true, "verify_safe": false, 
		"check_safe": func(_ranking: Dictionary) -> bool:
			safety_calls[0] += 1
			return false}, result)
	check( not (result["hint"] as Dictionary).is_empty() and result["stop_reason"] == "resolved"
		and int(result["elapsed_ms"]) > 800 and safety_calls[0] == 0, 
		"生产已证明首盆回放跨过旧截止仍交付，而且不调用后续安全择优")
	var cancel: = Semaphore.new()
	var clock_calls: Array[int] = [0]
	var cancel_clock: Callable = func() -> int:
		clock_calls[0] += 1
		if clock_calls[0] == 3:
			cancel.post()
		return clock_calls[0] * 200
	result = {}
	S.run_checked_hint_task(st, lv, {"preferred_path": path, "now": cancel_clock, 
		"ms_cap": 1, "deadline": 1, "require_complete": true, "verify_safe": false, "cancel": cancel}, result)
	check((result["hint"] as Dictionary).is_empty() and result["stop_reason"] == "cancelled", 
		"生产首盆回放忽略旧时间截止但仍响应中途取消")
	print("ROOT_SWAP_FIRST_POT production=first_witness_no_ranking expired=delivered cancel=guarded optional_preferred=safe")


func _test_first_pot_compression() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 9888826, "capacity": 2, "targetCups": 3, 
		"initial": ["0|1,2", "1|2,0", "2|0,1"], "incoming": [], 
		"columnCaps": {"initial": [2, 2, 2], "incoming": []}})
	check(lv.validate().is_empty(), "满混色快证题面合法")
	var st: Dictionary = enabled_state(lv)
	var ctx: Dictionary = S.begin_root_closed_search(st, lv)
	var outcome: Dictionary = S.advance_root_closed_search(ctx)
	check(outcome["status"] == "CLOSED" and outcome["reason"] == "swap_only"
		and bool(exhaustive_closed(st, lv)["no_deposit"]), "满混色快证与独立实际图一致")
	for ci in (st["cols"] as Array).size():
		st["cols"][ci] = [ci] as Array[int]
	outcome = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(outcome["status"] == "CLOSED" and outcome["reason"] == "insufficient_stock"
		and bool(exhaustive_closed(st, lv)["no_deposit"]), "库存快证与独立真实图一致")

	var oracle_cases: int = 0
	for code in 729:
		st = enabled_state(lv)
		var n: int = code
		for ci in 3:
			st["cols"][ci] = [n % 3, (n / 3) % 3] as Array[int]
			n /= 9
		var closed: bool = bool(exhaustive_closed(st, lv)["no_deposit"])
		outcome = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
		check((outcome["status"] == "CLOSED") == closed, 
			"满盘729独立实际图判定一致：" + str(code))
		oracle_cases += 1

	lv = JuiceLevel.from_dict({"id": 9888823, "capacity": 3, "targetCups": 2, 
		"initial": ["-|0,0", "1|1,1,0", "0|1"], "incoming": ["x"]})
	st = enabled_state(lv)
	st["cols"].append([] as Array[int])
	st["caps"].append(0)
	st["jars"].append(-1)
	st["gone"].append(true)
	st["locks"].append({})
	var before: String = S.root_closed_state_key(st)
	check(S._root_can_merge_permutations(st, lv), "合法退场槽排除操作但不取消精确内容压缩")
	ctx = S.begin_root_closed_search(st, lv)
	outcome = S.advance_root_closed_search(ctx)
	check(outcome["status"] == "EXIT" and ctx["phase"] == "permutation", "退场槽仍在内容图直接找到真实首盆")
	for mv: Dictionary in outcome["path"]:
		check(int(mv["src"]) < 3 and int(mv["dst"]) < 3, "压缩路径保留原真实列号，不操作退场槽")
	check(S.root_closed_state_key(st) == before, "内容去重不重排或修改玩家盘面")
	for mechanism: String in ["internal_hidden", "frozen", "frozen_pot", "lock"]:
		var special: Dictionary = R.clone_state(st)
		match mechanism:
			"internal_hidden": special["cols"][1][0] = JuiceLevel.HIDDEN_BASE + 1
			"frozen": special["cols"][1][0] = JuiceLevel.FROZEN_BASE + 1
			"frozen_pot": special["frozen_pots"] = [false, true, false, false] as Array[bool]
			"lock": special["locks"][1] = {"condition": "collect_count", "count": 1}
		check(S._root_can_merge_permutations(special, lv), "首盆内容对称性保留机制原编码：" + mechanism)
		_check_root_search_nodes_readonly(special, lv, mechanism)
	var legacy: Dictionary = st.duplicate(true)
	legacy.erase("locks")
	_check_root_search_nodes_readonly(legacy, lv, "旧档缺锁数组")
	print("ROOT_SWAP_FIRST_POT_COMPRESSION oracle=", oracle_cases, 
		" mixed=fast_CLOSED stock=fast_CLOSED compression=retired_hidden_ice_lock")



func _check_root_search_nodes_readonly(st: Dictionary, lv: JuiceLevel, label: String) -> void :
	var source_before: String = JSON.stringify(st)
	var ctx: Dictionary = S.begin_root_closed_search(st, lv, 64)
	var root_before: String = S.root_closed_state_key(ctx["start"])
	S.advance_root_closed_search(ctx, 8, {"skip_fast_proof": true, "node_cap": 2})
	check(JSON.stringify(st) == source_before and S.root_closed_state_key(ctx["start"]) == root_before, 
		"首盆节点搜索不修改输入/根节点：" + label)
	var nodes: Array = ctx["nodes"]
	for id in nodes.size():
		var node: Dictionary = nodes[id]
		var replay: Dictionary = R.clone_state(ctx["start"])
		var path: Array = [] if id == 0 else P._path(int(node["parent"]), nodes, node["mv"])
		for mv: Dictionary in path:
			check( not R.apply_move(replay, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true).is_empty(), 
				"首盆父链动作合法：" + label)
		check(S.root_closed_state_key(replay) == S.root_closed_state_key(node["st"]), 
			"首盆兄弟节点花串不被后续分支污染：" + label)
		for field: String in ["jars", "caps", "gone", "locks", "cups", "frozen_pots"]:
			check((node["st"] as Dictionary).get(field) == (ctx["start"] as Dictionary).get(field), 
				"首盆前静态元数据不变：" + label + "/" + field)


func _test_first_pot_state_cap_resume() -> void :
	var lv: JuiceLevel = level7_cycle_level()
	var st: Dictionary = level7_cycle_state(lv)
	var ctx: Dictionary = S.begin_root_closed_search(st, lv, 1)
	var limited: Dictionary = S.advance_root_closed_search(ctx)
	check(limited["status"] == "UNKNOWN" and bool(limited["recoverable"]) and not bool(limited["continuable"]), 
		"后台状态上限只停止UNKNOWN，并保留主动Hint可恢复的前沿")
	var previous: int = int(limited["candidates"])
	check(S.resume_root_closed_search(ctx, 10), "主动Hint增加预算复用原ctx")
	var resumed: Dictionary = S.advance_root_closed_search(ctx)
	check(resumed["status"] == "CLOSED" and int(resumed["states"]) == 2 and int(resumed["candidates"]) >= previous, 
		"状态上限恢复不丢未接纳边，续至两内容态精确结论")
	check( not S.resume_root_closed_search(ctx, 20), "已完成CLOSED不得人为恢复")
	print("ROOT_SWAP_FIRST_POT_RESUME budget=1_to_10 frontier=retained result=CLOSED")


func _test_first_pot_complete_dfs() -> void :
	var lv: JuiceLevel = level7_cycle_level()
	var st: Dictionary = level7_cycle_state(lv)
	var original: String = S._full_state_key(st)
	var ctx: Dictionary = S.begin_root_closed_search(st, lv, 1, true)
	var calls: Array[int] = [0]
	var clock: Callable = func() -> int:
		calls[0] += 1
		return calls[0]
	var outcome: Dictionary = {}
	var slices: int = 0
	var pauses: int = 0
	var previous_candidates: int = 0
	while not bool(ctx["done"]) and slices < 1000:
		outcome = S.advance_root_closed_search(ctx, 8, {"now": clock, "deadline": calls[0] + 12})
		slices += 1
		check(int(outcome["candidates"]) >= previous_candidates, "完整会话跨片保留候选游标与累计进度")
		previous_candidates = int(outcome["candidates"])
		check((ctx["nodes"] as Array).size() <= 1 and (ctx["seen"] as Dictionary).size() <= 1, 
			"完整会话不会增长A*图超过内存阈值")
		if String(ctx["method"]) == "dfs":
			check((ctx["dfs_completed"] as Dictionary).size() <= 1, 
				"完成缓存固定容量，淘汰后仍完整重访")
			check((ctx["dfs_active"] as Dictionary).size() == (ctx["dfs_stack"] as Array).size(), 
				"DFS每个活动路径状态都有精确防环指纹")
		if not bool(ctx["done"]):
			pauses += 1
			check(outcome["status"] == "UNKNOWN" and bool(outcome["continuable"])
				and not bool(outcome["recoverable"]), "完整会话预算只暂停，不终端state_cap")
	check(outcome.get("status", "") == "CLOSED" and String(ctx["method"]) == "dfs"
		and int(ctx["dfs_evictions"]) > 0 and pauses > 0 and (ctx["dfs_stack"] as Array).is_empty(), 
		"低内存DFS经过暂停与完成缓存淘汰，根穷尽后准确CLOSED")
	check(S._full_state_key(st) == original and int(ctx["max_states"]) == 1, 
		"完整会话不改玩家快照，也不无限增大BFS预算")

	var cases: Array[Dictionary] = [
		{"id": 9898101, "capacity": 4, "targetCups": 5, 
			"initial": ["0|0,1,1", "1|2,1,1", "2|3,1"], 
			"incoming": ["1|0,0,0,1", "3|1,1,2,2", "-|2,3,3,3", "x"]}, 
		{"id": 9898102, "capacity": 4, "targetCups": 5, 
			"initial": ["0|0,1,1", "1|2,1,1", "2|0,1"], 
			"incoming": ["1|0,0,1,1", "2|1,2,2,2", "-|2,2,2,2", "x"]}, 
		{"id": 9898103, "capacity": 3, "targetCups": 3, 
			"initial": ["0|0,1", "1|2,1", "2|0,0"], "incoming": ["-|1,2,2", "x"]}]
	for i in cases.size():
		lv = JuiceLevel.from_dict(cases[i])
		check(lv.validate().is_empty(), "精确DFS杂色周转反例题面合法")
		st = enabled_state(lv)
		var truth: Dictionary = exhaustive_closed(st, lv)
		ctx = S.begin_root_closed_search(st, lv, 2, true)
		var started: int = Time.get_ticks_usec()
		outcome = S.advance_root_closed_search(ctx)
		check(outcome["status"] == ("CLOSED" if bool(truth.get("no_deposit", false)) else "EXIT")
			and String(ctx["method"]) == "dfs", "低阈值切换DFS与独立真实状态图首盆真值相同")
		check((ctx["nodes"] as Array).is_empty() and (ctx["seen"] as Dictionary).is_empty(), 
			"DFS切换释放整张A*父图")
		var after: Dictionary = R.clone_state(st)
		var collected: bool = false
		for mv: Dictionary in outcome["path"]:
			var rec: Dictionary = R.apply_move(after, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			check( not rec.is_empty(), "DFS的EXIT每步保留实际列号并能真实回放")
			collected = collected or not (rec["deposits"] as Array).is_empty()
		check(collected if outcome["status"] == "EXIT" else (outcome["path"] as Array).is_empty(), 
			"DFS只交付首次真实收盆，真CLOSED没有假路径")
		var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
		var independent: Dictionary = {}
		S.run_checked_hint_task(st, lv, {"require_complete": true, "verify_safe": false, 
			"state_cap": 2, "node_cap": 1, "deadline": 1, "now": func() -> int: return 1000}, independent)
		check(independent["stop_reason"] == ("dead" if outcome["status"] == "CLOSED" else "resolved")
			and independent["first_pot_status"] == outcome["status"], 
			"没有preferred的完整Hint也不因旧截止或节点预算终端UNKNOWN")
		print("ROOT_SWAP_COMPLETE_DFS case=", i, " status=", outcome["status"], " states=", outcome["states"], 
			" depth=", ctx["dfs_peak_depth"], " evictions=", ctx["dfs_evictions"], 
			" ms=", elapsed_ms)
	print("ROOT_SWAP_COMPLETE_DFS paused_slices=", pauses, " cache=1 bounded_legacy=unchanged")


func _test_first_pot_ready_trigger() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 9888824, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0,0", "1|1,1", "-|"], "incoming": []})
	check(lv.validate().is_empty(), "已满两盆触发题面合法")
	var st: Dictionary = enabled_state(lv)
	st["caps"][2] = 0
	st["gone"][2] = true
	check(R.any_ready(st), "已满两盆等待真实收集触发")
	var ctx: Dictionary = S.begin_root_closed_search(st, lv, 1, true)
	var outcome: Dictionary = S.advance_root_closed_search(ctx)
	check(outcome["status"] == "EXIT" and ctx["phase"] == "actual" and ctx["method"] == "dfs"
		and (outcome["path"] as Array).size() == 2, 
		"初始ready的一次错位交换不收盆，保留两步真实换回出口")
	var sliced: Dictionary = S.begin_root_closed_search(st, lv, 1, true)
	var calls: Array[int] = [0]
	var clock: Callable = func() -> int:
		calls[0] += 1
		return calls[0]
	var slices: int = 0
	var initial_pauses: int = 0
	var previous_candidates: int = 0
	var sliced_result: Dictionary = {}
	while not bool(sliced["done"]) and slices < 1000:
		var was_initial: bool = String(sliced["phase"]) == "initial"
		sliced_result = S.advance_root_closed_search(sliced, 8, 
			{"now": clock, "deadline": calls[0] + (4 if was_initial else 5)})
		slices += 1
		check(int(sliced_result["candidates"]) >= previous_candidates, 
			"初始ready真实触发检查跨片保留候选进度")
		previous_candidates = int(sliced_result["candidates"])
		if was_initial and String(sliced["phase"]) == "initial" and not bool(sliced["done"]):
			initial_pauses += 1
	check(sliced_result.get("status", "") == "EXIT" and initial_pauses > 1
		and String(sliced["method"]) == "dfs" and (sliced_result["path"] as Array).size() == 2, 
		"每片不足扫描初始ready候选前缀仍能前进并交付两步真实出口")
	var canceled_search: Dictionary = S.begin_root_closed_search(st, lv, 1, true)
	var canceled_result: Dictionary = S.advance_root_closed_search(canceled_search, 8, 
		{"now": func() -> int: return 100, "deadline": 1})
	check(canceled_result["status"] == "UNKNOWN" and bool(canceled_result["continuable"])
		and int(canceled_search["candidates"]) == 0 and String(canceled_search["phase"]) == "initial", 
		"初始ready扫描仍先响应取消或片截止，不能继续处理动作")
	var step: int = 0
	for mv: Dictionary in outcome["path"]:
		var rec: Dictionary = R.apply_move(st, lv, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		check( not rec.is_empty(), "初始ready的EXIT每步实际合法")
		check((rec["deposits"] as Array).is_empty() if step == 0 else not (rec["deposits"] as Array).is_empty(), 
			"初始ready两步路径只在真实换回后首次收盆")
		step += 1
	check(int(st["done"]) == 2, "初始ready的两步出口真实完成两盆")
	st = enabled_state(lv)
	st["cols"][1] = [] as Array[int]
	st["caps"][1] = 0
	st["jars"][1] = -1
	st["gone"][1] = true
	st["caps"][2] = 0
	st["gone"][2] = true
	st["done"] = 1
	outcome = S.advance_root_closed_search(S.begin_root_closed_search(st, lv))
	check(outcome["status"] == "UNKNOWN" and outcome["reason"] == "ready_pending_collect"
		and (outcome["path"] as Array).is_empty(), "无动作ready等待结算，不能伪造空路径EXIT或误判死")
	lv = JuiceLevel.from_dict({"id": 9898110, "capacity": 4, "targetCups": 3, 
		"initial": ["0|0,0", "1|1,1,1", "2|2,2,2,2"], 
		"columnCaps": {"initial": [2, 3, 4], "incoming": []}, "incoming": []})
	check(lv.validate().is_empty(), "三列变容量初始满盆无动作题面合法")
	st = enabled_state(lv)
	check(R.any_ready(st) and not R.has_any_move(st) and not R.is_win(st, lv), 
		"合法初始ready无move不等于stuck或win，等待Board正式结算")
	outcome = S.advance_root_closed_search(S.begin_root_closed_search(st, lv, 1, true))
	check(outcome["status"] == "UNKNOWN" and outcome["reason"] == "ready_pending_collect"
		and (outcome["path"] as Array).is_empty(), "完整会话也不伪造无动作ready的Hint动作")
	var deposits: Array = []
	R.run_deposit(st, lv, deposits)
	check(deposits.size() == 3 and R.is_win(st, lv), "无动作ready交给正式收盆后真实胜利")
	print("ROOT_SWAP_FIRST_POT_READY real_path=two_swaps no_move=UNKNOWN_pending_collect")
