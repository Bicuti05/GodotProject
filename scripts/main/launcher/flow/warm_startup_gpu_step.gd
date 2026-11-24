class_name WarmStartupGpuStep
extends FlowStep


func get_step_name() -> String:
	return "WarmStartupGpu"


func should_run(ctx) -> bool:
	return ctx.is_startup_active() if ctx.cold_start_optimized else ctx.is_logo_preparation_active()


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	NativeUtilManager.set_crashlytics_key("gpu_adapter", "%s | %s" % [
		RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_name()])
	NativeUtilManager.set_crashlytics_key("gl_version", RenderingServer.get_video_adapter_api_version())
	var active: Callable = ctx.is_startup_active if ctx.cold_start_optimized else ctx.is_logo_preparation_active
	var started: int = Time.get_ticks_usec()
	var skin_id: StringName = &"default"

	if ctx.initial_page in ["", "game"]:
		var preview: Dictionary = await GameSkinPreparer.preview_skin(
			LevelManager.preview_next_round_descriptor(), ctx.launcher.get_tree(), active)
		if not preview.is_empty():
			skin_id = StringName(preview["skin_id"])
	SortLogger.info("[SkinPrepare] source=startup skin=%s logo=%s" % [skin_id, not ctx.cold_start_optimized])
	if not ctx.cold_start_optimized:
		ctx.begin_logo_stage("WarmGameEffects")
	if not await GameEffectsPreparer.prepare_startup(ctx.launcher, active, 
			ctx.progress_callback() if ctx.cold_start_optimized else Callable(), skin_id):
		ctx.fail_startup("Logo 游戏特效预绘失败或已取消")
		return
	if not ctx.cold_start_optimized:
		ctx.begin_logo_stage("WarmFinishRender")
		if not await FinishParticleCache.pre_render_startup(ctx.launcher, active):
			ctx.fail_startup("Logo 完成页特效预绘失败或已取消")
			return
	ctx.gpu_ready = active.call()
	SortLogger.info("[StartupGpu] done elapsed_ms=%.2f headless=%s" % [
		(Time.get_ticks_usec() - started) / 1000.0, DisplayServer.get_name() == "headless"])
