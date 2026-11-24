class_name ConsumeFirstSessionStep
extends FlowStep









func get_step_name() -> String:
	return "ConsumeFirstSession"


func run(_ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	UserState.consume_first_session()
