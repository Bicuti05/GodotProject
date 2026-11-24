class_name ValidDropStep
extends FlowStep

func should_run(ctx) -> bool:
	return not ctx.handled and ctx.outcome == JuiceDropContext.Outcome.VALID

func run(ctx) -> void :
	if not should_run(ctx):
		return
	ctx.handled = true
	var connection: Dictionary = {} if ctx.root_swapped else ctx.board.capture_connection(ctx.src, ctx.j, ctx.target)
	ctx.move_applied = ctx.board._apply_valid_drop(ctx.src, ctx.j, ctx.target, not connection.is_empty())
	if ctx.move_applied and not ctx.root_swapped:
		ctx.board.queue_connection_feedback(connection)

func get_step_name() -> String:
	return "ValidDrop"
