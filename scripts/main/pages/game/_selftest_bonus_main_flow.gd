extends Node


var _failures: Array[String] = []
var _page: JuiceGamePage
var _board: JuiceBoardView

func _ready() -> void :
	call_deferred("_run")

func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		print("BONUS_MAIN_FAIL ", message)

func _wait_board() -> void :
	var deadline: int = Time.get_ticks_msec() + 15000
	while (_board.is_busy() or _page._bonus_pot_collecting or _page._bonus_pig_hud.is_flying() or _page._has_cup_flights()) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(Time.get_ticks_msec() < deadline, "Real collection chain finishes")

func _run() -> void :
	DbManager.init()
	UserState.set_current_level(13)
	_page = load("res://scripts/main/pages/game/juice_game_page.tscn").instantiate() as JuiceGamePage
	add_child(_page)
	_page.set_process(false)
	assert ( await _page.prepare_for_display( func() -> bool: return is_instance_valid(_page)))
	assert ( await _page._ensure_component_groups(["bonus", "end_bonus"], func() -> bool: return true))
	assert ( await _page._components.ensure_resources(PackedStringArray([GamePagePreparation.WIN_COIN_PATH]), 
		func() -> bool: return true))
	_board = _page._board
	_board.show()

	for info: Dictionary in _board.get_signal_list():
		if info["name"] in ["cup_collected", "pot_collect_enqueuing"]:
			continue
		for connection: Dictionary in _board.get_signal_connection_list(info["name"]):
			if connection["callable"].get_object() == _page:
				_board.disconnect(info["name"], connection["callable"])
	var model: = JuiceLevelModel.new()
	model.level_id = 13
	model.chapter_index = 1
	model.difficulty_type = "Normal"
	model.juice = JuiceLevel.from_dict({"id": 13, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "1|1", "-|0,1"], "incoming": []})
	model.raw = model.juice.to_dict()
	_page._level_model = model
	_board._bonus_plan_pending = {"type": 0}
	_board.setup(model.juice)
	_board._cancel_closed_check()
	_page._bonus_type = _board.bonus_type()
	_page._quota.setup(2)
	_page._layout()
	_page._playfield_ready = true
	_page._ui_props_ready = true
	_board.set_entrance_lock(false)
	await get_tree().process_frame
	_check(_page.is_bonus_level_round(), "Candidate identity adopted by real page")
	_check(_board._texture_for_fruit(0) == _board.bonus_coin_texture, "Real rope uses static coin texture")
	_check(_board._texture_for_blender(0) == _board.bonus_pig_texture, "Real pot uses pig texture behind shelf")
	_page._save_initial_snapshot()
	var idle: BonusPigIdleFx = _board._bonus_idle_fx
	_check(is_instance_valid(idle), "Real Bonus pig has idle component")
	idle._process(0.6)
	_check(idle._active and idle._motes.emitting and idle._motes.amount == 4, "Pig idle has four rising motes")
	_check(idle._target.get_node("Body").material == idle._material, "Shine only affects Bonus pig")
	_check(float(idle._material.get_shader_parameter("intensity")) <= 0.1, "Idle shine weaker than banner")
	idle._process(1.0)
	_check(idle._star.emitting, "Idle sparkle occurs after shine")
	idle._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check( not idle._active and not idle._motes.emitting, "Background clears idle particles")
	idle._process(0.3)
	_check( not idle._active, "Idle does not restart in background")
	idle._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	idle._process(0.1)
	_check(idle._active, "Idle resumes after foreground")
	var expected_sparkle: Texture2D = JuiceGamePage.WIN_COIN_TRAIL_TEX
	_check(idle.point_texture == expected_sparkle and idle.star_texture == expected_sparkle, "Idle shares reward coin sparkle")
	_check(_page._bonus_pig_hud._trail_dust.texture == expected_sparkle and _page._bonus_pig_hud._arrival_stars.texture == expected_sparkle, "Flight and dock share reward coin sparkle")
	var entry_fx: BonusCoinEntryFx = _board._bonus_entry_fx
	_check(entry_fx.point_texture == expected_sparkle and entry_fx.star_texture == expected_sparkle and BonusGoldTrails.DUST_TEXTURE == expected_sparkle, "Collection and receipt share reward coin sparkle")
	_check(is_instance_valid(entry_fx) and is_instance_valid(_board._bonus_gold_trails), "Feedback and trail pools prebuilt before collection")
	var probe_origins: Array[Vector2] = [Vector2(400, 500), Vector2(400, 650)]
	entry_fx.start_coin_burst(probe_origins)
	entry_fx._sample_burst(0.08)
	_check(entry_fx._burst_coins[0].global_position.distance_to(entry_fx._burst_coins[1].global_position) > 90.0, "Merge point coins separated on opposite sides")
	_check( not entry_fx._burst_coins[4].visible, "Only two debris coins per source")
	entry_fx.reset()
	var emit: GPUParticles2D = _board._fire_rope_petals(200.0, 300.0, 900.0, 8, 
		JuiceBoardView.ROPE_PETAL_SPIN_MIN, JuiceBoardView.ROPE_PETAL_SPIN_MAX, Color.WHITE, true)
	var pm: ParticleProcessMaterial = emit.process_material as ParticleProcessMaterial
	_check(emit.texture == _board.bonus_coin_texture and emit.material == null, "Original particle emitter uses whole coin artwork not petal atlas")
	_check(is_equal_approx(emit.lifetime, JuiceBoardView.ROPE_PETAL_LIFETIME) and is_equal_approx(pm.initial_velocity_max, JuiceBoardView.ROPE_PETAL_SPEED_MAX), "Coin debris uses original flower drift speed and lifetime")
	_check(pm.scale_min * emit.texture.get_width() >= 40.0, "Coin debris has readable 40-58px size")
	emit.emitting = false
	_board._release_rope_petal_emitter(emit)

	var coin_targets: Array[Node2D] = []
	var coin_ribbons: Array[FireworkTrails.Ribbon] = []
	for i: int in range(4):
		var target: = Node2D.new()
		_board.add_child(target)
		coin_targets.append(target)
		coin_ribbons.append(_board._bonus_gold_trails.add_ribbon(target, 12.0, Color.YELLOW, 0.8, 0.2))
	_board._bonus_gold_trails.absorb_into_slot(coin_ribbons[0], 0.5, 0.8)
	_check(is_equal_approx(coin_ribbons[0].head_alpha, 0.4) and coin_ribbons[1].target == coin_targets[1], "Ingress fades only corresponding coin tail")
	for ribbon: FireworkTrails.Ribbon in coin_ribbons:
		_board._bonus_gold_trails.absorb_into_slot(ribbon, 1.0, 0.8)
		_check(ribbon.target == null and ribbon.pos.is_empty(), "Coin tail clears immediately at slot")
	_check(_board._bonus_gold_trails._dust_targets.all( func(target): return target == null), "All four coin dust emitters clear at slot")
	_board._bonus_gold_trails.clear_all()
	for target: Node2D in coin_targets:
		target.queue_free()
	var arc_start: = Vector2(760, 760)
	var arc_end: = Vector2(330, 100)
	var arc_mid: Vector2 = BonusPigHud.sample_flight_arc(arc_start, arc_end, 0.5)
	var line: Vector2 = (arc_end - arc_start).normalized()
	var deviation: float = absf((arc_mid - arc_start).cross(line))
	_check(deviation > 90.0, "Pig flight has visible sideways curvature")
	_check(BonusPigHud.flight_progress(0.2) < 0.07 and BonusPigHud.flight_progress(0.8) > 0.93, "Pig launch and landing have slow-fast-slow rhythm")

	var hud: BonusPigHud = _page._bonus_pig_hud
	hud.place_left_of_label(Rect2(450, 50, 180, 70), 180.0)
	var source_rect: = Rect2(380, 700, 170, 125)
	hud.fly_in_from(source_rect)
	hud._fly_tween.set_speed_scale(0.0)
	var shown: Rect2 = hud.dock_global_rect()
	_check(shown.position.distance_to(source_rect.position) < 0.1 and shown.size.distance_to(source_rect.size) < 0.1, "Pig flight preserves source position and non-square size")
	hud.hide_now()
	var original: JuiceBlender = _board.get("_blender_nodes")[1]
	var pool: JuiceNodePool = _board.get("_blender_pool")
	pool._live.erase(original)
	_board.get("_blender_nodes").erase(1)
	var body: Sprite2D = original.get_node("Body")
	var rect: Rect2 = body.global_transform * body.get_rect()
	var original_id: int = body.get_instance_id()
	var original_parent: Node = _board.garden_pot_layer
	hud.fly_in_from(rect, {"node": original, "pool": pool, "plank_top": rect.end.y, "lift_layer": original_parent})
	hud._fly_tween.set_speed_scale(0.0)
	_check(hud._body.get_instance_id() == original_id and not hud._pig.visible, "Real original pig node is sole flight visual")
	_check(original.get_parent() == original_parent, "Lift starts on unclipped layer behind shelf")
	hud._sample_flight(BonusPigHud.LIFT_DURATION * 0.99)
	_check(original.get_parent() == original_parent, "No layer swap before pig clears plank")
	hud._sample_flight(BonusPigHud.LIFT_DURATION - 1e-05)
	var before_promote: Rect2 = hud.dock_global_rect()
	hud._sample_flight(BonusPigHud.LIFT_DURATION)
	_check(hud.dock_global_rect().position.distance_to(before_promote.position) < 0.1 and hud.dock_global_rect().size.distance_to(before_promote.size) < 0.1, "Layer promotion has continuous world rect")
	_check(original.get_parent() == hud._flight_host and hud._body.get_instance_id() == original_id, "Promotes same node after lift without swapping image")
	_check(hud._spiral_started, "Lifted pig plays actual pot spiral")
	_check(hud.dock_global_rect().end.y < rect.end.y, "Pig clears shelf before promotion")
	_check(is_zero_approx(hud._spiral._t), "Spiral starts at zero local age")

	hud._flight_host.scale = Vector2(0.8, 1.1)
	hud._sample_flight(BonusPigHud.LIFT_DURATION)
	_check(hud.dock_global_rect().size.distance_to(rect.size * BonusPigHud.LIFT_SCALE) < 0.1, "Scaled flight parent keeps pig dimensions")
	hud._sample_flight(BonusPigHud.FLIGHT_START)
	_check(hud._spiral.is_running() and hud._spiral._cfg.fade_at_top and hud._flight_trails._ribbons.size() == 1, "Departure crossfades frozen spiral with one pig-following ribbon")
	_check(hud._trail_dust.emitting and hud._trail_dust.amount == 24, "Departure adds fine particle trail")
	_check(hud._flight_trails.z_index == 0 and hud._flight_trails.get_index() < hud._flight_host.get_index() and hud._trail_dust.z_index == 0, "Trail uses HUD canvas layer and draws behind pig")
	_check(hud._trail_dust.texture.resource_path.ends_with("point/ef_point_004.png") and (hud._trail_dust.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "Bonus uses the same sparkle texture and blend as smash reward coin trails")
	hud._sample_flight(BonusPigHud.FLIGHT_START + 0.1)
	_check(hud._flight_trails._ribbons.size() == 1 and hud._trail_anchor.global_position.distance_to(hud.dock_global_rect().get_center()) < 0.1, "One ribbon follows actual pig center")
	hud._sample_flight(BonusPigHud.FLIGHT_START + 0.12)
	_check(hud._spiral.modulate.a > 0.0 and hud._spiral.modulate.a < 1.0, "Spiral tail fades continuously during launch")
	hud._sample_flight(BonusPigHud.ARRIVAL_START)
	_check(hud._arrival_started and hud._arrival_dust.emitting and hud._arrival_stars.emitting, "Dock impact triggers point and star burst")
	_check( not hud._trail_dust.emitting and hud._flight_ribbon.target == null, "Arrival stops emitting and detaches trail")
	_check(hud._arrival_dust.z_index == 0 and hud._arrival_dust.get_index() < hud._flight_host.get_index(), "Impact glow expands behind pig without whitening face")
	var arrival_center: Vector2 = hud.dock_global_rect().get_center()
	hud._sample_flight(BonusPigHud.ARRIVAL_START + BonusPigHud.ARRIVAL_PUNCH_DURATION * 0.5)
	_check(hud.dock_global_rect().size.distance_to(Vector2.ONE * 96.0 * 1.08) < 0.1, "Dock rebound smoothly peaks at 108 percent")
	_check(hud.dock_global_rect().get_center().distance_to(arrival_center) < 0.1 and hud._arrival_dust.global_position.distance_to(arrival_center) < 0.1, "Rebound and explosion stay centered on dock")
	hud._sample_flight(BonusPigHud.ARRIVAL_START + BonusPigHud.ARRIVAL_DURATION)
	_check(hud.dock_global_rect().size.distance_to(Vector2(96, 96)) < 0.1, "Original pig reaches dock size")
	hud.hide_now()
	hud._flight_host.scale = Vector2.ONE
	_check(pool._free.has(original), "Cancel returns borrowed original pig to its pool")
	_check(hud._flight_trails._ribbons.is_empty() and not hud._arrival_dust.emitting and not hud._arrival_stars.emitting, "Cancel clears trail and arrival burst")
	var pending: JuiceBlender = pool.acquire(_board.garden_pot_layer) as JuiceBlender
	_board._bonus_handoff_source = pending
	_board.stop_bonus_entry_feedback()
	_check(pool._free.has(pending) and _board._bonus_handoff_source == null, "Cancel before handoff returns pending original")
	_board._bonus_plan_pending = {"type": 0}
	_board.setup(model.juice)
	_board._cancel_closed_check()
	_page._bonus_type = 0
	var snapshot: Dictionary = _board.snapshot()
	_check(snapshot["bonus_type"] == 0, "Snapshot persists Bonus identity")
	_check(BonusLevelEntry.is_next_bonus(13, snapshot, false), "Home resume uses saved identity")
	_check( not BonusLevelEntry.is_next_bonus(14, {"bonus_type": -1}, false), "Ordinary resume stays ordinary")
	_check(_board.try_move(0, 1, 2), "Normal flower column collects via real rules")
	await _wait_board()
	_check( not _page._bonus_pig_hud.is_docked(), "Non-Bonus collection does not dock pig")
	_check(_board.try_move(0, 0, 1), "Bonus coin column collects via same real rules")
	var saw_burst: bool = false
	var saw_gold_trail: bool = false
	var saw_entry: bool = false
	var saw_collect_wait: bool = false
	var deposit_beat: Dictionary = {}
	var deadline: int = Time.get_ticks_msec() + 15000
	while (_board.is_busy() or _page._bonus_pot_collecting or _page._bonus_pig_hud.is_flying()) and Time.get_ticks_msec() < deadline:
		saw_entry = saw_entry or _board.is_bonus_entry_feedback_running()
		for beat: Dictionary in _board.get("_beats"):
			saw_burst = saw_burst or bool(beat.get("bonus_coin_debris", false))
			if bool(beat.get("bonus_sequential", false)):
				deposit_beat = beat
		saw_gold_trail = saw_gold_trail or (is_instance_valid(_board._bonus_gold_trails) and not _board._bonus_gold_trails._ribbons.is_empty())
		saw_collect_wait = saw_collect_wait or _page._bonus_pot_collecting
		await get_tree().process_frame
	_check(saw_burst, "Bonus merge shows small coin debris instead of flower petals")
	_check(saw_gold_trail, "Real Bonus collection uses layered gold spiral-style trail")
	_check(saw_entry and saw_collect_wait, "Actual deposit feedback plays before pig flies")
	_check(_page._bonus_pig_hud.is_docked(), "Real pig docks at Level left instead of order frame")
	_check(_page._quota.filled_count() == 2 and _page._quota._hidden_completed_slots.has(1), "Bonus counts as complete without rendering duplicate pig in order panel")
	_check( not idle._active and not idle._motes.emitting, "Collected pig does not retain idle particles")
	_check(is_instance_valid(_board._bonus_entry_fx) and _board._bonus_entry_fx.get_parent() == _page, "Real entry particles bypass board clipping")
	_check(deposit_beat.get("bonus_arrived", {}).size() == 2
		and is_instance_valid(_board._bonus_entry_fx) and _board._bonus_entry_fx._count == 1, 
		"Both real coins arrive sequentially with one entry effect per arrival")
	_check(_board._bonus_entry_fx._burst_coins.size() == 12, "Merge debris has bounded two-per-source pool")
	_check(is_instance_valid(_board._bonus_gold_trails) and _board._bonus_gold_trails._dust_emitters.size() == 6, "Layered coin trails include bounded fine dust pools")
	_check(_board._bonus_entry_fx._pig_target == null and not _board._bonus_entry_fx._receive.visible, "Stored confirmation resets pig overlay before departure")
	var before: int = UserState.get_coins()
	_page._bonus_v2 = true
	_page._commit_win_data_once()
	var rewarded: int = UserState.get_coins()
	_check(rewarded - before == 2 * _page.COIN_PER_TARGET + JuiceBonusLevel.reward_coins(true), "Normal plus Bonus reward awarded once")
	_page._commit_win_data_once()
	_check(UserState.get_coins() == rewarded, "Repeated commit cannot award twice")
	await _page.play_bonus_pig_smash()
	_check(UserState.get_coins() == rewarded, "Smash is presentation only")
	_check(_page._bonus_coin_pending == 0, "Real coin HUD finishes pending bonus display")
	_check( not _page._bonus_gain_label.visible and _page._bonus_gain_tween == null
		and _page._bonus_gain_label.text == "+300", 
		"2.0 gain label plays during the coin flight and hides before the smash step returns")


	_check(_page._bonus_pig_smash.visible
		and is_equal_approx(_page._bonus_pig_smash.held_background_opacity(), 0.55), 
		"Smash keeps Bonus dim when rank collection is skipped")
	var receiver: = DialogScene.new()
	add_child(receiver)
	var handoff_ok: Array[bool] = [false]
	receiver._on_show({"background_initial_opacity": _page._bonus_pig_smash.held_background_opacity(), 
		"background_handoff": func() -> void :
			handoff_ok[0] = is_equal_approx(receiver._bg.color.a * receiver._bg.modulate.a, 0.55)
			_page._bonus_pig_smash.hide_now()})
	_check(handoff_ok[0] and not _page._bonus_pig_smash.visible, 
		"Finish background installed at same opacity before Bonus dim removed")
	var dim_deadline: int = Time.get_ticks_msec() + 2000
	while receiver._bg_tween != null and receiver._bg_tween.is_valid() and receiver._bg_tween.is_running() and Time.get_ticks_msec() < dim_deadline:
		await get_tree().process_frame
	_check(is_equal_approx(receiver._bg.color.a * receiver._bg.modulate.a, 0.8), "Finish background smoothly reaches normal 80 percent darkness")
	receiver.queue_free()


	_check(_board.restore(model.juice, snapshot), "Restore accepts Bonus snapshot")
	_page._bonus_type = _board.bonus_type()
	_page._on_cups_changed()
	_check( not _page._bonus_pig_hud.is_docked(), "Restoring uncollected pig clears old dock")
	_board._bonus_plan_pending = {"type": 0}
	_board.setup(model.juice)
	_board._cancel_closed_check()
	_page._bonus_type = 0
	_page._quota.setup(2)
	_check(_board.try_move(0, 1, 2), "Undo setup move valid")
	await _wait_board()
	_check(_board.undo(), "Undo retains original rules")
	_page._on_cups_changed()
	_check(_board.bonus_type() == 0, "Undo retains Bonus identity")
	_check(UserState.get_coins() == rewarded, "Undo/restoring does not reaward or subtract reward")

	_page._bonus_pot_collecting = true
	_page._cancel_bonus_collection()
	_check( not _page._bonus_pot_collecting and not _board.is_bonus_entry_feedback_running(), "Cancel clears pending feedback")
	_page._bonus_level_banner.play()
	_page.reset_reuse_state()
	_check( not _page._bonus_level_banner.visible and not _page._bonus_pig_smash.visible, "Reuse clears Bonus presentation")
	_board._cancel_closed_check()
	_page.queue_free()
	for frame: int in range(5):
		await get_tree().process_frame
	print("BONUS_MAIN_FLOW_SELFTEST ", JSON.stringify({"passed": _failures.is_empty(), "failures": _failures}))
	get_tree().quit(0 if _failures.is_empty() else 1)
