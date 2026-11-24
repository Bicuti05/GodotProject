class_name GameNavigationFlow
extends RefCounted

class PrepareTarget extends FlowStep:
	func get_step_name() -> String:
		return "PrepareGameTarget"
	func run(ctx) -> void :
		ctx.target = await SceneManager.prepare_page_for_display("game", ctx.active)

class CommitNavigation extends FlowStep:
	func get_step_name() -> String:
		return "CommitGameNavigation"
	func should_run(ctx) -> bool:
		return ctx.active.call() and ctx.target != null
	func run(ctx) -> void :
		SceneManager.hide_page("home")
		SceneManager.show_page("game", ctx.params)
		ctx.committed = true



static func run(source: Control, params: Dictionary, active: Callable) -> bool:
	var lease: RefCounted = PagePreparationCoordinator.begin_foreground()
	var ctx: Dictionary = {"source": source, "params": params, "active": active, 
		"target": null, "committed": false}
	await FlowRunner.new([PrepareTarget.new(), CommitNavigation.new()] as Array[FlowStep]).run(ctx)
	PagePreparationCoordinator.end_foreground(lease)
	return ctx.committed
