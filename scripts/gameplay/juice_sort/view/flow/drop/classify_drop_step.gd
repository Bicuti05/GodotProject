class_name ClassifyDropStep
extends FlowStep

func run(ctx) -> void :
	if ctx.classified:
		return
	ctx.board._classify_drop(ctx)
	ctx.classified = true

func get_step_name() -> String:
	return "ClassifyDrop"
