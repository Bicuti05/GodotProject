class_name GameEndFlow
extends RefCounted


static func run(page, won_level: int) -> void :
	var ctx: = GameEndContext.new(page, won_level)
	if page.is_special_challenge():

		await ReportGameEndStep.new().run(ctx)
	if page.is_special_challenge():
		await SpecialChallengeRewardStep.new().run(ctx)
		if ctx.aborted:
			return
	var prepare_skin_step: = RequestNextSkinPreparationStep.new()
	if prepare_skin_step.should_run(ctx):
		prepare_skin_step.run(ctx)
	await IqGeniusFeedbackStep.new().run(ctx)
	if ctx.aborted:
		return
	var collect_steps: Array[FlowStep] = []
	if not page.is_special_challenge():

		collect_steps.append(ReportGameEndStep.new())
		collect_steps.append(WinCoinRewardStep.new())
		collect_steps.append(BonusPigSmashStep.new())
	collect_steps.append(RankCollectFlyStep.new())
	await FlowRunner.new(collect_steps).run(ctx)


	if ctx.aborted or not page.visible:
		return
	if not await ctx.page.wait_finish_preparation():
		return
	var settlement_steps: Array[FlowStep] = [
		HideBannerStep.new(), 
		FlowerFadeStep.new(), 
		RankRoundFinishStep.new(), 
		DailyFirstWinCheckinStep.new(), 
	]
	await FlowRunner.new(settlement_steps).run(ctx)
	if ctx.aborted or not page.visible:
		return
	var steps: Array[FlowStep] = [
		ShowFinishDialogStep.new(), 
		GameDataShowStep.new(), 
		RequestPushPermissionStep.new(), 
		ShowFinishButtonStep.new(), 
		RequestRatingStep.new(), 
		WaitNextPressedStep.new(), 
		InterstitialGateStep.new(), 
		FinishExitStep.new(), 
	]
	await FlowRunner.new(steps).run(ctx)
