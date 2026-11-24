class_name InjectDebugToolsStep
extends FlowStep





const _CHEAT_COMMANDS_PATH: String = "res://scripts/debug/cheat_commands.gd"
const _CHEAT_OVERLAY_PATH: String = "res://scripts/debug/cheat_manager/cheat_overlay.tscn"


func get_step_name() -> String:
	return "InjectDebugTools"


func should_run(_ctx) -> bool:
	return not OS.has_feature("rel")


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	var started_usec: int = Time.get_ticks_usec()
	for path: String in [_CHEAT_COMMANDS_PATH, _CHEAT_OVERLAY_PATH]:
		var error: Error = ResourceLoader.load_threaded_request(path)
		if error != OK:
			SortLogger.error("InjectDebugTools: 资源请求失败 %s error=%d" % [path, error])
			return
	for path: String in [_CHEAT_COMMANDS_PATH, _CHEAT_OVERLAY_PATH]:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await ctx.launcher.get_tree().process_frame
	var cheat_commands: GDScript = ResourceLoader.load_threaded_get(_CHEAT_COMMANDS_PATH) as GDScript
	var overlay_scene: PackedScene = ResourceLoader.load_threaded_get(_CHEAT_OVERLAY_PATH) as PackedScene
	if cheat_commands == null or overlay_scene == null:
		SortLogger.error("InjectDebugTools: 调试资源加载失败")
		return
	var loaded_usec: int = Time.get_ticks_usec()
	_register_debug_routes()
	ctx.launcher.add_child(cheat_commands.new())

	await ctx.launcher.get_tree().process_frame
	var cheat_overlay: Node = overlay_scene.instantiate()




	if cheat_overlay is CanvasLayer:
		(cheat_overlay as CanvasLayer).layer = SceneManager.Layer.DEBUG
	ctx.launcher.add_child(cheat_overlay)
	SortLogger.info("[Startup] debug_resource_wait_ms=%.2f debug_prepare_ms=%.2f" % [
		float(loaded_usec - started_usec) / 1000.0, 
		float(Time.get_ticks_usec() - loaded_usec) / 1000.0])





func _register_debug_routes() -> void :
	SceneManager.PAGE_SCENES["timed_endless_popup_preview"] = "res://scripts/debug/ui/timed_endless_popup_preview.tscn"
	SceneManager.PAGE_LAYERS["timed_endless_popup_preview"] = SceneManager.Layer.DEBUG
	SceneManager.PAGE_SCENES["rank_collectible_flow_preview"] = "res://scripts/debug/ui/rank_collectible_flow_preview.tscn"
	SceneManager.PAGE_LAYERS["rank_collectible_flow_preview"] = SceneManager.Layer.DEBUG
	SceneManager.PAGE_SCENES["rank_first_collect_preview"] = "res://scripts/debug/ui/rank_first_collect_preview.tscn"
	SceneManager.PAGE_LAYERS["rank_first_collect_preview"] = SceneManager.Layer.DEBUG
	SceneManager.PAGE_SCENES["rank_debug"] = "res://scripts/debug/view/rank_debug_page.tscn"
	SceneManager.PAGE_LAYERS["rank_debug"] = SceneManager.Layer.DEBUG
	SceneManager.PAGE_SCENES["ab_debug"] = "res://scripts/debug/ab_debug_page.tscn"
	SceneManager.PAGE_LAYERS["ab_debug"] = SceneManager.Layer.DEBUG


	if OS.has_feature("editor"):
		SceneManager.PAGE_SCENES["juice_replay"] = "res://scripts/debug/replay/juice_replay_page.tscn"
		SceneManager.PAGE_LAYERS["juice_replay"] = SceneManager.Layer.DEBUG
