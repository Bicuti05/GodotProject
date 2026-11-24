class_name WarmFinishRenderStep
extends FlowStep

func get_step_name() -> String:
	return "WarmFinishRender"


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	NativeUtilManager.set_crashlytics_key("gpu_adapter", "%s | %s" % [
		RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_name()])
	NativeUtilManager.set_crashlytics_key("gl_version", RenderingServer.get_video_adapter_api_version())
	var progress: Callable = ctx.progress_callback() if ctx is LauncherFlowContext else Callable()
	var ready: bool = await FinishParticleCache.prepare(ctx.launcher, progress, ctx.is_startup_active if ctx is LauncherFlowContext else Callable())
	if not ready:
		SortLogger.error("WarmFinishRender: 独立粒子准备失败")
	if ctx is LauncherFlowContext:
		ctx.finish_ready = ready
		if not ready:
			ctx.fail_startup("完成页粒子准备失败")
