class_name LongLinkFeedback
extends Control


@export_file("*.tscn") var spine_scene_paths: PackedStringArray = PackedStringArray()

const ENTER: StringName = &"enter"
const EXIT: StringName = &"exit"
const PLAYBACK_SPEED: float = 1.5
const DISPLAY_SCALE: float = 0.9
const MAX_ENTER_DURATION: float = 1.0
const EXIT_MIX_DURATION: float = 0.08
const SFX_IDS: Array[StringName] = [&"long_link_emoji_2", &"long_link_emoji_3", &"long_link_emoji_5"]

var _next_variant: int = -1
var _sprites: Dictionary = {}
var _bounds: Dictionary = {}
var _animations: Dictionary = {}
var _failed_variants: Dictionary = {}
var _loading_path: String = ""
var _loading_variant: int = -1
var _loaded_scene: PackedScene
var _preparing_spine: SpineSprite
var _pending: Dictionary = {}
var _active: SpineSprite
var _active_exit_name: StringName = &""
var _sfx_id: StringName = &""


func _ready() -> void :
	set_process(false)


func _exit_tree() -> void :
	_stop_sfx()



func prepare() -> void :
	if spine_scene_paths.is_empty():
		SortLogger.error("LongLinkFeedback: no Spine scenes configured")
		return
	if _next_variant < 0:
		_next_variant = randi_range(0, spine_scene_paths.size() - 1)
	_request_variant(_next_variant)


func play(center: Vector2, flower_width: float) -> void :
	_stop_sfx()
	_stop_active()
	prepare()
	if _next_variant < 0:
		return
	_pending = {"variant": _next_variant, "center": center, "flower_width": flower_width}
	_try_play_pending()


func hide_now() -> void :

	_pending.clear()
	_stop_sfx()
	_stop_active()


func _request_variant(variant: int) -> void :
	if _sprites.has(variant) or _failed_variants.has(variant) or _loading_variant >= 0:
		return
	var path: String = spine_scene_paths[variant]
	var error: Error = ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		_failed_variants[variant] = true
		SortLogger.error("LongLinkFeedback: cannot request %s, error=%d" % [path, error])
		return
	_loading_variant = variant
	_loading_path = path
	set_process(true)


func _process(_delta: float) -> void :

	if not _loading_path.is_empty():
		var status: int = ResourceLoader.load_threaded_get_status(_loading_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loaded_scene = ResourceLoader.load_threaded_get(_loading_path) as PackedScene
			_loading_path = ""
			if _loaded_scene == null:
				_fail_preparation("loaded resource is not a PackedScene")
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_preparation("threaded load failed: %s" % _loading_path)
		return
	if _loaded_scene != null:
		_preparing_spine = _loaded_scene.instantiate() as SpineSprite
		_loaded_scene = null
		if _preparing_spine == null:
			_fail_preparation("scene root is not a SpineSprite")
			return
		_preparing_spine.visible = false
		_preparing_spine.process_mode = Node.PROCESS_MODE_DISABLED

		_preparing_spine.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		_preparing_spine.z_as_relative = false
		add_child(_preparing_spine)
		_preparing_spine.animation_completed.connect(_on_animation_completed)
		return
	if _preparing_spine != null:
		_prepare_spine()
		return
	_try_play_pending()
	_request_variant(_next_variant)
	if _loading_variant < 0:
		set_process(false)


func _prepare_spine() -> void :
	var skeleton: SpineSkeleton = _preparing_spine.get_skeleton()
	var state: SpineAnimationState = _preparing_spine.get_animation_state()
	if skeleton == null or state == null:
		_fail_preparation("missing skeleton or animation state")
		return
	var data: SpineSkeletonDataResource = skeleton.get_data()
	var enter_animation: SpineAnimation = data.find_animation(&"appear")
	if enter_animation == null:
		enter_animation = data.find_animation(ENTER)
	var exit_animation: SpineAnimation = data.find_animation(&"disappear")
	if exit_animation == null:
		exit_animation = data.find_animation(EXIT)
	if enter_animation == null or exit_animation == null:
		_fail_preparation("missing appearance or disappearance animation")
		return


	var bounds: Rect2 = Rect2(data.get_x(), - data.get_y() - data.get_height(), 
		data.get_width(), data.get_height())
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		_fail_preparation("empty reference bounds")
		return
	_bounds[_loading_variant] = bounds
	_animations[_loading_variant] = {"enter": enter_animation.get_name(), "exit": exit_animation.get_name()}
	_sprites[_loading_variant] = _preparing_spine
	state.clear_tracks()
	skeleton.set_to_setup_pose()
	_preparing_spine = null
	_loading_variant = -1


func _try_play_pending() -> void :
	if _pending.is_empty():
		return
	var variant: int = int(_pending["variant"])
	if _failed_variants.has(variant):
		_pending.clear()
		return
	if not _sprites.has(variant):
		return
	var spine: SpineSprite = _sprites[variant]
	var bounds: Rect2 = _bounds[variant]

	var center: Vector2 = _pending["center"]
	var flower_radius: float = float(_pending["flower_width"]) * 0.5
	center += Vector2(flower_radius, - flower_radius)
	var half_size: Vector2 = bounds.size * DISPLAY_SCALE * 0.5
	var viewport_rect: Rect2 = get_global_transform().affine_inverse() * Rect2(Vector2.ZERO, UiMetrics.viewport_size())
	center.x = clampf(center.x, viewport_rect.position.x + half_size.x, viewport_rect.end.x - half_size.x)
	center.y = clampf(center.y, viewport_rect.position.y + half_size.y, viewport_rect.end.y - half_size.y)
	spine.scale = Vector2.ONE * DISPLAY_SCALE
	spine.position = center - bounds.get_center() * DISPLAY_SCALE
	var animations: Dictionary = _animations[variant]
	_apply_enter_pose(spine, 0.0, animations["enter"])
	var state: SpineAnimationState = spine.get_animation_state()
	state.set_time_scale(PLAYBACK_SPEED)

	var enter_entry: SpineTrackEntry = state.get_current(0)
	var enter_duration: float = enter_entry.get_animation().get_duration()
	var enter_end: float = minf(enter_duration, MAX_ENTER_DURATION * PLAYBACK_SPEED)
	enter_entry.set_animation_end(enter_end)
	var exit_entry: SpineTrackEntry = state.add_animation(animations["exit"], enter_end, false, 0)

	exit_entry.set_mix_duration(EXIT_MIX_DURATION * PLAYBACK_SPEED if enter_end < enter_duration else 0.0)
	_pending.clear()
	_active = spine
	_active_exit_name = animations["exit"]
	spine.process_mode = Node.PROCESS_MODE_INHERIT
	spine.show()
	_sfx_id = SFX_IDS[randi_range(0, SFX_IDS.size() - 1)]
	AudioManager.play_sfx(_sfx_id)
	_next_variant = randi_range(0, spine_scene_paths.size() - 1)
	_request_variant(_next_variant)


func _apply_enter_pose(spine: SpineSprite, time: float, animation_name: StringName) -> void :
	var skeleton: SpineSkeleton = spine.get_skeleton()
	var state: SpineAnimationState = spine.get_animation_state()

	state.set_time_scale(1.0)
	state.clear_tracks()
	skeleton.set_to_setup_pose()
	var entry: SpineTrackEntry = state.set_animation(animation_name, false, 0)
	entry.set_mix_duration(0.0)
	state.update(time)
	state.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)


func _on_animation_completed(sprite: Object, _state: Object, entry: Object) -> void :
	if sprite != _active or entry.get_animation().get_name() != _active_exit_name:
		return
	_stop_active()


func _stop_sfx() -> void :
	if _sfx_id != &"":
		AudioManager.stop_sfx(_sfx_id)
		_sfx_id = &""


func _stop_active() -> void :
	if not is_instance_valid(_active):
		_active = null
		_active_exit_name = &""
		return
	_active.hide()
	_active.process_mode = Node.PROCESS_MODE_DISABLED
	var state: SpineAnimationState = _active.get_animation_state()
	state.set_time_scale(1.0)
	state.clear_tracks()
	_active.get_skeleton().set_to_setup_pose()
	_active = null
	_active_exit_name = &""


func _fail_preparation(reason: String) -> void :
	SortLogger.error("LongLinkFeedback: %s (variant=%d)" % [reason, _loading_variant])
	_failed_variants[_loading_variant] = true
	if is_instance_valid(_preparing_spine):
		_preparing_spine.queue_free()
	_preparing_spine = null
	_loaded_scene = null
	_loading_path = ""
	_loading_variant = -1
