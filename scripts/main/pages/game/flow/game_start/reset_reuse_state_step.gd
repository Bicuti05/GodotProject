class_name ResetReuseStateStep
extends FlowStep













func get_step_name() -> String:
	return "ResetReuseState"

func run(ctx) -> void :
	ctx.page.reset_reuse_state()
