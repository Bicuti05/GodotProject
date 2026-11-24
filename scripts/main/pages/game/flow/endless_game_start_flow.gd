class_name EndlessGameStartFlow
extends RefCounted

class Context extends RefCounted:
	var page: Variant
	var generation: int
	var params: Dictionary = {}
	var aborted: bool = false
	var skip_playfield_enter: bool = false
	var skip_opening_banner: bool = false
	func _init(owner: Variant, token: int, skip: bool) -> void :
		page = owner
		generation = token
		skip_playfield_enter = skip
	func active() -> bool:
		return not aborted and is_instance_valid(page) and page.visible and page.endless_generation() == generation

class Prepare extends FlowStep:
	func run(ctx) -> void :
		if ctx.active() and not await ctx.page.prepare_endless_view(ctx):
			ctx.aborted = true

class Begin extends FlowStep:
	func run(ctx) -> void :
		if ctx.active():
			ctx.page.begin_endless_round(ctx)

class Enter extends FlowStep:
	func run(ctx) -> void :
		if ctx.active():
			await ctx.page.play_endless_entrance(ctx)

class Activate extends FlowStep:
	func run(ctx) -> void :
		while ctx.active() and ctx.page.endless_session().incoming.is_empty():
			await ctx.page.get_tree().process_frame
		if ctx.active():
			ctx.page.activate_endless_round()

static func run(ctx: Context) -> void :
	var runner: = FlowRunner.new([Prepare.new(), Begin.new(), Enter.new(), EndlessOpeningBannerStep.new(), Activate.new()] as Array[FlowStep], false)
	await runner.run(ctx)
