class_name RankSeasonWinPage
extends PageScene

signal finished

const BANNER_ANIM_IN: StringName = &"season_win_intro"
const BANNER_ANIM_IDLE: StringName = &"season_win_idle"
const CUE_BURST_SEC: float = 1.1
const CUE_EXIT_SEC: float = 5.7
const FADE_OUT_SEC: float = 0.45
const HANDOFF_HOLD_SEC: float = 0.4

@export var top_icons: Array[Texture2D] = []

@onready var _flags: RankSeasonWinFlags = $Flags
@onready var _presentation: Control = $Presentation
@onready var _spine: SpineSprite = $Presentation / Spine
@onready var _avatar_pool: RankAvatarPool = $AvatarPool
@onready var _firework: FireworkShow = $Firework
@onready var _confetti: ConfettiFx = $Confetti
@onready var _danmaku: RankDanmakuLayer = $DanmakuLayer
@onready var _cue_clock: Timer = $CueClock
@onready var _avatar: RankAvatarCell = $DynamicTextures / Avatar / Cell
@onready var _nickname: Label = $DynamicTextures / Nickname / Label
@onready var _rank: Label = $DynamicTextures / Rank / Label
@onready var _title: Label = $DynamicTextures / Title / Label
@onready var _viewports: Array[SubViewport] = [
	$DynamicTextures / Avatar, $DynamicTextures / Nickname, 
	$DynamicTextures / Rank, $DynamicTextures / Title, 
]
@onready var _slots: Array[SpineSlotNode] = [
	$Presentation / Spine / AvatarSlot, $Presentation / Spine / NicknameSlot, 
	$Presentation / Spine / RankSlot, $Presentation / Spine / TitleSlot, 
]
@onready var _badge_slot: SpineSlotNode = $Presentation / Spine / BadgeSlot

var presentation_finished: bool = false
var _show_token: int = 0
var _show_ms: int = 0
var _rank_pos: int = 0
var _end_tier: int = RankBadgeView.TIER_MIN
var _texture_keys: Array[String] = ["", "", "", ""]
var _anim_tweens: Array[Tween] = []
var _firework_preparing: bool = false


func _ready() -> void :
	for index: int in _slots.size():
		var material: ShaderMaterial = _slots[index].normal_material as ShaderMaterial
		material.set_shader_parameter("replacement_texture", _viewports[index].get_texture())
		material.set_shader_parameter("enabled", true)
	_spine.world_transforms_changed.connect(_update_text_centers)


func _on_show(params: Dictionary = {}) -> void :
	set_meta(RankSessionFlow.DIALOG_LEASE, null)
	_show_token += 1
	var token: int = _show_token
	presentation_finished = false
	_reset_to_start_state()
	_end_tier = clampi(int(params.get("end_tier", RankManager.get_current_tier())), 
		RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX)
	var snapshot: RankSnapshot = RankManager.get_current_snapshot()
	_rank_pos = int(params.get("rank_pos", snapshot.my_rank_pos if snapshot != null else 0))
	_bind_badge()
	visible = true

	while _firework_preparing:
		await get_tree().process_frame
		if token != _show_token or not is_inside_tree():
			return
	_firework_preparing = true
	await _firework.prepare_pool_spread()
	_firework_preparing = false
	if token != _show_token or not is_inside_tree():
		return
	if not await _prepare_dynamic_textures(token):
		return

	_show_ms = Time.get_ticks_msec()
	_flags.play()
	_play_spine_intro()
	AudioManager.play_sfx(&"rank_season_win")
	_danmaku.start(_end_tier)
	if not await _cue(token, CUE_BURST_SEC):
		return
	_firework.visible = true
	_firework.play()
	_confetti.play()
	if not await _cue(token, CUE_EXIT_SEC):
		return
	_danmaku.stop()
	_firework.stop()
	_confetti.fade_out(FADE_OUT_SEC)
	var fade: Tween = create_tween().set_parallel(true)
	_anim_tweens.append(fade)
	for node: CanvasItem in [_flags, _presentation, _firework]:
		fade.tween_property(node, "modulate:a", 0.0, FADE_OUT_SEC)
	if not await _cue(token, CUE_EXIT_SEC + FADE_OUT_SEC):
		return
	presentation_finished = true
	finished.emit()


func _bind_badge() -> void :
	var material: ShaderMaterial = _badge_slot.normal_material as ShaderMaterial
	var is_top: bool = _rank_pos >= 1 and _rank_pos <= 3
	material.set_shader_parameter("enabled", is_top)
	material.set_shader_parameter("replacement_texture", top_icons[_rank_pos - 1] if is_top else null)

	material.set_shader_parameter("content_scale", Vector2(1.0, 87.0 / 111.0))


func _prepare_dynamic_textures(token: int) -> bool:
	var avatar_index: int = RankManager.get_display_avatar_index()
	var nickname: String = RankManager.get_display_nickname()
	var locale: String = TranslationServer.get_locale()
	var rank_text: String = _format_rank(_rank_pos, locale)
	var title_text: String = tr("RANK_SEASON_WIN_TITLE")
	_avatar.bind(avatar_index, _avatar_pool.get_texture(avatar_index))
	_fit_label(_nickname, nickname, 92)
	_fit_label(_rank, rank_text, 76)
	_fit_label(_title, title_text, 168)
	var keys: Array[String] = [str(avatar_index), nickname + "|" + locale, 
		rank_text + "|" + locale, title_text + "|" + locale]
	for index: int in _viewports.size():
		if keys[index] == _texture_keys[index]:
			continue
		var viewport: SubViewport = _viewports[index]
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

		if DisplayServer.get_name() == "headless":
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw
		if token != _show_token or not is_inside_tree():
			return false
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_texture_keys[index] = keys[index]
	return token == _show_token


func _fit_label(label: Label, text: String, maximum_size: int) -> void :
	label.text = text
	label.language = TranslationServer.get_locale()
	var font: Font = label.get_theme_font(&"font")
	var outline: float = float(label.get_theme_constant(&"outline_size")) * 2.0
	var bounds: Vector2 = Vector2((label.get_parent() as SubViewport).size)
	var available: Vector2 = bounds - Vector2(8.0, 4.0)
	var minimum_size: int = 1
	var font_size: int = 1

	while minimum_size <= maximum_size:
		var candidate: int = (minimum_size + maximum_size) / 2
		var line: TextLine = TextLine.new()
		line.add_string(text, font, candidate, label.language)
		var measured: Vector2 = line.get_size() + Vector2.ONE * outline
		label.add_theme_font_size_override(&"font_size", candidate)
		var minimum: Vector2 = label.get_minimum_size()
		if measured.x <= available.x and measured.y <= available.y\
		and minimum.x <= available.x and minimum.y <= available.y:
			font_size = candidate
			minimum_size = candidate + 1
		else:
			maximum_size = candidate - 1
	label.add_theme_font_size_override(&"font_size", font_size)
	label.size = bounds


static func _format_rank(rank_pos: int, _locale: String) -> String:
	if rank_pos < 1:
		return ""
	return str(rank_pos) + "st"


func _update_text_centers(_sprite: SpineSprite) -> void :


	var centers: Array[Vector2] = [Vector2(-16.5, -1.5), Vector2(124.0, 6.0)]
	for index: int in centers.size():
		var slot: SpineSlotNode = _slots[index + 1]
		var bone: SpineBone = _spine.get_skeleton().find_slot(slot.get("slot_name")).get_bone()
		var material: ShaderMaterial = slot.normal_material as ShaderMaterial
		material.set_shader_parameter("mesh_center", bone.local_to_world(centers[index]))


func _play_spine_intro() -> void :
	var state: SpineAnimationState = _spine.get_animation_state()
	state.clear_tracks()
	_spine.get_skeleton().set_to_setup_pose()
	state.set_animation(BANNER_ANIM_IN, false, 0)
	state.add_animation(BANNER_ANIM_IDLE, 0.0, true, 0)
	_spine.set_time_scale(1.0)
	_spine.visible = true
	_spine.update_skeleton(0.0)
	_spine.update_mode = SpineConstant.UpdateMode_Process


func hold_then_hide() -> void :
	var token: int = _show_token
	await get_tree().create_timer(HANDOFF_HOLD_SEC).timeout
	if token == _show_token:
		SceneManager.hide_dlg("rank_season_win")


func _on_hide() -> void :
	_show_token += 1
	_cancel_cue()
	_stop_effects()
	AudioManager.stop_sfx(&"rank_season_win")
	_spine.get_animation_state().clear_tracks()
	_spine.update_mode = SpineConstant.UpdateMode_Manual
	_spine.set_time_scale(0.0)
	_spine.visible = false
	for viewport: SubViewport in _viewports:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_kill_anims()
	visible = false


func _reset_to_start_state() -> void :
	_cancel_cue()
	_kill_anims()
	_stop_effects()
	_spine.visible = false
	_spine.update_mode = SpineConstant.UpdateMode_Manual
	_spine.set_time_scale(0.0)
	for node: CanvasItem in [_flags, _presentation, _firework, _danmaku]:
		node.modulate.a = 1.0


func _stop_effects() -> void :
	_flags.stop()
	_firework.stop()
	_firework.visible = false
	_confetti.reset()
	_danmaku.stop()


func _cue(token: int, at_sec: float) -> bool:
	var wait_ms: int = _show_ms + int(at_sec * 1000.0) - Time.get_ticks_msec()
	if wait_ms > 0:
		_cue_clock.start(float(wait_ms) / 1000.0)
		await _cue_clock.timeout
	return token == _show_token and is_inside_tree()


func _cancel_cue() -> void :
	_cue_clock.stop()

	_cue_clock.timeout.emit()


func _kill_anims() -> void :
	for tween: Tween in _anim_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_anim_tweens.clear()
