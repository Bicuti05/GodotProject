class_name WarmPagesStep
extends FlowStep

func get_step_name() -> String:
	return "WarmPages"


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var active: Callable = func() -> bool:
		return ctx.is_startup_active() if ctx is LauncherFlowContext else is_instance_valid(ctx.launcher)
	var page: Node = await SceneManager.prepare_page_for_display(ctx.initial_page, active)
	if page == null:
		SortLogger.error("WarmPages: 首屏准备失败 %s" % ctx.initial_page)
	if ctx is LauncherFlowContext:
		ctx.initial_page_ready = page != null
		if page == null:
			ctx.fail_startup("首屏准备失败: " + ctx.initial_page)
