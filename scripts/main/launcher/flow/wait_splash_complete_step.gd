class_name WaitSplashCompleteStep
extends FlowStep




func get_step_name() -> String:
	return "WaitSplashComplete"


func is_barrier() -> bool:
	return true


func should_run(ctx) -> bool:
	return not ctx.startup_failed if ctx is LauncherFlowContext else true


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	if ctx is LauncherFlowContext:
		if ctx.cold_start_optimized and ( not ctx.data_ready or not ctx.anchors_ready or not ctx.levels_ready or not ctx.gpu_ready):
			ctx.fail_startup("数据或 GPU 准备尚未完成")
			return
		if not ctx.initial_page_ready or not ctx.audio_ready or not ctx.finish_ready or not ctx.auth_ready:
			ctx.fail_startup("必要准备或权限尚未完成，禁止进度到 100%")
			return
		ctx.begin_stage("minimum_display", 95.0, 99.0)

	if ctx.splash_page != null and is_instance_valid(ctx.splash_page) and ctx.splash_shown_msec >= 0:
		var deadline_msec: int = ctx.splash_shown_msec + ABManager.splash_min_display_seconds.get_min_display_msec()
		var remaining_msec: int = maxi(1, deadline_msec - Time.get_ticks_msec())
		var progress: Callable = ctx.progress_callback() if ctx is LauncherFlowContext else Callable()
		while Time.get_ticks_msec() < deadline_msec:
			if ctx is LauncherFlowContext:
				if not ctx.is_startup_active():
					return
				progress.call(1.0 - float(deadline_msec - Time.get_ticks_msec()) / remaining_msec)
			await ctx.launcher.get_tree().process_frame
	if ctx is LauncherFlowContext:
		await ctx.finish_stage()
		if not ctx.is_startup_active():
			return
		ctx.begin_stage("finish", 99.0, 100.0)

	await ctx.launcher.wait_splash_complete(ctx.splash_page)
