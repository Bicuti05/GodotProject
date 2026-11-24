class_name NoMoreLevelGuardStep
extends FlowStep




func get_step_name() -> String:
	return "NoMoreLevelGuard"

func should_run(ctx) -> bool:
	return not ctx.aborted and ctx.level_model == null

func run(ctx) -> void :
	ctx.aborted = true
	var level: int = UserState.get_current_level()
	SortLogger.info("[NoMoreLevelGuardStep] 关号 %d 的模型不可用，退回可恢复首页" % level)
	await ctx.page.return_home()

	if not LevelManager.is_end_reached(level):
		SceneManager.show_toast(tr("HOME_NETWORK_ERROR"))
