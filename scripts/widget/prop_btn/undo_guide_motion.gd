extends Node2D



const CYCLE_DURATION: float = 2.0
const ACTIVE_DURATION: float = 1.45
const QUIET_DURATION: float = CYCLE_DURATION - ACTIVE_DURATION
const FADE_DURATION: float = 0.12
const RING_SIZE: Vector2 = Vector2(268.0, 268.0)
const ICON_GROW_END: float = 0.2
const ICON_LEFT_PEAK_TIME: float = 0.28
const ICON_RIGHT_PEAK_TIME: float = 0.44
const ICON_RETURN_START: float = 0.48
const LAND_TIME: float = 0.62

const ICON_MAX_SCALE: float = 1.85
const ICON_SHAKE_ANGLE: float = 13.0
const RING_DELAY: float = 0.18
const RING_DURATION: float = 0.65
const RING_FADE_IN: float = 0.045
const RING_PEAK_AGE: float = 0.12
const RING_ALPHA_GAIN: float = 1.5
const SECOND_RING_STRENGTH: float = 0.65
const RING_START_SCALE: float = 0.9

const RING_SCALE_TRAVEL: float = 0.6
const PARTICLE_STARTS: Array[float] = [0.62, 0.67, 0.65, 0.62, 0.74, 0.66, 0.7, 0.78]
const PARTICLE_ENDS: Array[float] = [1.18, 1.3, 1.24, 1.16, 1.38, 1.26, 1.34, 1.42]

@export var body_icon: TextureRect = null

@onready var _ring: Sprite2D = $Ring
@onready var _second_ring: Sprite2D = $SecondRing
@onready var _particles: Array[Sprite2D] = [
	$ParticleLarge1, $ParticleLarge2, $ParticleLarge3, 
	$ParticleSmall1, $ParticleSmall2, $ParticleSmall3, $ParticleSmall4, $ParticleSmall5, 
]

var _ring_base_scale: Vector2 = Vector2.ONE
var _badge_rects: Array[Rect2] = []
var _playing: bool = false
var _loop: bool = true
var _elapsed: float = 0.0
var _stopping: bool = false
var _fade_elapsed: float = 0.0
var _icon_owned: bool = false
var _icon_base_scale: Vector2 = Vector2.ONE
var _icon_base_rotation: float = 0.0
var _icon_base_pivot: Vector2 = Vector2.ZERO
var _icon_motion_pivot: Vector2 = Vector2.ZERO
var _icon_last_scale: Vector2 = Vector2.ONE
var _icon_last_rotation: float = 0.0
var _fade_icon_scale: Vector2 = Vector2.ONE
var _fade_icon_rotation: float = 0.0


func _ready() -> void :
	_ring_base_scale = RING_SIZE / _ring.texture.get_size()
	visibility_changed.connect(_on_visibility_changed)
	_reset()



func play(loop: bool = true) -> bool:
	if not is_node_ready() or not is_visible_in_tree() or not is_instance_valid(body_icon):
		return false
	if _playing and not _stopping and _loop and loop:
		return true
	_reset()

	_icon_base_scale = body_icon.scale
	_icon_base_rotation = body_icon.rotation
	_icon_base_pivot = body_icon.pivot_offset
	_icon_motion_pivot = body_icon.size * 0.5
	_icon_last_scale = _icon_base_scale
	_icon_last_rotation = _icon_base_rotation
	body_icon.pivot_offset = _icon_motion_pivot
	_icon_owned = true
	_loop = loop
	_playing = true
	_apply_frame(0.0)
	set_process(true)
	return true


func stop(immediate: bool = false) -> void :
	if immediate or not _playing:
		_reset()
		return
	if _stopping:
		return
	_stopping = true
	_fade_elapsed = 0.0
	_fade_icon_scale = _icon_last_scale
	_fade_icon_rotation = _icon_last_rotation



func is_playing() -> bool:
	return _playing



func set_badge_obstacles(rects: Array[Rect2]) -> void :
	_badge_rects.assign(rects)
	if _playing:
		_apply_particle_visibility()


func _process(delta: float) -> void :
	if _stopping:
		_fade_elapsed += delta
		var progress: float = clampf(_fade_elapsed / FADE_DURATION, 0.0, 1.0)
		modulate.a = 1.0 - progress
		var eased: float = _sine_ease(progress)
		_write_icon_transform(
			_fade_icon_scale.lerp(_icon_base_scale, eased), 
			lerpf(_fade_icon_rotation, _icon_base_rotation, eased)
		)
		if _fade_elapsed >= FADE_DURATION:
			_reset()
		return
	_elapsed += delta
	if _elapsed >= CYCLE_DURATION:
		if not _loop:
			_reset()
			return
		_elapsed = fmod(_elapsed, CYCLE_DURATION)
	_apply_frame(_elapsed)


func _apply_frame(time: float) -> void :
	_apply_icon_frame(time)

	_apply_ring_frame(_ring, time - LAND_TIME, RING_ALPHA_GAIN)
	_apply_ring_frame(_second_ring, time - LAND_TIME - RING_DELAY, 
		RING_ALPHA_GAIN * SECOND_RING_STRENGTH)
	for index: int in range(_particles.size()):
		var start: float = PARTICLE_STARTS[index]
		var peak: float = start + 0.16
		var end: float = PARTICLE_ENDS[index]
		var alpha: float = 0.0
		if time >= start and time < peak:
			alpha = smoothstep(start, peak, time)
		elif time >= peak and time < end:
			alpha = 1.0 - smoothstep(peak, end, time)
		_particles[index].modulate.a = alpha
	_apply_particle_visibility()


func _apply_ring_frame(ring: Sprite2D, age: float, gain: float) -> void :
	var progress: float = clampf(age / RING_DURATION, 0.0, 1.0)
	ring.scale = _ring_base_scale * (RING_START_SCALE + RING_SCALE_TRAVEL * progress)
	var alpha: float = 0.0
	if age >= 0.0 and age < RING_FADE_IN:
		alpha = smoothstep(0.0, RING_FADE_IN, age)
	elif age >= RING_FADE_IN and age < RING_PEAK_AGE:
		alpha = 1.0
	elif age >= RING_PEAK_AGE and age < RING_DURATION:
		alpha = 1.0 - smoothstep(RING_PEAK_AGE, RING_DURATION, age)

	ring.modulate.a = alpha * gain
	ring.visible = alpha > 0.0


func _apply_icon_frame(time: float) -> void :

	var scale_factor: float = _icon_scale_factor(time)
	var angle: float = _icon_rotation_offset(time)
	_write_icon_transform(_icon_base_scale * scale_factor, _icon_base_rotation + deg_to_rad(angle))


func _icon_scale_factor(time: float) -> float:
	if time < ICON_GROW_END:
		return lerpf(1.0, ICON_MAX_SCALE, smoothstep(0.0, ICON_GROW_END, time))
	if time < ICON_RETURN_START:
		return ICON_MAX_SCALE
	return lerpf(ICON_MAX_SCALE, 1.0, smoothstep(ICON_RETURN_START, LAND_TIME, time))


func _icon_rotation_offset(time: float) -> float:
	if time < ICON_GROW_END:
		return 0.0
	if time < ICON_LEFT_PEAK_TIME:
		return lerpf(0.0, - ICON_SHAKE_ANGLE, smoothstep(ICON_GROW_END, ICON_LEFT_PEAK_TIME, time))
	if time < ICON_RIGHT_PEAK_TIME:
		return lerpf( - ICON_SHAKE_ANGLE, ICON_SHAKE_ANGLE, 
			smoothstep(ICON_LEFT_PEAK_TIME, ICON_RIGHT_PEAK_TIME, time))
	return lerpf(ICON_SHAKE_ANGLE, 0.0, smoothstep(ICON_RIGHT_PEAK_TIME, LAND_TIME, time))


func _sine_ease(progress: float) -> float:
	return 0.5 - 0.5 * cos(PI * progress)


func _owns_icon_transform() -> bool:
	return _icon_owned and is_instance_valid(body_icon)\
	and body_icon.scale.is_equal_approx(_icon_last_scale)\
	and is_equal_approx(body_icon.rotation, _icon_last_rotation)\
	and body_icon.pivot_offset.is_equal_approx(_icon_motion_pivot)


func _write_icon_transform(value_scale: Vector2, value_rotation: float) -> void :
	if not _owns_icon_transform():

		_icon_owned = false
		return
	body_icon.scale = value_scale
	body_icon.rotation = value_rotation
	_icon_last_scale = value_scale
	_icon_last_rotation = value_rotation


func _restore_icon() -> void :
	var restore: bool = _owns_icon_transform()
	_icon_owned = false
	if restore:
		body_icon.scale = _icon_base_scale
		body_icon.rotation = _icon_base_rotation
		body_icon.pivot_offset = _icon_base_pivot


func _apply_particle_visibility() -> void :
	for particle: Sprite2D in _particles:
		var particle_size: Vector2 = particle.texture.get_size() * particle.scale
		var particle_rect: Rect2 = Rect2(particle.position - particle_size * 0.5, particle_size)
		var overlaps_badge: bool = false
		for badge_rect: Rect2 in _badge_rects:
			if particle_rect.intersects(badge_rect):
				overlaps_badge = true
				break
		particle.visible = particle.modulate.a > 0.0 and not overlaps_badge


func _reset() -> void :
	_playing = false
	_loop = true
	_stopping = false
	_elapsed = 0.0
	_fade_elapsed = 0.0

	_restore_icon()
	modulate.a = 1.0
	set_process(false)
	if _ring != null:
		_ring.visible = false
		_ring.modulate.a = 0.0
		_ring.scale = _ring_base_scale
	if _second_ring != null:
		_second_ring.visible = false
		_second_ring.modulate.a = 0.0
		_second_ring.scale = _ring_base_scale
	for particle: Sprite2D in _particles:
		particle.visible = false
		particle.modulate.a = 0.0


func _on_visibility_changed() -> void :
	if not is_visible_in_tree():
		stop(true)


func _exit_tree() -> void :
	stop(true)
