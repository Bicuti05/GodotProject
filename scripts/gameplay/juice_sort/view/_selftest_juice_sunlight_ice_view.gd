extends SceneTree

const EXAMPLES_PATH: = "res://docs/gameplay/examples/juice-sunlight-ice-levels.json"
const MINIMAL_ROW: = {
	"id": 1001, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
	"initial": ["-|2", "2|2,2", "0|0,i0,0", "1|1,1,1"], "incoming": [], 
}

var _failures: Array[String] = []
var _checks: int = 0


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	var board_scene: PackedScene = load(
		"res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: Variant = _new_board(board_scene, MINIMAL_ROW)
	_test_formal_binding(board)
	await _test_move_and_melt(board)
	_free_board(board)

	if OS.get_cmdline_user_args().has("--candidate-levels"):
		var doc: Dictionary = _load_examples()
		if not doc.is_empty():
			var levels: Array = doc.get("levels", []) as Array
			if not levels.is_empty():
				await _test_continue_during_melt(board_scene, levels[0])
	await _test_frozen_connections(board_scene)
	await _test_ice_mode_switch(board_scene)
	await _test_continuation_and_cancel(board_scene)
	_test_quota_order()
	await _test_ambient_reset()
	var audio_manager: Node = root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.call("stop_all_sfx")
	for frame in 3:
		await process_frame
	_finish()


func _load_examples() -> Dictionary:
	if not FileAccess.file_exists(EXAMPLES_PATH):
		_fail("缺少验收数据 %s" % EXAMPLES_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXAMPLES_PATH))
	if not (parsed is Dictionary):
		_fail("验收数据不是 JSON 对象")
		return {}
	return parsed


func _new_board(board_scene: PackedScene, row: Dictionary) -> Variant:
	var level: JuiceLevel = JuiceLevel.from_dict(row)
	var board: Variant = board_scene.instantiate()
	board.size = Vector2(1080, 2340)
	root.add_child(board)
	board.setup(level)
	return board


func _free_board(board: Variant) -> void :
	board.set_process(false)
	board.cancel_sunlight_animation()
	board._cancel_closed_check()
	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()


func _test_formal_binding(board: Variant) -> void :
	_check(board.sunlight_fruit_texture != null, "阳光花正式贴图已绑定")
	_check(board.sunlight_blender_texture != null, "阳光空盆正式贴图已绑定")
	_check(board.sunlight_full_blender_texture != null, "阳光满盆正式贴图已绑定")
	_check(board._texture_for_fruit(2) == board.sunlight_fruit_texture, "阳光类型使用独立花朵贴图")
	_check(board._texture_for_blender(2) == board.sunlight_blender_texture, "阳光类型使用独立空盆贴图")
	_check(board.full_blender_texture_for_type(2) == board.sunlight_full_blender_texture, 
		"阳光类型使用独立满盆贴图")
	_check(board.color_for_type(2) == JuiceTheme.SUN_COLOR, "阳光类型使用独立主题色")
	var frozen_fruit: JuiceFruit = _fruit_at(board, 2, 1)
	_check(frozen_fruit != null and frozen_fruit.get("_ice_body").texture != null, "冰层正式贴图已绑定")
	_check(frozen_fruit != null and frozen_fruit.is_frozen(), "冻结花显示冰层状态")
	_check(frozen_fruit != null and bool(frozen_fruit.get("_ice_body").visible), "冻结花冰层可见")
	var normal_fruit: JuiceFruit = _fruit_at(board, 2, 0)
	_check(normal_fruit != null and not normal_fruit.is_frozen(), "普通花不带冰层")
	var cups: Array[int] = board.state()["cups"]
	cups.append(2)
	_check(board.cup_textures().size() == 1 and board.cup_textures()[0] == board.sunlight_full_blender_texture, 
		"订单栏太阳格使用阳光满盆贴图")
	_check(board.cup_colors().size() == 1 and board.cup_colors()[0] == JuiceTheme.SUN_COLOR, 
		"订单栏太阳格使用阳光主题色")
	board.setup(board.level())


func _test_move_and_melt(board: Variant) -> void :
	var saved: Dictionary = board.snapshot()
	var moved_info: Dictionary = {"snapshot_done": -1}
	board.moved.connect( func(_steps: int) -> void :
		moved_info["snapshot_done"] = int(board.snapshot()["state"]["done"]))
	board.cup_collected.connect( func(fruit_type: int, nth: int, color: Color, from_rect: Rect2) -> void :
		if board.level().is_sunlight_type(fruit_type):
			board.start_sunlight_collection(nth, from_rect, Rect2(50, 50, 100, 100)))
	_check(board.try_move(0, 0, 1), "最小验证题直接 try_move 成功")
	_check(int(moved_info["snapshot_done"]) == 3, "moved 同步时快照已包含最终逻辑状态")
	_check(int(board.state()["done"]) == 3, "moved 同步时规则状态已完成全部收集")
	var history: Array = board.get("_history")
	var rec: Dictionary = history[history.size() - 1]["rec"]
	var deposits: Array = rec["deposits"]
	_check(deposits.size() == 3 and bool(deposits[0]["sun"]), "首个收集事件是阳光")
	_check((deposits[0]["melted"] as Array).size() == 1, "阳光事件记录融冰坐标")
	_check(_same_int_array(board.state()["cups"], [2, 0, 1] as Array[int]), "cups 有序记录阳光与花盆")
	_check( not (board.get("_sunlight_batches") as Array).is_empty(), "融冰视觉队列进行中")
	_check(bool(board.get("_input_enabled")), "融冰动画不锁输入")
	_check(_frozen_visual_in_beats(board), "收集拍保留冰层视觉节点")
	var beats: Array = board.get("_beats")
	board.set("_t", 1.2)
	board._advance_beats()
	_check( not (board.get("_sunlight_flight") as Dictionary).is_empty(), "太阳收满后启动收集器飞行")
	_check( not bool(beats[1]["started"]), "级联花列等待收集器与融冰表现")
	board._tick_sunlight_collection(0.48)
	var effect: SunlightFx = board.get("_sunlight_fx")
	_check(effect.is_running(), "收集器0.48秒到达后开始日光")
	if not effect.is_running():
		return
	effect.set_clock(0.38)
	var batch: Dictionary = board.get("_sunlight_active_batch")
	var ice: JuiceFruit = batch["flowers"][0]
	_check(is_equal_approx(float(ice.get("_melt_progress")), 0.0), "日光0.38秒时冰层开始融化")
	effect.set_clock(1.0)
	_check(float(ice.get("_melt_progress")) > 0.0 and not bool(batch["released"]), "融冰中保持级联表现等待")
	effect.set_clock(effect.ice_melt_duration())
	board._tick_sunlight_collection(0.0)
	_check(bool(batch["released"]) and not ice.is_frozen(), "前后冰层融完释放级联花列")
	board._advance_beats()
	_check(bool(beats[1]["started"]), "融冰后花列收集表现正常起播")

	_check(board.restore(board.level(), saved), "续局恢复冻结题面")
	var frozen_fruit: JuiceFruit = _fruit_at(board, 2, 1)
	_check(frozen_fruit != null and frozen_fruit.is_frozen() and frozen_fruit.fruit_type == 2000, 
		"续局重建冻结花")
	_check((board.get("_sunlight_batches") as Array).is_empty(), "续局清空融冰等待")
	_check(board.try_move(0, 0, 1), "重开后可再次触发阳光融冰")
	board.setup(board.level())
	_check((board.get("_sunlight_batches") as Array).is_empty(), "setup 清空融冰等待")
	await process_frame


func _test_continue_during_melt(board_scene: PackedScene, row: Dictionary) -> void :
	var undo_board: Variant = _new_board(board_scene, row)
	var level: JuiceLevel = undo_board.level()
	var path: Array = JuiceSolver.hint_win_path(undo_board.state(), level, {
		"max_routes": 20000, "width": 8, "route_nodes": 30000, "route_depth": 50, 
	})
	_check( not path.is_empty(), "候选阳光题找到通关路线")
	if path.is_empty():
		_free_board(undo_board)
		return
	var pre_sun_key: String = ""
	var sun_index: int = -1
	for index in path.size():
		var move: Dictionary = path[index]
		pre_sun_key = JuiceRules.state_key(undo_board.state())
		if not undo_board.try_move(int(move["src"]), int(move["j"]), int(move["dst"])):
			break
		if _last_move_has_sun(undo_board):
			sun_index = index
			break
	_check(sun_index >= 0 and sun_index + 1 < path.size(), "到达阳光收集且仍有后续走法")
	if sun_index < 0 or sun_index + 1 >= path.size():
		_free_board(undo_board)
		return
	_check( not (undo_board.get("_sunlight_batches") as Array).is_empty(), 
		"阳光收集后融冰动画仍在进行")
	_check(bool(undo_board.get("_input_enabled")), "融冰动画期间输入保持开启")
	_check(undo_board.undo(), "非终局阳光移动可撤销")
	_check(JuiceRules.state_key(undo_board.state()) == pre_sun_key, "撤销恢复阳光步之前盘面")
	_check((undo_board.get("_sunlight_batches") as Array).is_empty(), 
		"撤销取消融冰等待")
	_free_board(undo_board)
	await process_frame

	var board: Variant = _new_board(board_scene, row)
	var continue_sun_index: int = -1
	for index in path.size():
		var move: Dictionary = path[index]
		if not board.try_move(int(move["src"]), int(move["j"]), int(move["dst"])):
			break
		if _last_move_has_sun(board):
			continue_sun_index = index
			break
	_check(continue_sun_index >= 0 and continue_sun_index + 1 < path.size(), 
		"第二块盘面到达阳光收集且仍有后续走法")
	if continue_sun_index < 0 or continue_sun_index + 1 >= path.size():
		_free_board(board)
		return
	_check( not (board.get("_sunlight_batches") as Array).is_empty(), 
		"第二块盘面融冰动画仍在进行")
	_check(bool(board.get("_input_enabled")), "第二块盘面融冰动画期间输入保持开启")
	var advanced: bool = false
	var waited: int = 0
	while waited < 90 and not advanced\
	and not (board.get("_sunlight_batches") as Array).is_empty():
		for move: Dictionary in JuiceRules.useful_moves(board.state()):
			var src: int = int(move["src"])
			var dst: int = int(move["dst"])
			if board._replenish_column_pending(src) or board._replenish_column_pending(dst):
				continue
			if board.try_move(src, int(move["j"]), dst):
				advanced = true
				break
		if advanced:
			break
		await process_frame
		waited += 1
	_check(advanced, "融冰动画中可继续下一步 waited=%d" % waited)
	_free_board(board)
	await process_frame


func _test_frozen_connections(board_scene: PackedScene) -> void :
	for variant in ["frozen_source", "frozen_target", "both_frozen"]:
		var row: Dictionary = {
			"id": 1004, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
			"initial": ["-|2", "-|0", "-|1", "0|0,0", "2|2,2", "1|1,1"], "incoming": [], 
		}
		if variant != "frozen_target":
			row["initial"][1] = "-|i0"
		if variant != "frozen_source":
			row["initial"][3] = "0|0,i0"
		var board: Variant = _new_board(board_scene, row)
		var rejected: Array[int] = []
		board.move_rejected.connect( func(reason: int) -> void : rejected.append(reason))
		var initial_key: String = JuiceRules.state_key(board.state())
		var connection: Dictionary = board.capture_connection(1, 0, 3)
		_check( not connection.is_empty() and int(connection["type"]) == 0, 
			"%s 同色连接反馈按真实颜色识别" % variant)
		_drop(board, 1, 0, 3)
		_check(board.steps() == 1 and rejected.is_empty(), "%s 玩家松手成功且不报拒绝" % variant)
		_check(board.state()["cols"][3].size() == 3 and int(board.state()["done"]) == 0, 
			"%s 接满含冰列不消除" % variant)
		_check(JuiceRules.deposit_ready(board.state(), 3) == 0 and board.sync_error().is_empty(), 
			"%s 规则与节点保留冻结状态" % variant)
		_check(board.undo() and JuiceRules.state_key(board.state()) == initial_key, 
			"%s 撤销连接恢复盘面" % variant)
		_drop(board, 1, 0, 3)
		_check(board.try_move(0, 0, 4), "%s 阳光列可以消除" % variant)
		_check(_same_int_array(board.state()["cups"], [2, 0] as Array[int]), 
			"%s 阳光后自动级联消除原冰列" % variant)
		_check(board.undo() and board.state()["cols"][3].size() == 3
			and JuiceRules.deposit_ready(board.state(), 3) == 0, 
			"%s 撤销阳光恢复接满但冰住的列" % variant)
		_free_board(board)
		await process_frame


func _test_ice_mode_switch(board_scene: PackedScene) -> void :
	for mode: String in [JuiceLevel.ICE_BLOCK_CONNECTION, JuiceLevel.ICE_BLOCK_COLLECTION]:
		for variant: String in ["frozen_source", "frozen_target", "both_frozen"]:
			var row: Dictionary = {
				"id": 1004, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, "iceMode": mode, 
				"initial": ["-|2", "-|0", "-|1", "0|0,0", "2|2,2", "1|1,1"], "incoming": [], 
			}
			if variant != "frozen_target":
				row["initial"][1] = "-|i0"
			if variant != "frozen_source":
				row["initial"][3] = "0|0,i0"
			var board: Variant = _new_board(board_scene, row)
			var initial_key: String = JuiceRules.state_key(board.state())
			var rejected: Array[int] = []
			var attempts: Array[Dictionary] = []
			board.move_rejected.connect( func(reason: int) -> void : rejected.append(reason))
			board.move_attempted.connect( func(info: Dictionary) -> void : attempts.append(info))
			var strict: bool = mode == JuiceLevel.ICE_BLOCK_CONNECTION
			_check(board.capture_connection(1, 0, 3).is_empty() == strict, 
				"%s/%s 连接反馈遵循模式" % [mode, variant])
			_drop(board, 1, 0, 3)
			if strict:
				_check(board.steps() == 0 and rejected == ([JuiceRules.Reject.FROZEN] as Array[int]), 
					"严格模式松手拒绝冰端点且不记成功步")
				_check(JuiceRules.state_key(board.state()) == initial_key and attempts.size() == 1
					and int(attempts[0]["reject_reason"]) == JuiceRules.Reject.FROZEN, 
					"严格拒绝不改盘面并沿既有尝试信号交付原因")
			else:
				_check(board.steps() == 1 and rejected.is_empty() and int(board.state()["done"]) == 0, 
					"当前模式同色冰连接成功但不消除")
				_check(board.undo(), "当前模式撤销恢复初始冰端点")
			var empty_target: Dictionary = JuiceRules.clone_state(board.state())
			(empty_target["cols"][2] as Array[int]).clear()
			_check(JuiceRules.move_info(empty_target, 1, 0, 2) == 1, "%s 可移到空列" % mode)
			_check(board.try_move(0, 0, 4) and int(board.state()["done"]) == 1, 
				"%s 收阳光当帧完成逻辑融冰" % mode)
			var melted: Dictionary = board.snapshot()
			_check(board.try_move(1, 0, 3), "%s 演出中融冰后端点可继续连接" % mode)
			_check(board.restore(board.level(), JSON.parse_string(JSON.stringify(melted))), 
				"%s 融冰演出中快照可续局重建" % mode)
			_check(board.state()["ice_mode"] == mode and board.undo()
				and JuiceRules.state_key(board.state()) == initial_key, 
				"%s 续局撤销回冻且模式不变" % mode)
			board.setup(board.level())
			_check(board.state()["ice_mode"] == mode, "%s 重开保留模式" % mode)
			_free_board(board)
			await process_frame


func _test_continuation_and_cancel(board_scene: PackedScene) -> void :
	var row: Dictionary = {
		"id": 1004, "capacity": 3, "targetCups": 3, "sunlight": {"typeId": 2}, 
		"initial": ["-|2", "-|0", "-|1", "0|i0,0", "2|2,2", "1|1,1"], "incoming": [], 
	}
	var board: Variant = _new_board(board_scene, row)
	board.cup_collected.connect( func(fruit_type: int, nth: int, _color: Color, from_rect: Rect2) -> void :
		if board.level().is_sunlight_type(fruit_type):
			board.start_sunlight_collection(nth, from_rect, Rect2(50, 50, 100, 100)))
	_check(board.try_move(0, 0, 4), "非终局先收阳光")
	_check(board._can_play() and board.try_move(1, 0, 3), "阳光动画中可继续连接融化列")
	_check(int(board.state()["done"]) == 2, "动画中后续移动即时完成逻辑收集")
	var beats: Array = board.get("_beats")
	_check( not (beats[1].get("melt_batch", {}) as Dictionary).is_empty(), 
		"后续移动收集原冰花时保留融冰视觉依赖")
	var generation: int = int(board.get("_melt_generation"))
	_check(board.undo(), "动画中撤销后续移动")
	_check(int(board.get("_melt_generation")) > generation
		and (board.get("_sunlight_batches") as Array).is_empty(), "撤销取消旧融冰代次")
	_check(board.undo() and _fruit_at(board, 3, 0).is_frozen(), "再次撤销阳光回冻")
	_check(board.try_move(0, 0, 4), "取消后再次播放阳光")
	board.set("_t", 1.2)
	board._advance_beats()
	board.sunlight_collector_landed.connect( func(_nth: int) -> void : board.setup(board.level()))
	board._tick_sunlight_collection(0.48)
	var effect: SunlightFx = board.get("_sunlight_fx")
	_check( not effect.is_running() and (board.get("_sunlight_batches") as Array).is_empty(), 
		"落地信号同步重开后旧回调不能起播日光")
	board._on_sunlight_finished()
	_check(_fruit_at(board, 3, 0).is_frozen(), "取消后的结束回调不改写新盘面")
	_free_board(board)
	await process_frame


func _test_quota_order() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_quota_bar.tscn")
	var quota: JuiceQuotaBar = scene.instantiate()
	root.add_child(quota)
	var collector: Texture2D = load("res://assets/sprites/juice_sort/sunlight_collector_body.png")
	var icon: Texture2D = load("res://assets/sprites/juice_sort/sunlight_sunlight.png")
	quota.set_sunlight_textures(collector, icon)
	quota.setup(3)
	quota.push_sunlight_round_cup(1, collector, JuiceTheme.SUN_COLOR)
	_check((quota.get("_texs") as Array).is_empty(), "阳光落地早于前盆时不改变有序计数")
	quota.push_sunlight_round_cup(2, icon, Color.WHITE)
	quota.push_sunlight_round_cup(0, icon, Color.WHITE)
	var textures: Array = quota.get("_texs")
	_check(textures.size() == 3 and textures[1] == collector, "乱序落地按逻辑盆序入栏")
	quota.setup(3)
	quota.push_sunlight_round_cup(1, collector, JuiceTheme.SUN_COLOR)
	quota.set_cups([] as Array[Texture2D], PackedColorArray())
	_check((quota.get("_arrived_sunlight_round_cups") as Dictionary).is_empty(), "续局重建取消旧落地缓存")
	quota.queue_free()


func _test_ambient_reset() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_sunlight_ambient.tscn")
	var ambient: JuiceSunlightAmbient = scene.instantiate()
	var sun: GPUParticles2D = ambient.get_node("SunParticles")
	var cold: GPUParticles2D = ambient.get_node("ColdParticles")
	_check( not sun.visible and not sun.emitting and not cold.visible and not cold.emitting, 
		"GPU粒子入树前默认隐藏停发")
	_check((sun.process_material as ParticleProcessMaterial).particle_flag_disable_z
		and (cold.process_material as ParticleProcessMaterial).particle_flag_disable_z, 
		"两种粒子关闭Z轴模拟")
	root.add_child(ambient)
	ambient.set_sunlight(true)
	ambient.set_frozen(true)
	ambient.stop()
	await process_frame
	_check( not sun.visible and not sun.emitting and not cold.visible and not cold.emitting, 
		"取消旧准备后粒子保持隐藏停发")
	ambient.set_sunlight(true)
	ambient.set_frozen(true)
	_check(bool(ambient.get("_sun_emitting")) and bool(ambient.get("_cold_emitting")), "回池复用可重新请求起播")
	ambient.stop()
	ambient.queue_free()


func _drop(board: Variant, src: int, segment_start: int, target: int) -> void :
	var lay: Variant = board.get("_lay")
	board.set("_drag", {
		"col": src, "j": segment_start, "nodes": [], 
		"pos": Vector2(board._col_x(target), lay.plank_top + 10.0), 
		"grab": Vector2.ZERO, 
	})
	board._drop_at()


func _last_move_has_sun(board: Variant) -> bool:
	var history: Array = board.get("_history")
	if history.is_empty():
		return false
	var rec: Dictionary = history[history.size() - 1]["rec"]
	for deposit: Dictionary in rec.get("deposits", []) as Array:
		if bool(deposit.get("sun", false)):
			return true
	return false


func _frozen_visual_in_beats(board: Variant) -> bool:
	for beat: Dictionary in board.get("_beats") as Array:
		for fruit: JuiceFruit in beat.get("nodes", []) as Array:
			if is_instance_valid(fruit) and fruit.is_frozen() and fruit.fruit_type == 0\
			and bool(fruit.get("_ice_body").visible):
				return true
	return false


func _fruit_at(board: Variant, column_index: int, fruit_index: int) -> JuiceFruit:
	var fruits: Array = (board.get("_fruit_nodes") as Dictionary).get(column_index, []) as Array
	if fruit_index < 0 or fruit_index >= fruits.size():
		return null
	return fruits[fruit_index] as JuiceFruit


func _same_int_array(actual: Variant, expected: Array[int]) -> bool:
	if not (actual is Array):
		return false
	var actual_array: Array = actual
	if actual_array.size() != expected.size():
		return false
	for index in actual_array.size():
		if int(actual_array[index]) != expected[index]:
			return false
	return true


func _check(condition: bool, label: String) -> void :
	_checks += 1
	if not condition:
		_fail(label)


func _fail(label: String) -> void :
	_failures.append(label)
	print("  ✗ %s" % label)


func _finish() -> void :
	print("—— %d 项断言 ——" % _checks)
	if _failures.is_empty():
		print("PASS")
		quit(0)
	else:
		print("FAIL")
		quit(1)
