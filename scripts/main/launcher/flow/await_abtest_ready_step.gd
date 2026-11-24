class_name AwaitAbtestReadyStep
extends FlowStep




const LOGO_HOLD_SECONDS: float = 1.6
const AB_WAIT_SECONDS: float = 2.0


func get_step_name() -> String:
	return "AwaitAbtestReady"

func is_blocking() -> bool:
	return true


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	await ABManager.await_ready(AB_WAIT_SECONDS)
	ctx.ab_ready_msec = Time.get_ticks_msec()
	var remaining: float = LOGO_HOLD_SECONDS - float(Time.get_ticks_msec() - ctx.logo_shown_msec) / 1000.0
	if remaining > 0.0:
		await ctx.launcher.get_tree().create_timer(remaining).timeout
