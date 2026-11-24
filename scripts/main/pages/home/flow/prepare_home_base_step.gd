class_name PrepareHomeBaseStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareHomeBase"

func run(ctx) -> void :
	if not ctx.active.call():
		ctx.aborted = true
		return
	var started: int = Time.get_ticks_usec()
	ctx.page = SceneManager.get_page("home")
	if ctx.page == null or not ctx.page.visible:
		ctx.page = await SceneManager.prepare_page_for_display("home", ctx.active)
	ctx.aborted = ctx.page == null or not ctx.active.call()
	SortLogger.info("[HomeLoad] base_prepare_ms=%.2f success=%s" % [(Time.get_ticks_usec() - started) / 1000.0, not ctx.aborted])
	if ctx.page == null and ctx.active.call():
		SortLogger.error("HomeNavigationFlow: 基础首页准备失败或导航已取消")
