class_name FinishAdRewardFlow
extends RefCounted

static func run(page, panel) -> void :
	if page.is_finish_ad_busy() or page.is_finish_interstitial_busy():
		return
	var claim: Dictionary = panel.begin_ad_claim()
	if claim.is_empty():
		return
	var busy_generation: int = page.begin_finish_ad_busy()
	var ctx: Dictionary = {
		"page": page, "panel": panel, "generation": int(claim["generation"]), 
		"reward": claim["reward"], "rewarded": false, "granted": false, 
	}
	await FlowRunner.new([ShowRewardAdStep.new(), GrantRewardStep.new(), PlayFinishAdRewardStep.new()]).run(ctx)
	if is_instance_valid(panel) and panel.is_ad_claim_current(ctx.generation):
		panel.end_ad_claim(ctx.generation, ctx.granted)
	if is_instance_valid(page):
		page.end_finish_ad_busy(busy_generation)
