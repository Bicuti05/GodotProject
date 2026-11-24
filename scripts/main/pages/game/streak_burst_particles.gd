class_name StreakBurstParticles
extends Node2D

const PRIMARY_COUNT: int = 15
const TRAIL_COUNT: int = 8
const PRIMARY_SIZE_MULTIPLIER: float = 0.8
const LIFETIME_RANDOMNESS: float = 0.35
const PRIMARY_RANGE_MULTIPLIER: float = 1.2
const TRAIL_RANGE_MULTIPLIER: float = 1.2 * 1.25
const TRAIL_GRAVITY: float = 220.0 * 0.7 * 0.7 * 0.5
const TRAIL_SPREAD: float = PI * 1.5
const BASE_SIZE: float = 22.0 * 0.8 * 0.75
const PRIMARY_SIZE_MAX: float = 1.5 * 1.6
const TRAIL_SIZE_MULTIPLIER: float = 2.0 * 1.25
const LIFETIME_RATIO: float = 0.65
const RANGE_RATIO: float = 0.7 * 0.75
const LIFETIME: float = 2.6 * LIFETIME_RATIO * 0.7
const PRIMARY_LIFETIME: float = LIFETIME * 0.8
const FADE_DURATION: float = 0.35 * LIFETIME_RATIO * 0.7
const BASE_SPEED: float = 1450.0 * RANGE_RATIO / LIFETIME_RATIO
const RESIDUAL_SPEED: float = 18.0 * RANGE_RATIO / LIFETIME_RATIO
const DECAY_RATE: float = 3.6 / LIFETIME_RATIO
const PARTICLE_COLOR: = Color("A135FF")
const TRAIL_WIDTH_RATIO: float = 0.25 * 1.3
const TRAIL_ALPHA: float = 0.75
const TRAIL_FADE_MULTIPLIER: float = 1.4 * 2.0
const TRAIL_LIFETIME: float = 0.24 * LIFETIME_RATIO * 0.7 * TRAIL_FADE_MULTIPLIER

class ParticleState extends RefCounted:
	var sprite: Sprite2D
	var direction: Vector2
	var start_position: Vector2
	var start_speed: float
	var residual_speed: float
	var rotation: float
	var spin: float
	var diameter: float
	var lifetime: float
	var gravity: float
	var tint: Color
	var ribbon: FireworkTrails.Ribbon

@onready var _trails: FireworkTrails = $Trails
@onready var _sprites: Node2D = $Sprites

var _states: Array[ParticleState] = []
var _random: = RandomNumberGenerator.new()
var _playing: bool = false


func _ready() -> void :
	_random.randomize()
	for sprite: Sprite2D in _sprites.get_children():
		var state: = ParticleState.new()
		state.sprite = sprite
		_states.append(state)
	_trails.prepare_pool(TRAIL_COUNT)
	reset()


func play(random_seed: int = -1) -> void :
	reset()
	if random_seed >= 0:
		_random.seed = random_seed
	for index: int in _states.size():
		var state: ParticleState = _states[index]
		var has_trail: bool = index >= PRIMARY_COUNT
		var group_count: int = TRAIL_COUNT if has_trail else PRIMARY_COUNT
		var group_index: int = index - PRIMARY_COUNT if has_trail else index
		var angle_step: float = (TRAIL_SPREAD if has_trail else TAU) / float(group_count)
		var angle: float = angle_step * float(group_index) + _random.randf_range(-0.5, 0.5) * angle_step
		if has_trail:
			angle += - PI * 0.5 - TRAIL_SPREAD * 0.5 + angle_step * 0.5
		var speed_factor: float = _random.randf_range(0.5, 1.5)
		var range_multiplier: float = TRAIL_RANGE_MULTIPLIER if has_trail else PRIMARY_RANGE_MULTIPLIER
		state.direction = Vector2.from_angle(angle)
		state.start_position = state.direction * _random.randf_range(110.0, 190.0) * RANGE_RATIO * range_multiplier
		state.start_speed = BASE_SPEED * speed_factor * range_multiplier
		state.residual_speed = RESIDUAL_SPEED * speed_factor * range_multiplier
		state.diameter = BASE_SIZE * _random.randf_range(0.5, 1.5) * TRAIL_SIZE_MULTIPLIER if has_trail\
		else BASE_SIZE * _random.randf_range(0.5, PRIMARY_SIZE_MAX) * PRIMARY_SIZE_MULTIPLIER
		state.lifetime = (LIFETIME if has_trail else PRIMARY_LIFETIME)\
		* _random.randf_range(1.0 - LIFETIME_RANDOMNESS, 1.0 + LIFETIME_RANDOMNESS)
		state.gravity = TRAIL_GRAVITY if has_trail else 0.0
		state.tint = Color.WHITE.lerp(PARTICLE_COLOR, _random.randf())
		state.ribbon = null
		state.rotation = _random.randf_range( - PI * 0.5, PI * 0.5)
		state.spin = deg_to_rad(20.0) * _random.randf_range(-1.5, 1.5)
		state.sprite.position = state.start_position
		state.sprite.scale = Vector2.ONE * state.diameter / float(state.sprite.texture.get_width())
		state.sprite.modulate = state.tint
		state.sprite.show()
		if has_trail:
			state.ribbon = _trails.add_ribbon(state.sprite, state.diameter * TRAIL_WIDTH_RATIO, 
				state.tint, TRAIL_ALPHA, TRAIL_LIFETIME)
	_playing = true
	show()
	_trails.set_process(true)
	sample(0.0)


func sample(elapsed: float) -> void :
	if not _playing:
		return
	var time: float = maxf(elapsed, 0.0)
	modulate.a = 1.0
	var alive: bool = false
	var decay_distance: float = (1.0 - exp( - DECAY_RATE * time)) / DECAY_RATE
	for state: ParticleState in _states:
		var fade_duration: float = FADE_DURATION * state.lifetime / LIFETIME
		if state.ribbon != null:
			var trail_end: float = state.lifetime + fade_duration * (TRAIL_FADE_MULTIPLIER - 1.0)
			state.ribbon.head_alpha = TRAIL_ALPHA * (1.0 - smoothstep(
				state.lifetime - fade_duration, trail_end, time))
			if time < trail_end:
				alive = true
		if time >= state.lifetime:
			state.sprite.hide()
			if state.ribbon != null:
				state.ribbon.detach()
			continue
		alive = true
		var alpha: float = 1.0 - smoothstep(state.lifetime - fade_duration, state.lifetime, time)
		state.sprite.modulate.a = alpha
		var distance: float = state.residual_speed * time\
		+ (state.start_speed - state.residual_speed) * decay_distance
		state.sprite.position = state.start_position + state.direction * distance\
		+ Vector2(0.0, 0.5 * state.gravity * time * time)
		state.sprite.rotation = state.rotation + state.spin * time
	if not alive:
		reset()


func reset() -> void :
	_playing = false
	hide()
	modulate = Color.WHITE
	_trails.set_process(false)
	_trails.clear_all()
	for state: ParticleState in _states:
		state.ribbon = null
		state.sprite.hide()
		state.sprite.position = Vector2.ZERO
		state.sprite.rotation = 0.0
		state.sprite.scale = Vector2.ONE
