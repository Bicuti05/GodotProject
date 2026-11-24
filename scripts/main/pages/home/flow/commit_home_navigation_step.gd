class_name CommitHomeNavigationStep
extends FlowStep

func get_step_name() -> String:
	return "CommitHomeNavigation"

func should_run(ctx) -> bool:
	return not ctx.aborted and ctx.active.call()

func run(ctx) -> void :

	if is_instance_valid(ctx.source):
		SceneManager.hide_page("game")
	var page: Node = SceneManager.show_page("home", ctx.params)
	if page == null:
		ctx.aborted = true
		return
	ctx.committed = true
