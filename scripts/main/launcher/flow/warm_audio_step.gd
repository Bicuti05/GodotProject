class_name WarmAudioStep
extends FlowStep


func get_step_name() -> String:
	return "WarmAudio"


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var progress: Callable = ctx.progress_callback() if ctx is LauncherFlowContext else Callable()
	var ready: bool = await AudioManager.warm_startup_resources(progress)
	if ctx is LauncherFlowContext:
		ctx.audio_ready = ready
		if not ready:
			ctx.fail_startup("音效加载未全部成功")
