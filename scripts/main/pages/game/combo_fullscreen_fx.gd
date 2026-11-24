class_name ComboFullscreenFx
extends Control

const FADE_IN_DURATION: float = 0.1
const SETTLE_DURATION: float = 0.14
const HOLD_DURATION: float = 0.26
const FADE_OUT_DURATION: float = 0.5
const PARTICLE_UPDATE_FRAMES: int = 2
const EDGE_LIGHT_COLOR: Color = Color(1.0, 0.976, 0.6)
const EDGE_LIGHT_OPACITY: float = 0.925
const SPAWN_CAPACITY: int = 16
const PETAL_EDGE_INSET: float = 26.0
const FLOWER_EDGE_INSET: float = 30.0
const PETAL_SPEED_RANGE: Vector2 = Vector2(0.12, 0.42)
const FLOWER_SPEED_RANGE: Vector2 = Vector2(0.115, 0.462)
const CULL_MARGIN: float = 240.0
const WARM_RENDER_FRAMES: int = 4
const PETAL_LAYOUT: Array = [
	[
		Vector4(0.9287037, 0.17051282, 0.0, 1.0), 
		Vector4(0.04722222, 0.1991453, 1.0, 1.0), 
		Vector4(0.02222222, 0.23931624, 2.0, 1.0), 
		Vector4(0.96111111, 0.2474359, 3.0, 1.0), 
		Vector4(0.93981481, 0.30683761, 4.0, 1.0), 
		Vector4(0.01944444, 0.35683761, 5.0, 1.0), 
		Vector4(0.97037037, 0.41410256, 6.0, 1.0), 
		Vector4(0.03703704, 0.42905983, 7.0, 1.0), 
		Vector4(0.06018519, 0.48162393, 8.0, 1.0), 
		Vector4(0.96574074, 0.5042735, 9.0, 1.0), 
		Vector4(0.03518519, 0.56965812, 10.0, 1.0), 
		Vector4(0.93981481, 0.57521368, 11.0, 1.0), 
		Vector4(0.03148148, 0.64188034, 12.0, 1.0), 
		Vector4(0.93981481, 0.66752137, 13.0, 1.0), 
		Vector4(0.06111111, 0.69487179, 14.0, 1.0), 
		Vector4(0.94166667, 0.72136752, 15.0, 1.0), 
		Vector4(0.03611111, 0.80042735, 16.0, 1.0), 
		Vector4(0.93611111, 0.82435897, 17.0, 1.0), 
		Vector4(0.96388889, 0.86025641, 18.0, 1.0), 
		Vector4(0.07962963, 0.88418803, 19.0, 1.0), 
	], 
	[
		Vector4(0.9212963, 0.16709402, 20.0, 1.0), 
		Vector4(0.08055556, 0.17307692, 21.0, 1.0), 
		Vector4(0.08055556, 0.1982906, 22.0, 1.0), 
		Vector4(0.97685185, 0.20769231, 23.0, 1.0), 
		Vector4(0.07222222, 0.24230769, 24.0, 1.0), 
		Vector4(0.92314815, 0.25940171, 25.0, 1.0), 
		Vector4(0.06296296, 0.29230769, 26.0, 1.0), 
		Vector4(0.96018519, 0.2957265, 27.0, 1.0), 
		Vector4(0.96296296, 0.33931624, 28.0, 1.0), 
		Vector4(0.04444444, 0.34401709, 29.0, 1.0), 
		Vector4(0.95833333, 0.40213675, 30.0, 1.0), 
		Vector4(0.05925926, 0.4034188, 31.0, 1.0), 
		Vector4(0.98148148, 0.44401709, 32.0, 1.0), 
		Vector4(0.03425926, 0.45897436, 33.0, 1.0), 
		Vector4(0.05833333, 0.48675214, 34.0, 1.0), 
		Vector4(0.98425926, 0.50726496, 35.0, 1.0), 
		Vector4(0.0287037, 0.55, 36.0, 1.0), 
		Vector4(0.9712963, 0.55982906, 37.0, 1.0), 
		Vector4(0.05833333, 0.58461538, 38.0, 1.0), 
		Vector4(0.93888889, 0.60683761, 39.0, 1.0), 
		Vector4(0.93981481, 0.64059829, 40.0, 1.0), 
		Vector4(0.06388889, 0.65854701, 41.0, 1.0), 
		Vector4(0.96944444, 0.68205128, 42.0, 1.0), 
		Vector4(0.01388889, 0.69059829, 43.0, 1.0), 
		Vector4(0.94166667, 0.73717949, 44.0, 1.0), 
		Vector4(0.075, 0.74615385, 45.0, 1.0), 
		Vector4(0.02962963, 0.79700855, 46.0, 1.0), 
		Vector4(0.98148148, 0.80769231, 47.0, 1.0), 
		Vector4(0.94444444, 0.84017094, 48.0, 1.0), 
		Vector4(0.07685185, 0.8525641, 49.0, 1.0), 
		Vector4(0.96944444, 0.9, 50.0, 1.0), 
		Vector4(0.06944444, 0.90811966, 51.0, 1.0), 
	], 
	[
		Vector4(0.95740741, 0.16581197, 52.0, 1.0), 
		Vector4(0.03611111, 0.17863248, 53.0, 1.0), 
		Vector4(0.94537037, 0.21068376, 54.0, 1.0), 
		Vector4(0.04537037, 0.22820513, 55.0, 1.0), 
		Vector4(0.06111111, 0.28119658, 56.0, 1.0), 
		Vector4(0.93981481, 0.29145299, 57.0, 1.0), 
		Vector4(0.93981481, 0.32606838, 58.0, 1.0), 
		Vector4(0.06111111, 0.34188034, 59.0, 1.0), 
		Vector4(0.94074074, 0.36794872, 60.0, 1.0), 
		Vector4(0.06111111, 0.3974359, 61.0, 1.0), 
		Vector4(0.06296296, 0.42820513, 62.0, 1.0), 
		Vector4(0.94074074, 0.43162393, 63.0, 1.0), 
		Vector4(0.05925926, 0.48675214, 64.0, 1.0), 
		Vector4(0.94074074, 0.48632479, 65.0, 1.0), 
		Vector4(0.06018519, 0.53888889, 66.0, 1.0), 
		Vector4(0.93888889, 0.5542735, 67.0, 1.0), 
		Vector4(0.93796296, 0.6034188, 68.0, 1.0), 
		Vector4(0.06018519, 0.62051282, 69.0, 1.0), 
		Vector4(0.94166667, 0.6525641, 70.0, 1.0), 
		Vector4(0.06111111, 0.66623932, 71.0, 1.0), 
		Vector4(0.06018519, 0.71068376, 72.0, 1.0), 
		Vector4(0.93888889, 0.71282051, 73.0, 1.0), 
		Vector4(0.92314815, 0.76666667, 74.0, 1.0), 
		Vector4(0.05648148, 0.78461538, 75.0, 1.0), 
		Vector4(0.05092593, 0.82692308, 76.0, 1.0), 
		Vector4(0.96203704, 0.84145299, 77.0, 1.0), 
		Vector4(0.04444444, 0.87820513, 78.0, 1.0), 
		Vector4(0.96388889, 0.89188034, 79.0, 1.0), 
	], 
]
const FLOWER_LAYOUT: Array[Vector4] = [
	Vector4(0.09537037, 0.26923077, 0.0, 64.0 / 224.0), 
	Vector4(0.09722222, 0.56623932, 1.0, 72.0 / 224.0), 
	Vector4(0.07777778, 0.7991453, 0.0, 60.0 / 224.0), 
	Vector4(0.90462963, 0.33119658, 1.0, 70.0 / 224.0), 
	Vector4(0.91296296, 0.62393162, 0.0, 62.0 / 224.0), 
	Vector4(0.88981481, 0.87179487, 1.0, 66.0 / 224.0), 
]

@onready var _petals: Array[GPUParticles2D] = [$Petals / Left, $Petals / Right]
@onready var _flowers: Array[GPUParticles2D] = [$Flowers / Left, $Flowers / Right]
@onready var _glows: Array[Sprite2D] = [$Glow / Left, $Glow / Right]

var _petal_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _flower_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _active_lifecycles: Array[GpuParticleLifecycle] = []
var _stage: int = 1
var _playing: bool = false
var _tween: Tween = null
var _warm_viewport: SubViewport = null
var _warm_groups: Array[Node] = []
var _warm_generation: int = 0


func _ready() -> void :
	for emitter: GPUParticles2D in _petals + _flowers:
		emitter.process_material = emitter.process_material.duplicate() as ParticleProcessMaterial
		emitter.material = emitter.material.duplicate() as ShaderMaterial
	_layout_emitters()
	_petal_lifecycle.prepare(_petals, PARTICLE_UPDATE_FRAMES, _can_render)
	_flower_lifecycle.prepare(_flowers, PARTICLE_UPDATE_FRAMES, _can_render)
	get_viewport().size_changed.connect(hide_now)
	_warm_render_pipeline.call_deferred()


func _warm_render_pipeline() -> void :
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or _playing:
		return
	_stage = 3
	_layout_emitters()
	_warm_viewport = SubViewport.new()
	_warm_viewport.name = "ComboWarmRender"
	_warm_viewport.size = Vector2i(UiMetrics.viewport_size())
	_warm_viewport.disable_3d = true
	_warm_viewport.transparent_bg = true
	_warm_viewport.msaa_2d = get_viewport().msaa_2d
	_warm_viewport.use_hdr_2d = get_viewport().use_hdr_2d
	_warm_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_warm_viewport)
	for group_name: String in ["Glow", "Petals", "Flowers"]:
		var group: Node = get_node(group_name)
		_warm_groups.append(group)
		group.reparent(_warm_viewport, false)
	_set_strength(1.0)
	_warm_generation += 1
	var generation: int = _warm_generation
	_start_warm_particles(generation)
	for frame_index: int in WARM_RENDER_FRAMES:
		if not _is_warming(generation):
			break
		await RenderingServer.frame_post_draw
	if _is_warming(generation):
		_cancel_warm_render()


func _start_warm_particles(generation: int) -> void :
	_petal_lifecycle.pre_render(_is_warming.bind(generation), 0.22)
	_flower_lifecycle.pre_render(_is_warming.bind(generation), 0.22)


func _is_warming(generation: int) -> bool:
	return generation == _warm_generation and is_inside_tree()\
	and is_instance_valid(_warm_viewport) and not _warm_viewport.is_queued_for_deletion()


func _cancel_warm_render() -> void :
	if not is_instance_valid(_warm_viewport):
		return
	_warm_generation += 1
	_petal_lifecycle.reset_immediate()
	_flower_lifecycle.reset_immediate()
	for group: Node in _warm_groups:
		group.reparent(self, false)
	_warm_groups.clear()
	_warm_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_warm_viewport.queue_free()
	_warm_viewport = null
	_stage = 1
	_set_strength(0.0)


static func stage_for_count(combo_count: int) -> int:
	if combo_count >= 8:
		return 3
	return 2 if combo_count >= 5 else 1


func play(stage: int) -> void :
	hide_now()
	if stage < 1 or stage > 3:
		return
	_stage = stage
	_layout_emitters()
	_active_lifecycles.append(_petal_lifecycle)
	if stage == 3:
		_active_lifecycles.append(_flower_lifecycle)
	_playing = true
	show()
	_set_strength(0.0)
	for lifecycle: GpuParticleLifecycle in _active_lifecycles:
		lifecycle.play()
	_tween = create_tween()
	_tween.tween_method(_set_strength, 0.0, 1.0, FADE_IN_DURATION)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_strength, 1.0, 0.9, SETTLE_DURATION)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_callback(_stop_with_tail)
	_tween.tween_method(_set_strength, 0.9, 0.0, FADE_OUT_DURATION)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(hide_now)


func hide_now() -> void :
	_cancel_warm_render()
	_playing = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	for lifecycle: GpuParticleLifecycle in _active_lifecycles:
		lifecycle.reset_immediate()
	_active_lifecycles.clear()
	for glow: Sprite2D in _glows:
		glow.self_modulate.a = 0.0
	hide()


func _stop_with_tail() -> void :
	for lifecycle: GpuParticleLifecycle in _active_lifecycles:
		lifecycle.stop_with_tail()


func _set_strength(strength: float) -> void :
	for lifecycle: GpuParticleLifecycle in _active_lifecycles:
		lifecycle.set_opacity(strength)
	for glow: Sprite2D in _glows:
		glow.self_modulate.a = strength * EDGE_LIGHT_OPACITY if _stage == 3 else 0.0


func _layout_emitters() -> void :
	var screen_size: Vector2 = UiMetrics.viewport_size()
	position = Vector2.ZERO
	size = screen_size
	var flower_color_offset: int = randi_range(0, 1)
	for side: int in 2:
		var direction_x: float = 1.0 if side == 0 else -1.0
		var side_x: float = 0.0 if side == 0 else screen_size.x
		var petal: GPUParticles2D = _petals[side]
		petal.position = Vector2(side_x + direction_x * PETAL_EDGE_INSET, screen_size.y * 0.5)
		var petal_items: PackedVector4Array = PackedVector4Array()
		for reference_item: Vector4 in PETAL_LAYOUT[_stage - 1]:
			if (reference_item.x < 0.5) == (side == 0):
				petal_items.append(reference_item)
		_set_reference_items(petal, _shuffle_reference_items(petal_items), screen_size)
		_configure_petal_motion(petal.process_material as ParticleProcessMaterial, 
			screen_size.x, direction_x)
		var flower: GPUParticles2D = _flowers[side]
		flower.position = Vector2(side_x + direction_x * FLOWER_EDGE_INSET, screen_size.y * 0.5)
		var flower_items: PackedVector4Array = PackedVector4Array()
		for reference_item: Vector4 in FLOWER_LAYOUT:
			if (reference_item.x < 0.5) != (side == 0):
				continue
			var flower_item: Vector4 = reference_item
			flower_item.z = fmod(flower_item.z + float(flower_color_offset), 2.0)
			flower_items.append(flower_item)
		_set_reference_items(flower, _shuffle_reference_items(flower_items), screen_size)
		_configure_flower_motion(flower.process_material as ParticleProcessMaterial, 
			screen_size.x, direction_x)
	for emitter: GPUParticles2D in _petals + _flowers:
		emitter.visibility_rect = Rect2( - emitter.position - Vector2.ONE * CULL_MARGIN, 
			screen_size + Vector2.ONE * CULL_MARGIN * 2.0)
	var edge_band_width: float = clampf(screen_size.x * 0.1328125, 118.75, 175.0)
	_glows[0].position = Vector2.ZERO
	_glows[1].position = Vector2(screen_size.x - edge_band_width, 0.0)
	for glow: Sprite2D in _glows:
		glow.modulate = EDGE_LIGHT_COLOR
		glow.scale = Vector2(edge_band_width / glow.texture.get_size().x, 
			screen_size.y / glow.texture.get_size().y)


func _shuffle_reference_items(reference_items: PackedVector4Array) -> PackedVector4Array:
	var shuffled_items: Array[Vector4] = []
	for reference_item: Vector4 in reference_items:
		shuffled_items.append(reference_item)
	shuffled_items.shuffle()
	return PackedVector4Array(shuffled_items)


func _set_reference_items(emitter: GPUParticles2D, reference_items: PackedVector4Array, 
		screen_size: Vector2) -> void :
	var visible_count: int = reference_items.size()
	for item_index: int in visible_count:
		var reference_item: Vector4 = reference_items[item_index]
		reference_item.x = 0.0
		reference_item.y = reference_item.y * screen_size.y - emitter.position.y
		reference_items[item_index] = reference_item
	reference_items.resize(SPAWN_CAPACITY)
	var draw_material: ShaderMaterial = emitter.material as ShaderMaterial
	draw_material.set_shader_parameter("reference_items", reference_items)
	draw_material.set_shader_parameter("visible_count", float(visible_count))
	draw_material.set_shader_parameter("art_scale", screen_size.x / UiMetrics.DESIGN.x)


func _configure_petal_motion(material: ParticleProcessMaterial, screen_width: float, 
		direction_x: float) -> void :
	material.direction = Vector3(direction_x * randf_range(0.65, 1.05), randf_range(-1.7, -1.1), 0.0)
	material.spread = randf_range(24.0, 38.0)
	material.gravity = Vector3(screen_width * randf_range(-0.012, 0.012), 
		randf_range(220.0, 380.0), 0.0)
	_configure_random_forces(material, screen_width, randf_range(0.65, 1.45))
	var damping_scale: float = randf_range(0.7, 1.25)
	material.damping_min = screen_width * 0.015 * damping_scale
	material.damping_max = screen_width * 0.065 * damping_scale
	material.emission_box_extents = Vector3(3.0, 3.0, 0.0)
	material.initial_velocity_min = PETAL_SPEED_RANGE.x * screen_width
	material.initial_velocity_max = PETAL_SPEED_RANGE.y * screen_width


func _configure_flower_motion(material: ParticleProcessMaterial, screen_width: float, 
		direction_x: float) -> void :
	material.direction = Vector3(direction_x * randf_range(0.55, 0.95), randf_range(-1.6, -1.05), 0.0)
	material.spread = randf_range(22.0, 36.0)
	material.gravity = Vector3(screen_width * randf_range(-0.01, 0.01), 
		randf_range(200.0, 360.0), 0.0)
	_configure_random_forces(material, screen_width, randf_range(0.55, 1.2))
	var damping_scale: float = randf_range(0.7, 1.25)
	material.damping_min = screen_width * 0.012 * damping_scale
	material.damping_max = screen_width * 0.055 * damping_scale
	material.emission_box_extents = Vector3(3.0, 3.0, 0.0)
	material.initial_velocity_min = FLOWER_SPEED_RANGE.x * screen_width
	material.initial_velocity_max = FLOWER_SPEED_RANGE.y * screen_width


func _configure_random_forces(material: ParticleProcessMaterial, screen_width: float, 
		force_scale: float) -> void :
	material.linear_accel_min = - screen_width * 0.025 * force_scale
	material.linear_accel_max = screen_width * 0.01 * force_scale
	material.tangential_accel_min = - screen_width * 0.03 * force_scale
	material.tangential_accel_max = screen_width * 0.03 * force_scale


func _can_render() -> bool:
	return (_playing and is_visible_in_tree()) or _is_warming(_warm_generation)


func _notification(what: int) -> void :
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT\
	or what == NOTIFICATION_APPLICATION_PAUSED\
	or (what == NOTIFICATION_VISIBILITY_CHANGED and _playing and not is_visible_in_tree()):
		hide_now()


func _exit_tree() -> void :
	if is_node_ready():
		hide_now()
