class_name RequestWarmPagesStep
extends FlowStep


func get_step_name() -> String:
	return "RequestWarmPages"

func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	if ctx is LauncherFlowContext and ctx.cold_start_optimized and not GameEffectsPreparer.request_startup_resources():
		ctx.fail_startup("Board 资源请求失败")
		return
	var progress: Callable = ctx.progress_callback() if ctx is LauncherFlowContext else Callable()
	var particle_progress: Callable = func(ratio: float) -> void :
		if progress.is_valid():
			progress.call(ratio * 0.5)
	var audio_progress: Callable = func(ratio: float) -> void :
		if progress.is_valid():
			progress.call(0.5 + ratio * 0.5)
	var particles_requested: bool = await FinishParticleCache.request_resources_spread(ctx.launcher, particle_progress)
	var audio_requested: bool = await AudioManager.request_startup_resources_spread(audio_progress)
	if ctx is LauncherFlowContext and ( not particles_requested or not audio_requested):
		ctx.fail_startup("启动资源请求失败")
