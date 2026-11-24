class_name GameStartFlow
extends RefCounted



































static func run(ctx: GameStartContext) -> void :
	if ctx.aborted:
		return
	var runner: = FlowRunner.new([
		ResetReuseStateStep.new(), 
		LoadLevelDataStep.new(), 
		NoMoreLevelGuardStep.new(), 
		PreloadBannerStep.new(), 
		PrepareRankRoundStep.new(), 
		PrepareCoinBonusLevelStep.new(), 
		PrepareSunlightPotStep.new(), 
		PrepareSkinStep.new(), 
		StartRoundStep.new(), 
		ReportGameStartStep.new(), 
		PlayfieldEnterStep.new(), 
		ShowTutorialStep.new(), 
		OpeningBannerAfterStep.new(), 
		PropUnlockStep.new(), 
		LockGuideStep.new(), 
		SunlightGuideStep.new(), 
		ShowMysteryGuideStep.new(), 
	] as Array[FlowStep])
	await runner.run(ctx)
