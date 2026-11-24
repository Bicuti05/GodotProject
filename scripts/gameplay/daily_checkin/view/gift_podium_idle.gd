extends Node2D

const BEATS: = [0.18, 0.66, 1.23, 1.88]
var motes: CPUParticles2D
var sparkles: Array[CPUParticles2D] = []
var spots: Array[Vector2] = []
var subject_mode: = false
var _mask_cache: Dictionary = {}
var focus_suppressed: = false
var anchor_offset: = Vector2(0, -2)
var target: Node2D
var active: = false
var paused: = false
var occluded: = false
var clock: = 0.0
var beat: = 0
var cycle: = 0
var pool_index: = 0
var seed_offset: = 0
var rng: = RandomNumberGenerator.new()
var next_sparkle_time: = 0.18
var last_spot: = -1
var sparkle_count: = 0

func _ready() -> void :
	motes = $RiseMotes
	motes.local_coords = true

	motes.amount = 7
	motes.lifetime = 2.6
	motes.preprocess = 2.0
	motes.randomness = 0.45
	motes.spread = 28.0
	motes.scale_amount_min = 0.05
	motes.scale_amount_max = 0.09
	for i in 3:
		var p: = get_node("Sparkles%d" % i) as CPUParticles2D
		p.local_coords = true
		sparkles.append(p)
	z_index = 6
	reset()

func prepare_mask(texture: Texture2D, size_hint: Vector2) -> Dictionary:
	var key: String = "%s:%s:%s" % [texture.get_instance_id(), size_hint, subject_mode]
	if _mask_cache.has(key):
		return _mask_cache[key]
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	var bounds: Rect2i = image.get_used_rect()
	var image_scale: float = minf(size_hint.x / texture.get_width(), size_hint.y / texture.get_height())
	var mask_center: Vector2 = texture.get_size() * 0.5
	if subject_mode:
		image_scale = minf(size_hint.x / maxf(bounds.size.x, 1), size_hint.y / maxf(bounds.size.y, 1))
		mask_center = Vector2(bounds.position) + Vector2(bounds.size) * 0.5
	var half: Vector2 = size_hint * 0.5
	var prepared_spots: Array[Vector2] = []
	for gy in 28:
		for gx in 28:
			var pixel: Vector2i = Vector2i(int((gx + 0.5) * image.get_width() / 28.0), int((gy + 0.5) * image.get_height() / 28.0))
			var color: Color = image.get_pixelv(pixel)
			if color.a < 0.35:
				continue
			if subject_mode and color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722 > 0.84:
				continue
			var local: Vector2 = (Vector2(pixel) + Vector2(0.5, 0.5) - mask_center) * image_scale
			if Vector2(local.x / half.x, local.y / half.y).length() > 0.6:
				prepared_spots.append(local)
	var prepared: Dictionary = {"bounds": bounds, "spots": prepared_spots}
	_mask_cache[key] = prepared
	return prepared

func start(rig: Node2D, texture: Texture2D, size_hint: Vector2) -> void :
	target = rig
	if active: return
	var half: = size_hint * 0.5
	var prepared: Dictionary = prepare_mask(texture, size_hint)
	if subject_mode:
		var size_ratio: = minf(size_hint.x / 96.6, size_hint.y / 108.15)

		var particle_ratio: = sqrt(size_ratio)
		motes.scale_amount_min = 0.05 * particle_ratio * 1.6
		motes.scale_amount_max = 0.09 * particle_ratio * 1.6
		for p in sparkles:
			p.lifetime = 0.62
			p.scale_amount_min = 0.18 * particle_ratio * 1.45
			p.scale_amount_max = 0.26 * particle_ratio * 1.45
		motes.amount = 12
		for p in [motes] + sparkles:
			var mix: = CanvasItemMaterial.new()
			mix.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			p.material = mix
			p.modulate = Color(1, 1, 1, 0.82 if p == motes else 0.95)
	if subject_mode:
		motes.color = Color.WHITE
		var fade: = motes.color_ramp.duplicate() as Gradient
		for i in fade.get_point_count():
			fade.set_color(i, Color(1, 1, 1, fade.get_color(i).a))
		motes.color_ramp = fade
	spots.assign(prepared.spots)
	motes.position = Vector2(0, half.y * 0.92)
	motes.emission_rect_extents = Vector2(half.x * 0.55, 10.0)
	if subject_mode: motes.emission_rect_extents.x = half.x * 0.85
	motes.initial_velocity_min = half.y * 0.55 * 0.55
	motes.initial_velocity_max = half.y * 0.55 * 0.9
	clock = 0.0
	beat = 0
	cycle = 0
	pool_index = seed_offset
	rng.seed = 44123 + seed_offset
	next_sparkle_time = 0.18
	last_spot = -1
	sparkle_count = 0
	active = true
	motes.restart()
	motes.emitting = true
	_sync()

func _process(delta: float) -> void :
	if not active or paused or occluded: return

	if get_parent().modulate.a <= 0.01:
		for p in [motes] + sparkles: p.speed_scale = 0.0
		return
	_sync()
	if not is_instance_valid(target):
		reset()
		return
	if subject_mode:
		position = get_parent().to_local(target.global_position) + anchor_offset
	else:
		position = target.position + anchor_offset
	if subject_mode:

		while clock + delta >= next_sparkle_time:
			_emit_sparkle()
			next_sparkle_time += rng.randf_range(0.45, 0.8)
	else:
		while clock + delta >= cycle * 5.5 + float(BEATS[beat]):
			_emit_sparkle()
			beat += 1
			if beat == BEATS.size():
				beat = 0
				cycle += 1
	clock += delta

func _emit_sparkle() -> void :
	if spots.is_empty() or focus_suppressed: return
	var index: = rng.randi_range(0, spots.size() - 1)
	if index == last_spot and spots.size() > 1: index = (index + 1) % spots.size()
	last_spot = index
	var p: = sparkles[pool_index % sparkles.size()]
	p.position = spots[index]
	pool_index += 1
	p.show()
	p.restart()
	p.emitting = true
	sparkle_count += 1

func reset() -> void :
	active = false
	focus_suppressed = false
	modulate.a = 1.0
	clock = 0.0
	next_sparkle_time = 0.18
	sparkle_count = 0
	paused = false
	occluded = false
	for p in [motes] + sparkles:
		if is_instance_valid(p):
			p.restart()
			p.emitting = false
			p.speed_scale = 0.0
	hide()

func suspend(value: bool) -> void :
	paused = value
	_sync()

func set_occluded(value: bool) -> void :
	occluded = value
	_sync()

func _sync() -> void :
	visible = active and not occluded
	for p in [motes] + sparkles:
		p.speed_scale = 0.0 if paused or occluded or not active else 1.0
