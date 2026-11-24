class_name JuiceDropFlow
extends RefCounted


static func run(ctx: JuiceDropContext) -> void :
	var runner: = FlowRunner.new([
		FinishDragStep.new(), 
		ClassifyDropStep.new(), 
		CancelDropStep.new(), 
		BlockedDropStep.new(), 
		RejectedDropStep.new(), 
		ValidDropStep.new(), 
		LongLinkStep.new(), 
	] as Array[FlowStep], false)
	await runner.run(ctx)



static func finish_now(ctx: JuiceDropContext) -> void :
	FinishDragStep.new().run(ctx)
	ClassifyDropStep.new().run(ctx)
	match ctx.outcome:
		JuiceDropContext.Outcome.CANCEL:
			CancelDropStep.new().run(ctx)
		JuiceDropContext.Outcome.BLOCKED:
			BlockedDropStep.new().run(ctx)
		JuiceDropContext.Outcome.REJECTED:
			RejectedDropStep.new().run(ctx)
		JuiceDropContext.Outcome.VALID:
			ValidDropStep.new().run(ctx)
	LongLinkStep.new().run(ctx)
