class_name GameMoveFlow
extends RefCounted
static func run(ctx: GameMoveContext) -> void :
	var runner: = FlowRunner.new([
		MysteryAutoUnlockStep.new(), 
		MoveFeedbackStep.new(), 
		QueuePropRefreshStep.new(), 
		PersistMoveStep.new(), 
	] as Array[FlowStep], false)
	await runner.run(ctx)
