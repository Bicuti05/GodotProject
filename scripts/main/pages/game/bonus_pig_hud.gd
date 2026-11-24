class_name BonusPigHud
extends Control


const DOCK_SIZE: float = 96.0
const DOCK_GAP_TO_LABEL: float = 12.0
const LIFT_DURATION: float = 0.25
const SHOW_DURATION: float = 0.45
const FLY_DUR: float = 0.58
const ANTICIPATION_DUR: float = 0.1
const FLY_BEND_MIN: float = 150.0
const FLY_BEND_MAX: float = 260.0
const LIFT_SCALE: float = 1.2
const ARRIVAL_DURATION: float = 0.36
const ARRIVAL_PUNCH_DURATION: float = 0.22
const ARRIVAL_SCALE: float = 1.08
const FLIGHT_START: float = LIFT_DURATION + SHOW_DURATION
const ARRIVAL_START: float = FLIGHT_START + FLY_DUR
@export var pig_texture: Texture2D
@export var spiral_scene: PackedScene
@onready var _pig: TextureRect = $Pig
@onready var _trail_anchor: Node2D = $TrailAnchor
@onready var _trail_dust: CPUParticles2D = $TrailDust
@onready var _arrival_dust: CPUParticles2D = $ArrivalDust
@onready var _arrival_stars: CPUParticles2D = $ArrivalStars
var _flight_trails: FireworkTrails
var _flight_ribbon: FireworkTrails.Ribbon = null
var _arrival_started: bool = false
var _last_trail_age: float = -1.0
var _source: JuiceBlender = null
var _source_pool: JuiceNodePool = null
var _body: Sprite2D
var _spiral: SpiralLightFx
var _flight_host: Node2D
var _docked: bool = false
var _flight_active: bool = false
var _fly_tween: Tween = null
var _punch_tween: Tween = null
var _generation: int = 0
var _dock_position: Vector2
var _from_rect: Rect2
var _lift_center: Vector2
var _promoted: bool = false
var _spiral_started: bool = false
var _last_age: float = 0.0

func _ready() -> void :
	_pig.texture = pig_texture
	_pig.size = Vector2.ONE * DOCK_SIZE
	_pig.pivot_offset = _pig.size * 0.5
	_flight_host = Node2D.new()
	add_child(_flight_host)
	_spiral = spiral_scene.instantiate() as SpiralLightFx
	_spiral.dust_texture = _trail_dust.texture
	_flight_host.add_child(_spiral)
	_flight_trails = FireworkTrails.new()
	_flight_trails.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(_flight_trails)

	move_child(_arrival_stars, 0)
	move_child(_arrival_dust, 0)
	move_child(_flight_trails, 0)
	_flight_trails.prepare_pool(1)
	hide_now()

func is_docked() -> bool:
	return _docked

func is_flying() -> bool:
	return _flight_active

func dock_global_rect() -> Rect2:
	return _body.global_transform * _body.get_rect() if is_instance_valid(_source) else _pig.get_global_rect()

func place_left_of_label(label_global_rect: Rect2, text_width: float) -> void :
	_dock_position = Vector2(label_global_rect.get_center().x - text_width * 0.5 - DOCK_GAP_TO_LABEL - DOCK_SIZE, 
		label_global_rect.get_center().y - DOCK_SIZE * 0.5)
	if not is_flying():
		_place_body(_dock_position + Vector2.ONE * DOCK_SIZE * 0.5, Vector2.ONE * DOCK_SIZE)

func hide_now() -> void :
	_generation += 1
	if _fly_tween != null and _fly_tween.is_valid():
		_fly_tween.kill()
	_fly_tween = null
	_flight_active = false
	_docked = false
	if _spiral != null:
		_spiral.stop()
		_spiral.modulate = Color.WHITE
	if _flight_trails != null:
		_flight_trails.clear_all()
		_flight_trails.set_process(false)
	_flight_ribbon = null
	_arrival_started = false
	_last_trail_age = -1.0
	for particles: CPUParticles2D in [_trail_dust, _arrival_dust, _arrival_stars]:
		if is_instance_valid(particles):
			particles.emitting = false
			particles.amount = particles.amount
	if is_instance_valid(_source):
		if is_instance_valid(_source_pool):
			_source_pool.release(_source)
		else:
			_source.queue_free()
	_source = null
	_source_pool = null
	_body = null
	if _pig != null:
		_pig.hide()
		_pig.scale = Vector2.ONE

func dock_instantly() -> void :
	hide_now()
	_docked = true
	_pig.texture = pig_texture
	_pig.global_position = _dock_position
	_pig.show()

func fly_in_from(from_rect: Rect2, source_visual: Dictionary = {}) -> void :
	hide_now()
	_from_rect = from_rect
	_promoted = false
	_spiral_started = false
	_last_age = 0.0
	_source = source_visual.get("node") as JuiceBlender
	_source_pool = source_visual.get("pool") as JuiceNodePool
	if is_instance_valid(_source):
		_body = _source.get_node("Body") as Sprite2D
		var lift_layer: Node2D = source_visual.get("lift_layer") as Node2D
		if is_instance_valid(lift_layer):

			_source.reparent(lift_layer, true)
		_source.show()
	else:

		_pig.texture = pig_texture
		_pig.scale = from_rect.size / DOCK_SIZE
		_pig.global_position = from_rect.get_center() - _pig.size * 0.5
		_pig.global_position += from_rect.get_center() - _pig.get_global_rect().get_center()
		_pig.show()
	var plank_top: float = float(source_visual.get("plank_top", from_rect.end.y))
	var lift: float = maxf(from_rect.size.y * 0.45, from_rect.get_center().y + from_rect.size.y * LIFT_SCALE * 0.5 - plank_top + 18.0)
	_lift_center = from_rect.get_center() - Vector2(0.0, lift)
	_flight_active = true
	var generation: int = _generation
	_sample_flight(0.0)
	_fly_tween = create_tween()
	_fly_tween.tween_method(_sample_flight, 0.0, ARRIVAL_START + ARRIVAL_DURATION, 
		ARRIVAL_START + ARRIVAL_DURATION)
	_fly_tween.tween_callback( func() -> void :
		if generation != _generation:
			return
		_docked = true
		_flight_active = false)

func _sample_flight(age: float) -> void :
	var center: Vector2
	var dimensions: Vector2
	if age < LIFT_DURATION:
		var u: float = 1.0 - pow(1.0 - clampf(age / LIFT_DURATION, 0.0, 1.0), 3.0)
		center = _from_rect.get_center().lerp(_lift_center, u)
		dimensions = _from_rect.size * lerpf(1.0, LIFT_SCALE, u)
	else:
		if not _promoted:

			if is_instance_valid(_source):
				_source.reparent(_flight_host, true)
				_source.z_index = 0
			_promoted = true
		var show_age: float = age - LIFT_DURATION
		if show_age < SHOW_DURATION:
			var anticipation: float = smoothstep(SHOW_DURATION - ANTICIPATION_DUR, SHOW_DURATION, show_age)
			center = _lift_center + Vector2(0.0, -4.0 * sin(show_age / SHOW_DURATION * PI * 0.5) + 8.0 * anticipation)
			dimensions = _from_rect.size * lerpf(LIFT_SCALE, 1.16, anticipation)
		else:
			var u: float = clampf((show_age - SHOW_DURATION) / FLY_DUR, 0.0, 1.0)
			var t: float = flight_progress(u)
			var start: Vector2 = _lift_center + Vector2(0.0, 4.0)
			var dst: Vector2 = _dock_position + Vector2.ONE * DOCK_SIZE * 0.5
			center = sample_flight_arc(start, dst, t)

			var shrink: float = smoothstep(0.1, 0.96, u)
			dimensions = (_from_rect.size * 1.16).lerp(Vector2.ONE * DOCK_SIZE, shrink)
	if age >= ARRIVAL_START:
		var arrival_age: float = age - ARRIVAL_START
		var punch: float = sin(clampf(arrival_age / ARRIVAL_PUNCH_DURATION, 0.0, 1.0) * PI)
		dimensions = Vector2.ONE * DOCK_SIZE * (1.0 + (ARRIVAL_SCALE - 1.0) * punch)
	_place_body(center, dimensions)
	_sample_flight_feedback(age, center)
	if age >= LIFT_DURATION and age < FLIGHT_START and not _spiral_started:
		_spiral_started = true
		var cfg: SpiralLightFx.Cfg = SpiralLightFx.pot_cfg(_from_rect.size * LIFT_SCALE)
		cfg.climb_start = 0.0
		cfg.climb_end = SHOW_DURATION
		cfg.dust_start = 0.0
		cfg.dust_size = 28.0
		cfg.beam_dur = FLY_DUR
		cfg.fade_at_top = true
		cfg.top_fade_duration = 0.17
		cfg.front_z = 1
		_spiral.start(_flight_host.to_local(center), cfg, func() -> Vector2:
			return _flight_host.to_local(_dock_position + Vector2.ONE * DOCK_SIZE * 0.5))
		_spiral.set_process(false)
	if _spiral_started and _spiral.is_running():

		if age < FLIGHT_START:
			_spiral.follow(_flight_host.to_local(center))
		_spiral._advance(maxf(age - maxf(_last_age, LIFT_DURATION), 0.0))
	_last_age = age

static func flight_progress(u: float) -> float:
	var t: float = clampf(u, 0.0, 1.0)

	return t * t * t * (10.0 + t * (-15.0 + 6.0 * t))

static func sample_flight_arc(start: Vector2, dst: Vector2, progress: float) -> Vector2:
	var direction: Vector2 = dst - start
	var side: Vector2 = Vector2( - direction.y, direction.x).normalized()

	if side.x < 0.0:
		side = - side
	var bend: float = clampf(direction.length() * 0.38, FLY_BEND_MIN, FLY_BEND_MAX)
	var c1: Vector2 = start + direction * 0.12 + side * bend
	var c2: Vector2 = dst - direction * 0.28 + side * bend * 0.72
	var t: float = clampf(progress, 0.0, 1.0)
	var inv: float = 1.0 - t
	return start * inv * inv * inv + c1 * 3.0 * inv * inv * t + c2 * 3.0 * inv * t * t + dst * t * t * t


func _sample_flight_feedback(age: float, center: Vector2) -> void :
	_trail_anchor.global_position = center
	_trail_dust.global_position = center
	if age >= FLIGHT_START and age < ARRIVAL_START:
		if _flight_ribbon == null:

			_flight_ribbon = _flight_trails.add_ribbon(_trail_anchor, 11.0, SpiralLightFx.GOLD, 0.48, 0.2)
			_trail_dust.emitting = true

		if _last_trail_age < 0.0 or age - _last_trail_age >= 1.0 / 60.0:
			_flight_trails._process(0.0)
			_last_trail_age = age
	elif age >= ARRIVAL_START and not _arrival_started:
		_arrival_started = true
		_spiral.stop()
		_trail_dust.emitting = false
		if _flight_ribbon != null:
			_flight_trails._process(0.0)
			_flight_ribbon.detach()
			_flight_trails.set_process(true)
		for particles: CPUParticles2D in [_arrival_dust, _arrival_stars]:
			particles.global_position = center
			particles.restart()
			particles.emitting = true


func _place_body(center: Vector2, dimensions: Vector2) -> void :
	if is_instance_valid(_source):
		var actual: Rect2 = _body.global_transform * _body.get_rect()
		var ratio: Vector2 = dimensions / actual.size

		var transform: Transform2D = _source.global_transform
		transform.x *= ratio.x
		transform.y *= ratio.y
		_source.global_transform = transform
		_source.global_position += center - (_body.global_transform * _body.get_rect()).get_center()
	else:
		_pig.scale = dimensions / DOCK_SIZE
		_pig.global_position += center - _pig.get_global_rect().get_center()

func _exit_tree() -> void :
	hide_now()
