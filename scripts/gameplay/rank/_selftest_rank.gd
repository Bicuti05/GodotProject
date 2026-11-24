extends Node

const FinishMotion = preload("res://scripts/gameplay/rank/view/motion/rank_finish_motion.gd")
const PodiumSweepFx = preload("res://scripts/gameplay/rank/view/rank_podium_sweep_fx.gd")

class HomeEnterProbe extends Node:
	signal progress_finished
	var generation: int = 0
	var rank_session_count: int = 0

	func play_outer_loop_progress(_level_won: bool) -> void :
		await progress_finished

	func run_rank_session() -> void :
		rank_session_count += 1

	func finish_home_enter(active: Callable) -> void :
		if active.call():
			await run_rank_session()

class ChapterProgressWait extends RefCounted:
	signal completed

class HomeChapterProbe extends HomePage:
	var progress_waits: Array[ChapterProgressWait] = []
	var start_calls: int = 0
	var was_session_running: bool = true
	var rank_calls: int = 0
	var probe_rank_go: bool = false

	func _start_game_from_home(is_special: bool) -> void :
		if not probe_rank_go:
			await super._start_game_from_home(is_special)
			return
		start_calls += 1
		was_session_running = _rank_session_running

	func open_rank_page() -> void :
		if not probe_rank_go:
			await super.open_rank_page()
			return
		rank_calls += 1


	func play_outer_loop_progress(_level_won: bool) -> void :
		var wait: = ChapterProgressWait.new()
		progress_waits.append(wait)
		await wait.completed


	func _refresh_play_button() -> void :
		pass

	func _start_unavailable_retry() -> void :
		pass

	func _play_logo() -> void :
		pass

func _reset_rank_state() -> void :
	UserState.reset_all()


func _ready() -> void :
	UserState.set_rank_disabled(false)
	if "--rank-update-final-only" in OS.get_cmdline_user_args():
		_test_rank_update_final_difficulty()
		SortLogger.info("RANK_RESTORE_PASS: rank_update final difficulty")
		get_tree().quit()
		return
	if "--rank-update-only" in OS.get_cmdline_user_args():
		await _test_rank_update()
		SortLogger.info("RANK_RESTORE_PASS: rank_update experiment rules, budgets, persistence and round eligibility")
		get_tree().quit()
		return
	if "--virtual-only" in OS.get_cmdline_user_args():
		await _test_virtual_list()
		AudioManager.stop_all_sfx()
		await get_tree().create_timer(0.2).timeout
		SortLogger.info("RANK_RESTORE_PASS: fixed row pools, recycled scroll windows, receiver ownership, cancellation and large rank rises")
		get_tree().quit()
		return
	if "--home-session-only" in OS.get_cmdline_user_args():
		await _test_home_season_expiry()
		SortLogger.info("RANK_RESTORE_PASS: normal-season rank stays open, stale home entry cancellation, home/rank countdown settlement, modal waiting and expired rank click")
		get_tree().quit()
		return
	if "--ui-only" in OS.get_cmdline_user_args():
		await _test_rank_row_text_layout()
		_reset_rank_state()
		UserState.set_current_level(21)
		RankManager.invalidate_snapshot()
		RankManager.ensure_profile()
		RankManager.ensure_season()
		_test_rank_collect_command()
		await _test_avatars()
		await _test_trophy_shadows()
		_test_rank_ui_layout()
		await _test_claim_coin_hud_layout()
		_test_rank_zone_snapshots()
		await _test_reward_gift_connections()
		await _test_rank_introduction_layout()
		await _test_title_render_sequence()
		SortLogger.info("RANK_RESTORE_PASS: 29-locale introduction text and arrow separation, rank UI layers, digit centering, gift particles/reset and title render ordering")
		get_tree().quit()
		return
	if "--finish-word-only" in OS.get_cmdline_user_args():
		_reset_rank_state()
		UserState.set_current_level(21)
		RankManager.invalidate_snapshot()
		RankManager.ensure_profile()
		RankManager.ensure_season()
		var finish: RankGameFinishPage = load("res://scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn").instantiate()
		add_child(finish)
		assert ( await finish.prepare_content( func() -> bool: return true))
		await _test_finish_word(finish)
		finish._on_show({"result": {"rank_before": 30, "rank_after": 24}})
		assert ( not finish._encourage_word.visible)
		await _wait_until( func() -> bool: return finish._encourage_word.visible)
		assert (finish._list._animation_tweens.all( func(tween: Tween) -> bool: return not tween.is_valid() or not tween.is_running()))
		finish._on_hide()
		finish._on_show({"result": {"rank_before": 1, "rank_after": 2}})
		await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
		assert ( not finish._encourage_word.visible)
		await _test_finish_rise_tip(finish)
		finish._on_hide()
		finish.queue_free()
		SortLogger.info("RANK_RESTORE_PASS: finish encouragement thresholds, rank decline suppression, five Spine skins, native animation timing, top-three confetti, cancellation/replay and six localized finish tip pools")
		get_tree().quit()
		return
	if "--settlement-only" in OS.get_cmdline_user_args():
		_reset_rank_state()
		RankManager.invalidate_snapshot()
		UserState.set_current_level(21)
		RankManager.ensure_profile()
		assert (RankManager.ensure_season())
		RankManager.mark_guide_shown()
		await _test_settlement_presentation()
		AudioManager.stop_all_sfx()
		await get_tree().create_timer(0.2).timeout
		SortLogger.info("RANK_RESTORE_PASS: settlement first overlay frame, private animation, atomic rewards and cached cancellation/reuse")
		get_tree().quit()
		return
	if "--presentation-only" in OS.get_cmdline_user_args():
		await _test_presentations()
		SortLogger.info("RANK_RESTORE_PASS: ranking presentations, virtual podium transitions and cancellation")
		get_tree().quit()
		return
	if "--rules-only" in OS.get_cmdline_user_args():
		_test_finish_motion()
		_test_rules()
		_test_ledger()
		_test_bot_collect_migration()
		SortLogger.info("RANK_RESTORE_PASS: varied collect targets, offline accumulation, legal bonuses, migration, retry/dedup and season freezing")
		get_tree().quit()
		return
	if "--load-only" in OS.get_cmdline_user_args():
		await _test_direct_rank_display()
		SortLogger.info("RANK_RESTORE_PASS: zero startup UI warmup, one first-open rank Loading, stable cached reopen, direct finish display and cancellation")
		get_tree().quit()
		return
	if "--collect-bar-layout-only" in OS.get_cmdline_user_args():
		var owner: = Control.new()
		add_child(owner)
		var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
		owner.add_child(bar)
		bar.apply_layout(144.0)
		await _assert_collect_bar_layout(owner, bar)
		owner.queue_free()
		SortLogger.info("RANK_RESTORE_PASS: collect bar 1-8 digits, 99-to-100 transition, punch and delta bounds across viewport widths")
		get_tree().quit()
		return
	if "--source-collection-only" in OS.get_cmdline_user_args():
		var finish: RankGameFinishPage = load("res://scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn").instantiate()
		add_child(finish)
		assert ( await finish.prepare_content( func() -> bool: return true))
		finish.show()
		assert ( await finish._list.prepare_first_screen(_finish_snapshot(5), 5, func() -> bool: return true))
		assert ( await _prepare_test_list(finish._list))
		await _test_source_collection(finish)
		finish._on_hide()
		finish.queue_free()
		SortLogger.info("RANK_RESTORE_PASS: rank 1-5 source collection unclipped flight, row following, particle dimensions and cancellation")
		get_tree().quit()
		return
	if "--effects-only" in OS.get_cmdline_user_args():
		_reset_rank_state()
		RankManager.invalidate_snapshot()
		UserState.set_current_level(21)
		RankManager.ensure_profile()
		RankManager.ensure_season()
		await _test_new_season()
		await _test_season_win_effects()
		AudioManager.stop_all_sfx()
		await get_tree().create_timer(0.2).timeout
		print("RANK_RESTORE_PASS: 29 locales, title placement/aspect and simultaneous entrance, close/reopen cancellation, original flags animation, shared fireworks and GPU reset")
		get_tree().quit()
		return
	_test_finish_motion()
	_test_original_rank_fx()
	_test_rules()
	await _test_virtual_list()
	_test_ledger()
	InjectDebugToolsStep.new()._register_debug_routes()
	_test_scenes()
	await _test_home_season_expiry()
	await _test_avatars()
	await _test_trophy_shadows()
	_test_rank_ui_layout()
	await _test_claim_coin_hud_layout()
	await _test_rank_introduction_layout()
	await _test_presentations()
	await _test_new_season()
	await _test_title_render_sequence()
	await _test_season_win_effects()
	await _test_collect_bar()
	await _test_collect_abort_step()
	await _test_collect_effect_transform()
	AudioManager.stop_all_sfx()
	await get_tree().create_timer(0.15).timeout
	print("RANK_RESTORE_PASS: rules, season boundaries, atomic claims, score retry/dedup, rollback, dialog completion/cancellation, flight destinations and resource loading")
	get_tree().quit()


func _test_virtual_list() -> void :
	var active: Callable = func() -> bool: return true
	for route: String in ["rank", "rank_game_finish"]:
		var page: Control = load(SceneManager.PAGE_SCENES[route]).instantiate()
		add_child(page)
		page.show()
		assert ( await page.prepare_content(active))
		var list: RankListView = page._list
		var snap: RankSnapshot = _finish_snapshot(25)
		assert ( await list.prepare_first_screen(snap, 25, active))
		var pool_count: int = list.get_prepared_item_count()
		assert (pool_count > 0 and pool_count < 50 and pool_count == list._pool_capacity)
		assert (list.get_layout_entry_count() == (52 if route == "rank" else 49))
		assert (list._content.custom_minimum_size.y == list._layout.content_height)
		var receiver: RankItemView = list.find_my_item()
		assert (receiver != null)
		await _test_virtual_collectible_rebind(list, snap, receiver, active)
		var nodes: int = get_tree().get_node_count()
		var created: int = list.preparation_stats.created
		var bottom: float = maxf(list._layout.content_height - list._view_height(), 0.0)
		for scroll: float in [0.0, bottom, 1300.0, bottom * 0.5, 0.0, bottom]:
			list.set_scroll_vertical(scroll)
			await get_tree().process_frame
			assert (list.get_prepared_item_count() == pool_count and get_tree().get_node_count() == nodes)
			assert (list.preparation_stats.created == created)
			assert (list.find_my_item() == receiver)
			var window: Vector2i = list._layout.range_for_scroll(scroll, list._view_height())
			var assigned: Dictionary = {}
			for index: int in range(window.x, window.y + 1):
				var row: Control = list.row_node_at(index)
				assert (row != null and not assigned.has(row))
				assigned[row] = true
				assert (row.position.y == list.row_base_y_at(index))
				if row is RankItemView:
					assert (row.get_row_key() == list._layout.entries[index].key)
					assert (row._rank_pos == list._row_rank[index])
		for target: float in [0.0, bottom, bottom * 0.5, bottom]:
			list._scroll.scroll_vertical = int(target)
			await _wait_until( func() -> bool: return not list._refresh_pending and not list._stage_active)
			assert (absf(list.get_scroll_vertical() - target) <= 1.0)
			assert (list.preparation_stats.created == created and list.preparation_stats.scroll_created == 0)
			var visible_window: Vector2i = list._layout.range_for_scroll(list.get_scroll_vertical(), list._view_height())
			for index: int in range(visible_window.x, visible_window.y + 1):
				assert (list.row_node_at(index) != null)

		list.set_scroll_vertical(bottom * 0.5)
		list._drag_helper._fling = Vector2(0.0, 1200.0)
		list._drag_helper._process(1.0 / 60.0)
		assert (list._drag_helper._fling.y > 0.0)
		list._drag_helper._stop_fling()
		await _wait_until( func() -> bool: return not list._refresh_pending)
		list.set_scroll_vertical(bottom)
		var bound: int = list.preparation_stats.bound
		list.set_scroll_vertical(bottom - 1.0)
		await get_tree().process_frame
		assert (list.preparation_stats.bound == bound)
		assert ( await list.prepare_animation(active))
		if route == "rank_game_finish":
			for ranks: Vector2i in [Vector2i(50, 4), Vector2i(50, 3), Vector2i(3, 2), Vector2i(3, 1), Vector2i(2, 1), Vector2i(1, 1)]:
				var before: RankSnapshot = _finish_snapshot(ranks.x)
				assert ( await list.prepare_first_screen(before, ranks.x, active))
				await list.play_rise_anim(before, _finish_snapshot(ranks.y))
				assert (list._snapshot.my_rank_pos == ranks.y and list.find_my_item() != null)
				assert (list.get_prepared_item_count() == pool_count)
		list.cancel_animations()
		assert ( not list.is_first_screen_ready())
		assert ( await list.prepare_first_screen(snap, 25, active))
		assert (list.get_prepared_item_count() == pool_count)

		var old_height: float = list.size.y
		list.size.y += 600.0
		await get_tree().process_frame
		await _wait_until( func() -> bool: return not list._resizing_pool and not list._refresh_pending)
		assert (list.get_prepared_item_count() >= pool_count and list.get_prepared_item_count() <= 50)
		assert (list.get_prepared_item_count() >= list._required_capacity())
		var grown_count: int = list.get_prepared_item_count()
		list.size.y = old_height
		await get_tree().process_frame
		await _wait_until( func() -> bool: return not list._refresh_pending)
		assert (list.get_prepared_item_count() == grown_count)
		SortLogger.info("[RankVirtualTest] route=%s stats=%s" % [route, JSON.stringify(list.get_performance_stats())])
		page._on_hide()
		page.queue_free()
		await get_tree().process_frame

	InjectDebugToolsStep.new()._register_debug_routes()
	var preview: Node = SceneManager.show_debug_panel("rank_first_collect_preview", {"auto_play": false})
	await _wait_until( func() -> bool: return preview._stage == "就绪")
	assert (get_tree().paused and preview._page._list.find_my_item() != null)
	preview.replay()
	await _wait_until( func() -> bool: return preview._page._list._collect_source_fx.visible)
	preview.close()
	assert ( not get_tree().paused and not preview.visible)
	assert ( not preview._page._list._collect_source_fx.visible)


func _test_virtual_collectible_rebind(list: RankListView, snap: RankSnapshot, 
		receiver: RankItemView, active: Callable) -> void :
	var pool: RankCollectElementPool = list._element_pool
	var original: Texture2D = pool.presentation_texture
	var created: int = list.preparation_stats.created

	for index: int in [0, 1, 2, 3, -1]:
		var texture: Texture2D = pool.get_texture_for_index(index)
		pool.presentation_texture = texture
		assert ( await list.prepare_first_screen(snap, snap.my_rank_pos, active))
		assert (list.find_my_item() == receiver)
		assert (receiver._collect_icon.texture == texture)
		for item: RankItemView in list._items:
			if item.visible:
				assert (item._collect_icon.texture == texture)
		assert (list.preparation_stats.created == created)
		var bound: int = list.preparation_stats.bound
		assert ( await list.prepare_first_screen(snap, snap.my_rank_pos, active))
		assert (list.preparation_stats.bound == bound)
	pool.presentation_texture = original
	assert ( await list.prepare_first_screen(snap, snap.my_rank_pos, active))
	assert (receiver._collect_icon.texture == pool.get_texture())


func _test_original_rank_fx() -> void :
	var source: Control = load("res://scripts/gameplay/rank/view/source_fx/podium_sweep.tscn").instantiate()
	assert (source.find_children("*", "CPUParticles2D", true, false).size() == 7)
	var player: AnimationPlayer = source.get_node("AnimationPlayer")
	for rank: int in range(1, 4):
		assert (player.get_animation("Sweep%d" % rank).get_track_count() == 14)
	for pair: Array in [["StarAlp", "StarAdd"], ["Line_1alp", "Line_1"]]:
		var first: CPUParticles2D = source.get_node("EffectRisingParticle/" + pair[0])
		var second: CPUParticles2D = source.get_node("EffectRisingParticle/" + pair[1])
		assert (first.seed == second.seed and first.amount == second.amount)
		assert (first.material != second.material)
	assert (source.get_node("EffectFlreworks/Flreworks_1").material.particles_animation)
	assert (source.get_node("EffectFlreworks/Flreworks_1").texture.resource_path.ends_with("et_ribbon_001.png"))
	source.free()
	var row: Control = load("res://scripts/gameplay/rank/view/source_fx/rank_cell_particles.tscn").instantiate()
	assert (row.get_node("EffectStars").get_child_count() == 8)
	assert (row.get_node("EffectStars/StarsAlpT").amount == 20)
	assert (row.get_node("EffectStars/StarsAlpL").amount == 6)
	assert (row.get_node("Arrow/Arrow").amount == 4)
	assert (row.get_node("EffectGlow/Glow").texture.resource_path.ends_with("et_mask_015.png"))
	row.free()
	var collect: Control = load("res://scripts/gameplay/rank/view/source_fx/rank_change_collection.tscn").instantiate()
	var appear: AnimationPlayer = collect.get_node("CollectionAppear")
	assert (appear.get_animation("Count").get_track_count() == 48)
	assert (appear.get_animation("Count2").get_track_count() == 48)
	assert (collect.get_node("EffectBurst/StarAlp").texture.resource_path.ends_with("et_star_1.png"))
	assert (collect.get_node("EffectBurst/StarAdd").texture.resource_path.ends_with("et_star_003.png"))
	collect.free()


func _test_direct_rank_display() -> void :
	assert (SceneManager.get_page("rank") == null and SceneManager.get_page("rank_game_finish") == null)
	for step: FlowStep in LauncherFlow._build_steps():
		assert (step.get_step_name() != "WarmRankUi")
	_reset_rank_state()
	UserState.set_current_level(21)
	RankManager.invalidate_snapshot()
	RankManager.ensure_season()
	RankManager.ensure_profile()
	await SceneManager.warm_page_threaded("home")
	var home: HomePage = SceneManager.get_page("home")
	await home._components.ensure_group("rank", func() -> bool: return true)
	home.visible = true
	await _test_cold_rank_first_screen(home)
	var observed: Dictionary = {"loading": false, "collected": false, "cycles": 0, 
		"was_loading": false, "blank_rank": false, "loading_over_rank": false, 
		"reopening": false, "reopen_frames": 0, "unstable_reopen": false}
	var monitor: Callable = func() -> void :
		var loading: Node = SceneManager.get_page("loading")
		var showing: bool = loading != null and loading.visible
		if showing:
			observed.loading = true
			if not observed.was_loading:
				observed.cycles += 1
		observed.was_loading = showing
		var rank_page: RankPage = SceneManager.get_page("rank")
		if rank_page != null and rank_page.visible:
			if not rank_page._list.is_first_screen_ready():
				observed.blank_rank = true
			if showing:
				observed.loading_over_rank = true
			if observed.reopening:
				observed.reopen_frames += 1
				if not _rank_show_screen_is_stable(rank_page):
					observed.unstable_reopen = true
	get_tree().process_frame.connect(monitor)
	home.open_rank_page()
	assert (SceneManager.get_page("loading").visible)
	var first_request: RefCounted = home._rank_open_request
	assert (first_request != null)
	home.open_rank_page()
	assert (home._rank_open_request == first_request)

	SceneManager.hide_page("home")
	home.visible = true
	home.open_rank_page()
	assert (home._rank_open_request != null and home._rank_open_request != first_request)
	await _wait_until( func() -> bool:
		var rank_page: Node = SceneManager.get_page("rank")
		return rank_page != null and rank_page.visible)
	var page: RankPage = SceneManager.get_page("rank")
	assert (page._content_ready and page._list.is_first_screen_ready())
	assert ( not page.needs_first_display_preparation())
	assert (page._title_label.text == tr("RANK_LEADERBOARD_TITLE"))
	assert (SceneManager.get_page("rank_game_finish") == null)
	assert (observed.loading and observed.cycles == 1)
	assert ( not observed.blank_rank and not observed.loading_over_rank)
	assert ( not SceneManager.get_page("loading").visible)
	assert (home._rank_open_request == null)
	var pool_count: int = page._list.get_prepared_item_count()
	assert (pool_count > 0)
	var created: int = page._list.preparation_stats.created
	var bottom: float = page._list._layout.content_height - page._list._view_height()
	observed.loading = false


	for scroll: float in [0.0, bottom, bottom * 0.5]:
		page._list.set_scroll_vertical(scroll)
		await _wait_until( func() -> bool: return not page._list._refresh_pending and not page._list._stage_active)
		assert (absf(page._list.get_scroll_vertical() - scroll) <= 1.0)
		SceneManager.hide_page("rank")
		assert ( not page.visible)
		await get_tree().process_frame
		observed.reopening = true
		observed.reopen_frames = 0
		home.open_rank_page()
		assert ( not page.visible and not SceneManager.get_page("loading").visible)
		var reopen_request: RefCounted = home._rank_open_request
		assert (reopen_request != null)
		home.open_rank_page()
		assert (home._rank_open_request == reopen_request)
		await _wait_until( func() -> bool: return page.visible)
		assert (_rank_show_screen_is_stable(page))
		for frame: int in range(3):
			await get_tree().process_frame
		assert (observed.reopen_frames >= 3 and not observed.unstable_reopen)
		assert (page._list.get_prepared_item_count() == pool_count)
		assert (page._list.preparation_stats.created == created)
		observed.reopening = false
	SceneManager.hide_page("rank")

	home.open_rank_page()
	assert (home._rank_open_request != null and not page.visible)
	SceneManager.hide_page("home")
	for frame: int in range(3):
		await get_tree().process_frame
	assert ( not page.visible and home._rank_open_request == null)

	home.visible = true
	home.open_rank_page()
	var cancelled_request: RefCounted = home._rank_open_request
	SceneManager.hide_page("home")
	home.visible = true
	observed.reopening = true
	home.open_rank_page()
	assert (home._rank_open_request != null and home._rank_open_request != cancelled_request)
	await _wait_until( func() -> bool: return page.visible)
	for frame: int in range(3):
		await get_tree().process_frame
	assert (_rank_show_screen_is_stable(page) and not observed.unstable_reopen)
	assert ( not observed.blank_rank and not observed.loading and home._rank_open_request == null)
	observed.reopening = false
	SceneManager.hide_page("rank")

	SceneManager.show_page("rank", {"on_collect": func() -> void : observed.collected = true})
	page._on_collect_pressed()
	assert (observed.collected and not page.visible)
	var token: Dictionary = {"active": false}
	var ctx: Dictionary = {"owner": self, "active": func() -> bool: return token.active}
	assert ( await RankSessionFlow.show_dialog(ctx, "rank_game_finish") == null)
	assert (SceneManager.get_page("rank_game_finish") == null)

	token.active = true
	var request: Dictionary = {"done": false, "page": null}
	_show_rank_dialog_probe(ctx, request)
	var finish: RankGameFinishPage = SceneManager.get_page("rank_game_finish")
	assert (finish != null and finish.visible and not finish._content_ready)
	assert (finish._title_label.text == tr("RANK_LEADERBOARD_TITLE"))
	assert (finish._list.get_prepared_item_count() == 0)
	await get_tree().process_frame
	token.active = false
	await _wait_until( func() -> bool: return request.done)
	assert ( not finish.visible)
	assert (SceneManager.show_dlg("rank_game_finish", {"result": {"collect_delta": 0}}) == finish)
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	assert (finish.visible and finish._content_ready and finish._podium.visible)
	assert (finish._podium.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (page._badge.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (page._tier_nav.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	pool_count = finish._list.get_prepared_item_count()
	SceneManager.hide_dlg("rank_game_finish")
	assert (SceneManager.show_dlg("rank_game_finish", {"result": {"collect_delta": 0}}) == finish)
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	assert (finish._list.get_prepared_item_count() == pool_count)
	SceneManager.hide_dlg("rank_game_finish")
	get_tree().process_frame.disconnect(monitor)
	assert ( not observed.loading and not SceneManager.get_page("loading").visible)

	SceneManager.show_loading()
	SceneManager.show_page("rank")
	await _wait_until( func() -> bool: return page._list.is_first_screen_ready() and page._list.modulate.a == 1.0)
	assert (SceneManager.get_page("loading").visible)
	SceneManager.hide_page("rank")
	SceneManager.hide_loading()

	var first_lease: RefCounted = SceneManager.begin_display_loading()
	var second_lease: RefCounted = SceneManager.begin_display_loading()
	SceneManager.end_display_loading(first_lease)
	assert (SceneManager.get_page("loading").visible)
	SceneManager.end_display_loading(second_lease)
	assert ( not SceneManager.get_page("loading").visible)
	first_lease = SceneManager.begin_display_loading()
	SceneManager.show_loading()
	SceneManager.end_display_loading(first_lease)
	assert (SceneManager.get_page("loading").visible)
	SceneManager.hide_loading()

	await get_tree().process_frame


func _test_cold_rank_first_screen(home: HomePage) -> void :


	home.open_rank_page()
	await _wait_until( func() -> bool:
		var page: Node = SceneManager.get_page("rank")
		return page != null and page.visible)
	var page: RankPage = SceneManager.get_page("rank")
	var list: RankListView = page._list
	SortLogger.info("[RankVirtualTest] cold_first_screen target=%.1f actual=%.1f content_y=%.1f range=%.1f" % [
		list._target_scroll, list.get_scroll_vertical(), list._content.position.y, 
		list._scroll.get_v_scroll_bar().max_value - list._scroll.get_v_scroll_bar().page])
	assert (_rank_show_screen_is_stable(page), "Cold first open must position visible rows without scrolling")
	for frame: int in range(5):
		await get_tree().process_frame
		assert (_rank_show_screen_is_stable(page), "Cold first screen must remain at the player position")
	assert (home._rank_open_request == null and not SceneManager.get_page("loading").visible)
	await _test_rank_profile_return(home, page)
	SceneManager.hide_page("rank")
	await get_tree().process_frame


	SceneManager._page_cache.erase("rank")
	page.free()
	await get_tree().process_frame


func _test_rank_profile_return(home: HomePage, page: RankPage) -> void :
	var list: RankListView = page._list
	for changed: bool in [false, true]:
		if changed:
			SceneManager.hide_page("rank")
			UserState._rank_avatar_dialog_ever_shown = false
			home.open_rank_page()
		await _wait_until( func() -> bool:
			var dialog: Node = SceneManager.get_page("avatar_select")
			return dialog != null and dialog.visible)
		var dialog: AvatarSelectDialog = SceneManager.get_page("avatar_select")
		await _wait_until( func() -> bool: return not dialog._anim.is_playing())

		if changed:
			list.set_scroll_vertical(list._layout.content_height * 0.5)
			await _wait_until( func() -> bool:
				return not list._stage_active and not list._refresh_pending\
				and absf(list._content.position.y + list.get_scroll_vertical()) <= 1.0)
		var before: Dictionary = _rank_profile_window_state(page)
		var snapshot: RankSnapshot = list._snapshot
		var rows: Array[Dictionary] = snapshot.rows.duplicate(true)
		var bound: int = list.preparation_stats.bound
		var checked: Dictionary = {"frames": 0}
		var monitor: Callable = func() -> void :
			checked.frames += 1
			assert (_rank_profile_window_state(page) == before, 
				"Closing the avatar dialog must preserve every visible row and scroll position")
		get_tree().process_frame.connect(monitor)
		if changed:
			dialog._name_input.text = "ProfileReturn"
			dialog._on_cell_picked(1 if dialog._selected_index != 1 else 2)
			dialog._on_confirm_pressed()
		else:
			dialog._on_close_pressed()
		await _wait_until( func() -> bool: return not dialog.visible)
		for frame: int in range(5):
			await get_tree().process_frame
		get_tree().process_frame.disconnect(monitor)
		assert (checked.frames >= 5 and _rank_profile_window_state(page) == before)
		assert (list._snapshot == snapshot)
		assert (list.preparation_stats.bound == bound + (1 if changed else 0))
		SortLogger.info("[RankVirtualTest] profile_return changed=%s stable_frames=%d bound_delta=%d" % [
			changed, checked.frames, list.preparation_stats.bound - bound])
		for index: int in range(rows.size()):
			if not rows[index].is_me:
				assert (snapshot.rows[index] == rows[index], "Profile edits must not refresh bot ranks or scores")
		var me_index: int = int(list._layout.key_indices.me)
		var me: RankItemView = list.row_node_at(me_index) as RankItemView
		var row: Dictionary = snapshot.get_my_row()
		assert (row.nickname == RankManager.get_display_nickname())
		assert (row.avatar_index == RankManager.get_display_avatar_index())
		assert (me._nickname.text == row.nickname)
		assert (me._avatar.texture == list._pool.get_texture(int(row.avatar_index)))
		assert (list._bound_rows[me] == list._layout.entries[me_index])

		if changed:
			var player_scroll: float = list._layout.scroll_for_rank(snapshot.my_rank_pos, list._view_height(), true)
			for scroll: float in [0.0, player_scroll]:
				list.set_scroll_vertical(scroll)
				await _wait_until( func() -> bool: return not list._stage_active and not list._refresh_pending)
			assert (me.is_visible_in_tree() and me._nickname.text == row.nickname\
			and me._avatar.texture == list._pool.get_texture(int(row.avatar_index)))

	SceneManager.hide_page("rank")
	UserState._rank_avatar_dialog_ever_shown = false
	home.open_rank_page()
	await _wait_until( func() -> bool: return SceneManager.get_page("avatar_select").visible)
	var dialog: AvatarSelectDialog = SceneManager.get_page("avatar_select")
	dialog._name_input.text = "CancelledReturn"
	dialog._on_confirm_pressed()
	SceneManager.hide_page("rank")
	home.open_rank_page()
	await _wait_until( func() -> bool: return page.visible and not dialog.visible)
	assert (_rank_show_screen_is_stable(page))
	var before: Dictionary = _rank_profile_window_state(page)
	var bound: int = list.preparation_stats.bound
	for frame: int in range(5):
		await get_tree().process_frame
		assert (_rank_profile_window_state(page) == before and list.preparation_stats.bound == bound, 
			"Cancelled profile return must not refresh the reopened page")
	assert (list._snapshot.get_my_row().nickname == "CancelledReturn")
	SortLogger.info("[RankVirtualTest] profile_return cancellation/reopen stable")


func _rank_profile_window_state(page: RankPage) -> Dictionary:
	var list: RankListView = page._list
	var visibility: Array[bool] = []
	var positions: Array[Vector2] = []
	var process_modes: Array[int] = []
	for row: Control in list._row_nodes:
		visibility.append(row != null and row.is_visible_in_tree())
		positions.append(row.position if row != null else Vector2.ZERO)
		process_modes.append(row.process_mode if row != null else -1)
	return {"ready": list.is_first_screen_ready(), "alpha": list.modulate.a, 
		"scroll": list.get_scroll_vertical(), "target": list._target_scroll, 
		"content_position": list._content.position, "window": list._window.duplicate(), 
		"nodes": list._row_nodes.duplicate(), "visibility": visibility, 
		"positions": positions, "process_modes": process_modes, 
		"generation": list._preparation_generation, "created": list.preparation_stats.created, 
		"nav": page._tier_nav.visible, "badge": page._badge.visible, "tier": page._tier_label.text}


func _rank_show_screen_is_stable(page: RankPage) -> bool:
	var list: RankListView = page._list
	if not list.is_first_screen_ready() or not is_equal_approx(list.modulate.a, 1.0):
		return false
	var expected_scroll: float = list._layout.scroll_for_rank(list._snapshot.my_rank_pos, list._view_height(), true)
	if absf(list.get_scroll_vertical() - expected_scroll) > 1.0:
		return false
	if absf(list._content.position.y + expected_scroll) > 1.0:
		return false
	var window: Vector2i = list._layout.range_for_scroll(expected_scroll, list._view_height())
	for index: int in range(window.x, window.y + 1):
		var row: Control = list.row_node_at(index)
		if row == null or not row.is_visible_in_tree():
			return false
	if not page._tier_label.visible or page._tier_label.text != page.TIER_NAME_KEY_FMT % page._player_tier:
		return false
	return page._tier_nav.is_active() and page._tier_nav.visible and not page._badge.visible\
	and page._tier_nav.get_browse_tier() == page._player_tier


func _show_rank_dialog_probe(ctx: Dictionary, outcome: Dictionary) -> void :
	outcome.page = await RankSessionFlow.show_dialog(ctx, "rank_game_finish", {"result": {"collect_delta": 0}})
	outcome.done = true


func _prepare_test_list(list: RankListView) -> bool:
	if list._snapshot == null:
		return false
	if not await list.prepare_first_screen(list._snapshot, list._snapshot.my_rank_pos, func() -> bool: return true):
		return false
	return await list.prepare_animation( func() -> bool: return true)


func _test_finish_motion() -> void :
	for old_rank: int in [4, 8, 50]:
		for new_rank: int in [1, 2, 3]:
			var cues: Dictionary = FinishMotion.build(old_rank, new_rank)
			assert (FinishMotion.overtaken_count(cues, 0.0) == 0)
			assert (FinishMotion.overtaken_count(cues, cues.fly_at) == old_rank - 4)
			assert (FinishMotion.overtaken_count(cues, cues.winner_at) == old_rank - new_rank)
	var motion: FinishMotion = FinishMotion.new()
	var enter: Dictionary = FinishMotion.build(4, 3)
	assert (is_zero_approx(float(enter.rise_sec)))
	assert (is_equal_approx(float(enter.fly_sec), 0.702))
	assert (is_equal_approx(float(enter.occupant_at) - float(enter.fly_at), 0.0555))
	assert (is_equal_approx(float(enter.sweep_at) - float(enter.winner_at), 0.1))
	assert (is_equal_approx(float(enter.commit_at) - float(enter.winner_at), 0.5))
	assert (is_equal_approx(float(enter.duration) - float(enter.winner_at), 0.667))
	assert (motion.sample(enter, FinishMotion.UP_SEC).row_scale.is_equal_approx(Vector2.ONE * 1.05))
	var rest_y: float = 25.38
	assert (FinishMotion.winner(0.0, rest_y).is_equal_approx(Vector2(rest_y - 300.0, 0.9)))
	var previous_y: float = rest_y - 300.0
	for step: int in range(1, 51):
		var current_y: float = FinishMotion.winner(step * 0.01, rest_y).x
		assert (current_y >= previous_y)
		previous_y = current_y
	assert (FinishMotion.winner(0.4, rest_y).is_equal_approx(Vector2(rest_y - 50.0, 1.2)))
	assert (FinishMotion.winner(0.5, rest_y).is_equal_approx(Vector2(rest_y, 0.95)))
	assert (FinishMotion.winner(0.667, rest_y).is_equal_approx(Vector2(rest_y, 1.05)))
	enter = FinishMotion.build(8, 1)
	assert (is_equal_approx(float(enter.rise_sec), 0.6))
	assert (is_equal_approx(float(enter.fly_sec), 0.702))
	for ranks: Vector2i in [Vector2i(3, 2), Vector2i(3, 1), Vector2i(2, 1)]:
		var swap: Dictionary = FinishMotion.build(ranks.x, ranks.y)
		assert (is_equal_approx(float(swap.fly_at) - float(swap.lift_at), 0.3))
		assert (float(swap.sweep_at) > float(swap.fly_at) and float(swap.sweep_at) < float(swap.mid_at))
		assert (is_equal_approx(float(swap.commit_at), float(swap.mid_at)))
		var above: Dictionary = motion.sample(swap, float(swap.mid_at))
		assert (above.flyer_progress == Vector2.ONE and is_equal_approx(float(above.flyer_above), 85.0))
		assert (is_equal_approx(float(above.flyer_scale), 1.2))
		var landed: Dictionary = motion.sample(swap, float(swap.land_at))
		assert (is_zero_approx(float(landed.flyer_above)) and is_equal_approx(float(landed.flyer_scale), 0.9))
		assert (is_equal_approx(float(motion.sample(swap, float(swap.duration)).flyer_scale), 1.0))
	for rank: int in range(1, 4):
		var path: String = "Rank%d/Podium/PodiumMask/Glow:" % rank
		assert (is_equal_approx(float(motion.curve("podium_Sweep%d" % rank, path + "position:y", 0.416667, 0.0)), 50.0))
		var color: Color = motion.curve("podium_Sweep%d" % rank, path + "modulate", 0.750001, Color.WHITE)
		assert (is_zero_approx(color.a))


func _test_collect_effect_transform() -> void :
	var row: RankItemView = load("res://scripts/gameplay/rank/view/rank_finish_item_view.tscn").instantiate()
	var fly: = RankCollectFlyLayer.new()
	add_child(row)
	add_child(fly)
	row.position = Vector2(50, 100)
	row.pivot_offset = row.size * 0.5
	fly._try_arrive_fx(row.get_collect_target_global_pos, row)
	var shine: Sprite2D = row.get_node("BurstShine")
	var stars: CPUParticles2D = row.get_node("BurstStars")
	var before: Vector2 = shine.global_transform.get_scale()
	assert (shine.global_position.is_equal_approx(row.get_collect_target_global_pos()))
	assert (shine.z_index < row.get_node("CollectIcon").z_index)
	assert (stars.local_coords)
	row.scale = Vector2(1.12, 1.12)
	assert (shine.global_transform.get_scale().is_equal_approx(before * 1.12))
	assert (shine.global_position.is_equal_approx(row.get_collect_target_global_pos()))
	row.scale = Vector2.ONE
	assert (shine.global_transform.get_scale().is_equal_approx(before))
	fly.cancel_all()
	assert ( not shine.visible and not stars.visible and fly._effects.is_empty())
	await get_tree().process_frame
	assert ( not is_instance_valid(shine) and not is_instance_valid(stars))
	row.queue_free()
	fly.queue_free()


func _test_rules() -> void :
	_test_rank_zone_snapshots()
	_test_bot_collect_rules()
	_test_bot_activity_upgrade()
	_test_bot_growth_clock()
	_test_bot_player_climb()
	_test_bot_distribution()
	var zones: Dictionary = RankSettleLogic.compute_zone_thresholds(50)
	assert (zones.upgrade_end_rank == 15 and zones.downgrade_start_rank == 41)
	assert (RankSettleLogic.compute_tier_after(15, 3, 15, 41) == 4)
	assert (RankSettleLogic.compute_tier_after(16, 3, 15, 41) == 3)
	assert (RankSettleLogic.compute_tier_after(40, 3, 15, 41) == 3)
	assert (RankSettleLogic.compute_tier_after(41, 3, 15, 41) == 2)
	assert (RankSettleLogic.compute_tier_after(1, 7, 15, 41) == 7)
	assert (RankSettleLogic.compute_tier_after(50, 1, 15, 41) == 1)
	for tier: int in range(1, 8):
		var first: Array = RankFakeUserGenerator.generate_bots("local_20261030", tier, 49)
		var second: Array = RankFakeUserGenerator.generate_bots("local_20261030", tier, 49)
		assert (first == second and first.size() == 49)
		var zero_count: int = 0
		for bot: Dictionary in first:
			assert (bot.base_collect >= 0 and bot.base_collect <= 12 + 6 * 16)
			assert ( not bot.has("random_initial_collect"))
			assert (RankFakeUserGenerator.get_collect_count_at(bot, 0) == bot.base_collect)
			zero_count += 1 if bot.base_collect == 0 else 0
			assert (RankFakeUserGenerator.VISIBLE_AVATARS.has(int(bot.avatar_index)))
			for elapsed: int in [0, 1, 3600, 172800]:
				var count: int = RankFakeUserGenerator.get_collect_count_at(bot, elapsed)
				assert (count == 0 or count >= 9)
		assert (zero_count <= RankFakeUserGenerator.MAX_ZERO_COLLECT_BOTS)
		for rank: int in range(1, 51):
			var reward: Dictionary = RankSettleLogic.get_reward(rank, tier)
			assert (reward.hint == ({1: 5, 2: 3, 3: 2}).get(rank, 0))
			assert ((reward.coin > 0) == (rank <= 3))
	var tie_bot: Dictionary = RankFakeUserGenerator.generate_bots("tie", 1, 1)[0]
	var tied_score: int = RankFakeUserGenerator.get_collect_count_at(tie_bot, 1000)
	var tied: Array = RankSettleLogic.build_ranked_rows(tied_score, "Me", 1, [tie_bot], 1000)
	assert ( not tied[0].is_me and tied[1].is_me)
	var boundary: Dictionary = RankSnapshotBuilder.create_entity("boundary", 1000, 2000, 3, 49)
	assert ( not RankSnapshotBuilder.build(boundary, 1999, "Me", 1).is_ended)
	assert (RankSnapshotBuilder.build(boundary, 2000, "Me", 1).is_ended)
	var frozen: RankSnapshot = RankSnapshotBuilder.build(boundary, 2000, "Me", 1)
	assert (frozen.rows == RankSnapshotBuilder.build(boundary, 999999, "Me", 1).rows)


func _test_bot_collect_rules() -> void :
	_test_bot_collect_level_sequence()
	_test_bot_independent_collect_starts()
	var regular: Dictionary = {"kind": "regular", "slope": 1.0, "base_collect": 0, "bonus": 0, "bonus_budget": 0, "collect_seed": 0, "collect_rules_version": RankFakeUserGenerator.COLLECT_RULES_VERSION}
	for pair: Array in [[0, 0], [10, 0], [11, 0], [12, 12], [24, 12], [25, 25], [36, 25], [37, 37], [51, 51]]:
		assert (RankFakeUserGenerator.get_collect_count_at(regular, pair[0] * 3600) == pair[1])
	var started: Dictionary = regular.duplicate()
	started["base_collect"] = 12
	assert (RankFakeUserGenerator.get_collect_progress_at(started, 0).next_level_id == 22)
	assert (RankFakeUserGenerator.get_collect_count_at(started, 12 * 3600) == 12)
	assert (RankFakeUserGenerator.get_collect_count_at(started, 13 * 3600) == 25)

	assert (RankFakeUserGenerator.get_collect_count_at(regular, 25 * 3600) == 25)
	var targets: PackedInt32Array = RankFakeUserGenerator.COLLECT_TARGET_COUNTS
	var official_total: int = 0
	for target: int in RankFakeUserGenerator.LEVEL_TARGET_COUNTS:
		official_total += target
	for seed_value in 4:
		var previous: int = 0
		var completed_levels: int = 0
		for budget in range(1, official_total + RankFakeUserGenerator.COLLECT_BLOCK_TOTAL * 2 + 1):
			var progress: Dictionary = RankFakeUserGenerator.get_collect_progress(float(budget), seed_value)
			var completed: int = int(progress.collect_num)
			assert (completed >= previous and completed <= budget)
			assert (progress.remaining_budget >= 0 and progress.remaining_budget < progress.next_target)
			assert (progress.next_level_id == 21 + progress.completed_levels)
			if completed > previous:
				var delta: int = completed - previous
				if completed_levels < RankFakeUserGenerator.LEVEL_TARGET_COUNTS.size():
					assert (delta == RankFakeUserGenerator.LEVEL_TARGET_COUNTS[completed_levels])
				else:
					assert (targets.has(delta))
				completed_levels += 1
			assert (completed_levels == progress.completed_levels)
			previous = completed

	var bonus: Dictionary = RankFakeUserGenerator.resolve_collect_bonus(regular, 0, 10)
	assert (bonus.bonus == 0 and bonus.budget_delta == 10)
	var chased: Dictionary = regular.duplicate()
	chased["bonus_budget"] = 10
	assert (RankFakeUserGenerator.get_collect_count_at(chased, 0) == 0)
	bonus = RankFakeUserGenerator.resolve_collect_bonus(chased, 0, 2)
	assert (bonus.bonus == 12 and bonus.budget_delta == 2)
	chased["bonus_budget"] += bonus.budget_delta
	chased["bonus"] = bonus.bonus
	assert (RankFakeUserGenerator.get_collect_progress_at(chased, 0).next_level_id == 22)
	assert (RankFakeUserGenerator.get_collect_count_at(chased, 12 * 3600) == 12)
	assert (RankFakeUserGenerator.get_collect_count_at(chased, 13 * 3600) == 25)
	bonus = RankFakeUserGenerator.resolve_collect_bonus(regular, 24 * 3600, 1)
	assert (bonus.bonus == 13 and bonus.budget_delta == 1)
	for hour: int in [0, 11, 12, 24, 25, 36, 37, 50, 100, 1200]:
		for rolled in range(0, 101):
			bonus = RankFakeUserGenerator.resolve_collect_bonus(regular, hour * 3600, rolled)
			if rolled == 0:
				assert (bonus.is_empty())
				continue
			var before: Dictionary = RankFakeUserGenerator.get_collect_progress_at(regular, hour * 3600)
			var updated: Dictionary = regular.duplicate()
			updated["bonus_budget"] = bonus.budget_delta
			updated["bonus"] = bonus.bonus
			var after: Dictionary = RankFakeUserGenerator.get_collect_progress_at(updated, hour * 3600)
			assert (bonus.bonus >= 0 and bonus.budget_delta == rolled)
			assert (after.collect_budget == before.collect_budget + rolled)
			assert (after.collect_num - before.collect_num == bonus.bonus)
			assert (after.remaining_budget >= 0 and after.remaining_budget < after.next_target)
	_test_bot_catch_up(regular)

	var bots: Array[Dictionary] = RankFakeUserGenerator.generate_bots("collect-budget", 7, 49)
	var began: int = Time.get_ticks_usec()
	for bot: Dictionary in bots:
		RankFakeUserGenerator.get_collect_count_at(bot, 1000000000)
	SortLogger.info("[RankCollectTest] 49 bots long-offline calculation: %d us" % (Time.get_ticks_usec() - began))


func _test_bot_catch_up(regular: Dictionary) -> void :
	var sizes: Dictionary = {}
	var targets: Dictionary = {}
	var one_target_count: int = 0
	var all_target_count: int = 0
	var early: bool = false
	var deferred: bool = false
	var first_empty: bool = false
	for seed_value in 100:
		var bots: Array = []
		for count: int in [0, 12, 25, 37, 51, 61]:
			var bot: Dictionary = regular.duplicate()
			bot["base_collect"] = count

			bot["last_boost_round"] = 7
			bots.append(bot)
		var rows: Array = RankSettleLogic.build_ranked_rows(37, "Me", 1, bots, 0)
		assert (RankSettleLogic.find_my_rank_pos(rows) == 4)
		var rng: = RandomNumberGenerator.new()
		rng.seed = seed_value
		var first: Dictionary = RankCatchUpRule.resolve(rows, 50, 1, rng, bots, 0, 7)
		var wave: Dictionary = first.wave
		assert (wave.start_round == 7 and wave.members.size() >= 2 and wave.members.size() <= 3)
		sizes[wave.members.size()] = true
		first_empty = first_empty or first.picks.is_empty()
		var selected: Dictionary = {}
		for member: Dictionary in wave.members:
			assert (member.bot_index in [0, 1, 2] and not selected.has(member.bot_index))
			assert (member.target_levels >= 1 and member.target_levels <= 2)
			assert (member.first_levels >= 0 and member.first_levels <= 1)
			targets[member.target_levels] = true
			one_target_count += 1 if member.target_levels == 1 else 0
			all_target_count += 1
			early = early or int(member.first_levels) > 0
			deferred = deferred or int(member.first_levels) < int(member.target_levels)
			selected[member.bot_index] = true
		rng.seed = seed_value
		assert (first == RankCatchUpRule.resolve(rows, 50, 1, rng, bots, 0, 7))
		_apply_catch_up_test_picks(bots, first.picks, 0)
		for member: Dictionary in wave.members:
			var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bots[member.bot_index], 0)
			assert (progress.completed_levels - member.start_completed_levels == member.first_levels)
		var original_wave: Dictionary = wave.duplicate(true)

		var outside_rows: Array = RankSettleLogic.build_ranked_rows(0, "Me", 1, bots, 0)
		var second: Dictionary = RankCatchUpRule.resolve(outside_rows, 6, 12, rng, bots, 0, 8, wave)
		assert (second.wave.is_empty() and wave == original_wave)
		_apply_catch_up_test_picks(bots, second.picks, 0)
		for member: Dictionary in wave.members:
			var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bots[member.bot_index], 0)
			assert (progress.completed_levels - member.start_completed_levels == member.target_levels)
			assert (progress.completed_levels - member.start_completed_levels >= 1)
			assert (progress.completed_levels - member.start_completed_levels <= 2)
		var none: Dictionary = RankCatchUpRule.resolve(outside_rows, 6, 12, rng, bots, 0, 9)
		assert (none.wave.is_empty() and none.picks.is_empty())
		var invalid: Dictionary = RankCatchUpRule.resolve(rows, 4, 0, rng, bots, 0, 8, wave)
		assert (invalid.wave == wave and invalid.picks.is_empty())
		var next: Dictionary = RankCatchUpRule.resolve(rows, 4, 1, rng, bots, 0, 9)
		assert (next.wave.start_round == 9 and next.wave.members.size() >= 2)
	assert (sizes.size() == 2 and targets.size() == 2 and early and deferred and first_empty)
	var one_ratio: float = float(one_target_count) / all_target_count
	assert (one_ratio >= 0.65 and one_ratio <= 0.85, "1关追赶应占多数，仍保留2关的竞争压力")
	var ahead_bots: Array = [regular.duplicate(), regular.duplicate()]
	ahead_bots[0]["base_collect"] = 12
	ahead_bots[1]["base_collect"] = 25
	var ahead_rows: Array = RankSettleLogic.build_ranked_rows(12, "Me", 1, ahead_bots, 0)
	var no_chaser: Dictionary = RankCatchUpRule.resolve(ahead_rows, 5, 12, RandomNumberGenerator.new(), ahead_bots, 0, 1)
	assert (no_chaser.wave.is_empty() and no_chaser.picks.is_empty(), "没有身后候选时不能改为加速领先者")
	var crossing_bots: Array = [regular.duplicate(), regular.duplicate(), regular.duplicate()]
	for i in crossing_bots.size():
		crossing_bots[i]["base_collect"] = [12, 25, 37][i]
	var crossing_rows: Array = RankSettleLogic.build_ranked_rows(51, "Me", 1, crossing_bots, 0)
	var crossing: Dictionary = RankCatchUpRule.resolve(crossing_rows, 4, 14, RandomNumberGenerator.new(), crossing_bots, 0, 1)
	assert (crossing.wave.members.size() == 2)
	for member: Dictionary in crossing.wave.members:
		assert (member.bot_index in [0, 1], "刚超过的同分对手留到后续轮次追赶")
	_test_bot_catch_up_natural_growth(regular)
	_test_bot_catch_up_cross_wave(regular)
	_test_bot_catch_up_wave_upgrade(regular)
	SortLogger.info("[RankCollectTest] 100 catch-up waves: 2/3 nearby bots, 1-2 real levels by second win, early/deferred growth and stable identities")


func _apply_catch_up_test_picks(bots: Array, picks: Array, elapsed_seconds: int) -> void :
	var seen: Dictionary = {}
	for pick: Dictionary in picks:
		assert ( not seen.has(pick.bot_index))
		seen[pick.bot_index] = true
		var bot: Dictionary = bots[pick.bot_index]
		var before: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, elapsed_seconds)
		bot["bonus_budget"] = int(bot.get("bonus_budget", 0)) + int(pick.budget_delta)
		bot["bonus"] = int(bot.get("bonus", 0)) + int(pick.bonus)
		var after: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, elapsed_seconds)
		assert (after.collect_num - before.collect_num == pick.bonus)
		assert (after.completed_levels - before.completed_levels == pick.completed_levels)
		assert (pick.completed_levels >= 1 and pick.completed_levels <= 2)
		assert (pick.budget_delta > 0 and after.remaining_budget == 0)


func _test_bot_catch_up_natural_growth(regular: Dictionary) -> void :
	var bots: Array = [regular.duplicate(), regular.duplicate()]
	bots[0]["base_collect"] = 12
	bots[1]["base_collect"] = 25
	var wave: Dictionary = {"rules_version": RankCatchUpRule.RULES_VERSION, "start_round": 5, "members": [
		{"bot_index": 0, "start_completed_levels": 1, "target_levels": 1, "first_levels": 0}, 
		{"bot_index": 1, "start_completed_levels": 2, "target_levels": 2, "first_levels": 0}, 
	]}
	var rows: Array = RankSettleLogic.build_ranked_rows(37, "Me", 1, bots, 13 * 3600)
	var result: Dictionary = RankCatchUpRule.resolve(rows, 4, 12, RandomNumberGenerator.new(), bots, 13 * 3600, 6, wave)
	assert (result.wave.is_empty() and result.picks.size() == 1)
	assert (result.picks[0].bot_index == 1 and result.picks[0].completed_levels == 1)
	_apply_catch_up_test_picks(bots, result.picks, 13 * 3600)
	assert (RankFakeUserGenerator.get_collect_progress_at(bots[0], 13 * 3600).completed_levels == 2)
	assert (RankFakeUserGenerator.get_collect_progress_at(bots[1], 13 * 3600).completed_levels == 4)
	result = RankCatchUpRule.resolve(rows, 4, 12, RandomNumberGenerator.new(), bots, 100 * 3600, 6, wave)
	assert (result.wave.is_empty() and result.picks.is_empty())

	var bonus: Dictionary = RankFakeUserGenerator.resolve_collect_level_bonus(regular, 24 * 3600, 1)
	assert (bonus.bonus == 13 and bonus.budget_delta == 1 and bonus.completed_levels == 1)
	assert (RankFakeUserGenerator.resolve_collect_level_bonus(regular, 0, 0).is_empty())

	var official_total: int = 0
	for target: int in RankFakeUserGenerator.LEVEL_TARGET_COUNTS:
		official_total += target
	var crossing: Dictionary = regular.duplicate()
	crossing["base_collect"] = official_total - 1
	var before: Dictionary = RankFakeUserGenerator.get_collect_progress_at(crossing, 0)
	bonus = RankFakeUserGenerator.resolve_collect_level_bonus(crossing, 0, 4)
	bonus["bot_index"] = 0
	_apply_catch_up_test_picks([crossing], [bonus], 0)
	assert (RankFakeUserGenerator.get_collect_progress_at(crossing, 0).completed_levels == before.completed_levels + 2)


func _test_bot_catch_up_cross_wave(regular: Dictionary) -> void :
	var deferred: bool = false
	for seed_value in 30:
		var bots: Array = [regular.duplicate(), regular.duplicate()]
		bots[0]["base_collect"] = 12
		bots[0]["last_catch_up_growth_round"] = 7
		bots[1]["base_collect"] = 25
		bots[1]["last_catch_up_growth_round"] = 8
		var rows: Array = RankSettleLogic.build_ranked_rows(37, "Me", 1, bots, 0)
		var rng: = RandomNumberGenerator.new()
		rng.seed = seed_value
		var first: Dictionary = RankCatchUpRule.resolve(rows, 1, 1, rng, bots, 0, 9)
		for member: Dictionary in first.wave.members:
			if member.bot_index == 0:
				assert (member.first_levels >= 1, "跨轮不能连续两次结算不增长")
			else:
				deferred = deferred or member.first_levels == 0
		assert (first.growth_rounds.get(0) == 9)
		_apply_catch_up_test_picks(bots, first.picks, 0)
		for bot_index: int in first.growth_rounds:
			bots[bot_index]["last_catch_up_growth_round"] = first.growth_rounds[bot_index]
		var second: Dictionary = RankCatchUpRule.resolve(rows, 1, 12, rng, bots, 0, 10, first.wave)
		_apply_catch_up_test_picks(bots, second.picks, 0)
		for bot_index: int in second.growth_rounds:
			bots[bot_index]["last_catch_up_growth_round"] = second.growth_rounds[bot_index]
		var next: Dictionary = RankCatchUpRule.resolve(rows, 1, 1, rng, bots, 0, 11)
		for member: Dictionary in next.wave.members:
			if bots[member.bot_index].last_catch_up_growth_round == 9:
				assert (member.first_levels >= 1)
	assert (deferred)


func _test_bot_catch_up_wave_upgrade(regular: Dictionary) -> void :
	var bots: Array = [regular.duplicate(), regular.duplicate()]
	bots[0]["base_collect"] = 12
	bots[1]["base_collect"] = 51
	var wave: Dictionary = {"rules_version": 1, "start_round": 7, "members": [
		{"bot_index": 0, "start_completed_levels": 1, "target_levels": 4, "first_levels": 0, "observed_completed_levels": 1}, 
		{"bot_index": 1, "start_completed_levels": 1, "target_levels": 4, "first_levels": 3, "observed_completed_levels": 4}, 
	]}
	var original: Dictionary = wave.duplicate(true)
	var rows: Array = RankSettleLogic.build_ranked_rows(0, "Me", 1, bots, 0)
	var rng: = RandomNumberGenerator.new()
	var first: Dictionary = RankCatchUpRule.resolve(rows, 6, 12, rng, bots, 0, 7, wave)
	assert (first.wave.rules_version == RankCatchUpRule.RULES_VERSION and first.wave.start_round == 7)
	assert (first.wave.members.size() == 2 and first.picks.is_empty())
	for i in wave.members.size():
		assert (first.wave.members[i].bot_index == wave.members[i].bot_index)
		assert (first.wave.members[i].start_completed_levels == wave.members[i].start_completed_levels)
		assert (first.wave.members[i].target_levels == 2)
		assert (first.wave.members[i].observed_completed_levels == wave.members[i].observed_completed_levels)
	var second: Dictionary = RankCatchUpRule.resolve(rows, 6, 12, rng, bots, 0, 8, first.wave)
	assert (second.wave.is_empty() and second.picks.size() == 1)
	assert (second.picks[0].bot_index == 0 and second.picks[0].completed_levels == 2)
	_apply_catch_up_test_picks(bots, second.picks, 0)
	assert (RankFakeUserGenerator.get_collect_progress_at(bots[1], 0).completed_levels == 4)
	assert (wave == original)
	var invalid: Dictionary = RankCatchUpRule.resolve(rows, 6, 0, rng, bots, 0, 8, wave)
	assert (invalid.wave == original and invalid.picks.is_empty())
	SortLogger.info("[RankCollectTest] old catch-up wave: capped at 2, stable identities/deadline, fulfilled growth retained")


func _old_activity_bots(event_id: String, tier: int) -> Array:
	var bots: Array = RankFakeUserGenerator.generate_bots(event_id, tier, 49)
	for bot: Dictionary in bots:
		bot["activity_rules_version"] = 1
		if bool(bot.is_contender):
			bot["fast_mult"] = 3.5
			bot["slow_mult"] = 1.05
	return bots


func _test_bot_activity_upgrade() -> void :
	for tier in range(1, 8):
		for elapsed: int in [7200, 43199, 43200, 60000]:
			var bots: Array = _old_activity_bots("activity-upgrade", tier)
			var original: Array = bots.duplicate(true)
			assert (RankFakeUserGenerator.prepare_activity_rules(bots, "activity-upgrade", tier, elapsed))
			assert ( not RankFakeUserGenerator.prepare_activity_rules(bots, "activity-upgrade", tier, elapsed))
			for i in bots.size():
				var bot: Dictionary = bots[i]
				for key: String in ["base_collect", "initial_collect_budget", "bonus", "bonus_budget", "nickname", "avatar_index", "is_contender", "activity_slope_micros", "activity_phase_seconds", "activity_prefix"]:
					assert (bot[key] == original[i][key], "减速升级不能改动身份、进度或活跃周期：%s" % key)
				var before: Dictionary = RankFakeUserGenerator.get_collect_progress_at(original[i], elapsed)
				var after: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, elapsed)
				assert (before.collect_budget == after.collect_budget and before.collect_num == after.collect_num)
				for offset: int in [1, 3600, 43200]:
					var future: int = RankFakeUserGenerator.get_collect_count_at(bot, elapsed + offset)
					assert (future >= int(before.collect_num))
					assert (future <= RankFakeUserGenerator.get_collect_count_at(original[i], elapsed + offset))
				if bool(bot.is_contender):
					assert (bot.fast_mult == 2.5 and bot.slow_mult == 1.0)
				else:
					assert (bot.activity_origin_seconds == original[i].activity_origin_seconds)
	SortLogger.info("[RankCollectTest] activity v1 -> v2: unchanged scores/budgets/identities, reduced future growth across all 7 tiers")


func _test_bot_growth_clock() -> void :
	var start_ms: int = 1700000000000
	var entity: Dictionary = RankSnapshotBuilder.create_entity("growth-clock", start_ms, start_ms + 172800000, 7, 49)
	var initial: RankSnapshot = RankSnapshotBuilder.build(entity, start_ms, "Me", 1)
	for hour: int in [0, 12, 24, 36]:
		var join_ms: int = start_ms + hour * 3600000
		assert (RankSnapshotBuilder.bot_elapsed_seconds(entity, join_ms) == 0)
		assert (RankSnapshotBuilder.build(entity, join_ms, "Me", 1).rows == initial.rows)
		var joined: Dictionary = entity.duplicate(true)
		joined["bot_start_time"] = join_ms
		assert (RankSnapshotBuilder.build(joined, join_ms, "Me", 1).rows == initial.rows)
		assert (RankSnapshotBuilder.bot_elapsed_seconds(joined, join_ms + 3600000) == 3600)
		var later: RankSnapshot = RankSnapshotBuilder.build(joined, join_ms + 3600000, "Me", 1)
		for row: Dictionary in later.rows:
			if not bool(row.is_me):
				assert (row.collect_num == RankFakeUserGenerator.get_collect_count_at(joined.bots[row.bot_index], 3600))
		assert (RankSnapshotBuilder.build(joined, int(joined.end_time), "Me", 1).rows
			== RankSnapshotBuilder.build(joined, int(joined.end_time) + 86400000, "Me", 1).rows)
	var legacy: Dictionary = entity.duplicate(true)
	legacy.erase("bot_start_time")
	assert (RankSnapshotBuilder.bot_elapsed_seconds(legacy, start_ms + 43200000) == 43200)
	assert (RankSnapshotBuilder.bot_elapsed_seconds(legacy, start_ms + 259200000) == 172800)
	SortLogger.info("[RankCollectTest] bot clock: idle and late participation start at 0; old seasons retain midnight clock; expiry freezes")


func _test_bot_player_climb() -> void :
	var overtakes: int = 0
	for low_score: bool in [false, true]:
		for seconds_per_win: int in [180, 300]:
			for tier in range(1, 8):
				var lowest: Array[int] = [99, 99, 99, 99]
				var highest: Array[int] = [0, 0, 0, 0]
				for season in 12:
					var start_ms: int = 1700000000000
					var join_ms: int = start_ms + [0, 12, 24, 36][season % 4] * 3600000
					var event_id: String = "player-climb-%d" % season
					var entity: Dictionary = RankSnapshotBuilder.create_entity(event_id, start_ms, start_ms + 172800000, tier, 49)
					var reached: Array[int] = [0, 0, 0, 0]
					var previous_rank: int = 50
					for win in range(1, 21):
						var now_ms: int = join_ms + (win - 1) * seconds_per_win * 1000
						var before: RankSnapshot = RankSnapshotBuilder.build(entity, now_ms, "Me", 1)
						if win == 1:
							entity["bot_start_time"] = now_ms
						var delta: int = 10 if low_score else RankFakeUserGenerator.LEVEL_TARGET_COUNTS[win - 1]
						entity["collect_num"] = int(entity.collect_num) + delta
						entity["scored_round_count"] = win
						var added: RankSnapshot = RankSnapshotBuilder.build(entity, now_ms, "Me", 1)
						var elapsed: int = RankSnapshotBuilder.bot_elapsed_seconds(entity, now_ms)
						var rng: = RandomNumberGenerator.new()
						rng.seed = (event_id + str(win)).hash()
						var result: Dictionary = RankCatchUpRule.resolve(added.rows, before.my_rank_pos, delta, rng, entity.bots, elapsed, win, entity.get("catch_up_wave", {}))
						entity["catch_up_wave"] = result.wave
						_apply_catch_up_test_picks(entity.bots, result.picks, elapsed)
						for bot_index: int in result.growth_rounds:
							entity.bots[bot_index]["last_catch_up_growth_round"] = result.growth_rounds[bot_index]
						var after: RankSnapshot = RankSnapshotBuilder.build(entity, now_ms, "Me", 1)
						for milestone in 4:
							if after.my_rank_pos <= [40, 15, 5, 3][milestone] and reached[milestone] == 0:
								reached[milestone] = win
						overtakes += 1 if previous_rank <= 5 and after.my_rank_pos > previous_rank else 0
						previous_rank = after.my_rank_pos
					for milestone in 4:
						assert (reached[milestone] > 0, "持续通关必须可以达成四个排名节点")
						lowest[milestone] = mini(lowest[milestone], reached[milestone])
						highest[milestone] = maxi(highest[milestone], reached[milestone])
				SortLogger.info("[RankCollectTest] milestones low10=%s sec/win=%d tier=%d min=%s max=%s" % [str(low_score), seconds_per_win, tier, str(lowest), str(highest)])
				assert (highest[0] <= 4 and highest[1] <= 8 and highest[2] <= 10 and highest[3] <= 12, "3/6/8/10关节奏不能持续拖后")
	assert (overtakes > 0, "入榜后必须仍有相近对手追赶换位")
	SortLogger.info("[RankCollectTest] player climb: 336 sessions, four stages and %d top-five overtakes" % overtakes)


func _test_bot_distribution() -> void :
	var contender_counts: Dictionary = {}
	var switches: int = 0
	var max_contender_spread: int = 0
	for tier in range(1, 8):
		var ties_total: PackedInt32Array = [0, 0, 0, 0, 0, 0]
		var unique_total: PackedInt32Array = [0, 0, 0, 0, 0, 0]
		var top_five_spread_total: PackedInt32Array = [0, 0, 0, 0, 0, 0]
		var sample_hours: PackedInt32Array = [0, 1, 6, 12, 24, 48]
		for season in 12:
			var event_id: String = "distribution-%d" % season
			var bots: Array = RankFakeUserGenerator.generate_bots(event_id, tier, 49)
			assert (bots == RankFakeUserGenerator.generate_bots(event_id, tier, 49))
			var contenders: int = 0
			var initial: Dictionary = {}
			var initial_levels: PackedInt32Array = [0, 0, 0, 0, 0, 0, 0, 0]
			for bot: Dictionary in bots:
				contenders += 1 if bot.is_contender else 0
				var count: int = RankFakeUserGenerator.get_collect_count_at(bot, 0)
				initial[count] = int(initial.get(count, 0)) + 1
				var progress: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, 0)
				assert (count == bot.base_collect and progress.completed_levels <= 7)
				initial_levels[int(progress.completed_levels)] += 1
				assert (progress.remaining_budget == bot.initial_collect_budget)
				assert (bot.activity_prefix[0] == 0 and bot.activity_prefix[-1] == 600)
				assert (is_equal_approx(RankFakeUserGenerator._get_activity_hours(bot, 24.0), 24.0))
				var previous: int = count
				for hour in range(1, 49):
					var after: int = RankFakeUserGenerator.get_collect_count_at(bot, hour * 3600)
					assert (after >= previous)
					previous = after
			assert (contenders >= 4 and contenders <= 6)
			contender_counts[contenders] = true
			assert (initial_levels == PackedInt32Array([2, 4, 8, 8, 13, 11, 0, 3]))
			assert (initial.size() >= 7 and initial.get(0) == 2)
			var last_leader: int = -1
			for hour in range(1, 49):
				var contender_rows: Array[Dictionary] = []
				for index in bots.size():
					if bool(bots[index].is_contender):
						contender_rows.append({"bot_index": index, "collect_num": RankFakeUserGenerator.get_collect_count_at(bots[index], hour * 3600)})
				contender_rows.sort_custom( func(a: Dictionary, b: Dictionary) -> bool: return int(a.collect_num) > int(b.collect_num))
				var leader: int = int(contender_rows[0].bot_index)
				switches += 1 if last_leader >= 0 and leader != last_leader else 0
				last_leader = leader
				var spread: int = int(contender_rows[0].collect_num) - int(contender_rows[-1].collect_num)
				max_contender_spread = maxi(max_contender_spread, spread)
			for sample in sample_hours.size():
				var rows: Array = RankSettleLogic.build_ranked_rows(0, "Me", 1, bots, sample_hours[sample] * 3600)
				var counts: Dictionary = {}
				for row: Dictionary in rows:
					if not row.is_me:
						var count: int = int(row.collect_num)
						counts[count] = int(counts.get(count, 0)) + 1
				var max_tie: int = 0
				for count: int in counts.values():
					max_tie = maxi(max_tie, count)
				ties_total[sample] += max_tie
				unique_total[sample] += counts.size()
				top_five_spread_total[sample] += int(rows[0].collect_num) - int(rows[4].collect_num)
		var averages: Array[String] = []
		for sample in sample_hours.size():
			averages.append("%dh ties=%.1f unique=%.1f top5_gap=%.1f" % [sample_hours[sample], float(ties_total[sample]) / 12.0, float(unique_total[sample]) / 12.0, float(top_five_spread_total[sample]) / 12.0])
		SortLogger.info("[RankCollectTest] tier=%d (12 seasons): %s" % [tier, "; ".join(averages)])
	assert (contender_counts.size() == 3 and switches > 0)
	assert (max_contender_spread <= 80, "争冠组的自然增长差距不能持续拉大")
	SortLogger.info("[RankCollectTest] 84 seasons contenders=4/5/6, leader switches=%d, max contender spread=%d" % [switches, max_contender_spread])


func _strip_bot_activity(bot: Dictionary) -> void :
	for key: String in ["activity_rules_version", "activity_prefix", "activity_phase_seconds", "activity_origin_seconds", "activity_origin_growth_micros", "activity_slope_micros", "activity_delay_seconds", "initial_collect_budget", "is_contender"]:
		bot.erase(key)


func _assert_rank_simulation_reloaded(saved: Dictionary, reloaded: Dictionary) -> void :
	for key: String in ["event_id", "collect_num", "last_round_id", "scored_round_count", "start_time", "end_time", "bot_start_time", "catch_up_wave"]:
		assert (saved.get(key) == reloaded.get(key))
	assert (saved.bots.size() == reloaded.bots.size())
	for i in saved.bots.size():

		for key: String in ["base_collect", "bonus", "bonus_budget", "last_catch_up_growth_round", "nickname", "avatar_index", "collect_seed", "collect_start_level_id", "collect_first_target", "initial_collect_budget", "activity_prefix", "activity_phase_seconds", "activity_origin_seconds", "activity_origin_growth_micros", "activity_slope_micros", "activity_delay_seconds", "is_contender"]:
			assert (saved.bots[i].get(key) == reloaded.bots[i].get(key), "重启丢失模拟字段：%s" % key)
		for seconds in range(0, 172801, 900):
			assert (RankFakeUserGenerator.get_collect_count_at(saved.bots[i], seconds)
				== RankFakeUserGenerator.get_collect_count_at(reloaded.bots[i], seconds))


func _test_bot_activity_persistence() -> void :
	_reset_rank_state()
	UserState.set_current_level(21)
	RankManager.invalidate_snapshot()
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var entity: Dictionary = RankSnapshotBuilder.create_entity("activity-persistence", now_ms, now_ms + 86400000, 1, 49)
	entity["has_guide"] = true

	for bot: Dictionary in entity.bots:
		bot["base_collect"] = int(bot["collect_first_target"])
		bot["initial_collect_budget"] = 0
		bot["slope"] = 0.0
		bot["activity_slope_micros"] = 0
	entity["collect_num"] = 12
	entity["catch_up_wave"] = {"rules_version": RankCatchUpRule.RULES_VERSION, "start_round": 1, "members": [
		{"bot_index": 0, "start_completed_levels": 1, "target_levels": 1, "first_levels": 0}, 
		{"bot_index": 1, "start_completed_levels": 1, "target_levels": 2, "first_levels": 0}, 
		{"bot_index": 2, "start_completed_levels": 1, "target_levels": 2, "first_levels": 0}, 
	]}
	assert (UserState.commit_rank_entity(entity))
	var result: Dictionary = RankManager.commit_round_score(10, 50, "pending-round", "activity-persistence")
	assert (result.ok and result.applied and result.picks.is_empty())
	var saved: Dictionary = UserState.get_rank_current_entity()
	assert (saved.scored_round_count == 1 and saved.catch_up_wave.members.size() == 3)
	for member: Dictionary in saved.catch_up_wave.members:
		assert (member.first_levels == 0 and member.observed_completed_levels == 1)
	UserState._load_data()
	_assert_rank_simulation_reloaded(saved, UserState.get_rank_current_entity())
	saved = UserState.get_rank_current_entity()
	result = RankManager.commit_round_score(10, 50, "pending-round", "activity-persistence")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == saved)

	var ended: Dictionary = saved.duplicate(true)
	ended["end_time"] = now_ms - 1000
	assert (UserState.commit_rank_entity(ended))
	RankManager.invalidate_snapshot()
	result = RankManager.commit_round_score(10, 5, "expired-wave-round", "activity-persistence")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == ended)
	assert (UserState.commit_rank_entity(saved))
	RankManager.invalidate_snapshot()

	UserState.fail_save = true
	result = RankManager.commit_round_score(10, 5, "complete-round", "activity-persistence")
	assert ( not result.ok and UserState.get_rank_current_entity() == saved)
	UserState.fail_save = false
	result = RankManager.commit_round_score(10, 5, "complete-round", "activity-persistence")
	assert (result.ok and result.applied and result.picks.size() == 3)
	var completed: Dictionary = UserState.get_rank_current_entity()
	assert (completed.scored_round_count == 2 and not completed.has("catch_up_wave"))
	for member: Dictionary in saved.catch_up_wave.members:
		var bot: Dictionary = completed.bots[member.bot_index]
		assert (RankFakeUserGenerator.get_collect_progress_at(bot, 0).completed_levels == member.start_completed_levels + member.target_levels)
		assert (bot.bonus > 0 and bot.bonus_budget > 0 and bot.last_catch_up_growth_round == 2)
	UserState._load_data()
	_assert_rank_simulation_reloaded(completed, UserState.get_rank_current_entity())
	completed = UserState.get_rank_current_entity()
	result = RankManager.commit_round_score(10, 5, "complete-round", "activity-persistence")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == completed)
	result = RankManager.commit_round_score(10, 3, "next-wave-round", "activity-persistence")
	assert (result.ok and result.applied)
	var next: Dictionary = UserState.get_rank_current_entity()
	assert (next.scored_round_count == 3 and next.catch_up_wave.start_round == 3)
	assert (next.catch_up_wave.members.size() >= 2 and next.catch_up_wave.members.size() <= 3)
	entity.erase("catch_up_wave")

	entity.erase("bot_start_time")
	for bot: Dictionary in entity.bots:
		_strip_bot_activity(bot)
		bot["slope"] = 2.3
		bot["bonus_budget"] = 3
	entity["start_time"] = now_ms - 7200000
	var before: RankSnapshot = RankSnapshotBuilder.build(entity, now_ms, "Me", 1)
	var upgraded: Dictionary = entity.duplicate(true)
	assert (RankManager._prepare_bot_collect_rules(upgraded, now_ms))
	assert ( not RankManager._prepare_bot_collect_rules(upgraded, now_ms))
	assert (before.rows == RankSnapshotBuilder.build(upgraded, now_ms, "Me", 1).rows)
	for i in entity.bots.size():
		assert (RankFakeUserGenerator.get_collect_progress_at(entity.bots[i], 7200).remaining_budget
			== RankFakeUserGenerator.get_collect_progress_at(upgraded.bots[i], 7200).remaining_budget)
	assert (UserState.commit_rank_entity(entity))
	UserState.fail_save = true
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	assert (UserState.get_rank_current_entity() == entity)
	UserState.fail_save = false
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	saved = UserState.get_rank_current_entity()
	UserState._load_data()
	_assert_rank_simulation_reloaded(saved, UserState.get_rank_current_entity())
	var future_ms: int = now_ms + 12 * 3600000
	assert (RankSnapshotBuilder.build(saved, future_ms, "Me", 1).rows
		== RankSnapshotBuilder.build(UserState.get_rank_current_entity(), future_ms, "Me", 1).rows)
	entity["end_time"] = now_ms - 1000
	assert (UserState.commit_rank_entity(entity))
	RankManager.invalidate_snapshot()
	var frozen: RankSnapshot = RankManager.get_current_snapshot()
	assert (frozen.is_ended and UserState.get_rank_current_entity() == entity)
	assert (frozen.rows == RankSnapshotBuilder.build(entity, future_ms, RankManager.get_display_nickname(), RankManager.get_display_avatar_index()).rows)

	entity = RankSnapshotBuilder.create_entity("pace-persistence", now_ms - 7200000, now_ms + 86400000, 7, 49)
	entity.erase("bot_start_time")
	entity["bots"] = _old_activity_bots("pace-persistence", 7)
	assert (UserState.commit_rank_entity(entity))
	UserState.fail_save = true
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	assert (UserState.get_rank_current_entity() == entity)
	UserState.fail_save = false
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	saved = UserState.get_rank_current_entity()
	for bot: Dictionary in saved.bots:
		assert (bot.activity_rules_version == RankFakeUserGenerator.ACTIVITY_RULES_VERSION)
		if bool(bot.is_contender):
			assert (bot.fast_mult == 2.5 and bot.slow_mult == 1.0)
	UserState._load_data()
	_assert_rank_simulation_reloaded(saved, UserState.get_rank_current_entity())
	entity["end_time"] = now_ms - 1000
	assert (UserState.commit_rank_entity(entity))
	RankManager.invalidate_snapshot()
	frozen = RankManager.get_current_snapshot()
	assert (frozen.is_ended and UserState.get_rank_current_entity() == entity)
	assert (frozen.rows == RankSnapshotBuilder.build(entity, future_ms, RankManager.get_display_nickname(), RankManager.get_display_avatar_index()).rows)


func _test_bot_first_score_clock() -> void :
	_reset_rank_state()
	UserState.set_current_level(21)
	RankManager.invalidate_snapshot()
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var entity: Dictionary = RankSnapshotBuilder.create_entity("first-score-clock", now_ms - 43200000, now_ms + 86400000, 7, 49)
	entity["has_guide"] = true
	assert (UserState.commit_rank_entity(entity))
	assert (entity.bot_start_time == 0)
	assert (RankManager.is_valid_rank_in_game())
	var result: Dictionary = RankManager.commit_round_score(0, 50, "no-score", "first-score-clock")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == entity)
	result = RankManager.commit_round_score(10, 50, "wrong-season", "other-season")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == entity)
	UserState.fail_save = true
	result = RankManager.commit_round_score(10, 50, "first-score", "first-score-clock")
	assert ( not result.ok and UserState.get_rank_current_entity() == entity)
	UserState.fail_save = false
	result = RankManager.commit_round_score(10, 50, "first-score", "first-score-clock")
	assert (result.ok and result.applied)
	var saved: Dictionary = UserState.get_rank_current_entity()
	assert (saved.bot_start_time >= now_ms and saved.collect_num == 10 and saved.scored_round_count == 1)
	assert (RankSnapshotBuilder.bot_elapsed_seconds(saved, int(saved.bot_start_time)) == 0)
	UserState._load_data()
	_assert_rank_simulation_reloaded(saved, UserState.get_rank_current_entity())
	saved = UserState.get_rank_current_entity()
	result = RankManager.commit_round_score(10, 50, "first-score", "first-score-clock")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == saved)
	result = RankManager.commit_round_score(10, 50, "second-score", "first-score-clock")
	assert (result.ok and result.applied and UserState.get_rank_current_entity().bot_start_time == saved.bot_start_time)
	var expired: Dictionary = saved.duplicate(true)
	expired["end_time"] = now_ms - 1000
	assert (UserState.commit_rank_entity(expired))
	RankManager.invalidate_snapshot()
	result = RankManager.commit_round_score(10, 50, "expired-score", "first-score-clock")
	assert (result.ok and not result.applied and UserState.get_rank_current_entity() == expired)
	SortLogger.info("[RankCollectTest] first-score clock: atomic start, failed/no-score/old-season ignored, retry/restart stable")


func _test_bot_collect_level_sequence() -> void :

	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/builtin/chapter_default_1_5.json"))
	var by_level: Dictionary = {}
	for chapter: Dictionary in data.data:
		for entry: Dictionary in chapter.get("levels", []):
			var level_id: int = LevelIndex.level_id_of(int(chapter.chapterIndex), int(entry.levelIndex))
			if String(entry.get("levelUserTags", "")) != "default":
				continue
			var content: Dictionary = JSON.parse_string(AESDecryptor.decrypt(String(entry.initialLayout)))
			by_level[level_id] = int(content.targetCups)
	assert (RankFakeUserGenerator.FIRST_LEVEL_ID == 21)
	assert (RankFakeUserGenerator.FIRST_LEVEL_TARGET_COUNT == by_level[21])
	assert (RankFakeUserGenerator.START_LEVEL_TARGET_COUNTS.size() == by_level.size())
	for i in RankFakeUserGenerator.START_LEVEL_TARGET_COUNTS.size():
		assert (RankFakeUserGenerator.START_LEVEL_TARGET_COUNTS[i] == by_level[1 + i])
	SortLogger.info("[RankCollectTest] real level targets 1-125 verified; legacy sequence from 21 preserved")
	for value in range(0, 52):
		for has_sequence: bool in [false, true]:
			var bot: Dictionary = {"kind": "regular", "slope": 1.0, "base_collect": value, "bonus": 0}
			if has_sequence:
				bot["collect_seed"] = 0
			var before: int = RankFakeUserGenerator.get_collect_count_at(bot, 0)
			assert (before == 0 or before >= 12)
			assert (before >= value)
			assert (RankFakeUserGenerator.prepare_collect_rules(bot, 0, 0))
			assert (RankFakeUserGenerator.get_collect_count_at(bot, 0) == before)
			assert ( not RankFakeUserGenerator.prepare_collect_rules(bot, 0, 0))
			assert (RankFakeUserGenerator.get_collect_progress_at(bot, 0).remaining_budget == 0)
			var previous: int = before
			for hour in range(1, 40):
				var after: int = RankFakeUserGenerator.get_collect_count_at(bot, hour * 3600)
				if after > previous:
					assert (RankFakeUserGenerator.COLLECT_TARGET_COUNTS.has(after - previous))
				previous = after
	var with_bonus: Dictionary = {"kind": "regular", "slope": 1.0, "base_collect": 2, "bonus": 3, "collect_seed": 0}
	assert (RankFakeUserGenerator.prepare_collect_rules(with_bonus, 0, 0))
	assert (with_bonus.bonus == 3 and with_bonus.base_collect == 12 and with_bonus.bonus_budget == 0)
	assert (RankFakeUserGenerator.get_collect_count_at(with_bonus, 0) == 12)

	for value: int in [0, 10, 11, 12, 13]:
		for pair: Array in [[0, 0], [0, 12], [12, 12], [25, 12]]:
			var hours: int = pair[0]
			var bonus_budget: int = pair[1]
			var random_initial: Dictionary = {
				"kind": "regular", "slope": 1.0, "base_collect": value, 
				"bonus": bonus_budget, "bonus_budget": bonus_budget, "collect_seed": 0, 
				"collect_rules_version": RankFakeUserGenerator.COLLECT_RULES_VERSION, 
				"random_initial_collect": true, 
			}
			var elapsed: int = hours * 3600
			var old_count: int = value + RankFakeUserGenerator.get_completed_collect(float(hours + bonus_budget), 0)
			var mapped: Dictionary = RankFakeUserGenerator.get_collect_progress(float(old_count), 0)
			var expected: int = int(mapped.collect_num)
			if old_count > expected:
				expected += int(mapped.next_target)
			assert (RankFakeUserGenerator.get_collect_count_at(random_initial, elapsed) == expected)
			assert (RankFakeUserGenerator.prepare_collect_rules(random_initial, 0, elapsed))
			assert ( not random_initial.has("random_initial_collect"))
			assert (random_initial.bonus == bonus_budget and random_initial.bonus_budget == 0)
			assert (RankFakeUserGenerator.get_collect_count_at(random_initial, elapsed) == expected)
			assert ( not RankFakeUserGenerator.prepare_collect_rules(random_initial, 0, elapsed))
			var next: Dictionary = RankFakeUserGenerator.get_collect_progress_at(random_initial, elapsed)
			assert (next.remaining_budget == 0)
			assert (RankFakeUserGenerator.get_collect_count_at(random_initial, elapsed + int(next.next_target) * 3600)
				== expected + int(next.next_target))


func _test_bot_independent_collect_starts() -> void :
	var first_targets: Dictionary = {}
	var start_levels: Dictionary = {}
	for tier in range(1, 8):
		var generated: Array[Dictionary] = RankFakeUserGenerator.generate_bots("independent-starts", tier, 49)
		for bot: Dictionary in generated:
			assert (bot.collect_start_level_id >= 1 and bot.collect_start_level_id <= 125)
			assert (RankFakeUserGenerator.INITIAL_FIRST_TARGET_COUNTS.has(int(bot.collect_first_target)))
			first_targets[int(bot.collect_first_target)] = true
			start_levels[int(bot.collect_start_level_id)] = true
	assert (first_targets.size() == 4 and start_levels.size() > 1)

	for start_level_id in range(1, 126):
		for first_target: int in [9, 10, 11, 12]:
			var bot: Dictionary = {"kind": "regular", "slope": 1.0, "base_collect": 0, 
				"bonus": 0, "bonus_budget": 0, "collect_seed": start_level_id, 
				"collect_rules_version": RankFakeUserGenerator.COLLECT_RULES_VERSION, 
				"collect_start_level_id": start_level_id, "collect_first_target": first_target}
			var unchanged: Dictionary = bot.duplicate(true)
			assert ( not RankFakeUserGenerator.prepare_collect_rules(bot, 0, 0) and bot == unchanged)
			var expected: int = 0
			for level_id in range(start_level_id, 126):
				var target: int = first_target if level_id == start_level_id else RankFakeUserGenerator.START_LEVEL_TARGET_COUNTS[level_id - 1]
				var before: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, (expected + target - 1) * 3600)
				assert (before.collect_num == expected and before.next_target == target)
				assert (before.next_level_id == level_id and before.remaining_budget == target - 1)
				expected += target
				var after: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, expected * 3600)
				assert (after.collect_num == expected and after.remaining_budget == 0)
				assert (after.completed_levels == level_id - start_level_id + 1)
				assert (after.next_level_id == level_id + 1)

			bot["initial_collect_budget"] = first_target - 1
			var before: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, 0)
			var pick: Dictionary = RankFakeUserGenerator.resolve_collect_level_bonus(bot, 0, 2)
			pick["bot_index"] = 0
			_apply_catch_up_test_picks([bot], [pick], 0)
			var after: Dictionary = RankFakeUserGenerator.get_collect_progress_at(bot, 0)
			assert (before.completed_levels == 0 and after.completed_levels == 2)
			assert (pick.budget_delta == int(after.collect_num) - first_target + 1)

	var legacy: Dictionary = {"kind": "regular", "slope": 1.0, "base_collect": 12, 
		"initial_collect_budget": 1, "bonus_budget": 3, "collect_seed": 7, 
		"collect_rules_version": RankFakeUserGenerator.COLLECT_RULES_VERSION}
	var saved: Dictionary = legacy.duplicate(true)
	assert ( not RankFakeUserGenerator.prepare_collect_rules(legacy, 0, 0) and legacy == saved)
	assert (RankFakeUserGenerator.get_collect_count_at(legacy, 0) == 12)
	assert (RankFakeUserGenerator.get_collect_count_at(legacy, 9 * 3600) == 25)
	SortLogger.info("[RankCollectTest] 500 independent starts: first targets 9/10/11/12, real successors, partial budgets, two-level catch-up and unchanged legacy v2")


func _test_bot_collect_migration() -> void :
	_reset_rank_state()
	RankManager.invalidate_snapshot()
	UserState.set_current_level(21)
	assert (RankManager.is_unlocked())
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var legacy: Dictionary = RankSnapshotBuilder.create_entity("legacy-collect", now_ms - 3600000, now_ms + 86400000, 1, 49)
	legacy.erase("bot_start_time")
	legacy["has_guide"] = true
	for bot: Dictionary in legacy.bots:
		_strip_bot_activity(bot)
		bot.erase("collect_start_level_id")
		bot.erase("collect_first_target")
		bot.erase("collect_seed")
		bot.erase("collect_rules_version")
		bot.erase("bonus_budget")
		bot["bonus"] = 7
	legacy["collect_num"] = int(RankSnapshotBuilder.build(legacy, now_ms, "Me", 1).rows[0].collect_num)
	var before: RankSnapshot = RankSnapshotBuilder.build(legacy, now_ms, "Me", 1)
	var upgraded: Dictionary = legacy.duplicate(true)
	assert (RankManager._prepare_bot_collect_rules(upgraded, now_ms))
	assert ( not RankManager._prepare_bot_collect_rules(upgraded, now_ms))
	var after: RankSnapshot = RankSnapshotBuilder.build(upgraded, now_ms, "Me", 1)
	assert (before.rows == after.rows, "存档衔接不能让现有收集数或名次跳变")
	for i in legacy.bots.size():
		assert (upgraded.bots[i].bonus == 7 and upgraded.bots[i].nickname == legacy.bots[i].nickname)
	assert (UserState.commit_rank_entity(legacy))
	UserState.fail_save = true
	RankManager.get_current_snapshot()
	assert (UserState.get_rank_current_entity() == legacy)
	UserState.fail_save = false
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	var saved: Dictionary = UserState.get_rank_current_entity()
	for bot: Dictionary in saved.bots:
		assert (bot.has("collect_seed") and bot.has("collect_origin_growth"))
	var future_ms: int = now_ms + 12 * 3600000
	var future: RankSnapshot = RankSnapshotBuilder.build(saved, future_ms, "Me", 1)
	UserState._load_data()
	RankManager.invalidate_snapshot()
	var reloaded: Dictionary = UserState.get_rank_current_entity()

	for i in saved.bots.size():
		for field: String in ["collect_seed", "collect_origin_growth", "collect_rules_version", "base_collect", "bonus", "bonus_budget", "nickname"]:
			assert (saved.bots[i][field] == reloaded.bots[i][field])
	assert (future.rows == RankSnapshotBuilder.build(reloaded, future_ms, "Me", 1).rows)

	assert (UserState.commit_rank_entity(legacy))
	UserState.fail_save = true
	var result: Dictionary = RankManager.commit_round_score(24, 1, "collect-migration-round", "legacy-collect")
	assert ( not result.ok and UserState.get_rank_current_entity() == legacy)
	UserState.fail_save = false
	result = RankManager.commit_round_score(24, 1, "collect-migration-round", "legacy-collect")
	assert (result.ok and result.applied)
	saved = UserState.get_rank_current_entity()
	assert (saved.collect_num == int(legacy.collect_num) + 24)
	assert (saved.catch_up_wave.members.size() >= 2 and saved.catch_up_wave.members.size() <= 3)
	for bot: Dictionary in saved.bots:
		assert (bot.has("collect_seed"))
	for pick: Dictionary in result.picks:
		assert (saved.bots[pick.bot_index].bonus == 7 + pick.bonus)
	UserState._load_data()
	saved = UserState.get_rank_current_entity()
	result = RankManager.commit_round_score(24, 1, "collect-migration-round", "legacy-collect")
	assert (result.ok and not result.applied and saved == UserState.get_rank_current_entity())

	var small: Dictionary = saved.duplicate(true)
	small.erase("catch_up_wave")
	small["start_time"] = now_ms
	for i in small.bots.size():
		_strip_bot_activity(small.bots[i])
		small.bots[i]["base_collect"] = i % 10
		small.bots[i]["bonus"] = 0
		small.bots[i]["collect_origin_growth"] = 0.0
		small.bots[i]["collect_rules_version"] = 1
	assert (UserState.commit_rank_entity(small))
	RankManager.invalidate_snapshot()
	UserState.fail_save = true
	RankManager.get_current_snapshot()
	assert (UserState.get_rank_current_entity() == small)
	UserState.fail_save = false
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	var repaired: Dictionary = UserState.get_rank_current_entity()
	for i in repaired.bots.size():
		assert (repaired.bots[i].base_collect == (0 if i % 10 == 0 else RankFakeUserGenerator.FIRST_LEVEL_TARGET_COUNT))
	UserState._load_data()
	for i in repaired.bots.size():
		assert (repaired.bots[i].base_collect == UserState.get_rank_current_entity().bots[i].base_collect)

	var random_saved: Dictionary = small.duplicate(true)
	for bot: Dictionary in random_saved.bots:
		bot["collect_rules_version"] = RankFakeUserGenerator.COLLECT_RULES_VERSION
		bot["random_initial_collect"] = true
		bot["base_collect"] = 13
	assert (UserState.commit_rank_entity(random_saved))
	RankManager.invalidate_snapshot()
	UserState.fail_save = true
	RankManager.get_current_snapshot()
	assert (UserState.get_rank_current_entity() == random_saved)
	UserState.fail_save = false
	RankManager.invalidate_snapshot()
	RankManager.get_current_snapshot()
	repaired = UserState.get_rank_current_entity()
	for i in repaired.bots.size():
		var bot: Dictionary = repaired.bots[i]

		var expected: int = RankFakeUserGenerator.get_collect_count_at(random_saved.bots[i], 0)
		assert (bot.base_collect == expected and not bot.has("random_initial_collect"))
	UserState._load_data()
	assert (RankSnapshotBuilder.build(repaired, future_ms, "Me", 1).rows
		== RankSnapshotBuilder.build(UserState.get_rank_current_entity(), future_ms, "Me", 1).rows)

	legacy = random_saved.duplicate(true)
	legacy["end_time"] = now_ms - 1000
	assert (UserState.commit_rank_entity(legacy))
	RankManager.invalidate_snapshot()
	before = RankManager.get_current_snapshot()
	assert (before.is_ended and UserState.get_rank_current_entity() == legacy)
	assert (before.rows == RankSnapshotBuilder.build(legacy, future_ms, RankManager.get_display_nickname(), RankManager.get_display_avatar_index()).rows)

	_test_bot_activity_persistence()
	_test_bot_first_score_clock()


func _test_ledger() -> void :
	_reset_rank_state()
	RankManager.invalidate_snapshot()
	UserState.set_current_level(20)
	assert ( not RankManager.is_unlocked())
	UserState.set_current_level(21)
	assert (RankManager.is_unlocked())
	UserState.set_current_level(1)
	assert (RankManager.is_unlocked())
	RankManager.ensure_profile()
	assert (RankManager.ensure_season())
	var initial: Dictionary = UserState.get_rank_current_entity()
	assert (int(initial.end_time) - int(initial.start_time) == 2 * 86400 * 1000)
	assert ( not RankManager.is_valid_rank_in_game())
	RankManager.mark_guide_shown()
	assert (RankManager.is_valid_rank_in_game())
	var tampered: Dictionary = initial.duplicate(true)
	tampered.has_receive_bonus = true
	assert ( not UserState.commit_rank_entity(tampered))
	assert ( not UserState.get_rank_current_entity().has_receive_bonus)
	var season_id: String = String(initial.event_id)
	var before: int = RankManager.get_collect_num()
	var result: Dictionary = RankManager.commit_round_score(7, 50, "round-1", season_id)
	assert (result.ok and result.applied and RankManager.get_collect_num() == before + 7)
	UserState._load_data()
	RankManager.invalidate_snapshot()
	result = RankManager.commit_round_score(7, 50, "round-1", season_id)
	assert (result.ok and not result.applied and RankManager.get_collect_num() == before + 7)
	UserState.fail_save = true
	result = RankManager.commit_round_score(9, 50, "round-2", season_id)
	assert ( not result.ok and RankManager.get_collect_num() == before + 7)
	UserState.fail_save = false
	result = RankManager.commit_round_score(9, 50, "round-2", season_id)
	assert (result.ok and result.applied and RankManager.get_collect_num() == before + 16)
	result = RankManager.commit_round_score(9, 50, "round-3", "old-season")
	assert (result.ok and not result.applied)

	RankManager.cheat_adjust_collect_num(99999999)
	RankManager.cheat_set_remaining_seconds(0)
	var settlement: Dictionary = RankManager.check_rank_end()
	assert (settlement.has_ended and settlement.rank_pos == 1)
	assert (settlement.reward_hint == 5 and settlement.reward_coin == 300)
	assert ( not RankManager.ensure_season())
	assert (RankManager.check_rank_end() == settlement)
	var coin_before: int = UserState.get_coins()
	var hint_before: int = UserState.get_prop_count("hint")
	UserState.fail_save = true
	assert ( not RankManager.claim_season_reward(settlement.event_id))
	assert (UserState.get_coins() == coin_before and UserState.get_prop_count("hint") == hint_before)
	assert ( not UserState.get_rank_current_entity().has_receive_bonus)
	UserState.fail_save = false
	UserState._load_data()
	RankManager.invalidate_snapshot()
	assert (RankManager.claim_season_reward(settlement.event_id))
	assert (UserState.get_coins() == coin_before + 300 and UserState.get_prop_count("hint") == hint_before + 5)
	assert ( not RankManager.claim_season_reward(settlement.event_id))
	UserState._load_data()
	assert ( not RankManager.claim_season_reward(settlement.event_id))
	assert (RankManager.ensure_season())
	assert (RankManager.get_current_tier() == 2)

	RankManager.cheat_set_remaining_seconds(0)
	settlement = RankManager.check_rank_end()
	assert (settlement.has_ended and settlement.reward_coin == 0 and settlement.reward_hint == 0)
	assert (RankManager.claim_season_reward(settlement.event_id))
	assert (RankManager.ensure_season())

	var external: Dictionary = UserState.get_rank_current_entity()
	external.collect_num = 12345
	assert (UserState.get_rank_current_entity().collect_num != 12345)
	var now: int = int(Time.get_unix_time_from_system() * 1000.0)
	UserState.advance_rank_clock_watermark(now + RankManager.CLOCK_ROLLBACK_TOLERANCE_MS + 60000)
	assert ( not RankManager.is_valid_rank_in_game() and RankManager.is_clock_rolled_back())
	assert ( not RankManager.ensure_season())

func _test_scenes() -> void :
	for route: String in ["rank", "rank_game_finish", "rank_change", "rank_new_season", "rank_introduction", "rank_season_win", "avatar_select", "rank_debug", "home", "game"]:
		var packed: PackedScene = load(SceneManager.PAGE_SCENES[route])
		assert (packed != null, route)
		var instance: Node = packed.instantiate()
		assert (instance != null, route)
		instance.free()


func _test_avatars() -> void :
	var pool: RankAvatarPool = load("res://scripts/gameplay/rank/view/rank_avatar_pool.tscn").instantiate()
	assert (pool.textures.size() == 12)
	for index: int in range(1, 13):
		var texture: Texture2D = pool.get_texture(index)
		assert (texture != null and texture.get_size() == Vector2(200, 200))
		assert (texture.resource_path.ends_with("common_rank_avatar_animal_%02d.png" % index))
	for index: int in [-1, 0, 13, 32]:
		assert (pool.get_texture(index) == pool.get_texture(1))
	for index: int in [0, 32]:
		UserState.set_rank_profile("AvatarMigration", index)
		RankManager.ensure_profile()
		assert (UserState.get_rank_avatar_index() == 1)
	for index: int in [1, 12]:
		assert (RankManager.set_profile("AvatarSelection", index))
		RankManager.ensure_profile()
		assert (RankManager.get_display_avatar_index() == index)
	pool.free()
	var dialog: AvatarSelectDialog = load("res://scripts/main/dialogs/avatar_select/avatar_select_dialog.tscn").instantiate()
	add_child(dialog)
	await get_tree().process_frame
	assert (dialog.get_cell_count() == 12)
	var grid: GridContainer = dialog.get_node("Root/Content/Dialog/ListBg/Scroll/GridMargin/Grid")
	assert (grid.size.x == 840 and grid.size.y == 620)
	for index: int in range(12):
		var cell: RankAvatarCell = dialog.get_cell_at(index)
		assert (cell.size == Vector2(180, 180))
		assert (cell.position == Vector2((index % 4) * 220, (index / 4) * 220))
		cell.set_selected(index == 11)
		assert (cell.get_node("Root/Selected").visible == (index == 11))
		assert (cell.get_node("Root/Selected").z_index > cell.get_node("Root/Avatar").z_index)
	var cell: RankAvatarCell = dialog.get_cell_at(11)
	var selected: TextureRect = cell.get_node("Root/Selected")
	var ratio: Vector2 = selected.size / selected.texture.get_size()
	assert ((selected.position + RankAvatarCell.SELECTED_INNER_RECT.position * ratio).is_equal_approx(Vector2.ZERO))
	assert ((RankAvatarCell.SELECTED_INNER_RECT.size * ratio).is_equal_approx(cell.size))
	dialog._on_show()
	for index: int in range(1, 13):
		dialog._on_cell_picked(index)
		_assert_avatar_selection_overlay(dialog)
	SceneManager.play_press_feedback(dialog._selection_target)
	await get_tree().create_timer(0.09).timeout
	_assert_avatar_selection_overlay(dialog)
	SceneManager.play_release_feedback(dialog._selection_target)
	await get_tree().create_timer(0.35).timeout
	_assert_avatar_selection_overlay(dialog)

	var chapter: Control = load("res://scripts/gameplay/outer_loop/view/new_scene_page.tscn").instantiate()
	add_child(chapter)
	assert (_effective_canvas_z(dialog._selection) == _effective_canvas_z(chapter))
	assert (dialog.get_index() < chapter.get_index())
	chapter.free()
	dialog._on_hide()
	assert ( not dialog.is_processing())
	dialog.free()


func _assert_avatar_selection_overlay(dialog: AvatarSelectDialog) -> void :
	for cell: RankAvatarCell in dialog._cells:
		assert ( not cell.get_node("Root/Selected").visible, "Cell Z=1 rings must remain hidden in the dialog")
	var frame: TextureRect = dialog._selection
	var inner: Rect2 = RankAvatarCell.SELECTED_INNER_RECT
	var ratio: Vector2 = frame.size / frame.texture.get_size()
	var avatar_transform: Transform2D = dialog._selection_target.get_global_transform()
	assert (frame.visible and _effective_canvas_z(frame) == 0)
	assert ((frame.get_global_transform() * (inner.position * ratio)).is_equal_approx(avatar_transform.origin))
	assert ((frame.get_global_transform() * (inner.end * ratio)).is_equal_approx(
		avatar_transform * dialog._selection_target.size))


func _test_rank_collect_command() -> void :
	var commands: Node = load("res://scripts/debug/cheat_commands.gd").new()
	var original: int = RankManager.get_collect_num()
	for count: int in [314, 314, 9, 0, -10, 99999999]:
		var args: Array[String] = [str(count)]
		commands._cmd_rank_collect(args)
		assert (RankManager.get_collect_num() == maxi(count, 0))
		assert (RankManager.get_current_snapshot().my_collect_num == maxi(count, 0))
		UserState._load_data()
		assert (RankManager.get_collect_num() == maxi(count, 0), "Absolute collect count must survive reload")
	var empty: Array[String] = []
	commands._cmd_rank_collect(empty)
	assert (RankManager.get_collect_num() == 100)
	var restore: Array[String] = [str(original)]
	commands._cmd_rank_collect(restore)
	commands.free()


func _test_trophy_shadows() -> void :
	var badge: RankBadgeView = load("res://scripts/gameplay/rank/view/rank_badge_view.tscn").instantiate()
	add_child(badge)
	for bounds: Vector2 in [Vector2(200, 200), Vector2(560, 560), Vector2(453.2, 519.2), Vector2(800, 500)]:
		badge.size = bounds
		for tier: int in range(1, 8):
			for dark: bool in [false, true]:
				badge.set_tier(tier, dark)
				assert (badge._shadow.texture.resource_path.ends_with("common_rank_shadow.png"))
				assert (badge._shadow.show_behind_parent and badge._shadow.scale.is_equal_approx(badge._img.scale))
				var image_bottom: float = bounds.y * 0.5 + badge._img.texture.get_height() * badge._img.scale.y * 0.5
				var shadow_bottom: float = badge._shadow.position.y + badge._shadow.texture.get_height() * badge._shadow.scale.y * 0.25
				assert (is_equal_approx(shadow_bottom, image_bottom))
				assert (is_equal_approx(badge._shadow.position.x, bounds.x * 0.5))
		var shadow_position: Vector2 = badge._shadow.position
		var image_scale: Vector2 = badge._img.scale
		for offset_ratio: float in [12.0 / 519.2, 0.0]:
			badge.set_ground_contact_offset_ratio(offset_ratio)
			assert (badge._float_host.position.is_equal_approx(bounds * 0.5 + Vector2(0.0, bounds.y * offset_ratio)))
			assert (badge._shadow.position.is_equal_approx(shadow_position))
			assert (badge._img.scale.is_equal_approx(image_scale))
	badge.free()
	var center_badge: RankBadgeView = load("res://scripts/gameplay/rank/view/rank_badge_view.tscn").instantiate()
	add_child(center_badge)
	center_badge.size = Vector2(453.2, 519.2)
	var nav: RankTierNav = load("res://scripts/gameplay/rank/view/rank_tier_nav.tscn").instantiate()
	add_child(nav)
	nav.setup(center_badge)
	assert (is_equal_approx(center_badge._float_host.position.y - center_badge.size.y * 0.5, 12.0))
	for slot: RankBadgeView in nav._all_slots():
		slot.size = center_badge.size
		for tier: int in range(1, 8):
			for dark: bool in [false, true]:
				slot.set_tier(tier, dark)
				assert (is_equal_approx(slot._float_host.position.y - slot.size.y * 0.5, 12.0))
				var image_bottom: float = (slot.size.y + slot._img.texture.get_height() * slot._img.scale.y) * 0.5
				var shadow_bottom: float = slot._shadow.position.y + slot._shadow.texture.get_height() * slot._shadow.scale.y * 0.25
				assert (is_equal_approx(shadow_bottom, image_bottom))
	nav.free()
	center_badge.free()
	for route: String in ["rank_new_season", "rank_introduction"]:
		var dialog: Control = load(SceneManager.PAGE_SCENES[route]).instantiate()
		add_child(dialog)
		await get_tree().process_frame
		var parents: Array[String] = ["Root/Content/Dialog/Medal"]
		if route == "rank_introduction":
			parents.assign(["Root/Content/Badge1", "Root/Content/Badge2", "Root/Content/Badge3"])
		for path: String in parents:
			var image: TextureRect = dialog.get_node(path)
			var shadow: TextureRect = image.get_node("Shadow")
			var factor: float = minf(image.size.x / image.texture.get_width(), image.size.y / image.texture.get_height())
			assert (shadow.show_behind_parent and shadow.mouse_filter == Control.MOUSE_FILTER_IGNORE)
			assert (shadow.size.is_equal_approx(shadow.texture.get_size() * factor))
			assert (is_equal_approx(shadow.position.x + shadow.size.x * 0.5, image.size.x * 0.5))
			assert (is_equal_approx(shadow.position.y + shadow.size.y * 0.75, 
				(image.size.y + image.texture.get_height() * factor) * 0.5))
		dialog.free()


func _wait_until(check: Callable, seconds: float = 5.0) -> void :
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not check.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert (check.call(), "Presentation wait timed out")


func _test_home_season_expiry() -> void :
	await _test_home_enter_cancellation()
	await SceneManager.warm_page_threaded("home")
	var home: HomePage = SceneManager.get_page("home")
	await home._components.ensure_group("rank", func() -> bool: return true)
	await _test_home_chapter_season_order(home)


	home.visible = true
	_prepare_home_season(home)
	home._rank_entry._tick.stop()
	home.open_rank_page()
	await _wait_until( func() -> bool:
		var page: Node = SceneManager.get_page("rank")
		return page != null and page.visible)
	var rank_page: Node = SceneManager.get_page("rank")

	await home.run_rank_session()
	await get_tree().process_frame
	assert (rank_page.visible, "An active, introduced season must keep the newly opened rank page visible")
	assert ( not home._rank_session_running)
	SceneManager.hide_page("rank")
	await get_tree().process_frame
	for wait_for_modal: bool in [false, true]:
		_prepare_home_season(home)
		var modal: Node = null
		if wait_for_modal:
			await SceneManager.warm_page_threaded("avatar_select")
			modal = SceneManager.show_dlg("avatar_select")
		RankManager.cheat_set_remaining_seconds(1)
		await _wait_until( func() -> bool: return RankManager.is_season_ended())
		await _wait_until( func() -> bool: return home._rank_session_running)
		if wait_for_modal:
			var blocked: Node = SceneManager.get_page("rank_change")
			assert (blocked == null or not blocked.visible)
			assert (modal.visible)
			SceneManager.hide_dlg("avatar_select")
		await _finish_home_season(home)

	_prepare_home_season(home)
	SceneManager.show_dlg("avatar_select")
	RankManager.cheat_set_remaining_seconds(1)
	await _wait_until( func() -> bool: return home._rank_session_running)
	home._on_hide()
	await get_tree().process_frame
	assert ( not home._rank_session_running)
	assert ( not SceneManager.get_page("rank_change").visible)
	assert ( not SceneManager.get_page("rank_new_season").visible)
	assert ( not UserState.get_rank_current_entity().has_receive_bonus)

	home.visible = true
	_prepare_home_season(home)
	home._rank_entry._tick.stop()
	RankManager.cheat_set_remaining_seconds(0)
	home._on_rank_pressed()
	await _finish_home_season(home)
	await _test_rank_page_season_expiry(home)
	home._on_hide()
	AudioManager.stop_all_sfx()
	await get_tree().create_timer(0.2).timeout
	_reset_rank_state()
	RankManager.invalidate_snapshot()


func _test_home_enter_cancellation() -> void :
	var page: = HomeEnterProbe.new()
	add_child(page)
	for cancelled: bool in [true, false]:
		var generation: int = page.generation
		HomeEnterFlow.run(page, true, func() -> bool: return generation == page.generation)
		if cancelled:
			page.generation += 1
		page.progress_finished.emit()
		await get_tree().process_frame
		assert (page.rank_session_count == (0 if cancelled else 1), 
			"Only the current home entry may run a rank session after chapter progress")
	page.free()


func _test_home_chapter_season_order(cached_home: HomePage) -> void :
	var home = load(SceneManager.PAGE_SCENES.home).instantiate()
	home.set_script(HomeChapterProbe)
	cached_home.get_parent().add_child(home)
	await home._components.ensure_group("rank", func() -> bool: return true)
	await SceneManager.warm_page_threaded("rank_change")
	var change: RankChangeDialog = SceneManager.get_page("rank_change")
	var shows: Dictionary = {"count": 0}
	var on_visibility: Callable = func() -> void :
		if change.visible:
			shows.count += 1
	change.visibility_changed.connect(on_visibility)
	for expires_on_refresh: bool in [true, false]:
		var previous_shows: int = shows.count
		home.visible = true
		_prepare_home_season(home)
		if expires_on_refresh:
			home._rank_entry._tick.stop()
			RankManager.cheat_set_remaining_seconds(0)
		home._on_show({})
		assert ( not home.progress_waits.is_empty())
		if not expires_on_refresh:
			RankManager.cheat_set_remaining_seconds(1)
			await _wait_until( func() -> bool: return RankManager.is_season_ended())
			home._rank_entry._on_tick()

		home._on_rank_pressed()
		home.run_rank_session()
		assert ( not home._rank_session_running, "Season expiry must wait for the chapter step")
		for route: String in ["rank_change", "rank_new_season", "rank_season_win"]:
			var dialog: Node = SceneManager.get_page(route)
			assert (dialog == null or not dialog.visible)
		(home.progress_waits.pop_back() as ChapterProgressWait).completed.emit()
		await _finish_home_season(home)
		assert (shows.count == previous_shows + 1, "Pending requests must merge into one settlement")
		home._on_hide()

	home.visible = true
	_prepare_home_season(home)
	RankManager.cheat_set_remaining_seconds(0)
	home._on_show({})
	var old_wait: ChapterProgressWait = home.progress_waits.pop_back()
	home._on_hide()
	assert ( not home._home_enter_pending and not home._rank_session_pending)
	home._on_show({})
	old_wait.completed.emit()
	await get_tree().process_frame
	assert ( not home._rank_session_running)
	assert (home._home_enter_pending)
	(home.progress_waits.pop_back() as ChapterProgressWait).completed.emit()
	await _finish_home_season(home)
	home._on_hide()
	assert (shows.count == 3)
	change.visibility_changed.disconnect(on_visibility)
	home.free()


func _test_rank_page_season_expiry(home: HomePage) -> void :
	for wait_for_modal: bool in [false, true]:
		_prepare_home_season(home)
		UserState.mark_rank_avatar_dialog_shown()
		home.open_rank_page()
		await _wait_until( func() -> bool:
			var page: Node = SceneManager.get_page("rank")
			return page != null and page.visible and not page._clock._tick.is_stopped())
		var rank_page: RankPage = SceneManager.get_page("rank")

		home._rank_entry._tick.stop()
		if wait_for_modal:
			SceneManager.show_dlg("avatar_select")
		var change: RankChangeDialog = SceneManager.get_page("rank_change")
		var shows: Dictionary = {"count": 0}
		var on_visibility: Callable = func() -> void :
			if change.visible:
				shows.count += 1
		change.visibility_changed.connect(on_visibility)
		RankManager.cheat_set_remaining_seconds(1)
		await _wait_until( func() -> bool: return home._rank_session_running)
		assert (home._rank_session_running, "Rank page expiry must start the shared season session")
		if wait_for_modal:
			assert (rank_page.visible and not change.visible)
			assert (rank_page._clock._tick.is_stopped())
			assert (rank_page._clock._rotate_tween == null, "Expiry must leave the stopped clock without a new pointer tween")
			SceneManager.hide_dlg("avatar_select")
		await _finish_home_season(home)
		change.visibility_changed.disconnect(on_visibility)
		assert ( not rank_page.visible and shows.count == 1)
		assert (rank_page._clock._rotate_tween == null)

	_prepare_home_season(home)
	UserState.mark_rank_avatar_dialog_shown()
	home.open_rank_page()
	await _wait_until( func() -> bool:
		return not (SceneManager.get_page("rank") as RankPage)._clock._tick.is_stopped())
	home._rank_entry._tick.stop()
	RankManager.cheat_set_remaining_seconds(1)
	SceneManager.hide_page("rank")
	await get_tree().create_timer(2.1).timeout
	assert ( not home._rank_session_running and not SceneManager.get_page("rank_change").visible)
	assert ( not UserState.get_rank_current_entity().has_receive_bonus)


func _prepare_home_season(home: HomePage) -> void :
	_reset_rank_state()
	RankManager.invalidate_snapshot()
	UserState.set_current_level(21)
	RankManager.ensure_profile()
	RankManager.ensure_season()
	RankManager.mark_guide_shown()
	RankManager.mark_rank_ever_played()
	home.refresh_entry_ui()
	assert ( not home._rank_session_running and not home._rank_entry._expired_reported)


func _finish_home_season(home: HomePage) -> void :
	await _wait_until( func() -> bool:
		var dialog: Node = SceneManager.get_page("rank_change")
		return dialog != null and dialog.visible and dialog.is_action_enabled())
	var change: RankChangeDialog = SceneManager.get_page("rank_change")
	assert (UserState.get_rank_current_entity().settle_state == "computed")
	assert ( not UserState.get_rank_current_entity().has_receive_bonus)
	assert (change._reward_coin == 0 and change._reward_hint == 0)
	change._on_action_pressed()
	await _wait_until( func() -> bool:
		var dialog: Node = SceneManager.get_page("rank_new_season")
		return dialog != null and dialog.visible and not dialog._ok_btn.disabled)
	assert ( not RankManager.is_season_ended() and RankManager.get_remain_seconds() > 0)
	assert (RankManager.get_current_snapshot().has_guide)
	var new_season: RankNewSeasonDialog = SceneManager.get_page("rank_new_season")
	new_season._on_close_pressed()
	await _wait_until( func() -> bool: return not home._rank_session_running)
	assert ( not change.visible and not new_season.visible)


func _test_rank_ui_layout() -> void :
	var home: Control = load("res://scripts/main/pages/home/home_page.tscn").instantiate()
	assert (home.get_node("Root/HomeNav/CoinHud").z_index == 0)
	home.free()
	var original_locale: String = TranslationServer.get_locale()
	for path: String in ["rank_zone_banner", "rank_finish_zone_banner"]:
		var banner: RankZoneBanner = load("res://scripts/gameplay/rank/view/%s.tscn" % path).instantiate()
		add_child(banner)
		for locale: String in TranslationServer.get_loaded_locales():
			TranslationServer.set_locale(locale)
			for kind: RankZoneBanner.Kind in [RankZoneBanner.Kind.UPGRADE, RankZoneBanner.Kind.DOWNGRADE]:
				banner.setup(kind, 1 if kind == RankZoneBanner.Kind.UPGRADE else 41, 
					15 if kind == RankZoneBanner.Kind.UPGRADE else 50)
				var label: Label = banner.range_label if banner.range_label != null else banner._text
				assert (absf(_first_digit_center_y(label) - banner._bg.get_global_rect().get_center().y) < 1.5)
		banner.free()
	TranslationServer.set_locale(original_locale)
	var pool: RankAvatarPool = load("res://scripts/gameplay/rank/view/rank_avatar_pool.tscn").instantiate()
	var podium: RankFinishPodium = load("res://scripts/gameplay/rank/view/rank_finish_podium.tscn").instantiate()
	add_child(podium)
	for fx: RankThemeIdleView in podium._gift_fx:
		assert ( not fx.visible and not fx._rise_motes.emitting and not fx._sparkles.emitting)
	podium.bind_snapshot(_finish_snapshot(1), pool, null)
	for card: RankItemView in podium._cards:
		var label: Label = card.get_node("CollectBg/CollectNum")
		var bg: Control = card.get_node("CollectBg")
		var icon: Control = card.get_node("CollectIcon")
		var base_font_size: int = label.get_theme_font_size("font_size")
		assert (bg.size.is_equal_approx(Vector2(200.0, 80.0)))
		assert (is_equal_approx((icon.position.x + bg.position.x + bg.size.x) * 0.5, card.size.x * 0.5))
		assert (label.size.x == 120.0)
		if card.podium_slot == 1:
			card.set_collect_num_display(143)
			assert (label.get_theme_font_size("font_size") == 52)
		assert (label.get_global_rect().position.x >= icon.get_global_rect().end.x + 7.0)
		for count: int in [0, 12, 999, 9999, 99999999, 12]:
			card.set_collect_num_display(count)
			assert (card.get_collect_num_display() == count)
			assert (label.get_minimum_size().x <= label.size.x)
			assert (absf(_first_digit_center_y(label) - bg.get_global_rect().get_center().y) < 1.5)
			assert (is_equal_approx(label.get_global_rect().get_center().x, 
				(icon.get_global_rect().end.x + 8.0
				+ bg.get_global_rect().end.x - 16.0) * 0.5))
		assert (label.get_theme_font_size("font_size") == base_font_size)
		assert ((card.get_node("GiftButton") as TextureButton).texture_normal.resource_path.ends_with(
			"common_rank_ranks_gift_icon_%d.png" % card.podium_slot))
	for fx: RankThemeIdleView in podium._gift_fx:
		assert (fx.visible and fx._rise_motes.emitting and fx._sparkle_loop_active)
		assert ( not fx._img.visible and fx._rise_motes.amount == 7)
	podium.cancel_animations()
	for fx: RankThemeIdleView in podium._gift_fx:
		assert ( not fx.visible and not fx._rise_motes.emitting and not fx._sparkles.emitting)
		assert ( not fx._sparkle_loop_active and fx._sparkle_loop_tween == null)
	podium.bind_snapshot(_finish_snapshot(2), pool, null)
	assert (podium._gift_fx.all( func(fx: RankThemeIdleView) -> bool: return fx.visible and fx._rise_motes.emitting))
	_test_podium_enter(podium, pool)
	podium.cancel_animations()
	podium.free()
	pool.free()


func _test_podium_enter(podium: RankFinishPodium, pool: RankAvatarPool) -> void :
	podium.cancel_animations()
	podium.prepare_enter()
	podium.bind_snapshot(_finish_snapshot(1), pool, null)
	var scores: Array[int] = []
	for index: int in podium._cards.size():
		var card: RankItemView = podium._cards[index]
		var offset: float = 80.0 if index == 0 else 60.0
		assert (is_zero_approx(card.modulate.a))
		assert (card.position.is_equal_approx(Vector2(podium._card_rest[index].position) + Vector2(0.0, offset)))
		assert (card.scale.is_equal_approx(Vector2.ONE * 0.95))
		scores.append(card.get_collect_num_display())
	assert (is_zero_approx(podium._crown_glow.modulate.a))
	var tween: Tween = podium.play_enter()
	tween.custom_step(0.05)
	assert (is_zero_approx(podium._cards[0].modulate.a))
	assert (podium._cards[1].modulate.a > 0.0)
	assert (is_equal_approx(podium._cards[1].modulate.a, podium._cards[2].modulate.a))
	tween.custom_step(0.02)
	assert (podium._cards[0].modulate.a > 0.0)
	tween.custom_step(0.23)
	for index: int in [1, 2]:
		assert (podium._cards[index].position.is_equal_approx(podium._card_rest[index].position))
		assert (podium._cards[index].scale.is_equal_approx(Vector2.ONE * 1.02))
	assert (podium._cards[0].position.y > float(podium._card_rest[0].position.y))
	tween.custom_step(0.06)
	assert (podium._cards[0].scale.is_equal_approx(Vector2.ONE * 1.02))
	tween.custom_step(0.06)
	assert (podium._cards[1].scale.is_equal_approx(Vector2.ONE))
	assert (podium._cards[2].scale.is_equal_approx(Vector2.ONE))
	assert (podium._cards[0].scale.x > 1.0 and podium._cards[0].scale.x < 1.02)
	tween.custom_step(0.059)
	assert (podium._enter_prepared and is_zero_approx(podium._crown_glow.modulate.a))
	tween.custom_step(0.002)
	assert ( not podium._enter_prepared and podium._enter_tween == null)
	for index: int in podium._cards.size():
		var card: RankItemView = podium._cards[index]
		assert (card.position.is_equal_approx(podium._card_rest[index].position))
		assert (card.scale.is_equal_approx(Vector2.ONE) and card.pivot_offset.is_equal_approx(Vector2.ZERO))
		assert (is_equal_approx(card.modulate.a, 1.0) and card.get_collect_num_display() == scores[index])
	podium._crown_glow_fade_tween.custom_step(0.08)
	assert (podium._crown_glow.modulate.a > 0.0 and podium._crown_glow.modulate.a < 1.0)
	var glow: Tween = podium._crown_glow_fade_tween
	podium.cancel_animations()
	assert ( not glow.is_valid() and is_equal_approx(podium._crown_glow.modulate.a, 1.0))

	podium.prepare_enter()
	podium.bind_snapshot(_finish_snapshot(2), pool, null)
	var interrupted: Tween = podium.play_enter()
	interrupted.custom_step(0.2)
	podium.cancel_animations()
	assert ( not interrupted.is_valid())
	var replay: Tween = podium.play_enter()
	replay.custom_step(0.1)
	var restarted: Tween = podium.play_enter()
	assert ( not replay.is_valid() and is_zero_approx(podium._cards[0].modulate.a))
	restarted.custom_step(0.49)
	assert (podium.find_item("me").podium_slot == 2 and not podium._enter_prepared)
	for card: RankItemView in podium._cards:
		assert (card.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(card.modulate.a, 1.0))


func _test_rank_zone_snapshots() -> void :
	for tier: int in range(RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX + 1):
		var entity: Dictionary = RankSnapshotBuilder.create_entity("zone_boundary", 1000, 2000, tier, 49)
		var snap: RankSnapshot = RankSnapshotBuilder.build(entity, 1500, "Me", 1)
		assert (snap.upgrade_end_rank == (0 if tier == RankSettleLogic.TIER_MAX else 15))
		assert (snap.downgrade_start_rank == (0 if tier == RankSettleLogic.TIER_MIN else 41))
		var layout: RankListLayout = RankListLayout.new()
		for has_podium: bool in [false, true]:
			layout.build(snap, has_podium, 0.0, 0.0)
			var banners: Array[Dictionary] = layout.entries.filter( func(entry: Dictionary) -> bool: return entry.rank == -1)
			assert (banners.size() == (1 if tier == RankSettleLogic.TIER_MIN or tier == RankSettleLogic.TIER_MAX else 2))
			for banner: Dictionary in banners:
				assert (tier != RankSettleLogic.TIER_MIN or banner.kind != RankZoneBanner.Kind.DOWNGRADE)
				assert (tier != RankSettleLogic.TIER_MAX or banner.kind != RankZoneBanner.Kind.UPGRADE)
		assert (RankSettleLogic.compute_tier_after(50, tier, snap.upgrade_end_rank, snap.downgrade_start_rank) == maxi(tier - 1, RankSettleLogic.TIER_MIN))
		assert (RankSettleLogic.compute_tier_after(1, tier, snap.upgrade_end_rank, snap.downgrade_start_rank) == mini(tier + 1, RankSettleLogic.TIER_MAX))
		assert (RankEncourageRule.should_show_finish_word(41, 40, snap.upgrade_end_rank, snap.downgrade_start_rank) == (tier != RankSettleLogic.TIER_MIN))
		assert (RankEncourageRule.should_show_finish_word(16, 15, snap.upgrade_end_rank, snap.downgrade_start_rank) == (tier != RankSettleLogic.TIER_MAX))
		var rolled: RankSnapshot = RankSnapshotBuilder.build_rolled_back(snap, 1)
		assert (rolled.upgrade_end_rank == snap.upgrade_end_rank and rolled.downgrade_start_rank == snap.downgrade_start_rank)


func _test_reward_gift_connections() -> void :
	for path: String in ["rank/rank_page", "rank_game_finish/rank_game_finish_page"]:
		var page: Control = load("res://scripts/main/pages/%s.tscn" % path).instantiate()
		add_child(page)
		assert ( await page.prepare_content( func() -> bool: return true))
		var list: RankListView = page._list
		assert ( await list.prepare_first_screen(_finish_snapshot(1), 1, func() -> bool: return true))
		var tooltip: RankRewardTooltip = page._reward_tooltip
		for rank: int in range(1, 4):
			var item: RankItemView = list.podium._cards[rank - 1] if list.podium != null else list.row_node_at(list.row_index_of_rank(rank))
			var button: TextureButton = item.get_node("GiftButton")
			button.pressed.emit()
			assert (tooltip.visible, "Gift press must reach the page reward tooltip: %s/%d" % [path, rank])
			var reward: Dictionary = RankManager.get_reward_preview(rank)
			assert (tooltip._hint_count.text == "x%d" % int(reward.hint))
			assert (tooltip._coin_count.text == "x%d" % int(reward.coin))
			(tooltip.get_node("Catcher") as Button).pressed.emit()
			await get_tree().create_timer(0.31).timeout
			assert ( not tooltip.visible)
			button.pressed.emit()
			assert (tooltip.visible, "Gift tooltip must reopen after dismissal")
			tooltip.hide_tooltip()
		page._on_hide()
		page.free()


func _first_digit_center_y(label: Label) -> float:
	var font_size: int = label.get_theme_font_size("font_size")
	var line: TextLine = TextLine.new()
	line.add_string(label.text, label.get_theme_font("font"), font_size, TranslationServer.get_locale())
	var ts: TextServer = TextServerManager.get_primary_interface()
	var baseline: float = label.global_position.y + (label.size.y - line.get_size().y) * 0.5 + line.get_line_ascent()
	for glyph: Dictionary in ts.shaped_text_get_glyphs(line.get_rid()):
		if glyph.start == 0:
			var offset: Vector2 = ts.font_get_glyph_offset(glyph.font_rid, Vector2i(font_size, 0), glyph.index)
			var size: Vector2 = ts.font_get_glyph_size(glyph.font_rid, Vector2i(font_size, 0), glyph.index)
			return baseline + glyph.offset.y + offset.y + size.y * 0.5
	assert (false, "Missing first digit")
	return 0.0


func _test_rank_introduction_layout() -> void :
	var original_locale: String = TranslationServer.get_locale()
	var dialog: RankIntroductionDialog = load("res://scripts/main/dialogs/rank_introduction/rank_introduction_dialog.tscn").instantiate()
	add_child(dialog)
	for locale: String in TranslationServer.get_loaded_locales():
		TranslationServer.set_locale(locale)
		dialog._fit_all_text()
		dialog._snap_groups_final()
		await get_tree().process_frame
		for label: Label in [dialog._line1, dialog._line2, dialog._line3]:
			var paragraph: = TextParagraph.new()
			paragraph.width = label.offset_right - label.offset_left
			paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
			paragraph.add_string(tr(label.text), label.get_theme_font("font"), 
				label.get_theme_font_size("font_size"), TranslationServer.get_locale())
			assert (paragraph.get_size().y <= label.offset_bottom - label.offset_top, 
				"Introduction text must fit its reserved region: %s/%s" % [locale, label.text])
		if dialog._line2.get_rect().end.y + 32.0 > dialog._arrow_left.position.y:
			SortLogger.info("[RankIntroLayout] locale=%s font=%d rect=%s minimum=%s offsets=%s arrow=%s lines=%d" % [
				locale, dialog._line2.get_theme_font_size("font_size"), dialog._line2.get_rect(), 
				dialog._line2.get_minimum_size(), Vector2(dialog._line2.offset_top, dialog._line2.offset_bottom), 
				dialog._arrow_left.get_rect(), dialog._line2.get_line_count()])
		assert (dialog._line2.get_rect().end.y + 32.0 <= dialog._arrow_left.position.y, 
			"Introduction arrow must stay below the complete text region: %s" % locale)
		assert ( not dialog._arrow_left.get_rect().intersects(dialog._badge_3.get_rect()))
	dialog.free()
	TranslationServer.set_locale(original_locale)


func _test_title_render_sequence() -> void :
	if DisplayServer.get_name() == "headless":
		return
	var original_locale: String = TranslationServer.get_locale()
	var scene: PackedScene = load("res://scripts/main/dialogs/rank_new_season/rank_new_season_dialog.tscn")
	var dialog: RankNewSeasonDialog = scene.instantiate()
	var other: RankNewSeasonDialog = scene.instantiate()
	add_child(dialog)
	add_child(other)
	assert (dialog._effect.material != other._effect.material)
	other.free()
	var bounds: Dictionary = {}
	for locale: String in ["en", "zh", "en", "en"]:
		TranslationServer.set_locale(locale)

		RenderingServer.frame_pre_draw.connect(dialog._on_show, CONNECT_ONE_SHOT)
		await RenderingServer.frame_post_draw
		await _wait_until( func() -> bool: return not dialog._ok_btn.disabled)
		assert (dialog._title_cache_key == TranslationServer.get_locale() + ":" + tr("RANK_NEW_SEASON_TITLE"))
		var ink: Rect2i = dialog._composite.get_texture().get_image().get_used_rect()
		assert (ink.has_area(), "A completed title cache must contain rendered text")
		if bounds.has(locale):
			assert (ink == bounds[locale])
		else:
			bounds[locale] = ink
		for viewport: SubViewport in [dialog._body, dialog._face, dialog._composite]:
			assert (viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
			assert (viewport.get_texture().get_image().get_used_rect().has_area())
		dialog._on_hide()
	assert (bounds.en != bounds.zh, "Switching language must rebuild the current text")
	TranslationServer.set_locale("zh")
	dialog._on_show()
	await get_tree().process_frame
	dialog._on_hide()
	dialog._on_show()
	await _wait_until( func() -> bool: return not dialog._ok_btn.disabled)
	assert (dialog._composite.get_texture().get_image().get_used_rect() == bounds.zh)
	dialog._on_hide()
	dialog.free()
	TranslationServer.set_locale(original_locale)


func _test_presentations() -> void :
	_reset_rank_state()
	RankManager.invalidate_snapshot()
	UserState.set_current_level(21)
	RankManager.ensure_profile()
	assert (RankManager.ensure_season())
	RankManager.mark_guide_shown()

	var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
	var fly: RankCollectFlyLayer = load("res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn").instantiate()
	add_child(bar)
	add_child(fly)
	var tracker: = RankRoundTracker.new()
	tracker.begin({}, 7, bar, fly)
	assert (tracker.commit("presentation-round"))
	var owner: = Control.new()
	add_child(owner)
	await tracker.play_collect(owner, func(_index: int) -> Vector2: return Vector2(500, 600))
	owner.queue_free()
	assert (bar.get_count() == 7 and not fly.is_flying() and not bar.visible)
	tracker.cancel()
	bar.queue_free()
	fly.queue_free()
	await _test_settlement_presentation()
	assert (RankManager.ensure_season())
	RankManager.mark_guide_shown()

	var finish: RankGameFinishPage = load(SceneManager.PAGE_SCENES.rank_game_finish).instantiate()
	add_child(finish)
	assert ( await finish.prepare_content( func() -> bool: return true))
	finish._on_show({})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	var list: RankListView = finish._list
	list.play_enter_anim()
	await get_tree().process_frame
	finish._on_hide()
	finish._on_show({})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	assert (list.modulate.a == 1.0)
	var real_me: RankItemView = list.find_my_item()
	finish._crown.play_fly_in(real_me)
	await get_tree().process_frame
	finish._crown.hide_crown()
	assert ( not finish._crown.visible and finish._crown.get_attached_item() == null)

	RankManager.invalidate_snapshot()
	var from_snap: RankSnapshot = RankManager.get_current_snapshot()
	RankManager.cheat_adjust_collect_num(99999999)
	var to_snap: RankSnapshot = RankManager.get_current_snapshot()
	list.set_snapshot(from_snap, true)
	assert ( await _prepare_test_list(list))
	list.play_rise_anim(from_snap, to_snap)
	await get_tree().create_timer(0.4).timeout
	list.cancel_animations()
	list.set_snapshot(to_snap, true)
	assert ( await _prepare_test_list(list))
	real_me = list.find_my_item()
	var displayed: int = real_me.get_collect_num_display()
	list.play_collect_anim(1)
	list.cancel_animations()
	list.set_snapshot(to_snap, true)
	assert ( await _prepare_test_list(list))
	await get_tree().create_timer(0.7).timeout
	assert (real_me.get_collect_num_display() == displayed and real_me.scale == Vector2.ONE)
	assert ( not list.get_rise_overlay_item().visible)
	await _test_finish_podium(finish)
	await _test_particle_dimensions(finish)
	await _test_source_collection(finish)
	await _test_finish_word(finish)
	await _test_finish_rise_tip(finish)
	finish._on_continue_pressed()
	assert ( not finish.visible)
	finish._on_hide()
	finish.queue_free()

	var old: Dictionary = {"done": false, "active": true}
	var new: Dictionary = {"done": false, "active": true}
	_run_leased_dialog(old)
	await _wait_until( func() -> bool:
		var dlg: Node = SceneManager.get_page("rank_new_season")
		return dlg != null and dlg.visible)
	_run_leased_dialog(new)
	await get_tree().process_frame
	old.active = false
	await _wait_until( func() -> bool: return old.done)
	var dlg: Node = SceneManager.get_page("rank_new_season")
	assert (dlg.visible)
	dlg._on_close_pressed()
	await _wait_until( func() -> bool: return new.done)
	assert ( not dlg.visible)


func _test_settlement_presentation() -> void :
	_test_upgrade_arrow_bounds()

	RankManager.cheat_adjust_collect_num(99999999)
	RankManager.cheat_set_remaining_seconds(0)
	var result: Dictionary = RankManager.check_rank_end()
	var coins: int = UserState.get_coins()
	var hints: int = UserState.get_prop_count("hint")
	var change: RankChangeDialog = load(SceneManager.PAGE_SCENES.rank_change).instantiate()
	add_child(change)
	_assert_rank_popup_animation(change)
	change._on_show(result)
	assert (is_equal_approx((change.get_node("Root/Overlay") as Control).self_modulate.a, 1.0), 
		"Settlement must apply its overlay before the first await")
	await _wait_until(change.is_action_enabled)
	await _assert_settlement_button_feedback(change)
	change._on_action_pressed()
	await _wait_until( func() -> bool: return not change.visible)
	assert (UserState.get_coins() == coins + int(result.reward_coin))
	assert (UserState.get_prop_count("hint") == hints + int(result.reward_hint))
	change._on_hide()

	change._on_show({"preview": true})
	await _wait_until(change.is_action_enabled)
	change._close()
	change._on_hide()
	change._on_show({"preview": true})
	assert (is_equal_approx((change.get_node("Root/Overlay") as Control).self_modulate.a, 1.0))
	await _wait_until(change.is_action_enabled)
	assert (change.visible)

	for reward: int in [10, 0, 10, 0]:
		change._on_hide()
		change._on_show({"preview": true, "reward_coin": reward})
		await _wait_until(change.is_action_enabled)
		await _assert_settlement_button_feedback(change)

	change._tips.text = "Line one\nLine two\nLine three\nLine four"
	await get_tree().process_frame
	change._layout_reward_area()
	await _assert_settlement_button_feedback(change)
	change._on_hide()
	change.queue_free()


func _assert_settlement_button_feedback(change: RankChangeDialog) -> void :
	var position: Vector2 = change._action_btn.position
	SceneManager.play_press_feedback(change._action_btn)
	SceneManager.play_release_feedback(change._action_btn)
	var tween: Tween = change._action_btn.get_meta(SceneManager._FEEDBACK_TWEEN_META)
	while tween.is_valid() and tween.is_running():
		await get_tree().process_frame
		assert (change._action_btn.position.is_equal_approx(position), "Button feedback must use the current reward/text layout")


func _test_upgrade_arrow_bounds() -> void :
	var effect: RankChangeEffect = load("res://scripts/gameplay/rank/view/rank_change_effect.tscn").instantiate()
	for path: String in ["Upgrade/Arrows", "Upgrade/ArrowBig", "UpgradeIdle/Arrows"]:
		var arrows: CPUParticles2D = effect.get_node(path)
		for tick: int in range(129):
			var progress: float = float(tick) / 128.0
			var scale: float = arrows.scale_amount_max
			if arrows.scale_amount_curve != null:
				scale *= arrows.scale_amount_curve.sample(progress)
			var half_height: float = arrows.texture.get_height() * scale * 0.5
			var half_emission: float = arrows.emission_rect_extents.y\
			if arrows.emission_shape == CPUParticles2D.EMISSION_SHAPE_RECTANGLE else 0.0
			var upper: float = arrows.position.y - half_emission\
			- arrows.initial_velocity_max * arrows.lifetime * progress - half_height
			var lower: float = arrows.position.y + half_emission\
			- arrows.initial_velocity_min * arrows.lifetime * progress * cos(deg_to_rad(arrows.spread)) + half_height
			assert (upper >= - RankChangeDialog.BADGE_SIZE * 0.5 and lower <= RankChangeDialog.BADGE_SIZE * 0.5, 
				"Upgrade arrow trajectory must stay around the trophy: %s (%f, %f)" % [path, upper, lower])
	effect.free()


func _test_claim_coin_hud_layout() -> void :
	var window: Window = get_window()
	var original_size: Vector2i = window.size
	var original_coins: int = UserState.get_coins()
	var original_notch: bool = SafeAreaSim.is_enabled()
	var original_top: int = SafeAreaSim.get_top_px()
	var original_bottom: int = SafeAreaSim.get_bottom_px()
	for physical_top: int in [0, 88]:
		SafeAreaSim.set_notch(physical_top, 34 if physical_top > 0 else 0)
		var home: HomePage = load(SceneManager.PAGE_SCENES.home).instantiate()
		var change: RankChangeDialog = load(SceneManager.PAGE_SCENES.rank_change).instantiate()
		add_child(home)
		add_child(change)
		_assert_rank_popup_animation(change)
		assert ( not change._coin_pill.is_in_group("_safe_top"))
		change._reward_coin = 1
		(change.get_node("Root/Content") as Control).scale = Vector2.ONE * 0.6
		for physical_size: Vector2i in [Vector2i(540, 1170), Vector2i(540, 1200), Vector2i(750, 1334), Vector2i(768, 1024)]:
			window.size = physical_size
			await get_tree().process_frame
			SceneManager._apply_safe_area("home", home)

			assert (is_equal_approx(change._coin_pill.offset_top, 20.0 + UiMetrics.safe_insets().x))
			if physical_top > 0 and DisplayServer.get_name() != "headless":
				assert (UiMetrics.safe_insets().x > 0.0)
			for coins: int in [0, 9, 99, 100, 99999999]:
				UserState.set_coins(coins)
				home.refresh_coin_hud()
				change._prepare_claim_panel(coins, 0)
				for part: String in ["", "/Pill", "/CoinIcon", "/CoinLabel"]:
					var home_part: Control = home.get_node("Root/HomeNav/CoinHud" + part)
					var claim_part: Control = change.get_node("Root/ClaimPanel/CoinPill" + part)
					assert (home_part.get_global_rect().is_equal_approx(claim_part.get_global_rect()), 
						"Home/claim coin rect differs: %s, %s, inset=%s, coins=%d" % [part, physical_size, UiMetrics.safe_insets(), coins])
				assert (home._coin_label.get_theme_font_size("font_size") == change._coin_pill_label.get_theme_font_size("font_size"))
			SortLogger.info("[RankCoinHudTest] physical=%s logical=%s inset=%s rect=%s" % [
				DisplayServer.window_get_size(), UiMetrics.viewport_size(), UiMetrics.safe_insets(), change._coin_pill.get_global_rect()])
		home.free()
		change.free()
	window.size = original_size
	UserState.set_coins(original_coins)
	if original_notch:
		SafeAreaSim.set_notch(original_top, original_bottom)
	else:
		SafeAreaSim.disable()
	await get_tree().process_frame
	SortLogger.info("[RankCoinHudTest] four aspect ratios, 0/88px safe areas, 0-8 digit values; display=%s" % DisplayServer.get_name())


func _assert_rank_popup_animation(change: RankChangeDialog) -> void :
	var shared: Animation = load("res://assets/animation/GenericPopup.res")
	var private_animation: Animation = change._anim.get_animation("GenericPopup")
	var peer: RankChangeDialog = load(SceneManager.PAGE_SCENES.rank_change).instantiate()
	var peer_player: AnimationPlayer = peer.get_node("Root/AnimationPlayer")
	assert (change._anim.get_animation_library(&"") != peer_player.get_animation_library(&""))
	assert (peer_player.get_animation("GenericPopup") == shared)
	peer.free()
	assert (private_animation != shared)
	assert (private_animation.length == shared.length)
	assert (private_animation.get_marker_time(&"Mark") == shared.get_marker_time(&"Mark"))
	assert (private_animation.get_track_count() == shared.get_track_count())
	for track: int in shared.get_track_count():
		assert (private_animation.track_get_path(track) == shared.track_get_path(track))
		assert (private_animation.track_get_key_count(track) == shared.track_get_key_count(track))
		for key: int in shared.track_get_key_count(track):
			assert (private_animation.track_get_key_time(track, key) == shared.track_get_key_time(track, key))
			assert (private_animation.track_get_key_transition(track, key) == shared.track_get_key_transition(track, key))
			if shared.track_get_path(track) == NodePath("Overlay:self_modulate") and key == 0:
				assert ((shared.track_get_key_value(track, key) as Color).a == 0.0)
				assert ((private_animation.track_get_key_value(track, key) as Color).a == 1.0)
			else:
				assert (private_animation.track_get_key_value(track, key) == shared.track_get_key_value(track, key))


func _run_leased_dialog(state: Dictionary) -> void :
	await RankSessionFlow.show_dialog({
		"owner": self, "active": func() -> bool: return bool(state.active), 
	}, "rank_new_season")
	state.done = true


func _test_finish_podium(finish: RankGameFinishPage) -> void :
	var list: RankListView = finish._list
	await _test_finish_enter_scope(list)
	assert (finish._title_label.text == tr("RANK_LEADERBOARD_TITLE"))
	assert (finish._continue_btn.btn_text == "FINISH_CONTINUE")
	assert (finish._list_area.is_in_group("_safe_top") and finish._list_area.is_in_group("_safe_bottom"))
	var source: RankSnapshot = _finish_snapshot(4)
	list.set_snapshot(source, true)
	assert ( await _prepare_test_list(list))
	assert (list.get_prepared_item_count() < 47 and list.get_visible_item_count() <= list.get_prepared_item_count())
	assert (list.row_index_of_rank(1) == -1 and list.row_index_of_rank(4) == 0)
	assert (list.row_base_y_at(0) == 24.0)
	var row_15: int = list.row_index_of_rank(15)
	assert (list._layout.entries[row_15 + 1].kind == RankZoneBanner.Kind.UPGRADE)
	list.set_scroll_vertical(list.row_base_y_at(row_15 + 1))
	assert (list.row_node_at(row_15 + 1) is RankZoneBanner)
	assert (list.row_index_of_rank(16) == row_15 + 2)
	var row_41: int = list.row_index_of_rank(41)
	assert (list._layout.entries[row_41 - 1].kind == RankZoneBanner.Kind.DOWNGRADE)
	list.set_scroll_vertical(list.row_base_y_at(row_41 - 1))
	assert (list.row_node_at(row_41 - 1) is RankZoneBanner)
	var podium: RankFinishPodium = list.podium
	assert (podium == finish._podium and podium.get_parent() == finish)
	assert (podium.is_in_group("_safe_top"))
	list.set_scroll_vertical(0.0)
	await get_tree().process_frame
	await _test_finish_scroll_bounds(finish)
	var podium_card: Control = podium.get_node("First")
	var row: Control = list.get_item_at(0)
	var card_y: float = podium_card.global_position.y
	var row_y: float = row.global_position.y
	var title_y: float = finish._title_label.global_position.y
	list.set_scroll_vertical(400.0)
	await get_tree().process_frame
	assert (is_equal_approx(podium_card.global_position.y, card_y))
	assert (is_equal_approx(row.global_position.y, row_y - 400.0))
	assert (is_equal_approx(finish._title_label.global_position.y, title_y))
	list.scroll_rank_to_center(1)
	await get_tree().process_frame
	assert (is_zero_approx(list.get_scroll_vertical()))
	assert (is_equal_approx(podium_card.global_position.y, card_y))
	assert (is_equal_approx(list.content_y_to_overlay_y(row.position.y)
		+ (list.get_node("RiseOverlay") as Control).global_position.y, row.global_position.y))
	for card: RankItemView in podium._cards:
		assert (card.get_node("Avatar").z_index == 100 and not card.get_node("Avatar").z_as_relative)
		assert (card.get_node("AvatarFrame").z_index == 101 and not card.get_node("AvatarFrame").z_as_relative)
	assert (podium._flight_layer.z_index == 102 and not podium._flight_layer.z_as_relative)
	assert (podium.get_node("Second").position.x < podium.get_node("First").position.x)
	assert (podium.get_node("First").position.x < podium.get_node("Third").position.x)
	var gift: Dictionary = {"rank": 0}
	var on_gift: = func(rank_pos: int, rect: Rect2) -> void :
		gift.rank = rank_pos
		assert (rect.size.x > 0.0 and rect.size.y > 0.0)
	list.gift_tapped.connect(on_gift)
	(podium.get_node("Second") as RankItemView)._on_gift_pressed()
	assert (gift.rank == 2)
	list.gift_tapped.disconnect(on_gift)
	for ranks: Vector2i in [Vector2i(4, 3), Vector2i(8, 3), Vector2i(3, 2), Vector2i(3, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(8, 1)]:
		source = _finish_snapshot(ranks.x)
		var destination: RankSnapshot = _finish_snapshot(ranks.y)
		list.set_snapshot(source, true)
		assert ( await _prepare_test_list(list))
		list.scroll_rank_to_center(ranks.x)
		await list.play_rise_anim(source, destination)
		var item: RankItemView = list.find_my_item()
		assert (item != null and item.podium_slot == ranks.y)
		assert (item.get_collect_num_display() == destination.my_collect_num)
		assert (item.get_node("Avatar").visible and item.get_node("AvatarFrame").visible)
		var avatar: Control = item.get_node("Avatar")
		assert (avatar.scale.is_equal_approx(Vector2.ONE * (1.05 if ranks.x > 3 else 1.0)))
		assert (podium._avatar_clones.is_empty() and podium._hidden_items.is_empty())
		assert (list.get_prepared_item_count() < 47 and list.get_visible_item_count() <= list.get_prepared_item_count())
		if ranks.y == 3:
			var fourth: RankItemView = list.row_node_at(list.row_index_of_rank(4))
			assert (fourth.get_row_key() == RankItemView.make_row_key(source.rows[2]))
			assert (fourth.position.y == list.row_base_y_at(list.row_index_of_rank(4)))

	for ranks: Vector2i in [Vector2i(4, 3), Vector2i(8, 3), Vector2i(50, 3), Vector2i(8, 1), Vector2i(8, 2)]:
		var old_rank: int = ranks.x
		list.set_snapshot(_finish_snapshot(old_rank), true)
		assert ( await _prepare_test_list(list))
		var started: int = Time.get_ticks_msec()
		list.play_rise_anim(_finish_snapshot(old_rank), _finish_snapshot(ranks.y))
		await _wait_until( func() -> bool: return list._fourth_fill_item != null)
		var elapsed: float = (Time.get_ticks_msec() - started) / 1000.0
		var plan: Dictionary = FinishMotion.build(old_rank, ranks.y)
		assert (elapsed < float(plan.winner_at))
		var fourth_fill: RankItemView = list._fourth_fill_item
		assert (fourth_fill.position.y < list._fourth_fill_y)
		assert (fourth_fill.modulate.a == 1.0 and list.get_rise_overlay_item().visible)
		assert (fourth_fill.get_row_key() == RankItemView.make_row_key(_finish_snapshot(old_rank).rows[2]))
		assert (podium._avatar_clones.is_empty())
		assert (podium._cards[2].get_node("Avatar").visible)
		assert (fourth_fill.get_node("Avatar").visible)
		list.cancel_animations()
		assert (fourth_fill.position.y == list.row_base_y_at(list.row_index_of_rank(4)))
		assert ( not fourth_fill.visible and list._fourth_fill_item == null)
		assert (podium._avatar_clones.is_empty() and podium._cards[2].get_node("Avatar").visible)


	for rank: int in [1, 2, 3]:
		list.set_snapshot(_finish_snapshot(4), true)
		assert ( await _prepare_test_list(list))
		var card: RankItemView = podium._cards[rank - 1]
		var old_key: String = card.get_row_key()
		var old_texture: Texture2D = card.get_node("Avatar").texture
		var plan: Dictionary = FinishMotion.build(4, rank)
		list.play_rise_anim(_finish_snapshot(4), _finish_snapshot(rank))
		await get_tree().create_timer(float(plan.winner_at) + 0.25).timeout
		assert (card.get_row_key() == old_key and card.get_node("Avatar").texture == old_texture)
		assert (card.get_node("Avatar").visible and podium._avatar_clones.size() == 1)
		var incoming: Control = podium._avatar_clones[0]
		assert (incoming.visible and incoming.global_position.y < card.get_avatar_global_rect().position.y)
		await get_tree().create_timer(0.3).timeout
		assert (card.get_row_key() == "me" and not card.get_node("Avatar").visible)
		assert (incoming.visible)
		list.cancel_animations()
		assert (card.get_node("Avatar").visible and podium._avatar_clones.is_empty())

	list.set_snapshot(_finish_snapshot(4), true)
	assert ( await _prepare_test_list(list))
	list.play_rise_anim(_finish_snapshot(4), _finish_snapshot(3))
	var landing_plan: Dictionary = FinishMotion.build(4, 3)
	await get_tree().create_timer(float(landing_plan.vibrate_at) + 0.06).timeout
	var board: Control = podium.get_node("Third/Bg")
	assert (board.scale.y < 1.0 and board.position.y > float(podium._landing_rest[2].Bg.position.y))
	var info: Control = podium.get_node("Third/Info")
	assert (info.position.y > float(podium._landing_rest[2].Info.position.y))
	var crown: Control = podium.get_node("Third/Crown")
	assert (crown.scale.y < 1.0 and crown.position.y > float(podium._landing_rest[2].Crown.position.y))
	assert (crown.z_index == 105 and not crown.z_as_relative)
	list.cancel_animations()
	assert (board.scale == Vector2.ONE and board.position == podium._landing_rest[2].Bg.position)
	assert (info.position == podium._landing_rest[2].Info.position)
	assert (crown.position == podium._landing_rest[2].Crown.position and crown.scale == Vector2.ONE and is_zero_approx(crown.rotation))

	for ranks: Vector2i in [Vector2i(3, 2), Vector2i(2, 1)]:
		list.set_snapshot(_finish_snapshot(ranks.x), true)
		assert ( await _prepare_test_list(list))
		var names: Array[String] = []
		for rank: int in range(ranks.y, ranks.x + 1):
			names.append((podium._cards[rank - 1].get_node("Info/Nickname") as Label).text)
		list.play_rise_anim(_finish_snapshot(ranks.x), _finish_snapshot(ranks.y))
		await get_tree().create_timer(0.5).timeout
		assert (podium._avatar_clones.size() == 2 and podium._name_clones.size() == 2)
		for index: int in names.size():
			assert ((podium._name_clones[index] as Label).text == names[index])
			assert (podium._name_clones[index].visible and podium._avatar_clones[index].visible)
			assert ( not podium._cards[ranks.y + index - 1].get_node("Avatar").visible)
			assert ( not podium._cards[ranks.y + index - 1].get_node("Info/Nickname").visible)
		list.cancel_animations()
		assert (podium._name_clones.is_empty() and podium._hidden_names.is_empty())
		for card: RankItemView in podium._cards:
			assert (card.get_node("Info/Nickname").visible and card.get_node("Avatar").visible)

	list.set_snapshot(_finish_snapshot(3), true)
	assert ( await _prepare_test_list(list))
	var old_first: String = (podium.get_node("First") as RankItemView).get_row_key()
	list.play_rise_anim(_finish_snapshot(3), _finish_snapshot(1))
	await get_tree().create_timer(0.5).timeout
	assert (podium._avatar_clones.size() == 3 and podium._name_clones.size() == 3)
	assert ((podium.get_node("First") as RankItemView).get_row_key() == old_first)
	assert ( not (podium.get_node("Third/Avatar") as Control).visible)
	list.cancel_animations()

	list.set_snapshot(_finish_snapshot(4), true)
	assert ( await _prepare_test_list(list))
	list.play_rise_anim(_finish_snapshot(4), _finish_snapshot(3))
	await get_tree().create_timer(0.65).timeout
	list.cancel_animations()
	assert (list.find_my_item().visible)
	assert ( not (list.get_rise_overlay_item().get_parent() as Control).clip_contents)
	list.set_snapshot(_finish_snapshot(2), true)
	assert ( await _prepare_test_list(list))
	await get_tree().create_timer(0.8).timeout
	assert (list.find_my_item().podium_slot == 2)

	list.set_snapshot(_finish_snapshot(3), true)
	assert ( await _prepare_test_list(list))
	list.play_rise_anim(_finish_snapshot(3), _finish_snapshot(1))
	await get_tree().create_timer(0.8).timeout
	assert ( not podium._avatar_clones.is_empty())
	list.cancel_animations()
	list.set_snapshot(_finish_snapshot(2), true)
	assert ( await _prepare_test_list(list))
	await get_tree().create_timer(0.7).timeout
	assert (list.find_my_item().podium_slot == 2)
	assert (podium._avatar_clones.is_empty() and podium._hidden_items.is_empty())
	for name: String in ["First", "Second", "Third"]:
		var card: RankItemView = podium.get_node(name)
		assert (card.get_node("Avatar").visible and card.get_node("AvatarFrame").visible)
		assert (card.get_node("Info/Nickname").visible)
		assert (card.scale == Vector2.ONE)
		assert ((card.get_node("Avatar") as Control).scale == Vector2.ONE)
		var sweep: PodiumSweepFx = card.get_node("Bg/SweepFx")
		assert ( not sweep.visible)
		for particle: Node in sweep.find_children("*", "CPUParticles2D", true, false):
			assert ( not (particle as CPUParticles2D).emitting)
	var main_row: RankItemView = load("res://scripts/gameplay/rank/view/rank_item_view.tscn").instantiate()
	assert (main_row.get_node("Avatar").size == Vector2(140, 140))
	assert (main_row.get_node("AvatarFrame").size == Vector2(169, 169))
	main_row.free()
	await _test_finish_online_style(list)


func _test_finish_enter_scope(list: RankListView) -> void :
	for rank_pos: int in [1, 2, 3, 25]:
		list.cancel_animations()
		list.set_snapshot(_finish_snapshot(rank_pos), true)
		assert ( await _prepare_test_list(list))
		list.scroll_rank_to_center(rank_pos)
		await get_tree().process_frame
		var scroll_rect: Rect2 = (list.get_node("Scroll") as ScrollContainer).get_global_rect()
		var on_screen: Array[Control] = []
		for node: Control in list._row_nodes:
			if node != null and scroll_rect.intersects(node.get_global_rect()):
				on_screen.append(node)
		assert ( not on_screen.is_empty() and on_screen.size() < 17)
		var state: Dictionary = {"done": false}
		list.begin_enter_mask()
		_wait_finish_enter(list, state)

		for node: Control in list._row_nodes:
			if node == null:
				continue
			assert (is_equal_approx(node.position.x, list.ROW_X) == not on_screen.has(node))
		await _wait_until( func() -> bool: return state.done, 1.2)
		for node: Control in list._row_nodes:
			if node == null:
				continue
			assert (is_equal_approx(node.position.x, list.ROW_X) and is_equal_approx(node.modulate.a, 1.0))
		if rank_pos <= 3:
			assert (list.find_my_item().podium_slot == rank_pos)
	list.cancel_animations()


func _wait_finish_enter(list: RankListView, state: Dictionary) -> void :
	await list.play_enter_anim()
	state.done = true


func _test_finish_scroll_bounds(finish: RankGameFinishPage) -> void :
	var scroll: ScrollContainer = finish._list_scroll
	var rect: Rect2 = scroll.get_global_rect()
	var expected_height: float = minf(finish._list_area.size.y, RankItemView.ROW_PITCH * 6.0)
	assert (is_equal_approx(rect.size.y, expected_height))
	assert (is_equal_approx(finish._continue_btn.global_position.y - rect.end.y, 80.0))
	var tip_border: Control = finish._rise_tip.get_node("Border") as Control
	assert (finish._title_label.get_global_rect().position.y - tip_border.get_global_rect().end.y >= 24.0)
	assert (is_equal_approx(rect.position.y - finish._podium.get_global_rect().end.y, 18.0))
	assert ((finish.get_node("TopBlock") as Control).z_index > finish._list_fade.z_index)
	assert (finish._list.get_parent() == finish._list_fade)
	var material: ShaderMaterial = finish._list_fade.material as ShaderMaterial
	var icon_material: ShaderMaterial = finish._list.collect_icon_fade_material
	assert (icon_material != null and icon_material != material)

	for item: RankItemView in finish._list._items:
		assert ((item.get_node("CollectIcon") as TextureRect).material == icon_material)
	for name: String in ["First", "Second", "Third"]:
		assert ((finish._podium.get_node(name + "/CollectIcon") as TextureRect).material == null)
	assert ((finish._list.get_rise_overlay_item().get_node("CollectIcon") as TextureRect).material == icon_material)
	var detail: RankListView = load("res://scripts/gameplay/rank/view/rank_list_view.tscn").instantiate()
	assert (detail.collect_icon_fade_material == null)
	detail.free()
	var viewport_height: float = UiMetrics.viewport_size().y
	assert (is_equal_approx(float(material.get_shader_parameter("top_uv")), rect.position.y / viewport_height))
	assert (is_equal_approx(float(material.get_shader_parameter("bottom_uv")), rect.end.y / viewport_height))
	assert (is_equal_approx(float(material.get_shader_parameter("fade_uv")), 64.0 / viewport_height))
	for parameter: String in ["top_uv", "bottom_uv", "fade_uv"]:
		assert (is_equal_approx(float(icon_material.get_shader_parameter(parameter)), float(material.get_shader_parameter(parameter))))

	var initial_top: float = finish._list_area.offset_top
	var initial_bottom: float = finish._list_area.offset_bottom
	finish._list_area.offset_top += 30.0
	finish._list_area.offset_bottom -= 40.0
	await get_tree().process_frame
	rect = scroll.get_global_rect()
	assert (is_equal_approx(rect.size.y, minf(finish._list_area.size.y, RankItemView.ROW_PITCH * 6.0)))
	assert (is_equal_approx(finish._continue_btn.global_position.y - rect.end.y, 80.0))
	assert (is_equal_approx(float(material.get_shader_parameter("top_uv")), rect.position.y / viewport_height))
	assert (is_equal_approx(float(material.get_shader_parameter("bottom_uv")), rect.end.y / viewport_height))
	for parameter: String in ["top_uv", "bottom_uv", "fade_uv"]:
		assert (is_equal_approx(float(icon_material.get_shader_parameter(parameter)), float(material.get_shader_parameter(parameter))))
	finish._list_area.offset_top = initial_top
	finish._list_area.offset_bottom = initial_bottom
	await get_tree().process_frame


func _test_finish_online_style(list: RankListView) -> void :
	await _test_rank_row_text_layout()
	var detail: RankItemView = load("res://scripts/gameplay/rank/view/rank_item_view.tscn").instantiate()
	add_child(detail)
	list.set_scroll_vertical(0.0)
	var finish: RankItemView = list.get_item_at(1)
	assert (finish != null)
	for key: String in [RankFakeUserGenerator.ONLINE_KEY_NOW, 
			RankFakeUserGenerator.ONLINE_KEY_MINUTES_AGO, ""]:
		var data: Dictionary = {"rank_pos": 5, "nickname": "Bot", "online_text_key": key, 
			"online_minutes": 83}
		detail.bind(data, null)
		finish.bind(data, null)
		var detail_bg: NinePatchRect = detail.get_node("Info/OnlineBg")
		var finish_bg: NinePatchRect = finish.get_node("Info/OnlineBg")
		var detail_label: Label = detail.get_node("Info/Online")
		var finish_label: Label = finish.get_node("Info/Online")
		assert (detail_bg.visible == finish_bg.visible and detail_bg.texture == finish_bg.texture)
		assert (detail_bg.size.is_equal_approx(finish_bg.size))
		assert (detail_label.visible == finish_label.visible and detail_label.text == finish_label.text)
		assert (detail_label.get_theme_font_size("font_size") == finish_label.get_theme_font_size("font_size"))
		assert (detail_label.get_theme_color("font_color") == finish_label.get_theme_color("font_color"))
	for name: String in ["First", "Second", "Third"]:
		assert ( not (list.podium.get_node(name + "/Info/Online") as Label).visible)
		assert ( not (list.podium.get_node(name + "/Info/OnlineBg") as NinePatchRect).visible)
	detail.queue_free()


func _test_rank_row_text_layout() -> void :
	var detail: RankItemView = load("res://scripts/gameplay/rank/view/rank_item_view.tscn").instantiate()
	var finish: RankItemView = load("res://scripts/gameplay/rank/view/rank_finish_item_view.tscn").instantiate()
	var clone: RankItemView = load("res://scripts/gameplay/rank/view/rank_finish_item_view.tscn").instantiate()
	add_child(detail)
	add_child(finish)
	add_child(clone)
	var original_locale: String = TranslationServer.get_locale()
	for locale: String in ["en", "zh", "ar"]:
		TranslationServer.set_locale(locale)
		for nickname: String in ["DreamCatcher", "KosmicznaHarmonia", "সবুজ_সাগর_23", "بادل_کا_بیٹا_520", 
				"亨妮_23", "ดอกไม้_23", "மலர்_23", "Player_23"]:

			for key: String in [RankFakeUserGenerator.ONLINE_KEY_NOW, 
					RankFakeUserGenerator.ONLINE_KEY_MINUTES_AGO, ""]:
				var data: Dictionary = {"rank_pos": 5, "nickname": nickname, "online_text_key": key, 
					"online_minutes": 83, "is_me": key.is_empty()}
				detail.bind(data, null)
				finish.bind(data, null)
				detail.prepare_text()
				finish.prepare_text()
				clone.clone_bind_from(finish)
				await get_tree().process_frame
				var expected_offset: float = 0.0 if key.is_empty() else -30.0
				for item: RankItemView in [detail, finish, clone]:
					var name_rect: Rect2 = item._nickname.get_global_rect()
					var avatar_center: float = item._avatar.get_global_rect().get_center().y
					SortLogger.info("[RankTextTest] locale=%s nickname=%s finish=%s online=%s height=%.1f min=%.1f center_offset=%.1f gap=%.1f" % [
						locale, nickname, item.finish_layout, not key.is_empty(), name_rect.size.y, 
						item._nickname.get_minimum_size().y, name_rect.get_center().y - avatar_center, 
						item._online_bg.get_global_rect().position.y - name_rect.end.y])
					assert (is_equal_approx(name_rect.get_center().y - avatar_center, expected_offset))
					assert (name_rect.size.y >= item._nickname.get_minimum_size().y)
					var row_height: float = 184.0 if item.finish_layout else 200.0
					assert (name_rect.position.y >= item.global_position.y)
					assert (name_rect.end.y <= item.global_position.y + row_height)
					if not key.is_empty():
						var state_rect: Rect2 = item._online_bg.get_global_rect()
						assert (state_rect.position.y - name_rect.end.y >= 8.0)
						assert (state_rect.end.y <= item.global_position.y + row_height)
						assert (item._online.get_global_rect().position.y == state_rect.position.y)
						assert (item._online.get_global_rect().size.y == state_rect.size.y)
				assert (clone._nickname.get_global_rect() == finish._nickname.get_global_rect())
				assert (clone._online_bg.get_global_rect() == finish._online_bg.get_global_rect())
	TranslationServer.set_locale(original_locale)
	detail.free()
	finish.free()
	clone.free()


func _assert_particle_dimensions(actual: Control, original: Control) -> void :
	for node: Node in original.find_children("*", "CPUParticles2D", true, false):
		var source: CPUParticles2D = node as CPUParticles2D
		var particle: CPUParticles2D = actual.get_node(original.get_path_to(source))

		assert (is_equal_approx(particle.global_transform.x.length(), source.global_transform.x.length()))
		assert (is_equal_approx(particle.global_transform.y.length(), source.global_transform.y.length()))
		var factor: float = 1.0 if particle.name in [&"Arrow", &"Flreworks_1", &"Flreworks_2"] else 0.5
		assert (is_equal_approx(particle.scale_amount_min, source.scale_amount_min * factor))
		assert (is_equal_approx(particle.scale_amount_max, source.scale_amount_max * factor))
		assert (particle.scale_amount_curve == source.scale_amount_curve)
		assert (particle.scale_curve_x == source.scale_curve_x and particle.scale_curve_y == source.scale_curve_y)


func _test_particle_dimensions(finish: Variant) -> void :
	var original: Control = load("res://scripts/gameplay/rank/view/source_fx/podium_sweep.tscn").instantiate()
	add_child(original)
	original.hide()
	var list: RankListView = finish._list
	list.set_snapshot(_finish_snapshot(5), true)
	assert ( await _prepare_test_list(list))
	for card: RankItemView in list.podium._cards:
		var sweep: PodiumSweepFx = card.get_node("Bg/SweepFx")

		for repeat: int in 2:
			sweep.play(list, card.podium_slot, list.animation_generation)
			await get_tree().create_timer(0.35).timeout
			_assert_particle_dimensions(sweep._source, original)
			for name: String in ["Flreworks_1", "Flreworks_2"]:
				var particle: CPUParticles2D = sweep._source.get_node("EffectFlreworks/" + name)
				var source: CPUParticles2D = original.get_node("EffectFlreworks/" + name)
				assert (is_equal_approx((particle.position.y - source.position.y) * sweep._source.scale.y, 200.0))
			assert (sweep._range.clip_contents)
			assert (sweep._range.position.is_equal_approx(sweep.size * sweep.sweep_region.position))
			assert (sweep._range.size.is_equal_approx(sweep.size * sweep.sweep_region.size))
			assert (sweep._glow.scale.y * sweep._glow.texture.get_height() <= sweep.size.y * sweep.sweep_thickness + 0.001)
			for node: Node in sweep._source.get_node("EffectRisingParticle").get_children():
				var point: Vector2 = sweep.get_global_transform().affine_inverse() * (node as CPUParticles2D).global_position
				assert (Rect2(Vector2.ZERO, sweep.size).has_point(point))
			assert (sweep.z_index == 10)
			sweep.stop()


		var source_glow: Sprite2D = sweep._source.get_node("Rank%d/Podium/PodiumMask/Glow" % card.podium_slot)
		for time: float in [0.0, 0.375, sweep.VISIBLE_SEC]:
			sweep._player.play("Sweep%d" % card.podium_slot)
			sweep._player.pause()
			sweep._player.seek(time, true)
			sweep._sample_glow(source_glow, time, Color(1, 1, 1, 0.588), 1.85)
			var half_height: float = sweep._glow.texture.get_height() * sweep._glow.scale.y * 0.5
			if time == 0.0:
				assert (sweep._glow.position.y - half_height >= sweep._range.size.y - 0.001)
			elif time == sweep.VISIBLE_SEC:
				assert (sweep._glow.position.y + half_height <= 0.001)
			else:
				assert (sweep._glow.modulate.a > 0.0)
				assert (half_height * 2.0 > sweep.size.y)
			sweep.stop()
	original.queue_free()
	var row_original: Control = load("res://scripts/gameplay/rank/view/source_fx/rank_cell_particles.tscn").instantiate()
	var row_fx: RankRowSourceFx = load("res://scripts/gameplay/rank/view/rank_row_source_fx.tscn").instantiate()
	add_child(row_original)
	row_original.hide()
	add_child(row_fx)
	assert (row_fx._arrow.texture.resource_path.ends_with("finish_up.png"))
	for row_size: Vector2 in [Vector2(984, 184), Vector2(970, 180), Vector2(1200, 240), Vector2(984, 184)]:
		row_fx.fit_row(row_size)
		_assert_particle_dimensions(row_fx._source, row_original)
	row_fx.queue_free()
	row_original.queue_free()
	list.cancel_animations()


func _test_source_collection(finish: Variant) -> void :
	var list: RankListView = finish._list
	var original: Control = load("res://scripts/gameplay/rank/view/source_fx/rank_change_collection.tscn").instantiate()
	add_child(original)
	original.hide()
	var pool: RankCollectElementPool = load("res://scripts/gameplay/rank/view/rank_collect_element_pool.tscn").instantiate()
	add_child(pool)
	for rank: int in [1, 2, 3, 4, 5]:
		var count: int = 3 if rank == 1 else 6
		list.set_snapshot(_finish_snapshot(rank), true)
		assert ( await _prepare_test_list(list))
		var me: RankItemView = list.find_my_item()
		RankListCollectAnim.play(list, list._collect_source_fx, me, pool.get_texture(), count, 10, 10 + count)
		await get_tree().create_timer(0.5).timeout
		var fx: RankSourceCollectionFx = list._collect_source_fx
		assert (fx.top_level and fx.get_parent() == me)
		assert ( not fx.z_as_relative)
		var podium_z: int = _effective_canvas_z(finish._podium)
		for node: Node in finish._podium.find_children("*", "CanvasItem", true, false):
			if node == fx or fx.is_ancestor_of(node):
				continue
			podium_z = maxi(podium_z, _effective_canvas_z(node as CanvasItem))
		for node: CanvasItem in fx._sprites:
			_assert_unclipped_collection(node)
			assert (_effective_canvas_z(node) > podium_z, "Flying collectibles must draw above the entire podium")
		for node: CanvasItem in fx._particles:
			_assert_unclipped_collection(node)
			assert (_effective_canvas_z(node) > podium_z)

		var original_position: Vector2 = me.position
		var original_scale: Vector2 = me.scale
		var relative: Transform2D = me.get_global_transform().affine_inverse() * fx.global_transform
		me.position += Vector2(0, -80)
		me.scale = Vector2.ONE * 1.05
		await get_tree().process_frame
		await get_tree().process_frame
		assert (fx.global_transform.is_equal_approx(me.get_global_transform() * relative))
		me.position = original_position
		me.scale = original_scale
		await get_tree().process_frame
		await get_tree().process_frame
		_assert_particle_dimensions(list._collect_source_fx._source, original)
		for sprite: Sprite2D in list._collect_source_fx._sprites:
			if sprite.modulate.a > 0.0:
				var half_width: float = sprite.texture.get_width() * absf(sprite.global_scale.x) * 0.5
				assert (sprite.global_position.x - half_width >= 0.0)
				assert (sprite.global_position.x + half_width <= UiMetrics.viewport_size().x)
		await get_tree().create_timer(1.3).timeout
		assert (me.get_collect_num_display() == 10 + count)
		assert (list._collect_source_fx.get_fly_count() == 6)
		assert (list._collect_source_fx.get_parent() == me)
		assert (list._collect_source_fx._sprites[0].texture == pool.get_texture())
		list.cancel_animations()
		assert ( not list._collect_source_fx.visible)
		assert ( not fx.is_processing() and fx._follow_item == null)
		assert (fx.get_parent() == list and fx.position == Vector2.ZERO)

	list.set_snapshot(_finish_snapshot(5), true)
	assert ( await _prepare_test_list(list))
	var tail_receiver: RankItemView = list.find_my_item()
	await RankListCollectAnim.play(list, list._collect_source_fx, tail_receiver, pool.get_texture(), 6, 10, 16)
	var tail_transform: Transform2D = list._collect_source_fx.global_transform
	list.set_snapshot(_finish_snapshot(3), true)
	assert (list._collect_source_fx.get_parent() == list.find_my_item())
	assert (list._collect_source_fx._follow_item == list.find_my_item())
	assert (list._collect_source_fx.global_transform.is_equal_approx(tail_transform))
	list.cancel_animations()

	list.set_snapshot(_finish_snapshot(5), true)
	assert ( await _prepare_test_list(list))
	var me: RankItemView = list.find_my_item()
	RankListCollectAnim.play(list, list._collect_source_fx, me, pool.get_texture(), 6, 100, 106)
	await get_tree().create_timer(0.25).timeout
	list.cancel_animations()
	me.set_collect_num_display(999)
	await get_tree().create_timer(1.8).timeout
	assert (me.get_collect_num_display() == 999 and not list._collect_source_fx.visible)
	pool.queue_free()
	original.queue_free()


func _effective_canvas_z(node: CanvasItem) -> int:
	var result: int = 0
	var current: CanvasItem = node
	while current != null:
		result += current.z_index
		if not current.z_as_relative:
			break
		current = current.get_parent() as CanvasItem
	return result


func _assert_unclipped_collection(node: CanvasItem) -> void :
	var ancestor: Node = node
	while ancestor != null:
		if ancestor is Control:
			assert ( not (ancestor as Control).clip_contents and not ancestor is ScrollContainer)
		if ancestor is CanvasItem and (ancestor as CanvasItem).top_level:
			return
		ancestor = ancestor.get_parent()
	assert (false, "Collection flight must stop inheriting clipping before the scroll list")


func _test_finish_word(finish: RankGameFinishPage) -> void :
	for row: Array in [
		[30, 25, false], [30, 24, true], [41, 40, true], [45, 41, false], 
		[16, 15, true], [20, 16, false], [4, 3, true], [3, 3, true], 
		[3, 2, true], [1, 1, true], [1, 2, false], [2, 3, false], [3, 4, false], 
		[10, 10, false], [0, 2, false], [51, 1, false], [1, 0, false], 
	]:
		assert (RankEncourageRule.should_show_finish_word(row[0], row[1], 15, 41) == row[2])
	assert (RankEncourageRule.should_show_finish_word(17, 16, 6, 17))
	assert (RankEncourageRule.should_show_finish_word(7, 6, 6, 17))
	assert ( not RankEncourageRule.should_show_finish_word(16, 15, 6, 17))
	assert ( not RankEncourageRule.should_show_finish_word(16, 15, 0, 0))
	assert ( not finish._encourage_word.visible)
	assert (finish._encourage_word.z_index > finish._crown.z_index)
	var spine: SpineSprite = finish._encourage_spine
	var data: SpineSkeletonDataResource = spine.skeleton_data_res
	var skins: Array[String] = []
	for skin: SpineSkin in data.get_skins():
		skins.append(skin.get_name())
	assert (skins == RankGameFinishPage.ENCOURAGE_SKINS)
	var duration: float = data.find_animation(RankGameFinishPage.ENCOURAGE_ANIMATION).get_duration()
	assert (is_equal_approx(duration, 1.2))
	var from_snap: RankSnapshot = _finish_snapshot(8)
	var to_snap: RankSnapshot = _finish_snapshot(2)
	finish.show()
	for result: Dictionary in [{"rank_before": 1, "rank_after": 2}, {"rank_before": 30, "rank_after": 25}]:
		finish._play_encourage_word(result, from_snap, to_snap, finish._generation)
		assert ( not finish._encourage_word.visible and not finish._confetti.visible)
	finish._play_encourage_word({}, null, null, finish._generation)
	assert ( not finish._encourage_word.visible)
	for skin: String in skins:
		finish._set_encourage_skin(skin)
		assert (spine.get_skeleton().get_skin().get_name() == skin)
		assert (is_zero_approx(spine.get_animation_state().get_current(0).get_track_time()))
		var text: Rect2 = finish._encourage_bounds[skin]["text"]
		var full: Rect2 = finish._encourage_bounds[skin]["full"]
		assert (full.size.x > text.size.x and text.has_area())
		var text_center: Vector2 = spine.global_transform * text.get_center()
		assert (text_center.is_equal_approx(UiMetrics.viewport_size() * 0.5))
		assert (is_equal_approx(spine.scale.x, spine.scale.y) and spine.scale.x <= RankGameFinishPage.ENCOURAGE_SCALE, 
			"Spine scale must respect the page limit: skin=%s scale=%s full=%s" % [skin, spine.scale, full])
		assert (full.size.x * spine.scale.x <= UiMetrics.viewport_size().x - 80.0)
	var seen: Dictionary = {}
	for sample: int in 100:
		finish._play_encourage_word({"rank_before": 30, "rank_after": 24}, from_snap, to_snap, finish._generation)
		var skin: String = spine.get_skeleton().get_skin().get_name()
		assert (skins.has(skin))
		seen[skin] = true
		assert (is_zero_approx(spine.get_animation_state().get_current(0).get_track_time()))
		assert ( not finish._confetti.visible)
	assert (seen.size() == 5)
	var tween: Tween = finish._encourage_tween
	tween.pause()
	spine.update_mode = SpineConstant.UpdateMode_Manual
	finish._apply_encourage_pose(0.5)
	assert (is_equal_approx(spine.get_animation_state().get_current(0).get_track_time(), 0.5))
	tween.custom_step(duration + RankGameFinishPage.ENCOURAGE_HOLD_SEC - 0.01)
	assert (finish._encourage_word.visible and finish._encourage_word.scale == Vector2.ONE)
	tween.custom_step(0.02)
	assert ( not finish._encourage_word.visible and finish._encourage_tween == null)
	assert (spine.get_animation_state().get_current(0) == null)
	assert (spine.update_mode == SpineConstant.UpdateMode_Manual)
	for elapsed: float in [0.1, 0.6, 1.1]:
		finish._play_encourage_word({}, from_snap, to_snap, finish._generation)
		var old_tween: Tween = finish._encourage_tween
		old_tween.pause()
		old_tween.custom_step(elapsed)
		finish._on_hide()
		assert ( not old_tween.is_valid() and not finish._encourage_word.visible)
		assert ( not finish._confetti.visible and spine.get_animation_state().get_current(0) == null)
		finish.show()
		finish._play_encourage_word({}, from_snap, to_snap, finish._generation)
		assert (finish._encourage_tween != old_tween and finish._encourage_word.visible)
		assert (is_zero_approx(spine.get_animation_state().get_current(0).get_track_time()))

	finish._play_encourage_word({}, from_snap, to_snap, finish._generation)
	tween = finish._encourage_tween
	finish._play_encourage_word({}, from_snap, to_snap, finish._generation - 1)
	assert (finish._encourage_tween == tween)
	finish._on_hide()
	assert ( not finish._encourage_word.visible and not tween.is_valid())
	finish.show()
	await _test_finish_confetti(finish, from_snap, to_snap)


func _test_finish_confetti(finish: RankGameFinishPage, from_snap: RankSnapshot, to_snap: RankSnapshot) -> void :
	var confetti: RankFinishConfetti = finish._confetti
	for row: Array in [
		[6, 3, true], [4, 3, true], [3, 2, true], [2, 1, true], 
		[1, 1, true], [2, 2, true], [3, 3, true], 
		[1, 2, false], [2, 3, false], [4, 4, false], [30, 24, false], 
		[0, 1, false], [51, 1, false], [1, 0, false], 
	]:
		assert (RankEncourageRule.should_play_top_three_confetti(row[0], row[1]) == row[2])
		finish._play_encourage_word({"rank_before": row[0], "rank_after": row[1]}, from_snap, to_snap, finish._generation)

		assert (confetti.visible == (row[2] or row[0] == 0 or row[0] == 51 or row[1] == 0))
		finish._on_hide()
		finish.show()
	var original: GPUParticles2D = load("res://scripts/main/dialogs/finish/ui/confetti_rain.tscn").instantiate()
	var particle_count: int = 0
	for index: int in confetti._emitters.size():
		var emitter: GPUParticles2D = confetti._emitters[index]
		var material: ParticleProcessMaterial = emitter.process_material as ParticleProcessMaterial
		particle_count += emitter.amount
		assert ( not emitter.visible and not emitter.emitting)
		assert (material.particle_flag_disable_z and emitter.one_shot and emitter.explosiveness == 1.0)
		assert (material != original.process_material and material != confetti._emitters[(index + 1) % 4].process_material)
		assert (is_equal_approx(emitter.lifetime, 4.0) and is_zero_approx(emitter.preprocess))
		assert (is_equal_approx(material.emission_box_extents.y, UiMetrics.viewport_size().y * 0.4))
		assert (emitter.position.x < 0.0 if index % 2 == 0 else emitter.position.x > UiMetrics.viewport_size().x)
		assert (emitter.scale.x == (1.0 if index % 2 == 0 else -1.0))
		assert ((emitter.global_transform * emitter.visibility_rect).intersects(emitter.get_viewport_rect()))
	assert (particle_count == 92)
	original.free()

	confetti.play()
	var old_tail: Tween = confetti._tail_tween
	assert (confetti._emitters[0].self_modulate.a == 0.0)
	confetti.reset()
	for frame: int in 4:
		await get_tree().process_frame
	assert ( not old_tail.is_valid())
	for emitter: GPUParticles2D in confetti._emitters:
		assert ( not emitter.visible and not emitter.emitting and emitter.self_modulate.a == 0.0)

	confetti.play()
	confetti.play()
	var current_tail: Tween = confetti._tail_tween
	for frame: int in 4:
		await get_tree().process_frame
	assert (confetti.visible and confetti._tail_tween == current_tail)
	confetti.reset()

	finish._play_encourage_word({}, from_snap, to_snap, finish._generation)
	finish._encourage_tween.pause()
	confetti._tail_tween.pause()
	for frame: int in 4:
		await get_tree().process_frame
	for emitter: GPUParticles2D in confetti._emitters:
		assert (emitter.visible and emitter.self_modulate.a == 1.0)
	finish._encourage_tween.custom_step(1.21 + RankGameFinishPage.ENCOURAGE_HOLD_SEC)
	assert ( not finish._encourage_word.visible and confetti.visible)
	confetti._tail_tween.custom_step(4.19)
	assert (confetti.visible)
	confetti._tail_tween.custom_step(0.02)
	assert ( not confetti.visible and confetti._tail_tween == null)
	finish._play_encourage_word({}, from_snap, to_snap, finish._generation)
	confetti._tail_tween.pause()
	finish._on_hide()
	finish.show()
	for frame: int in 4:
		await get_tree().process_frame
	assert ( not confetti.visible)
	for emitter: GPUParticles2D in confetti._emitters:
		assert ( not emitter.visible and not emitter.emitting and emitter.self_modulate.a == 0.0)


func _test_finish_tip_rules() -> void :
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 731
	var cases: Array[Array] = [
		[50, 1, 15, "FIRST", 10, -1], [1, 1, 15, "FIRST", 10, -1], 
		[50, 2, 15, "SECOND", 5, -1], [3, 2, 2, "SECOND", 5, -1], 
		[50, 3, 15, "THIRD", 5, -1], [4, 3, 3, "THIRD", 5, -1], 
		[16, 15, 15, "UPGRADE", 5, -1], [17, 6, 6, "UPGRADE", 5, -1], 
		[16, 15, 6, "RISE", 10, 1], [15, 14, 15, "RISE", 10, 1], 
		[50, 4, 0, "RISE", 10, 46], [50, 49, 0, "RISE", 10, 1], 
		[2, 2, 15, "NOCHANGE", 10, -1], [3, 3, 15, "NOCHANGE", 10, -1], 
		[6, 6, 6, "NOCHANGE", 10, -1], [50, 50, 0, "NOCHANGE", 10, -1], 
		[1, 2, 15, "DECLINE", 10, -1], [2, 3, 15, "DECLINE", 10, -1], 
		[20, 50, 15, "DECLINE", 10, -1], 
	]
	for row: Array in cases:
		var seen: Dictionary = {}
		for sample: int in range(300):
			var tip: Dictionary = RankEncourageRule.resolve_finish_tip(row[0], row[1], row[2], rng)
			assert (int(tip["arg"]) == int(row[5]))
			var expected: Array[String] = _finish_tip_keys(row[3], row[4])
			assert (expected.has(String(tip["key"])))
			seen[tip["key"]] = true
		assert (seen.size() == int(row[4]))
	for pair: Array in [[0, 1], [1, 0], [-1, 2], [51, 3], [50, 51]]:
		assert (String(RankEncourageRule.resolve_finish_tip(pair[0], pair[1], 15, rng)["key"]).is_empty())


func _finish_tip_keys(group: String, count: int) -> Array[String]:
	var keys: Array[String] = []
	for i: int in range(1, count + 1):
		keys.append("RANK_FINISH_%s_%02d" % [group, i])
	return keys


func _assert_finish_tip_text(finish: RankGameFinishPage, keys: Array[String], arg: int = -1) -> void :
	var expected: Array[String] = []
	for key: String in keys:
		expected.append(tr(key) % arg if arg >= 0 else tr(key))
	assert (expected.has(finish._rise_tip_text.get_parsed_text()))


func _test_finish_rise_tip(finish: RankGameFinishPage) -> void :
	_test_finish_tip_rules()
	assert (finish._rise_tip_holder.z_index > (finish.get_node("TopBlock") as Control).z_index)
	var from_snap: RankSnapshot = _finish_snapshot(8)
	var to_snap: RankSnapshot = _finish_snapshot(2)

	var tip: Dictionary = finish._resolve_finish_tip({"rank_before": 20, "rank_after": 16}, from_snap, to_snap)
	assert (_finish_tip_keys("RISE", 10).has(String(tip["key"])) and int(tip["arg"]) == 4)
	assert (_finish_tip_keys("SECOND", 5).has(String(finish._resolve_finish_tip({}, from_snap, to_snap)["key"])))
	assert (_finish_tip_keys("UPGRADE", 5).has(String(finish._resolve_finish_tip({"rank_before": 20, "rank_after": 15}, from_snap, to_snap)["key"])))
	assert (_finish_tip_keys("NOCHANGE", 10).has(String(finish._resolve_finish_tip({"rank_before": 2, "rank_after": 2}, from_snap, to_snap)["key"])))
	assert (_finish_tip_keys("DECLINE", 10).has(String(finish._resolve_finish_tip({"rank_before": 2, "rank_after": 8}, from_snap, to_snap)["key"])))
	assert (String(finish._resolve_finish_tip({}, null, null)["key"]).is_empty())
	assert (String(finish._resolve_finish_tip({}, _finish_snapshot(0), to_snap)["key"]).is_empty())
	assert (_finish_tip_keys("SECOND", 5).has(String(finish._resolve_finish_tip({"rank_before": 0, "rank_after": 51}, from_snap, to_snap)["key"])))
	await finish._show_rise_tip({"key": "", "arg": -1}, finish._generation)
	assert ( not finish._rise_tip_holder.visible)
	var previous_locale: String = TranslationServer.get_locale()
	var overflowing: Array[String] = []
	for locale: String in TranslationServer.get_loaded_locales():
		TranslationServer.set_locale(locale)
		for group: Array in [["RISE", 10], ["FIRST", 10], ["SECOND", 5], ["THIRD", 5], ["UPGRADE", 5], ["NOCHANGE", 10], ["DECLINE", 10]]:
			for key: String in _finish_tip_keys(group[0], group[1]):
				var arg: int = 49 if group[0] == "RISE" else -1
				finish._set_rise_tip_text({"key": key, "arg": arg})
				assert (tr(key) != key)
				_assert_finish_tip_text(finish, [key], arg)
				assert (finish._rise_tip_text.get_theme_font_size("normal_font_size") == 48)
				assert (finish._rise_tip_text.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
				var height: float = finish._rise_tip_text.get_content_height()
				if height > finish._rise_tip_text.size.y:
					overflowing.append("%s/%s height=%.1f available=%.1f" % [locale, key, height, finish._rise_tip_text.size.y])
	TranslationServer.set_locale(previous_locale)
	assert (overflowing.is_empty(), "Finish tip overflow: " + "; ".join(overflowing))
	finish._show_rise_tip(tip, finish._generation)
	assert (finish._rise_tip_holder.visible)
	assert (finish._rise_tip_holder.global_position.y + finish._rise_tip.position.y + finish._rise_tip.size.y < 0.0)
	await get_tree().process_frame
	finish._on_hide()
	finish._on_show({"result": {"rank_before": 30, "rank_after": 30}})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	assert (finish._rise_tip_holder.visible and finish._rise_tip.position == Vector2.ZERO)
	_assert_finish_tip_text(finish, _finish_tip_keys("NOCHANGE", 10))

	for row: Array in [[8, 1, "FIRST"], [1, 1, "FIRST"], [8, 2, "SECOND"], [8, 3, "THIRD"], [20, 15, "UPGRADE"], [20, 16, "RISE"], [2, 2, "NOCHANGE"], [3, 3, "NOCHANGE"]]:
		finish._on_show({"result": {"rank_before": row[0], "rank_after": row[1]}})
		await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
		assert (finish._rise_tip_holder.visible and finish._rise_tip.position == Vector2.ZERO)
		_assert_finish_tip_text(finish, _finish_tip_keys(row[2], 5 if row[2] in ["SECOND", "THIRD", "UPGRADE"] else 10), int(row[0]) - int(row[1]) if row[2] == "RISE" else -1)
		finish._on_continue_pressed()
		assert ( not finish._rise_tip_holder.visible and finish._rise_tip_tween == null)
	finish._on_show({"result": {"rank_before": 1, "rank_after": 2}})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	assert (finish._rise_tip_holder.visible)
	_assert_finish_tip_text(finish, _finish_tip_keys("DECLINE", 10))

	finish._on_show({"result": {"rank_before": 20, "rank_after": 16}})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	var held_text: String = finish._rise_tip_text.get_parsed_text()
	assert (finish._rise_tip_tween == null)
	await get_tree().create_timer(3.0).timeout
	assert (finish._rise_tip_holder.visible and finish._rise_tip.position == Vector2.ZERO)
	assert (finish._rise_tip_text.get_parsed_text() == held_text)
	assert ( not finish._continue_btn.disabled)
	finish._on_continue_pressed()
	assert ( not finish._rise_tip_holder.visible)
	assert (finish._rise_tip_tween == null and finish._rise_tip.position == Vector2.ZERO)
	finish._on_show({"result": {"rank_before": 20, "rank_after": 16}})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	finish._on_hide()
	finish._on_show({"result": {"rank_before": 30, "rank_after": 30}})
	await _wait_until( func() -> bool: return not finish._continue_btn.disabled)
	held_text = finish._rise_tip_text.get_parsed_text()
	await get_tree().create_timer(2.4).timeout
	assert (finish._rise_tip_holder.visible and not finish._continue_btn.disabled)
	assert (finish._rise_tip_text.get_parsed_text() == held_text)
	_assert_finish_tip_text(finish, _finish_tip_keys("NOCHANGE", 10))


func _finish_snapshot(my_rank: int) -> RankSnapshot:
	var snap: = RankSnapshot.new()
	snap.event_id = "finish-layout-test"
	snap.upgrade_end_rank = 15
	snap.downgrade_start_rank = 41
	snap.participant_count = 50
	snap.my_rank_pos = my_rank
	snap.my_collect_num = 100 - my_rank
	var bot: int = 0
	for rank_pos: int in range(1, 51):
		var is_me: bool = rank_pos == my_rank
		if not is_me:
			bot += 1
		snap.rows.append({"rank_pos": rank_pos, "is_me": is_me, 
			"nickname": "Me" if is_me else "Bot%d" % bot, 
			"avatar_index": 1 if is_me else (bot % 12) + 1, 
			"collect_num": 100 - rank_pos, 
			"online_text_key": "" if is_me else RankFakeUserGenerator.ONLINE_KEY_NOW})
	return snap


func _test_new_season() -> void :
	var scene: PackedScene = load("res://scripts/main/dialogs/rank_new_season/rank_new_season_dialog.tscn")
	var dialog: RankNewSeasonDialog = scene.instantiate()
	add_child(dialog)
	assert ( not dialog.has_node("Root/Content/Dialog/ThemeImageBig"))
	assert ( not dialog.has_node("Root/Content/Dialog/EventNameLabel"))
	assert (dialog._ok_btn.btn_text == "RANK_NEW_SEASON_GO")
	assert (dialog._bg.texture != null and dialog._title_spine.skeleton_data_res != null)
	assert ( not dialog.has_node("Root/Content/Dialog/Flowers"))
	assert ( not dialog.has_node("Root/Content/Dialog/Ribbon"))
	assert ( not dialog.has_node("Root/Content/Dialog/TitlePlate"))
	assert (is_equal_approx(dialog._title_spine.skeleton_data_res.find_animation("idle").get_duration(), 6.0))
	var original_locale: String = TranslationServer.get_locale()
	var locales: PackedStringArray = TranslationServer.get_loaded_locales()
	assert (locales.size() == 29)
	for locale: String in locales:
		TranslationServer.set_locale(locale)
		dialog._on_show()
		assert (dialog._title_spine.get_skeleton().find_slot("glow").get_attachment() == null)
		assert (dialog._tips.paragraph.get_size().y <= dialog._tips.size.y)
		assert (dialog._tips.icon_texture != null and dialog._tips.icon_rect.size == Vector2(96, 96))
		assert (dialog._body_text.layout.size() > 0)
		assert (Rect2(8, 8, 484, 120).encloses(dialog._body_text.ink_bounds))
		assert (Rect2(8, 8, 484, 120).encloses(dialog._face_text.ink_bounds))
		for item: Dictionary in dialog._body_text.layout:
			assert (item.glyph.font_rid.is_valid() and item.glyph.index != 0)
		dialog._on_hide()
		assert (dialog._composite.render_target_update_mode == SubViewport.UPDATE_DISABLED)
		assert ( not dialog._title_spine.visible and dialog._title_spine.get_animation_state().get_current(0) == null)
	TranslationServer.set_locale(original_locale)
	dialog._on_show()
	assert (dialog._title_spine.visible and dialog._ok_btn.disabled)
	for delta: float in [0.0, 0.1, 3.0, 6.0]:
		dialog._title_spine.update_skeleton(delta)
		assert (dialog._title_spine.get_skeleton().find_slot("glow").get_attachment() == null, 
			"The yellow glow must stay absent when the idle animation updates or loops")
		assert (dialog._title_spine.get_skeleton().find_slot("title").get_attachment() != null)
	assert (is_zero_approx(dialog._content.modulate.a))
	assert (is_equal_approx(dialog._bg.modulate.a, 1.0) and is_equal_approx(dialog._ok_btn.modulate.a, 1.0))
	var ink: Rect2 = dialog._body_text.ink_bounds.merge(dialog._face_text.ink_bounds)
	var slot_center: Vector2 = dialog._TITLE_SLOT_REST_RECT.get_center()\
	+ dialog._TITLE_SLOT_REST_RECT.size * dialog._title_content_scale\
	* (ink.get_center() / dialog._TITLE_CACHE_SIZE - Vector2.ONE * 0.5)
	var rest_center: Vector2 = dialog._title_spine.position + slot_center * dialog._TITLE_SCALE
	assert (rest_center.is_equal_approx(dialog._title.position + ink.get_center()))
	var mapped_cache: Vector2 = dialog._TITLE_SLOT_REST_RECT.size * dialog._title_content_scale
	assert (is_equal_approx(mapped_cache.x / dialog._TITLE_CACHE_SIZE.x, 
		mapped_cache.y / dialog._TITLE_CACHE_SIZE.y))
	assert (dialog._title_content_scale.x <= 1.0 and dialog._title_content_scale.y <= 1.0)

	for frame: int in 3:
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	assert (dialog._title_spine.visible and dialog._content.modulate.a > 0.0)
	await _wait_until( func() -> bool: return not dialog._ok_btn.disabled, 1.0)
	assert (dialog._title_spine.visible and is_equal_approx(dialog._content.modulate.a, 1.0))
	var click_position: Vector2 = dialog._ok_btn.get_global_rect().get_center()
	var motion: = InputEventMouseMotion.new()
	motion.position = click_position
	motion.global_position = click_position
	get_viewport().push_input(motion, true)
	for is_pressed: bool in [true, false]:
		var event: = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = is_pressed
		event.position = click_position
		event.global_position = click_position
		get_viewport().push_input(event, true)
	await _wait_until( func() -> bool: return not dialog.visible)
	assert (dialog.should_open_rank_on_close())

	dialog._on_show()
	dialog._on_close_pressed()
	dialog._on_show()
	assert (dialog._title_spine.get_skeleton().find_slot("glow").get_attachment() == null)
	assert (dialog._ok_btn.disabled and is_zero_approx(dialog._content.modulate.a))
	await get_tree().create_timer(0.3).timeout
	assert (dialog.visible and not dialog.should_open_rank_on_close())
	assert (dialog._title_spine.visible and dialog._content.modulate.a > 0.0)
	dialog._on_close_pressed()
	await _wait_until( func() -> bool: return not dialog.visible)
	assert ( not dialog.should_open_rank_on_close())
	dialog._on_hide()
	dialog.queue_free()


func _test_season_win_effects() -> void :
	var page: RankSeasonWinPage = load("res://scripts/main/dialogs/rank_season_win/rank_season_win_page.tscn").instantiate()
	add_child(page)
	page.visible = true
	assert (page._firework.get_script() == load("res://scripts/main/dialogs/finish/view/firework_show.gd"))
	assert (page._firework.particle_atlas != null and page._firework.star_texture != null)
	page._flags.play()
	assert (page._flags.get_animation_state().get_current(0).get_animation().get_name() == "Appear")
	for slot: SpineSlot in page._flags.get_skeleton().get_slots():
		if slot.get_data().get_name() not in RankSeasonWinFlags.FLAG_SLOTS:
			assert (slot.get_attachment() == null)
	var duration: float = page._flags.skeleton_data_res.find_animation("Appear").get_duration()
	page._flags.update_skeleton(duration + 0.01)
	page._flags.update_skeleton(0.01)
	assert (page._flags.get_animation_state().get_current(0).get_animation().get_name() == "flags_idle")
	await page._firework.prepare_pool_spread()
	page._firework.visible = true
	page._firework.play()
	assert (page._firework._pool_glows.size() == 6 and page._firework._pool_stars.size() == 6)
	page._on_hide()
	assert ( not page._flags.visible and not page._firework.visible)
	assert (page._flags.get_animation_state().get_current(0) == null)
	assert (page._firework._tweens.is_empty())
	for emitter: GPUParticles2D in page._firework._pool_stars:
		assert ( not emitter.visible and not emitter.emitting)
		assert ((emitter.process_material as ParticleProcessMaterial).particle_flag_disable_z)
	page.visible = true
	page._flags.play()
	assert (page._flags.get_animation_state().get_current(0).get_animation().get_name() == "Appear")
	page._on_hide()
	page.queue_free()


func _assert_collect_bar_layout(owner: Control, bar: RankCollectBar) -> void :

	for width: float in [1080.0, 1315.0, 1755.0]:
		owner.size = Vector2(width, 2340)
		for count: int in [0, 9, 80, 99, 100, 101, 111, 888, 999, 1000, 99999999]:
			bar.set_count(count)
			for frame: int in 2:
				await get_tree().process_frame
			var rect: Rect2 = bar._count_label.get_global_rect()
			assert (is_equal_approx(rect.end.x, width - 16.0) and rect.position.x >= 0.0)
			assert (bar._count_label.size.x >= bar._count_label.get_minimum_size().x)
			var bg: Rect2 = (bar.get_node("Bg") as Control).get_global_rect()
			assert (is_equal_approx(bg.end.x, width) and bg.position.x >= 0.0)
			bar.punch_icon()
			bar._punch_tween.pause()
			bar._punch_tween.custom_step(0.08)
			assert (is_equal_approx(bar._count_label.pivot_offset.x, bar._count_label.size.x))
			rect = bar._count_label.get_global_rect()
			assert (is_equal_approx(rect.end.x, width - 16.0) and rect.position.x >= 0.0)
			bar.reset_now()
		for delta: int in [12, 100, 999, 99999999]:
			bar.set_count(99)
			bar.float_delta(delta)
			bar._float_tween.pause()
			for frame: int in 2:
				await get_tree().process_frame
			var rect: Rect2 = bar._delta_label.get_global_rect()
			assert (is_equal_approx(rect.end.x, width - 16.0) and rect.position.x >= 0.0)
			assert (bar._delta_label.size.x >= bar._delta_label.get_minimum_size().x)
			bar.reset_now()
	await get_tree().process_frame


func _test_collect_bar() -> void :
	_reset_rank_state()
	RankManager.invalidate_snapshot()
	UserState.set_current_level(21)
	RankManager.ensure_profile()
	assert (RankManager.ensure_season())
	RankManager.mark_guide_shown()
	var owner: = Control.new()
	owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(owner)
	var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
	var fly: RankCollectFlyLayer = load("res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn").instantiate()
	owner.add_child(bar)
	owner.add_child(fly)
	bar.apply_layout(144.0)
	await _assert_collect_bar_layout(owner, bar)
	owner.size = Vector2(1080, 2340)
	var tracker: = RankRoundTracker.new()
	tracker.begin({}, 12, bar, fly)
	assert ( not bar.visible)
	assert (tracker.commit("collect-bar-round"))
	assert (RankManager.get_collect_num() == 12 and tracker.awarded == 12)
	var arrivals: Array[int] = []
	var starts: Array[int] = []
	var callback: Callable = func(index: int) -> void : arrivals.append(index)
	fly.item_arrived.connect(callback)
	var source: Callable = func(index: int) -> Vector2:
		starts.append(index)
		return Vector2(250 + index * 30, 310)
	assert ( await tracker.play_collect(owner, source))
	assert (starts.size() == 12 and arrivals.size() == 12)
	assert (bar.get_count() == 12 and not bar.visible and not bar._delta_label.visible)
	assert (bar._delta_label.text == "+12")
	assert (RankManager.get_collect_num() == 12)
	assert (tracker.commit("collect-bar-round"))
	assert ( await tracker.play_collect(owner, source))
	assert (arrivals.size() == 12 and RankManager.get_collect_num() == 12)

	for stage: String in ["slide_in", "flight", "float", "slide_out"]:
		tracker.begin({}, 3, bar, fly)
		assert (tracker.commit("collect-cancel-%s" % stage))
		var score: int = RankManager.get_collect_num()
		var state: Dictionary = {"done": false, "result": true}
		_run_collect(tracker, owner, source, state)
		if stage == "slide_in":
			await _wait_until( func() -> bool: return bar.visible and bar._slide_offset > 0.0)
		elif stage == "flight":
			await _wait_until(fly.is_flying)
		else:
			await _wait_until( func() -> bool: return bar._delta_label.visible)
			if stage == "slide_out":
				await _wait_until( func() -> bool: return not bar._delta_label.visible and bar.visible)
		tracker.cancel()
		await _wait_until( func() -> bool: return bool(state.done))
		assert ( not state.result and not bar.visible and not fly.is_flying())
		assert ( not bar._delta_label.visible and RankManager.get_collect_num() == score)
		assert ( await tracker.play_collect(owner, source))
		assert ( not bar.visible and RankManager.get_collect_num() == score)
	fly.item_arrived.disconnect(callback)
	tracker.cancel()
	owner.queue_free()

func _run_collect(tracker: RankRoundTracker, owner: Node, source: Callable, state: Dictionary) -> void :
	state.result = await tracker.play_collect(owner, source)
	state.done = true


class CollectAbortPage:
	extends RefCounted
	var visible: bool = true
	func play_rank_collect() -> bool:
		return false

func _test_collect_abort_step() -> void :
	var ctx: Dictionary = {"aborted": false, "page": CollectAbortPage.new()}
	var step: = RankCollectFlyStep.new()
	assert (step.should_run(ctx))
	await step.run(ctx)
	assert (ctx.aborted)


func _test_rank_update() -> void :
	_test_rank_update_lifecycle()
	await _test_rank_update_go()
	await _test_rank_update_home_go()
	_test_rank_update_competition()
	_test_rank_update_level_boundaries()
	_test_rank_update_online_time()
	for tier in range(1, 8):
		for seed_index in range(12):
			var event_id: String = "update_%d" % seed_index
			var old: Array[Dictionary] = RankFakeUserGenerator.generate_bots(event_id, tier, 49)
			for duration in [24 * 3600, 48 * 3600]:
				var bots: Array = old.duplicate(true)
				RankUpdateRule.configure_bots(bots, duration, event_id, tier)
				var zero: int = 0
				var low: int = 0
				var mid: int = 0
				for i in bots.size():
					var initial: int = RankFakeUserGenerator.get_collect_count_at(bots[i], 0)
					zero += 1 if initial == 0 else 0
					low += 1 if initial >= 4 and initial <= 6 else 0
					mid += 1 if initial >= 10 and initial <= 12 else 0
					assert (initial == 0 or initial in range(4, 7) or initial in range(10, 13) or initial in range(16, 21))
					var previous: int = initial
					for seconds in [30, 90, 180, 300, 600, 900, 3600, 12 * 3600, duration]:
						var current: int = RankFakeUserGenerator.get_collect_count_at(bots[i], seconds)
						assert (current >= previous)
						previous = current
					var old_final: int = RankFakeUserGenerator.get_collect_count_at(old[i], 48 * 3600)
					if previous != old_final:
						SortLogger.error("[RankUpdateEndpoint] tier=%d seed=%d i=%d old=%d new=%d old_budget=%s new_budget=%s old_first=%s new_first=%s" % [tier, seed_index, i, old_final, previous, RankFakeUserGenerator.get_collect_progress_at(old[i], 172800).collect_budget, bots[i].update_final_budget, old[i].collect_first_target, bots[i].collect_first_target])
					assert (previous == old_final, "Endpoint collect must match the same old opponent exactly")
					assert (RankFakeUserGenerator.get_collect_count_at(bots[i], duration * 2) == previous)
					var cfg: = ConfigFile.new()
					cfg.set_value("rank", "bot", bots[i])
					var restored: = ConfigFile.new()
					assert (restored.parse(cfg.encode_to_text()) == OK)
					assert (RankFakeUserGenerator.get_collect_count_at(restored.get_value("rank", "bot"), 900) == RankFakeUserGenerator.get_collect_count_at(bots[i], 900))
				assert (zero >= 3 and zero <= 5 and low >= 3 and low <= 8 and mid == 20)
	_test_rank_update_climb()
	_test_rank_update_competition_rhythm()


func _test_rank_update_lifecycle() -> void :
	_reset_rank_state()
	UserState.set_current_level(21)
	RankManager.ensure_profile()
	ABManager.rank_update.set_debug_override(0)
	assert (ABManager.rank_update.is_control_group())
	assert (RankManager.ensure_season())
	var old: Dictionary = UserState.get_rank_current_entity()
	ABManager.rank_update.set_debug_override(1)
	assert (ABManager.rank_update.is_24_hour_activity_enabled())
	assert ( not RankManager.ensure_season())
	assert (UserState.get_rank_current_entity() == old, "Switching AB cannot alter the running activity")
	for group in [1, 2]:
		_reset_rank_state()
		UserState.set_current_level(21)
		RankManager.ensure_profile()
		ABManager.rank_update.set_debug_override(group)
		assert (RankManager.ensure_season())
		var entity: Dictionary = UserState.get_rank_current_entity()
		var duration: int = (24 if group == 1 else 48) * 3600 * 1000
		assert (bool(entity.update_pending_start))
		assert (int(entity.end_time) - int(entity.start_time) == duration)
		assert (RankSnapshotBuilder.bot_elapsed_seconds(entity, int(entity.end_time) + 1000) == 0)
		assert ( not RankSnapshotBuilder.build(entity, int(entity.end_time) + 1000, "Me", 1).is_ended)
		UserState.fail_save = true
		assert ( not RankManager.activate_update_activity())
		assert (UserState.get_rank_current_entity() == entity)
		UserState.fail_save = false
		assert (RankManager.activate_update_activity())
		RankManager.mark_guide_shown()
		entity = UserState.get_rank_current_entity()
		assert ( not bool(entity.update_pending_start))
		assert (int(entity.end_time) - int(entity.start_time) == duration)
		assert (RankManager.activate_update_activity())
		assert (UserState.get_rank_current_entity() == entity)
		var bar: RankCollectBar = load("res://scripts/gameplay/rank/view/rank_collect_bar.tscn").instantiate()
		var fly: RankCollectFlyLayer = load("res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn").instantiate()
		add_child(bar)
		add_child(fly)
		var tracker: = RankRoundTracker.new()
		tracker.begin({"rank_round": {"season_id": "previous", "rank_before": 40, "score_before": 0}}, 11, bar, fly, "resume")
		assert (tracker.season_id == String(entity.event_id), "Unscored restored round must bind to the new activity")
		var prepared: Dictionary = UserState.get_rank_current_entity()
		tracker.begin({"rank_round": tracker.snapshot()}, 11, bar, fly, "resume")
		assert (UserState.get_rank_current_entity() == prepared)
		UserState.fail_save = true
		assert ( not tracker.commit("resume"))
		assert (UserState.get_rank_current_entity() == prepared)
		UserState.fail_save = false
		assert (tracker.commit("resume"))
		assert (tracker.applied and RankManager.get_collect_num() == 11)
		assert (RankManager.commit_round_score(11, 50, "resume", String(entity.event_id)).applied == false)
		var stale: Dictionary = RankManager.commit_round_score(11, 50, "stale", "previous")
		assert ( not bool(stale.applied))
		tracker.cancel()
		bar.free()
		fly.free()
		ABManager.rank_update.set_debug_override(99)
		assert ( not ABManager.rank_update.is_control_group() and not ABManager.rank_update.is_24_hour_activity_enabled() and not ABManager.rank_update.is_48_hour_activity_enabled())
	ABManager.rank_update.clear_debug_override()
	_reset_rank_state()


func _test_rank_update_competition() -> void :
	var entity: Dictionary = RankSnapshotBuilder.create_entity("competition", 1000, 86401000, 1, 49, "new_24")
	entity.update_pending_start = false
	entity.collect_num = 30
	entity.scored_round_count = 6
	entity.update_wave = {"members": [0], "start_round": 4, "next_round": 6}
	var bot: Dictionary = entity.bots[0]
	bot.collect_first_target = 10
	bot.update_original_first_target = 10
	bot.collect_start_level_id = 20
	bot.update_initial_budget = 22
	bot.update_early_budget = 22
	bot.update_floor_budget = 22
	bot.update_final_budget = 100
	var rows: Array = RankSettleLogic.build_ranked_rows(30, "Me", 1, [bot], 300)
	assert (RankUpdateRule.prepare_round(entity, rows, 300, "competition-round", 12))
	assert (bot.has("update_pending_budget"))
	var ready: int = int(bot.update_ready_seconds)
	var before: int = RankFakeUserGenerator.get_collect_count_at(bot, ready - 1)
	var after: int = RankFakeUserGenerator.get_collect_count_at(bot, ready)
	assert (after > before and after < int(entity.collect_num) + 12)
	var frozen: Dictionary = entity.duplicate(true)
	assert ( not RankUpdateRule.prepare_round(entity, rows, 301, "competition-round", 12))
	assert (entity == frozen)
	RankUpdateRule.materialize(entity.bots, ready)
	assert ( not bot.has("update_pending_budget"))
	assert (RankFakeUserGenerator.get_collect_count_at(bot, ready) == after)
	assert (RankFakeUserGenerator.get_collect_count_at(bot, 86400) <= 100)
	entity.scored_round_count = 2
	entity.update_round_id = ""
	assert (RankUpdateRule.prepare_round(entity, rows, ready, "early-round", 12))
	assert ( not bot.has("update_pending_budget"))


func _test_rank_update_climb() -> void :
	for seconds_per_round in [180, 300]:
		for duration in [24 * 3600, 48 * 3600]:
			var third_total: int = 0
			var fifth_total: int = 0
			var first_growing: int = 0
			for tier in range(1, 8):
				for seed_index in range(12):
					var entity: Dictionary = RankSnapshotBuilder.create_entity("climb_%d" % seed_index, 1000, 1000 + duration * 1000, tier, 49, "new_24" if duration == 86400 else "new_48")
					entity.update_pending_start = false
					for round_index in range(1, 6):
						entity.collect_num = round_index * 11
						var snap: RankSnapshot = RankSnapshotBuilder.build(entity, 1000 + round_index * seconds_per_round * 1000, "Me", 1)
						if round_index == 1:
							for i in entity.bots.size():
								first_growing += 1 if RankFakeUserGenerator.get_collect_count_at(entity.bots[i], seconds_per_round) > RankFakeUserGenerator.get_collect_count_at(entity.bots[i], 0) else 0
						if round_index == 3:
							third_total += snap.my_rank_pos
						if round_index == 5:
							fifth_total += snap.my_rank_pos
			SortLogger.info("[RankUpdateClimb] duration=%dh round=%ds rank3=%.2f rank5=%.2f first-growing=%.2f" % [duration / 3600, seconds_per_round, third_total / 84.0, fifth_total / 84.0, first_growing / 84.0])


func _test_rank_update_final_difficulty() -> void :
	for duration in [86400, 172800]:
		var rank_difference_total: int = 0
		var samples: int = 0
		var max_difference: int = 0
		for tier in range(1, 8):
			for seed_index in range(12):
				for rounds in [10, 30, 60, 100]:
					var event_id: String = "final_%d" % seed_index
					var old: Dictionary = RankSnapshotBuilder.create_entity(event_id, 1000, 172801000, tier, 49)
					old.bot_start_time = 1000
					var fresh: Dictionary = RankSnapshotBuilder.create_entity(event_id, 1000, 1000 + duration * 1000, tier, 49, "new_24" if duration == 86400 else "new_48")
					fresh.update_pending_start = false
					var wave: Dictionary = {}
					var before: int = 50
					for round_index in range(rounds):
						var old_seconds: int = int(float(round_index + 1) * 172799 / rounds)
						var new_seconds: int = int(float(round_index + 1) * (duration - 1) / rounds)
						var rows: Array = RankSnapshotBuilder.build(fresh, 1000 + new_seconds * 1000, "Me", 1).rows
						RankUpdateRule.prepare_round(fresh, rows, new_seconds, str(round_index), 11)
						fresh.collect_num = (round_index + 1) * 11
						fresh.scored_round_count = round_index + 1
						RankUpdateRule.materialize(fresh.bots, new_seconds + 120, true)
						old.collect_num = (round_index + 1) * 11
						var snap: RankSnapshot = RankSnapshotBuilder.build(old, 1000 + old_seconds * 1000, "Me", 1)
						var rng: = RandomNumberGenerator.new()
						rng.seed = (event_id + str(round_index)).hash()
						var catch_up: Dictionary = RankCatchUpRule.resolve(snap.rows, before, 11, rng, old.bots, old_seconds, round_index + 1, wave)
						wave = catch_up.wave
						for pick: Dictionary in catch_up.picks:
							var bot: Dictionary = old.bots[int(pick.bot_index)]
							bot.bonus = int(bot.bonus) + int(pick.bonus)
							bot.bonus_budget = int(bot.bonus_budget) + int(pick.budget_delta)
						for index: int in catch_up.growth_rounds:
							old.bots[index]["last_catch_up_growth_round"] = round_index + 1
						before = RankSnapshotBuilder.build(old, 1000 + old_seconds * 1000, "Me", 1).my_rank_pos
					var old_rank: int = RankSnapshotBuilder.build(old, 172801000, "Me", 1).my_rank_pos
					var new_rank: int = RankSnapshotBuilder.build(fresh, 1000 + duration * 1000, "Me", 1).my_rank_pos
					var difference: int = absi(old_rank - new_rank)
					rank_difference_total += difference
					max_difference = maxi(max_difference, difference)
					samples += 1
		assert (rank_difference_total / float(samples) < 0.1 and max_difference <= 2)
		SortLogger.info("[RankUpdateFinal] duration=%dh same-effort samples=%d mean-rank-diff=%.3f max=%d" % [duration / 3600, samples, rank_difference_total / float(samples), max_difference])


func _test_rank_update_go() -> void :
	for group in [0, 1, 2]:
		for first_ever: bool in [true, false]:
			_reset_rank_state()
			UserState.set_current_level(21)
			ABManager.rank_update.set_debug_override(group)
			RankManager.ensure_profile()
			RankManager.ensure_season()
			if not first_ever:
				RankManager.mark_rank_ever_played()
			var result: Dictionary = {"done": false, "rank": 0, "game": 0, "active": true}
			var ctx: Dictionary = {"owner": self, "active": func() -> bool: return bool(result.active), 
				"on_open_rank": func() -> void : result.rank += 1, 
				"on_start_game": func() -> void : result.game += 1}
			_run_rank_update_dialog(ctx, result)
			if first_ever:
				await _wait_until( func() -> bool:
					var dlg: Node = SceneManager.get_page("rank_introduction")
					return dlg != null and dlg.visible)
				SceneManager.hide_dlg("rank_introduction")
			await _wait_until( func() -> bool:
				var dlg: Node = SceneManager.get_page("rank_new_season")
				return dlg != null and dlg.visible and not dlg._ok_btn.disabled)
			var dialog: RankNewSeasonDialog = SceneManager.get_page("rank_new_season")
			dialog._on_ok_pressed()
			await _wait_until( func() -> bool: return bool(result.done))
			assert (int(result.game) == (1 if group > 0 and not first_ever else 0))
			assert (int(result.rank) == (0 if group > 0 and not first_ever else 1))
			assert ( not dialog.visible)

	for cancel: bool in [false, true]:
		_reset_rank_state()
		UserState.set_current_level(21)
		ABManager.rank_update.set_debug_override(1)
		RankManager.ensure_profile()
		RankManager.ensure_season()
		RankManager.mark_rank_ever_played()
		var result: Dictionary = {"done": false, "rank": 0, "game": 0, "active": true}
		var ctx: Dictionary = {"owner": self, "active": func() -> bool: return bool(result.active), 
			"on_open_rank": func() -> void : result.rank += 1, 
			"on_start_game": func() -> void : result.game += 1}
		_run_rank_update_dialog(ctx, result)
		await _wait_until( func() -> bool:
			var dlg: Node = SceneManager.get_page("rank_new_season")
			return dlg != null and dlg.visible and not dlg._ok_btn.disabled)
		if cancel:
			result.active = false
		else:
			SceneManager.get_page("rank_new_season")._on_close_pressed()
		await _wait_until( func() -> bool: return bool(result.done))
		assert (int(result.rank) == 0 and int(result.game) == 0)
	ABManager.rank_update.clear_debug_override()
	_reset_rank_state()


func _run_rank_update_dialog(ctx: Dictionary, result: Dictionary) -> void :
	await RankNewSeasonDialogStep.new().run(ctx)
	result.done = true


func _test_rank_update_competition_rhythm() -> void :
	var overtakes: int = 0
	var net_stalled: int = 0
	var max_stalled: int = 0
	for seed_index in range(12):
		var entity: Dictionary = RankSnapshotBuilder.create_entity("rhythm_%d" % seed_index, 1000, 86401000, 3, 49, "new_24")
		entity.update_pending_start = false
		var last_rank: int = 50
		var stalled: int = 0
		for round_index in range(20):
			var started: int = round_index * 300
			var rows: Array = RankSnapshotBuilder.build(entity, 1000 + started * 1000, "Me", 1).rows
			RankUpdateRule.prepare_round(entity, rows, started, str(round_index), 11)
			var before: int = RankSnapshotBuilder.build(entity, 1000 + (started + 300) * 1000, "Me", 1).my_rank_pos
			overtakes += 1 if before > last_rank else 0
			RankUpdateRule.materialize(entity.bots, started + 300, true)
			entity.collect_num = int(entity.collect_num) + 11
			entity.scored_round_count = round_index + 1
			var after: int = RankSnapshotBuilder.build(entity, 1000 + (started + 300) * 1000, "Me", 1).my_rank_pos
			stalled = stalled + 1 if after >= last_rank and after > 1 else 0
			entity.update_stalled_rounds = stalled
			max_stalled = maxi(max_stalled, stalled)
			net_stalled += 1 if stalled > 0 else 0
			last_rank = after
	assert (overtakes > 0)
	SortLogger.info("[RankUpdateRhythm] 12 activities x20 rounds overtakes=%d net-stalled=%d longest=%d" % [overtakes, net_stalled, max_stalled])


func _test_rank_update_home_go() -> void :
	_reset_rank_state()
	UserState.set_current_level(21)
	ABManager.rank_update.set_debug_override(1)
	RankManager.ensure_profile()
	RankManager.ensure_season()
	RankManager.mark_rank_ever_played()
	await SceneManager.warm_page_threaded("home")
	var cached: Node = SceneManager.get_page("home")
	cached.visible = false
	var home: Node = load(SceneManager.PAGE_SCENES.home).instantiate()
	home.set_script(HomeChapterProbe)
	home.probe_rank_go = true
	cached.get_parent().add_child(home)
	home.visible = true
	home.run_rank_session()
	await _wait_until( func() -> bool:
		var dlg: Node = SceneManager.get_page("rank_new_season")
		return dlg != null and dlg.visible and not dlg._ok_btn.disabled)
	SceneManager.get_page("rank_new_season")._on_ok_pressed()
	await _wait_until( func() -> bool: return not home._rank_session_running)
	assert (home.start_calls == 1 and home.rank_calls == 0)
	assert ( not home.was_session_running, "Go must release home session gate before calling shared start")
	home._on_hide()
	home.free()
	ABManager.rank_update.clear_debug_override()
	_reset_rank_state()


func _test_rank_update_level_boundaries() -> void :
	var bots: Array[Dictionary] = RankFakeUserGenerator.generate_bots("boundaries", 1, 49)
	RankUpdateRule.configure_bots(bots, 86400, "boundaries", 1)
	for bot: Dictionary in bots:
		var previous: int = 0
		var completed: int = 0
		for budget in range(1, 160):
			var progress: Dictionary = RankFakeUserGenerator._get_bot_collect_progress(bot, budget, int(bot.collect_seed))
			if int(progress.collect_num) > previous:
				completed += 1
				previous = int(progress.collect_num)
			assert (int(progress.completed_levels) == completed)
			assert (int(progress.remaining_budget) >= 0 and int(progress.remaining_budget) < int(progress.next_target))


func _test_rank_update_online_time() -> void :
	for mode: String in ["new_24", "new_48"]:
		var entity: Dictionary = RankSnapshotBuilder.create_entity("online-time", 1000, 172801000, 1, 49, mode)

		var pending: RankSnapshot = RankSnapshotBuilder.build(entity, 7201000, "Me", 1)
		for row: Dictionary in pending.rows:
			if not bool(row.is_me):
				assert (int(row.online_minutes) == 0 and row.online_text_key == RankFakeUserGenerator.ONLINE_KEY_NOW)
		entity.update_pending_start = false
		for seconds in [0, 292, 1799, 1800, 3600, 7200]:
			var snap: RankSnapshot = RankSnapshotBuilder.build(entity, 1000 + seconds * 1000, "Me", 1)
			for row: Dictionary in snap.rows:
				if bool(row.is_me):
					continue
				assert (int(row.online_minutes) <= int(seconds / 60))
				if seconds < 1800:
					assert (row.online_text_key == RankFakeUserGenerator.ONLINE_KEY_NOW)

		assert (RankSnapshotBuilder.build(entity, 172801000, "Me", 1).rows == RankSnapshotBuilder.build(entity, 180001000, "Me", 1).rows)
	var old: Dictionary = RankSnapshotBuilder.create_entity("online-time", 1000, 172801000, 1, 49)
	var snap: RankSnapshot = RankSnapshotBuilder.build(old, 1000, "Me", 1)
	var expected: Array = snap.rows.duplicate(true)
	RankFakeUserGenerator.assign_online_status(expected, 1)
	assert (snap.rows == expected)
	assert (expected.any( func(row: Dictionary) -> bool: return int(row.online_minutes) > 0))
