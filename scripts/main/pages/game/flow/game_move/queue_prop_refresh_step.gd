class_name QueuePropRefreshStep
extends FlowStep

func run(ctx) -> void :
	ctx.page.queue_move_prop_refresh()

func get_step_name() -> String:
	return "QueuePropRefresh"
