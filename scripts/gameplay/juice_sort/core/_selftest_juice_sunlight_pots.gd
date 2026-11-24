extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	_test_rules()
	var manager: Node = root.get_node("LevelManager")
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/game/juice_sunlight_pot_recipes_index.json"))
	_check((index["levels"] as Array).size() == 36, "固定36关")
	_check(int(index["count"]) == 180, "36关覆盖5个人群")
	var processed: int = 0
	var ready: int = 0
	var skipped: int = 0
	for key: String in index["addresses"]:
		var parts: PackedStringArray = key.split("|")
		var recipe: Dictionary = manager.call("read_sunlight_pot_recipe", int(parts[0]), parts[1], parts[2])
		_check( not recipe.is_empty(), "索引可以读取对应记录")
		if recipe.get("status") == "ready":
			ready += 1
			var converted: Dictionary = JuiceSunlightPotVariant.apply_recipe(recipe["source_raw"], recipe)
			_check( not converted.is_empty(), "原题身份匹配后可应用改造")
			if converted.is_empty():
				continue
			_check(converted["incoming"] == recipe["source_raw"]["incoming"], "补货与后续同色花不修改")
			var level: JuiceLevel = JuiceLevel.from_dict(converted)
			_check(level.validate().is_empty() and level.types <= 10, "改造题校验且不超十色")
			var state: Dictionary = JuiceRules.make_state(level)
			var before: String = JuiceRules.state_key(state)
			var history: Array = []
			var first: Dictionary = {}
			for move: Dictionary in recipe["proof"]:
				var record: Dictionary = JuiceRules.apply_move(state, level, int(move["src"]), int(move["j"]), int(move["dst"]))
				_check( not record.is_empty(), "预计算路线在真实规则中合法")
				history.append(record)
				if not (record.get("deposits", []) as Array).is_empty():
					first = record["deposits"][0]
					break
			_check( not first.is_empty() and bool(first.get("sun", false)), "第一盆确实为太阳")
			_check( not (state["frozen_pots"] as Array).has(true), "第一盆解冻所有其它盆")
			var restored: Dictionary = JuiceRules.state_from_dict(JuiceRules.state_to_dict(state), level)
			_check( not restored.is_empty() and JuiceRules.state_key(restored) == JuiceRules.state_key(state), "解冻后续局匹配")
			history.reverse()
			for record: Dictionary in history:
				JuiceRules.undo_move(state, record)
			_check(JuiceRules.state_key(state) == before, "撤销全部路线恢复初始冻盆")
			var changed: Dictionary = (recipe["source_raw"] as Dictionary).duplicate(true)
			changed["capacity"] = 99
			_check(JuiceSunlightPotVariant.apply_recipe(changed, recipe).is_empty(), "版本变化不套用旧记录")
		else:
			skipped += 1
			_check(recipe.get("reason") == "original_color_lock_conflict", "受影响的原色锁候选明确跳过")
			_check(JuiceSunlightPotVariant.apply_recipe(recipe["source_raw"], recipe).is_empty(), "跳过候选保持原题")
		processed += 1
		if processed % 8 == 0:
			await process_frame
	_check((manager.call("read_sunlight_pot_recipe", 41, "missing", "default") as Dictionary).is_empty(), "缺记录不选其它题")
	_check(ready == 163 and skipped == 17, "163个启用，17个原色锁冲突保持原题")
	print("SUNLIGHT_POTS_CORE %d checks %d candidates" % [_checks, processed])
	print("PASS" if _failures.is_empty() else "FAIL")
	quit(0 if _failures.is_empty() else 1)


func _test_rules() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 41, "capacity": 3, "targetCups": 3, 
		"sunlight": {"typeId": 2}, "frozenPots": [3, 5], 
		"initial": ["-|2", "-|0", "-|1", "0|0,0", "2|2,2", "1|1,1"], "incoming": []})
	_check(level.validate().is_empty(), "冻盆题面合法")
	var state: Dictionary = JuiceRules.make_state(level)
	_check(JuiceRules.move_info(state, 1, 0, 3) == 1, "冻盆仍可接花")
	var assembled: Dictionary = JuiceRules.apply_move(state, level, 1, 0, 3)
	_check(state["done"] == 0 and JuiceRules.deposit_ready(state, 3) == 0, "满冻盆不消除")
	_check(JuiceRules.move_info(state, 3, 2, 1) == 1, "冻盆仍可向空列搬花")
	var cloned: Dictionary = JuiceRules.clone_state(state)
	(cloned["frozen_pots"] as Array[bool]).fill(false)
	_check(JuiceRules.state_key(cloned) != JuiceRules.state_key(state), "冻盆进入状态指纹")
	var sunshine: Dictionary = JuiceRules.apply_move(state, level, 0, 0, 4)
	_check(state["done"] == 2 and sunshine["deposits"][0]["thawed_pots"].size() == 2, "阳光当帧解冻并级联")
	JuiceRules.undo_move(state, sunshine, true)
	_check(JuiceRules.is_frozen_pot(state, 3) and JuiceRules.is_frozen_pot(state, 5), "撤销回冻不受问号记忆影响")
	JuiceRules.undo_move(state, assembled)
	_check(JuiceRules.state_from_dict(JuiceRules.state_to_dict(state), level).size() > 0, "初始续局保留冻盆")
	var bad: Dictionary = JuiceRules.state_to_dict(state)
	bad.erase("frozen_pots")
	_check(JuiceRules.state_from_dict(bad, level).is_empty(), "丢失冻盆字段的坏档拒绝")


func _check(condition: bool, label: String) -> void :
	_checks += 1
	if not condition:
		_failures.append(label)
		printerr("FAIL: " + label)
