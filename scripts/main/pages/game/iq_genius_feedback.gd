extends Control



const TOTAL_SECONDS: float = 2.2
const FADE_START_SECONDS: float = 2.0
const FADE_SECONDS: float = TOTAL_SECONDS - FADE_START_SECONDS
const ENTER_PLAYBACK_SPEED: float = 1.0
@onready var _composite: CanvasGroup = $Composite
@onready var _dim: ColorRect = $Composite / Dim
@onready var _content: Control = $Composite / Content
@onready var _spine: SpineSprite = $Composite / Content / Spine
@onready var _title: Control = $TitleViewport / Title
@onready var _title_viewport: SubViewport = $TitleViewport
@onready var _title_display: TextureRect = $Composite / Content / Spine / TitleAnchor / Title
var _elapsed: float = 0.0
var _playing: bool = false
var _first_tick: bool = false
var _last_tick_usec: int = 0


func _ready() -> void :
	_title_display.texture = _title_viewport.get_texture()
	resized.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	set_process(false)
	_layout()


func present() -> void :
	hide_now()
	if not _spine_ready():

		var data: SpineSkeletonDataResource = _spine.skeleton_data_res
		SortLogger.error("IqGeniusFeedback: Spine骨架不可用，跳过Genius data=%s loaded=%s atlas=%s file=%s" % [
			data != null, data != null and data.is_skeleton_data_loaded(), 
			data != null and data.atlas_res != null, data != null and data.skeleton_file_res != null])
		return
	_refresh_title()
	_layout()
	_elapsed = 0.0
	modulate.a = 1.0
	_composite.self_modulate.a = 1.0
	show()
	_spine.show()
	_spine.get_skeleton().set_to_setup_pose()
	var state: SpineAnimationState = _spine.get_animation_state()
	state.set_animation("enter", false, 0)
	_playing = true
	_first_tick = true
	_spine.update_skeleton(0.0)
	_last_tick_usec = Time.get_ticks_usec()
	set_process(true)
	AudioManager.play_sfx(&"iq_genius_feedback")


func hide_now() -> void :
	hide()
	_stop_animation()
	_spine.hide()


func is_playing() -> bool:
	return _playing


func _process(_delta: float) -> void :

	var now_usec: int = Time.get_ticks_usec()
	var elapsed: float = float(now_usec - _last_tick_usec) / 1000000.0
	_last_tick_usec = now_usec
	if _first_tick:
		_first_tick = false
		return
	_advance_animation(elapsed * Engine.time_scale)


func _advance_animation(delta: float) -> void :
	if not _playing:
		return
	_elapsed = minf(TOTAL_SECONDS, _elapsed + maxf(delta, 0.0))
	var current: SpineTrackEntry = _spine.get_animation_state().get_current(0)
	var speed: float = ENTER_PLAYBACK_SPEED if current != null and current.get_animation().get_name() == "enter" else 1.0
	_spine.update_skeleton(delta * speed)

	_composite.self_modulate.a = 1.0 - clampf((_elapsed - FADE_START_SECONDS) / FADE_SECONDS, 0.0, 1.0)
	if _elapsed >= TOTAL_SECONDS:
		hide_now()


func _stop_animation() -> void :
	AudioManager.stop_sfx(&"iq_genius_feedback")
	_playing = false
	_first_tick = false
	set_process(false)
	if _spine_ready():
		_spine.get_animation_state().clear_tracks()
		_spine.get_skeleton().set_to_setup_pose()
	_title_display.modulate.a = 0.0



func _spine_ready() -> bool:
	return _spine.get_animation_state() != null and _spine.get_skeleton() != null


func _on_visibility_changed() -> void :
	if not is_visible_in_tree():
		_stop_animation()


func _on_spine_world_transforms_changed(sprite: SpineSprite) -> void :
	if not is_node_ready():
		return

	var text_slot: SpineSlot = sprite.get_skeleton().find_slot("title_iq_genius")
	if text_slot != null:
		text_slot.set_attachment(null)
	var sample_bg: SpineSlot = sprite.get_skeleton().find_slot("bg_level_dimmed")
	if sample_bg != null:
		sample_bg.set_attachment(null)

	_title_display.modulate = sprite.get_skeleton().find_slot("title_iq_genius").get_color()


func _notification(what: int) -> void :
	if what == NOTIFICATION_UNPAUSED:

		_last_tick_usec = Time.get_ticks_usec()
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_refresh_title()


func _refresh_title() -> void :
	_title.set_title(tr("GAME_IQ_GENIUS_TITLE"))
	_title_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _layout() -> void :
	var viewport_size: Vector2 = UiMetrics.viewport_size()

	_dim.size = viewport_size
	_content.position = (viewport_size - _content.size) * 0.5
