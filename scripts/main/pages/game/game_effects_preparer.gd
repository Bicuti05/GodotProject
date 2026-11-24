class_name GameEffectsPreparer
extends RefCounted

var _groups_ready: bool = false
static var _cold_start_optimized: bool = false








const BOARD_SCENE_PATH: String = "res://scripts/gameplay/juice_sort/view/juice_board_view.tscn"

static var _startup_scene: PackedScene
static var _startup_board: JuiceBoardView
static var _startup_holder: Node
static var _startup_preparing: bool = false



var _connection_warmed: bool = false



static func prepare_startup(host: Node, active: Callable, progress: Callable = Callable(), 
		skin_id: StringName = &"default") -> bool:
	while _startup_preparing and active.call():
		await host.get_tree().process_frame
	if not active.call():
		return false
	if DisplayServer.get_name() == "headless":
		return true
	_startup_preparing = true
	var prepared: bool = await _prepare_startup(host, active, progress, skin_id)
	_startup_preparing = false
	return prepared


static func _prepare_startup(host: Node, active: Callable, progress: Callable, skin_id: StringName) -> bool:
	var base: JuiceSkinResolver = await GameSkinPreparer.prepare_resources(
		GameSkinPreparer.SKIN_CATALOG, &"default", host.get_tree(), active, "startup")
	if base == null or not active.call():
		return false
	if _startup_scene == null:
		var status: int = ResourceLoader.load_threaded_get_status(BOARD_SCENE_PATH)
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED:
			if ResourceLoader.load_threaded_request(BOARD_SCENE_PATH, "PackedScene", false) != OK:
				SortLogger.error("WarmGameEffects: Board 资源请求失败")
				return false
		while active.call() and ResourceLoader.load_threaded_get_status(BOARD_SCENE_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await host.get_tree().process_frame
		if not active.call():
			return false
		if ResourceLoader.load_threaded_get_status(BOARD_SCENE_PATH) != ResourceLoader.THREAD_LOAD_LOADED:
			SortLogger.error("WarmGameEffects: Board 资源加载失败")
			return false
		_startup_scene = ResourceLoader.load_threaded_get(BOARD_SCENE_PATH) as PackedScene
	if not is_instance_valid(_startup_holder):
		_startup_holder = Node.new()
		_startup_holder.name = "GameEffectsCache"
		host.add_child(_startup_holder)
	if not is_instance_valid(_startup_board):
		var started: int = Time.get_ticks_usec()
		_startup_board = _startup_scene.instantiate() as JuiceBoardView
		_startup_board.name = "Board"
		_startup_board.visible = false
		_startup_board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_startup_board.size = UiMetrics.viewport_size()
		_startup_holder.add_child(_startup_board)
		SortLogger.info("[StartupGpu] board_create_ms=%.2f" % ((Time.get_ticks_usec() - started) / 1000.0))
		await host.get_tree().process_frame
	if not active.call():
		return false
	var preparer: = GameEffectsPreparer.new()
	_startup_board.cold_start_optimized = _cold_start_optimized
	await preparer.run(_startup_holder, active, base, progress)
	if active.call() and skin_id != &"default":
		var resources: JuiceSkinResolver = await GameSkinPreparer.prepare_resources(
			GameSkinPreparer.SKIN_CATALOG, skin_id, host.get_tree(), active, "startup")
		if resources == null or not await prepare_mystery(_startup_board, resources, active):
			return false
	return active.call() and not preparer.should_run(null)



static func prepare_mystery(board: JuiceBoardView, skin: JuiceSkinResolver, active: Callable, 
		stage_progress: Callable = Callable(), background: bool = false) -> bool:
	var effects: JuiceMysteryRevealEffects = board.mystery_effects_for_skin(skin)
	if effects.rendered:
		SortLogger.info("[SkinPrepare] skin=%s stage=effects cache=hit" % (skin.active_skin.id if skin != null else &"default"))
		return active.call()
	var factory: Callable = Callable()
	var budgets: Array[StartupWarmupBudget] = []
	if _cold_start_optimized or background:
		factory = func(viewport: SubViewport) -> Callable:
			var budget: = StartupWarmupBudget.new(board, active)
			budgets.append(budget)
			return func(stage: String) -> bool:
				if not await budget.begin_batch(viewport, stage):
					return false
				if stage_progress.is_valid():
					stage_progress.call()
				return true
	var completed: bool = await effects.prepare_render(board, active, 
		EffectWarmupPolicy.needs_full_warmup("mystery_reveal", skin), factory)
	for budget: StartupWarmupBudget in budgets:
		budget.close()
	if completed:
		EffectWarmupPolicy.mark_rendered("mystery_reveal", active, skin)
	return completed



static func take_startup_board() -> Node:
	if _startup_preparing or not is_instance_valid(_startup_board):
		return null
	var board: JuiceBoardView = _startup_board
	_startup_board = null
	board.hide()
	if board.get_parent() != null:
		board.get_parent().remove_child(board)
	if is_instance_valid(_startup_holder):
		_startup_holder.queue_free()
	_startup_holder = null
	return board


func get_step_name() -> String:
	return "WarmGameEffects"


func should_run(_ctx) -> bool:
	return not _groups_ready or not _connection_warmed


func run(game: Node, active: Callable = Callable(), skin: JuiceSkinResolver = null, progress: Callable = Callable()) -> void :
	if _cold_start_optimized:
		await run_optimized(game, active, skin, progress)
		return
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:start" % get_step_name())
	if DisplayServer.get_name() == "headless" or (active.is_valid() and not active.call()):
		return
	var board: JuiceBoardView = game.get_node_or_null("Board") as JuiceBoardView if game != null else null
	if board == null:
		SortLogger.error("WarmGameEffects: cached game page board not found")
		return
	board.cold_start_optimized = _cold_start_optimized

	if skin == null:
		skin = board.skin_resources()
	_connection_warmed = board.is_connection_particles_warmed()
	var warm_ice: bool = EffectWarmupPolicy.needs_render("ice_unlock", skin)
	var warm_mystery: bool = not board.mystery_effects_for_skin(skin).rendered or EffectWarmupPolicy.needs_render("mystery_reveal", skin)
	var warm_connection: bool = not _connection_warmed or EffectWarmupPolicy.needs_render("connection", skin)
	var full_connection: bool = EffectWarmupPolicy.needs_full_warmup("connection", skin)
	_log_preparation_groups(warm_ice, warm_mystery, warm_connection, _connection_warmed)
	_groups_ready = not warm_ice and not warm_mystery
	if _groups_ready and not warm_connection:
		return
	var original_parent: Node = board.get_parent()
	var original_index: int = board.get_index()
	var original_visible: bool = board.visible
	var original_flowers_alpha: float = (board.get_node("FruitLayer") as CanvasItem).modulate.a
	var viewport: = SubViewport.new()
	viewport.name = "GameEffectsWarmupViewport"
	viewport.size = Vector2i(UiMetrics.viewport_size())
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	game.add_child(viewport)
	board.visible = false
	board.reparent(viewport, false)

	board.set_flowers_alpha(1.0)
	board.visible = true
	var successes: Array[String] = []
	var completed: bool = true
	if warm_ice:
		completed = await board.warm_effects_render(active, true, false, EffectWarmupPolicy.needs_full_warmup("ice_unlock", skin))
		if completed:
			successes.append("ice_unlock")
	if completed and warm_mystery:
		completed = await prepare_mystery(board, skin, active)
		if completed:
			successes.append("mystery_reveal")
	if completed and warm_connection:

		_connection_warmed = await board.warm_connection_particles_render(active, full_connection)
		completed = _connection_warmed
		if completed:
			successes.append("connection")
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:restore" % get_step_name())
	if is_instance_valid(board):
		board.visible = false
		board.set_flowers_alpha(original_flowers_alpha)
	if not is_instance_valid(board) or not is_instance_valid(original_parent):
		_connection_warmed = false
		if is_instance_valid(viewport):
			viewport.queue_free()
		return
	board.reparent(original_parent, false)
	original_parent.move_child(board, original_index)
	board.visible = original_visible
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.queue_free()
	var still_active: bool = not active.is_valid() or active.call()
	if not still_active:
		_connection_warmed = false

	if still_active:
		for group: String in successes:
			if active.is_valid() and not active.call():
				still_active = false
				_connection_warmed = false
				break
			EffectWarmupPolicy.mark_rendered(group, active, skin)
			await game.get_tree().process_frame
	_groups_ready = completed and still_active
	NativeUtilManager.set_crashlytics_key("boot_step_done", "%s:restore" % get_step_name())
static func set_startup_mode(optimized: bool) -> void :
	_cold_start_optimized = optimized


static func request_startup_resources() -> bool:
	if _startup_scene != null:
		return true
	var status: int = ResourceLoader.load_threaded_get_status(BOARD_SCENE_PATH)
	if status not in [ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED]:
		return true
	while ResourceLoader.load_threaded_get_status(BOARD_SCENE_PATH) == ResourceLoader.THREAD_LOAD_FAILED:
		ResourceLoader.load_threaded_get(BOARD_SCENE_PATH)
	return ResourceLoader.load_threaded_request(BOARD_SCENE_PATH, "PackedScene", false) == OK


func run_optimized(game: Node, active: Callable = Callable(), skin: JuiceSkinResolver = null, progress: Callable = Callable()) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:start" % get_step_name())
	if DisplayServer.get_name() == "headless" or (active.is_valid() and not active.call()):
		return
	var board: JuiceBoardView = game.get_node_or_null("Board") as JuiceBoardView if game != null else null
	if board == null:
		SortLogger.error("WarmGameEffects: cached game page board not found")
		return
	board.cold_start_optimized = _cold_start_optimized

	if skin == null:
		skin = board.skin_resources()
	_connection_warmed = board.is_connection_particles_warmed()
	var warm_ice: bool = EffectWarmupPolicy.needs_render("ice_unlock", skin)
	var warm_mystery: bool = not board.mystery_effects_for_skin(skin).rendered or EffectWarmupPolicy.needs_render("mystery_reveal", skin)
	var warm_connection: bool = not _connection_warmed or EffectWarmupPolicy.needs_render("connection", skin)
	var full_connection: bool = EffectWarmupPolicy.needs_full_warmup("connection", skin)
	_log_preparation_groups(warm_ice, warm_mystery, warm_connection, _connection_warmed)
	_groups_ready = not warm_ice and not warm_mystery
	if _groups_ready and not warm_connection:
		return
	var original_parent: Node = board.get_parent()
	var original_index: int = board.get_index()
	var original_visible: bool = board.visible
	var original_flowers_alpha: float = (board.get_node("FruitLayer") as CanvasItem).modulate.a
	var viewport: = SubViewport.new()
	viewport.name = "GameEffectsWarmupViewport"
	viewport.size = Vector2i(UiMetrics.viewport_size())
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	game.add_child(viewport)
	board.visible = false
	board.reparent(viewport, false)

	board.set_flowers_alpha(1.0)
	board.visible = true
	var guard: Callable = func() -> bool:
		return is_instance_valid(game) and game.is_inside_tree() and is_instance_valid(board)\
		and board.is_inside_tree() and ( not active.is_valid() or active.call())
	var budget: = StartupWarmupBudget.new(game, guard)
	var total: int = (3 if warm_ice else 0) + (4 if warm_mystery else 0) + (13 if warm_connection else 0)
	var work: Dictionary = {"submitted": 0, "prepared": 0}
	var checkpoint: Callable = func(stage: String) -> bool:
		if progress.is_valid():
			progress.call(0.15 + 0.75 * float(work.submitted + work.prepared) / maxi(1, total))
		if not await budget.begin_batch(viewport, stage):
			return false
		work.submitted += 1
		return true
	if progress.is_valid():
		progress.call(0.15)
	var successes: Array[String] = []
	var completed: bool = true
	if warm_ice:
		completed = await board.warm_effects_render(guard, true, false, EffectWarmupPolicy.needs_full_warmup("ice_unlock", skin), checkpoint)
		if completed:
			successes.append("ice_unlock")
	if completed and warm_mystery:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		var mystery_progress: Callable = func() -> void :
			work.submitted += 1
			if progress.is_valid():
				progress.call(0.15 + 0.75 * float(work.submitted + work.prepared) / maxi(1, total))
		completed = await prepare_mystery(board, skin, guard, mystery_progress)
		if completed:
			successes.append("mystery_reveal")
	if completed and warm_connection:
		var prepare_checkpoint: Callable = func(stage: String, force_frame: bool) -> bool:
			return await budget.begin_preparation(viewport, stage, force_frame)
		var prepare_progress: Callable = func(ratio: float) -> void :
			work.prepared = int(round(ratio * 10.0))
			if progress.is_valid():
				progress.call(0.15 + 0.75 * float(work.submitted + work.prepared) / maxi(1, total))

		completed = await board.prepare_connection_particles_spread(guard, prepare_checkpoint, prepare_progress)
		if completed:
			_connection_warmed = await board.warm_connection_particles_render(guard, full_connection, checkpoint)
		else:
			_connection_warmed = false
		completed = _connection_warmed
		if completed:
			successes.append("connection")
	budget.close()
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:restore" % get_step_name())
	if is_instance_valid(board):
		board.visible = false
		board.set_flowers_alpha(original_flowers_alpha)
	if not is_instance_valid(board) or not is_instance_valid(original_parent):
		_connection_warmed = false
		if is_instance_valid(viewport):
			viewport.queue_free()
		return
	board.reparent(original_parent, false)
	original_parent.move_child(board, original_index)
	board.visible = original_visible
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.queue_free()
	var still_active: bool = not active.is_valid() or active.call()
	if not still_active:
		_connection_warmed = false

	if still_active:
		for group: String in successes:
			if active.is_valid() and not active.call():
				still_active = false
				_connection_warmed = false
				break
			EffectWarmupPolicy.mark_rendered(group, active, skin)
			await game.get_tree().process_frame
	_groups_ready = completed and still_active
	if _groups_ready and progress.is_valid():
		progress.call(1.0)
	NativeUtilManager.set_crashlytics_key("boot_step_done", "%s:restore" % get_step_name())

func _log_preparation_groups(ice: bool, mystery: bool, connection: bool, reused: bool) -> void :
	SortLogger.info("[GameEffectsPrepare] ice=%s mystery=%s connection=%s connection_reused=%s" %
		[ice, mystery, connection, reused])
