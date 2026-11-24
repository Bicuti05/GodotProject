extends Node

const PREVIEW: PackedScene = preload("res://scripts/debug/ui/bonus_motion_preview.tscn")
var _failures: Array[String] = []

func _ready() -> void :
	call_deferred("_run")

func _check(condition: bool, message: String) -> void :
	if not condition:
		_failures.append(message)

func _fingerprint() -> String:
	return JSON.stringify([UserState.get_coins(), UserState.get_current_level(), 
		UserState.get_prop_count("hint"), UserState.get_prop_count("undo"), 
		UserState.get_prop_count("rope"), UserState.get_win_streak_count()])

func _run() -> void :
	var before: String = _fingerprint()

	var page: JuiceGamePage = load("res://scripts/main/pages/game/juice_game_page.tscn").instantiate() as JuiceGamePage
	add_child(page)
	page.set_process(false)
	var page_board: JuiceBoardView = page.get("_board") as JuiceBoardView
	for signal_info: Dictionary in page_board.get_signal_list():
		for connection: Dictionary in page_board.get_signal_connection_list(signal_info["name"]):
			if connection["callable"].get_object() == page:
				page_board.disconnect(signal_info["name"], connection["callable"])
	var anchor_level: = JuiceLevel.from_dict({"id": 12, "capacity": 4, "targetCups": 3, 
		"initial": ["6|6,6,6", "-|6", "0|0,4,0,4", "4|4,0,4,0"], "incoming": []})
	page_board.setup(anchor_level)
	page_board._cancel_closed_check()
	page._playfield_ready = true
	await get_tree().process_frame
	var real_anchors: Dictionary = page.get_bonus_motion_preview_anchors()
	_check( not real_anchors.is_empty(), "Real game page anchor getter executes without TextureRect property error")
	if not real_anchors.is_empty():
		_check((real_anchors["coin_rect"] as Rect2).has_area(), "Real HUD TextureRect gives valid visible coin rect")
	page.queue_free()
	await get_tree().process_frame
	var preview: BonusMotionPreview = PREVIEW.instantiate() as BonusMotionPreview
	add_child(preview)
	preview.open(false, {"pot_rect": Rect2(450, 650, 180, 180), "coin_origins": [Vector2(540, 920), Vector2(540, 1080), Vector2(540, 1240), Vector2(540, 1400)], "coin_diameter": 150.0, "level_rect": Rect2(400, 30, 250, 80), "level_text_width": 180.0, "coin_rect": Rect2(920, 35, 64, 64)})
	_check(get_tree().paused, "Preview pauses underlying game")
	_check( not preview._coin_icon.visible and not preview._label.visible, "No fake coin HUD or Level label")
	_check((preview._anchors["coin_rect"] as Rect2).get_center() == Vector2(952, 67), "Real HUD snapshot is used")
	_check(preview._fill._coins.size() == 6 and preview._coins.size() == 8, "Spine coins use bounded six/eight pools")
	var coin: BonusSpineCoin = preview._coins[0]
	coin.size = Vector2.ONE * 100.0
	coin.pivot_offset = coin.size * 0.5
	coin.start_rotation(0.13, 1.0)
	_check(coin.spine.get_skeleton() != null, "Clover Spine loads for burst coins")
	_check(is_equal_approx(coin.spine.scale.x, 100.0 / BonusSpineCoin.REFERENCE_WIDTH), "Spine coin keeps requested flight diameter")
	_check(coin.visual_global_rect().get_center().distance_to(coin.global_position + coin.size * 0.5) < 0.1, "Spine holder is centered")
	var original_time: float = coin._time
	coin._process(0.2)
	_check(coin._time > original_time, "Visible clover coin rotates")
	coin.reset()
	_check(coin._track == null and not coin.is_processing(), "Reset clears Spine track and stops ticking")
	preview._coins[1].start_rotation(0.27)
	_check( not is_equal_approx(original_time, preview._coins[1]._time), "Coins use staggered rotation phases")
	preview._coins[1].reset()

	var board: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate() as JuiceBoardView
	add_child(board)
	board.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board.size = Vector2(1080, 1400)
	var level: = JuiceLevel.from_dict({"id": 12, "capacity": 4, "targetCups": 3, 
		"initial": ["6|6,6,6", "-|6", "0|0,4,0,4", "4|4,0,4,0"], "incoming": []})
	board.setup(level)
	board._cancel_closed_check()
	await get_tree().process_frame
	var geometry: Dictionary = board.bonus_collection_preview_geometry(2)
	_check( not geometry.is_empty(), "Real visible column supplies rope coin origins")
	var state_before: String = JSON.stringify(board.get("_state"))
	var parent_before: Node = preview._fill._pig.get_parent()
	_check(board.begin_bonus_collection_preview(preview._fill._pig, 2), "Pig can mount in real BlenderLayer")
	_check(preview._fill._pig.get_parent() == board.get("_blender_layer"), "Pig shares flower-pot layer below plank")
	_check(board.get("_blender_layer").get_index() < board.get("_plank").get_index(), "Shelf plank draws after pot layer")
	_check( not board.get("_blender_nodes")[2].visible and not board.get("_fruit_nodes")[2][0].visible, "Original pot and flowers hidden only for preview")
	var origins: Array[Vector2] = []
	for point: Vector2 in geometry["coin_origins"]:
		origins.append(point)
	preview._fill.play(geometry["pot_rect"], origins, float(geometry["coin_diameter"]), 1.0)
	preview._fill._tween.set_speed_scale(0.0)
	_check(preview._fill._coins[0].global_position.distance_to(origins[0]) < 0.1, "Coin starts at actual flower center")
	preview._fill._sample_collection(0.75)
	_check(preview._fill._ribbons[0] != null, "Rising coin has same batched ribbon renderer as flowers")
	preview._fill._sample_collection(0.85)
	_check(preview._fill._ribbons[0].pos.size() >= 2, "Ribbon samples moving Spine coin center")
	var shared: Dictionary = JuiceBoardView.sample_collection_motion(origins[0], 
		(geometry["pot_rect"] as Rect2).position + preview._fill.mouth_anchor * (geometry["pot_rect"] as Rect2).size, 
		0, 0.85 - BonusPigFill.ACCENT_DURATION)
	_check(preview._fill._coins[0].global_position.distance_to(shared["center"]) < 0.1, 
		"Bonus uses the exact same original flower collection trajectory")
	_check(is_equal_approx(preview._fill._coins[0].scale.x * preview._fill.coin_texture.get_width() / float(geometry["coin_diameter"]), float(shared["scale"])), "Bonus uses original flower shrink timing")
	_check(is_zero_approx(BonusPigFill.COLLECT_STAGGER), "Original collection is simultaneous, not invented staggered deposit")

	for sample_age: float in [0.05, 0.2, 0.3, 0.42, 0.58]:
		for index: int in range(4):
			var home: = Vector2(200.0, 500.0 + index * 150.0)
			var mouth: = Vector2(200.0, 300.0)
			var actual: Dictionary = JuiceBoardView.sample_collection_motion(home, mouth, index, sample_age)
			var expected: Vector2
			if sample_age < JuiceBoardView.GHOST_FADE_DUR:
				var t: float = sample_age / JuiceBoardView.GHOST_FADE_DUR
				expected = home + Vector2(0.0, - JuiceBoardView.SLAM_FLOAT_RISE * t * t * (3.0 - 2.0 * t))
			else:
				var u: float = clampf((sample_age - JuiceBoardView.GHOST_FADE_DUR) / JuiceBoardView.SLAM_FLY_DUR, 0.0, 1.0)
				var e: float = 1.0 - cos(u * PI * 0.5)
				var direction: float = -1.0 if index % 2 == 0 else 1.0
				var wave: float = direction * JuiceBoardView.SLAM_FLY_WAVE_AMP * pow(JuiceBoardView.SLAM_FLY_WAVE_AMP_GROWTH, float(index / 2)) * pow(JuiceBoardView.SLAM_FLY_WAVE_DECAY, floor(e * JuiceBoardView.SLAM_FLY_WAVE_CYCLES)) * sin(e * JuiceBoardView.SLAM_FLY_WAVE_CYCLES * PI)
				expected = (home + Vector2(0.0, - JuiceBoardView.SLAM_FLOAT_RISE)).lerp(mouth, e) + Vector2(wave, 0.0)
			_check((actual["center"] as Vector2).distance_to(expected) < 0.001, "Shared flower formula has no position regression")

	var final_arrival: float = BonusPigFill.ACCENT_DURATION + float(origins.size() - 1) * BonusPigFill.COLLECT_STAGGER + BonusPigFill.FLIGHT_DURATION + BonusPigFill.ENTRY_DURATION
	preview._fill._sample_collection(final_arrival + 0.21)
	for collected_coin: Sprite2D in preview._fill._coins:
		_check( not collected_coin.visible, "All collected coins disappear before pig flies")
	_check(preview._fill._pig.scale.is_equal_approx(Vector2.ONE), "Final pig punch finishes before dock flight")
	_check(preview._fill._entry_events.size() == origins.size(), "Every deposited static coin gets exactly one feedback event")
	_check(preview._fill._coins[0].rotation == 0.0, "Collection coins are static artwork, no Spine self-rotation")
	preview._fill._sample_collection(final_arrival + 0.04)
	_check(preview._fill._entry_events.size() == origins.size(), "Repeated sampling never emits another entry event")
	_check(preview._fill._entry_particles[0].visible, "Each deposit produces visible short mouth particles")
	preview._fill._sample_collection(final_arrival + 0.6)
	for particle: Sprite2D in preview._fill._entry_particles:
		_check( not particle.visible, "Deposit particles expire before pig departure")
	preview._fill.cancel()
	board.end_bonus_collection_preview()
	_check(preview._fill._pig.get_parent() == parent_before, "Stop returns borrowed pig to original parent")
	_check(board.get("_blender_nodes")[2].visible and board.get("_fruit_nodes")[2][0].visible, "Stop restores original pot and flowers")
	_check(JSON.stringify(board.get("_state")) == state_before, "Preview mount does not collect or change board state")
	board.queue_free()
	preview._speed = 1.0
	preview.play_stage(1)
	var fx_deadline: int = Time.get_ticks_msec() + 3500
	while preview._banner._next_star < 3 and Time.get_ticks_msec() < fx_deadline:
		await get_tree().process_frame
	_check( not preview._banner.base_art_only, "Approved base art now plays new FX")
	var shine: ShaderMaterial = preview._banner._pig.material as ShaderMaterial
	_check(shine != null and is_equal_approx(float(shine.get_shader_parameter("intensity")), 0.16), "Pig has gentle scene-local shine")
	preview._banner._sample_motion(1.25)
	_check(is_equal_approx(float(shine.get_shader_parameter("progress")), 1.0), "Shine leaves image after a single pass")
	_check(preview._banner._motes.emitting and preview._banner._motes.amount == 16, "16 rising CPU motes active")
	_check(preview._banner._motes.emission_rect_extents.x >= 400.0, "Motes span both coin piles and pig")
	_check(preview._banner._motes.scale_amount_min >= 0.1, "Mote minimum diameter doubled")
	_check(preview._banner._next_star >= 3 and preview._banner._stars.size() == 6, "Coin/pig highlights stagger across six pooled emitters")
	preview.stop()
	_check(preview._banner._float_host.position == preview._banner._float_origin, "Cancel resets float position")
	_check(is_zero_approx(float(shine.get_shader_parameter("progress"))), "Cancel resets shine for replay")
	_check( not preview._banner._motes.emitting and preview._banner._next_star == 0, "Cancel clears emission and delayed star index")
	_check(is_equal_approx(preview._banner._art.scale.x, 1.0), "Cancel restores pop scale")

	var smash: BonusPigSmash = preview._smash
	smash.play(Rect2(100.0, 100.0, 96.0, 96.0), Vector2(500.0, 850.0))
	smash._tween.set_speed_scale(0.0)
	smash._sample(BonusPigSmash.PIG_SOURCE_HOLD * 0.9)
	_check((smash._pig.get_global_transform() * Rect2(Vector2.ZERO, smash._pig.size)).get_center().distance_to(Vector2(148, 148)) < 0.1, "Smash visibly starts at supplied label-side pig position before launch")
	var contact: float = BonusPigSmash.PIG_FLY_DUR + BonusPigSmash.PIG_HOLD_DUR + BonusPigSmash.CONTACT_TIME
	smash._sample(BonusPigSmash.PIG_FLY_DUR + BonusPigSmash.PIG_HOLD_DUR + 0.1)
	_check(is_zero_approx(smash._hammer.modulate.a), "Hammer is transparent before initial attachment appears")
	smash._sample(BonusPigSmash.PIG_FLY_DUR + BonusPigSmash.PIG_HOLD_DUR + 0.18)
	_check(smash._hammer.modulate.a > 0.0 and smash._hammer.modulate.a < 1.0, "Hammer first appearance fades rather than pops")
	smash._sample(contact - 0.01)
	_check( not smash._contact and not smash._ceramic._active, "Pig remains whole before hammer contact")
	smash._sample(contact)
	var hit_bone: SpineBone = smash._hammer.get_skeleton().find_bone("images/Impact_2")
	var hit: Vector2 = smash._hammer.to_global(Vector2(hit_bone.get_world_x(), hit_bone.get_world_y()))
	_check(hit.distance_to(smash.hit_global_position()) < 0.1, "Spine hit anchor matches pig middle within 0.1px")
	_check( not smash._reward_emitted, "Coin flight waits until after contact")
	_check(is_zero_approx(float(smash._impact_particles[0]["delay"])) and float(smash._impact_particles[6]["delay"]) > 0.0, "Hit dust appears at contact, shard trails wait")
	_check(is_equal_approx(BonusPigSmash.BIG_PIG_SIZE, 655.2) and is_equal_approx(smash.hammer_scale, 0.936), "Final smash presentation enlarged another 20 percent")
	_check(smash._hammer.z_index > smash._pig.z_index, "Hammer draws above whole pig")
	_check(smash._impact_particles.size() == 10, "Bounded pool: 6 hit puffs, 4 trails")
	_check(float(smash._impact_particles[0]["scale"]) * 256.0 >= 240.0, "Impact dust large enough to read at pig scale")
	_check(float(smash._impact_particles[0]["alpha"]) >= 0.38, "Impact dust no longer nearly transparent")
	var dust_left: Vector2 = smash._impact_particles[0]["origin"]
	var dust_right: Vector2 = smash._impact_particles[5]["origin"]
	_check(dust_right.x - dust_left.x > 180.0, "Smoke distributed across both sides, not clustered at center")

	smash._sample(contact + 0.04)
	_check(smash._ceramic._shards.size() == 22 and smash._ceramic._active, "Contact creates 22 pooled ceramic shards")
	_check( not smash._pig.visible, "Whole pig is replaced by shell shards")
	_check(smash._impact_particles[0]["node"].visible, "Hit smoke appears from contact clock")
	_check( not smash._impact_particles[6]["node"].visible, "Shard trails wait until fragments have separated")
	smash._sample(contact + 0.09)
	_check( not smash._reward_emitted, "Smoke has a readable beat before coins")
	smash._sample(contact + 0.24)
	_check(smash._reward_emitted, "Coin flight begins after visible impact beat")
	smash._sample(contact + 0.2)
	_check(smash._impact_particles[6]["node"].visible, "Selected shard receives delayed smoke")
	smash._sample(contact + 0.75)
	for particle: Dictionary in smash._impact_particles:
		_check( not particle["node"].visible, "Particle expires before end of smash")
	smash.hide_now()
	for particle: Dictionary in smash._impact_particles:
		_check( not particle["node"].visible, "Cancel hides pooled impact particle")
	_check( not smash._hammer.visible and not smash._ceramic._active, "Cancel clears Spine and shards")
	preview._speed = 2.0
	preview.play_stage(0)
	var deadline: int = Time.get_ticks_msec() + 15000
	while preview.is_running() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check( not preview.is_running(), "Full flow completes without deadlock")
	_check(preview.stages_seen == ["横幅", "金币入罐", "金猪飞入顶栏", "飞出砸猪＋金币"], "Full flow stage order")
	_check(preview._balance.text == str(UserState.get_coins() + 100), "Demo HUD shows reward without awarding")
	_check(_fingerprint() == before, "User economy/level/props/streak unchanged")
	_check(preview._flight_specs.size() == 8 and float(preview._flight_specs[4]["delay"]) >= 0.5, "Burst uses two distinct four-coin volleys")
	_check(preview._flight_specs[0]["start"] != preview._flight_specs[1]["start"], "Coin lanes curve in alternate directions")
	_check(is_equal_approx(preview._coins[0].size.x, 135.0) and is_equal_approx(preview._coins[2].size.x, 165.0), "Burst coins enlarged another 1.5x to 135-165px")
	preview._coins[0].start_rotation(0.32)
	preview._fly_coin(1.0, preview._coins[0], Vector2(500, 800), Vector2(952, 67), preview._generation)
	var actual_landing: Rect2 = preview._coins[0].visual_global_rect()
	_check(actual_landing.get_center().distance_to(Vector2(952, 67)) < 0.1, "Rendered Spine center reaches HUD icon")
	_check(actual_landing.size.distance_to(Vector2(64, 64)) < 0.1, "Rendered Spine outline fits HUD icon, not only holder")
	_check(preview._coin_trails.size() == 8, "Each burst coin has real win-coin CPU trail")
	for trail: CPUParticles2D in preview._coin_trails:
		_check(trail.texture == JuiceGamePage.WIN_COIN_TRAIL_TEX and is_equal_approx(trail.lifetime, JuiceGamePage.WIN_COIN_TRAIL_LIFETIME), "Bonus reuses original trail texture and lifetime")
	preview._coins[1].start_rotation(0.32)
	preview._begin_coin_trail(preview._coin_trails[1], preview._coins[1])
	_check(preview._coin_trails[1].emitting, "Trail starts on curve flight")
	preview._fly_coin(0.4, preview._coins[1], Vector2(600, 900), Vector2(952, 67), preview._generation)
	_check(preview._coin_trails[1].global_position.distance_to(preview._coins[1].visual_global_rect().get_center()) < 0.1, "Trail follows actual Spine flight center")
	preview._coins[1].reset()
	for stage: int in range(1, 5):
		preview.play_stage(stage)
		await get_tree().process_frame
		preview.stop()
		await get_tree().process_frame
		_check( not preview.is_running() and not preview._smash.visible and not preview._fill.visible, "Stop cleans stage %d" % stage)
	preview.play_stage(2)
	await get_tree().process_frame
	preview.play_stage(4)
	deadline = Time.get_ticks_msec() + 7000
	while preview.is_running() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check( not preview.is_running() and preview.stages_seen == ["飞出砸猪＋金币"], "Replay takes over canceled coroutine")
	preview._loop.button_pressed = true
	var completed: int = preview.completed_runs
	preview.play_stage(3)
	deadline = Time.get_ticks_msec() + 7000
	while preview.completed_runs < completed + 2 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(preview.completed_runs >= completed + 2, "Loop replays bounded pooled objects")
	preview.close()
	_check( not get_tree().paused and not preview._active, "Close restores original pause state")
	get_tree().paused = true
	preview.open(false, {"pot_rect": Rect2(450, 650, 180, 180), "coin_origins": [Vector2(540, 920), Vector2(540, 1080), Vector2(540, 1240), Vector2(540, 1400)], "coin_diameter": 150.0, "level_rect": Rect2(400, 30, 250, 80), "level_text_width": 180.0, "coin_rect": Rect2(920, 35, 64, 64)})
	preview.close()
	_check(get_tree().paused, "An originally paused game stays paused")
	get_tree().paused = false
	preview.open(false, {"pot_rect": Rect2(450, 650, 180, 180), "coin_origins": [Vector2(540, 920), Vector2(540, 1080), Vector2(540, 1240), Vector2(540, 1400)], "coin_diameter": 150.0, "level_rect": Rect2(400, 30, 250, 80), "level_text_width": 180.0, "coin_rect": Rect2(920, 35, 64, 64)})
	preview.play_stage(2)
	preview._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check( not get_tree().paused and not preview._active, "Background cancels and releases pause")
	_check(_fingerprint() == before, "All preview operations preserve data")
	preview.queue_free()
	await get_tree().process_frame
	print("BONUS_MOTION_PREVIEW_SELFTEST ", JSON.stringify({"passed": _failures.is_empty(), "failures": _failures}))
	get_tree().quit(0 if _failures.is_empty() else 1)
