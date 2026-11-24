class_name PageComponentLoader
extends RefCounted


var _page: Node
var _tree: SceneTree
var _scenes: Dictionary
var _generation: int = 0
var _active: Callable
var _can_work: Callable
var _queue: Array[String] = []
var _ready_groups: Dictionary = {}
var _failed_groups: Dictionary = {}
var _resources: Dictionary = {}
var _resource_requested_usec: Dictionary = {}
var _running: bool = false


func _init(page: Node, scenes: Dictionary) -> void :
	_page = page
	_tree = page.get_tree()
	_scenes = scenes


func set_work_permission(can_work: Callable) -> void :
	_can_work = can_work


func start(groups: Array[String], active: Callable) -> void :
	_active = active
	request_groups(groups)
	for group: String in groups:
		_failed_groups.erase(group)
		if not is_ready(group) and not _queue.has(group):
			_queue.append(group)
	if not _running and not _queue.is_empty():
		_run(_generation, active)



func request_groups(groups: Array[String]) -> void :
	var paths: PackedStringArray = []
	for group: String in groups:
		for path: String in _scenes[group].values():
			if not paths.has(path):
				paths.append(path)
	request_resources(paths)


func request_resources(paths: PackedStringArray) -> void :
	for path: String in paths:
		if _resources.has(path):
			continue
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if _resource_requested_usec.has(path) and status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE\
		and status != ResourceLoader.THREAD_LOAD_FAILED:
			continue
		_resource_requested_usec[path] = Time.get_ticks_usec()
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED:

			while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_FAILED:
				ResourceLoader.load_threaded_get(path)
			if ResourceLoader.load_threaded_request(path, "PackedScene", false) != OK:
				SortLogger.error("PageComponentLoader: 资源请求失败 %s" % path)


func ensure_resources(paths: PackedStringArray, active: Callable) -> bool:
	request_resources(paths)
	for path: String in paths:
		if not active.call():
			return false
		if _resources.has(path):
			continue
		var wait_started: int = Time.get_ticks_usec()
		while active.call() and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await _tree.process_frame
		if not active.call():
			return false
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
			SortLogger.error("PageComponentLoader: 资源加载失败 %s" % path)
			return false

		if not _resources.has(path):
			_resources[path] = ResourceLoader.load_threaded_get(path)
			var now: int = Time.get_ticks_usec()
			SortLogger.info("[PageResource] path=%s wait_ms=%.2f elapsed_ms=%.2f" % [path, 
				(now - wait_started) / 1000.0, 
				(now - int(_resource_requested_usec[path])) / 1000.0])
	return active.call()


func get_resource(path: String) -> PackedScene:
	return _resources.get(path) as PackedScene


func is_ready(group: String) -> bool:
	return bool(_ready_groups.get(group, false))


func ensure_group(group: String, active: Callable) -> bool:
	if is_ready(group):
		return active.call()
	start([group], active)
	while active.call() and not is_ready(group) and not _failed_groups.has(group):
		await _tree.process_frame
	return active.call() and is_ready(group)


func prepare_group(group: String, active: Callable) -> bool:
	cancel()
	await wait_idle()
	if not active.call():
		return false
	return await ensure_group(group, active)


func cancel() -> void :
	_generation += 1
	_queue.clear()


func wait_idle() -> void :
	while _running and is_instance_valid(_page):
		await _tree.process_frame


func _run(generation: int, active: Callable) -> void :
	_running = true
	await _tree.process_frame
	var valid: Callable = func() -> bool:
		return is_instance_valid(_page) and generation == _generation and active.call()
	while valid.call() and not _queue.is_empty():
		var group: String = _queue.pop_front()
		var started: int = Time.get_ticks_usec()
		var scenes: Dictionary = {}
		for node_path: String in _scenes[group]:
			if not valid.call():
				break
			var path: String = _scenes[group][node_path]
			if not await ensure_resources(PackedStringArray([path]), valid):
				break
			scenes[node_path] = _resources[path]
		if not valid.call():
			break
		if scenes.size() != _scenes[group].size():
			_failed_groups[group] = true
			SortLogger.error("PageComponentLoader: 组件组加载失败 %s" % group)
			continue
		if not await SceneManager.instantiate_page_components(_page, scenes, valid, true, _can_work):
			break
		if not valid.call():
			break
		_page.bind_component_group(group)
		_ready_groups[group] = true
		SortLogger.info("[PageLoad] group=%s prepare_ms=%.2f" % [group, (Time.get_ticks_usec() - started) / 1000.0])
	_running = false
	if is_instance_valid(_page) and not _queue.is_empty() and _active.call():
		_run(_generation, _active)
