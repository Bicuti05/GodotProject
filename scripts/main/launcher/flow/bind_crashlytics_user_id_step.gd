class_name BindCrashlyticsUserIdStep
extends FlowStep








func get_step_name() -> String:
	return "BindCrashlyticsUserId"


func run(_ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var user_id: String = Tracker.get_uuid() if OS.has_feature("rel") else "debug"
	NativeUtilManager.set_crashlytics_user_id(user_id)
