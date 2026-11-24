class_name PlayfieldEnterStep
extends FlowStep











func get_step_name() -> String:
	return "PlayfieldEnter"


func should_run(ctx) -> bool:
	return not ctx.aborted


func run(ctx) -> void :
	if ctx.skip_playfield_enter:
		ctx.page.show_playfield_without_entrance(ctx)
		return

	await ctx.page.play_playfield_entrance(ctx)
