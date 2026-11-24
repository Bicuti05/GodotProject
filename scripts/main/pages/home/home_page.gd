class_name HomePage
extends PageScene




const COIN_FONT_MAX: int = 64
const COIN_FONT_MIN: int = 36
const COIN_HUD_WIDTH: float = 270.0
const COIN_ICON_SIZE: float = 88.0
const COIN_ICON_VISIBLE_INSET_LEFT: float = 7.0
const COIN_ICON_VISIBLE_INSET_RIGHT: float = 7.0
const COIN_ICON_VISIBLE_WIDTH: float = COIN_ICON_SIZE\
- COIN_ICON_VISIBLE_INSET_LEFT - COIN_ICON_VISIBLE_INSET_RIGHT
const COIN_ICON_TEXT_GAP: float = 8.0
const COIN_GROUP_EDGE_PAD: float = 14.0
const COIN_GROUP_MAX_W: float = COIN_HUD_WIDTH - COIN_GROUP_EDGE_PAD * 2.0
const COIN_TEXT_MAX_W: float = COIN_GROUP_MAX_W\
- COIN_ICON_VISIBLE_WIDTH - COIN_ICON_TEXT_GAP
@export var fire_white_icon: Texture2D
@export var fire_yellow_icon: Texture2D
@export var special_challenge_icon: Texture2D
@export var bonus_icon: Texture2D
const _LOGO_ANIM_INTO: String = "into"
const _LOGO_ANIM_IDLE: String = "idle_01"
const _LOGO_ANIM_IDLE_ALT: String = "idle_02"
const _LOGO_IDLE_PER_ALT: int = 4
const _LOGO_SCALE: float = 0.62
const _LOGO_CENTER_Y: float = 410.0
const _LOGO_BBOX_CENTER_Y: float = -9.804

const _LOGO_BBOX_HEIGHT: float = 496.61
const _ORIGINAL_LOGO_PATH: String = "res://assets/spine/effect_game_logo/effect_game_logo.tres"
const HEX_BOARD_GROWTH: float = 1.2
const HEX_BOARD_UI_GAP: float = 32.0

const PLAY_BADGE_TOP_EXTENT: float = 60.0


const PLAY_ENTRANCE_DELAY: float = 0.16
const PLAY_ENTRANCE_DUR: float = 0.28
const ENTRANCE_DUR: float = PLAY_ENTRANCE_DELAY + PLAY_ENTRANCE_DUR

const HOME_NAV_SAFE_GAP: float = 8.0

@onready var _background: TextureRect = $Root / Background

@onready var _home_nav: Control = $Root / HomeNav
@onready var _home_nav_base_offsets: Vector2 = Vector2(_home_nav.offset_top, _home_nav.offset_bottom)
@onready var _settings_btn: Button = $Root / HomeNav / SettingsButton
@onready var _coin_label: Label = $Root / HomeNav / CoinHud / CoinLabel
@onready var _coin_icon: TextureRect = $Root / HomeNav / CoinHud / CoinIcon
@onready var _coin_bonus_badge: HomeCoinBonusFx = $Root / PlayButton / CoinBonusBadge
var _coin_day_timer: Timer
@onready var _play_btn: CommonBtn = $Root / PlayButton
var _home_button_fx: HomeButtonFx = null
@onready var _logo: SpineSprite = $Root / Logo
@onready var _settings_red_dot: TextureRect = $Root / HomeNav / SettingsButton / RedDot

var _hex_board: HexBoard = null
var _hex_backdrop: OuterLoopBackdrop = null

@onready var _rank_entry_layout: Control = $Root / RankEntryLayout
var _rank_entry: RankHomeEntry = null
var _avatar_button: RankAvatarCell = null
var _avatar_pool: RankAvatarPool = null
var _rank_session_running: bool = false
var _home_enter_pending: bool = false
var _rank_session_pending: bool = false
var _enter_generation: int = 0
var _opening: bool = false
var _outer_loop_active: bool = false
var _level_unavailable: bool = false
var _play_level_unique_id: String = ""
var _retry_generation: int = 0
var _retry_active: bool = false
var _entrance_tween: Tween = null
var _entrance_entries: Array[Dictionary] = []
var _entry_fades: Array[Dictionary] = []
var _play_ready: bool = true
var _enter_home_dyed_this_show: bool = false
var _main_btn_preview_mode: int = -1
var _main_btn_preview_active: bool = false
var _main_btn_preview_settings: Dictionary = {}
var _components: HomeComponentLoader


func _ready() -> void :
	_coin_day_timer = Timer.new()
	_coin_day_timer.one_shot = true
	_coin_day_timer.timeout.connect(_on_coin_day_rolled)
	add_child(_coin_day_timer)

	for child: Node in _home_nav.get_children():
		child.remove_from_group(&"_safe_top")
	_components = HomeComponentLoader.new(self)
	LevelManager.level_data_changed.connect(_on_level_data_changed)
	ABManager.init_done.connect(_on_ab_init_done)
	UserState.help_center_badge_changed.connect(_on_help_center_badge_changed)
	if not _logo.animation_started.is_connected(_on_logo_animation_started):
		_logo.animation_started.connect(_on_logo_animation_started)
	if not _logo.animation_completed.is_connected(_on_logo_animation_completed):
		_logo.animation_completed.connect(_on_logo_animation_completed)
	get_viewport().size_changed.connect(_layout_home)
	_layout_logo()
	_layout_hex_board()
	_layout_rank_entry()
	_layout_home_nav()


func _on_show(params: Dictionary) -> void :

	_enter_generation += 1
	var generation: int = _enter_generation
	_home_enter_pending = true
	_rank_session_pending = false
	if not is_node_ready():
		await ready
		if generation != _enter_generation:
			return
	var logo_active: Callable = func() -> bool:
		return is_instance_valid(self) and generation == _enter_generation
	if not await prepare_logo_for_display(logo_active):
		return
	_components.cancel()
	_cancel_entrance()
	_home_nav.modulate.a = 1.0

	$Root / HomeNav / CoinHud.show()
	SceneManager.clear_button_feedback_baseline(_settings_btn)
	SceneManager.reset_button_feedback(_settings_btn)
	if _outer_loop_active:
		_hex_backdrop.cancel()
	_outer_loop_active = false
	_rank_open_request = null
	if _hex_board != null:
		_hex_board.hide()
	var pending_level: int = UserState.get_outer_loop_pending_level()
	var level_won: bool = pending_level > 0 and pending_level == UserState.get_current_level() - 1

	Tracker.track_scr_show(TrackingEvents.SCR_HOME)
	visible = true
	_opening = false
	_enter_home_dyed_this_show = false
	_dye_enter_home()
	_layout_logo()
	_layout_hex_board()
	_layout_rank_entry()
	_play_logo()
	_refresh_coin_hud()
	_start_component_loading(generation)
	_refresh_play_button()
	refresh_help_center_red_dot()
	refresh_entry_ui()
	_play_entrance()
	_show_unavailable_error_if_needed()
	_start_unavailable_retry()
	await HomeEnterFlow.run(self, level_won, 
		func() -> bool: return visible and generation == _enter_generation and not _opening, params)
	if generation == _enter_generation:
		_refresh_play_button()


func play_outer_loop_progress(level_won: bool) -> void :
	var generation: int = _enter_generation
	var active: Callable = func() -> bool: return visible and generation == _enter_generation and not _opening
	if not await _components.ensure_group("chapter", active):
		return
	_outer_loop_active = true
	UserState.consume_outer_loop_pending_level()
	await _hex_backdrop.refresh(UserState.get_current_level(), level_won)


func _layout_home() -> void :
	_layout_logo()
	_layout_hex_board()
	_layout_rank_entry()
	_layout_home_nav()


func _layout_hex_board() -> void :
	if _hex_board == null:
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	var design_size: = Vector2(1024.0, 1120.0)
	_hex_board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_hex_board.size = design_size
	_hex_board.pivot_offset = design_size * 0.5
	var logo_bottom: float = _LOGO_CENTER_Y + _LOGO_BBOX_HEIGHT * _LOGO_SCALE * 0.5
	var top: float = logo_bottom + HEX_BOARD_UI_GAP
	var bottom: float = _play_btn.position.y - PLAY_BADGE_TOP_EXTENT - HEX_BOARD_UI_GAP
	var scale_factor: float = minf(0.84, (vp.x - 80.0) / design_size.x) * HEX_BOARD_GROWTH
	scale_factor = minf(scale_factor, (vp.x - 40.0) / design_size.x)
	scale_factor = minf(scale_factor, (bottom - top) / design_size.y)
	_hex_board.scale = Vector2.ONE * scale_factor
	var half_height: float = design_size.y * scale_factor * 0.5
	var center_y: float = clampf(vp.y * 0.53, top + half_height, bottom - half_height)
	_hex_board.position = Vector2(vp.x * 0.5, center_y) - design_size * 0.5



func _add_entrance_entry(key: String, node: Control, button: BaseButton, 
		delay: float, dur: float, dy: float, grow: bool) -> void :
	SceneManager.clear_button_feedback_baseline(button)
	SceneManager.reset_button_feedback(button)
	var entry: Dictionary = {
		"key": key, "node": node, "button": button, "done": false, 
		"top": node.offset_top, "bottom": node.offset_bottom, 
		"color": node.modulate, "scale": node.scale, "pivot": node.pivot_offset, 
		"filter": button.mouse_filter, "focus": button.focus_mode, 
		"delay": delay, "dur": dur, "dy": dy, "grow": grow, 
	}
	if grow:
		node.pivot_offset = node.size * 0.5
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	button.release_focus()
	_entrance_entries.append(entry)


func _play_entrance() -> void :
	_cancel_entrance()
	_play_ready = false
	_add_entrance_entry("play", _play_btn, _play_btn, PLAY_ENTRANCE_DELAY, PLAY_ENTRANCE_DUR, 20.0, true)
	_set_entrance_time(0.0)
	_fade_rank_entries()
	_entrance_tween = create_tween()
	_entrance_tween.tween_method(_set_entrance_time, 0.0, ENTRANCE_DUR, ENTRANCE_DUR)
	_entrance_tween.finished.connect(_on_entrance_finished.bind(_entrance_tween), CONNECT_ONE_SHOT)



func _fade_home_entry(node: Control, button: BaseButton, delay: float) -> void :
	if not is_instance_valid(node) or not node.is_visible_in_tree() or _opening:
		return
	for pending: Dictionary in _entry_fades:
		if pending["node"] == node:
			return
	SceneManager.reset_button_feedback(button)
	SceneManager.clear_button_feedback_baseline(button)
	var color: Color = node.modulate
	var tween: Tween = create_tween()
	var entry: Dictionary = {
		"node": node, "button": button, "color": color, "tween": tween, 
		"filter": button.mouse_filter, "focus": button.focus_mode, 
	}
	_entry_fades.append(entry)
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	button.release_focus()
	node.modulate.a = 0.0
	tween.tween_property(node, "modulate:a", color.a, PLAY_ENTRANCE_DUR).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_entry_fade.bind(entry), CONNECT_ONE_SHOT)


func _fade_rank_entries() -> void :
	_fade_home_entry(_avatar_button, _avatar_button, 0.0)
	_fade_home_entry(_rank_entry, _rank_entry, 0.08)


func _finish_entry_fade(entry: Dictionary) -> void :
	if not _entry_fades.has(entry):
		return
	var node: Control = entry["node"] as Control
	if is_instance_valid(node):
		node.modulate = entry["color"] as Color
	var button: BaseButton = entry["button"] as BaseButton
	if is_instance_valid(button):

		button.mouse_filter = int(entry["filter"])
		button.focus_mode = int(entry["focus"])
		SceneManager.clear_button_feedback_baseline(button)
	_entry_fades.erase(entry)


func _restore_entrance_entry(entry: Dictionary) -> void :
	var node: Control = entry["node"] as Control
	if is_instance_valid(node):
		node.offset_top = float(entry["top"])
		node.offset_bottom = float(entry["bottom"])
		node.modulate = entry["color"] as Color
		node.scale = entry["scale"] as Vector2
		node.pivot_offset = entry["pivot"] as Vector2
	var button: BaseButton = entry["button"] as BaseButton
	if is_instance_valid(button):

		button.mouse_filter = int(entry["filter"])
		button.focus_mode = int(entry["focus"])
		SceneManager.clear_button_feedback_baseline(button)
	entry["done"] = true


func _set_entrance_time(time: float) -> void :
	for entry: Dictionary in _entrance_entries:
		if bool(entry["done"]):
			continue
		var node: Control = entry["node"] as Control
		if not is_instance_valid(node):
			continue
		var u: float = clampf((time - float(entry["delay"])) / float(entry["dur"]), 0.0, 1.0)
		var ease: float = sin(u * PI * 0.5)
		var dy: float = float(entry["dy"]) * (1.0 - ease)
		node.offset_top = float(entry["top"]) + dy
		node.offset_bottom = float(entry["bottom"]) + dy
		var color: Color = entry["color"] as Color
		color.a *= ease
		node.modulate = color
		if bool(entry["grow"]):
			node.scale = (entry["scale"] as Vector2) * lerpf(0.96, 1.0, ease)
		if u >= 1.0:
			_restore_entrance_entry(entry)
			_play_ready = true


func _on_entrance_finished(tween: Tween) -> void :
	if _entrance_tween != tween:
		return
	_set_entrance_time(ENTRANCE_DUR)
	_entrance_tween = null
	_entrance_entries.clear()
	_play_ready = true
	PagePreparationCoordinator.first_page_entered(self, "home")


func _cancel_entrance() -> void :
	for entry: Dictionary in _entry_fades.duplicate():
		var tween: Tween = entry["tween"] as Tween
		if tween != null and tween.is_valid():
			tween.kill()
		_finish_entry_fade(entry)
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	_entrance_tween = null
	for entry: Dictionary in _entrance_entries:
		if not bool(entry["done"]):
			_restore_entrance_entry(entry)
	_entrance_entries.clear()
	_play_ready = true




func refresh_help_center_red_dot() -> void :
	_settings_red_dot.visible = HelpshiftManager.should_show_badge()


func _on_help_center_badge_changed(badge_visible: bool) -> void :
	_settings_red_dot.visible = badge_visible


func _on_hide() -> void :
	_coin_day_timer.stop()
	_cancel_entrance()
	_components.cancel()
	_coin_bonus_badge.set_effect_enabled(false)
	if _home_button_fx != null:
		_home_button_fx.set_effect_enabled(false)
	visible = false
	_enter_generation += 1
	_home_enter_pending = false
	_rank_session_pending = false
	_rank_open_request = null
	if _outer_loop_active:
		_hex_backdrop.cancel()
	_outer_loop_active = false
	_rank_session_running = false
	for route: String in ["rank_change", "rank_new_season", "rank_introduction", "rank_season_win", "avatar_select"]:
		SceneManager.hide_dlg(route)
	SceneManager.hide_page("rank")
	_retry_generation += 1
	_retry_active = false


func _notification(what: int) -> void :
	super (what)
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		if _outer_loop_active:
			_hex_backdrop.refresh_titles()
		_refresh_play_button()
	if is_node_ready() and (what == NOTIFICATION_APPLICATION_FOCUS_OUT\
	or what == NOTIFICATION_APPLICATION_PAUSED):
		_cancel_entrance()
	if (what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN) and is_node_ready() and visible:
		_refresh_play_button()
		if _level_unavailable:
			LevelManager.retry_unavailable_level(UserState.get_current_level())


func _on_level_data_changed(chapter_index: int) -> void :
	if not visible or chapter_index != LevelIndex.chapter_of(UserState.get_current_level()):
		return
	var was_unavailable: bool = _level_unavailable
	_refresh_play_button()
	if _level_unavailable and not was_unavailable:
		_show_unavailable_error_if_needed()
	_start_unavailable_retry()


func _on_ab_init_done() -> void :
	if is_node_ready() and visible:
		_dye_enter_home()
		refresh_entry_ui()
		_refresh_play_button()


func _start_unavailable_retry() -> void :
	if not visible or not _level_unavailable or _retry_active:
		return
	_retry_active = true
	_retry_generation += 1
	_retry_unavailable_level(UserState.get_current_level(), _retry_generation)


func _retry_unavailable_level(level: int, generation: int) -> void :
	while visible and generation == _retry_generation and _level_unavailable\
	and level == UserState.get_current_level():
		await LevelManager.retry_unavailable_level(level)
		if not visible or generation != _retry_generation:
			return
		_refresh_play_button()
		if not _level_unavailable:
			break
		await get_tree().create_timer(LevelManager.UNAVAILABLE_RETRY_INTERVAL).timeout
	if generation == _retry_generation:
		_retry_active = false


func _layout_logo() -> void :
	if _logo == null or not is_instance_valid(_logo):
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	_logo.scale = Vector2.ONE * _LOGO_SCALE
	_logo.position = Vector2(vp.x * 0.5, _LOGO_CENTER_Y - _LOGO_BBOX_CENTER_Y * _LOGO_SCALE)


func _play_logo() -> void :
	_play_original_logo()



func prepare_logo_for_display(active: Callable) -> bool:
	return await _ensure_original_logo(active)


func _ensure_original_logo(active: Callable) -> bool:
	if not active.call():
		return false
	if _logo.skeleton_data_res == null:
		var status: int = ResourceLoader.load_threaded_get_status(_ORIGINAL_LOGO_PATH)
		if not ResourceLoader.has_cached(_ORIGINAL_LOGO_PATH) and status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			if ResourceLoader.load_threaded_request(_ORIGINAL_LOGO_PATH, "SpineSkeletonDataResource", false) != OK:
				SortLogger.error("HomePage: 原 Logo 骨架资源请求失败")
				return false
		while active.call() and ResourceLoader.load_threaded_get_status(_ORIGINAL_LOGO_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if not active.call():
			return false

		if ResourceLoader.load_threaded_get_status(_ORIGINAL_LOGO_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
			_logo.skeleton_data_res = ResourceLoader.load_threaded_get(_ORIGINAL_LOGO_PATH) as SpineSkeletonDataResource
		elif ResourceLoader.has_cached(_ORIGINAL_LOGO_PATH):
			_logo.skeleton_data_res = load(_ORIGINAL_LOGO_PATH) as SpineSkeletonDataResource
		if _logo.skeleton_data_res == null:
			SortLogger.error("HomePage: 原 Logo 骨架加载失败")
			return false
	_logo.process_mode = Node.PROCESS_MODE_INHERIT
	_logo.show()
	return true


func _play_original_logo() -> void :
	if _logo.skeleton_data_res == null:
		_play_original_after_prepare()
		return
	var state: Object = _logo.get_animation_state()
	if state == null:
		return
	state.call("clear_tracks")
	state.call("set_animation", _LOGO_ANIM_INTO, false, 0)
	_queue_logo_idle_batch(state)



func _play_original_after_prepare() -> void :
	var generation: int = _enter_generation
	var active: Callable = func() -> bool:
		return is_instance_valid(self) and is_visible_in_tree() and generation == _enter_generation
	if await _ensure_original_logo(active):
		_play_original_logo()


func _queue_logo_idle_batch(state: Object) -> void :
	for _i in _LOGO_IDLE_PER_ALT:
		state.call("add_animation", _LOGO_ANIM_IDLE, 0.0, false, 0)
	state.call("add_animation", _LOGO_ANIM_IDLE_ALT, 0.0, false, 0)


func _on_logo_animation_started(sprite: Object, _state: Object, entry: Object) -> void :
	if entry == null:
		return
	var animation: Object = entry.call("get_animation")
	if animation == null:
		return
	var animation_name: String = String(animation.call("get_name"))
	if animation_name != _LOGO_ANIM_INTO and animation_name != _LOGO_ANIM_IDLE:
		return

	var flower: SpineSlot = sprite.get_skeleton().find_slot("flower")
	var color: Color = flower.get_color()
	color.a = 1.0
	flower.set_color(color)


func _on_logo_animation_completed(_sprite: Object, state: Object, entry: Object) -> void :
	if entry == null or state == null:
		return
	var animation: Object = entry.call("get_animation")
	if animation != null and String(animation.call("get_name")) == _LOGO_ANIM_IDLE_ALT:
		_queue_logo_idle_batch(state)


func _refresh_play_button() -> void :
	var target: Dictionary = LevelManager.get_next_round_descriptor()
	if bool(target.get("is_timed_endless", false)):
		_play_level_unique_id = String(target["instance_id"])
		_level_unavailable = false
		var timed_state: Dictionary = NextLevelButtonPresenter.describe(UserState.get_current_level(), 
			false, false, false, false, false, false, false, true)
		NextLevelButtonPresenter.apply(_play_btn, timed_state, {}, _opening, true, _coin_bonus_badge)
		_refresh_main_button_fx()
		return
	var special: bool = bool(target["is_special"])
	var level: int = UserState.get_current_level()
	var resumed: Dictionary = {} if special else LevelManager.load_resumed_level(level)
	var meta: LevelModel = resumed.get("model") as LevelModel
	if not special and meta == null:
		meta = LevelManager.get_level_model(LevelIndex.chapter_of(level), LevelIndex.index_of(level))
	_play_level_unique_id = meta.level_unique_id if meta != null else ""
	_level_unavailable = not special and resumed.is_empty() and ( not LevelManager.is_level_state_resolved(level)\
	or LevelManager.is_end_reached(level))
	var coin_assignment: Dictionary = {} if special or _level_unavailable else CoinBonusLevelEntry.preview(
		meta, is_visible_in_tree(), not resumed.is_empty())

	var bonus: bool = not special and not _level_unavailable and BonusLevelEntry.is_next_bonus(
		level, resumed.get("current_state", {}) as Dictionary, true, coin_assignment)
	var hard: bool = meta != null and meta.difficulty_type.strip_edges().to_lower() == "hard"
	var super_hard: bool = meta != null and meta.is_super_hard()
	var coming_soon: bool = _level_unavailable and LevelManager.has_completed_coming_soon_before(level)
	var state: Dictionary = NextLevelButtonPresenter.describe(
		level, hard, super_hard, bonus, special, _level_unavailable, coming_soon, 
		bool(coin_assignment.get("double_coins", false)))
	NextLevelButtonPresenter.apply(_play_btn, state, {
		"special": special_challenge_icon, "bonus": bonus_icon, 
		"fire_white": fire_white_icon, "fire_yellow": fire_yellow_icon, 
	}, _opening, true, _coin_bonus_badge)
	_schedule_coin_day_roll()
	_refresh_main_button_fx()


func preview_home_button_fx(mode: int, settings: Dictionary, active: bool = true) -> void :
	_main_btn_preview_active = active
	_main_btn_preview_mode = clampi(mode, -1, 1) if active else -1
	_main_btn_preview_settings = settings.duplicate() if active else {}
	if active and _home_button_fx == null and visible:
		var generation: int = _enter_generation
		_components.start(["fx"], func() -> bool: return visible and generation == _enter_generation)
	if _home_button_fx != null:
		_home_button_fx.set_settings(_main_btn_preview_settings if active else HomeButtonFx.DEFAULT_SETTINGS)
	_refresh_main_button_fx()



func _dye_enter_home() -> void :
	if not is_visible_in_tree() or _enter_home_dyed_this_show or not ABManager.is_ab_init_done():
		return
	if ABManager._startup_control_locked:
		return
	ABManager.dye_at_enter_home()
	_enter_home_dyed_this_show = true


func _refresh_main_button_fx() -> void :
	if not is_visible_in_tree():
		_coin_bonus_badge.set_effect_enabled(false)
		if _home_button_fx != null:
			_home_button_fx.set_effect_enabled(false)
		return
	var enabled: bool = _main_btn_preview_mode == 1 if _main_btn_preview_mode >= 0\
	else ABManager.main_btn.is_new_effect_enabled()
	_coin_bonus_badge.set_effect_enabled(_coin_bonus_badge.visible and not _level_unavailable and not _opening, 
		not enabled or _home_button_fx == null)
	if _home_button_fx == null:
		if enabled and not _opening:
			var generation: int = _enter_generation
			_components.start(["fx"], func() -> bool: return visible and generation == _enter_generation and not _opening)
		return
	_home_button_fx.process_mode = Node.PROCESS_MODE_ALWAYS if _main_btn_preview_active else Node.PROCESS_MODE_INHERIT
	_home_button_fx.set_effect_enabled(enabled and not _level_unavailable and not _opening)


func _show_unavailable_error_if_needed() -> void :
	if _level_unavailable and not LevelManager.has_completed_coming_soon_before(
			UserState.get_current_level()):
		SceneManager.show_toast(tr("HOME_NETWORK_ERROR"))


func _refresh_coin_hud() -> void :
	var value: String = str(UserState.get_coins())
	_coin_label.text = value
	var font: Font = _coin_label.get_theme_font("font")
	var font_size: int = COIN_FONT_MAX
	var text_width: float = 0.0
	if font != null:
		while true:
			text_width = font.get_string_size(
				value, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size
			).x
			if text_width <= COIN_TEXT_MAX_W or font_size <= COIN_FONT_MIN:
				break
			font_size -= 2
		text_width = minf(text_width, COIN_TEXT_MAX_W)
	_coin_label.add_theme_font_size_override("font_size", font_size)
	_layout_coin_group(text_width)



func refresh_coin_hud() -> void :
	_refresh_coin_hud()


func _layout_coin_group(text_width: float) -> void :
	var visible_group_w: float = COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP + text_width
	var visible_group_left: float = (COIN_HUD_WIDTH - visible_group_w) * 0.5
	var icon_box_left: float = visible_group_left - COIN_ICON_VISIBLE_INSET_LEFT
	_coin_icon.offset_left = icon_box_left
	_coin_icon.offset_right = icon_box_left + COIN_ICON_SIZE
	var text_center: float = visible_group_left + COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP\
	+ text_width * 0.5
	_coin_label.offset_left = text_center - COIN_TEXT_MAX_W * 0.5
	_coin_label.offset_right = text_center + COIN_TEXT_MAX_W * 0.5


func _on_play_pressed() -> void :
	if _rank_session_running or not _play_ready\
	or (_home_enter_pending and RankManager.has_pending_session()):
		return
	_refresh_play_button()

	var is_special: bool = bool(LevelManager.get_next_round_descriptor()["is_special"])


	Tracker.track_btn_click(TrackingEvents.BTN_PLAY, "", _play_level_unique_id)
	await _start_game_from_home(is_special)



func _schedule_coin_day_roll() -> void :
	if _coin_day_timer != null and visible:
		_coin_day_timer.start(maxf(1.0, CoinBonusLevelEntry.seconds_until_midnight()))


func _on_coin_day_rolled() -> void :
	if visible:
		_refresh_play_button()



func _start_game_from_home(is_special: bool) -> void :
	if _rank_session_running or not _play_ready\
	or (_home_enter_pending and RankManager.has_pending_session()):
		return
	if is_special or bool(LevelManager.get_next_round_descriptor().get("is_timed_endless", false)):
		if _opening:
			return
		_opening = true
		await _enter_game()
		_opening = false
		return
	if _level_unavailable:
		if LevelManager.has_completed_coming_soon_before(UserState.get_current_level()):
			SceneManager.show_toast(tr("HOME_COMING_SOON_TOAST"))
		return
	if _opening:
		return
	_opening = true
	_play_btn.disabled = true
	var level: int = UserState.get_current_level()

	if not LevelManager.load_resumed_level(level).is_empty():
		await _enter_game()
		_opening = false
		return
	if not LevelManager.check_level_exist(level):
		SceneManager.show_loading()
		var result: Dictionary = await LevelManager.waiting_load_data(LevelIndex.chapter_of(level))
		SceneManager.hide_loading()
		if not bool(result.get("ok", false)):
			_resume_after_failed_opening()
			return
		if bool(result.get("exhausted", false)):
			_resume_after_failed_opening()
			return
	if LevelManager.is_end_reached(level):
		_resume_after_failed_opening()
		return


	await _enter_game()
	_opening = false


func _on_settings_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_SETTING)
	SceneManager.show_dlg("setting", {"source": "home"})


func _home_top_safe_inset() -> float:
	var ratio: float = UiMetrics.HOME_RANK_TOP_INSET_RATIO if RankManager.is_enabled() else UiMetrics.SAFE_INSET_RATIO
	return UiMetrics.safe_insets(ratio).x


func _layout_rank_entry() -> void :
	if _rank_entry == null:
		return
	_rank_entry.scale = Vector2.ONE
	_rank_entry_layout.scale = Vector2(0.9, 0.9)
	var top_inset: float = _home_top_safe_inset()
	var gap: float = HOME_NAV_SAFE_GAP if RankManager.is_enabled() and top_inset > 0.0 else 0.0
	_rank_entry_layout.position = Vector2(32.4, 284.0 + top_inset + gap)

func _layout_home_nav() -> void :
	var enabled: bool = RankManager.is_enabled()
	var top_inset: float = _home_top_safe_inset()
	var gap: float = HOME_NAV_SAFE_GAP if enabled and top_inset > 0.0 else 0.0
	_home_nav.offset_top = _home_nav_base_offsets.x + top_inset + gap
	_home_nav.offset_bottom = _home_nav_base_offsets.y + top_inset + gap
	if _avatar_button != null:
		_avatar_button.visible = enabled
	_rank_entry_layout.visible = enabled and _rank_entry != null
	_settings_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT if enabled else Control.PRESET_TOP_LEFT)
	_settings_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN if enabled else Control.GROW_DIRECTION_END
	_settings_btn.offset_left = -429.2 if enabled else 40.0
	_settings_btn.offset_right = -314.0 if enabled else 155.2
	var top: float = -4.0 if enabled else 14.0
	_settings_btn.offset_top = top
	_settings_btn.offset_bottom = top + 115.2
	_layout_rank_entry()


func refresh_entry_ui() -> void :
	_layout_home_nav()
	if RankManager.is_enabled() and _rank_entry != null and _avatar_pool != null and _avatar_button != null:
		RankManager.ensure_profile()
		_avatar_button.bind(RankManager.get_display_avatar_index(), _avatar_pool.get_texture(RankManager.get_display_avatar_index()))
		_rank_entry.refresh()
	_refresh_coin_hud()


func finish_home_enter(active: Callable) -> void :
	if RankManager.is_enabled():
		if not await _components.ensure_group("rank", active):
			return
	if not active.call():
		return
	_home_enter_pending = false
	var requested: bool = _rank_session_pending
	_rank_session_pending = false
	if requested or RankManager.has_pending_session():
		await run_rank_session()


func run_rank_session() -> void :
	if not visible:
		return
	if _home_enter_pending:
		_rank_session_pending = true
		return

	if _rank_session_running or not RankManager.has_pending_session():
		return
	_rank_session_running = true
	var generation: int = _enter_generation
	var active: Callable = func() -> bool: return visible and generation == _enter_generation
	while active.call() and not SceneManager.is_topmost(self):
		var rank: Node = SceneManager.get_page("rank")
		if rank != null and rank.visible and SceneManager.is_topmost(rank):
			SceneManager.hide_page("rank")
			break
		await get_tree().process_frame
	var navigation: Dictionary = {"start_game": false}
	if active.call():
		await RankSessionFlow.run(self, active, open_rank_page, 
			func() -> void : navigation.start_game = true)
	if generation == _enter_generation:
		_rank_session_running = false
		if active.call() and bool(navigation.start_game):
			var is_special: bool = bool(LevelManager.get_next_round_descriptor()["is_special"])
			await _start_game_from_home(is_special)
		refresh_entry_ui()

		_restore_home_tracking([
			TrackingEvents.SCR_LEADERBOARD, TrackingEvents.SCR_CHALLENGE_START, 
			TrackingEvents.SCR_CHALLENGE_RENEW, TrackingEvents.SCR_CHALLENGE_END, 
			TrackingEvents.SCR_CHALLENGE_BONUS, 
		])

func _on_rank_season_expired() -> void :
	if visible:
		run_rank_session()

func _on_rank_pressed() -> void :
	if not RankManager.is_enabled() or _rank_entry == null:
		return

	Tracker.track_btn_click(TrackingEvents.BTN_LEADERBOARD)
	if _rank_entry.is_locked():
		SceneManager.show_toast(tr("JUICE_PROP_UNLOCK_TOAST") % RankManager.get_unlock_level())
		return
	if RankManager.is_season_ended():
		run_rank_session()
	elif not _rank_session_running:
		open_rank_page()

var _rank_open_request: RefCounted

func open_rank_page() -> void :
	if not visible or _rank_open_request != null or not RankManager.is_unlocked():
		return
	var rank_page: Node = SceneManager.get_page("rank")
	if rank_page != null and rank_page.visible:
		return
	var generation: int = _enter_generation
	var request: = RefCounted.new()
	_rank_open_request = request
	var active: Callable = func() -> bool:
		return visible and generation == _enter_generation and _rank_open_request == request
	if rank_page == null or rank_page.needs_first_display_preparation():
		rank_page = await SceneManager.load_page_for_display("rank", active)
	elif not await rank_page.prepare_for_display(active):
		rank_page = null
	var ready: bool = rank_page != null and active.call()
	if _rank_open_request == request:
		_rank_open_request = null
	if not ready:

		if visible and generation == _enter_generation:
			_restore_home_tracking([TrackingEvents.SCR_CHALLENGE_RENEW])
		return
	rank_page = SceneManager.show_page("rank", {
		"on_collect": _on_rank_collect_started, "on_season_expired": run_rank_session})
	if rank_page == null:
		return
	$Root / HomeNav / CoinHud.hide()
	while visible and generation == _enter_generation and rank_page.visible:
		await get_tree().process_frame
	if visible and generation == _enter_generation and not rank_page.visible:
		$Root / HomeNav / CoinHud.show()

		_restore_home_tracking([TrackingEvents.SCR_LEADERBOARD])



func _on_rank_collect_started() -> void :
	var generation: int = _enter_generation
	var is_special: bool = bool(LevelManager.get_next_round_descriptor()["is_special"])
	await _start_game_from_home(is_special)
	if visible and generation == _enter_generation:
		_restore_home_tracking([TrackingEvents.SCR_LEADERBOARD])



func _restore_home_tracking(closed_scr_names: Array[String]) -> void :
	if not visible or _opening or _rank_session_running or _rank_open_request != null:
		return
	if SceneManager.is_topmost(self):
		Tracker.track_scr_return(TrackingEvents.SCR_HOME, closed_scr_names)


func _on_avatar_picked(_index: int) -> void :
	if not RankManager.is_enabled():
		return

	Tracker.track_btn_click(TrackingEvents.BTN_EDIT_NAME)
	var generation: int = _enter_generation
	var ctx: Dictionary = {
		"owner": self, 
		"active": func() -> bool: return visible and generation == _enter_generation, 
	}
	await RankSessionFlow.show_dialog(ctx, "avatar_select")
	if visible and generation == _enter_generation:
		refresh_entry_ui()

		_restore_home_tracking([TrackingEvents.SCR_EDIT_NAME])



func prepare_for_display(active: Callable) -> bool:
	if not is_node_ready():
		await ready
	if not active.call():
		return false
	if not await prepare_logo_for_display(active):
		return false
	_layout_home()
	_refresh_coin_hud()
	refresh_help_center_red_dot()
	var generation: int = _enter_generation
	var valid: Callable = func() -> bool:
		return is_instance_valid(self) and active.call() and generation == _enter_generation
	LevelManager.prefetch_next_chapter_covers(LevelIndex.chapter_of(UserState.get_current_level()), true)
	if not await _components.prepare_group("chapter", valid):
		return false
	var current_level: int = UserState.get_current_level()
	var pending_level: int = UserState.get_outer_loop_pending_level()
	var level_won: bool = pending_level > 0 and pending_level == current_level - 1
	if not await _hex_backdrop.prepare_for_display(current_level, level_won, valid):
		return false
	return active.call()


func set_preparation_work_permission(can_work: Callable) -> void :
	_components.set_work_permission(can_work)


func prepare_for_background(active: Callable) -> bool:
	return await prepare_for_display(active)


func can_prepare_other_page() -> bool:
	return not _opening and not _home_enter_pending and not _rank_session_running and _entrance_tween == null


func _start_component_loading(generation: int) -> void :
	var groups: Array[String] = []
	if RankManager.has_pending_session() and RankManager.is_enabled():
		groups.append("rank")
	groups.append("chapter")
	if RankManager.is_enabled() and not groups.has("rank"):
		groups.append("rank")
	if ABManager.main_btn.is_new_effect_enabled() or _main_btn_preview_active:
		groups.append("fx")
	_components.start(groups, func() -> bool: return visible and generation == _enter_generation and not _opening)



func bind_component_group(group: String) -> void :
	match group:
		"chapter":
			_hex_board = get_node("Root/HexBoard") as HexBoard
			_hex_backdrop = get_node("Root/HexBackdrop") as OuterLoopBackdrop
			_hex_board.process_mode = Node.PROCESS_MODE_INHERIT
			_hex_backdrop.process_mode = Node.PROCESS_MODE_INHERIT
			_hex_backdrop.setup(_background, _hex_board)
			_layout_hex_board()
		"rank":
			_rank_entry = get_node("Root/RankEntryLayout/RankEntry") as RankHomeEntry
			_avatar_button = get_node("Root/HomeNav/AvatarButton") as RankAvatarCell
			_avatar_pool = get_node("AvatarPool") as RankAvatarPool
			for node: Node in [_rank_entry, _avatar_button, _avatar_pool]:
				node.process_mode = Node.PROCESS_MODE_INHERIT
			_rank_entry.pressed.connect(_on_rank_pressed)
			_rank_entry.season_expired.connect(_on_rank_season_expired)
			_avatar_button.picked.connect(_on_avatar_picked)
			SceneManager.prepare_page_ui("home", self)
			_layout_rank_entry()
			refresh_entry_ui()
			if visible:
				_fade_rank_entries()
		"fx":
			_home_button_fx = get_node("Root/PlayButton/HomeButtonFx") as HomeButtonFx
			_home_button_fx.process_mode = Node.PROCESS_MODE_INHERIT
			if _main_btn_preview_active:
				_home_button_fx.set_settings(_main_btn_preview_settings)
			_refresh_main_button_fx()



func _enter_game() -> void :
	var generation: int = _enter_generation
	_components.cancel()
	if _outer_loop_active:
		_hex_backdrop.cancel()
		_outer_loop_active = false
	await _components.wait_idle()
	await LevelManager.wait_chapter_covers_idle()
	if not visible or generation != _enter_generation:
		return
	var params: Dictionary = {"source": TrackingEvents.SCR_HOME}
	if not await GameNavigationFlow.run(self, params, 
			func() -> bool: return visible and generation == _enter_generation):
		if visible and generation == _enter_generation:
			_resume_after_failed_opening()


func _resume_after_failed_opening() -> void :
	_opening = false

	_restore_home_tracking([TrackingEvents.SCR_LEADERBOARD])
	_enter_generation += 1
	var generation: int = _enter_generation
	_home_enter_pending = true
	_components.cancel()
	_start_component_loading(generation)
	_refresh_play_button()
	_show_unavailable_error_if_needed()
	_start_unavailable_retry()
	var pending: int = UserState.get_outer_loop_pending_level()
	HomeEnterFlow.run(self, pending > 0 and pending == UserState.get_current_level() - 1, 
		func() -> bool: return visible and generation == _enter_generation and not _opening)
