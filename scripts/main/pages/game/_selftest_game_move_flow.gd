extends SceneTree



class FakePage:
	extends RefCounted
	var calls: Array[String] = []
	var auto_unlock_enabled: bool = false
	func check_mystery_auto_unlock(ctx) -> void :
		calls.append("auto_unlock")
		ctx.auto_unlock_applied = auto_unlock_enabled
	func apply_auto_unlock_feedback() -> void :
		calls.append("auto_feedback")
	func apply_move_feedback(steps: int) -> void :
		calls.append("feedback:%d" % steps)
	func apply_empty_rope_feedback() -> void :
		calls.append("empty_rope_feedback")
	func queue_move_prop_refresh() -> void :
		calls.append("queue_refresh")
	func persist_moved_state() -> void :
		calls.append("persist")

class FakeAbPlugin:
	extends RefCounted
	var raw_value: String = "yes"
	var status: String = "valid"
	var calls: Array[String] = []
	func getAbString(_key: String, _fallback: String) -> String:
		calls.append("get")
		return raw_value
	func getGroupStatus(_key: String) -> String:
		return status
	func dyeAbTest(_key: String) -> void :
		calls.append("dye")

var failures: Array[String] = []

func expect(ok: bool, message: String) -> void :
	if not ok:
		failures.append(message)
		SortLogger.error("GameMoveFlow selftest FAIL: " + message)

func _initialize() -> void :
	call_deferred("_run")

func _run() -> void :

	var context_script: GDScript = load("res://scripts/main/pages/game/flow/game_move/game_move_context.gd") as GDScript
	var flow_script: GDScript = load("res://scripts/main/pages/game/flow/game_move/game_move_flow.gd") as GDScript
	var persist_script: GDScript = load("res://scripts/main/pages/game/flow/game_move/persist_move_step.gd") as GDScript
	var runner_script: GDScript = load("res://scripts/frame/flow/flow_runner.gd") as GDScript
	var page: = FakePage.new()
	var ctx: Variant = context_script.new(page, 4)
	flow_script.run(ctx)
	if page.calls != ["auto_unlock", "feedback:4", "empty_rope_feedback", "queue_refresh", "persist"] or not ctx.sync_settlement_done:
		SortLogger.error("GameMoveFlow selftest FAIL: moved signal returned before ordered persistence: %s" % str(page.calls))
		quit(1)
		return
	persist_script.new().run(ctx)
	if page.calls.size() != 5:
		SortLogger.error("GameMoveFlow selftest FAIL: duplicate persistence")
		quit(1)
		return
	for enabled: bool in [false, true]:
		page.calls.clear()
		page.auto_unlock_enabled = enabled
		ctx = context_script.new(page, 4, true)
		flow_script.run(ctx)
		var expected: Array[String] = ["auto_unlock", "queue_refresh", "persist"]
		if enabled:
			expected.insert(1, "auto_feedback")
		if page.calls != expected or not ctx.sync_settlement_done or ctx.steps != 4:
			SortLogger.error("GameMoveFlow selftest FAIL: automatic update changed player move feedback or delayed settlement")
			quit(1)
			return
	var default_runner: Variant = runner_script.new()
	if not default_runner.get("_log_steps"):
		SortLogger.error("GameMoveFlow selftest FAIL: existing flow logging default changed")
		quit(1)
		return
	_test_mystery_config()
	_test_mystery_snapshot()
	var page_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript
	expect(page_script != null and page_script.can_instantiate(), "真实页面脚本及依赖应编译通过")
	if not failures.is_empty():
		quit(1)
		return
	SortLogger.info("GameMoveFlow selftest PASS")
	quit()


func _test_mystery_config() -> void :
	var config_script: GDScript = load("res://scripts/data/abtest/ab_configs/mystery_auto_unlock/mystery_auto_unlock_config.gd") as GDScript
	var config: Variant = config_script.new()
	var gateway: Variant = root.get_node("ABManager")
	var sdk: Variant = root.get_node("UniKit")
	var user: Variant = root.get_node("UserState")
	var saved_plugin: Object = sdk._plugin
	var saved_ready: bool = gateway._is_init_done
	var saved_locked: bool = gateway._startup_control_locked
	var saved_dyed: bool = gateway._mystery_auto_unlock_dyed
	var saved_overrides: Dictionary = user._debug_ab_overrides
	var registered: Variant = gateway.mystery_auto_unlock
	var saved_value: int = registered._value
	var saved_loaded: bool = registered._value_loaded
	var fake: = FakeAbPlugin.new()
	sdk._plugin = fake
	gateway._is_init_done = true
	gateway._startup_control_locked = false

	user._debug_ab_overrides = saved_overrides.duplicate(true)
	user._debug_ab_overrides.erase(config.key)
	for raw_value: String in ["no", "yes", "", "unknown", "YES", "1"]:
		fake.raw_value = raw_value
		config._value_loaded = false
		expect(config.is_auto_unlock_enabled() == (raw_value == "yes"), "SDK字符串映射 " + raw_value)
		var loaded: int = config._value
		expect(config.peek_value() == loaded and config._value == loaded, "面板读取不改业务缓存")
		config.load_value_silent()
		expect(config._value == loaded, "静默读取也走字符串钩子")
	fake.raw_value = "yes"
	for status: String in ["invalid", "unknown", ""]:
		fake.status = status
		config._value_loaded = false
		expect( not config.is_auto_unlock_enabled(), "未命中不可启用实验 " + status)
	fake.status = "valid"
	gateway._is_init_done = false
	config._value_loaded = false
	expect( not config.is_auto_unlock_enabled() and not config._value_loaded, "SDK未就绪不缓存fallback")
	gateway._is_init_done = true
	gateway._startup_control_locked = true
	config._value = 0
	config._value_loaded = true
	expect( not config.is_auto_unlock_enabled() and config.peek_value() == 0, "启动锁定不借晚到valid启用实验")
	for override: int in [0, 1, 2]:
		user._debug_ab_overrides[config.key] = override
		expect(config.is_auto_unlock_enabled() == (override == 1), "Cheat合法值优先且未知值回落")
	user._debug_ab_overrides.erase(config.key)
	gateway._startup_control_locked = false
	for raw_value: String in ["no", "yes"]:
		fake.raw_value = raw_value
		gateway._mystery_auto_unlock_dyed = false
		fake.calls.clear()
		gateway.dye_at_mystery_auto_unlock()
		gateway.dye_at_mystery_auto_unlock()
		expect(fake.calls.count("dye") == 1 and fake.calls.back() == "dye", "两组统一染色且进程内一次 " + raw_value)
		expect(fake.calls.size() >= 2 and fake.calls[-2] == "get", "SDK染色前紧邻get " + raw_value)
	_test_mystery_page_timing(gateway, fake)
	gateway._mystery_auto_unlock_dyed = false
	gateway._startup_control_locked = true
	fake.calls.clear()
	gateway.dye_at_mystery_auto_unlock()
	expect(fake.calls.is_empty(), "启动锁定不染色")
	gateway._startup_control_locked = false
	gateway._is_init_done = false
	gateway.dye_at_mystery_auto_unlock()
	expect(fake.calls.is_empty() and not gateway._mystery_auto_unlock_dyed, "未就绪不消耗染色守卫")
	_test_mystery_debug_button(gateway, fake)
	sdk._plugin = saved_plugin
	gateway._is_init_done = saved_ready
	gateway._startup_control_locked = saved_locked
	gateway._mystery_auto_unlock_dyed = saved_dyed
	registered._value = saved_value
	registered._value_loaded = saved_loaded
	user._debug_ab_overrides = saved_overrides


func _test_mystery_debug_button(gateway: Variant, fake: FakeAbPlugin) -> void :
	var commands_script: GDScript = load("res://scripts/debug/cheat_commands.gd") as GDScript
	var debug_level_script: GDScript = load("res://scripts/debug/juice_debug_level.gd") as GDScript
	var commands: Variant = commands_script.new()
	commands._ready()
	var defs: Array = commands.get("_command_defs")
	var entry: Dictionary = {}
	for definition: Dictionary in defs:
		if String(definition["name"]) == "mystery_auto_unlock_test":
			expect(entry.is_empty(), "问号自动解开测试命令不可重复注册")
			entry = definition
	expect( not entry.is_empty() and entry.get("category") == "游戏" and entry.get("section") == "关卡"
		and entry.get("version") == "1.0.10" and entry.has("handler"), "测试按钮在游戏关卡节注册且有实现")
	commands.free()
	var result: Dictionary = debug_level_script.load_mystery_auto_unlock_test()
	expect(bool(result["ok"]) and int(result["level"]) >= 2, "测试题面合法且避开第1关教学")
	var row: Dictionary = debug_level_script.MYSTERY_AUTO_UNLOCK_TEST_ROW.duplicate(true)
	var lv: JuiceLevel = JuiceLevel.from_dict(row)
	expect(lv.validate().is_empty() and lv.columns == 3 and lv.capacity == 4 and lv.groups_total == 2, 
		"最小测试题面为合法的三列两盆")
	var raw_before: String = JSON.stringify(lv.to_dict())
	var page_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript
	var context_script: GDScript = load("res://scripts/main/pages/game/flow/game_move/game_move_context.gd") as GDScript
	var board_script: GDScript = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript
	for raw_value: String in ["no", "yes"]:
		var board: Variant = board_script.new()
		board._level = lv
		board._state = JuiceRules.make_state(lv)
		var page: Variant = page_script.new()
		page._board = board
		var ctx: Variant = context_script.new(page, 1)
		gateway._is_init_done = true
		gateway._startup_control_locked = false
		gateway._mystery_auto_unlock_dyed = false
		fake.raw_value = raw_value
		fake.calls.clear()
		expect(board.state()["done"] == 0 and not board.can_auto_unlock_mystery(), "测试关从两盆起局，不提前满足实验资格")
		page.check_mystery_auto_unlock(ctx)
		expect(fake.calls.is_empty() and not gateway._mystery_auto_unlock_dyed, "用户移动前两组均不染色")

		var rec: Dictionary = JuiceRules.apply_move(board.state(), lv, 2, 2, 0)
		board._steps = 1
		board._history = [{"rec": rec}]
		expect( not rec.is_empty() and board.state()["done"] == 1
			and board.state()["cols"][1] == [1001, 1] and board.state()["cols"][2] == [1001, 1]
			and board.state()["gone"][0] and board.can_auto_unlock_mystery(), "移动一步收第一盆，剩最后一盆及两个问号")
		page.check_mystery_auto_unlock(ctx)
		expect(fake.calls.count("dye") == 1 and fake.calls[-2] == "get", "首次成功移动触达后由真实页面入口get后染色")
		expect(ctx.auto_unlock_applied == (raw_value == "yes"), "测试盘面沿当前SDK组决定自动解开")
		expect(board.state()["done"] == 1 and board.steps() == 1 and board.history_size() == 1, 
			"自动揭色不新增步数，跨绳最后一盆仍待玩家合并")
		if raw_value == "yes":
			expect(board.state()["cols"][1] == [1, 1] and board.state()["cols"][2] == [1, 1], "两个问号都显示真色")
			var merged: Dictionary = JuiceRules.clone_state(board.state())
			JuiceRules.apply_move(merged, lv, 2, 0, 1)
			expect(JuiceRules.is_win(merged, lv), "测试盘面揭色后可正常合并收盆")
		else:
			expect(board.can_auto_unlock_mystery(), "对照组保留两个问号")
		page.free()
		board.free()
	expect(JSON.stringify(lv.to_dict()) == raw_before, "测试入口不修改原始题面")



func _test_mystery_page_timing(gateway: Variant, fake: FakeAbPlugin) -> void :
	var rules: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_rules.gd") as GDScript
	var level_script: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_level.gd") as GDScript
	var board_script: GDScript = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript
	var page_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript
	var context_script: GDScript = load("res://scripts/main/pages/game/flow/game_move/game_move_context.gd") as GDScript
	for hidden: bool in [false, true]:
		var row: String = "1|?1,?1,1" if hidden else "1|1,1,1"
		var lv: Variant = level_script.from_dict({"id": 9009, "capacity": 5, "targetCups": 2, 
			"initial": ["-|0", "0|0,0,0,0", row, "-|1,1"], "incoming": []})
		for raw_value: String in ["no", "yes"]:
			var board: Variant = board_script.new()
			board._state = rules.make_state(lv)
			board._level = lv
			var page: Variant = page_script.new()
			page._board = board
			var ctx: Variant = context_script.new(page, 2, true)
			fake.raw_value = raw_value
			fake.calls.clear()
			gateway._mystery_auto_unlock_dyed = false
			page.check_mystery_auto_unlock(ctx)
			expect(fake.calls.is_empty() and not gateway._mystery_auto_unlock_dyed, "未到最后一盆不提前染色")
			rules.apply_move(board._state, lv, 0, 0, 1)
			expect(int(board._state["done"]) == 1, "正式收盆后仅剩最后一盆：%s" % str(board._state))
			var before: String = rules.state_key(board._state)
			page.check_mystery_auto_unlock(ctx)
			if hidden:
				expect(fake.calls.count("dye") == 1 and fake.calls.back() == "dye"
					and fake.calls[-2] == "get", "最后一盆还有多个问号时两组均get后染色")
			else:
				expect(fake.calls.is_empty() and not gateway._mystery_auto_unlock_dyed, 
					"最后一盆无问号时不读取分组、不染色且不消耗首次守卫")
			expect(ctx.auto_unlock_applied == (hidden and raw_value == "yes"), "只有有问号的实验组实际揭色")
			if hidden and raw_value == "yes":
				expect(board._state["cols"][2] == [1, 1, 1], "真实页面入口解开全部剩余问号")
			else:
				expect(rules.state_key(board._state) == before, "对照与零问号盘面保持原状态")
			page.check_mystery_auto_unlock(ctx)
			expect(fake.calls.count("dye") == (1 if hidden else 0), "重复页面检查遵守有问号的染色资格")
			if not hidden:
				board._state["cols"][2][0] = level_script.hide_type(1)
				page.check_mystery_auto_unlock(ctx)
				expect(fake.calls.count("dye") == 1 and fake.calls.back() == "dye"
					and fake.calls[-2] == "get", "零问号检查后首次出现问号仍可正常get后染色")
				expect(ctx.auto_unlock_applied == (raw_value == "yes"), "一个问号也按两组正式行为处理")
			page.free()
			board.free()


func _test_mystery_snapshot() -> void :
	var rules: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_rules.gd") as GDScript
	var level_script: GDScript = load("res://scripts/gameplay/juice_sort/core/juice_level.gd") as GDScript
	var board_script: GDScript = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd") as GDScript
	var lv: Variant = level_script.from_dict({"id": 9009, "capacity": 5, "targetCups": 2, 
		"initial": ["-|0", "0|0,0,0,0", "1|?1,?1,1,1,1"], "incoming": []})
	var state: Dictionary = rules.make_state(lv)
	rules.apply_move(state, lv, 0, 0, 1)
	var before: String = rules.state_key(state)
	var rec: Dictionary = rules.apply_move(state, lv, 2, 4, 0)

	var board: Variant = board_script.new()
	board._state = state
	board._level = lv
	board._steps = 2
	board._history = [{"rec": rec, "order": [0, 2] as Array[int]}]
	board._order = [0, 2] as Array[int]
	expect(board.can_auto_unlock_mystery(), "最后一盆进入染色资格")
	board.tutorial_demo_only = true
	expect( not board.can_auto_unlock_mystery() and not board.auto_unlock_mystery(), "教学演示不染色或解开")
	board.tutorial_demo_only = false
	expect(board.auto_unlock_mystery() and board.steps() == 2 and board.history_size() == 1, "自动解开不新增步数或历史")
	expect( not board.auto_unlock_mystery(), "盘面重复调用不再次解开")
	expect( not board.can_auto_unlock_mystery(), "跨绳问号全部解开后不再符合染色资格")
	var blob: Dictionary = JSON.parse_string(JSON.stringify(board.snapshot()))
	var restored: Variant = board_script.new()
	restored._state = rules.state_from_dict(blob["state"], lv)
	restored._restore_undo_history(lv, blob["undo_history"])
	expect(restored.history_size() == 1, "自动快照及移动历史JSON恢复")
	if restored.history_size() == 1:
		rules.undo_move(restored._state, restored._history[0]["rec"])
		expect(rules.state_key(restored._state) == before, "恢复后的撤销还原自动变更和真实移动")
	var old_entry: Dictionary = (blob["undo_history"][0] as Dictionary).duplicate(true)
	old_entry["rec"].erase("auto_unlock_before")
	old_entry["rec"].erase("had_auto_unlock_deposits")
	expect( not restored._undo_entry_from_dict(old_entry, lv).is_empty(), "旧存档缺自动字段保持兼容")
	old_entry = (blob["undo_history"][0] as Dictionary).duplicate(true)
	old_entry["rec"]["auto_unlock_before"] = "invalid"
	expect(restored._undo_entry_from_dict(old_entry, lv).is_empty(), "坏自动快照不得进入撤销历史")
	board.free()
	restored.free()
