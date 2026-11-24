class_name BonusPigSmash
extends Control



signal smashed(burst_center: Vector2)
const PRESENTATION_SCALE: float = 1.3 * 1.2
const DEFAULT_HAMMER_SCALE: float = 0.78 * 1.2
const BIG_PIG_SIZE: float = 420.0 * PRESENTATION_SCALE
const PIG_SOURCE_HOLD: float = 0.12
const PIG_FLY_DUR: float = PIG_SOURCE_HOLD + 0.54
const PIG_ANTICIPATION: float = 0.08
const PIG_FLY_ARC_HEIGHT: float = 240.0
const PIG_HOLD_DUR: float = 0.1
const CONTACT_TIME: float = 1.0667
const COIN_DELAY: float = 0.2
const HAMMER_DURATION: float = 1.3
const HAMMER_FADE_START: float = 0.1
const HAMMER_FADE_END: float = 0.28

const HAMMER_SWING_IMPACT_OFFSET: float = 0.81
const DUST_COUNT: int = 6
const TRAIL_COUNT: int = 4
@export var dust_texture: Texture2D
@export var big_pig_texture: Texture2D
@export var hammer_data: SpineSkeletonDataResource
@export var hammer_scale: float = DEFAULT_HAMMER_SCALE
@export var hit_offset: Vector2 = Vector2.ZERO
@onready var _dim: ColorRect = $Dim
@onready var _pig: TextureRect = $Pig
@onready var _hammer: SpineSprite = $Hammer
@onready var _ceramic: BonusPigShatterCeramic = $Ceramic
var _hammer_contact_local: Vector2 = Vector2.ZERO
var _tween: Tween = null
var _dim_tween: Tween = null
var _generation: int = 0
var _running: bool = false
var _hold_background: bool = false
var _fly_sound_played: bool = false
var _swing_sound_played: bool = false
var _contact: bool = false
var _shattered: bool = false
var _reward_emitted: bool = false
var _center: Vector2
var _from: Vector2
var _start_scale: float
var _track: SpineTrackEntry
var _impact_particles: Array[Dictionary] = []
var sampled_hammer_time: float = 0.0

func _ready() -> void :
	_pig.texture = big_pig_texture
	_pig.size = Vector2.ONE * BIG_PIG_SIZE
	_pig.pivot_offset = _pig.size * 0.5
	_hammer.set_skeleton_data_res(hammer_data.duplicate(true) as SpineSkeletonDataResource)
	_hammer.set_update_mode(SpineConstant.UpdateMode_Manual)
	_hammer.before_world_transforms_change.connect(_hide_hammer_impact)
	_build_impact_pool()
	hide_now()

func is_running() -> bool:
	return _running

func hit_global_position() -> Vector2:
	return _center + hit_offset * BIG_PIG_SIZE

func hide_now() -> void :
	AudioManager.stop_sfx(&"bonus_pig_fly")
	AudioManager.stop_sfx(&"bonus_pig_shatter")
	AudioManager.stop_sfx(&"bonus_hammer_swing")
	_fly_sound_played = false
	_swing_sound_played = false
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _dim_tween != null and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = null
	_running = false
	visible = false
	_contact = false
	_shattered = false
	_reward_emitted = false
	sampled_hammer_time = 0.0
	if not is_node_ready():
		return
	_dim.modulate.a = 0.0
	_pig.hide()
	_hammer.hide()
	_ceramic.reset()
	for particle: Dictionary in _impact_particles:
		(particle["node"] as Sprite2D).hide()
	if _hammer.get_animation_state() != null:
		_hammer.get_animation_state().clear_tracks()
	_track = null

func play(from_rect: Rect2, center: Vector2, hold_background: bool = false) -> void :
	hide_now()
	_hold_background = hold_background
	var generation: int = _generation
	_running = true

	if not _ceramic.is_prepared():
		await _ceramic.geometry_ready
	if generation != _generation or not is_inside_tree():
		return
	_center = center
	_from = from_rect.get_center()
	_start_scale = from_rect.size.x / BIG_PIG_SIZE
	visible = true
	_running = true
	_pig.show()
	_pig.modulate = Color.WHITE
	_pig.rotation = 0.0
	_pig.scale = Vector2.ONE * _start_scale
	_pig.global_position = _from - _pig.size * 0.5
	var sk: SpineSkeleton = _hammer.get_skeleton()
	sk.set_to_setup_pose()
	_track = _hammer.get_animation_state().set_animation("animation", false, 0)
	_track.set_track_time(CONTACT_TIME)
	_hammer.get_animation_state().apply(sk)
	sk.update_world_transform(SpineConstant.Physics_Update)
	var hit_bone: SpineBone = sk.find_bone("images/Impact_2")
	_hammer_contact_local = Vector2(hit_bone.get_world_x(), hit_bone.get_world_y())
	sk.set_to_setup_pose()
	_track.set_track_time(0.0)
	_hammer.get_animation_state().apply(sk)
	sk.update_world_transform(SpineConstant.Physics_Update)
	_hammer.scale = Vector2.ONE * hammer_scale
	_hammer.global_position = hit_global_position()
	_sample(0.0)
	var total: float = PIG_FLY_DUR + PIG_HOLD_DUR + CONTACT_TIME + _ceramic.fall_duration + 0.08
	_tween = create_tween()
	_tween.tween_method(_sample, 0.0, total, total)
	var tw: Tween = _tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation == _generation:
		if _hold_background:
			_running = false
			_tween = null
			_pig.hide()
			_hammer.hide()
			_ceramic.reset()
			for particle: Dictionary in _impact_particles:
				(particle["node"] as Sprite2D).hide()
			_dim.modulate.a = 0.55
		else:
			hide_now()

func _sample(age: float) -> void :
	if not _running:
		return
	if age >= PIG_SOURCE_HOLD and not _fly_sound_played:
		_fly_sound_played = true
		AudioManager.play_sfx(&"bonus_pig_fly")
	var center: Vector2
	var launch_age: float = maxf(age - PIG_SOURCE_HOLD, 0.0)
	if launch_age < PIG_ANTICIPATION:
		var anticipation: float = smoothstep(0.0, PIG_ANTICIPATION, launch_age)
		center = _from + Vector2(0.0, -12.0 * anticipation)
		_pig.scale = Vector2.ONE * _start_scale * lerpf(1.0, 1.04, anticipation)
	else:
		var u: float = clampf((launch_age - PIG_ANTICIPATION) / (PIG_FLY_DUR - PIG_SOURCE_HOLD - PIG_ANTICIPATION), 0.0, 1.0)
		var fly: float = BonusPigHud.flight_progress(u)
		var start: Vector2 = _from + Vector2(0, -12)
		var direction: Vector2 = _center - start
		var side: Vector2 = Vector2(direction.y, - direction.x).normalized()
		if side.x < 0.0:
			side = - side
		var c1: Vector2 = start + direction * 0.12 + side * PIG_FLY_ARC_HEIGHT
		var c2: Vector2 = _center - direction * 0.22 + side * PIG_FLY_ARC_HEIGHT * 0.7
		var inv: float = 1.0 - fly
		center = start * inv * inv * inv + c1 * 3 * inv * inv * fly + c2 * 3 * inv * fly * fly + _center * fly * fly * fly
		_pig.scale = Vector2.ONE * lerpf(_start_scale * 1.04, 1.0, smoothstep(0.08, 1.0, u))
	if age >= PIG_FLY_DUR and age < PIG_FLY_DUR + PIG_HOLD_DUR:
		var settle: float = sin((age - PIG_FLY_DUR) / PIG_HOLD_DUR * PI)
		_pig.scale = Vector2(1.0 + 0.035 * settle, 1.0 - 0.025 * settle)

	var drawn_rect: Rect2 = _pig.get_global_transform() * Rect2(Vector2.ZERO, _pig.size)
	_pig.global_position += center - drawn_rect.get_center()
	_dim.modulate.a = 0.55 * smoothstep(0.0, 0.42, age)
	var hammer_age: float = age - PIG_FLY_DUR - PIG_HOLD_DUR
	if hammer_age < 0.0:
		return

	if hammer_age >= CONTACT_TIME - HAMMER_SWING_IMPACT_OFFSET and not _swing_sound_played:
		_swing_sound_played = true
		AudioManager.play_sfx(&"bonus_hammer_swing")
	sampled_hammer_time = minf(hammer_age, HAMMER_DURATION)
	_hammer.show()
	_hammer.scale = Vector2.ONE * hammer_scale
	_hammer.global_position = hit_global_position() - _hammer_contact_local * _hammer.scale
	_track.set_track_time(sampled_hammer_time)
	var sk: SpineSkeleton = _hammer.get_skeleton()
	sk.set_to_setup_pose()
	_hammer.get_animation_state().apply(sk)
	sk.update_world_transform(SpineConstant.Physics_Update)
	_hammer.update_skeleton(0.0)
	_hammer.modulate.a = smoothstep(HAMMER_FADE_START, HAMMER_FADE_END, hammer_age) * (1.0 - smoothstep(HAMMER_DURATION - 0.06, HAMMER_DURATION + 0.08, hammer_age))
	if hammer_age >= CONTACT_TIME:
		if not _contact:
			_contact = true
			_start_impact()
		var hit_age: float = hammer_age - CONTACT_TIME
		if not _shattered:
			_shattered = true
			AudioManager.play_sfx(&"bonus_pig_shatter")
			_pig.hide()
			_ceramic.play(_center, BIG_PIG_SIZE)
		if _shattered:
			_ceramic.sample(hit_age)
		_sample_impact(hit_age)
		if hit_age >= COIN_DELAY and not _reward_emitted:
			_reward_emitted = true
			smashed.emit(_center)
		if not _hold_background:
			_dim.modulate.a *= 1.0 - smoothstep(0.1, _ceramic.fall_duration, hit_age)



func _build_impact_pool() -> void :
	for i: int in range(DUST_COUNT + TRAIL_COUNT):
		var sprite: = Sprite2D.new()
		var atlas: = AtlasTexture.new()
		atlas.atlas = dust_texture
		var cell: Vector2 = dust_texture.get_size() * 0.5
		atlas.region = Rect2(Vector2(i % 2, (i / 2) % 2) * cell, cell)
		sprite.texture = atlas
		sprite.z_index = 4
		add_child(sprite)
		sprite.hide()
		_impact_particles.append({"node": sprite, "dust": true, "trail": i >= DUST_COUNT, 
			"delay": 0.0, "life": 0.5, "origin": Vector2.ZERO, "velocity": Vector2.ZERO, 
			"scale": 0.1, "alpha": 1.0, "spin": 0.0, "rotation": 0.0})

func _start_impact() -> void :
	for i: int in range(_impact_particles.size()):
		var p: Dictionary = _impact_particles[i]
		var sprite: Sprite2D = p["node"]
		var trail: bool = p["trail"]
		p["delay"] = 0.16 if trail else 0.0
		p["life"] = randf_range(0.5, 0.58)
		p["alpha"] = 0.25 if trail else randf_range(0.38, 0.52)
		p["scale"] = randf_range(240.0, 310.0) / 256.0

		var angle: float = - PI + 0.15 + float(i % DUST_COUNT) / float(DUST_COUNT - 1) * (PI - 0.3)
		angle += randf_range(-0.1, 0.1)
		var direction: = Vector2(cos(angle), sin(angle))
		var radius: float = randf_range(95.0, 155.0)
		p["origin"] = _center + direction * radius
		p["velocity"] = direction * randf_range(160.0, 240.0)
		p["spin"] = randf_range(-0.8, 0.8)
		p["scale"] = float(p["scale"]) * PRESENTATION_SCALE
		p["origin"] = _center + (p["origin"] - _center) * PRESENTATION_SCALE
		p["velocity"] = p["velocity"] * PRESENTATION_SCALE
		p["rotation"] = randf_range(0.0, TAU)
		sprite.hide()

func _sample_impact(age: float) -> void :
	for i: int in range(_impact_particles.size()):
		var p: Dictionary = _impact_particles[i]
		var sprite: Sprite2D = p["node"]
		var t: float = age - float(p["delay"])
		var life: float = p["life"]
		if t < 0.0 or t >= life:
			sprite.hide()
			continue
		var u: float = t / life
		var origin: Vector2 = p["origin"]
		if bool(p["trail"]):

			var shard_index: int = [1, 3, 10, 14][i - DUST_COUNT]
			origin = _ceramic.shard_world_position(shard_index, float(p["delay"]))
		var velocity: Vector2 = p["velocity"]
		sprite.global_position = origin + velocity * t
		sprite.rotation = float(p["rotation"]) + float(p["spin"]) * t
		var size_factor: float = lerpf(1.0, 1.6, u)
		sprite.scale = Vector2.ONE * float(p["scale"]) * size_factor
		var fade: float = smoothstep(0.0, 0.045, t) * (1.0 - smoothstep(0.12, 1.0, u))
		sprite.modulate = Color(0.88, 0.82, 0.72, float(p["alpha"]) * fade)
		sprite.show()


func held_background_opacity() -> float:
	return 0.55 if visible and _hold_background and not _running else 0.0





func fade_out_held_background(duration: float) -> void :
	if not _hold_background or _running:
		return
	_hold_background = false
	if _dim_tween != null and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = create_tween()
	_dim_tween.tween_property(_dim, "modulate:a", 0.0, maxf(duration, 0.0))


func _exit_tree() -> void :
	AudioManager.stop_sfx(&"bonus_pig_fly")
	AudioManager.stop_sfx(&"bonus_pig_shatter")
	AudioManager.stop_sfx(&"bonus_hammer_swing")


func _hide_hammer_impact(sprite: SpineSprite) -> void :
	var slot: SpineSlot = sprite.get_skeleton().find_slot("images-Impact_0")
	if slot != null:
		slot.set_attachment(null)
