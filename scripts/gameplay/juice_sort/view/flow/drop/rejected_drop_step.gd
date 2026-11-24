class_name RejectedDropStep
extends FlowStep

func should_run(ctx) -> bool:
	return not ctx.handled and ctx.outcome == JuiceDropContext.Outcome.REJECTED

func run(ctx) -> void :
	if not should_run(ctx):
		return
	ctx.handled = true
	ctx.board._handle_rejected_drop(ctx.src, ctx.j, ctx.target, ctx.reason)

func get_step_name() -> String:
	return "RejectedDrop"
