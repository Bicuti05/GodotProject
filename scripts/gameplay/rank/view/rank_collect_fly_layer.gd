class_name RankCollectFlyLayer
extends Node2D


signal item_arrived(index: int)

const MAX_FLY_ITEMS: int = 8

const EXPLODE_RADIUS: float = 100.0
const EXPLODE_SEC: float = 0.3

enum ExplodeShape{
	RADIAL, 
	HORIZONTAL, 
}

const EXPLODE_RADIUS_RANDOM: float = 0.1
const EXPLODE_ANGLE_RANDOM_DEG: float = 15.0

const EXPLODE_SPACING_RATIO: float = 1.2
const EXPLODE_X_JITTER: float = 0.18
const EXPLODE_Y_SPREAD: float = 0.25

const FLY_DELAY: float = 0.1
const FLY_INTERVAL_DELAY: float = 0.1

const FLY_SEC: float = 0.6
const CURVE_OFFSET_X: Vector2 = Vector2(-80.0, 80.0)
const CURVE_OFFSET_Y: Vector2 = Vector2(20.0, 120.0)
const FADE_BEFORE_END: float = 0.2

const ITEM_SIZE: float = 80.0
const ITEM_SCALE_MIN: float = 0.8
const ITEM_SCALE_MAX: float = 1.2
const SCREEN_MARGIN: float = 8.0

const PARTICLE_TEX: Texture2D = preload("res://assets/sprites/common_rank_collect_dot.png")
const BURST_SHINE_TEX: Texture2D = PARTICLE_TEX
const BURST_SHINE_SEC: float = 0.4
const BURST_SHINE_PX: float = 280.0
const BURST_SHINE_PX_ARRIVE: float = 180.0
const BURST_STAR_BASE: int = 8
const BURST_STAR_PER_ITEM: int = 1
const BURST_STAR_AMOUNT_MAX: int = 12
const BURST_STAR_LIFETIME: float = 0.55
const ARRIVE_STAR_MIN: int = 3
const ARRIVE_STAR_MAX: int = 6
const ARRIVE_LIFETIME: float = 0.5
const FX_PINK: = Color(1.0, 0.65, 0.84, 0.7)


@export var item_size: float = ITEM_SIZE
@export var randomize_item_scale: bool = true


var playback_speed: float = 1.0

var _pool: Array[Sprite2D] = []
var _active: Array[Sprite2D] = []
var _effects: Array[CanvasItem] = []
var _tweens: Array[Tween] = []
var _token: int = 0
var _in_flight: int = 0
var _rng: = RandomNumberGenerator.new()


func _ready() -> void :
	_rng.randomize()


func play(start_global: Vector2, count: int, tex: Texture2D, 
		dst_provider: Callable, explode_radius: float = EXPLODE_RADIUS, 
		explode_shape: ExplodeShape = ExplodeShape.RADIAL, 
		arrival_parent: Variant = null) -> void :
	if count <= 0 or tex == null or not dst_provider.is_valid():
		return
	var fly_count: int = mini(count, MAX_FLY_ITEMS)
	var my_token: int = _token

	_in_flight += fly_count
	_spawn_burst(start_global, fly_count)

	var start_angle_deg: float = _rng.randf_range(0.0, 360.0)
	var done: = {"n": 0}
	for i in fly_count:
		_run_item(i, fly_count, start_angle_deg, start_global, tex, 
			dst_provider, explode_radius, explode_shape, my_token, done, -1.0, arrival_parent)

	while done.n < fly_count and my_token == _token and is_inside_tree():
		await get_tree().process_frame




func play_from_sources(count: int, tex: Texture2D, source_provider: Callable, 
		dst_provider: Callable, active: Callable) -> bool:
	if count <= 0 or tex == null:
		return true
	var token: int = _token
	var done: Dictionary = {"n": 0}
	for index: int in count:
		while token == _token and active.call() and _in_flight >= MAX_FLY_ITEMS:
			await get_tree().process_frame
		if token != _token or not active.call():
			return false
		var source: Variant = await source_provider.call(index)
		if token != _token or not active.call():
			return false
		if not source is Vector2:
			SortLogger.error("RankCollectFlyLayer: 起点必须返回全局 Vector2")
			cancel_all()
			return false
		_in_flight += 1
		_run_item(index, count, 0.0, source, tex, dst_provider, 0.0, 
			ExplodeShape.RADIAL, token, done, 0.0)
		var started: int = Time.get_ticks_msec()
		while token == _token and active.call() and Time.get_ticks_msec() - started < 80:
			await get_tree().process_frame
	while token == _token and active.call() and done.n < count:
		await get_tree().process_frame
	return token == _token and active.call()




func play_from_source(count: int, tex: Texture2D, source_provider: Callable, 
		dst_provider: Callable, active: Callable, burst_motion: Dictionary = {}) -> bool:
	if count <= 0 or tex == null:
		return true
	var fly_count: int = mini(count, MAX_FLY_ITEMS)
	var token: int = _token
	var done: Dictionary = {"n": 0}
	while token == _token and active.call() and _in_flight + fly_count > MAX_FLY_ITEMS:
		await get_tree().process_frame
	if token != _token or not active.call():
		return false
	var source: Variant = await source_provider.call(0)
	if token != _token or not active.call():
		return false
	if not source is Vector2:
		SortLogger.error("RankCollectFlyLayer: 起点必须返回全局 Vector2")
		cancel_all()
		return false
	_in_flight += fly_count
	_spawn_burst(source, fly_count)
	var start_angle_deg: float = _rng.randf_range(0.0, 360.0)
	for index: int in fly_count:
		_run_item(index, fly_count, start_angle_deg, source, tex, dst_provider, 
			EXPLODE_RADIUS, ExplodeShape.RADIAL, token, done, -1.0, null, burst_motion)
	while token == _token and active.call() and int(done.n) < fly_count:
		await get_tree().process_frame
	return token == _token and active.call()


func cancel_all() -> void :
	_token += 1
	_in_flight = 0
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()
	for spr in _active.duplicate():
		if is_instance_valid(spr):
			_recycle(spr)
	_active.clear()
	for effect: CanvasItem in _effects:
		if is_instance_valid(effect):
			if effect is RankCollectTrail:
				effect.cancel()
			effect.hide()
			effect.queue_free()
	_effects.clear()


func is_flying() -> bool:
	return _in_flight > 0


func _run_item(index: int, total: int, start_angle_deg: float, start_global: Vector2, 
		tex: Texture2D, dst_provider: Callable, explode_radius: float, 
		explode_shape: ExplodeShape, my_token: int, done: Dictionary, 
		flight_delay: float = -1.0, arrival_parent: Variant = null, 
		burst_motion: Dictionary = {}) -> void :
	var spr: Sprite2D = _acquire()
	spr.texture = tex
	var size_scale: float = _rng.randf_range(ITEM_SCALE_MIN, ITEM_SCALE_MAX) if randomize_item_scale else 1.0
	var base_scale: float = item_size / maxf(float(tex.get_width()), 1.0) * size_scale
	spr.scale = Vector2.ONE * base_scale
	spr.modulate.a = 1.0
	spr.global_position = start_global
	spr.visible = true

	var trail: = RankCollectTrail.new()
	add_child(trail)
	_track_effect(trail)
	trail.playback_speed = playback_speed

	var coin_motion: bool = not burst_motion.is_empty()
	var explode_global: Vector2 = start_global
	if coin_motion:
		var angle: float = _rng.randf_range(0.0, TAU)
		var distance: float = _rng.randf_range(
			float(burst_motion.pop_distance_min), float(burst_motion.pop_distance_max))
		explode_global = start_global + Vector2(cos(angle), sin(angle)) * distance
	elif explode_radius > 0.0:
		explode_global = _explode_pos(start_global, index, total, start_angle_deg, 
			explode_radius, explode_shape, item_size * size_scale)

	var tw: Tween = create_tween()
	tw.set_speed_scale(playback_speed)
	_tweens.append(tw)
	var tween_ref: WeakRef = weakref(tw)
	var fly_duration: float = FLY_SEC
	var ctrl_offset: Vector2
	if coin_motion:

		tw.tween_interval(float(index) * float(burst_motion.stagger))
		tw.tween_method(
			func(t: float) -> void :
				spr.global_position = start_global.lerp(explode_global, 1.0 - pow(1.0 - t, 3.0)), 
			0.0, 1.0, float(burst_motion.pop_duration))\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		var arc_random: float = float(burst_motion.arc_random)
		ctrl_offset = Vector2((float(index) - float(total - 1) * 0.5) * 25.0, 
			float(burst_motion.arc_height) * _rng.randf_range(1.0 - arc_random, 1.0 + arc_random))
		var speed_random: float = float(burst_motion.fly_speed_random)
		fly_duration = float(burst_motion.fly_duration) * _rng.randf_range(
			1.0 - speed_random, 1.0 + speed_random)
	else:
		if explode_radius > 0.0:
			tw.tween_property(spr, "global_position", explode_global, EXPLODE_SEC)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_interval(FLY_DELAY + float(index) * FLY_INTERVAL_DELAY if flight_delay < 0.0 else flight_delay)
		ctrl_offset = Vector2(
			_rng.randf_range(CURVE_OFFSET_X.x, CURVE_OFFSET_X.y), 
			_rng.randf_range(CURVE_OFFSET_Y.x, CURVE_OFFSET_Y.y))
	tw.tween_callback( func() -> void :
		if trail != null:
			trail.follow(spr))
	tw.tween_method(
		func(t: float) -> void :
			_apply_bezier(spr, explode_global, ctrl_offset, dst_provider, t)
			if coin_motion:
				spr.scale = Vector2.ONE * base_scale * lerpf(1.25, 0.85, t), 
		0.0, 1.0, fly_duration)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	if not coin_motion:
		tw.parallel().tween_property(spr, "modulate:a", 0.0, FADE_BEFORE_END)\
		.set_delay(maxf(FLY_SEC - FADE_BEFORE_END, 0.0))
	tw.tween_callback( func() -> void :
		_tweens.erase(tween_ref.get_ref())
		if my_token != _token:
			return
		if trail != null:
			trail.finish()
		_recycle(spr)
		_in_flight = maxi(_in_flight - 1, 0)
		done.n += 1
		_try_arrive_fx(dst_provider, arrival_parent)
		item_arrived.emit(index))


func _apply_bezier(spr: Sprite2D, from_global: Vector2, ctrl_offset: Vector2, 
		dst_provider: Callable, t: float) -> void :
	if not is_instance_valid(spr):
		return
	var dst: Vector2 = dst_provider.call()
	var ctrl: Vector2 = (from_global + dst) * 0.5 + ctrl_offset
	var u: float = 1.0 - t
	spr.global_position = u * u * from_global + 2.0 * u * t * ctrl + t * t * dst


func _explode_pos(start_global: Vector2, index: int, total: int, start_angle_deg: float, 
		radius: float, shape: ExplodeShape, item_size: float) -> Vector2:
	var offset: Vector2 = _explode_offset_horizontal(index, total, radius)\
	if shape == ExplodeShape.HORIZONTAL\
	else _explode_offset_radial(index, total, start_angle_deg, radius)
	var pos: Vector2 = start_global + offset
	var view: Vector2 = get_viewport_rect().size
	var half: float = item_size * 0.5 + SCREEN_MARGIN
	return Vector2(
		clampf(pos.x, half, maxf(view.x - half, half)), 
		clampf(pos.y, half, maxf(view.y - half, half)))


func _explode_offset_radial(index: int, total: int, start_angle_deg: float, 
		radius: float) -> Vector2:
	var step: float = 360.0 / maxf(float(total), 1.0)
	var angle_deg: float = start_angle_deg + step * float(index)\
	+ _rng.randf_range( - EXPLODE_ANGLE_RANDOM_DEG, EXPLODE_ANGLE_RANDOM_DEG)
	var r: float = radius + _rng.randf_range(
		- radius * EXPLODE_RADIUS_RANDOM, radius * EXPLODE_RADIUS_RANDOM)
	var angle: float = deg_to_rad(angle_deg)
	return Vector2(cos(angle), sin(angle)) * r


func _explode_offset_horizontal(index: int, total: int, radius: float) -> Vector2:
	var spacing: float = radius * EXPLODE_SPACING_RATIO
	return Vector2(
		(float(index) - float(total - 1) * 0.5) * spacing
			+ _rng.randf_range( - spacing, spacing) * EXPLODE_X_JITTER, 
		_rng.randf_range( - radius, radius) * EXPLODE_Y_SPREAD)


func _spawn_burst(at_global: Vector2, item_count: int) -> void :
	_spawn_shine_flash(at_global, BURST_SHINE_PX)
	var star_amount: int = mini(
		BURST_STAR_BASE + item_count * BURST_STAR_PER_ITEM, BURST_STAR_AMOUNT_MAX)
	_spawn_star_burst(at_global, star_amount, false)


func _try_arrive_fx(dst_provider: Callable, arrival_parent: Variant = null) -> void :
	if not dst_provider.is_valid():
		return

	if arrival_parent != null and not is_instance_valid(arrival_parent):
		return
	var at: Vector2 = dst_provider.call()
	_spawn_shine_flash(at, BURST_SHINE_PX_ARRIVE, arrival_parent)
	var amount: int = _rng.randi_range(ARRIVE_STAR_MIN, ARRIVE_STAR_MAX)
	_spawn_star_burst(at, amount, true, arrival_parent)


func _spawn_shine_flash(at_global: Vector2, display_px: float, 
		arrival_parent: Variant = null) -> void :
	var spr: = Sprite2D.new()
	spr.name = "BurstShine"
	spr.texture = BURST_SHINE_TEX
	spr.centered = true
	var tex_w: float = float(BURST_SHINE_TEX.get_width())
	var s0: float = (display_px * 0.55) / tex_w
	var s1: float = display_px / tex_w
	spr.scale = Vector2(s0, s0)
	spr.modulate = Color(FX_PINK.r, FX_PINK.g, FX_PINK.b, 0.0)
	spr.z_index = 2
	var mat: = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat

	if arrival_parent != null:
		arrival_parent.add_child(spr)
	else:
		add_child(spr)
	_track_effect(spr)
	spr.global_position = at_global
	var tw: = create_tween()
	_tweens.append(tw)
	var tween_ref: WeakRef = weakref(tw)
	tw.finished.connect( func() -> void : _tweens.erase(tween_ref.get_ref()), CONNECT_ONE_SHOT)
	tw.set_parallel(true)
	tw.tween_property(spr, "scale", Vector2(s1, s1), BURST_SHINE_SEC * 0.35)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "modulate:a", 0.55, BURST_SHINE_SEC * 0.2)
	tw.chain().tween_property(spr, "modulate:a", 0.0, BURST_SHINE_SEC * 0.65)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(spr, "scale", Vector2(s1 * 1.15, s1 * 1.15), 
		BURST_SHINE_SEC * 0.65)
	tw.chain().tween_callback(spr.queue_free)


func _spawn_star_burst(at_global: Vector2, amount: int, with_gravity: bool, 
		arrival_parent: Variant = null) -> void :
	var stars: = _make_burst_stars(amount)
	if with_gravity:
		stars.lifetime = ARRIVE_LIFETIME
		stars.emission_sphere_radius = 28.0
		stars.initial_velocity_min = 90.0
		stars.initial_velocity_max = 240.0
		stars.gravity = Vector2(0.0, 160.0)
	if arrival_parent != null:
		stars.local_coords = true
		arrival_parent.add_child(stars)
	else:
		add_child(stars)
	_track_effect(stars)
	stars.global_position = at_global
	stars.emitting = true
	stars.restart()
	_autofree(stars, stars.lifetime + 0.25)


func _make_burst_stars(amount: int) -> CPUParticles2D:
	var p: = CPUParticles2D.new()
	p.name = "BurstStars"
	p.texture = PARTICLE_TEX
	p.local_coords = false
	p.emitting = false
	p.one_shot = true
	p.amount = maxi(amount, 1)
	p.lifetime = BURST_STAR_LIFETIME
	p.lifetime_randomness = 0.35
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 22.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 300.0
	p.damping_min = 1.5
	p.damping_max = 4.5
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.6
	var mat: = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.color = FX_PINK
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(FX_PINK.r, FX_PINK.g, FX_PINK.b, 0.55))
	ramp.set_color(1, Color(FX_PINK.r, FX_PINK.g, FX_PINK.b, 0.0))
	p.color_ramp = ramp
	p.z_index = 1
	return p


func _make_particles(amount: int, lifetime: float, scale_max: float, 
		one_shot: bool) -> CPUParticles2D:
	var p: = CPUParticles2D.new()
	p.texture = PARTICLE_TEX
	p.local_coords = false
	p.emitting = false
	p.one_shot = one_shot
	p.amount = maxi(amount, 1)
	p.lifetime = lifetime
	p.lifetime_randomness = 0.5
	p.explosiveness = 0.9 if one_shot else 0.0
	p.scale_amount_min = scale_max * 0.4
	p.scale_amount_max = scale_max
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	var mat: = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	var init_ramp: = Gradient.new()
	init_ramp.set_color(0, Color(1, 1, 1, 0.4))
	init_ramp.set_color(1, Color(1, 1, 1, 1.0))
	p.color_initial_ramp = init_ramp
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	p.color_ramp = ramp
	return p


func _autofree(node: Node, after_sec: float) -> void :
	await get_tree().create_timer(after_sec).timeout
	if is_instance_valid(node):
		node.queue_free()


func _acquire() -> Sprite2D:
	var spr: Sprite2D = null
	while not _pool.is_empty() and spr == null:
		var candidate: Sprite2D = _pool.pop_back()
		if is_instance_valid(candidate):
			spr = candidate
	if spr == null:
		spr = Sprite2D.new()
		spr.z_index = 4
		add_child(spr)
	spr.visible = true
	_active.append(spr)
	return spr


func _recycle(spr: Sprite2D) -> void :
	if not is_instance_valid(spr):
		return
	_active.erase(spr)
	spr.visible = false
	spr.modulate.a = 1.0
	_pool.append(spr)


func _track_effect(effect: CanvasItem) -> void :
	_effects.append(effect)
	effect.tree_exited.connect( func() -> void : _effects.erase(effect), CONNECT_ONE_SHOT)
