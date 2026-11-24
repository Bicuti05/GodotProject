class_name ShowAbDebugStep
extends FlowStep
















func get_step_name() -> String:
	return "ShowAbDebug"




func should_run(_ctx) -> bool:
	return not OS.has_feature("rel") and UserState.is_first_session()


func run(_ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var page: Node = SceneManager.show_debug_panel("ab_debug", {"startup_mode": true})

	if page == null:
		return
	await page.closed
