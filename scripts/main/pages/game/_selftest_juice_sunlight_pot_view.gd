extends SceneTree

class TestPage extends JuiceGamePage:
	var force_bonus: bool = false
	var force_special: bool = false

	func _decide_bonus_enabled() -> bool:
		_bonus_v2 = false
		return force_bonus and not _level_model.raw.has("sunlightPotSource")

	func is_special_challenge() -> bool:
		return force_special

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	_test_sunlight_palette_mapping()
	await _test_sunlight_palette_view()
	await _test_visuals()
	await _test_two_row_shelf_occlusion()
	_test_restart_model_unification()
	_test_page()
	await process_frame
	print("SUNLIGHT_POT_VIEW %d checks" % _checks)
	print("PASS" if _failures.is_empty() else "FAIL")
	quit(0 if _failures.is_empty() else 1)


func _test_sunlight_palette_mapping() -> void :
	for types: int in range(1, JuiceTheme.SLOT_ORDER.size() + 1):
		var source: PackedInt32Array = JuiceTheme.slots_for(45, types)
		for sun_type: int in types:
			var result: PackedInt32Array = JuiceTheme.sunlight_pot_slots(source, sun_type)
			var seen: Dictionary = {}
			var valid: bool = result.size() == source.size()
			for type_id: int in result.size():
				valid = valid and not seen.has(result[type_id])
				seen[result[type_id]] = true
				if type_id != sun_type:
					valid = valid and result[type_id] != JuiceTheme.YELLOW_SLOT
			_check(valid, "%d种花太阳类型%d：普通花无黄色且不撞色" % [types, sun_type])
			_check(JuiceTheme.sunlight_pot_slots(result, sun_type) == result, "换色重复应用不反转")
		_check(source == JuiceTheme.slots_for(45, types), "换色不修改原始色板")
	var custom: PackedInt32Array = PackedInt32Array([4, 2, 1, 6, 0])
	_check(JuiceTheme.sunlight_pot_slots(custom, 4) == PackedInt32Array([0, 2, 1, 6, 4]), "保存色板使用太阳原槽换黄花")
	_check(JuiceTheme.sunlight_pot_slots(custom, 0) == custom, "太阳原本黄色无需交换")
	_check(JuiceTheme.sunlight_pot_slots(custom, -1) == custom, "没有太阳不换色")
	_check(JuiceTheme.sunlight_pot_slots(custom, 10) == custom, "无效太阳类型不换色")
	_check(JuiceTheme.sunlight_pot_slots(PackedInt32Array([0, 6, 1]), 1) == PackedInt32Array([0, 6, 1]), "没有黄花不换色")
	_check(JuiceTheme.sunlight_pot_slots(PackedInt32Array([0, 4, 0]), 2) == PackedInt32Array([0, 6, 4]), "太阳原槽被占用时选未用非黄色")


func _test_sunlight_palette_view() -> void :
	var raw: Dictionary = {"id": 45, "capacity": 3, "targetCups": 4, 
		"sunlight": {"typeId": 3}, "frozenPots": [2, 3, 4], 
		"initial": ["-|3", "-|0", "0|0,0", "1|1,1,1", "2|2,2,2", "3|3,3"], "incoming": []}
	var level: JuiceLevel = JuiceLevel.from_dict(raw)
	_check(level.validate().is_empty(), "换色验收题合法")
	var source: PackedInt32Array = JuiceTheme.slots_for(level.id, level.types)
	var expected: PackedInt32Array = JuiceTheme.sunlight_pot_slots(source, level.sunlight_type)
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	var board: Variant = scene.instantiate()
	root.add_child(board)
	board.setup(level)
	_check(board.get("_slots") == expected, "冻盆局摆盘应用整套换色")
	_check(level.to_dict() == JuiceLevel.from_dict(raw).to_dict(), "换色不改变题面")
	_check(JuiceRules.state_key(board.state()) == JuiceRules.state_key(JuiceRules.make_state(level)), "换色不改变开局规则")
	var slot: int = expected[2]
	_check(board._texture_for_fruit(2) == board.bead_fruit_textures[slot], "普通黄花换成太阳原来的花")
	_check(board._texture_for_blender(2) == board.bead_blender_textures[slot], "黄盆与花一起换色")
	_check(board.full_blender_texture_for_type(2) == board.bead_blender_full_textures[slot], "满盆与飞盆一起换色")
	_check(board._rope_top_tex(2) == board.rope_top_textures[slot]
		and board._rope_mid_tex(2) == board.rope_mid_textures[slot]
		and board._rope_bottom_tex(2) == board.rope_bottom_textures[slot], "绳三段一起换色")
	_check(board.slot_for_type(2) == slot and board.color_for_type(2) == JuiceTheme.color_of_slot(slot, board.get("_skin")), 
		"飞盆槽位与主题色一致")
	_check(board._texture_for_fruit(3) == board.sunlight_fruit_texture
		and board._texture_for_blender(3) == board.sunlight_blender_texture
		and board.color_for_type(3) == JuiceTheme.SUN_COLOR, "太阳保持独立黄色素材")
	var default_skin: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	board.apply_skin(JuiceSkinResolver.new(default_skin, default_skin))
	_check(board._texture_for_fruit(2) == board.bead_fruit_textures[slot]
		and board._texture_for_blender(2) == board.bead_blender_textures[slot], "默认皮肤保持冻盆局颜色映射")
	_check(board.try_move(0, 0, 5), "换色后太阳仍能按原规则收满")
	_check(board.get("_slots") == expected and not (board.state()["frozen_pots"] as Array).has(true), "碎冰后不恢复普通黄色")
	var cups: Array[Texture2D] = board.cup_textures()
	var colors: PackedColorArray = board.cup_colors()
	for index: int in (board.state()["cups"] as Array).size():
		var type_id: int = board.state()["cups"][index]
		_check(cups[index] == board.full_blender_texture_for_type(type_id)
			and colors[index] == board.color_for_type(type_id), "订单按统一色板显示")
	var melted: Dictionary = board.snapshot()
	_check(board.restore(level, JSON.parse_string(JSON.stringify(melted)), source), "碎冰后续局重建")
	_check(board.get("_slots") == expected, "融冰后续局保持换色")
	board.setup(level, {}, source)
	_check(board.get("_slots") == expected, "重开保持换色")
	_check(board.try_move(0, 0, 5) and board.undo(), "换色局撤销太阳收集")
	_check(board.get("_slots") == expected and JuiceRules.is_frozen_pot(board.state(), 4), "撤销回冻但不换回黄色")
	var frozen: Dictionary = board.snapshot()
	_check(board.restore(level, JSON.parse_string(JSON.stringify(frozen)), expected)
		and board.get("_slots") == expected, "续局已有换色表不再次交换")
	var ordinary: Dictionary = raw.duplicate(true)
	ordinary.erase("sunlight")
	ordinary.erase("frozenPots")
	board.setup(JuiceLevel.from_dict(ordinary))
	_check(board.get("_slots") == source, "普通关保持原黄色")
	var legacy: Dictionary = raw.duplicate(true)
	legacy.erase("frozenPots")
	legacy["initial"][2] = "0|0,i0"
	board.setup(JuiceLevel.from_dict(legacy))
	_check(board.get("_slots") == source, "旧冰花局保持原配色")
	board.set_bonus_candidate(true, true)
	board.setup(JuiceLevel.from_dict(ordinary))
	_check(board.get("_slots") == source, "金猪局不应用阳光换色")
	board.cancel_sunlight_animation()
	board._cancel_closed_check()
	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()
	await process_frame


func _test_visuals() -> void :
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 41, "capacity": 3, "targetCups": 3, 
		"sunlight": {"typeId": 2}, "frozenPots": [3, 5], 
		"initial": ["-|2", "-|0", "-|1", "0|0,0", "2|2,2", "1|1,1"], "incoming": []})
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	var board: Variant = scene.instantiate()
	root.add_child(board)
	board.setup(level)
	var pot: JuiceBlender = board.get("_blender_nodes")[3]
	var persisted: Dictionary = {}
	board.moved.connect( func(_steps: int) -> void :
		persisted["state"] = board.snapshot()["state"])
	_check(pot.is_frozen() and pot.get_node("IceBody").visible, "冰层只覆盖花盆")
	for layer_name: String in ["IceBack", "IceBody", "IceFrost"]:
		var ice: Sprite2D = pot.get_node(layer_name)
		_check(is_equal_approx(ice.modulate.a, 1.0), "盆冰使用原始不透明度: %s" % layer_name)
		_check(ice.get_rect().size.x * ice.scale.x <= float(board.get("_lay").col_w) * 0.99 + 0.001, 
			"冰层宽度不超过列距99%%: %s" % layer_name)
	var body: Sprite2D = pot.get_node("IceBody")
	_check(body.top_level and board.clip_contents, "冰层独立于盘面裁剪，盘面其他内容仍裁剪")
	var ice_material: ShaderMaterial = body.material as ShaderMaterial
	_check(bool(ice_material.get_shader_parameter("shelf_occlusion_enabled")), "对照组冰层由木架遮挡")
	_check(ice_material.get_shader_parameter("shelf_texture") == board.get("_plank").texture, 
		"冰层遮挡使用当前木架纹理")
	_check(is_equal_approx(float(ice_material.get_shader_parameter("shelf_alpha")), 1.0), "对照组木架保持不透明")
	var previous_ice_position: Vector2 = body.global_position
	pot.position.x += 7.0
	pot.force_update_transform()
	_check(is_equal_approx(body.global_position.x, previous_ice_position.x + 7.0), "独立冰层跟随花盆移动")
	pot.position.x -= 7.0
	pot.force_update_transform()
	_check(body.texture.resource_path == "res://assets/sprites/juice_sort/sunlight_pot_ice.png", 
		"盆冰绑定用户提供的新贴图")
	_check(is_equal_approx((pot.get_node("Body") as Sprite2D).self_modulate.a, 1.0), "冻结时保留冰层后面的原盆身")
	_check( not pot.get_node("IceFrost").visible, "新冰块不叠加旧冰霜")
	var next_body: Sprite2D = board.get("_blender_nodes")[4].get_node("IceBody")
	var ice_rect: Rect2 = body.get_global_transform() * body.get_rect()
	var next_ice_rect: Rect2 = next_body.get_global_transform() * next_body.get_rect()
	_check( not ice_rect.intersects(next_ice_rect), "相邻冰层不交叉")
	var pot_body: Sprite2D = pot.get_node("Body")
	var pot_rect: Rect2 = pot_body.get_global_transform() * Rect2(16.0, 25.0, 148.0, 140.0)
	pot_rect.position -= pot_body.get_global_transform().basis_xform(pot_body.texture.get_size() * 0.5)
	_check(ice_rect.intersection(pot_rect).get_area() >= pot_rect.get_area() * 0.95, 
		"轻微缩小后冰层范围仍覆盖至少95%%盆身面积")
	_check(is_equal_approx(body.scale.y, body.scale.x), "设计稿冰块保持原图比例，不拉成长柱")
	_check(body.global_position.is_equal_approx(pot.global_position), "冰块中心对齐盆身")
	_check(is_equal_approx(ice_rect.size.x, minf((pot.get("_rect") as Rect2).size.x * 1.16, 
		float(board.get("_lay").col_w) * 0.99) * 0.97), "冰层在限幅后等比缩小3%%")
	for fruit: JuiceFruit in board.get("_fruit_nodes")[3]:
		_check( not fruit.is_frozen(), "花朵没有被冻结")
	board.cup_collected.connect( func(type_id: int, number: int, _color: Color, rectangle: Rect2) -> void :
		if level.is_sunlight_type(type_id):
			board.start_sunlight_collection(number, rectangle, Rect2(50, 50, 100, 100)))
	_check(board.try_move(1, 0, 3) and board.state()["done"] == 0, "冻盆能接满但不收集")
	_check(board.try_move(0, 0, 4) and board.state()["done"] == 2, "阳光当帧解冻级联")
	_check(int(persisted["state"]["done"]) == 2 and not (persisted["state"]["frozen_pots"] as Array).has(true), 
		"moved同步快照已是解冻级联后的最终逻辑状态")
	_check(pot.is_frozen(), "逻辑解冻后保留旧视觉冰层")
	board.set("_t", 1.2)
	board._advance_beats()
	var effect: JuiceIceShatterFx = board.get("_ice_shatter_fx")
	_check(effect.is_running(), "太阳收盆时直接起播碎冰")
	_check( not (board.get("_sunlight_fx") as SunlightFx).is_running(), "冻盆不播放日光与融化")
	_check( not pot.is_frozen() and not pot.get_node("IceBody").visible, "碎开时完整冰层立即消失")
	_check( not (board.get("_sunlight_flight") as Dictionary).is_empty(), "碎冰与太阳飞入订单并行")
	_check((effect.get("_shards") as Array).size() == 24, "两只冻盆各生成12块碎片")
	var shard: Dictionary = (effect.get("_shards") as Array)[0]
	_check( not shard.has("surface"), "碎片只持有贴图和变换快照，不持有原盆")
	for uv: Vector2 in shard["uvs"]:
		_check(uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0, "碎片UV位于原贴图内")
	_check(board._can_play(), "碎冰不锁盘面输入")
	_check(board.try_move(2, 0, 1), "碎冰期间可以继续下一步连接")
	effect.set_clock(0.2)
	_check(effect.is_running(), "碎片按短时钟飞散")
	_check(is_equal_approx((pot.get_node("Body") as Sprite2D).self_modulate.a, 1.0), "碎冰期间原盆身持续保留")
	_check(board.undo(), "碎冰期间允许撤销下一步")
	_check( not effect.is_running() and (effect.get("_shards") as Array).is_empty(), "撤销清空旧碎片")
	_check(board.undo() and JuiceRules.is_frozen_pot(board.state(), 3), "演出期间撤销回冻")
	_check(board.get("_blender_nodes")[3].is_frozen(), "撤销重建冻盆")
	var blob: Dictionary = board.snapshot()
	_check(board.restore(level, JSON.parse_string(JSON.stringify(blob))), "冻盆续局重建")
	_check((board.get("_sunlight_batches") as Array).is_empty(), "续局取消旧视觉队列")
	board.setup(level)
	_check(board.get("_blender_nodes")[3].is_frozen(), "重开恢复盆冰层")
	var new_pot: JuiceBlender = board.get("_blender_nodes")[3]
	effect.play([new_pot])
	_check(effect.is_running(), "取消后碎冰能重新起播")
	effect.set_clock(JuiceIceShatterFx.DURATION)
	_check( not effect.is_running() and (effect.get("_shards") as Array).is_empty(), "0.55秒清空碎片尾段")
	effect.play([new_pot])
	board.setup(level)
	_check( not effect.is_running() and not effect.visible, "重开取消碎冰并隐藏效果")
	effect.play([board.get("_blender_nodes")[3]])
	_check(board.restore(level, JSON.parse_string(JSON.stringify(blob))), "碎冰期间续局重建")
	_check( not effect.is_running() and (effect.get("_shards") as Array).is_empty(), "续局重建清空碎片")
	effect.play([board.get("_blender_nodes")[3]])
	board.cancel_sunlight_animation()
	_check( not effect.is_running() and (effect.get("_shards") as Array).is_empty(), "离页清空碎冰")
	for flight_first: bool in [true, false]:
		board.setup(level)
		_check(board.try_move(1, 0, 3) and board.try_move(0, 0, 4), "重建并起播真实碎冰批次")
		board.set("_t", float(board.get("_t")) + 1.2)
		board._advance_beats()
		_check(effect.is_running() and not (board.get("_sunlight_active_batch") as Dictionary).is_empty(), 
			"真实批次已进入碎冰与飞盆并发")
		if flight_first:
			board._tick_sunlight_collection(0.48)
			_check( not (board.get("_sunlight_active_batch") as Dictionary).is_empty(), "飞盆先到时等待碎片尾段")
			effect.set_clock(JuiceIceShatterFx.DURATION)
		else:
			effect.set_clock(JuiceIceShatterFx.DURATION)
			_check( not (board.get("_sunlight_active_batch") as Dictionary).is_empty(), "碎片先结束时等待飞盆")
			board._tick_sunlight_collection(0.48)
		_check((board.get("_sunlight_active_batch") as Dictionary).is_empty()
			and (board.get("_sunlight_batches") as Array).is_empty(), "飞盆与碎冰都完成后释放批次")
		_check( not (board.get("_sunlight_fx") as SunlightFx).is_running(), "碎冰结束不补播日光")
	board.cancel_sunlight_animation()
	board._cancel_closed_check()
	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()
	await process_frame


func _test_two_row_shelf_occlusion() -> void :
	var initial: Array[String] = []
	for index: int in 8:
		initial.append("%d|0,1,0,1" % (index % 2))
	initial.append("9|9,9,9,9")
	initial.append("9|9,9,9,9")
	var level: JuiceLevel = JuiceLevel.from_dict({"id": 43, "capacity": 4, "targetCups": 10, 
		"layoutRows": 2, "layoutColumns": 5, "sunlight": {"typeId": 9}, 
		"frozenPots": [0, 1, 2, 3, 4, 5, 6, 7], "initial": initial, "incoming": []})
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	var board: Variant = scene.instantiate()
	root.add_child(board)
	board.setup(level)
	var pot: JuiceBlender = board.get("_blender_nodes")[5]
	var material: ShaderMaterial = (pot.get_node("IceBody") as Sprite2D).material as ShaderMaterial
	_check(bool(material.get_shader_parameter("shelf_occlusion_enabled")), "双排对照组冰层启用木架遮挡")
	_check(is_equal_approx(float(material.get_shader_parameter("second_shelf_alpha")), 1.0), "第二排木架参与遮挡")
	var first_axis: Vector3 = material.get_shader_parameter("shelf_uv_y")
	var second_axis: Vector3 = material.get_shader_parameter("second_shelf_uv_y")
	_check( not first_axis.is_equal_approx(second_axis), "双排木架使用各自实际位置")
	board.get("_second_plank").hide()
	pot.set_ice_behind_shelves(true)
	_check(is_zero_approx(float(material.get_shader_parameter("second_shelf_alpha"))), "隐藏的第二排不残留遮挡")
	pot.reset_for_pool()
	_check( not bool(material.get_shader_parameter("shelf_occlusion_enabled")), "回池清除旧遮挡开关")
	board.cancel_sunlight_animation()
	board._cancel_closed_check()
	for field: String in ["_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.queue_free()
	await process_frame


func _test_page() -> void :
	var manager: Node = root.get_node("LevelManager")
	var ab: Node = root.get_node("ABManager")
	var user: Node = root.get_node("UserState")
	var previous: int = int(user.call("get_debug_ab_override", "sunlight_gameplay"))
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/game/juice_sunlight_pot_recipes_index.json"))
	var key: String = ""
	for candidate: String in index["addresses"]:
		if candidate.begins_with("41|"):
			var candidate_parts: PackedStringArray = candidate.split("|")
			var value: Dictionary = manager.call("read_sunlight_pot_recipe", 41, candidate_parts[1], candidate_parts[2])
			if value.get("status") == "ready":
				key = candidate
				break
	var pieces: PackedStringArray = key.split("|")
	var recipe: Dictionary = manager.call("read_sunlight_pot_recipe", 41, pieces[1], pieces[2])
	_check(SunlightGameplayConfig.parse_value("no") == 0 and SunlightGameplayConfig.parse_value("yes") == 1
		and SunlightGameplayConfig.parse_value("10_5") == 0, "SDK字符串严格映射no/yes")
	for scenario: String in ["control", "enabled", "bonus", "special", "missing"]:
		user.call("set_debug_ab_override", "sunlight_gameplay", 0 if scenario == "control" else 1)
		var page: TestPage = TestPage.new()
		var board_scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
		var board: Node = board_scene.instantiate()
		page.set("_board", board)
		var model: JuiceLevelModel = JuiceLevelModel.new()
		model.level_id = 41
		model.level_user_tags = pieces[2]
		model.level_unique_id = "missing" if scenario == "missing" else pieces[1]
		model.raw = recipe["source_raw"].duplicate(true)
		model.juice = JuiceLevel.from_dict(model.raw)
		page.set("_level_model", model)
		page.force_bonus = scenario == "bonus"
		page.force_special = scenario == "special"
		page.prepare_sunlight_pot_round({})
		_check(model.raw.has("sunlightPotSource") == (scenario == "enabled"), "开局范围与金猪优先: %s" % scenario)
		if scenario == "enabled":
			var frozen: Dictionary = model.raw.duplicate(true)
			user.call("set_debug_ab_override", "sunlight_gameplay", 0)
			page.prepare_sunlight_pot_round({"resume": true})
			_check(model.raw == frozen, "续局不读取新AB组或改题")
			page.prepare_sunlight_pot_round({})
			_check(model.raw == frozen, "未命中降级时重开复用冻结变体")
			_check(model.level_unique_id == recipe["converted_hash"], "实际变体身份冻结")
		board.free()
		page.free()
	if previous == -1:
		user.call("clear_debug_ab_override", "sunlight_gameplay")
	else:
		user.call("set_debug_ab_override", "sunlight_gameplay", previous)


func _test_restart_model_unification() -> void :
	var restart_source: String = FileAccess.get_file_as_string(
		"res://scripts/main/pages/game/juice_game_page.gd")
	_check( not restart_source.contains("_level_model if _level_model.raw.has(\"sunlightPotSource\")"), 
		"主动重开阳光局不跳过统一选题")
	_check(restart_source.contains("else resolve_restart_model("), 
		"主动重开调用统一选题入口")
	var load_source: String = FileAccess.get_file_as_string(
		"res://scripts/main/pages/game/flow/game_start/load_level_data_step.gd")
	_check(load_source.contains("ctx.page.resolve_restart_model("), "死局重进调用统一选题入口")
	var user: Node = root.get_node("UserState")
	var manager: Node = root.get_node("LevelManager")
	var model: JuiceLevelModel = JuiceLevelModel.new()
	model.level_id = 41
	model.raw = {"sunlightPotSource": {"source_uid": "test"}}
	var saved_repeat_level: int = int(user.get("_repeat_restart_level"))
	var saved_repeat_count: int = int(user.get("_repeat_restart_count"))
	user.set("_repeat_restart_level", 41)
	user.set("_repeat_restart_count", 0)
	var restart_result: Variant = manager.call("resolve_restart_model", 41, model)
	_check(int(user.call("get_repeat_restart_count", 41)) == 1, "阳光局主动重开计入连续重开")
	_check(restart_result == model, "第1次重开未达固定阈值时保留冻结变体")
	user.set("_repeat_restart_level", saved_repeat_level)
	user.set("_repeat_restart_count", saved_repeat_count)
	user.call("_save_data")


func _check(condition: bool, label: String) -> void :
	_checks += 1
	if not condition:
		_failures.append(label)
		printerr("FAIL: " + label)
