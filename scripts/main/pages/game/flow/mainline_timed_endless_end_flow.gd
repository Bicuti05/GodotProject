class_name MainlineTimedEndlessEndFlow
extends RefCounted

class Context extends RefCounted:
	var page
	var generation: int
	var aborted: bool = false
	var claimed: bool = false
	var source: Rect2 = Rect2()
	var coin_parent: Node = null
	func _init(owner) -> void :
		page = owner
		generation = page.get_end_flow_generation()
	func active() -> bool:
		return not aborted and is_instance_valid(page) and page.visible and page.is_mainline_timed_endless() and generation == page.get_end_flow_generation()

class Prepare extends FlowStep:
	func run(ctx) -> void :
		ctx.aborted = not await ctx.page.prepare_mainline_timed_finish()
class Show extends FlowStep:
	func run(ctx) -> void :
		ctx.page.hide_banner_ad()
		ctx.page.show_timed_reward_dialog()
class Claim extends FlowStep:
	func run(ctx) -> void :
		ctx.claimed = await ctx.page.await_timed_reward_claim(ctx)
		ctx.aborted = not ctx.claimed
class Close extends FlowStep:
	func run(ctx) -> void :
		ctx.source = await ctx.page.close_timed_reward_dialog(ctx)
class Collect extends FlowStep:
	func run(ctx) -> void :
		var coin_layer: CanvasItem = ctx.coin_parent as CanvasItem
		if not is_instance_valid(coin_layer) or not coin_layer.visible:
			ctx.aborted = true
			return
		await ctx.page.play_win_coin_reward(ctx.source, coin_layer)
		ctx.aborted = not is_instance_valid(coin_layer) or not coin_layer.visible
class Exit extends FlowStep:
	func run(ctx) -> void :
		await ctx.page.return_home()
class Guarded extends FlowStep:
	var step: FlowStep
	func _init(value: FlowStep) -> void : step = value
	func should_run(ctx) -> bool: return ctx.active()
	func run(ctx) -> void : await step.run(ctx)


static func run(page, _after_level: int) -> void :
	var ctx: = Context.new(page)
	var guarded: Array[FlowStep] = []
	for step: FlowStep in [Prepare.new(), Show.new(), Claim.new(), Close.new(), Collect.new(), Exit.new()]:
		guarded.append(Guarded.new(step))
	await FlowRunner.new(guarded).run(ctx)
