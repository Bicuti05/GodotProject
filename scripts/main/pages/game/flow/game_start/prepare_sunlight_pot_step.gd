class_name PrepareSunlightPotStep
extends FlowStep

func get_step_name() -> String:
	return "PrepareSunlightPot"


func should_run(ctx) -> bool:
	return not ctx.aborted


func run(ctx) -> void :
	ctx.page.prepare_sunlight_pot_round(ctx.current_state)
