class_name BlockedDropStep
extends FlowStep

func should_run(ctx) -> bool:
	return not ctx.handled and ctx.outcome == JuiceDropContext.Outcome.BLOCKED

func run(ctx) -> void :
	if not should_run(ctx):
		return
	ctx.handled = true
	ctx.board._handle_blocked_drop(ctx.src, ctx.j, ctx.target)

func get_step_name() -> String:
	return "BlockedDrop"
