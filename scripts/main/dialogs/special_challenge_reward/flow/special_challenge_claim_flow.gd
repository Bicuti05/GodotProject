class_name SpecialChallengeClaimFlow
extends RefCounted

class ShowAd extends FlowStep:
	func run(ctx) -> void :
		if ctx.multiplier == 2:

			ctx.rewarded = await AdManager.show_reward_ad_and_await("special_challenge")
		else:
			ctx.rewarded = true

class Grant extends FlowStep:
	func run(ctx) -> void :
		if ctx.rewarded and is_instance_valid(ctx.dialog) and ctx.dialog.is_claim_current(ctx.generation):
			ctx.grant = UserState.claim_special_challenge(ctx.instance_id, ctx.multiplier)
			if ctx.grant.is_empty():
				return

			var source: String = TrackingEvents.REWARD_SOURCE_SPECIAL_CHALLENGE_ADS\
			if ctx.multiplier == 2 else TrackingEvents.REWARD_SOURCE_SPECIAL_CHALLENGE
			var reward: Dictionary = ctx.grant["reward"]
			var before: Dictionary = ctx.grant["before"]
			var coins: int = int(reward["coins"])
			if coins > 0:
				Tracker.send_event(TrackingEvents.EV_COIN_STATUS, {
					TrackingEvents.K_COIN_CHANGE_REASON: source, 
					TrackingEvents.K_COIN_CHANGE_NUM: coins, 
					TrackingEvents.K_COIN_TOTAL_NUM: int(before["coins"]) + coins})
			for kind: String in [TrackingEvents.PROP_HINT, TrackingEvents.PROP_UNDO, TrackingEvents.PROP_ROPE]:
				var amount: int = int(reward[kind])
				if amount > 0:
					Tracker.send_event(TrackingEvents.EV_PROP_GET, {
						TrackingEvents.K_SOURCE: source, 
						TrackingEvents.K_PROP_NAME: kind, 
						TrackingEvents.K_PROP_NUM: amount, 
						TrackingEvents.K_PROP_LEFT: int(before[kind]) + amount})

class FadePresentation extends FlowStep:
	func run(ctx) -> void :
		if not ctx.grant.is_empty() and is_instance_valid(ctx.dialog) and ctx.dialog.is_claim_current(ctx.generation):
			await ctx.dialog.fade_presentation(ctx.grant)

class Collect extends FlowStep:
	func run(ctx) -> void :
		if not ctx.grant.is_empty() and is_instance_valid(ctx.dialog) and ctx.dialog.is_claim_current(ctx.generation):
			await ctx.dialog.play_collection(ctx.grant)

static func run(dialog, generation: int, instance_id: String, multiplier: int) -> Dictionary:
	var ctx: Dictionary = {"dialog": dialog, "generation": generation, "instance_id": instance_id, 
		"multiplier": multiplier, "rewarded": false, "grant": {}}
	await FlowRunner.new([ShowAd.new(), Grant.new(), FadePresentation.new(), Collect.new()] as Array[FlowStep]).run(ctx)
	return ctx.grant
