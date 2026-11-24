class_name ShowLogoStep
extends FlowStep




const _NATIVE_CONFIRM_TIMEOUT_MSEC: int = 1000
const _NATIVE_RETRY_INTERVAL_MSEC: int = 100


func get_step_name() -> String:
	return "ShowLogo"


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", "%s:show_page" % get_step_name())
	ctx.logo_page = SceneManager.show_page("logo") as LogoPage
	if ctx.logo_page == null:
		SortLogger.error("[ShowLogo] Logo 页创建失败，保留原生启动遮罩")
		return

	for _frame: int in range(2):
		if DisplayServer.get_name() == "headless":
			await ctx.launcher.get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:hide_native_splash" % get_step_name())
	await _hide_native_splash(ctx, 0)
	ctx.logo_shown_msec = Time.get_ticks_msec()


func _hide_native_splash(ctx, fade_ms: int) -> void :
	var is_mobile: bool = OS.has_feature("android") or OS.has_feature("ios")
	if not Engine.has_singleton("SplashPlugin"):
		if is_mobile:
			SortLogger.error("[ShowLogo] SplashPlugin 缺失，无法移除原生启动遮罩")
		return
	var plugin: Object = Engine.get_singleton("SplashPlugin")
	plugin.hideSplash(fade_ms)
	if not is_mobile:
		return
	if not plugin.has_method("isSplashHidden"):
		SortLogger.error("[ShowLogo] SplashPlugin 缺少移除确认接口，请更新原生包")
		return
	var started_msec: int = Time.get_ticks_msec()
	var retry_msec: int = started_msec + _NATIVE_RETRY_INTERVAL_MSEC
	while Time.get_ticks_msec() - started_msec < _NATIVE_CONFIRM_TIMEOUT_MSEC:
		await ctx.launcher.get_tree().process_frame
		if plugin.isSplashHidden():
			SortLogger.info("[ShowLogo] 原生启动遮罩已移除，确认耗时 %dms" % (Time.get_ticks_msec() - started_msec))
			return
		if Time.get_ticks_msec() >= retry_msec:
			plugin.hideSplash(0)
			retry_msec = Time.get_ticks_msec() + _NATIVE_RETRY_INTERVAL_MSEC
	SortLogger.error("[ShowLogo] 原生启动遮罩移除未确认，已重试 1000ms")
