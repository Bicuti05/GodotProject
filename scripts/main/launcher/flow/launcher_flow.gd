class_name LauncherFlow
extends RefCounted



static func run(launcher) -> void :
	var ctx: = LauncherFlowContext.new(launcher)
	var prefix: = FlowRunner.new(_build_prefix())
	await prefix.run(ctx)
	if not ctx.is_logo_preparation_active():
		return
	ctx.cold_start_optimized = ABManager.cold_start_optimization.is_cold_start_optimization_enabled()
	GameEffectsPreparer.set_startup_mode(ctx.cold_start_optimized)
	FinishParticleCache.set_startup_mode(ctx.cold_start_optimized)
	PagePreparationCoordinator.cold_start_optimized = ctx.cold_start_optimized
	SortLogger.info("[ColdStart] optimized=%s locked=%s" % [ctx.cold_start_optimized, ABManager._startup_control_locked])
	var runner: = FlowRunner.new(_build_steps(ctx.cold_start_optimized))
	await runner.run(ctx)





static func _build_steps(optimized: bool = false) -> Array[FlowStep]:
	if optimized:
		return [
			WaitLogoReadyStep.new(), 
			ShowSplashStep.new(), 
			PrivacyCmpAttStep.new(), 
			StartupProgressStep.new(InitDataStep.new(), LauncherFlowContext.AUTH_STAGE_END_PERCENT, 27.0), 
			StartupProgressStep.new(InitGrtAnchorStep.new(), 27.0, 33.0), 
			BindCrashlyticsUserIdStep.new(), 
			ReassertUserLevelTagStep.new(), 
			StartupProgressStep.new(LoadStartupLevelsStep.new(), 33.0, 50.0), 
			StartupProgressStep.new(RequestWarmPagesStep.new(), 50.0, 56.0), 
			StartupProgressStep.new(PrepareRankSessionStep.new(), 56.0, 62.0), 
			StartupProgressStep.new(ResolveInitialRouteStep.new(), 62.0, 68.0), 
			StartupProgressStep.new(WarmStartupGpuStep.new(), 68.0, 74.0), 
			StartupProgressStep.new(WarmPagesStep.new(), 74.0, 85.0), 
			StartupProgressStep.new(WarmAudioStep.new(), 85.0, 90.0), 
			StartupProgressStep.new(WarmFinishRenderStep.new(), 90.0, 95.0), 
			WaitSplashCompleteStep.new(), 
			RouteInitialPageStep.new(), 
		] as Array[FlowStep]

	return [
		InitDataStep.new(), 
		InitGrtAnchorStep.new(), 
		WaitLogoReadyStep.new(), 
		BindCrashlyticsUserIdStep.new(), 
		ReassertUserLevelTagStep.new(), 
		LoadStartupLevelsStep.new(), 
		WarmStartupGpuStep.new(), 
		ShowSplashStep.new(), 
		PrivacyCmpAttStep.new(), 
		StartupProgressStep.new(RequestWarmPagesStep.new(), LauncherFlowContext.AUTH_STAGE_END_PERCENT, 26.0), 
		StartupProgressStep.new(PrepareRankSessionStep.new(), 26.0, 37.0), 
		StartupProgressStep.new(ResolveInitialRouteStep.new(), 37.0, 49.0), 
		StartupProgressStep.new(WarmPagesStep.new(), 49.0, 72.0), 
		StartupProgressStep.new(WarmAudioStep.new(), 72.0, 83.0), 
		StartupProgressStep.new(WarmFinishRenderStep.new(), 83.0, 95.0), 
		WaitSplashCompleteStep.new(), 
		RouteInitialPageStep.new(), 
	] as Array[FlowStep]


static func _build_prefix() -> Array[FlowStep]:
	return [
		ConsumeFirstSessionStep.new(), 
		ApplySystemLocaleStep.new(), 
		ShowLogoStep.new(), 
		InjectDebugToolsStep.new(), 
		ShowAbDebugStep.new(), 
		InitializeUniKitStep.new(), 
		AwaitAbtestReadyStep.new(), 
	] as Array[FlowStep]
