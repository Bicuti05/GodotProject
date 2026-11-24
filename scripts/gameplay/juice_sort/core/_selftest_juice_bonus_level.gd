extends SceneTree











const ROW_SINGLE: = {"capacity": 3, "targetCups": 3, 
	"initial": ["-|", "0|1,2,0", "1|2,0,1", "2|0,1,2"], "incoming": []}

const ROW_MULTI_YELLOW: = {"capacity": 2, "targetCups": 3, 
	"initial": ["0|0,1", "0|1,0", "1|0,0"], "incoming": []}

const ROW_NO_SINGLE: = {"capacity": 2, "targetCups": 4, 
	"initial": ["0|0,1", "0|1,0", "1|0,1", "1|1,0"], "incoming": []}

const ROW_INCOMING_SINGLE: = {"capacity": 2, "targetCups": 5, 
	"initial": ["0|0,1", "0|1,0", "1|0,1", "1|1,0"], "incoming": ["2|2,2"]}

const ROW_YELLOW_INCOMING: = {"capacity": 2, "targetCups": 5, 
	"initial": ["0|0,0", "1|1,1", "1|1,1", "1|1,1"], "incoming": ["2|2,2"]}

var _failures: Array[String] = []


func _initialize() -> void :
	_test_level_numbers()
	_test_reward()
	_test_pick_plan_v1()
	_test_pick_plan_v2()
	_test_has_candidate()
	_test_valid_bonus_type()
	_finish()


func _test_level_numbers() -> void :
	for lv: int in [13, 23, 33, 43, 53, 13 + 10 * 20]:
		_check(JuiceBonusLevel.is_bonus_level(lv), "第 %d 关应是 Bonus Level" % lv)
	for lv: int in [0, 1, 3, 10, 12, 14, 18, 20, 22, 24, 28, 30, 32, 34, 42, 44, 58]:
		_check( not JuiceBonusLevel.is_bonus_level(lv), "第 %d 关不应是 Bonus Level" % lv)


func _test_reward() -> void :
	_check(JuiceBonusLevel.reward_coins(false) == 100, "1.0 奖励应为 100")
	_check(JuiceBonusLevel.reward_coins(true) == 300, "2.0 实验组奖励应为 300")


func _test_pick_plan_v1() -> void :
	var single: JuiceLevel = JuiceLevel.from_dict(ROW_SINGLE)
	var multi: JuiceLevel = JuiceLevel.from_dict(ROW_MULTI_YELLOW)
	var no_single: JuiceLevel = JuiceLevel.from_dict(ROW_NO_SINGLE)
	var incoming_single: JuiceLevel = JuiceLevel.from_dict(ROW_INCOMING_SINGLE)
	for lv: Variant in [single, multi, no_single, incoming_single]:
		var level: JuiceLevel = lv as JuiceLevel
		_check(level.validate().is_empty(), "夹具题面应合法:%s" % str(level.validate()))

	_check(int(JuiceBonusLevel.pick_plan(null, PackedInt32Array()).get("type", 0))
		== JuiceBonusLevel.NO_BONUS_TYPE, "空题面应跳过奖励关")


	var no_yellow: = PackedInt32Array([0, 1, 2])
	var seen: Dictionary = {}
	var rng: = RandomNumberGenerator.new()
	for seed_value: int in range(1, 60):
		rng.seed = seed_value
		var plan: Dictionary = JuiceBonusLevel.pick_plan(single, no_yellow, false, rng)
		var t: int = int(plan["type"])
		_check(t >= 0 and t < single.types, "金猪颜色 %d 必须在 [0,%d) 内" % [t, single.types])
		_check(int(plan["recolor_from"]) == -1 and int(plan["recolor_to"]) == -1, "无黄盆时不应换色")
		seen[t] = true
	_check(seen.size() > 1, "不同随机种子应能选到不同颜色(只选到 %d 种)" % seen.size())
	var a: = RandomNumberGenerator.new()
	var b: = RandomNumberGenerator.new()
	a.seed = 7
	b.seed = 7
	_check(JuiceBonusLevel.pick_plan(single, no_yellow, false, a)
		== JuiceBonusLevel.pick_plan(single, no_yellow, false, b), "同种子应得到同一方案")


	var plan_yellow: Dictionary = JuiceBonusLevel.pick_plan(single, PackedInt32Array([4, 0, 1]))
	_check(int(plan_yellow["type"]) == 0, "黄色 1 盆时应选黄色(0 号)")
	_check(int(plan_yellow["recolor_from"]) == -1 and int(plan_yellow["recolor_to"]) == -1, 
		"黄色 1 盆时不需要换色")


	var plan_multi: Dictionary = JuiceBonusLevel.pick_plan(multi, PackedInt32Array([4, 1]))
	_check(int(plan_multi["type"]) == 1, "黄盆多个时应选只有 1 盆的 1 号色")
	_check(int(plan_multi["recolor_from"]) == 0 and int(plan_multi["recolor_to"]) == 1, 
		"黄盆多个时应把 0 号(黄)显示成 1 号的颜色")

	var plan_plain: Dictionary = JuiceBonusLevel.pick_plan(multi, PackedInt32Array([0, 1]))
	_check(int(plan_plain["type"]) == 1 and int(plan_plain["recolor_from"]) == -1, 
		"无黄盆时应选单盆的 1 号色且不换色")


	var plan_skip: Dictionary = JuiceBonusLevel.pick_plan(no_single, PackedInt32Array([0, 1]))
	_check(int(plan_skip["type"]) == JuiceBonusLevel.NO_BONUS_TYPE, "没有单盆颜色时应跳过奖励关")
	_check(String(plan_skip["reason"]) == JuiceBonusLevel.REASON_NO_SINGLE_POT, 
		"1.0 跳过原因应为「没有单盆颜色」")


	var plan_incoming: Dictionary = JuiceBonusLevel.pick_plan(
		incoming_single, PackedInt32Array([0, 1, 2]))
	_check(int(plan_incoming["type"]) == 2, "1.0 应选中只在补货列出现的单盆颜色")


func _test_pick_plan_v2() -> void :
	var single: JuiceLevel = JuiceLevel.from_dict(ROW_SINGLE)
	var multi: JuiceLevel = JuiceLevel.from_dict(ROW_MULTI_YELLOW)
	var no_single: JuiceLevel = JuiceLevel.from_dict(ROW_NO_SINGLE)
	var incoming_single: JuiceLevel = JuiceLevel.from_dict(ROW_INCOMING_SINGLE)
	var yellow_incoming: JuiceLevel = JuiceLevel.from_dict(ROW_YELLOW_INCOMING)
	for lv: Variant in [single, multi, no_single, incoming_single, yellow_incoming]:
		var level: JuiceLevel = lv as JuiceLevel
		_check(level.validate().is_empty(), "夹具题面应合法:%s" % str(level.validate()))


	var plan_yellow: Dictionary = JuiceBonusLevel.pick_plan(
		single, PackedInt32Array([4, 0, 1]), true)
	_check(int(plan_yellow["type"]) == 0, "2.0 黄色 1 盆且首屏可见时应选黄色(0 号)")
	_check(int(plan_yellow["recolor_from"]) == -1, "2.0 选黄色时不需要换色")


	var plan_multi: Dictionary = JuiceBonusLevel.pick_plan(
		multi, PackedInt32Array([4, 1]), true)
	_check(int(plan_multi["type"]) == 1, "2.0 黄盆多个时应选只有 1 盆的 1 号色")
	_check(int(plan_multi["recolor_from"]) == 0 and int(plan_multi["recolor_to"]) == 1, 
		"2.0 黄盆多个时应把 0 号(黄)显示成 1 号的颜色")


	var plan_skip: Dictionary = JuiceBonusLevel.pick_plan(no_single, PackedInt32Array([0, 1]), true)
	_check(int(plan_skip["type"]) == JuiceBonusLevel.NO_BONUS_TYPE, "2.0 没有单盆颜色时应跳过")
	_check(String(plan_skip["reason"]) == JuiceBonusLevel.REASON_NO_SINGLE_POT, 
		"2.0 应区分「没有单盆颜色」")


	var plan_incoming: Dictionary = JuiceBonusLevel.pick_plan(
		incoming_single, PackedInt32Array([0, 1, 2]), true)
	_check(int(plan_incoming["type"]) == JuiceBonusLevel.NO_BONUS_TYPE, 
		"2.0 单盆颜色只在补货列时应跳过奖励关")
	_check(String(plan_incoming["reason"]) == JuiceBonusLevel.REASON_NOT_ON_FIRST_SCREEN, 
		"2.0 跳过原因应区分「单盆颜色不在首屏」")


	var plan_yellow_in: Dictionary = JuiceBonusLevel.pick_plan(
		yellow_incoming, PackedInt32Array([0, 1, 4]), true)
	_check(int(plan_yellow_in["type"]) == 0, "2.0 应选首屏可见的 0 号色，不选补货列的黄色")
	_check(int(plan_yellow_in["recolor_from"]) == 2 and int(plan_yellow_in["recolor_to"]) == 0, 
		"2.0 黄色未被选中时应把 2 号(黄)显示成 0 号的颜色")


func _test_has_candidate() -> void :
	var single: JuiceLevel = JuiceLevel.from_dict(ROW_SINGLE)
	var multi: JuiceLevel = JuiceLevel.from_dict(ROW_MULTI_YELLOW)
	var no_single: JuiceLevel = JuiceLevel.from_dict(ROW_NO_SINGLE)
	var incoming_single: JuiceLevel = JuiceLevel.from_dict(ROW_INCOMING_SINGLE)
	var yellow_incoming: JuiceLevel = JuiceLevel.from_dict(ROW_YELLOW_INCOMING)

	_check(JuiceBonusLevel.has_bonus_candidate(single), "1.0 单盆颜色存在时应可启用奖励关")
	_check(JuiceBonusLevel.has_bonus_candidate(multi), "1.0 存在单盆颜色时应可启用奖励关")
	_check( not JuiceBonusLevel.has_bonus_candidate(no_single), "1.0 所有颜色都多盆时应跳过奖励关")
	_check(JuiceBonusLevel.has_bonus_candidate(incoming_single), "1.0 补货列单盆颜色也满足资格")
	_check(JuiceBonusLevel.has_bonus_candidate(yellow_incoming), "1.0 首屏有单盆颜色时应可启用奖励关")
	_check( not JuiceBonusLevel.has_bonus_candidate(null), "空题面不可启用奖励关")

	_check(JuiceBonusLevel.has_bonus_candidate(single, true), "2.0 首屏单盆颜色存在时应可启用奖励关")
	_check(JuiceBonusLevel.has_bonus_candidate(multi, true), "2.0 存在首屏单盆颜色时应可启用奖励关")
	_check( not JuiceBonusLevel.has_bonus_candidate(no_single, true), "2.0 所有颜色都多盆时应跳过奖励关")
	_check( not JuiceBonusLevel.has_bonus_candidate(incoming_single, true), 
		"2.0 单盆颜色只在补货列时不可启用奖励关")
	_check(JuiceBonusLevel.has_bonus_candidate(yellow_incoming, true), 
		"2.0 首屏有单盆颜色时应可启用奖励关")
	_check( not JuiceBonusLevel.has_bonus_candidate(null, true), "2.0 空题面不可启用奖励关")


func _test_valid_bonus_type() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict(ROW_SINGLE)
	_check(JuiceBonusLevel.is_valid_bonus_type(lv, 0), "0 号花型合法")
	_check(JuiceBonusLevel.is_valid_bonus_type(lv, lv.types - 1), "最大花型号合法")
	_check( not JuiceBonusLevel.is_valid_bonus_type(lv, -1), "-1 表示无金猪,不算合法花型")
	_check( not JuiceBonusLevel.is_valid_bonus_type(lv, lv.types), "越界花型号非法")
	_check( not JuiceBonusLevel.is_valid_bonus_type(null, 0), "空题面下任何花型都非法")


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)


func _finish() -> void :
	if _failures.is_empty():
		print("[selftest_juice_bonus_level] ALL PASS")
		quit(0)
		return
	for f: String in _failures:
		printerr("[selftest_juice_bonus_level] FAIL: " + f)
	quit(1)
