class_name RouteInitialPageStep
extends FlowStep


func get_step_name() -> String:
	return "RouteInitialPage"

func should_run(ctx) -> bool:
	return ctx.is_startup_current() if ctx is LauncherFlowContext else true

func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	if ctx.initial_page.is_empty() or SceneManager.get_page(ctx.initial_page) == null:
		SortLogger.error("RouteInitialPage: 首屏目标未确定或未完成预热")
		return
	var params: Dictionary = {"source": TrackingEvents.SCR_SPLASH} if ctx.initial_page == "game" else {}
	var page: Node = SceneManager.show_page(ctx.initial_page, params)
	if page == null:
		SortLogger.error("RouteInitialPage: 首屏展示失败 %s" % ctx.initial_page)
		return
	SceneManager.hide_page("splash")
	ctx.launcher.on_splash_finished()
	NativeUtilManager.set_crashlytics_key("boot_step", "done")
