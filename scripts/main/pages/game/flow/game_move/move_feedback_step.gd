class_name MoveFeedbackStep
extends FlowStep

func run(ctx) -> void :
	if ctx.automatic_only:
		if ctx.auto_unlock_applied:
			ctx.page.apply_auto_unlock_feedback()
		return
	ctx.page.apply_move_feedback(ctx.steps)
	ctx.page.apply_empty_rope_feedback()

func get_step_name() -> String:
	return "MoveFeedback"
