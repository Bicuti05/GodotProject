class_name WaitNextPressedStep
extends FlowStep














func get_step_name() -> String:
	return "WaitNextPressed"


func run(ctx) -> void :
	ctx.next_pressed = await ctx.page.await_next_pressed()
	ctx.aborted = not ctx.next_pressed
