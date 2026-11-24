class_name ReassertUserLevelTagStep
extends FlowStep







func get_step_name() -> String:
	return "ReassertUserLevelTag"


func run(_ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	UserLevelTag.reassert()
