extends Node2D

@export var combined_star: Texture2D
var impact: Node2D
var idle: Node2D
var impact_count: = 0
var impact_active: = false
var idle_active: = false
var paused: = false
var occluded: = false
var last_impact: = Vector2.ZERO
var impact_clock: = 0.0

func _ready() -> void :
	impact = $SunflowerConfirmedCollectionBurst
	idle = $SunflowerPodiumGiftIdle
	idle.subject_mode = true
	clear()

func play_impact(at: Vector2, footprint_width: float) -> void :
	impact_count += 1
	last_impact = at
	impact_clock = 0.0
	impact_active = true



	var mix: = CanvasItemMaterial.new()
	mix.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	impact.emitters[1].material = mix
	impact.emitters[1].texture = combined_star
	impact.emitters[1].color = Color(1, 1, 1, 0.82)
	var neutral: = Gradient.new()
	neutral.set_color(0, Color.WHITE)
	neutral.set_color(1, Color.WHITE)
	impact.emitters[1].color_initial_ramp = neutral
	impact.emitters[0].material = mix
	impact.emitters[0].modulate.a = 0.15
	impact.play(at, 108.0)
	impact.scale = Vector2.ONE * footprint_width / 300.0
	var points: = PackedVector2Array()
	var normals: = PackedVector2Array()
	for i in 12:
		var normal: = Vector2.from_angle(TAU * i / 12.0)
		points.append(normal * 140.0)
		normals.append(normal)
	for p in [impact.emitters[1], impact.emitters[2]]:
		p.amount = 12
		p.seed = 4033
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_DIRECTED_POINTS
		p.emission_points = points
		p.emission_normals = normals
		p.direction = Vector2.RIGHT
		p.spread = 5.0
		p.local_coords = true
		p.restart()
		p.emitting = true
	impact.emitters[0].show()
	impact.emitters[1].show()
	impact.emitters[2].emitting = false
	impact.emitters[2].hide()
	impact.emitters[0].modulate.a = 0.15
	impact.z_index = 5
	_sync()

func start_idle(sprite: Sprite2D, size_hint: Vector2) -> void :
	idle.start(sprite.get_parent(), sprite.texture, size_hint)

	var prepared: Dictionary = idle.prepare_mask(sprite.texture, size_hint)
	var rect: Rect2i = prepared.bounds
	var visible_center: = Vector2(rect.position) + Vector2(rect.size) * 0.5
	idle.anchor_offset = (visible_center - sprite.texture.get_size() * 0.5) * sprite.scale + sprite.position
	idle_active = true
	_sync()

func _process(delta: float) -> void :
	if paused or occluded: return
	if impact_active:
		impact_clock += delta
		if impact_clock > 1.3:
			impact_active = false
			impact.reset()

func stop_idle() -> void :
	idle_active = false
	if is_instance_valid(idle): idle.reset()

func suspend(value: bool) -> void :
	paused = value
	_sync()

func set_occluded(value: bool) -> void :
	occluded = value
	_sync()

func _sync() -> void :
	visible = not occluded
	if is_instance_valid(impact): impact.suspend(paused or occluded)
	if is_instance_valid(idle):
		idle.set_occluded(occluded)
		idle.suspend(paused)

func clear() -> void :
	impact_count = 0
	impact_clock = 0.0
	impact_active = false
	paused = false
	occluded = false
	if is_instance_valid(impact): impact.reset()
	stop_idle()
	visible = true

func _exit_tree() -> void :
	clear()
