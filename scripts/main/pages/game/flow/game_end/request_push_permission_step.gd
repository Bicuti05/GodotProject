class_name RequestPushPermissionStep
extends FlowStep








func get_step_name() -> String:
	return "RequestPushPermission"


func should_run(_ctx) -> bool:
	return UserState.get_push_ask_count() < 1


func run(ctx) -> void :

	if not ctx.page.visible:
		return
	await AuthManager.request_push_permission_once()
