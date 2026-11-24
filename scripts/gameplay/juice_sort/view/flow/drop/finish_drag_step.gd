class_name FinishDragStep
extends FlowStep

func run(ctx) -> void :
	if ctx.drag_finished:
		return
	ctx.drag_finished = true
	ctx.board._finish_drag_for_drop()

func get_step_name() -> String:
	return "FinishDrag"
