class_name ShowTutorialStep
extends FlowStep








func get_step_name() -> String:
	return "ShowTutorial"

func should_run(ctx) -> bool:
	return not ctx.aborted and ctx.page.should_run_tutorial_now(ctx.current_state)

func run(ctx) -> void :
	ctx.page.show_tutorial()
