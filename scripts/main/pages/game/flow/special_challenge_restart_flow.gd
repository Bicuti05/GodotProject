class_name SpecialChallengeRestartFlow
extends RefCounted

class Entrance extends FlowStep:
	func run(ctx) -> void :
		await ctx.page.play_playfield_entrance(ctx)
		ctx.aborted = not ctx.page.is_round_entrance_current(int(ctx.params["generation"]))


class Banner extends FlowStep:
	func should_run(ctx) -> bool:
		return not ctx.aborted

	func run(ctx) -> void :
		await ctx.page.show_opening_banners(ctx)

static func run(page, ctx: GameStartContext = null) -> void :
	if ctx == null:
		ctx = GameStartContext.new(page)
	await FlowRunner.new([Entrance.new(), Banner.new()] as Array[FlowStep]).run(ctx)
