class_name BonusSpineCoin
extends Control



const REFERENCE_WIDTH: float = 600.9786
@onready var spine: SpineSprite = $Spine
var playback_speed: float = 1.0
var _time: float = 0.0
var _duration: float = 1.0
var _track: SpineTrackEntry
var _animating: bool = false
var _landing: bool = false
var _landing_start: float = 0.0
var _landing_end: float = 0.0
var _pose_bounds: Rect2

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	spine.set_update_mode(SpineConstant.UpdateMode_Manual)
	resized.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()
	reset()

func _layout() -> void :
	if spine == null:
		return
	spine.position = size * 0.5
	spine.scale = Vector2.ONE * size.x / REFERENCE_WIDTH
	if _pose_bounds.has_area():
		spine.position -= _pose_bounds.get_center() * spine.scale

func start_rotation(phase: float = 0.0, speed: float = 1.0) -> void :
	reset()
	playback_speed = maxf(speed, 0.01)
	_layout()
	var skeleton: SpineSkeleton = spine.get_skeleton()
	skeleton.set_to_setup_pose()
	_track = spine.get_animation_state().set_animation("animation", true, 0)
	_duration = maxf(_track.get_animation().get_duration(), 0.01)
	_time = fposmod(phase, 1.0) * _duration
	_sample_pose()
	_animating = true
	show()
	set_process(true)

func reset() -> void :
	_animating = false
	_landing = false
	set_process(false)
	hide()
	if spine != null and spine.get_animation_state() != null:
		spine.get_animation_state().clear_tracks()
	_track = null

func _on_visibility_changed() -> void :
	if not visible:
		_animating = false
		set_process(false)
		if spine != null and spine.get_animation_state() != null:
			spine.get_animation_state().clear_tracks()
		_track = null

func _process(delta: float) -> void :
	if not _animating or _landing or not is_visible_in_tree():
		return
	_time += delta * playback_speed
	_sample_pose()

func _sample_pose() -> void :
	_track.set_track_time(_time)
	var skeleton: SpineSkeleton = spine.get_skeleton()
	skeleton.set_to_setup_pose()
	spine.get_animation_state().apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	spine.update_skeleton(0.0)
	_pose_bounds = skeleton.get_bounds()

	spine.position = size * 0.5 - _pose_bounds.get_center() * spine.scale



func settle_rotation(weight: float) -> void :
	if not _landing:
		_landing = true
		_landing_start = _time
		_landing_end = ceilf(_time / _duration) * _duration
	_time = lerpf(_landing_start, _landing_end, smoothstep(0.0, 1.0, weight))
	_sample_pose()


func fit_destination(rect: Rect2, weight: float) -> void :
	var actual: Vector2 = _pose_bounds.size * spine.scale
	if actual.x <= 0.0 or actual.y <= 0.0:
		return
	var final_scale: Vector2 = rect.size / actual
	scale = Vector2.ONE.lerp(final_scale, smoothstep(0.0, 1.0, weight))

func visual_global_rect() -> Rect2:
	return spine.global_transform * _pose_bounds


func place_visual_center(center: Vector2) -> void :
	global_position += center - visual_global_rect().get_center()
