extends Node

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved: String = FileAccess.get_file_as_string("res://save.cfg")
	var entity: Dictionary = UserState.get_rank_current_entity().duplicate(true)
	var engine_speed: float = Engine.time_scale
	InjectDebugToolsStep.new()._register_debug_routes()
	var tool: PageScene = SceneManager.show_debug_panel("rank_first_collect_preview", {"auto_play": false})
	await _wait( func() -> bool: return tool._stage == "就绪")
	assert (get_tree().paused and tool.visible)
	tool._speed_choice.select(3)
	tool._on_speed_selected(3)
	for mode: int in range(3):
		tool._mode.select(mode)
		var completed: int = tool.completed_runs
		tool.replay()
		await _wait( func() -> bool: return tool._running)
		if mode == 0:
			await _check_first_feedback(tool)
		else:
			await _wait( func() -> bool: return not tool._running)
		assert (tool.completed_runs == completed + 1)
		assert (tool._arrivals == 6)
		assert (tool._page._list.find_my_item().get_collect_num_display() == (204 if mode == 1 else 205))
		assert (tool._page._list.find_my_item()._rank_pos == 1)
		print("FIRST_COLLECT_MODE_PASS:", mode, " events=", tool._events)
	for rank: int in [2, 3]:
		tool._mode.select(rank + 1)
		tool.replay()
		await _wait( func() -> bool: return tool._running)
		await _check_unchanged_podium_feedback(tool, rank)
	tool.replay()
	await _wait( func() -> bool: return tool._stage == "扫光与上升粒子")
	tool.stop()
	assert ( not tool._page._podium._sweeps[2].visible)
	assert (tool._page._list._animation_tweens.is_empty())
	tool._mode.select(0)
	await tool._reset_scene(tool.make_snapshot(1))
	var crown_pose: Transform2D = tool._page._crown.get_global_transform()
	tool._page._crown.play_collect_drop()
	assert (tool._page._crown.get_global_transform().is_equal_approx(crown_pose), "existing crown snapped at big-motion start")
	tool.stop()
	tool._on_speed_selected(2)
	tool.replay()
	await get_tree().create_timer(0.15).timeout
	tool._on_pause_pressed()
	await get_tree().process_frame
	var position: float = tool._page._list._collect_source_fx._player.current_animation_position
	await get_tree().create_timer(0.15).timeout
	assert (absf(tool._page._list._collect_source_fx._player.current_animation_position - position) < 0.02)
	tool._on_pause_pressed()
	await _wait( func() -> bool: return not tool._running)

	tool.replay()
	await _wait( func() -> bool: return tool._stage == "皇冠放大 → 下砸回弹")
	await get_tree().create_timer(0.08).timeout
	tool._on_pause_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	var crown_position: Vector2 = tool._page._crown.position
	await get_tree().create_timer(0.15).timeout
	assert (tool._page._crown.position.is_equal_approx(crown_position))
	tool.stop()
	await get_tree().create_timer(0.3).timeout
	assert (tool._page._crown._fly_tween == null and not tool._page._crown.visible)
	assert ( not tool._page._podium._sweeps[0].visible)
	assert (tool._page._list._animation_tweens.is_empty())
	tool.replay()
	await get_tree().create_timer(0.15).timeout
	tool.replay()
	await get_tree().create_timer(0.1).timeout
	tool.stop()
	var arrivals: int = tool._arrivals
	await get_tree().create_timer(0.25).timeout
	assert ( not tool._running and tool._arrivals == arrivals)
	assert ( not tool._page._list._collect_source_fx.visible)
	assert (tool._page._list._animation_tweens.is_empty())
	tool._on_speed_selected(3)
	tool._loop.button_pressed = true
	var completed: int = tool.completed_runs
	tool.replay()
	await _wait( func() -> bool: return tool.completed_runs >= completed + 2)
	tool.close()
	await get_tree().process_frame
	assert ( not tool.visible and not get_tree().paused)
	assert (tool._page._list._collect_source_fx.item_arrived.get_connections().size() == 1)
	get_tree().paused = true
	tool._loop.button_pressed = false
	SceneManager.show_debug_panel("rank_first_collect_preview", {"auto_play": false})
	await _wait( func() -> bool: return tool._stage == "就绪")
	tool.close()
	assert (get_tree().paused)
	assert (Engine.time_scale == engine_speed)
	assert (FileAccess.get_file_as_string("res://save.cfg") == saved)
	assert (UserState.get_rank_current_entity() == entity)
	print("RANK_FIRST_COLLECT_PREVIEW_PASS: five production chains, static top-three boards, second/third without crown animation, overlapping sweep/crown drop, six arrivals, flower/crown pause, crown/sweep cancel, restart, stop, loop, cached reopen, original pause and unchanged save")
	get_tree().paused = false
	get_tree().quit()

func _check_unchanged_podium_feedback(tool: PageScene, rank: int) -> void :
	var card: RankItemView = tool._page._list.find_my_item()
	var rest: Dictionary = {}
	for name: String in ["Bg", "Avatar", "AvatarFrame", "Info", "RankIcon", "CollectBg", "GiftButton", "Crown"]:
		var node: Control = card.get_node(name)
		rest[name] = [node.position, node.scale, node.rotation, node.pivot_offset]
	await _wait( func() -> bool: return tool._stage == "扫光与上升粒子")
	var sweep: RankPodiumSweepFx = tool._page._podium._sweeps[rank - 1]
	assert (sweep.visible)
	while tool._running or sweep.visible:
		assert (card.scale == Vector2.ONE and card.pivot_offset == Vector2.ZERO)
		assert ( not tool._page._crown.visible and tool._page._crown._fly_tween == null)
		for name: String in rest:
			var node: Control = card.get_node(name)
			assert ([node.position, node.scale, node.rotation, node.pivot_offset] == rest[name], name + " moved during unchanged podium feedback")
		for other: int in range(3):
			if other != rank - 1:
				assert ( not tool._page._podium._sweeps[other].visible)
		await get_tree().process_frame
	assert (tool._arrivals == 6 and card._rank_pos == rank)
	assert (card.get_collect_num_display() == 206 - rank)
	for event: String in tool._events:
		assert ( not event.contains("皇冠"))
	print("UNCHANGED_PODIUM_FEEDBACK_PASS: rank=", rank, " still board, correct sweep, six arrivals and no crown animation")

func _check_first_feedback(tool: PageScene) -> void :
	await _wait( func() -> bool: return tool._stage == "扫光与上升粒子")
	var card: RankItemView = tool._page._list.find_my_item()
	var rest: Dictionary = {}
	for name: String in ["Bg", "Avatar", "AvatarFrame", "Info", "RankIcon", "CollectBg", "GiftButton"]:
		var node: Control = card.get_node(name)
		rest[name] = [node.position, node.scale, node.rotation, node.pivot_offset]
	var sweep_at: float = tool._elapsed
	var drop_at: float = -1.0
	var peak_scale: float = 0.0
	while tool._running:
		var confetti: Control = tool._page._podium._sweeps[0]._source.get_node("EffectFlreworks")
		assert ( not confetti.visible)
		for node: Node in confetti.get_children():
			assert ( not (node as CPUParticles2D).emitting)
		assert (card.scale == Vector2.ONE and card.pivot_offset == Vector2.ZERO)
		for name: String in rest:
			var node: Control = card.get_node(name)
			assert ([node.position, node.scale, node.rotation, node.pivot_offset] == rest[name], name + " moved during first-place feedback")
		assert (tool._page._crown.visible)
		if tool._stage == "皇冠放大 → 下砸回弹":
			if drop_at < 0.0:
				drop_at = tool._elapsed
				assert (tool._page._podium._sweeps[0].visible)
			peak_scale = maxf(peak_scale, tool._page._crown.scale.x)
		await get_tree().process_frame
	assert (drop_at - sweep_at >= 0.18 and drop_at - sweep_at < 0.27)
	assert (peak_scale > 3.3)
	assert (tool._page._crown.position.is_equal_approx(tool._page._crown.anchor_phase3))
	assert (tool._page._crown._idle_tween != null)
	var sweep: RankPodiumSweepFx = tool._page._podium._sweeps[0]
	await _wait( func() -> bool: return sweep._tween != null and sweep._tween.get_total_elapsed_time() >= 1.6)
	assert (sweep.visible)
	for particle: CPUParticles2D in sweep._particles:
		assert ( not particle.emitting, "one-shot emitter was retriggered")
	await _wait( func() -> bool: return not sweep.visible)
	print("FIRST_FEEDBACK_PASS: still board, sweep lead=", drop_at - sweep_at, " crown peak=", peak_scale, " one-shot tails survive old 1.5s cutoff")

func _wait(predicate: Callable) -> void :
	var deadline: int = Time.get_ticks_msec() + 15000
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert (predicate.call(), "first collect preview timed out")
