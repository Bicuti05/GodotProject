class_name LoadStartupLevelsStep
extends FlowStep





func get_step_name() -> String:
	return "LoadStartupLevels"


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	if ctx.cold_start_optimized:
		await run_optimized(ctx)
		return

	NativeUtilManager.set_crashlytics_key("boot_step", "%s:init" % get_step_name())
	LevelManager.init()
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:restore_experiments" % get_step_name())
	await LevelManager.restore_cached_experiments()


func run_optimized(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", "%s:init" % get_step_name())
	if not await LevelManager.init(true):
		ctx.fail_startup("本地章节准备失败")
		return
	if not ctx.is_startup_active():
		return
	ctx.progress_callback().call(0.5)
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:restore_experiments" % get_step_name())
	await LevelManager.restore_cached_experiments()
	ctx.levels_ready = ctx.is_startup_active()
