class_name MysteryAutoUnlockStep
extends FlowStep


func run(ctx) -> void :
	ctx.page.check_mystery_auto_unlock(ctx)


func get_step_name() -> String:
	return "MysteryAutoUnlock"
