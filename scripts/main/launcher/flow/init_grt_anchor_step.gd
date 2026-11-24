class_name InitGrtAnchorStep
extends FlowStep






func get_step_name() -> String:
	return "InitGrtAnchor"


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	if ctx.cold_start_optimized:
		await run_optimized(ctx)
		return
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())

	GrtManager.set_first_open_time_ms(NativeUtilManager.get_first_open_time_ms())
	GrtManager.ensure_all_batch_anchors()


func run_optimized(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())

	GrtManager.set_first_open_time_ms(NativeUtilManager.get_first_open_time_ms())
	if not await GrtManager.ensure_all_batch_anchors_spread(ctx.is_startup_active, ctx.progress_callback()):
		ctx.fail_startup("GRT anchor 保存失败或取消")
		return
	ctx.anchors_ready = ctx.is_startup_active()
