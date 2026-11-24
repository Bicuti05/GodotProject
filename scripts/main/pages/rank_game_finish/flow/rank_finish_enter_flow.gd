class_name RankFinishEnterFlow
extends RefCounted

class Components extends FlowStep:
	func should_run(ctx) -> bool:
		return ctx.active.call()
	func run(ctx) -> void :
		if not ctx.page._content_ready:
			await ctx.page.get_tree().process_frame
		ctx.ready = await ctx.page.prepare_content(ctx.active)
	func get_step_name() -> String:
		return "RankPageComponents"

class FirstScreen extends FlowStep:
	func should_run(ctx) -> bool:
		return ctx.ready and ctx.active.call()
	func run(ctx) -> void :
		await ctx.page.prepare_show_screen(ctx)
	func get_step_name() -> String:
		return "RankFirstScreen"

class Presentation extends FlowStep:
	func should_run(ctx) -> bool:
		return ctx.ready and ctx.active.call()
	func run(ctx) -> void :
		await ctx.page.play_show_presentation(ctx)
	func get_step_name() -> String:
		return "RankPresentation"

class Feedback extends FlowStep:
	func should_run(ctx) -> bool:
		return ctx.ready and ctx.active.call()
	func run(ctx) -> void :
		await ctx.page.finish_show_feedback(ctx)
	func get_step_name() -> String:
		return "RankFeedback"

static func run(page, generation: int, params: Dictionary) -> void :
	var ctx: Dictionary = {"page": page, "generation": generation, "params": params, "ready": false, 
		"active": func() -> bool: return is_instance_valid(page) and page._generation == generation and page.visible}
	await FlowRunner.new([Components.new(), FirstScreen.new(), Presentation.new(), Feedback.new()] as Array[FlowStep]).run(ctx)
