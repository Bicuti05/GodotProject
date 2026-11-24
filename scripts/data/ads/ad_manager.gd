extends Node















































const AD_PLACEMENT_ID_INTERSTITIAL: String = "interstitial"
const AD_PLACEMENT_ID_REWARD: String = "reward"
const AD_PLACEMENT_ID_BANNER: String = "banner"










var _editor_ads: EditorAds = EditorAds.new()



var _banner_load_triggered: bool = false


var _banner_preload_waiting_ab: bool = false






func _ad_module() -> Variant:
	if _use_mock():
		return _editor_ads
	return UniKit.ad_module





func _use_mock() -> bool:
	return OS.has_feature("editor") or _mock_active()



func _module_label(module: Variant) -> String:
	return "Mock" if module == _editor_ads else "UniKit"





func _mock_active() -> bool:
	return MockUnikitConfig.is_mock_enabled(OS.has_feature("editor"))


func _ready() -> void :
	if not _is_ad_inited():


		SortLogger.mark("等待广告 SDK 初始化完成")
		await _ad_module().ad_init_completed
		SortLogger.mark("广告 SDK 初始化完成，开始加载广告位")





	_bind_ad_signals()
	_load_ads()




func _is_ad_inited() -> bool:
	return _ad_module().is_ad_inited()





func _load_ads() -> void :
	SortLogger.mark("加载广告位：(interstitial=%s, reward=%s)" % [AD_PLACEMENT_ID_INTERSTITIAL, AD_PLACEMENT_ID_REWARD])
	_ad_module().load_ad(AD_PLACEMENT_ID_INTERSTITIAL)
	_ad_module().load_ad(AD_PLACEMENT_ID_REWARD)


	call_deferred("_bind_ad_baseline_config_logs")
	call_deferred("_maybe_preload_banner")



func _maybe_preload_banner() -> void :
	if _banner_load_triggered:
		log_ad_baseline_blocked("banner", "load_already_requested", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "startup_preload"})
		return
	if _debug_no_ads():
		log_ad_baseline_blocked("banner", "debug_no_ads", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "startup_preload"})
		return
	if not ABManager.is_ab_init_done():
		log_ad_baseline_blocked("banner", "ab_not_ready", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "startup_preload"})
		if not _banner_preload_waiting_ab:
			_banner_preload_waiting_ab = true
			ABManager.init_done.connect(_maybe_preload_banner)
		return
	if not ABManager.banner_unlock_level.should_allow_banner(
			UserState.get_current_level(), UserState.is_banner_unlocked()):
		log_ad_baseline_blocked("banner_unlock_level", "unlock_threshold", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "startup_preload", "level_id": UserState.get_current_level()})
		return
	AdBaselineDiagnostics.log_banner(TrackingEvents.AD_POSITION_GAME_PAGE, {"stage": "startup_preload"})
	SortLogger.info("[BannerAd] 启动预加载 Banner")
	_load_banner()
	log_ad_baseline_event("banner_unlock_level", "preload_requested", TrackingEvents.AD_POSITION_GAME_PAGE, 
		{"stage": "startup_preload"})



func maybe_preload_banner_on_game_enter() -> void :
	SortLogger.mark("进游戏页检查 Banner 预加载")
	if _banner_load_triggered:
		log_ad_baseline_blocked("banner", "load_already_requested", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "game_enter_preload"})
		return
	if _debug_no_ads():
		log_ad_baseline_blocked("banner", "debug_no_ads", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "game_enter_preload"})
		return
	if not ABManager.is_ab_init_done():
		log_ad_baseline_blocked("banner", "ab_not_ready", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "game_enter_preload"})
		return
	if not ABManager.banner_unlock_level.should_allow_banner(
			UserState.get_current_level() + 1, UserState.is_banner_unlocked()):
		log_ad_baseline_blocked("banner_unlock_level", "unlock_threshold", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "game_enter_preload", "level_id": UserState.get_current_level(), 
				"preload_level": UserState.get_current_level() + 1})
		return
	AdBaselineDiagnostics.log_banner(TrackingEvents.AD_POSITION_GAME_PAGE, {"stage": "game_enter_preload"})
	SortLogger.info("[BannerAd] 进游戏页预加载 Banner")
	_load_banner()
	log_ad_baseline_event("banner_unlock_level", "preload_requested", TrackingEvents.AD_POSITION_GAME_PAGE, 
		{"stage": "game_enter_preload"})








func _bind_ad_signals() -> void :
	SortLogger.mark("绑定广告 SDK 常驻信号")
	_ad_module().ad_loaded.connect(_on_ad_loaded)
	_ad_module().ad_will_show.connect(_on_ad_will_show)
	_ad_module().ad_closed.connect(_on_ad_closed)
	_ad_module().ad_rewarded.connect(_on_ad_rewarded)
	_ad_module().ad_error_occurred.connect(_on_ad_error_occurred)
	_ad_module().ad_impression_received.connect(_on_ad_impression_received)
















func _on_ad_loaded(placement_id: String) -> void :
	SortLogger.mark("广告加载成功：(placement_id=%s)" % placement_id)
	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL or placement_id == AD_PLACEMENT_ID_BANNER:
		log_ad_baseline_event(placement_id, "loaded", "")
	if placement_id != AD_PLACEMENT_ID_REWARD:
		return
	_track_pending_reward_fills()
	reward_ad_loaded.emit()






func _track_pending_reward_fills() -> void :
	for position: String in _reward_show_ids:
		var entry: Dictionary = _reward_show_ids[position]
		if entry[_KEY_REWARD_FILL_TRACKED]:
			continue
		entry[_KEY_REWARD_FILL_TRACKED] = true
		_track_ad(TrackingEvents.EV_AD_IS_FILL, AD_PLACEMENT_ID_REWARD, position, 
			entry[_KEY_REWARD_SHOW_ID])








func _on_ad_will_show(placement_id: String) -> void :
	SortLogger.mark("广告即将展示：(placement_id=%s)" % placement_id)



func _on_ad_closed(placement_id: String) -> void :
	SortLogger.mark("广告已关闭：(placement_id=%s)" % placement_id)
	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
		log_ad_baseline_event("interstitial", "inter_closed", "")
	if placement_id == AD_PLACEMENT_ID_REWARD and not _reward_request.is_empty()\
	and not _reward_request["closed"]:
		_reward_request["closed"] = true
		_reward_request["closed_msec"] = Time.get_ticks_msec()
	_clear_fullscreen_ad(placement_id)




func _on_ad_rewarded(placement_id: String) -> void :
	SortLogger.mark("广告发放激励：(placement_id=%s)" % placement_id)
	if placement_id != AD_PLACEMENT_ID_REWARD or _reward_request.is_empty()\
	or _reward_request["rewarded"]:
		return
	_reward_request["rewarded"] = true
	_reward_result = true
	if _reward_request["returned"]:
		var on_late_reward: Callable = _reward_request["on_late_reward"]
		_reward_request["on_late_reward"] = Callable()
		if on_late_reward.is_valid():
			SortLogger.info("[RewardAd] 晚到奖励补发 position=%s show_id=%s" % [
				_reward_request["position"], _reward_request["show_id"]])
			on_late_reward.call()






func _on_ad_error_occurred(placement_id: String, msg: String) -> void :
	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL or placement_id == AD_PLACEMENT_ID_BANNER:

		log_ad_baseline_blocked(placement_id, "sdk_error", "", 
			{"stage": "sdk_callback", "placement_id": placement_id, "message": msg})
	SortLogger.warn("[AdManager] 广告失败：(placement_id=%s, msg=%s)" % [placement_id, msg])
	_clear_fullscreen_ad(placement_id)






func _on_ad_impression_received(data: Dictionary) -> void :
	SortLogger.mark("收到广告有效展示信息：(data=%s)" % JSON.stringify(data))
	ad_impression_received.emit(data)
	if str(data.get("placement_id", "")) == AD_PLACEMENT_ID_BANNER or str(data.get("ad_type", "")) == "banner":
		log_ad_baseline_event("banner", "banner_impression", str(data.get("position", "")))



























func _show_ad_with_show_id(placement_id: String, position: String, ad_show_id: String, 
		reward_request: Dictionary = {}) -> bool:
	SortLogger.mark("广告时机 Id 与库存判断：(ad_show_id=%s)" % ad_show_id)
	var ready: bool = await _ad_module().is_ad_ready(placement_id, position, ad_show_id)
	if not ready:
		if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
			log_ad_baseline_blocked("interstitial", "inventory_not_ready", position, 
				{"stage": "show", "placement_id": placement_id, "ad_show_id": ad_show_id})
		SortLogger.mark("库存判断未通过，跳过展示：(placement_id=%s, position=%s)" % [placement_id, position])
		return false
	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
		log_ad_baseline_event("interstitial", "inventory_ready", position, {"ad_show_id": ad_show_id})

	if not _fullscreen_ad_placement.is_empty()\
	or (placement_id != AD_PLACEMENT_ID_REWARD and _reward_ad_in_flight):
		SortLogger.mark("已有广告展示或激励结算在进行，跳过展示：(placement_id=%s)" % placement_id)
		if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
			log_ad_baseline_blocked("interstitial", "fullscreen_ad_busy", position, {"ad_show_id": ad_show_id})
		return false




	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
		_track_ad(TrackingEvents.EV_AD_IS_FILL, placement_id, position, ad_show_id)
	if placement_id == AD_PLACEMENT_ID_REWARD:

		if not _reward_request.is_empty() and not _reward_request["rewarded"]:
			SortLogger.info("[RewardAd] 下一次展示结束旧奖励关联 position=%s show_id=%s" % [
				_reward_request["position"], _reward_request["show_id"]])
		_reward_request = reward_request
		_reward_result = false
	_fullscreen_ad_placement = placement_id
	fullscreen_ad_active_changed.emit(true)
	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
		log_ad_baseline_event("interstitial", "inter_request", position, {"ad_show_id": ad_show_id})
	_ad_module().show_ad(placement_id, position, ad_show_id)


	await _await_ad_will_show(placement_id)
	_track_ad(TrackingEvents.EV_AD_REAL_SHOW, placement_id, position, ad_show_id)

	ad_real_shown.emit(placement_id, position)
	if placement_id == AD_PLACEMENT_ID_INTERSTITIAL:
		log_ad_baseline_event("interstitial", "inter_started", position, {"ad_show_id": ad_show_id})
	return true







func _track_ad(event_name: String, placement_id: String, position: String, 
		ad_show_id: String) -> void :
	var tracked_positions: Array = []
	match placement_id:
		AD_PLACEMENT_ID_INTERSTITIAL:
			tracked_positions = [TrackingEvents.AD_POSITION_GAME_END, 
				TrackingEvents.AD_POSITION_GAME_RESTART]
		AD_PLACEMENT_ID_REWARD:
			tracked_positions = [TrackingEvents.AD_POSITION_HINT, 
				TrackingEvents.AD_POSITION_UNDO, TrackingEvents.AD_POSITION_ROPE, 
				TrackingEvents.AD_POSITION_FILL_POT, 
				TrackingEvents.AD_POSITION_FINISH_AD_REWARD, 
				TrackingEvents.AD_POSITION_SPECIAL_CHALLENGE]
	if not (position in tracked_positions):
		return
	Tracker.send_event(event_name, {
		TrackingEvents.K_AD_SHOW_ID: ad_show_id, 
		TrackingEvents.K_PLACEMENT: placement_id, 
		TrackingEvents.K_POSITION: position, 
	})










func _await_ad_will_show(placement_id: String) -> void :
	while true:
		var shown_id: String = await _ad_module().ad_will_show
		if shown_id == placement_id:
			return






func _await_ad_closed(placement_id: String) -> void :
	while true:
		var closed_id: String = await _ad_module().ad_closed
		if closed_id == placement_id:
			return






















var _last_interstitial_closed_msec: int = -1




func show_interstitial_and_await(position: String) -> void :
	SortLogger.mark("展示插屏广告并等待结束：(position=%s)" % position)
	if _debug_no_ads():
		SortLogger.mark("debug 去广告已开启，跳过插屏")
		log_ad_baseline_blocked("interstitial", "debug_no_ads", position, {"stage": "show"})
		return
	var cooldown_msec: int = ABManager.inter_cd_by_day.get_cd_seconds(UserState.get_install_days()) * 1000
	var now: int = Time.get_ticks_msec()
	if _last_interstitial_closed_msec >= 0 and now - _last_interstitial_closed_msec < cooldown_msec:
		SortLogger.mark("命中插屏冷却，跳过本次展示")
		log_ad_baseline_blocked("inter_cd_by_day", "cooldown", position, 
			{"stage": "show", "cooldown_msec": cooldown_msec, 
			"last_closed_msec": _last_interstitial_closed_msec, 
			"elapsed_msec": now - _last_interstitial_closed_msec, 
			"remaining_msec": cooldown_msec - (now - _last_interstitial_closed_msec)})
		return
	log_ad_baseline_cooldown(position, cooldown_msec, now)
	var shown: bool = await _try_show_interstitial(position)
	if shown:
		_last_interstitial_closed_msec = Time.get_ticks_msec()
		log_ad_baseline_event("inter_cd_by_day", "cooldown_started", position, 
			{"last_closed_msec": _last_interstitial_closed_msec})
	else:
		log_ad_baseline_event("interstitial", "not_shown", position)







func _try_show_interstitial(position: String) -> bool:

	var placement_id: String = AD_PLACEMENT_ID_INTERSTITIAL
	SortLogger.mark("检查插屏库存并展示：(placement_id=%s, position=%s)" % [placement_id, position])
	var module: Variant = _ad_module()


	var ad_show_id: String = module.create_show_id()
	_track_ad(TrackingEvents.EV_AD_SHOW_TIMING, placement_id, position, ad_show_id)
	var shown: bool = await _show_ad_with_show_id(placement_id, position, ad_show_id)
	if shown:

		await _await_ad_closed(placement_id)
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), shown])
	return shown



















































signal reward_ad_loaded



signal ad_real_shown(placement_id: String, position: String)

signal fullscreen_ad_active_changed(active: bool)
var _fullscreen_ad_placement: String = ""


func _clear_fullscreen_ad(placement_id: String) -> void :
	if _fullscreen_ad_placement.is_empty() or placement_id != _fullscreen_ad_placement:
		return
	_fullscreen_ad_placement = ""
	fullscreen_ad_active_changed.emit(false)



signal ad_impression_received(data: Dictionary)









var _reward_show_ids: Dictionary = {}



const _KEY_REWARD_SHOW_ID: String = "show_id"
const _KEY_REWARD_FILL_TRACKED: String = "fill_tracked"


var _reward_result: bool = false
const REWARD_SETTLE_MSEC: int = 2000
var _reward_ad_in_flight: bool = false

var _reward_request: Dictionary = {}






















func check_reward_ads_available(position: String) -> bool:
	SortLogger.mark("查询激励广告是否可用：(position=%s)" % position)
	if _debug_no_ads():
		SortLogger.mark("debug 去广告已开启，视为可用")
		return true
	var module: Variant = _ad_module()
	var ad_show_id: String = module.create_show_id()
	_track_ad(TrackingEvents.EV_AD_SHOW_TIMING, AD_PLACEMENT_ID_REWARD, position, ad_show_id)



	var entry: Dictionary = {
		_KEY_REWARD_SHOW_ID: ad_show_id, 
		_KEY_REWARD_FILL_TRACKED: false, 
	}
	_reward_show_ids[position] = entry
	var valid: bool = await module.is_reward_valid(AD_PLACEMENT_ID_REWARD, position)
	if valid:
		entry[_KEY_REWARD_FILL_TRACKED] = true
		_track_ad(TrackingEvents.EV_AD_IS_FILL, AD_PLACEMENT_ID_REWARD, position, ad_show_id)
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), valid])
	return valid




















func show_reward_ad_and_await(position: String, on_late_reward: Callable = Callable()) -> bool:
	SortLogger.mark("展示激励广告并等待结果：(position=%s)" % position)
	if _reward_ad_in_flight or not _fullscreen_ad_placement.is_empty():
		SortLogger.mark("已有广告展示或激励结算在进行，跳过重复请求")
		return false
	if _debug_no_ads():
		SortLogger.mark("debug 去广告已开启，不展示直接发奖")
		return true
	_reward_ad_in_flight = true
	var module: Variant = _ad_module()
	var entry: Dictionary = _reward_show_ids.get(position, {})



	var ad_show_id: String = ""
	if _reward_show_ids.has(position):
		ad_show_id = _reward_show_ids[position][_KEY_REWARD_SHOW_ID]
	else:
		ad_show_id = module.create_show_id()
		SortLogger.mark("该 position 没有已绑定的时机 Id，兜底新建：(ad_show_id=%s)" % ad_show_id)


		_track_ad(TrackingEvents.EV_AD_SHOW_TIMING, AD_PLACEMENT_ID_REWARD, position, ad_show_id)
	var request: Dictionary = {"position": position, "show_id": ad_show_id, 
		"rewarded": false, "closed": false, "closed_msec": 0, 
		"returned": false, "on_late_reward": on_late_reward}
	var shown: bool = await _show_ad_with_show_id(AD_PLACEMENT_ID_REWARD, position, ad_show_id, request)
	if not shown:
		_reward_ad_in_flight = false
		SortLogger.mark("激励广告库存判断未通过，未触发展示")
		return false


	while not request["closed"]:
		await get_tree().process_frame

	var deadline: int = int(request["closed_msec"]) + REWARD_SETTLE_MSEC
	while not request["rewarded"] and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	request["returned"] = true
	var rewarded: bool = request["rewarded"]
	if rewarded:
		request["on_late_reward"] = Callable()
	else:
		SortLogger.info("[RewardAd] 关闭后结算超时 position=%s show_id=%s late_callback=%s" % [
			position, ad_show_id, on_late_reward.is_valid()])

	if not entry.is_empty() and is_same(_reward_show_ids.get(position, {}), entry):
		_reward_show_ids.erase(position)
	_reward_ad_in_flight = false
	SortLogger.mark("%s 返回：(%s)" % [_module_label(module), rewarded])
	return rewarded











func peek_last_reward_result() -> bool:
	return _reward_result











func _load_banner() -> void :
	if _banner_load_triggered:
		return
	_banner_load_triggered = true
	_ad_module().load_ad(AD_PLACEMENT_ID_BANNER)







func show_banner(position: String, offset_base: int, height_base: int) -> void :
	SortLogger.mark("展示 Banner：(placement=%s, position=%s, offset=%d, height=%d)"
		%[AD_PLACEMENT_ID_BANNER, position, offset_base, height_base])
	if _debug_no_ads():
		SortLogger.mark("debug 去广告已开启，跳过 Banner")
		log_ad_baseline_blocked("banner", "debug_no_ads", position, {"stage": "show"})
		return
	var module: Variant = _ad_module()
	var final_offset_base: int = _native_banner_offset_base(module, offset_base)
	if final_offset_base != offset_base:
		SortLogger.mark("Banner 偏移抵消原生安全区下推：(传入=%d, 实际=%d)"
			%[offset_base, final_offset_base])

	_load_banner()
	log_ad_baseline_event("banner_unlock_level", "banner_request", position, {"stage": "show"})
	module.show_banner(AD_PLACEMENT_ID_BANNER, position, true, final_offset_base, height_base)









func _native_banner_offset_base(module: Variant, offset_base: int) -> int:
	if module == _editor_ads or not OS.has_feature("ios"):
		return offset_base
	var vp_w: float = UiMetrics.viewport_size().x
	if vp_w <= 0.0:
		return offset_base
	return offset_base - int(round(UiMetrics.system_insets().y * 1080.0 / vp_w))




func hide_banner() -> void :
	SortLogger.mark("隐藏 Banner：(placement=%s)" % AD_PLACEMENT_ID_BANNER)
	_ad_module().destroy_ad(AD_PLACEMENT_ID_BANNER)





func log_ad_baseline_conditions(position: String, context: Dictionary = {}) -> void :
	if not AdBaselineDiagnostics.enabled():
		return
	var stage: String = str(context.get("stage", "show_gate"))
	if not stage.ends_with("preload"):
		AdBaselineDiagnostics.log_interstitial(position, context, _ad_baseline_cooldown_snapshot())
	if position == TrackingEvents.AD_POSITION_GAME_PAGE:
		AdBaselineDiagnostics.log_banner(position, context)


func log_ad_baseline_banner(context: Dictionary) -> void :
	AdBaselineDiagnostics.log_banner(TrackingEvents.AD_POSITION_GAME_PAGE, context)



func log_ad_baseline_blocked(key: String, reason: String, position: String, 
		context: Dictionary = {}) -> void :
	if not AdBaselineDiagnostics.enabled():
		return
	var stage: String = str(context.get("stage", "show"))
	if stage == "finish_gate" or stage == "restart_gate":
		AdBaselineDiagnostics.log_interstitial(position, context, _ad_baseline_cooldown_snapshot(), reason)
	elif stage.ends_with("preload") or stage == "show_gate" or stage == "hide":
		AdBaselineDiagnostics.log_banner(position, context, reason)
	elif key == "inter_cd_by_day":
		AdBaselineDiagnostics.log_cooldown(position, stage, 
			ABManager.inter_cd_by_day.get_log_snapshot(UserState.get_install_days()), 
			_ad_baseline_cooldown_snapshot(context), "；本次预期：仍在冷却期，不展示插屏")
	else:
		AdBaselineDiagnostics.log_event(key, reason, position, context)



func log_ad_baseline_cooldown(position: String, cooldown_msec: int, now: int) -> void :
	if not AdBaselineDiagnostics.enabled():
		return
	AdBaselineDiagnostics.log_cooldown(position, "show", 
		ABManager.inter_cd_by_day.get_log_snapshot(UserState.get_install_days()), 
		_ad_baseline_cooldown_snapshot({"cooldown_msec": cooldown_msec, "now": now}), 
		"；本次冷却已通过，下一步检查SDK库存；尚未确认真实展示")


func log_ad_baseline_event(key: String, event: String, position: String, 
		context: Dictionary = {}) -> void :
	AdBaselineDiagnostics.log_event(key, event, position, context)
	if AdBaselineDiagnostics.enabled() and event == "cooldown_started":
		AdBaselineDiagnostics.log_cooldown(position, "show", 
			ABManager.inter_cd_by_day.get_log_snapshot(UserState.get_install_days()), 
			_ad_baseline_cooldown_snapshot(), "；本次刚关闭广告，以上为下次尝试时的冷却条件快照")



func _ad_baseline_cooldown_snapshot(context: Dictionary = {}) -> Dictionary:
	var now: int = int(context.get("now", Time.get_ticks_msec()))
	var config: Dictionary = ABManager.inter_cd_by_day.get_log_snapshot(UserState.get_install_days())
	var cooldown_msec: int = int(context.get("cooldown_msec", int(config["effective"]) * 1000))
	var elapsed: int = int(context.get("elapsed_msec", now - _last_interstitial_closed_msec if _last_interstitial_closed_msec >= 0 else 0))
	var allowed: bool = _last_interstitial_closed_msec < 0 or elapsed >= cooldown_msec
	return {"last_closed_msec": _last_interstitial_closed_msec, "cooldown_msec": cooldown_msec, 
		"elapsed_msec": elapsed, "remaining_msec": 0 if allowed else cooldown_msec - elapsed, 
		"allowed": allowed}



func _bind_ad_baseline_config_logs() -> void :
	if not AdBaselineDiagnostics.enabled():
		return
	if not ABManager.init_done.is_connected(_on_ad_baseline_config_ready):
		ABManager.init_done.connect(_on_ad_baseline_config_ready)
		ABManager.params_updated.connect(_on_ad_baseline_params_updated)
		ABManager.remote_config_ready.connect(_on_ad_baseline_config_updated)
	if ABManager.is_ab_init_done():
		_on_ad_baseline_config_ready()


func _on_ad_baseline_config_ready() -> void :
	log_ad_baseline_conditions(TrackingEvents.AD_POSITION_GAME_PAGE, {"stage": "config_ready"})


func _on_ad_baseline_params_updated(_update_type: String, _user_info: Dictionary) -> void :
	_on_ad_baseline_config_updated()


func _on_ad_baseline_config_updated() -> void :
	log_ad_baseline_conditions(TrackingEvents.AD_POSITION_GAME_PAGE, {"stage": "config_updated"})





func _debug_no_ads() -> bool:
	return UserState.is_debug_no_ads()




func set_mute_ad(mute: bool) -> void :
	SortLogger.mark("设置广告静音：(mute=%s)" % mute)
	_ad_module().set_mute_ad(mute)




func register_uid2(email: String) -> void :
	SortLogger.mark("注册 UID2 邮箱：(email=%s)" % email)
	_ad_module().register_uid2(email)




func open_ad_debug_view() -> void :
	SortLogger.mark("打开广告调试界面")
	_ad_module().open_ad_debug_view()
