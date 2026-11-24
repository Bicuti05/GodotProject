class_name RequestNextSkinPreparationStep
extends FlowStep

func get_step_name() -> String:
	return "RequestNextSkinPreparation"

func should_run(ctx) -> bool:
	return not ctx.aborted and ctx.page.has_method("request_next_skin_preparation")

func run(ctx) -> void :
	ctx.page.request_next_skin_preparation()
