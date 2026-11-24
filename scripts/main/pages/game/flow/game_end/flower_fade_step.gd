class_name FlowerFadeStep
extends FlowStep









func get_step_name() -> String:
	return "FlowerFade"


func run(ctx) -> void :
	ctx.page.fade_win_flowers()
