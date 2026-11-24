extends Node
























const DEFAULT_PORT: int = 8090
const LOCAL_CONFIG_PATH: String = "res://../.debug-server.local.cfg"
const ROUTE_PREFIX: String = "/pocketsort/api"

var _server: DebugApiServer = null

var _test_routes: DebugTestRoutes = null


func _ready() -> void :



	if not (OS.is_debug_build() or OS.has_feature("pre")):
		set_process(false)
		return

	_server = DebugApiServer.new()
	_register_default_routes()

	var port: int = _load_server_port()
	var err: int = _server.start(port)
	if err != OK:
		push_error("DebugApiServerManager: failed to start on port %d, err=%d" % [port, err])
		_server = null
		set_process(false)
		return

	print("DebugApiServerManager: routes available at http://127.0.0.1:%d%s/..." % [port, ROUTE_PREFIX])


func _process(_delta: float) -> void :
	if _server != null:
		_server.poll()


func _exit_tree() -> void :
	if _server != null:
		_server.stop()
		_server = null






func register_route(path: String, handler: Callable) -> void :
	if _server == null:
		return
	_server.register_route(_with_prefix(path), handler)


func is_running() -> bool:
	return _server != null and _server.is_running()






func _load_server_port() -> int:
	var config: = ConfigFile.new()
	var err: Error = config.load(LOCAL_CONFIG_PATH)
	if err == ERR_FILE_NOT_FOUND:
		return DEFAULT_PORT
	if err != OK:
		push_warning(
			"DebugApiServerManager: failed to load %s, using default port %d"
			%[LOCAL_CONFIG_PATH, DEFAULT_PORT]
		)
		return DEFAULT_PORT

	var raw_port: String = str(config.get_value("debug_server", "port", DEFAULT_PORT))
	if not raw_port.is_valid_int():
		push_warning(
			"DebugApiServerManager: invalid port '%s' in %s, using default port %d"
			%[raw_port, LOCAL_CONFIG_PATH, DEFAULT_PORT]
		)
		return DEFAULT_PORT

	var port: int = raw_port.to_int()
	if port < 1 or port > 65535:
		push_warning(
			"DebugApiServerManager: port %d in %s is out of range, using default port %d"
			%[port, LOCAL_CONFIG_PATH, DEFAULT_PORT]
		)
		return DEFAULT_PORT
	return port




func _register_default_routes() -> void :
	_server.register_route(_with_prefix("/ping"), _handle_ping)
	_server.register_route(_with_prefix("/routes"), _handle_routes)
	_server.register_route(_with_prefix("/version"), _handle_version)
	_server.register_route(_with_prefix("/trigger-crash"), _handle_trigger_crash)
	_server.register_route(_with_prefix("/trigger-anr"), _handle_trigger_anr)
	_server.register_route(_with_prefix("/cheat-set-active"), _handle_cheat_set_active)

	_test_routes = DebugTestRoutes.new()
	_test_routes.register_all(self)


func _handle_ping(ctx: DebugApiContext) -> void :
	ctx.set_json({"result": "pong"})


func _handle_routes(ctx: DebugApiContext) -> void :
	var routes: Array = _server.get_routes()
	routes.sort()
	ctx.set_json({"result": "success", "routes": routes})


func _handle_version(ctx: DebugApiContext) -> void :
	var info: Dictionary = Engine.get_version_info()
	ctx.set_json({
		"result": "success", 
		"godot": "%d.%d.%d" % [info.major, info.minor, info.patch], 
		"os": OS.get_name(), 
		"debug_build": OS.is_debug_build(), 
	})




func _handle_trigger_crash(ctx: DebugApiContext) -> void :
	ctx.set_json({"result": "success", "message": "Crash will be triggered in 0.1s"})
	get_tree().create_timer(0.1).timeout.connect(_actually_crash)


func _actually_crash() -> void :
	OS.crash("Triggered crash for testing via debug API")



func _handle_trigger_anr(ctx: DebugApiContext) -> void :
	ctx.set_json({"result": "success", "message": "ANR will be triggered, main thread will freeze 100s"})
	get_tree().create_timer(0.1).timeout.connect(_actually_anr)


func _actually_anr() -> void :
	OS.delay_msec(100000)





func _handle_cheat_set_active(ctx: DebugApiContext) -> void :
	if not ctx.query_params.has("active"):
		ctx.set_error("active parameter is required (0 or 1)")
		return
	var raw: String = ctx.get_query("active")
	if raw != "0" and raw != "1":
		ctx.set_error("active must be 0 or 1, got: %s" % raw)
		return
	var active: bool = raw == "1"


	var overlay: Node = get_tree().root.find_child("CheatOverlay", true, false)
	if overlay == null:
		ctx.set_error("CheatOverlay not found in scene tree (release build?)", 404)
		return
	overlay.visible = active
	ctx.set_json({
		"result": "success", 
		"active": active, 
		"message": "CheatOverlay %s" % ("shown" if active else "hidden"), 
	})



func _with_prefix(path: String) -> String:
	if not path.begins_with("/"):
		path = "/" + path
	return ROUTE_PREFIX + path
