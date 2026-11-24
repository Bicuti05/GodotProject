class_name FlowRunner
extends RefCounted




var _steps: Array[FlowStep] = []
var _log_steps: bool = true

func _init(steps: Array[FlowStep] = [], log_steps: bool = true) -> void :
	_steps = steps
	_log_steps = log_steps


func add(step: FlowStep) -> FlowRunner:
	_steps.append(step)
	return self







func run(ctx) -> void :
	var pending: Array[FlowStep] = []
	for step in _steps:
		if not step.should_run(ctx):
			if _log_steps:
				SortLogger.info("[Flow] skip: %s" % step.get_step_name())
			continue
		if step.is_barrier():
			for p in pending:
				if not p.is_done():
					await p.completed
			pending.clear()
		if _log_steps:
			SortLogger.info("[Flow] run: %s" % step.get_step_name())
		if step.is_blocking():
			await step.run(ctx)
		else:
			pending.append(step)
			_run_detached(step, ctx)



func _run_detached(step: FlowStep, ctx) -> void :
	await step.run(ctx)
	step.mark_done()
