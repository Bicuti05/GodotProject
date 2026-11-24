class_name PrivacyCmpAttStep
extends FlowStep













func get_step_name() -> String:
	return "PrivacyCmpAtt"


func is_blocking() -> bool:
	return false



func should_run(ctx) -> bool:
	return not ctx.startup_failed if ctx is LauncherFlowContext else true


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var started: int = Time.get_ticks_msec()
	var progress: Callable = ctx.report_auth_stage if ctx is LauncherFlowContext else Callable()
	await AuthManager.initialize(progress)
	if ctx is LauncherFlowContext:
		ctx.auth_ready = true
	SortLogger.info("[Startup] auth_wait_ms=%d cmp_wait=false" % (Time.get_ticks_msec() - started))
