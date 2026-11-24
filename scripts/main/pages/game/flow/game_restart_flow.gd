class_name GameRestartFlow
extends RefCounted

class Entrance extends FlowStep:
	func run(ctx) -> void :
		if ctx.page.is_special_challenge():
			await SpecialChallengeRestartFlow.run(ctx.page, ctx)
		else:
			await ctx.page.play_playfield_entrance(ctx)
		ctx.aborted = ctx.aborted or not ctx.page.is_round_entrance_current(int(ctx.params["generation"]))
		if not ctx.aborted and ctx.page.is_bonus_level_round():
			await ctx.page.show_opening_banners(ctx)
			ctx.aborted = ctx.aborted or not ctx.page.is_round_entrance_current(int(ctx.params["generation"]))



static func run(page) -> void :
	var ctx: = GameStartContext.new(page)
	await FlowRunner.new([Entrance.new(), SunlightGuideStep.new()] as Array[FlowStep]).run(ctx)
