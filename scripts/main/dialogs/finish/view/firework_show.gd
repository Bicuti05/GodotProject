class_name FireworkShow
extends Node2D










































const _BURST_MIN: int = 5
const _BURST_MAX: int = 6




const _TOTAL_SPREAD: float = 0.84







const _AREA_X: Vector2 = Vector2(0.1, 0.9)









const _AREA_Y: Vector2 = Vector2(0.08, 0.4)



const _PALETTE: Array[Color] = [
	Color(1.0, 0.94, 0.54), 
	Color(0.44, 0.82, 1.0), 
	Color(1.0, 0.64, 0.23), 
	Color(1.0, 0.5, 0.69), 
	Color(0.77, 0.91, 0.36), 
	Color(0.25, 0.85, 0.54), 
	Color(0.79, 0.48, 1.0), 
]




const _PALETTE_WEIGHTS: Array[float] = [1.0, 1.0, 1.5, 1.5, 1.0, 1.5, 1.5]









const _COLOR_BRIGHTNESS: float = 1.5


const _SPARK_MIN: int = 16
const _SPARK_MAX: int = 20

const _POOL_BURST_COUNT: int = _BURST_MAX
const _POOL_SPARKS_PER_BURST: int = _SPARK_MAX






const _LIFE: float = 1.46
const _LIFE_RAND: float = 0.25
















const _RADIUS: float = 462.0
const _RADIUS_RAND: float = 0.3




const _SPARK_SPEED_SCALE: float = 0.7










const _BURST_SCALE_MIN: float = 0.5

const _STOP_AT: float = 0.9





const _DECAY_EXP: float = 5.0
























const _FALL_SPEED: float = 91.0











const _FALL_IN_AT: float = 0.05
const _FALL_FULL_AT: float = 0.35


const _FALL_EASE_AT: float = 0.4









const _FALL_EASE_EXP: float = 0.5


const _FALL_END_RATIO: float = 0.05








const _FADE_FROM: float = 0.62






const _ATLAS_GRID: int = 1



const _SPARK_SIZE: float = 12.94

const _SPARK_SIZE_RAND: float = 0.45





const _TRAIL_LIFETIME: float = 0.25













const _STAR_AMOUNT: int = 18
const _STAR_LIFETIME: float = 1.3
const _STAR_LIFETIME_RAND: float = 0.4
const _STAR_SIZE_PX: float = 52.0
const _STAR_SIZE_RAND: float = 0.5





const _STAR_TRAVEL_PX: float = 600.0






const _STAR_FADE_FROM: float = 0.7



const _STAR_ALPHA: float = 0.6


const _STAR_YELLOW_MIN: float = 0.1
const _STAR_YELLOW_MAX: float = 0.2










const _GLOW_A_PEAK: float = 0.2
const _GLOW_A_MID: float = 0.1
const _GLOW_T_IN: float = 0.2
const _GLOW_T_MID: float = 0.2
const _GLOW_T_OUT: float = 1.2
const _GLOW_SIZE: float = 840.0




@export var particle_atlas: Texture2D = null
@export var glow_texture: Texture2D = null

@export var star_texture: Texture2D = null



var _tweens: Array[Tween] = []


var _trails: FireworkTrails = null



var _pool_glows: Array[Sprite2D] = []
var _pool_stars: Array[GPUParticles2D] = []
var _star_lifecycles: Array[GpuParticleLifecycle] = []
var _pool_sparks: Array[_Spark] = []
var _spark_cells: Array[AtlasTexture] = []
var _additive_material: CanvasItemMaterial = null
var _star_decel_curve: CurveTexture = null
var _star_color_ramp: GradientTexture1D = null







func play() -> void :
	stop()
	_ensure_pool()
	_launch_volley()




func prepare_pool_spread(progress: Callable = Callable(), active: Callable = Callable()) -> void :
	if particle_atlas == null or glow_texture == null:
		return
	_prepare_shared_pool_resources()
	_ensure_trails()
	if progress.is_valid():
		progress.call(0.0)
	await _trails.prepare_pool_spread(_POOL_BURST_COUNT * _POOL_SPARKS_PER_BURST)
	if active.is_valid() and not active.call():
		return
	if progress.is_valid():
		progress.call(0.25)

	var frame_started: int = Time.get_ticks_usec()
	var total: int = _POOL_BURST_COUNT * (1 + _POOL_SPARKS_PER_BURST)
	while _pool_glows.size() < _POOL_BURST_COUNT or _pool_sparks.size() < _POOL_BURST_COUNT * _POOL_SPARKS_PER_BURST:
		if active.is_valid() and not active.call():
			return
		if Time.get_ticks_usec() - frame_started >= 2000:
			await get_tree().process_frame
			frame_started = Time.get_ticks_usec()
			if active.is_valid() and not active.call():
				return

		if _pool_sparks.size() >= _pool_glows.size() * _POOL_SPARKS_PER_BURST:
			_create_pool_slot_shell()
		else:
			_create_pool_spark()
		if progress.is_valid():
			progress.call(0.25 + 0.75 * float(_pool_glows.size() + _pool_sparks.size()) / total)




func warm_render_pipeline(minimal_pool: bool = false, active: Callable = Callable(), checkpoint: Callable = Callable()) -> bool:
	if active.is_valid() and not active.call():
		return false
	if minimal_pool:
		_ensure_warmup_pool()
	else:
		_ensure_pool()
	var center: = UiMetrics.viewport_size() * 0.5
	var color: = Color(1.0, 0.75, 0.35)


	if (active.is_valid() and not active.call()) or (checkpoint.is_valid() and not await checkpoint.call("fireworks_glow")):
		stop()
		return false
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:fireworks_glow")
	_activate_glow(0, center, color, 1.0)
	await RenderingServer.frame_post_draw

	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:fireworks_glow")
	stop()

	if (active.is_valid() and not active.call()) or (checkpoint.is_valid() and not await checkpoint.call("fireworks_stars")):
		stop()
		return false
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:fireworks_stars")
	await _activate_stars_colored(0, center, 1.0, 0.15)
	if active.is_valid() and not active.call():
		stop()
		return false
	_pool_stars[0].request_particles_process(0.1)
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:fireworks_stars")
	stop()

	if (active.is_valid() and not active.call()) or (checkpoint.is_valid() and not await checkpoint.call("fireworks_spark")):
		stop()
		return false
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:fireworks_spark")
	var spark: _Spark = _pool_sparks[0]
	spark.texture = _spark_cells[0]
	spark.modulate = color
	spark.position = center
	var cell_w: float = maxf(1.0, float(particle_atlas.get_width()) / float(_ATLAS_GRID))
	spark.scale = Vector2.ONE * (_SPARK_SIZE / cell_w)
	var trail: FireworkTrails.Ribbon = _trails.add_ribbon(
		spark, _SPARK_SIZE, color, 0.9, _TRAIL_LIFETIME)
	spark.launch(Vector2.RIGHT, 600.0, 0.5, trail)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:fireworks_spark")
	stop()
	return not active.is_valid() or active.call()


func _launch_volley() -> void :
	if particle_atlas == null or glow_texture == null:


		push_warning("FireworkShow: particle_atlas / glow_texture 未绑定,本轮烟花跳过")
		return
	var count: int = randi_range(_BURST_MIN, _BURST_MAX)
	var gap: float = _TOTAL_SPREAD / float(maxi(1, count - 1))
	var scales: Array[float] = _build_burst_scales(count)
	for i in count:
		var center: Vector2 = _random_center()
		if i == 0:
			_spawn_burst(center, scales[0], i)
			continue
		var tw: = create_tween()
		tw.tween_interval(gap * float(i))
		tw.tween_callback(_spawn_burst.bind(center, scales[i], i))
		_tweens.append(tw)



func _build_burst_scales(count: int) -> Array[float]:
	var out: Array[float] = []
	if count <= 0:
		return out
	out.append(1.0)
	if count >= 2:
		out.append(_BURST_SCALE_MIN)
	while out.size() < count:
		out.append(randf_range(_BURST_SCALE_MIN, 1.0))
	out.shuffle()
	return out



func stop() -> void :
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()

	_ensure_trails()
	_trails.clear_all()
	for g: Sprite2D in _pool_glows:
		g.visible = false
		g.modulate.a = 0.0
	for lifecycle: GpuParticleLifecycle in _star_lifecycles:
		lifecycle.reset_immediate()
	for spark: _Spark in _pool_sparks:
		spark.reset_for_pool()




func _ensure_trails() -> void :
	if is_instance_valid(_trails):
		return
	_trails = FireworkTrails.new()
	_trails.name = "Trails"
	add_child(_trails)
	move_child(_trails, 0)


func _ensure_pool() -> void :
	if particle_atlas == null or glow_texture == null:
		return
	_prepare_shared_pool_resources()
	_ensure_trails()
	_trails.prepare_pool(_POOL_BURST_COUNT * _POOL_SPARKS_PER_BURST)

	while _pool_sparks.size() < _pool_glows.size() * _POOL_SPARKS_PER_BURST:
		_create_pool_spark()
	while _pool_glows.size() < _POOL_BURST_COUNT:
		_create_pool_slot()



func _ensure_warmup_pool() -> void :
	_prepare_shared_pool_resources()
	_ensure_trails()
	_trails.prepare_pool(1)
	if _pool_glows.is_empty():
		_create_pool_slot_shell()
	if _pool_sparks.is_empty():
		_create_pool_spark()


func _prepare_shared_pool_resources() -> void :
	if _additive_material == null:
		_additive_material = CanvasItemMaterial.new()
		_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	if _star_decel_curve == null:
		_star_decel_curve = _make_square_decel()
	if _star_color_ramp == null:
		_star_color_ramp = _make_hold_fade_ramp(_STAR_FADE_FROM, _STAR_ALPHA)
	if _spark_cells.is_empty():
		var w: float = float(particle_atlas.get_width()) / float(_ATLAS_GRID)
		var h: float = float(particle_atlas.get_height()) / float(_ATLAS_GRID)
		for y in _ATLAS_GRID:
			for x in _ATLAS_GRID:
				var atlas: = AtlasTexture.new()
				atlas.atlas = particle_atlas
				atlas.region = Rect2(float(x) * w, float(y) * h, w, h)
				_spark_cells.append(atlas)


func _create_pool_slot() -> void :
	_create_pool_slot_shell()
	for i in _POOL_SPARKS_PER_BURST:
		_create_pool_spark()


func _create_pool_slot_shell() -> void :
	var glow: = Sprite2D.new()
	glow.texture = glow_texture
	glow.material = _additive_material
	glow.visible = false
	add_child(glow)
	_pool_glows.append(glow)

	var pm: = ParticleProcessMaterial.new()

	pm.particle_flag_disable_z = true
	pm.lifetime_randomness = _STAR_LIFETIME_RAND
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 8.0
	pm.spread = 0.0
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.0
	pm.radial_velocity_curve = _star_decel_curve
	pm.damping_min = 0.0
	pm.damping_max = 0.0
	var cell: float = _STAR_SIZE_PX / maxf(1.0, float(star_texture.get_width()))\
	if star_texture != null else 1.0
	pm.scale_min = cell * (1.0 - _STAR_SIZE_RAND)
	pm.scale_max = cell * (1.0 + _STAR_SIZE_RAND)
	pm.color_ramp = _star_color_ramp

	var stars: = GPUParticles2D.new()
	stars.material = _additive_material
	stars.texture = star_texture
	stars.process_material = pm
	stars.amount = _STAR_AMOUNT
	stars.lifetime = _STAR_LIFETIME
	stars.one_shot = true
	stars.explosiveness = 1.0
	stars.local_coords = false
	var reach: float = _STAR_TRAVEL_PX * 1.6 + _STAR_SIZE_PX
	stars.visibility_rect = Rect2( - reach, - reach, reach * 2.0, reach * 2.0)
	stars.emitting = false
	stars.visible = false

	add_child(stars)
	_pool_stars.append(stars)
	var lifecycle: = GpuParticleLifecycle.new()
	lifecycle.prepare([stars], 2, func() -> bool: return is_visible_in_tree())
	_star_lifecycles.append(lifecycle)


func _create_pool_spark() -> void :
	var spark: = _Spark.new()
	spark.visible = false
	spark.set_process(false)
	add_child(spark)
	_pool_sparks.append(spark)


func _random_center() -> Vector2:
	var parent: = get_parent() as Control


	var sz: Vector2 = UiMetrics.viewport_size() if parent == null else parent.size
	return Vector2(
		randf_range(_AREA_X.x, _AREA_X.y) * sz.x, 
		randf_range(_AREA_Y.x, _AREA_Y.y) * sz.y)


func _spawn_burst(center: Vector2, burst_scale: float, slot: int) -> void :


	var color: Color = _pick_color()


	var bs: float = burst_scale
	_activate_glow(slot, center, color, bs)
	_activate_stars(slot, center, bs)
	var n: int = randi_range(_SPARK_MIN, _SPARK_MAX)

	var base: float = randf() * TAU
	for i in n:
		var ang: float = base + TAU * float(i) / float(n) + randf_range(-0.12, 0.12)


		var side: float = _SPARK_SIZE * randf_range(
			1.0 - _SPARK_SIZE_RAND, 1.0 + _SPARK_SIZE_RAND)

		var spark: _Spark = _pool_sparks[slot * _POOL_SPARKS_PER_BURST + i]
		spark.texture = _random_cell()
		spark.modulate = color
		spark.position = center
		var cell_w: float = maxf(1.0, float(particle_atlas.get_width()) / float(_ATLAS_GRID))
		spark.scale = Vector2.ONE * (side / cell_w)




		var trail: FireworkTrails.Ribbon = _trails.add_ribbon(
			spark, side, color, 0.9, _TRAIL_LIFETIME)
		var life: float = _LIFE * randf_range(1.0 - _LIFE_RAND, 1.0 + _LIFE_RAND)
		var radius: float = _RADIUS * bs\
		* randf_range(1.0 - _RADIUS_RAND, 1.0 + _RADIUS_RAND)


		var curve_area: float = _STOP_AT / (_DECAY_EXP + 1.0)
		var v0: float = (radius / maxf(0.001, life * curve_area)) * _SPARK_SPEED_SCALE
		spark.launch(Vector2.RIGHT.rotated(ang), v0, life, trail)



func _pick_color() -> Color:
	if _PALETTE_WEIGHTS.size() != _PALETTE.size():
		push_error("FireworkShow: _PALETTE_WEIGHTS 与 _PALETTE 长度不一致,退回等概率取色")
		return _PALETTE[randi() % _PALETTE.size()]
	var total: float = 0.0
	for w in _PALETTE_WEIGHTS:
		total += w
	var r: float = randf() * total
	var acc: float = 0.0
	for i in _PALETTE.size():
		acc += _PALETTE_WEIGHTS[i]
		if r < acc:
			return _brighten(_PALETTE[i])
	return _brighten(_PALETTE[_PALETTE.size() - 1])



func _brighten(c: Color) -> Color:
	var v: float = maxf(maxf(c.r, c.g), c.b)
	if v <= 0.0:
		return c
	var target: float = v * _COLOR_BRIGHTNESS
	if target <= 1.0:
		return Color(c.r * _COLOR_BRIGHTNESS, c.g * _COLOR_BRIGHTNESS, 
			c.b * _COLOR_BRIGHTNESS, c.a)

	var norm: = Color(c.r / v, c.g / v, c.b / v, c.a)
	return norm.lerp(Color(1.0, 1.0, 1.0, c.a), clampf(target - 1.0, 0.0, 1.0))



func _random_cell() -> AtlasTexture:

	var x: int = randi() % _ATLAS_GRID
	var y: int = randi() % _ATLAS_GRID
	return _spark_cells[y * _ATLAS_GRID + x]




func _activate_stars(slot: int, center: Vector2, burst_scale: float) -> void :
	_activate_stars_colored(slot, center, burst_scale, 
		randf_range(_STAR_YELLOW_MIN, _STAR_YELLOW_MAX))


func _activate_stars_colored(slot: int, center: Vector2, burst_scale: float, 
		yellow_blend: float) -> void :
	if star_texture == null:
		return
	var p: GPUParticles2D = _pool_stars[slot]
	var pm: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	if pm == null:
		return
	_star_lifecycles[slot].reset_immediate()



	var v0: float = _STAR_TRAVEL_PX * burst_scale / ((1.0 / 3.0) * _STAR_LIFETIME)
	pm.radial_velocity_min = v0 * 0.6
	pm.radial_velocity_max = v0

	pm.color = Color.WHITE.lerp(Color.YELLOW, yellow_blend)
	p.position = center
	_star_lifecycles[slot].play()



static func _make_square_decel() -> CurveTexture:
	var c: = Curve.new()
	c.min_value = 0.0
	c.max_value = 1.0

	for i in 5:
		var t: float = float(i) / 4.0
		c.add_point(Vector2(t, pow(1.0 - t, 2.0)))
	var t: = CurveTexture.new()
	t.curve = c
	return t





static func _make_hold_fade_ramp(hold: float, alpha: float) -> GradientTexture1D:
	var g: = Gradient.new()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	g.add_point(0.0, Color(1.0, 1.0, 1.0, alpha))
	g.add_point(clampf(hold, 0.0, 0.99), Color(1.0, 1.0, 1.0, alpha))
	g.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))
	var t: = GradientTexture1D.new()
	t.gradient = g
	return t




func _activate_glow(slot: int, center: Vector2, tint: Color, burst_scale: float) -> void :
	var g: Sprite2D = _pool_glows[slot]
	g.position = center
	g.visible = true

	var c: Color = tint.lerp(Color.WHITE, 0.45)
	c.a = 0.0
	g.modulate = c

	var gw: float = maxf(1.0, float(glow_texture.get_width()))
	g.scale = Vector2.ONE * (_GLOW_SIZE * burst_scale / gw)
	var tw: = create_tween()
	tw.tween_property(g, "modulate:a", _GLOW_A_PEAK, _GLOW_T_IN)
	tw.tween_property(g, "modulate:a", _GLOW_A_MID, _GLOW_T_MID)
	tw.tween_property(g, "modulate:a", 0.0, _GLOW_T_OUT)
	tw.tween_callback(g.hide)
	_tweens.append(tw)



class _Spark extends Sprite2D:
	var _dir: Vector2 = Vector2.RIGHT
	var _v0: float = 0.0
	var _life: float = 0.35
	var _t: float = 0.0
	var _trail: RefCounted = null

	func launch(dir: Vector2, v0: float, life: float, trail: RefCounted) -> void :
		_dir = dir
		_v0 = v0
		_life = maxf(0.01, life)
		_t = 0.0
		_trail = trail
		visible = true
		set_process(true)

	func reset_for_pool() -> void :
		set_process(false)
		if _trail != null:
			_trail.call("detach")
		_trail = null
		_t = 0.0
		visible = false

	func _process(delta: float) -> void :
		_t += delta
		if _t >= _life:
			_finish()
			return
		var tau: float = _t / _life

		var k: float = pow(clampf(1.0 - tau / _STOP_AT, 0.0, 1.0), _DECAY_EXP)



		var fall_k: float = 0.0
		if tau > _FALL_IN_AT:
			if tau < _FALL_FULL_AT:
				fall_k = (tau - _FALL_IN_AT) / maxf(0.001, _FALL_FULL_AT - _FALL_IN_AT)
			elif tau < _FALL_EASE_AT:
				fall_k = 1.0
			else:
				var t2: float = clampf((tau - _FALL_EASE_AT)
					/ maxf(0.001, _STOP_AT - _FALL_EASE_AT), 0.0, 1.0)
				fall_k = lerpf(1.0, _FALL_END_RATIO, pow(t2, _FALL_EASE_EXP))
		position += (_dir * _v0 * k + Vector2(0.0, _FALL_SPEED * fall_k)) * delta

		if tau > _FADE_FROM:
			modulate.a = clampf((1.0 - tau) / (1.0 - _FADE_FROM), 0.0, 1.0)


	func _finish() -> void :
		set_process(false)
		if _trail != null:


			_trail.call("detach")
		_trail = null
		visible = false
