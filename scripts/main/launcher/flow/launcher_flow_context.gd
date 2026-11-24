class_name LauncherFlowContext
extends RefCounted




const AUTH_STAGE_END_PERCENT: float = 15.0



var launcher = null


var system_locale: String = ""


var logo_page: LogoPage = null

var logo_shown_msec: int = 0
var ab_ready_msec: int = -1


var initial_page: String = ""
var initial_page_reason: String = ""


var splash_page: SplashPage = null

var splash_shown_msec: int = -1

var cold_start_optimized: bool = false
var data_ready: bool = false
var anchors_ready: bool = false
var levels_ready: bool = false
var startup_failed: bool = false

var gpu_ready: bool = false
var initial_page_ready: bool = false
var audio_ready: bool = false
var finish_ready: bool = false
var auth_ready: bool = false
var _progress_generation: int = -1
var _stage_token: int = 0
var _stage_name: String = ""
var _stage_start: float = 0.0
var _stage_end: float = 0.0


func _init(p_launcher) -> void :
	launcher = p_launcher


func begin_logo_stage(stage: String) -> void :
	_stage_token += 1
	_stage_name = stage
	SortLogger.info("[StartupGpu] stage=%s logo=true" % stage)



func is_logo_preparation_active() -> bool:
	return not startup_failed and _progress_generation < 0\
	and is_instance_valid(launcher) and launcher.is_inside_tree()\
	and is_instance_valid(logo_page) and logo_page.is_visible_in_tree()


func begin_stage(stage: String, start_percent: float, end_percent: float) -> void :
	_stage_token += 1
	_stage_name = stage
	_stage_start = start_percent
	_stage_end = end_percent
	if startup_failed:
		return
	if not is_instance_valid(splash_page):
		fail_startup("Splash 未准备成功")
		return
	if _progress_generation < 0:
		_progress_generation = splash_page.get_progress_generation()
	if not is_startup_active():
		return
	splash_page.begin_loading_stage(stage, start_percent, end_percent, _progress_generation)
	SortLogger.info("[StartupProgress] stage=%s range=%.0f..%.0f%%" % [stage, start_percent, end_percent])


func is_startup_active() -> bool:
	return is_startup_current() and splash_page.is_progress_active(_progress_generation)



func is_startup_current() -> bool:
	return not startup_failed and is_instance_valid(launcher) and launcher.is_inside_tree()\
	and is_instance_valid(splash_page) and splash_page.visible\
	and splash_page.get_progress_generation() == _progress_generation


func progress_callback() -> Callable:
	var token: int = _stage_token
	return func(ratio: float) -> void :
		if token == _stage_token and is_startup_active():
			splash_page.set_loading_progress(lerpf(_stage_start, _stage_end, clampf(ratio, 0.0, 1.0)), 
				_progress_generation)


func finish_stage() -> void :
	if not is_startup_active():
		return
	splash_page.set_loading_progress(_stage_end, _progress_generation)

	await splash_page.wait_loading_progress(_stage_end, _progress_generation)




func report_auth_stage(stage: String, completed: bool) -> void :
	if stage != "privacy" or not completed:
		return
	if _progress_generation < 0 or not is_startup_active():
		return
	splash_page.set_loading_progress(AUTH_STAGE_END_PERCENT, _progress_generation)


func fail_startup(message: String) -> void :
	if startup_failed:
		return
	startup_failed = true
	_stage_token += 1
	SortLogger.error("[StartupProgress] failed=%s reason=%s" % [_stage_name, message])
