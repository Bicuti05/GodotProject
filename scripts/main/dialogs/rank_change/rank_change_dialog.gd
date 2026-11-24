class_name RankChangeDialog
extends PageScene


signal closed

const TIER_PITCH: float = 540.0
const BADGE_SIZE: float = 560.0
const MIN_SCALE: float = 0.6
const SIDE_BADGE_ALPHA: float = 0.4
const ONE_LEVEL_MOVE_SEC: float = 0.5
const TIER_NAME_KEY_FMT: String = "RANK_LEVEL_%d"

const TIPS_KEY_UP: String = "RANK_UP_CONTENT"
const TIPS_KEY_SAME: String = "RANK_MAINTAINED_CONTENT"
const TIPS_KEY_DOWN: String = "RANK_DOWN_CONTENT"
const TIPS_HIGHLIGHT_COLOR: String = "fff091"
const BTN_KEY_CLAIM: String = "SPECIAL_CHALLENGE_CLAIM"
const BTN_KEY_OK: String = "COMMON_GOT_IT"


const CLAIM_PANEL_FADE_SEC: float = 0.18
const CLAIM_SOURCE_FADE_SEC: float = 0.3
const CLAIM_PANEL_OUT_SEC: float = 0.24
const CLAIM_ITEM_SIZE: float = 200.0
const CLAIM_FLY_Z: int = 200
const CLAIM_FLY_MAX: int = 6
const CLAIM_PUNCH_PEAK: float = 1.22
const CLAIM_PUNCH_RECOVER: float = 0.18


const CLAIM_SPAWN_INTERVAL: float = 0.09

const REWARD_TOP: float = 1534.0
const REWARD_TIPS_GAP: float = 45.0
const REWARD_BUTTON_GAP: float = 54.0
const REWARD_SIDE_CENTER: float = 190.0

const COIN_FONT_MAX: int = 64
const COIN_FONT_MIN: int = 36
const COIN_HUD_WIDTH: float = 270.0
const COIN_ICON_SIZE: float = 88.0
const COIN_ICON_VISIBLE_INSET_LEFT: float = 7.0
const COIN_ICON_VISIBLE_WIDTH: float = 74.0
const COIN_ICON_TEXT_GAP: float = 8.0
const COIN_GROUP_EDGE_PAD: float = 14.0
const COIN_TEXT_MAX_W: float = COIN_HUD_WIDTH - COIN_GROUP_EDGE_PAD * 2.0\
- COIN_ICON_VISIBLE_WIDTH - COIN_ICON_TEXT_GAP

@onready var _fx: RankChangeEffect = $Root / Content / ChangeEffect
@onready var _title: Label = $Root / Content / Title
@onready var _badge_row: Control = $Root / Content / BadgeRow
@onready var _track: Control = $Root / Content / BadgeRow / Track
@onready var _tips: RichTextLabel = $Root / Content / Tips
@onready var _reward_box: Control = $Root / Content / RewardBox
@onready var _reward_icon: TextureRect = $Root / Content / RewardBox / Icon
@onready var _reward_halo: TextureRect = $Root / Content / RewardBox / Halo
@onready var _reward_count: Label = $Root / Content / RewardBox / Count
@onready var _coin_box: Control = $Root / Content / CoinBox
@onready var _coin_icon: TextureRect = $Root / Content / CoinBox / Icon
@onready var _coin_halo: TextureRect = $Root / Content / CoinBox / Halo
@onready var _coin_count: Label = $Root / Content / CoinBox / Count
@onready var _action_btn: CommonBtn = $Root / Content / ActionButton
@onready var _anim: AnimationPlayer = $Root / AnimationPlayer
@onready var _confetti: ConfettiFx = $Root / Confetti

@onready var _claim_panel: Control = $Root / ClaimPanel
@onready var _coin_pill: Control = $Root / ClaimPanel / CoinPill
@onready var _coin_pill_icon: TextureRect = $Root / ClaimPanel / CoinPill / CoinIcon
@onready var _coin_pill_label: Label = $Root / ClaimPanel / CoinPill / CoinLabel
@onready var _hint_counter: PropBtn = $Root / ClaimPanel / HintCounter
@onready var _hint_counter_icon: TextureRect = $Root / ClaimPanel / HintCounter / Icon
@onready var _hint_counter_badge: Label = $Root / ClaimPanel / HintCounter / Badge / Number

var _badges: Array[RankBadgeView] = []

var _start_tier: int = RankSettleLogic.TIER_MIN
var _end_tier: int = RankSettleLogic.TIER_MIN
var _rank_pos: int = -1
var _reward_hint: int = 0
var _reward_coin: int = 0
var _closing: bool = false
var _preview: bool = false
var _event_id: String = ""
@onready var _hint_fly: RankCollectFlyLayer = $Root / ClaimPanel / HintFly
@onready var _coin_fly: RankCollectFlyLayer = $Root / ClaimPanel / CoinFly
var _claiming: bool = false
var _punch_tweens: Dictionary = {}
var _center_tier: float = float(RankSettleLogic.TIER_MIN)
var _slide_tween: Tween = null
var _claim_tweens: Array[Tween] = []
var _show_token: int = 0


func _ready() -> void :
	_prepare_popup_animation()
	resized.connect(_layout_claim_coin_hud)
	get_viewport().size_changed.connect(_layout_claim_coin_hud)
	_layout_claim_coin_hud()
	_hint_counter.configure(PropBtn.PropType.HINT)
	_tips.resized.connect(_layout_reward_area)
	for child in _track.get_children():
		if child is RankBadgeView:
			var badge: = child as RankBadgeView
			badge.set_tier(_badges.size() + 1)
			_badges.append(badge)
	if _badges.size() != RankSettleLogic.TIER_MAX:
		SortLogger.error("RankChangeDialog: 徽章数 %d != 段位档数 %d,检查 .tscn" % [
			_badges.size(), RankSettleLogic.TIER_MAX])


func _prepare_popup_animation() -> void :

	var library: AnimationLibrary = _anim.get_animation_library(&"").duplicate()
	var animation: Animation = library.get_animation(&"GenericPopup").duplicate()
	var overlay_track: int = animation.find_track(NodePath("Overlay:self_modulate"), Animation.TYPE_VALUE)
	var color: Color = animation.track_get_key_value(overlay_track, 0)
	color.a = 1.0
	animation.track_set_key_value(overlay_track, 0, color)
	library.remove_animation(&"GenericPopup")
	library.add_animation(&"GenericPopup", animation)
	_anim.remove_animation_library(&"")
	_anim.add_animation_library(&"", library)


func _on_show(params: Dictionary = {}) -> void :
	set_meta(RankSessionFlow.DIALOG_LEASE, null)
	_closing = false
	_claiming = false
	_show_token += 1
	var token: int = _show_token
	_kill_slide()
	SceneManager.reset_button_feedback(_action_btn)
	_hint_fly.cancel_all()
	_coin_fly.cancel_all()
	_confetti.reset()

	_preview = bool(params.get("preview", false))
	_event_id = String(params.get("event_id", ""))
	_rank_pos = int(params.get("rank_pos", -1))
	_start_tier = clampi(int(params.get("start_tier", RankSettleLogic.TIER_MIN)), 
		RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX)
	_end_tier = clampi(int(params.get("end_tier", _start_tier)), 
		RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX)
	_reward_hint = maxi(int(params.get("reward_hint", 0)), 0)
	_reward_coin = maxi(int(params.get("reward_coin", 0)), 0)



	if not _preview:
		var info: Dictionary = RankManager.get_challenge_info_params()
		if not info.is_empty():
			info[TrackingEvents.K_CHALLENGE_RANK] = _rank_pos
			info[TrackingEvents.K_CHALLENGE_LEVEL] = _start_tier
			Tracker.track_challenge_info(TrackingEvents.CHALLENGE_STATE_END, info, 
				TrackingEvents.CHALLENGE_POSITION_END)

	_center_tier = float(_start_tier)
	_layout_badges()
	_fx.stop_all()

	_tips.text = _build_tips_text()
	_reward_box.visible = _reward_hint > 0
	_reward_count.text = str(_reward_hint)
	_coin_box.visible = _reward_coin > 0
	_coin_count.text = str(_reward_coin)
	_action_btn.btn_text = BTN_KEY_CLAIM if _reward_hint > 0 or _reward_coin > 0 else BTN_KEY_OK
	_reset_claim_panel()
	_layout_claim_coin_hud()
	_layout_reward_area()
	_action_btn.disabled = true

	visible = true

	if not _preview:
		Tracker.track_scr_show(TrackingEvents.SCR_CHALLENGE_END)
	_anim.play_section_with_markers("GenericPopup", &"", &"Mark")
	_anim.advance(0.0)
	while token == _show_token and _anim.is_playing():
		await get_tree().process_frame
	if token != _show_token or _closing:
		return
	await _play_slide()
	if token != _show_token or _closing:
		return
	_action_btn.disabled = false


func _play_slide() -> void :
	var token: int = _show_token
	if _end_tier == _start_tier:
		_center_fx_on_badge(_start_tier)
		AudioManager.play_sfx(&"rank_unchanged")
		_fx.play_unchanged()
		return
	var span: int = absi(_end_tier - _start_tier)
	_slide_tween = create_tween()
	_slide_tween.tween_method(_set_center_tier, float(_start_tier), float(_end_tier), 
		ONE_LEVEL_MOVE_SEC * float(span))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var tw: Tween = _slide_tween
	while token == _show_token and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if token != _show_token or _closing:
		return
	_center_fx_on_badge(_end_tier)
	if _end_tier > _start_tier:
		AudioManager.play_sfx(&"rank_promote")
		_fx.play_upgrade()
		_confetti.play()
	else:
		AudioManager.play_sfx(&"rank_demote")
		_fx.play_downgrade()


func _center_fx_on_badge(tier: int) -> void :
	var idx: int = tier - 1
	if _fx == null or idx < 0 or idx >= _badges.size():
		return
	var badge: RankBadgeView = _badges[idx]
	if badge != null:
		_fx.global_position = badge.get_global_rect().get_center()


func _set_center_tier(value: float) -> void :
	_center_tier = value
	_layout_badges()


func _layout_badges() -> void :
	var track_w: float = _track.size.x
	var mid_x: float = (track_w if track_w > 0.0 else UiMetrics.viewport_size().x) * 0.5
	for i in _badges.size():
		var badge: RankBadgeView = _badges[i]
		var dx: float = (float(i + 1) - _center_tier) * TIER_PITCH
		badge.position = Vector2(mid_x + dx - BADGE_SIZE * 0.5, 0.0)
		var s: float = _scale_at(dx)
		badge.scale = Vector2(s, s)
		badge.modulate.a = lerpf(1.0, SIDE_BADGE_ALPHA, clampf(absf(dx) / TIER_PITCH, 0.0, 1.0))


func _layout_reward_area() -> void :
	if _action_btn == null or _claiming:
		return
	var tips_height: float = float(_tips.get_content_height())
	var tips_bottom: float = _tips.position.y + (tips_height if tips_height > 0.0 else _tips.size.y)
	var reward_y: float = maxf(REWARD_TOP, tips_bottom + REWARD_TIPS_GAP)
	_reward_box.position.y = reward_y
	_coin_box.position.y = reward_y
	var pair: bool = _reward_hint > 0 and _reward_coin > 0
	var coin_center: float = - REWARD_SIDE_CENTER if pair else 0.0
	var hint_center: float = REWARD_SIDE_CENTER if pair else 0.0
	var coin_half: float = _coin_box.size.x * 0.5
	var hint_half: float = _reward_box.size.x * 0.5
	_coin_box.offset_left = coin_center - coin_half
	_coin_box.offset_right = coin_center + coin_half
	_reward_box.offset_left = hint_center - hint_half
	_reward_box.offset_right = hint_center + hint_half
	_action_btn.position.y = reward_y + _reward_box.size.y + REWARD_BUTTON_GAP\
	if _has_reward() else tips_bottom + REWARD_TIPS_GAP
	SceneManager.clear_button_feedback_baseline(_action_btn)


func _scale_at(dx: float) -> float:
	return lerpf(1.0, MIN_SCALE, clampf(absf(dx) / TIER_PITCH, 0.0, 1.0))


func _build_tips_text() -> String:
	var key: String = TIPS_KEY_SAME
	if _end_tier > _start_tier:
		key = TIPS_KEY_UP
	elif _end_tier < _start_tier:
		key = TIPS_KEY_DOWN
	return tr(key) % [_rank_pos, _highlight(tr(TIER_NAME_KEY_FMT % _end_tier))]


func _highlight(value: String) -> String:
	return "[color=#%s]%s[/color]" % [TIPS_HIGHLIGHT_COLOR, value]


func _on_action_pressed() -> void :
	if _closing or _claiming or _action_btn.disabled:
		return

	if not _preview:
		Tracker.track_btn_click(TrackingEvents.BTN_CHALLENGE_BONUS_CLAIM if _has_reward()
			else TrackingEvents.BTN_CHALLENGE_END)
	await _claim()


func _claim() -> void :
	_claiming = true
	_action_btn.disabled = true
	var token: int = _show_token
	var coin_before: int = UserState.get_coins()
	var hint_before: int = UserState.get_prop_count("hint")
	if not _preview and not RankManager.claim_season_reward(_event_id):
		_claiming = false
		_action_btn.disabled = false
		SortLogger.error("[Rank] 赛季领取未完成，保留待领取状态")
		return
	if not _preview:

		var coin_gained: int = UserState.get_coins() - coin_before
		var hint_gained: int = UserState.get_prop_count("hint") - hint_before
		if coin_gained > 0 or hint_gained > 0:
			_report_rank_season_reward(coin_gained, hint_gained)
		var home_page: Node = SceneManager.get_page("home")
		if home_page != null and home_page.visible and home_page.has_method("refresh_coin_hud"):
			home_page.call("refresh_coin_hud")
	if not _preview and _has_reward():
		await _play_claim(coin_before, hint_before)
	if token == _show_token and not _closing:
		_close()




func _report_rank_season_reward(coin_gained: int, hint_gained: int) -> void :
	if coin_gained > 0:
		Tracker.send_event(TrackingEvents.EV_COIN_STATUS, {
			TrackingEvents.K_COIN_CHANGE_REASON: TrackingEvents.REWARD_SOURCE_RANK_SEASON, 
			TrackingEvents.K_COIN_CHANGE_NUM: coin_gained, 
			TrackingEvents.K_COIN_TOTAL_NUM: UserState.get_coins(), 
		})
	if hint_gained > 0:
		Tracker.send_event(TrackingEvents.EV_PROP_GET, {
			TrackingEvents.K_SOURCE: TrackingEvents.REWARD_SOURCE_RANK_SEASON, 
			TrackingEvents.K_PROP_NAME: TrackingEvents.PROP_HINT, 
			TrackingEvents.K_PROP_NUM: hint_gained, 
			TrackingEvents.K_PROP_LEFT: UserState.get_prop_count("hint"), 
		})


func _play_claim(coin_before: int, hint_before: int) -> void :
	var token: int = _show_token
	_prepare_claim_panel(coin_before, hint_before)
	_hide_settle_ui()

	_claim_panel.visible = true

	Tracker.track_scr_show(TrackingEvents.SCR_CHALLENGE_BONUS)
	var t_in: = _create_claim_tween()
	t_in.tween_property(_claim_panel, "modulate:a", 1.0, CLAIM_PANEL_FADE_SEC)
	await _wait_claim_tween(t_in, token)
	if token != _show_token or _closing:
		return

	var flights: Array[Dictionary] = []
	if _reward_hint > 0:
		flights.append(_start_fly(_reward_icon, _reward_box, _hint_counter, 
			_hint_counter_badge, hint_before, _reward_hint, 
			&"prop_reward_arrive", _hint_counter_icon))
	if _reward_coin > 0:
		flights.append(_start_fly(_coin_icon, _coin_box, _coin_pill_icon, 
			_coin_pill_label, coin_before, _reward_coin, 
			&"coin_fly", _coin_pill_icon))
	await _await_all_landed(flights)
	if token != _show_token or _closing:
		return

	var t_out: = _create_claim_tween()
	t_out.tween_property(_claim_panel, "modulate:a", 0.0, CLAIM_PANEL_OUT_SEC)
	await _wait_claim_tween(t_out, token)


func _hide_settle_ui() -> void :
	_reward_halo.visible = false
	_coin_halo.visible = false
	_title.visible = false
	_badge_row.visible = false
	_tips.visible = false
	_action_btn.visible = false
	_fx.stop_all()
	_fx.visible = false
	_confetti.fade_out()


func _start_fly(source_icon: TextureRect, source_slot: Control, punch_target: Control, 
		label: Label, base: int, gain: int, arrive_sound: StringName, 
		dst_icon: TextureRect) -> Dictionary:
	var layer: RankCollectFlyLayer = _hint_fly if arrive_sound == &"prop_reward_arrive" else _coin_fly
	layer.cancel_all()
	var count: int = clampi(gain, 1, CLAIM_FLY_MAX)
	var token: int = _show_token
	var state: Dictionary = {"arrived": 0, "layer": layer}
	var callback: Callable = func(_index: int) -> void :
		if token != _show_token:
			return
		state["arrived"] = int(state["arrived"]) + 1
		_on_reward_item_arrived(arrive_sound, punch_target, label, base, gain, int(state["arrived"]), count)
	layer.item_arrived.connect(callback)
	state["callback"] = callback
	layer.item_size = dst_icon.get_global_rect().size.x
	layer.randomize_item_scale = false
	layer.play(source_icon.get_global_rect().get_center(), count, dst_icon.texture, 
		func() -> Vector2: return dst_icon.get_global_rect().get_center())
	var t_fade: Tween = _create_claim_tween()
	t_fade.tween_property(source_slot, "modulate:a", 0.0, CLAIM_SOURCE_FADE_SEC)
	state["fade"] = t_fade
	return state


func _await_all_landed(flights: Array[Dictionary]) -> void :
	var token: int = _show_token
	while token == _show_token and visible:
		var pending: bool = false
		for flight: Dictionary in flights:
			var layer: RankCollectFlyLayer = flight["layer"]
			pending = pending or layer.is_flying()
		if not pending:
			break
		await get_tree().process_frame
	for flight: Dictionary in flights:
		var layer: RankCollectFlyLayer = flight["layer"]
		var callback: Callable = flight["callback"]
		if layer.item_arrived.is_connected(callback):
			layer.item_arrived.disconnect(callback)

		flight.erase("callback")
		flight.erase("fade")
		flight.erase("layer")


func _on_reward_item_arrived(arrive_sound: StringName, punch_target: Control, 
		label: Label, base: int, gain: int, arrived: int, total_items: int) -> void :
	AudioManager.play_sfx(arrive_sound)
	HapticManager.play_event(HapticManager.Event.BUTTON)
	_punch(punch_target)
	if label != null:
		var shown: int = base + int(round(float(gain) * float(arrived) / float(maxi(total_items, 1))))
		label.text = str(shown)
		if label == _coin_pill_label:
			_layout_coin_pill(label.text)
		elif label == _hint_counter_badge:
			_hint_counter._layout_badge(label.text)


func _punch(node: Control) -> void :
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var prev: Tween = _punch_tweens.get(node) as Tween
	if prev != null and prev.is_valid():
		prev.kill()
	node.scale = Vector2.ONE * CLAIM_PUNCH_PEAK
	var tw: = create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, CLAIM_PUNCH_RECOVER)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_punch_tweens[node] = tw


func _prepare_claim_panel(coin_before: int, hint_before: int) -> void :
	_layout_claim_coin_hud()
	_coin_pill.visible = _reward_coin > 0
	_coin_pill_label.text = str(coin_before)
	_layout_coin_pill(str(coin_before))
	_hint_counter.visible = _reward_hint > 0

	_hint_counter.refresh(_hint_counter.get_unlock_level(), 0, true, false, maxi(hint_before, 1), false)
	_hint_counter_badge.text = str(hint_before)
	_hint_counter._layout_badge(_hint_counter_badge.text)


func _layout_claim_coin_hud() -> void :
	if _coin_pill == null:
		return

	var top: float = 20.0 + UiMetrics.safe_insets().x
	_coin_pill.offset_top = top
	_coin_pill.offset_bottom = top + 116.0


func _layout_coin_pill(text_value: String) -> void :
	var font: Font = _coin_pill_label.get_theme_font("font")
	var fs: int = _coin_pill_label.get_theme_font_size("font_size")
	var text_w: float = 0.0
	if font != null:
		fs = COIN_FONT_MAX
		while true:
			text_w = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fs).x
			if text_w <= COIN_TEXT_MAX_W or fs <= COIN_FONT_MIN:
				break
			fs -= 2
		text_w = minf(text_w, COIN_TEXT_MAX_W)
	_coin_pill_label.add_theme_font_size_override("font_size", fs)
	var group_width: float = COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP + text_w
	var group_left: float = (COIN_HUD_WIDTH - group_width) * 0.5
	_coin_pill_icon.offset_left = group_left - COIN_ICON_VISIBLE_INSET_LEFT
	_coin_pill_icon.offset_right = _coin_pill_icon.offset_left + COIN_ICON_SIZE
	var text_center: float = group_left + COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP + text_w * 0.5
	_coin_pill_label.offset_left = text_center - COIN_TEXT_MAX_W * 0.5
	_coin_pill_label.offset_right = text_center + COIN_TEXT_MAX_W * 0.5


func _reset_claim_panel() -> void :
	for tw: Tween in _claim_tweens:
		if tw.is_valid():
			tw.kill()
	_claim_tweens.clear()
	for tw: Variant in _punch_tweens.values():
		if tw is Tween and (tw as Tween).is_valid():
			(tw as Tween).kill()
	_punch_tweens.clear()
	_title.visible = true
	_badge_row.visible = true
	_tips.visible = true
	_action_btn.visible = true
	_fx.visible = true
	_reward_box.modulate.a = 1.0
	_coin_box.modulate.a = 1.0
	_reward_halo.visible = _reward_hint > 0
	_coin_halo.visible = _reward_coin > 0
	_claim_panel.visible = false
	_claim_panel.modulate.a = 0.0
	_coin_pill.scale = Vector2.ONE
	_coin_pill_icon.scale = Vector2.ONE
	_hint_counter.scale = Vector2.ONE


func _on_hide() -> void :
	_show_token += 1
	_closing = true
	_kill_slide()
	_anim.stop()
	_fx.stop_all()
	_confetti.reset()
	_hint_fly.cancel_all()
	_coin_fly.cancel_all()
	_reset_claim_panel()
	visible = false
	closed.emit()


func _has_reward() -> bool:
	return _reward_hint > 0 or _reward_coin > 0


func _on_back_request() -> void :

	if _closing or _claiming or _action_btn.disabled:
		return
	await _claim()


func _close() -> void :
	if _closing:
		return
	_closing = true
	var token: int = _show_token
	_kill_slide()
	_fx.fade_out()
	_confetti.fade_out()
	_action_btn.disabled = true
	_anim.play_section_with_markers("GenericPopup", &"Mark", &"")
	while token == _show_token and _anim.is_playing():
		await get_tree().process_frame
	if token != _show_token:
		return
	visible = false
	closed.emit()


func _kill_slide() -> void :
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = null


func get_center_tier() -> float:
	return _center_tier


func get_badge_at(index: int) -> RankBadgeView:
	return _badges[index] if index >= 0 and index < _badges.size() else null


func get_badge_count() -> int:
	return _badges.size()


func is_action_enabled() -> bool:
	return not _action_btn.disabled


func _create_claim_tween() -> Tween:
	var tw: = create_tween()
	_claim_tweens.append(tw)
	var tween_ref: WeakRef = weakref(tw)
	tw.finished.connect( func() -> void : _claim_tweens.erase(tween_ref.get_ref()), CONNECT_ONE_SHOT)
	return tw


func _wait_claim_tween(tw: Tween, token: int) -> void :
	while token == _show_token and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
