extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void :
	call_deferred("_run")

func _run() -> void :
	var board: Variant = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	root.add_child(board)
	board.size = Vector2(1080, 2340)
	await _test_particle_preparation(board)
	await _test_skin_particle_cache(board)
	await _test_particle_reuse(board)
	board.setup(JuiceLevel.from_dict({"id": 98110, "capacity": 4, "targetCups": 3, 
		"initial": ["0|0", "-|0", "1|1", "2|"], "incoming": []}))
	_check(board.capture_connection(0, 0, 3).is_empty(), "空绳不播放连接反馈")
	_check(board.capture_connection(0, 0, 2).is_empty(), "异色不播放连接反馈")
	var entry: Dictionary = board.capture_connection(0, 0, 1)
	_check( not entry.is_empty(), "同色捕获两朵接点花")
	_check(board.try_move(0, 0, 1), "同色连接成功")
	board.queue_connection_feedback(entry)
	await create_timer(0.35).timeout
	_check(board.get("_connection_pending").is_empty(), "归位后消费连接反馈")
	var effects: Array = board.get("_connection_effects").duplicate()
	_check(effects.size() == 3, "两朵花周围发射顺逆两组花瓣及局部星光")
	for effect: GPUParticles2D in effects:
		var material: ParticleProcessMaterial = effect.process_material as ParticleProcessMaterial
		if effect.texture == board.ROPE_STAR_TEX:
			_check(is_equal_approx(effect.lifetime, board.ROPE_STAR_LIFETIME)
				and is_zero_approx(material.initial_velocity_min), "局部星光复用收盆原地闪烁")
		else:
			_check(is_equal_approx(effect.lifetime, board.ROPE_PETAL_LIFETIME), "花瓣沿用收盆寿命")
			_check(is_equal_approx(material.initial_velocity_min, board.ROPE_PETAL_SPEED_MIN), 
				"花瓣沿用收盆飘散速度")
		_check(material.emission_box_extents.y * 2.0 < board.get("_lay").rope_bottom
			- board.get("_lay").rope_visible_top, "花瓣出生范围仅覆盖连接两朵，不炸整绳")
	var leading: JuiceFruit = entry["leading"]
	var bottom: JuiceFruit = entry["bottom"]
	var untouched: JuiceFruit = board.get("_fruit_nodes")[2][0]
	for flower: JuiceFruit in [leading, bottom]:
		flower.play_connection_pop(board.CONNECTION_PULSE_SCALE, 
			board.CONNECTION_PULSE_UP_DUR, board.CONNECTION_PULSE_DOWN_DUR)
		(flower.get("_connection_tween") as Tween).custom_step(board.CONNECTION_PULSE_UP_DUR)
		_check(is_equal_approx(flower.get("_connection_scale"), 1.3), "两朵连接花轻柔放大到130%")
		flower.set_hint_highlight(false)
		_check((flower.get_node("Body") as Sprite2D).scale.is_equal_approx(
			Vector2.ONE * float(flower.get("_body_scale")) * 1.3), "清提示不打断连接缩放")
		_check(flower.scale == Vector2.ONE, "连接缩放不争用花朵归位及收盆节点")
		(flower.get("_connection_tween") as Tween).custom_step(board.CONNECTION_PULSE_DOWN_DUR)
		_check(is_equal_approx(flower.get("_connection_scale"), 1.0), "连接后恢复正常大小")
	_check(is_equal_approx(untouched.get("_connection_scale"), 1.0), "非连接花朵不缩放")
	leading.play_connection_pop(board.CONNECTION_PULSE_SCALE, 
		board.CONNECTION_PULSE_UP_DUR, board.CONNECTION_PULSE_DOWN_DUR)
	leading.reset_for_pool()
	_check(is_equal_approx(leading.get("_connection_scale"), 1.0)
		and leading.get("_connection_tween") == null, "回池打断连接缩放并复位")
	board._clear_all_burst_state()
	_check(board.get("_connection_effects").is_empty(), "重建时清理连接效果")
	for effect: GPUParticles2D in effects:
		_check( not effect.visible and not effect.emitting and is_zero_approx(effect.self_modulate.a), 
			"重建立即复位未播放完的花瓣/星光，保留预绘实例供下一局复用")
	await process_frame
	await process_frame
	for effect: GPUParticles2D in effects:
		_check( not effect.visible and not effect.emitting, "取消后旧等待不恢复连接粒子")
	for jar: String in ["0", "1", "-"]:
		board.setup(JuiceLevel.from_dict({"id": 98111, "capacity": 4, "targetCups": 3, 
			"initial": ["-|0", jar + "|0,0,0", "1|1", "2|2"], "incoming": []}))
		var full_entry: Dictionary = board.capture_connection(0, 0, 1)
		_check( not full_entry.is_empty(), "满列移动前仍能捕获同色接点")
		_check(board.try_move(0, 0, 1), "同色连接组成满列")
		board.queue_connection_feedback(full_entry)
		var collecting: bool = jar == "0"
		_check(board.get("_connection_pending").is_empty() == collecting, 
			"仅满足目标盆收集条件时跳过双花动画，白盆和非目标色满列保留")
		_check(board.get("_beats").is_empty() != collecting, "满列收集动画正常入队")
		await create_timer(0.35).timeout
		_check(board.get("_connection_effects").is_empty() == collecting, 
			"满足收集时不产生双花花瓣，否则继续播放连接反馈")
		if collecting:
			_check((full_entry["leading"] as JuiceFruit).get("_connection_tween") == null
				and (full_entry["bottom"] as JuiceFruit).get("_connection_tween") == null, 
				"满足收集时不额外启动双花缩放")
	board.setup(JuiceLevel.from_dict({"id": 98112, "capacity": 4, "targetCups": 3, 
		"initial": ["-|0", "0|0,0", "2|0", "1|1"], "incoming": []}))
	var pending_entry: Dictionary = board.capture_connection(0, 0, 1)
	_check(board.try_move(0, 0, 1), "先形成普通连接")
	board.queue_connection_feedback(pending_entry)
	_check(board.try_move(2, 0, 1), "连接反馈等待中下一步凑满并收集")
	board._advance_connection_feedback()
	_check(board.get("_connection_pending").is_empty()
		and board.get("_connection_effects").is_empty(), 
		"收集接管后取消未播放的双花反馈 (pending=%s effects=%s target_size=%s beats=%s)" % [
			board.get("_connection_pending").size(), board.get("_connection_effects").size(), 
			board.get("_fruit_nodes").get(1, []).size(), board.get("_beats").size()])

	for key: String in ["_closed_task_id", "_death_task_id", "_challenge_task_id", "_lucky_task_id", "_safe_task_id"]:
		var task_id: int = board.get(key)
		if task_id >= 0:
			WorkerThreadPool.wait_for_task_completion(task_id)
			board.set(key, -1)
	board.free()
	if _failures.is_empty():
		print("PASS: connection flower burst")
	else:
		for failure in _failures:
			push_error(failure)
	quit(0 if _failures.is_empty() else 1)


func _test_particle_preparation(board: Variant) -> void :
	var petal: GPUParticles2D = board._acquire_rope_petal_emitter()
	var star: GPUParticles2D = board._acquire_rope_star_emitter()
	for emitter: GPUParticles2D in [petal, star]:
		_check( not emitter.visible and not emitter.emitting, "动态发射器准备后默认隐藏且停发")
		_check((emitter.process_material as ParticleProcessMaterial).particle_flag_disable_z, 
			"实际连接发射器材质关闭Z模拟")
		_check(emitter.visibility_rect.has_area(), "连接发射器显式配置剔除范围")
	board._release_rope_petal_emitter(petal)
	board._release_rope_star_emitter(star)
	var lifecycles: Dictionary = board.get("_rope_particle_lifecycles")
	for emitter: GPUParticles2D in [petal, star]:
		_check(emitter.get_meta(&"skin_lifecycle") == lifecycles[emitter], 
			"换肤复位与连接预热共用同一生命周期，取消不留第二份等待")
	if DisplayServer.get_name() == "headless":
		_check( not await board.warm_connection_particles_render(), "Headless不冒充实际连接预绘完成")
		_check( not board.is_connection_particles_warmed(), "Headless不写进程准备成功标记")
		_check( not await (lifecycles[petal] as GpuParticleLifecycle).pre_render( func() -> bool: return true, 0.12), 
			"公共预绘在Headless返回失败")
		var preparer: Variant = load("res://scripts/main/pages/game/game_effects_preparer.gd").new()
		await preparer.run(null)
		_check(preparer.should_run(null), "Headless准备器保留重试资格")
		return
	var viewport: = SubViewport.new()
	viewport.size = Vector2i(1080, 2340)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	board.reparent(viewport, false)
	var state: Dictionary = {"active": true}
	_cancel_warm_after_frame(state)
	_check( not await board.warm_connection_particles_render( func() -> bool: return state.active), 
		"离屏真实更新期间取消返回失败")
	_check( not board.is_connection_particles_warmed(), "取消不写进程成功标记")
	for emitter: GPUParticles2D in board.get("_rope_particle_lifecycles"):
		_check( not emitter.visible and not emitter.emitting, "取消预绘立即隐藏停发")
	_check( await board.warm_connection_particles_render(), "取消后重新预绘可完成")
	_check(board.get("_rope_petal_pool").size() == 2 and board.get("_rope_star_pool").size() == 1, 
		"预绘保留两组花瓣和同一星光实例")
	var count: int = board.get("_rope_particle_lifecycles").size()
	_check( await board.warm_connection_particles_render(), "已预绘重复准备直接完成")
	_check(board.get("_rope_particle_lifecycles").size() == count, "重复准备不创建额外发射器")
	board.reparent(root, false)
	viewport.queue_free()


func _cancel_warm_after_frame(state: Dictionary) -> void :
	await process_frame
	state.active = false


func _test_skin_particle_cache(board: Variant) -> void :
	var petal: GPUParticles2D = board._acquire_rope_petal_emitter()
	var star: GPUParticles2D = board._acquire_rope_star_emitter()
	board._release_rope_petal_emitter(petal)
	board._release_rope_star_emitter(star)

	board.set("_connection_particles_warmed", true)
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	board.apply_skin(JuiceSkinResolver.new(base, base), false)
	_check(board.get("_rope_petal_pool").has(petal) and board.get("_rope_star_pool").has(star)
		and board.is_connection_particles_warmed(), "启动盘面首次绑定默认皮肤保留预绘池及完成标记")
	board.apply_skin(JuiceSkinResolver.new(base, base), false)
	_check(board.get("_rope_particle_lifecycles").has(petal)
		and board.get("_rope_particle_lifecycles").has(star), "相同素材再次绑定仍保留生命周期实例")
	var changed: JuiceSkinDefinition = base.duplicate() as JuiceSkinDefinition
	changed.effects = base.effects.duplicate() as JuiceSkinEffectAssets
	changed.effects.rope_star = GradientTexture2D.new()
	board.apply_skin(JuiceSkinResolver.new(base, changed), false)
	_check(board.get("_rope_petal_pool").is_empty() and board.get("_rope_star_pool").is_empty()
		and board.get("_rope_particle_lifecycles").is_empty() and not board.is_connection_particles_warmed(), 
		"实际换素材清空旧连接池与完成标记，下一次准备必须重新预绘")
	_check( not petal.visible and not petal.emitting and not star.visible and not star.emitting, 
		"旧皮肤发射器销毁前已隐藏停发")
	var changed_star: GPUParticles2D = board._spawn_rope_stars(200.0, 1.0, 1.0, 0.0, Vector2(100.0, 240.0))
	board.get("_connection_effects").append(changed_star)
	board._clear_all_burst_state()
	_check(board.get("_rope_star_pool").has(changed_star) and board.get("_rope_petal_pool").is_empty()
		and not changed_star.has_meta(&"rope_star_tween"), "换肤星光取消按发射入口回池，不按默认贴图误判成花瓣")
	board.apply_skin(JuiceSkinResolver.new(base, base), false)
	await process_frame


func _test_particle_reuse(board: Variant) -> void :
	var petal: GPUParticles2D = board._fire_rope_petals(200.0, 100.0, 240.0, 4, 
		board.ROPE_PETAL_SPIN_MIN, board.ROPE_PETAL_SPIN_MAX, Color.RED)
	_check(petal.visible and is_zero_approx(petal.self_modulate.a), "复用花瓣先透明更新")
	board._release_rope_petal_emitter(petal)
	for i: int in 4:
		await process_frame
	_check( not petal.visible and not petal.emitting, "起播中取消不会被旧等待显现")
	var coin: GPUParticles2D = board._fire_rope_petals(200.0, 100.0, 240.0, 4, 
		- board.ROPE_PETAL_SPIN_MAX, - board.ROPE_PETAL_SPIN_MIN, Color.WHITE, true)
	_check(coin == petal and coin.texture == board.bonus_coin_texture and coin.material == null, 
		"同一池实例切换金币完整贴图及材质")
	_check(is_zero_approx(coin.self_modulate.a), "金币样式首绘前仍保持透明")
	board._release_rope_petal_emitter(coin)
	var replay: GPUParticles2D = board._fire_rope_petals(200.0, 100.0, 240.0, 4, 
		board.ROPE_PETAL_SPIN_MIN, board.ROPE_PETAL_SPIN_MAX, Color.BLUE)
	_check(replay == petal and replay.texture == board.rope_petal_texture and replay.material is ShaderMaterial, 
		"金币回花瓣恢复图集材质并复用实例")
	for i: int in 4:
		await process_frame
	_check(replay.visible and is_equal_approx(replay.self_modulate.a, 1.0), "新一轮正常显现")
	board._release_rope_petal_emitter(replay)
	var star: GPUParticles2D = board._spawn_rope_stars(200.0, 1.0, 1.0, 0.0, Vector2(100.0, 240.0))
	board._release_rope_star_emitter(star)
	for i: int in 4:
		await process_frame
	_check( not star.visible and not star.emitting and not star.has_meta(&"rope_star_tween"), 
		"星光取消同时杀停发回池Tween及旧显现等待")
	var star_replay: GPUParticles2D = board._spawn_rope_stars(200.0, 1.0, 1.0, 0.0, Vector2(100.0, 240.0))
	_check(star_replay == star, "星光再次播放复用同一实例")
	board._release_rope_star_emitter(star_replay)


func _check(ok: bool, label: String) -> void :
	if not ok:
		_failures.append(label)
