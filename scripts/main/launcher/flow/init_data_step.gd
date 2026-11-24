class_name InitDataStep
extends FlowStep






func get_step_name() -> String:
	return "InitData"


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	if ctx.cold_start_optimized:
		await run_optimized(ctx)
		return

	NativeUtilManager.set_crashlytics_key("boot_step", "%s:db_init" % get_step_name())

	DbManager.init()
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:register_parser" % get_step_name())


	var juice_parser: = JuiceLevelParser.new()
	LevelManager.register_parser(juice_parser)
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:recover_level" % get_step_name())

	if not UserState.recover_pending_level_completion():
		ctx.fail_startup("普通关通关 journal 恢复失败")
		return
	if not UserState.recover_interrupted_timed_endless():
		ctx.fail_startup("限时挑战结算恢复失败")
		return
	if not _recover_special_challenge(ctx):
		return


func run_optimized(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", "%s:db_init" % get_step_name())

	var active: Callable = ctx.is_startup_active
	var progress: Callable = ctx.progress_callback()
	if not await DbManager.init_async(active):
		ctx.fail_startup("SQLite 初始化失败或取消")
		return
	progress.call(0.5)
	if not active.call():
		return
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:register_parser" % get_step_name())


	var juice_parser: = JuiceLevelParser.new()
	LevelManager.register_parser(juice_parser)
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:recover_level" % get_step_name())

	if not UserState.recover_pending_level_completion():
		ctx.fail_startup("普通关通关 journal 恢复失败")
		return
	progress.call(0.75)
	if not UserState.recover_interrupted_timed_endless():
		ctx.fail_startup("限时挑战结算恢复失败")
		return
	await ctx.launcher.get_tree().process_frame
	if not active.call():
		return
	if not _recover_special_challenge(ctx):
		return
	ctx.data_ready = active.call()



func _recover_special_challenge(ctx) -> bool:

	if not LevelManager.recover_special_challenge_completion(false):
		ctx.fail_startup("挑战通关 journal 恢复失败")
		return false
	var challenge: Dictionary = UserState.get_special_challenge()
	if challenge.get("status", "") == "reward_pending":
		var instance_id: String = String(challenge["instance_id"])
		if UserState.claim_special_challenge(instance_id, 1).is_empty():
			ctx.fail_startup("挑战单倍奖励恢复领取失败")
			return false
		SortLogger.info("[SpecialChallenge] 冷启动自动领取单倍奖励: %s" % instance_id)
	return true
