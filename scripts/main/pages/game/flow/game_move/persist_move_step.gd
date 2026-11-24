class_name PersistMoveStep
extends FlowStep

func run(ctx) -> void :
	if ctx.sync_settlement_done:
		return
	ctx.page.persist_moved_state()
	ctx.sync_settlement_done = true

func get_step_name() -> String:
	return "PersistMove"
