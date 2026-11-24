class_name RankPageEnterFlow
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
		return ctx.ready and ctx.active.call() and not ctx.first_screen_ready
	func run(ctx) -> void :
		await ctx.page.prepare_show_screen(ctx)
	func get_step_name() -> String:
		return "RankFirstScreen"

class Activate extends FlowStep:
	func should_run(ctx) -> bool:
		return ctx.ready and ctx.active.call()
	func run(ctx) -> void :
		await ctx.page.activate_show(ctx)
	func get_step_name() -> String:
		return "RankActivate"

class Profile extends FlowStep:
	func should_run(ctx) -> bool:
		return ctx.ready and ctx.active.call()
	func run(ctx) -> void :
		await ctx.page.show_profile_if_needed(ctx)
	func get_step_name() -> String:
		return "RankProfile"

static func run(page, generation: int, params: Dictionary, first_screen_ready: bool = false) -> void :
	var ctx: Dictionary = {"page": page, "generation": generation, "params": params, "ready": false, 
		"first_screen_ready": first_screen_ready, 
		"active": func() -> bool: return is_instance_valid(page) and page._generation == generation and page.visible}
	await FlowRunner.new([Components.new(), FirstScreen.new(), Activate.new(), Profile.new()] as Array[FlowStep]).run(ctx)
