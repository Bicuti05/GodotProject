class_name CancelDropStep
extends FlowStep

func should_run(ctx) -> bool:
	return not ctx.handled and ctx.outcome == JuiceDropContext.Outcome.CANCEL

func run(ctx) -> void :
	if not should_run(ctx):
		return
	ctx.handled = true
	if ctx.target < 0:
		ctx.board.blank_dropped.emit()
	ctx.board.queue_redraw()

func get_step_name() -> String:
	return "CancelDrop"
