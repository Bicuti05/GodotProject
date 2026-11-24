class_name RankNewSeasonDialog
extends PageScene


signal closed

const _POOL_SCENE_PATH: String = "res://scripts/gameplay/rank/view/rank_collect_element_pool.tscn"

const _ITEM_DUR: float = 0.4
const _OVERLAY_DUR: float = 0.25
const _EXIT_DUR: float = 0.2
const _TITLE_ANIMATION: StringName = &"idle"

const _TITLE_SCALE: float = 1034.4 / 806.7692
const _TITLE_DECORATION_SCALE: float = 0.9
const _TITLE_SLOT_REST_RECT: Rect2 = Rect2(-231.0, -63.0, 462.0, 99.0)
const _TITLE_CACHE_SIZE: Vector2 = Vector2(500.0, 136.0)

@export var badges: Array[Texture2D] = []


@onready var _overlay: ColorRect = $Root / Overlay
@onready var _content: Control = $Root / Content
@onready var _dialog: Control = $Root / Content / Dialog
@onready var _bg: NinePatchRect = $Root / Content / Dialog / common_dialog_bg
@onready var _title: Control = $Root / Content / Dialog / Title
@onready var _title_spine: SpineSprite = $Root / Content / Dialog / TitleSpine
@onready var _title_slot: SpineSlotNode = $Root / Content / Dialog / TitleSpine / TitleSlot
@onready var _composite: SubViewport = $Root / Content / Dialog / Title / Composite
@onready var _body: SubViewport = $Root / Content / Dialog / Title / Composite / BodyMask
@onready var _face: SubViewport = $Root / Content / Dialog / Title / Composite / FaceMask
@onready var _body_text: RankNewSeasonTitleMask = $Root / Content / Dialog / Title / Composite / BodyMask / Text
@onready var _face_text: RankNewSeasonTitleMask = $Root / Content / Dialog / Title / Composite / FaceMask / Text
@onready var _effect: TextureRect = $Root / Content / Dialog / Title / Composite / Effect
@onready var _close_btn: TextureButton = $Root / Content / Dialog / CloseButton
@onready var _clock: RankFinishClock = $Root / Content / Dialog / Clock
@onready var _illustration: TextureRect = $Root / Content / Dialog / Illustration
@onready var _medal: TextureRect = $Root / Content / Dialog / Medal
@onready var _tips: RankNewSeasonTips = $Root / Content / Dialog / Tips
@onready var _ok_btn: CommonBtn = $Root / Content / Dialog / OkButton

var _element_pool: RankCollectElementPool = null
var _closing: bool = false
var _generation: int = 0
var _open_rank_on_close: bool = false
var _enter_tween: Tween
var _exit_tween: Tween
var _title_cache_key: String = ""
var _title_content_scale: Vector2 = Vector2.ONE


func _ready() -> void :
	_title_spine.before_world_transforms_change.connect(_hide_title_glow)
	_effect.texture = _body.get_texture()
	var material: ShaderMaterial = _effect.material as ShaderMaterial
	material.set_shader_parameter("body_mask", _body.get_texture())
	material.set_shader_parameter("face_mask", _face.get_texture())
	var slot_material: ShaderMaterial = _title_slot.normal_material as ShaderMaterial
	slot_material.set_shader_parameter("replacement_texture", _composite.get_texture())
	slot_material.set_shader_parameter("enabled", true)


	slot_material.set_shader_parameter("mesh_scale", 1.0 / _TITLE_DECORATION_SCALE)
	var fit: float = minf(_TITLE_SLOT_REST_RECT.size.x / _TITLE_CACHE_SIZE.x, 
		_TITLE_SLOT_REST_RECT.size.y / _TITLE_CACHE_SIZE.y)
	_title_content_scale = _TITLE_CACHE_SIZE * fit / _TITLE_SLOT_REST_RECT.size
	slot_material.set_shader_parameter("content_scale", _title_content_scale)
	resized.connect(_layout_dialog)
	_layout_dialog()


func _layout_dialog() -> void :
	var insets: Vector2 = UiMetrics.safe_insets()
	var shift: float = (insets.x - insets.y) * 0.5
	_dialog.offset_top = -1172.0 + shift
	_dialog.offset_bottom = 1172.0 + shift


func _on_show(_params: Dictionary = {}) -> void :
	set_meta(RankSessionFlow.DIALOG_LEASE, null)
	_generation += 1
	_stop_title()
	_closing = false
	_open_rank_on_close = false
	_cancel_title_render()
	_apply_collectible()
	_layout_dialog()
	visible = true
	_kill_tweens()
	_prepare_shell()
	_ok_btn.disabled = true
	_close_btn.disabled = true
	var generation: int = _generation
	await _prepare_title(generation)
	if generation != _generation or _closing:
		return
	_play_title()
	_clock.start()

	Tracker.track_scr_show(TrackingEvents.SCR_CHALLENGE_RENEW)
	_play_enter()


func _on_hide() -> void :
	_generation += 1
	_stop_title()
	_cancel_title_render()
	_clock.stop()
	_closing = true
	_kill_tweens()
	visible = false
	closed.emit()


func _apply_collectible() -> void :
	var tier: int = RankManager.get_current_tier()
	_medal.texture = badges[clampi(tier - 1, 0, badges.size() - 1)] if not badges.is_empty() else null
	if _ensure_element_pool():
		var texture: Texture2D = _element_pool.get_texture()
		_tips.set_content(tr("RANK_NEW_SEASON_TIPS"), texture)


func _prepare_title(generation: int) -> void :
	var text: String = tr("RANK_NEW_SEASON_TITLE")
	var key: String = TranslationServer.get_locale() + ":" + text
	if _title_cache_key == key:
		return
	_title_cache_key = ""
	_body_text.prepare(text)
	_face_text.prepare(text, _body_text.fit)

	var safe: Rect2 = Rect2(8.0, 8.0, 484.0, 120.0)
	for attempt: int in 12:
		if safe.encloses(_body_text.ink_bounds) and safe.encloses(_face_text.ink_bounds):
			break
		var fit: float = _body_text.fit * 0.9
		_body_text.prepare(text, fit)
		_face_text.prepare(text, fit)
	if DisplayServer.get_name() == "headless":
		return


	await get_tree().process_frame
	if generation != _generation or _closing:
		return
	_body.render_target_update_mode = SubViewport.UPDATE_ONCE
	_face.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	if generation != _generation or _closing:
		return
	_composite.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	if generation != _generation or _closing:
		return
	_cancel_title_render()
	_title_cache_key = key


func _play_title() -> void :

	var ink: Rect2 = _body_text.ink_bounds.merge(_face_text.ink_bounds)
	var center: Vector2 = ink.get_center()

	var slot_center: Vector2 = _TITLE_SLOT_REST_RECT.get_center()\
	+ _TITLE_SLOT_REST_RECT.size * _title_content_scale * (center / _TITLE_CACHE_SIZE - Vector2.ONE * 0.5)
	_title_spine.position = _title.position + center - slot_center * _TITLE_SCALE
	_title_spine.scale = Vector2.ONE * _TITLE_SCALE * _TITLE_DECORATION_SCALE
	var state: SpineAnimationState = _title_spine.get_animation_state()
	state.clear_tracks()
	_title_spine.get_skeleton().set_to_setup_pose()
	state.set_animation(_TITLE_ANIMATION, true, 0)
	_title_spine.set_time_scale(1.0)
	_title_spine.visible = true
	_title_spine.update_skeleton(0.0)
	_title_spine.update_mode = SpineConstant.UpdateMode_Process


func _hide_title_glow(_sprite: SpineSprite) -> void :
	_title_spine.get_skeleton().find_slot("glow").set_attachment(null)


func _stop_title() -> void :
	_title_spine.visible = false
	_title_spine.update_mode = SpineConstant.UpdateMode_Manual
	_title_spine.set_time_scale(0.0)
	_title_spine.get_animation_state().clear_tracks()


func _cancel_title_render() -> void :
	_body.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_face.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_composite.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _ensure_element_pool() -> bool:
	if _element_pool != null:
		return true
	var scene: PackedScene = load(_POOL_SCENE_PATH) as PackedScene
	if scene == null:
		SortLogger.error("RankNewSeasonDialog: 收集元素池加载失败 %s" % _POOL_SCENE_PATH)
		return false
	_element_pool = scene.instantiate() as RankCollectElementPool
	if _element_pool == null:
		SortLogger.error("RankNewSeasonDialog: 收集元素池根节点类型不符 %s" % _POOL_SCENE_PATH)
		return false
	add_child(_element_pool)
	return true

func _on_ok_pressed() -> void :
	if _closing:
		return

	Tracker.track_btn_click(TrackingEvents.BTN_CHALLENGE_RENEW)
	_open_rank_on_close = true
	_close()


func _on_close_pressed() -> void :

	Tracker.track_btn_click(TrackingEvents.BTN_CLOSE)
	_close()


func _on_back_request() -> void :
	_close()


func should_open_rank_on_close() -> bool:
	return _open_rank_on_close


func _close() -> void :
	if _closing:
		return
	_closing = true
	_generation += 1
	_clock.stop()
	_ok_btn.disabled = true
	_close_btn.disabled = true
	var generation: int = _generation
	_kill_tweens()
	_cancel_title_render()
	_title_spine.update_mode = SpineConstant.UpdateMode_Manual
	_title_spine.set_time_scale(0.0)
	_exit_tween = create_tween()
	_exit_tween.set_parallel(true)
	_exit_tween.tween_property(_overlay, "self_modulate:a", 0.0, _EXIT_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(_content, "modulate:a", 0.0, _EXIT_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var tw: Tween = _exit_tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation != _generation:
		return
	_stop_title()
	visible = false
	closed.emit()


func _prepare_shell() -> void :

	_content.modulate = Color(1, 1, 1, 0)
	_content.scale = Vector2.ONE
	_overlay.self_modulate = Color(1, 1, 1, 0)


func _play_enter() -> void :
	_enter_tween = create_tween().set_parallel(true)
	_enter_tween.tween_property(_overlay, "self_modulate:a", 1.0, _OVERLAY_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_enter_tween.tween_property(_content, "modulate:a", 1.0, _ITEM_DUR)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var generation: int = _generation
	_enter_tween.finished.connect( func() -> void :
		if generation == _generation and not _closing:
			_ok_btn.disabled = false
			_close_btn.disabled = false)


func _kill_tweens() -> void :
	if _enter_tween != null and _enter_tween.is_valid():
		_enter_tween.kill()
	_enter_tween = null
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()
	_exit_tween = null
