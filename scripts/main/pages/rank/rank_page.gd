class_name RankPage
extends PageScene

@export var deferred_scenes: Dictionary = {}
var _content_ready: bool = false
var _content_running: bool = false


const TIER_NAME_KEY_FMT: String = "RANK_LEVEL_%d"

const _TITLE_BASE_FONT_SIZE: int = 84
const _TITLE_MIN_FONT_SIZE: int = 40
const _TITLE_MAX_WIDTH: float = 696.0


const _CENTER_FOOT: Vector2 = Vector2(531.325, 745.2)
const _LEFT_FOOT: Vector2 = Vector2(175.175, 811.8)
const _RIGHT_FOOT: Vector2 = Vector2(895.175, 812.8)

@onready var _background: TextureRect = $Bg
@onready var _list: RankListView = $ListRoot
var _badge: RankBadgeView
var _tier_nav: RankTierNav
var _bg_ambient_fall: RankBgAmbientFall
@onready var _tier_label: Label = $TierName
@onready var _clock: RankFinishClock = $Clock
@onready var _reward_tooltip: RankRewardTooltip = $RewardTooltip
@onready var _title_label: Label = $TopBar / Title

var _on_collect: Callable
var _on_season_expired: Callable
var _player_tier: int = RankBadgeView.TIER_MIN


func _ready() -> void :
	_list.gift_tapped.connect(_on_gift_tapped)
	_reward_tooltip.closed.connect(_on_reward_tooltip_closed)
	resized.connect(_layout_trophies, CONNECT_DEFERRED)


func _layout_trophies() -> void :
	if not _content_ready:
		return
	var texture_size: Vector2 = _background.texture.get_size()
	var background_scale: float = maxf(UiMetrics.viewport_size().x / texture_size.x, 1.0)
	_background.size = texture_size
	_background.scale = Vector2(background_scale, background_scale)

	_background.position = Vector2(UiMetrics.center_left(texture_size.x * background_scale), 
		_CENTER_FOOT.y * (1.0 - background_scale))
	var center_foot: Vector2 = _background.position + _CENTER_FOOT * background_scale
	_badge.position = center_foot - Vector2(_badge.size.x * 0.5, _badge.size.y)
	_tier_label.position = Vector2(center_foot.x - _tier_label.size.x * 0.5, 
		center_foot.y - 3.2)

	_tier_nav.set_ground_positions(
		_background.get_global_transform() * _LEFT_FOOT, 
		_background.get_global_transform() * _RIGHT_FOOT)


var _generation: int = 0
var _prepared_for_show: bool = false
var _displayed_once: bool = false


func needs_first_display_preparation() -> bool:
	return not _displayed_once


func prepare_for_display(active: Callable) -> bool:
	_prepared_for_show = false
	if not await prepare_content(active):
		return false
	_layout_trophies()
	RankManager.ensure_season()
	RankManager.ensure_profile()
	var ready: bool = await _refresh_from_snapshot(active)

	if not active.call():
		return false
	_prepared_for_show = ready
	return ready


func prepare_content(active: Callable) -> bool:
	while _content_running and active.call():
		await get_tree().process_frame
	if not active.call():
		return false
	if _content_ready:
		return true
	_content_running = true
	var ready: bool = await SceneManager.instantiate_page_components(self, deferred_scenes, active)
	if not ready:
		_content_running = false
		return false
	_badge = $Badge
	_tier_nav = $TierNav
	_bg_ambient_fall = $BgAmbientFall
	_tier_nav.setup(_badge, _on_browse_tier_changed)
	_content_ready = active.call()
	_content_running = false
	return _content_ready


func _on_show(params: Dictionary = {}) -> void :
	ABManager.dye_at_enter_rank()
	visible = true
	_generation += 1
	var first_screen_ready: bool = _prepared_for_show and _list.is_first_screen_ready()
	_prepared_for_show = false
	if not first_screen_ready:
		_list.cancel_animations()
	_list.begin_enter_mask()
	_list.set_drag_enabled(false)
	_clock.stop()
	_clock.refresh_time()
	_on_collect = params.get("on_collect", Callable())
	_on_season_expired = params.get("on_season_expired", Callable())
	_title_label.text = tr("RANK_LEADERBOARD_TITLE")
	_fit_title_font_size()
	if not first_screen_ready:
		_tier_label.hide()

	Tracker.track_scr_show(TrackingEvents.SCR_LEADERBOARD)
	await RankPageEnterFlow.run(self, _generation, params, first_screen_ready)


func prepare_show_screen(ctx) -> void :
	_layout_trophies()
	RankManager.ensure_season()
	RankManager.ensure_profile()
	if not await _refresh_from_snapshot():
		ctx.ready = false
		return


func activate_show(ctx) -> void :
	if not ctx.active.call():
		return

	var info: Dictionary = RankManager.get_challenge_info_params()
	if not info.is_empty():
		Tracker.track_challenge_info(TrackingEvents.CHALLENGE_STATE_IN_PROGRESS, info)

	if RankManager.is_tier_browsing_enabled():
		_tier_nav.activate(_player_tier)
	else:
		_tier_nav.deactivate()
		_badge.start_idle_fx()
	_list.end_enter_mask()
	_list.set_drag_enabled(true)
	_displayed_once = true
	_clock.start()
	visible = true
	_bg_ambient_fall.start()
	_on_clock_timeout()


func show_profile_if_needed(ctx) -> void :
	var generation: int = ctx.generation
	if not UserState.is_rank_avatar_dialog_ever_shown():
		var nickname: String = RankManager.get_display_nickname()
		var avatar_index: int = RankManager.get_display_avatar_index()
		await RankSessionFlow.show_dialog({
			"owner": self, 
			"active": func() -> bool: return visible and generation == _generation, 
		}, "avatar_select")
		if generation != _generation or not visible:
			return

		if SceneManager.is_topmost(self):
			Tracker.track_scr_return(TrackingEvents.SCR_LEADERBOARD, [TrackingEvents.SCR_EDIT_NAME])
		var current_nickname: String = RankManager.get_display_nickname()
		var current_avatar_index: int = RankManager.get_display_avatar_index()
		if current_nickname != nickname or current_avatar_index != avatar_index:
			_list.update_player_profile(current_nickname, current_avatar_index)


func _refresh_from_snapshot(active: Callable = Callable()) -> bool:
	if not active.is_valid():
		var generation: int = _generation
		active = func() -> bool: return generation == _generation and visible
	if not active.call():
		return false
	RankManager.invalidate_snapshot()
	var snap: RankSnapshot = RankManager.get_current_snapshot()
	_player_tier = clampi(snap.start_tier, RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX)
	if _tier_nav.is_active():
		_tier_nav.refresh_player_tier(_player_tier)
		_tier_label.text = TIER_NAME_KEY_FMT % _tier_nav.get_browse_tier()
	else:
		_badge.set_tier(_player_tier)
		_badge.show()
		_tier_label.text = TIER_NAME_KEY_FMT % _player_tier
	_tier_label.show()
	if not await _list.prepare_first_screen(snap, snap.my_rank_pos, active):
		return false
	return true


func _on_browse_tier_changed(tier: int) -> void :
	_tier_label.text = TIER_NAME_KEY_FMT % clampi(tier, RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX)


func _fit_title_font_size() -> void :
	var font_size: int = _TITLE_BASE_FONT_SIZE
	var font: Font = _title_label.get_theme_font("font")
	var text: String = _title_label.text
	if font != null and text != "":
		while font_size > _TITLE_MIN_FONT_SIZE:
			var text_width: float = font.get_string_size(
				text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
			if text_width <= _TITLE_MAX_WIDTH:
				break
			font_size -= 2
	_title_label.add_theme_font_size_override("font_size", font_size)


func cheat_refresh() -> void :
	if await _refresh_from_snapshot():
		_list.scroll_to_me()


func cheat_refresh_countdown() -> void :
	_clock.refresh_time()
	_on_clock_timeout()


func _on_clock_timeout() -> void :

	if not visible or not RankManager.is_season_ended() or not _on_season_expired.is_valid():
		return
	_clock.stop()
	_on_season_expired.call()


func _on_hide() -> void :
	visible = false
	_generation += 1
	_prepared_for_show = false
	SortLogger.info("[RankVirtual] stats=%s" % JSON.stringify(_list.get_performance_stats()))
	if not _content_ready:
		_list.cancel_animations()
		_clock.stop()
		_on_season_expired = Callable()
		return
	_list.cancel_animations()
	_clock.stop()
	_on_season_expired = Callable()
	_reward_tooltip.hide_tooltip()
	_list.set_drag_enabled(true)
	_badge.reset_motion()
	_tier_nav.deactivate()
	_bg_ambient_fall.stop()





func _on_back_request() -> void :
	_close()


func _on_back_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_CLOSE)
	_close()


func _on_collect_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_GO_TO_COLLECT)
	_close()
	if _on_collect.is_valid():
		_on_collect.call()


func _close() -> void :
	SceneManager.hide_page("rank")


func _on_gift_tapped(rank_pos: int, global_rect: Rect2) -> void :
	_reward_tooltip.show_at(global_rect, RankManager.get_reward_preview(rank_pos))
	_list.set_drag_enabled(false)


func _on_reward_tooltip_closed() -> void :
	_list.set_drag_enabled(true)
