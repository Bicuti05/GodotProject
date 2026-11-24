class_name StartupProgressStep
extends FlowStep


var step: FlowStep
var _start_percent: float
var _end_percent: float


func _init(p_step: FlowStep, start_percent: float, end_percent: float) -> void :
	step = p_step
	_start_percent = start_percent
	_end_percent = end_percent


func get_step_name() -> String:
	return step.get_step_name()


func should_run(ctx) -> bool:
	return not ctx.startup_failed and step.should_run(ctx)


func is_blocking() -> bool:
	return step.is_blocking()


func is_barrier() -> bool:
	return step.is_barrier()


func run(ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	ctx.begin_stage(get_step_name(), _start_percent, _end_percent)
	if not ctx.is_startup_active():
		return
	var started: int = Time.get_ticks_usec()
	await step.run(ctx)
	if ctx.is_startup_active():
		await ctx.finish_stage()
	SortLogger.info("[StartupProgress] done=%s elapsed_ms=%.2f failed=%s" % [
		get_step_name(), (Time.get_ticks_usec() - started) / 1000.0, ctx.startup_failed])
