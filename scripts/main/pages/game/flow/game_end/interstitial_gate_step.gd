class_name InterstitialGateStep
extends FlowStep






func get_step_name() -> String:
	return "InterstitialGate"


func should_run(ctx) -> bool:
	if ctx.interstitial_checked:
		AdManager.log_ad_baseline_blocked("interstitial", "already_checked", TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level})
		return false
	if not ctx.page.visible:
		AdManager.log_ad_baseline_blocked("interstitial", "page_hidden", TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level})
		return false
	if ctx.page.is_finish_ad_busy():
		AdManager.log_ad_baseline_blocked("interstitial", "finish_ad_busy", TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level})
		return false
	if not ABManager.inter_unlock_level.should_allow_interstitial(
			ctx.won_level, UserState.is_interstitial_unlocked()):
		AdManager.log_ad_baseline_blocked("inter_unlock_level", "unlock_threshold", TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level})
		return false
	if not ABManager.inter_protect_by_day.should_allow_interstitial(
			UserState.get_install_days(), UserState.get_daily_completed_level_count()):
		AdManager.log_ad_baseline_blocked("inter_protect_by_day", "daily_protection", TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level, "after_completion": true})
		return false
	if not ctx.next_pressed:
		AdManager.log_ad_baseline_blocked("interstitial", "next_not_pressed", TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level})
	else:
		AdManager.log_ad_baseline_conditions(TrackingEvents.AD_POSITION_GAME_END, 
			{"stage": "finish_gate", "won_level": ctx.won_level, "after_completion": true})
	return ctx.next_pressed

func run(ctx) -> void :
	UserState.unlock_ads(true, false)
	ctx.interstitial_checked = true
	ctx.page.set_finish_interstitial_busy(true)
	await AdManager.show_interstitial_and_await(TrackingEvents.AD_POSITION_GAME_END)
	ctx.page.set_finish_interstitial_busy(false)
