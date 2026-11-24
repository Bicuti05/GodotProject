class_name RankGameFinishPage
extends PageScene

@export var deferred_scenes: Dictionary = {}
var _content_ready: bool = false
var _content_running: bool = false
@export var encourage_data: Resource = null

signal closed
signal collect_feedback_stage(stage: String)

const SCRIM_FADE_SEC: float = 0.22
const CONTINUE_FADE_SEC: float = 0.3
const CONTINUE_LIST_GAP_PX: float = 80.0
const RISE_TIP_SLIDE_SEC: float = 0.35
const RISE_TIP_NUMBER_COLOR: Color = Color("0aa733")
const _TIP_BASE_FONT_SIZE: int = 48

const _TITLE_BASE_FONT_SIZE: int = 100
const _TITLE_MIN_FONT_SIZE: int = 52
const _TITLE_MAX_WIDTH: float = 850.0
const SCROLL_EDGE_FADE_PX: float = 64.0
const SCROLL_VISIBLE_ROW_COUNT: int = 6
const ENCOURAGE_SKINS: Array[String] = ["Amazing!", "Awesome!", "Bravo!", "Moving Up!", "On Fire!"]
const ENCOURAGE_ANIMATION: StringName = &"Animation"
const ENCOURAGE_REFERENCE_TIME: float = 0.5
const ENCOURAGE_HOLD_SEC: float = 0.8
const ENCOURAGE_SCALE: float = 1.3

@onready var _scrim: ColorRect = $Scrim
@onready var _list_area: Control = $ListArea
@onready var _list: RankListView = $ListArea / ListFade / ListRoot
@onready var _list_fade: CanvasGroup = $ListArea / ListFade
@onready var _list_scroll: ScrollContainer = $ListArea / ListFade / ListRoot / Scroll
@onready var _clock: RankFinishClock = $TopBlock / Clock
var _podium: RankFinishPodium
@onready var _continue_btn: CommonBtn = $ContinueButton
@onready var _crown: RankCrownAnimator = $CrownLayer
var _crown_burst: RankCrownBurstFx
var _crown_shine: RankCrownShineFx
@onready var _title_label: Label = $TopBlock / Title
@onready var _reward_tooltip: RankRewardTooltip = $RewardTooltip
@onready var _rise_tip_holder: Control = $RiseTip
@onready var _rise_tip: Control = $RiseTip / Content
@onready var _rise_tip_text: RichTextLabel = $RiseTip / Content / Text
@onready var _encourage_word: Control = $EncourageWord
var _encourage_spine: SpineSprite
var _confetti: RankFinishConfetti

var _closing: bool = false

func _ready() -> void :
	_rng.randomize()
	_list.gift_tapped.connect(_on_gift_tapped)
	_reward_tooltip.closed.connect(_on_reward_tooltip_closed)
	_list_area.item_rect_changed.connect(_sync_list_layout)
	_list_scroll.resized.connect(_update_scroll_fade)
	resized.connect(_sync_list_layout)
	_sync_list_layout()


func _sync_list_layout() -> void :



	var visible_height: float = RankItemView.ROW_PITCH * SCROLL_VISIBLE_ROW_COUNT
	_list.size = Vector2(_list_area.size.x, minf(_list_area.size.y, visible_height))
	_update_scroll_fade()
	_continue_btn.position.y = _list_area.position.y + _list.size.y + CONTINUE_LIST_GAP_PX


func _update_scroll_fade() -> void :
	var rect: Rect2 = _list_scroll.get_global_rect()
	var viewport_height: float = UiMetrics.viewport_size().y
	for material: ShaderMaterial in [_list_fade.material, _list.collect_icon_fade_material]:
		material.set_shader_parameter("top_uv", rect.position.y / viewport_height)
		material.set_shader_parameter("bottom_uv", rect.end.y / viewport_height)
		material.set_shader_parameter("fade_uv", minf(SCROLL_EDGE_FADE_PX, rect.size.y * 0.5) / viewport_height)

var _generation: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _scrim_tween: Tween
var _continue_tween: Tween
var _rise_tip_tween: Tween
var _encourage_tween: Tween
var _encourage_bounds: Dictionary = {}

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
	_podium = $Podium
	_crown_burst = $CrownBurstFx
	_crown_shine = $CrownShineFx
	_confetti = $Confetti
	if _encourage_spine == null:
		_encourage_spine = SpineSprite.new()
		_encourage_spine.name = "Spine"
		_encourage_spine.update_mode = SpineConstant.UpdateMode_Manual
		_encourage_spine.skeleton_data_res = encourage_data
		_encourage_word.add_child(_encourage_spine)
		await get_tree().process_frame
		if not active.call():
			_content_running = false
			return false
	_crown.set_fx(_crown_burst, _crown_shine, null)
	if not _podium.avatar_landed.is_connected(_on_avatar_landed):
		_podium.avatar_landed.connect(_on_avatar_landed)
	_list.attach_podium(_podium)
	_content_ready = active.call()
	_content_running = false
	return _content_ready


func _on_show(params: Dictionary = {}) -> void :
	_reset_scrim_fade()
	visible = true
	_generation += 1
	_closing = false
	_list.cancel_animations()
	_list.begin_enter_mask()
	_list.set_drag_enabled(false)
	if _podium != null:
		_podium.hide()
	_crown.hide_crown()
	_hide_rise_tip()
	_hide_encourage_word()
	if _confetti != null:
		_confetti.reset()
	_clock.stop()
	_clock.refresh_time()
	_title_label.text = tr("RANK_LEADERBOARD_TITLE")
	_fit_title_font_size()
	if _continue_tween != null and _continue_tween.is_valid():
		_continue_tween.kill()
	_continue_btn.disabled = true
	_continue_btn.modulate.a = 0.0
	set_meta(RankSessionFlow.DIALOG_LEASE, null)

	_start_scrim_fade()

	Tracker.track_scr_show(TrackingEvents.SCR_RANK_RENEW)
	await RankFinishEnterFlow.run(self, _generation, params)


func prepare_show_screen(ctx) -> void :
	var generation: int = ctx.generation
	_podium.set_first_crown_visible(true)
	_podium.prepare_enter()
	_update_scroll_fade()

	var result: Dictionary = ctx.params.get("result", {})
	var collect_delta: int = maxi(int(result.get("collect_delta", 0)), 0)

	RankManager.invalidate_snapshot()
	var to_snap: RankSnapshot = RankManager.get_current_snapshot()
	var from_snap: RankSnapshot = RankSnapshotBuilder.build_rolled_back(to_snap, collect_delta)


	var info: Dictionary = RankManager.get_challenge_info_params()
	if not info.is_empty():
		Tracker.track_challenge_info(TrackingEvents.CHALLENGE_STATE_IN_PROGRESS, info, 
			TrackingEvents.CHALLENGE_POSITION_GAME_FINISH)

	_clock.start()

	var active: Callable = func() -> bool: return generation == _generation and visible
	if not await _list.prepare_first_screen(from_snap, from_snap.my_rank_pos, active):
		ctx.ready = false
		return
	if not await _list.prepare_animation(active):
		ctx.ready = false
		return
	_list.begin_enter_mask()
	_list.set_drag_enabled(false)
	visible = true
	await get_tree().process_frame
	if generation != _generation or not visible:
		ctx.ready = false
		return
	_list.scroll_rank_to_center(from_snap.my_rank_pos)
	ctx.result = result
	ctx.collect_delta = collect_delta
	ctx.from_snap = from_snap
	ctx.to_snap = to_snap
	var already_first: bool = to_snap.my_rank_pos == 1 and from_snap.my_rank_pos == 1
	ctx.already_first = already_first
	_crown.hide_crown()



func play_show_presentation(ctx) -> void :
	var generation: int = ctx.generation
	var from_snap: RankSnapshot = ctx.from_snap
	var to_snap: RankSnapshot = ctx.to_snap
	var collect_delta: int = ctx.collect_delta
	var enter_tween: Tween = _podium.play_enter()
	await _list.play_enter_anim()
	while generation == _generation and visible and enter_tween.is_valid() and enter_tween.is_running():
		await get_tree().process_frame
	if generation != _generation or not visible:
		return
	if ctx.already_first:
		_attach_resting_crown()
	if collect_delta > 0:
		await _list.play_collect_anim(collect_delta)
		if generation != _generation or not visible:
			return
		await play_post_collect_feedback(from_snap, to_snap)
		if generation != _generation or not visible:
			return
		_list.set_drag_enabled(false)
	else:
		_list.set_snapshot(to_snap, true)


func finish_show_feedback(ctx) -> void :
	var generation: int = ctx.generation
	var from_snap: RankSnapshot = ctx.from_snap
	var to_snap: RankSnapshot = ctx.to_snap
	var result: Dictionary = ctx.result
	var already_first: bool = ctx.already_first
	_play_encourage_word(result, from_snap, to_snap, generation)
	await _show_rise_tip(_resolve_finish_tip(result, from_snap, to_snap), generation)
	if generation != _generation or not visible:
		return
	if to_snap.my_rank_pos == 1 and not already_first:
		var item: RankItemView = _list.find_my_item()
		if item != null:
			_podium.set_first_crown_visible(false)
			await _crown.play_fly_in(item)
			if generation != _generation or not visible:
				return
	_list.set_drag_enabled(true)
	_reveal_continue()

func play_post_collect_feedback(from_snap: RankSnapshot, to_snap: RankSnapshot) -> void :
	var generation: int = _generation
	var list_generation: int = _list.animation_generation
	var already_first: bool = from_snap.my_rank_pos == 1 and to_snap.my_rank_pos == 1
	var same_podium_rank: bool = from_snap.my_rank_pos == to_snap.my_rank_pos and to_snap.my_rank_pos <= 3
	collect_feedback_stage.emit("扫光与上升粒子" if same_podium_rank else "升位／落位开始")
	await _list.play_rise_anim(from_snap, to_snap)
	if generation != _generation or not visible or not _list.animation_is_active(list_generation):
		return
	if already_first:
		collect_feedback_stage.emit("皇冠放大 → 下砸回弹")
		await _crown.play_collect_drop()
		if generation != _generation or not visible or not _list.animation_is_active(list_generation):
			return
		collect_feedback_stage.emit("皇冠恢复待机")
	elif not same_podium_rank:
		collect_feedback_stage.emit("升位／落位结束")
	if from_snap.my_rank_pos == to_snap.my_rank_pos and to_snap.my_rank_pos >= 1 and to_snap.my_rank_pos <= 3:
		AudioManager.play_sfx(&"rank_podium_landed")


func _on_hide() -> void :
	_reset_scrim_fade()
	SortLogger.info("[RankVirtual] stats=%s" % JSON.stringify(_list.get_performance_stats()))
	if not _content_ready:
		var was_visible: bool = visible
		_generation += 1
		_list.cancel_animations()
		_clock.stop()
		visible = false
		if was_visible:
			closed.emit()
		return
	var was_visible: bool = visible
	_list.cancel_animations()
	_generation += 1
	_hide_rise_tip()
	_hide_encourage_word()
	_confetti.reset()
	_clock.stop()
	if _continue_tween != null and _continue_tween.is_valid():
		_continue_tween.kill()
	_continue_btn.disabled = true
	_list.end_enter_mask()
	_crown.hide_crown()
	_podium.set_first_crown_visible(true)
	_reward_tooltip.hide_tooltip()
	visible = false
	if was_visible:
		closed.emit()

func _round_ranks(result: Dictionary, from_snap: RankSnapshot, to_snap: RankSnapshot) -> Vector2i:
	var before: int = int(result.get("rank_before", 0))
	var after: int = int(result.get("rank_after", 0))
	if before < 1 or before > 50 or after < 1 or after > 50:
		if from_snap == null or to_snap == null or not from_snap.is_valid() or not to_snap.is_valid():
			return Vector2i.ZERO
		before = from_snap.my_rank_pos
		after = to_snap.my_rank_pos
	return Vector2i(before, after)

func _resolve_finish_tip(result: Dictionary, from_snap: RankSnapshot, to_snap: RankSnapshot) -> Dictionary:
	var ranks: Vector2i = _round_ranks(result, from_snap, to_snap)
	var upgrade_end_rank: int = to_snap.upgrade_end_rank if to_snap != null else 0
	return RankEncourageRule.resolve_finish_tip(ranks.x, ranks.y, upgrade_end_rank, _rng)

func _play_encourage_word(result: Dictionary, from_snap: RankSnapshot, to_snap: RankSnapshot, generation: int) -> void :
	if generation != _generation or not visible or to_snap == null:
		return
	_hide_encourage_word()
	_confetti.reset()
	var ranks: Vector2i = _round_ranks(result, from_snap, to_snap)
	if not RankEncourageRule.should_show_finish_word(ranks.x, ranks.y, to_snap.upgrade_end_rank, to_snap.downgrade_start_rank):
		return
	_set_encourage_skin(ENCOURAGE_SKINS[_rng.randi_range(0, ENCOURAGE_SKINS.size() - 1)])
	_encourage_spine.update_mode = SpineConstant.UpdateMode_Process
	_encourage_word.show()
	if RankEncourageRule.should_play_top_three_confetti(ranks.x, ranks.y):
		_confetti.play()
	var tween: Tween = create_tween()
	_encourage_tween = tween
	tween.tween_interval(ENCOURAGE_REFERENCE_TIME)
	tween.tween_callback( func() -> void :
		if generation == _generation and _encourage_tween == tween:
			_encourage_spine.set_time_scale(0.0))
	tween.tween_interval(ENCOURAGE_HOLD_SEC)
	tween.tween_callback( func() -> void :
		if generation == _generation and _encourage_tween == tween:
			_encourage_spine.set_time_scale(1.0))
	tween.tween_interval(_encourage_spine.skeleton_data_res.find_animation(ENCOURAGE_ANIMATION).get_duration() - ENCOURAGE_REFERENCE_TIME)
	tween.tween_callback( func() -> void :
		if generation == _generation and _encourage_tween == tween:
			_hide_encourage_word())

func _set_encourage_skin(skin: String) -> void :
	var skeleton: SpineSkeleton = _encourage_spine.get_skeleton()
	var state: SpineAnimationState = _encourage_spine.get_animation_state()
	_encourage_spine.update_mode = SpineConstant.UpdateMode_Manual
	state.clear_tracks()
	skeleton.set_skin_by_name(skin)
	skeleton.set_to_setup_pose()
	state.set_animation(ENCOURAGE_ANIMATION, false, 0)
	if not _encourage_bounds.has(skin):

		_apply_encourage_pose(ENCOURAGE_REFERENCE_TIME)
		var full: Rect2 = skeleton.get_bounds()
		for slot: SpineSlot in skeleton.get_slots():
			if not slot.get_data().get_name().ends_with("_text"):
				slot.set_attachment(null)
		_encourage_bounds[skin] = {"full": full, "text": skeleton.get_bounds()}
	var full: Rect2 = _encourage_bounds[skin]["full"]
	var text: Rect2 = _encourage_bounds[skin]["text"]
	var factor: float = minf(ENCOURAGE_SCALE, maxf(UiMetrics.viewport_size().x - 80.0, 1.0) / full.size.x)
	_encourage_spine.scale = Vector2.ONE * factor
	_encourage_spine.position = - text.get_center() * factor

	state.clear_tracks()
	skeleton.set_to_setup_pose()
	state.set_animation(ENCOURAGE_ANIMATION, false, 0)
	_apply_encourage_pose(0.0)


func _apply_encourage_pose(elapsed: float) -> void :
	var skeleton: SpineSkeleton = _encourage_spine.get_skeleton()
	var state: SpineAnimationState = _encourage_spine.get_animation_state()
	state.update(elapsed)
	state.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	_encourage_spine.update_skeleton(0.0)

func _hide_encourage_word() -> void :
	_encourage_word.hide()
	if _encourage_tween != null and _encourage_tween.is_valid():
		_encourage_tween.kill()
	_encourage_tween = null
	if _encourage_spine == null:
		return
	_encourage_spine.set_time_scale(1.0)
	_encourage_spine.update_mode = SpineConstant.UpdateMode_Manual
	_encourage_spine.get_animation_state().clear_tracks()
	_encourage_spine.get_skeleton().set_to_setup_pose()

func _show_rise_tip(tip: Dictionary, generation: int) -> void :
	if generation != _generation or not visible:
		return
	_hide_rise_tip()
	if String(tip.get("key", "")).is_empty():
		return
	_set_rise_tip_text(tip)

	var offscreen_y: float = - maxf(0.0, _rise_tip_holder.global_position.y) - _rise_tip.size.y - 8.0
	_rise_tip.position.y = offscreen_y
	_rise_tip_holder.show()
	var tween: Tween = create_tween()
	_rise_tip_tween = tween
	tween.tween_property(_rise_tip, "position:y", 0.0, RISE_TIP_SLIDE_SEC)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	while generation == _generation and visible and tween.is_valid() and tween.is_running():
		await get_tree().process_frame
	if generation == _generation and visible and _rise_tip_tween == tween:
		_rise_tip.position = Vector2.ZERO
		_rise_tip_tween = null

func _set_rise_tip_text(tip: Dictionary) -> void :
	var template: String = tr(String(tip["key"]))
	var arg: int = int(tip["arg"])
	var text: String = template % arg if arg >= 0 else template
	_rise_tip_text.add_theme_font_size_override("normal_font_size", _TIP_BASE_FONT_SIZE)
	_rise_tip_text.clear()
	_rise_tip_text.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	if arg >= 0:
		var parts: PackedStringArray = template.split("%d", true, 1)
		_rise_tip_text.add_text(parts[0])
		_rise_tip_text.push_color(RISE_TIP_NUMBER_COLOR)
		_rise_tip_text.add_text(str(arg))
		_rise_tip_text.pop()
		_rise_tip_text.add_text(parts[1])
	else:
		_rise_tip_text.add_text(text)
	_rise_tip_text.pop()

	var text_height: float = maxf(132.0, float(_rise_tip_text.get_content_height()) + 4.0)
	var extra: float = text_height - 132.0
	_rise_tip_text.size.y = text_height
	_rise_tip.size.y = 218.319153 + extra
	(_rise_tip.get_node("Fill") as Control).size.y = 134.37738 + extra
	(_rise_tip.get_node("Border") as Control).size.y = 165.779358 + extra

func _hide_rise_tip() -> void :
	_rise_tip_holder.hide()
	if _rise_tip_tween != null and _rise_tip_tween.is_valid():
		_rise_tip_tween.kill()
	_rise_tip_tween = null
	_rise_tip.position = Vector2.ZERO
	_rise_tip_text.clear()

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
	var material: ShaderMaterial = _title_label.material as ShaderMaterial
	material.set_shader_parameter("ink_top", (176.0 - float(font_size)) * 0.5)
	material.set_shader_parameter("ink_bottom", (176.0 + float(font_size)) * 0.5)

func _attach_resting_crown() -> void :
	var item: RankItemView = _list.find_my_item()
	if item != null:
		_podium.set_first_crown_visible(false)
		_crown.show_resting(item)


func _on_avatar_landed(rank: int) -> void :
	if rank == 1 and _crown.get_attached_item() != null:
		_crown.play_land_bounce()

func _reveal_continue() -> void :
	_continue_btn.disabled = false
	_continue_tween = create_tween()
	_continue_tween.tween_property(_continue_btn, "modulate:a", 1.0, CONTINUE_FADE_SEC)

func _on_gift_tapped(rank_pos: int, global_rect: Rect2) -> void :
	if _continue_btn.disabled:
		return
	_reward_tooltip.show_at(global_rect, RankManager.get_reward_preview(rank_pos))
	_list.set_drag_enabled(false)

func _on_reward_tooltip_closed() -> void :
	_list.set_drag_enabled(true)

func _on_back_request() -> void :
	if not _continue_btn.disabled:
		_close_finish()

func _on_continue_pressed() -> void :
	if _closing or _continue_btn.disabled:
		return

	Tracker.track_btn_click(TrackingEvents.BTN_RANK_RENEW)
	_close_finish()


func _close_finish() -> void :
	if _closing:
		return
	_closing = true
	_on_hide()



func prepare_motion_preview(from_snap: RankSnapshot, to_snap: RankSnapshot, count: int, 
		texture: Texture2D, active: Callable) -> Dictionary:
	_generation += 1
	_closing = false
	_list.cancel_animations()
	_crown.hide_crown()
	_hide_rise_tip()
	_hide_encourage_word()
	if not await prepare_content(active) or not active.call():
		return {}
	_list._ensure_element_pool()
	_list._element_pool.presentation_texture = texture
	_podium.set_first_crown_visible(true)
	_podium.prepare_enter()
	_list.begin_enter_mask()
	_list.set_drag_enabled(false)
	_continue_btn.disabled = true
	_continue_btn.modulate.a = 0.0
	_clock.stop()
	_clock.refresh_time()
	_title_label.text = tr("RANK_LEADERBOARD_TITLE")
	_fit_title_font_size()
	show()
	_start_scrim_fade()
	_sync_list_layout()
	if not await _list.prepare_first_screen(from_snap, from_snap.my_rank_pos, active):
		return {}
	if not await _list.prepare_animation(active) or not active.call():
		return {}
	_list.begin_enter_mask()
	_list.scroll_rank_to_center(from_snap.my_rank_pos)
	return {"page": self, "generation": _generation, "ready": true, "active": active, 
		"from_snap": from_snap, "to_snap": to_snap, "collect_delta": count, 
		"result": {"collect_delta": count}, 
		"already_first": from_snap.my_rank_pos == 1 and to_snap.my_rank_pos == 1}



func _start_scrim_fade() -> void :
	_reset_scrim_fade()
	_scrim_tween = create_tween()
	_scrim_tween.tween_property(_scrim, "self_modulate:a", 1.0, SCRIM_FADE_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not OS.has_feature("rel"):
		SortLogger.info("[RankFinishEnter] scrim_fade_sec=%.2f ease=SINE_OUT generation=%d" % [SCRIM_FADE_SEC, _generation])


func _reset_scrim_fade() -> void :
	if _scrim_tween != null and _scrim_tween.is_valid():
		_scrim_tween.kill()
	_scrim_tween = null
	if is_instance_valid(_scrim):
		_scrim.self_modulate.a = 0.0


func _exit_tree() -> void :
	_reset_scrim_fade()
