class_name ShowSplashStep
extends FlowStep



const _LOGO_FADE_DURATION_SECONDS: float = 0.4


func get_step_name() -> String:
	return "ShowSplash"


func should_run(ctx) -> bool:
	return (ctx.cold_start_optimized or ctx.gpu_ready) and ctx.is_logo_preparation_active() if ctx is LauncherFlowContext else true


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	ctx.splash_shown_msec = -1
	var params: Dictionary = {"cold_start_optimized": ctx.cold_start_optimized, "system_locale": ctx.system_locale}

	SceneManager.warm_page("privacy")
	await ctx.launcher.get_tree().process_frame

	SceneManager.warm_page("splash")
	ctx.splash_page = SceneManager.get_page("splash") as SplashPage
	var active: Callable = func() -> bool:

		return ctx.is_logo_preparation_active() if ctx is LauncherFlowContext else is_instance_valid(ctx.launcher)
	if ctx.splash_page == null or not await ctx.splash_page.prepare_logo_for_display(active):
		SortLogger.error("ShowSplash: 游戏 Logo 资源准备失败或已取消")
		return
	if ctx.logo_page == null or not is_instance_valid(ctx.logo_page):
		ctx.splash_page = SceneManager.show_page("splash", params) as SplashPage
		ctx.splash_shown_msec = Time.get_ticks_msec()
		_request_optimized_resources(ctx)
		return
	ctx.splash_page = SceneManager.prepare_page_below("splash", ctx.logo_page) as SplashPage
	if ctx.splash_page == null:
		SortLogger.error("ShowSplash: 无法准备 Splash 页")
		return
	ctx.splash_page.set_cold_start_optimized(ctx.cold_start_optimized)

	await ctx.launcher.get_tree().process_frame
	await ctx.launcher.get_tree().process_frame
	if ctx.logo_page == null or not is_instance_valid(ctx.logo_page):
		ctx.splash_page = SceneManager.show_page("splash", params) as SplashPage
		ctx.splash_shown_msec = Time.get_ticks_msec()
		_request_optimized_resources(ctx)
		return

	ctx.splash_page = SceneManager.show_page("splash", params, ctx.logo_page) as SplashPage
	await ctx.logo_page.fade_out(_LOGO_FADE_DURATION_SECONDS)
	SceneManager.hide_page("logo")
	ctx.splash_shown_msec = Time.get_ticks_msec()
	_request_optimized_resources(ctx)


func _request_optimized_resources(ctx) -> void :
	if not ctx.cold_start_optimized:
		return
	if not GameEffectsPreparer.request_startup_resources():
		ctx.fail_startup("Board 资源请求失败")
	FinishParticleCache.request_resources()
