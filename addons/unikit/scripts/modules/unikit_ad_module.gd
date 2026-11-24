class_name UniKitAdModule
extends UniKitModuleBase

signal ad_loaded(placement_id: String)
signal ad_closed(placement_id: String)
signal ad_rewarded(placement_id: String)
signal ad_error_occurred(placement_id: String, msg: String)
signal ad_impression_received(data: Dictionary)
signal ad_will_show(placement_id: String)
signal ad_init_completed
signal ad_is_ready_result(placement_id: String, is_ready: bool)
signal ad_is_valid_result(placement_id: String, is_valid: bool)

var _is_ad_inited: bool = false


func load_ad(placement_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.loadAd(placement_id)


func create_show_id() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.createShowId()


func is_ad_ready(placement_id: String, position: String, show_id: String) -> bool:
	if _host._plugin == null:
		return false
	_host._plugin.isAdReady(placement_id, position, show_id)
	return await _await_ad_is_ready(placement_id)


func show_ad(placement_id: String, position: String, show_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.showAd(placement_id, position, show_id)


func try_show_interstitial(placement_id: String, position: String) -> bool:
	if _host._plugin == null:
		return false
	var show_id: String = _host._plugin.createShowId()
	_host._plugin.isAdReady(placement_id, position, show_id)
	if not await _await_ad_is_ready(placement_id):
		return false
	_host._plugin.showAd(placement_id, position, show_id)
	return true


func show_reward(placement_id: String, position: String) -> void :
	if _host._plugin == null:
		return
	var show_id: String = _host._plugin.createShowId()
	_host._plugin.isAdReady(placement_id, position, show_id)
	if await _await_ad_is_ready(placement_id):
		_host._plugin.showAd(placement_id, position, show_id)

func is_reward_valid(placement_id: String, position: String) -> bool:
	if _host._plugin == null:
		return false
	_host._plugin.isAdValid(placement_id, position)
	return await _await_ad_is_valid(placement_id)

func is_banner_valid(placement_id: String, position: String) -> bool:
	if _host._plugin == null:
		return false
	_host._plugin.isAdValid(placement_id, position)
	return await _await_ad_is_valid(placement_id)

func is_interstitial_valid(placement_id: String, position: String) -> bool:
	if _host._plugin == null:
		return false
	_host._plugin.isAdValid(placement_id, position)
	return await _await_ad_is_valid(placement_id)


func _await_ad_is_ready(placement_id: String) -> bool:
	while true:
		var r: Array = await ad_is_ready_result
		if r[0] == placement_id:
			return r[1]
	return false


func _await_ad_is_valid(placement_id: String) -> bool:
	while true:
		var r: Array = await ad_is_valid_result
		if r[0] == placement_id:
			return r[1]
	return false





func show_banner(placement_id: String, position: String, anchor_bottom: bool = true, offset_base: int = 0, height_base: int = 180) -> void :
	if _host._plugin == null:
		return
	var device_w_px: float = float(DisplayServer.window_get_size().x)
	var scale: float = device_w_px / 1080.0
	var offset_px: int = int(round(offset_base * scale))
	var height_px: int = int(round(height_base * scale))
	_host._plugin.showBanner(placement_id, position, anchor_bottom, offset_px, height_px)


func pause_ad(placement_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.pauseAd(placement_id)


func resume_ad(placement_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.resumeAd(placement_id)


func destroy_ad(placement_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.destroyAd(placement_id)


func open_ad_debug_view() -> void :
	if _host._plugin == null:
		return
	_host._plugin.openAdDebugView()


func set_mute_ad(mute: bool) -> void :
	if _host._plugin == null:
		return
	_host._plugin.setMuteAd(mute)


func register_uid2(email: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.registerUid2(email)


func is_ad_inited() -> bool:
	return _is_ad_inited




func debug_mock_ad_load_fail() -> void :
	if _host._plugin == null:
		return
	if not OS.has_feature("ios"):
		return
	_host._plugin.debugMockAdLoadFail()
