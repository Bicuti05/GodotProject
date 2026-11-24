class_name PagePreparationCoordinator
extends RefCounted


static var cold_start_optimized: bool = false
static var _first_page_entered: bool = false
static var _background_generation: int = 0
static var _foreground_leases: Dictionary = {}


static func first_page_entered(page: Control, route: String) -> void :
	if _first_page_entered:
		return
	_first_page_entered = true
	if cold_start_optimized:
		LevelManager.first_page_entered()
	_background_generation += 1
	_prepare_other(page, "home" if route == "game" else "game", _background_generation)


static func begin_foreground() -> RefCounted:
	_background_generation += 1
	var lease: = RefCounted.new()
	_foreground_leases[lease] = true
	return lease


static func end_foreground(lease: RefCounted) -> void :
	_foreground_leases.erase(lease)


static func can_prepare_background() -> bool:
	return _foreground_leases.is_empty()


static func _prepare_other(source: Control, route: String, generation: int) -> void :
	var active: Callable = func() -> bool:
		return is_instance_valid(source) and source.is_inside_tree() and source.visible\
		and generation == _background_generation
	var can_work: Callable = func() -> bool:
		return _foreground_leases.is_empty() and is_instance_valid(source)\
		and ( not source.has_method("can_prepare_other_page") or source.can_prepare_other_page())
	await source.get_tree().process_frame
	if not active.call():
		return
	SceneManager.request_page_threaded(route)
	while active.call():
		if not await SceneManager.wait_preparation_permission(active, can_work):
			return

		var work_active: Callable = func() -> bool: return active.call() and can_work.call()
		var prepared: Node = await SceneManager.prepare_page_for_display(route, work_active, can_work, true)
		if prepared != null:
			SortLogger.info("[PagePreparation] background_ready=%s" % route)
			return
		await source.get_tree().create_timer(0.25).timeout
