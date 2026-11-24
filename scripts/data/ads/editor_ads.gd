class_name EditorAds
extends RefCounted





















const AD_MOCK_DEFAULT: int = MockUnikitConfig.MockState.TRUE











signal ad_loaded(placement_id: String)
signal ad_closed(placement_id: String)
signal ad_rewarded(placement_id: String)
signal ad_error_occurred(placement_id: String, msg: String)
signal ad_impression_received(data: Dictionary)
signal ad_will_show(placement_id: String)
signal ad_init_completed
signal ad_is_ready_result(placement_id: String, is_ready: bool)
signal ad_is_valid_result(placement_id: String, is_valid: bool)










func load_ad(placement_id: String) -> void :
	await (Engine.get_main_loop() as SceneTree).create_timer(5.0).timeout
	if not _mock_is_ready(placement_id):
		return
	ad_loaded.emit(placement_id)


func create_show_id() -> String:
	return "test_ad_show_id"


func is_ad_ready(placement_id: String, _position: String, _show_id: String) -> bool:
	return _mock_is_ready(placement_id)







func show_ad(placement_id: String, _position: String, _show_id: String) -> void :
	SceneManager.show_toast("编辑器模拟广告：%s 已展示（无真实广告）" % placement_id)
	_mock_emit_show_started(placement_id)
	if placement_id == AdManager.AD_PLACEMENT_ID_REWARD and _mock_should_grant_reward():
		ad_rewarded.emit(placement_id)
	_mock_emit_closed(placement_id)








func try_show_interstitial(placement_id: String, _position: String) -> bool:
	_mock_show_and_close(placement_id)
	return false







func show_reward(placement_id: String, _position: String) -> void :
	_mock_show_and_close(placement_id)


func is_reward_valid(placement_id: String, _position: String) -> bool:
	return _mock_is_ready(placement_id)





func is_banner_valid(_placement_id: String, _position: String) -> bool:
	return _mock_is_ready(AdManager.AD_PLACEMENT_ID_BANNER)




func is_interstitial_valid(_placement_id: String, _position: String) -> bool:
	return _mock_is_ready(AdManager.AD_PLACEMENT_ID_INTERSTITIAL)




const FAKE_BANNER_LAYER: int = 200


const FAKE_BANNER_BG_COLOR: Color = Color(0.78, 0.78, 0.78, 1.0)
const FAKE_BANNER_TEXT_COLOR: Color = Color(0.827, 0.184, 0.184, 1.0)


var _fake_banner_layer: CanvasLayer = null




func show_banner(placement_id: String, _position: String, _anchor_bottom: bool = true, offset_base: int = 0, height_base: int = 180) -> void :
	if placement_id != AdManager.AD_PLACEMENT_ID_BANNER:
		return
	if not _mock_is_ready(placement_id):
		_destroy_fake_banner()
		return
	_show_fake_banner(offset_base, height_base)





func _show_fake_banner(offset_base: int, height_base: int) -> void :
	var vp_w: float = UiMetrics.viewport_size().x
	var logical_scale: float = vp_w / 1080.0
	var height: float = float(height_base) * logical_scale
	var bottom_offset: float = float(offset_base) * logical_scale
	if _fake_banner_layer == null:
		var panel: = ColorRect.new()
		panel.name = "FakeBannerAd"
		panel.color = FAKE_BANNER_BG_COLOR
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.anchor_left = 0.0
		panel.anchor_right = 1.0
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		var label: = Label.new()
		label.name = "Text"
		label.text = "Banner 广告"
		label.add_theme_color_override("font_color", FAKE_BANNER_TEXT_COLOR)
		label.add_theme_font_size_override("font_size", 48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		_fake_banner_layer = CanvasLayer.new()
		_fake_banner_layer.name = "FakeBannerAdLayer"
		_fake_banner_layer.layer = FAKE_BANNER_LAYER
		_fake_banner_layer.add_child(panel)
		(Engine.get_main_loop() as SceneTree).root.add_child(_fake_banner_layer)
	var banner_panel: Control = _fake_banner_layer.get_child(0) as Control
	banner_panel.offset_left = 0.0
	banner_panel.offset_right = 0.0
	banner_panel.offset_top = - bottom_offset - height
	banner_panel.offset_bottom = - bottom_offset



func _destroy_fake_banner() -> void :
	if _fake_banner_layer == null:
		return
	_fake_banner_layer.queue_free()
	_fake_banner_layer = null


func pause_ad(_placement_id: String) -> void :
	pass


func resume_ad(_placement_id: String) -> void :
	pass



func destroy_ad(placement_id: String) -> void :
	if placement_id != AdManager.AD_PLACEMENT_ID_BANNER:
		return
	_destroy_fake_banner()



func open_ad_debug_view() -> void :
	SceneManager.show_toast("打开广告调试界面，请在真机上使用")


func set_mute_ad(_mute: bool) -> void :
	pass


func register_uid2(_email: String) -> void :
	pass









func _mock_show_and_close(placement_id: String) -> void :
	SceneManager.show_toast("编辑器模拟广告：%s 已展示" % placement_id)
	_mock_emit_show_started(placement_id)
	_mock_emit_closed(placement_id)








func _mock_emit_show_started(placement_id: String) -> void :
	await (Engine.get_main_loop() as SceneTree).process_frame
	ad_will_show.emit(placement_id)













func _mock_emit_closed(placement_id: String) -> void :
	await (Engine.get_main_loop() as SceneTree).process_frame
	await (Engine.get_main_loop() as SceneTree).process_frame

	ad_closed.emit(placement_id)




func _mock_enabled() -> bool:
	return MockUnikitConfig.is_mock_enabled(OS.has_feature("editor"))








func _mock_is_ready(placement_id: String) -> bool:
	if not _mock_enabled():
		return true
	var mock: int
	if placement_id == AdManager.AD_PLACEMENT_ID_REWARD:
		mock = MockUnikitConfig.get_mock_reward_ad_ready(AD_MOCK_DEFAULT)
	elif placement_id == AdManager.AD_PLACEMENT_ID_BANNER:
		mock = MockUnikitConfig.get_mock_banner_ad_ready(AD_MOCK_DEFAULT)
	else:
		mock = MockUnikitConfig.get_mock_inter_ad_ready(AD_MOCK_DEFAULT)
	return mock != MockUnikitConfig.MockState.FALSE




func _mock_should_grant_reward() -> bool:
	if not _mock_enabled():
		return true
	return MockUnikitConfig.get_mock_reward_ad_result(AD_MOCK_DEFAULT) != MockUnikitConfig.MockState.FALSE







func is_ad_inited() -> bool:
	return true


func debug_mock_ad_load_fail() -> void :
	pass
