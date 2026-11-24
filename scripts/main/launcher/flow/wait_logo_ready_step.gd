class_name WaitLogoReadyStep
extends FlowStep


func get_step_name() -> String:
	return "WaitLogoReady"


func is_barrier() -> bool:
	return true


func run(_ctx) -> void :
	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
