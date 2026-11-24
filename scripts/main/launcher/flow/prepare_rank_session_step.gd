class_name PrepareRankSessionStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareRankSession"

func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var active: Callable = func() -> bool:
		return ctx.is_startup_active() if ctx is LauncherFlowContext else\
		is_instance_valid(ctx.launcher) and ctx.launcher.is_inside_tree()
	if not await RankManager.prepare_startup_session(active) and ctx is LauncherFlowContext:
		ctx.fail_startup("排行榜启动准备失败")
