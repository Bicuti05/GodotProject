class_name LongLinkStep
extends FlowStep


func should_run(ctx) -> bool:
	return ctx.move_applied and not ctx.root_swapped and not ctx.long_link_finished


func run(ctx) -> void :
	if not should_run(ctx):
		return
	ctx.long_link_finished = true
	ctx.board.record_valid_placement(ctx.long_link_geometry)


func get_step_name() -> String:
	return "LongLink"
