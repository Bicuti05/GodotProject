extends Node

var _bgm_controller: BgmSceneController = BgmSceneController.new()


const _LOGO_SCENE: PackedScene = preload("res://scripts/main/pages/logo/logo_page.tscn")

const _IOS_MAX_TOUCHES: int = 32


var _crash_logger: CrashLogger = null

func _ready() -> void :

	_crash_logger = CrashLogger.new()
	OS.add_logger(_crash_logger)
	SortLogger.info("[Startup] launcher_ready ticks_ms=%d" % Time.get_ticks_msec())
	_reset_ios_startup_touch()



	_fit_desktop_window()




	Engine.max_fps = 60
	_bgm_controller.initialize()




	SortLogger.info("[Startup] launcher_flow_begin ticks_ms=%d" % Time.get_ticks_msec())
	await LauncherFlow.run(self)





func _reset_ios_startup_touch() -> void :
	if OS.get_name() != "iOS":
		return
	for index: int in range(_IOS_MAX_TOUCHES):
		var event: = InputEventScreenTouch.new()
		event.index = index
		event.pressed = false
		event.canceled = true
		event.position = Vector2.ZERO
		Input.parse_input_event(event)
	Input.flush_buffered_events()





func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_sync_active_game_data_time()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_sync_active_game_data_time()


func _sync_active_game_data_time() -> void :
	var game_page: Node = SceneManager.get_page("game")
	if game_page == null or not (game_page is CanvasItem) or not (game_page as CanvasItem).visible:
		return
	if game_page.has_method("sync_game_data_time"):
		game_page.sync_game_data_time()




func _fit_desktop_window() -> void :
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return
	var win: Window = get_window()
	if win == null:
		return
	var usable: Rect2i = DisplayServer.screen_get_usable_rect()

	var h: int = mini(usable.size.y - 80, 1080)
	h = maxi(h, 720)
	var w: int = int(round(float(h) * 1080.0 / 2340.0))
	w = clampi(w, 360, maxi(usable.size.x - 40, 360))
	win.mode = Window.MODE_WINDOWED
	win.size = Vector2i(w, h)
	win.position = Vector2i(
		usable.position.x + (usable.size.x - w) / 2, 
		usable.position.y + (usable.size.y - h) / 2
	)






func wait_splash_complete(splash_page: SplashPage) -> void :
	if splash_page == null or not is_instance_valid(splash_page):
		return
	splash_page.force_complete()
	await splash_page.loading_complete



func on_splash_finished() -> void :
	_bgm_controller.on_splash_finished()
