class_name JuiceSkinLoader
extends RefCounted


static var selected_id: StringName = &"default"
static var _definitions: Dictionary[String, JuiceSkinDefinition] = {}
static var _requests: Dictionary[String, Dictionary] = {}
var _base: JuiceSkinDefinition
var _current: JuiceSkinDefinition
var error: String = ""

func load_skin(catalog: JuiceSkinCatalog, id: StringName, tree: SceneTree, active: Callable) -> JuiceSkinResolver:
	error = ""
	if catalog == null or not catalog.paths.has(&"default") or not catalog.paths.has(id):
		error = "皮肤未登记：%s" % id
		return null
	if _base == null:
		_base = await _load_definition(catalog.paths[&"default"], tree, active)
		if not active.call():
			return null
		error = JuiceSkinResolver.validate(_base, &"default", true)
		if not error.is_empty():
			_base = null
			return null
	var pack: JuiceSkinDefinition = _base if id == &"default" else _current
	if pack == null or pack.id != id:
		pack = await _load_definition(catalog.paths[id], tree, active)
	if not active.call():
		return null
	error = JuiceSkinResolver.validate(pack, id)
	if not error.is_empty():
		return null
	return JuiceSkinResolver.new(_base, pack)

func commit(resolver: JuiceSkinResolver) -> void :
	_current = resolver.active_skin
	selected_id = _current.id

func _load_definition(path: String, tree: SceneTree, active: Callable) -> JuiceSkinDefinition:
	if not ResourceLoader.exists(path):
		return null
	if _definitions.has(path):
		return _definitions[path] if active.call() else null
	var pending: Dictionary = _requests.get(path, {})
	if pending.is_empty():
		pending = {"done": false, "resource": null}
		_requests[path] = pending
		_load_request(path, tree, pending)

	while not pending["done"] and active.call():
		await tree.process_frame
	return pending["resource"] as JuiceSkinDefinition if active.call() else null


static func _load_request(path: String, tree: SceneTree, request: Dictionary) -> void :
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		ResourceLoader.load_threaded_get(path)
		status = ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		if ResourceLoader.load_threaded_request(path, "Resource", false) != OK:
			request["done"] = true
			_requests.erase(path)
			return
	while true:
		status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource: JuiceSkinDefinition = ResourceLoader.load_threaded_get(path) as JuiceSkinDefinition
			if resource != null:
				_definitions[path] = resource
			request["resource"] = resource
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			break
		await tree.process_frame
	request["done"] = true
	_requests.erase(path)
