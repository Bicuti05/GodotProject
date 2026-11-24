class_name JuiceMysteryRevealEffects
extends Node2D


var skin_resources: JuiceSkinResolver
var fruit_d: float = 0.0
var bonus_coin_texture: Texture2D
var emitters: Array[GPUParticles2D] = []
var rendered: bool = false
var preparing: bool = false
var _layer: Node2D
var _petal_size: float
var _petal_min_ratio: float
var _petal_max_ratio: float
var _flower_z: int
var _nodes: Dictionary = {}
var _active_nodes: Dictionary = {}
var _tweens: Array[Tween] = []
var _warm_generation: int = 0
var _rendered_stages: PackedStringArray = []
var _recipe_signature: String = ""
var _watched_resources: Array[Resource] = []

func configure(resources: JuiceSkinResolver, diameter: float, coin: Texture2D, 
		petal_size: float, min_ratio: float, max_ratio: float, flower_z: int) -> void :
	skin_resources = resources
	_watch_resource(preload("res://assets/effect/shader/particle_atlas_cell.gdshader"))
	var signature: String = EffectWarmupPolicy.signature("mystery_reveal", resources)
	var textures: Array[Texture2D] = [
		effect_texture(&"mystery_petal", MYSTERY_PETAL_TEX), effect_texture(&"mystery_glow", MYSTERY_GLOW_TEX), 
		effect_texture(&"mystery_flash", MYSTERY_FLASH_TEX), effect_texture(&"mystery_star", MYSTERY_STAR_TEX)]
	for slot: int in JuiceTheme.COLOR_KEYS.size():
		textures.append(resources.mystery_particle_texture(slot) if resources != null else null)
	for texture: Texture2D in textures:
		signature += ":" + str(texture.get_instance_id() if texture != null else 0)
		_watch_resource(texture)
	if resources != null:
		for pack: JuiceSkinDefinition in [resources.default_skin, resources.active_skin]:
			_watch_resource(pack)
			_watch_resource(pack.effects)
		if EffectWarmupPolicy.signature("mystery_reveal", resources).is_empty():
			signature += ":%d:%d" % [resources.default_skin.revision, resources.active_skin.revision]
	if signature != _recipe_signature:
		_invalidate_rendered()
		_recipe_signature = signature
	fruit_d = diameter
	bonus_coin_texture = coin
	_petal_size = petal_size
	_petal_min_ratio = min_ratio
	_petal_max_ratio = max_ratio
	_flower_z = flower_z

func _watch_resource(resource: Resource) -> void :
	if resource == null or _watched_resources.has(resource):
		return
	_watched_resources.append(resource)
	resource.changed.connect(_invalidate_rendered)

func _invalidate_rendered() -> void :
	reset_immediate()
	rendered = false
	_rendered_stages.clear()
	for node: CanvasItem in _nodes.keys():
		if is_instance_valid(node):
			if node is GPUParticles2D:
				node.finished.disconnect(_release_mystery_petal_emitter.bind(node))
			node.queue_free()
	_nodes.clear()
	emitters.clear()
	_mystery_petal_pool.clear()
	_mystery_glow_pool.clear()
	_mystery_flash_pool.clear()
	_mystery_star_pool.clear()

func bind_layer(layer: Node2D) -> void :
	_layer = layer

func _resolve_fruit_layer() -> Node2D:
	return _layer if is_instance_valid(_layer) and _layer.is_inside_tree() else null

func effect_texture(field: StringName, fallback: Texture2D) -> Texture2D:
	return skin_resources.effect_texture(field, fallback) if skin_resources != null else fallback

func _render_ready() -> bool:
	return is_instance_valid(_layer) and _layer.is_inside_tree() and _layer.is_visible_in_tree()\
	and _layer.modulate.a > 0.01 and ( not _layer.get_viewport() is SubViewport\
	or (_layer.get_viewport() as SubViewport).render_target_update_mode != SubViewport.UPDATE_DISABLED)

func _track_warm_effect(node: CanvasItem, release: Callable) -> void :
	_nodes[node] = release
	_active_nodes[node] = release

func _create_warm_effect_tween(node: Node) -> Tween:
	for index: int in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween: Tween = node.create_tween()
	_tweens.append(tween)
	return tween

func reset_immediate() -> void :
	_warm_generation += 1
	_reset_nodes()

func _reset_nodes() -> void :
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	for node: CanvasItem in _active_nodes.keys():
		if is_instance_valid(node):
			_active_nodes[node].call()
	_active_nodes.clear()
	for emitter: GPUParticles2D in emitters:
		if is_instance_valid(emitter):
			(emitter.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()

func has_effects() -> bool:
	return not _active_nodes.is_empty()

func _exit_tree() -> void :
	reset_immediate()


func prepare_render(host: Node, active: Callable, full_warmup: bool, 
		checkpoint_factory: Callable = Callable()) -> bool:
	while preparing and active.call():
		await host.get_tree().process_frame
	if rendered or not active.call():
		return rendered and active.call()
	if DisplayServer.get_name() == "headless":
		return false
	var original_parent: Node = get_parent()
	var previous_layer: Node2D = _layer
	var viewport: = SubViewport.new()
	viewport.name = "SkinEffectsWarmupViewport"
	viewport.size = Vector2i(UiMetrics.viewport_size())
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if checkpoint_factory.is_valid() else SubViewport.UPDATE_ALWAYS
	host.add_child(viewport)
	reparent(viewport, false)
	bind_layer(self)
	var checkpoint: Callable = checkpoint_factory.call(viewport) if checkpoint_factory.is_valid() else Callable()

	for node: CanvasItem in _nodes.keys():
		if is_instance_valid(node) and node.get_parent() != self:
			node.reparent(self, false)
	var completed: bool = await warm_render(active, full_warmup, checkpoint)
	if is_instance_valid(original_parent):
		reparent(original_parent, false)
	else:
		_reset_nodes()
		viewport.queue_free()
		return false
	bind_layer(previous_layer if is_instance_valid(previous_layer) else self)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.queue_free()
	return completed and active.call()


func warm_render(active: Callable, full_warmup: bool, checkpoint: Callable = Callable()) -> bool:
	if rendered:
		return active.call()
	if DisplayServer.get_name() == "headless" or not active.call():
		return false
	reset_immediate()
	preparing = true
	_warm_generation += 1
	var generation: int = _warm_generation
	var guard: Callable = func() -> bool:
		return generation == _warm_generation and is_inside_tree() and active.call()
	var viewport: SubViewport = get_viewport() as SubViewport
	var center: Vector2 = Vector2(viewport.size) * 0.5
	var texture: Texture2D = skin_resources.mystery_particle_texture(0) if skin_resources != null else null
	var spawns: Array[Callable] = [
		_spawn_mystery_reveal_petals.bind(center, Color.WHITE, false, texture), 
		_spawn_mystery_reveal_glow.bind(center, Color.WHITE), 
		_spawn_mystery_reveal_flash.bind(center, Color.WHITE), 
		_spawn_mystery_reveal_star.bind(center, Color.WHITE), 
	]
	var stages: PackedStringArray = ["mystery_petals", "mystery_glow", "mystery_flash", "mystery_star"]
	var completed: bool = true
	for index: int in spawns.size():
		if stages[index] in _rendered_stages:
			continue
		if not guard.call() or (checkpoint.is_valid() and not await checkpoint.call(stages[index])):
			completed = false
			break
		NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:" + stages[index])
		spawns[index].call()
		for node: CanvasItem in _active_nodes.keys():
			if not node is GPUParticles2D:
				continue
			var emitter: GPUParticles2D = node as GPUParticles2D
			if not await (emitter.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).pre_render(guard, 0.12 if full_warmup else 0.0):
				completed = false
				break
		await RenderingServer.frame_post_draw
		completed = completed and guard.call()
		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:" + stages[index])
		if completed:
			_rendered_stages.append(stages[index])
		_reset_nodes()
		if not completed:
			break
	_reset_nodes()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for index: int in 2:
		await RenderingServer.frame_post_draw
	preparing = false
	rendered = completed and guard.call()
	return rendered






const MYSTERY_PETAL_TEX: Texture2D = preload("res://assets/effect/texture/point/ef_point_009.png")
const MYSTERY_PETAL_GRID: float = 6.0




const MYSTERY_PETAL_SIZE_REF_GRID: float = 2.0
const MYSTERY_PETAL_COUNT_MIN: = 5
const MYSTERY_PETAL_COUNT_MAX: = 8

const MYSTERY_PETAL_SPEED_MIN: = 104.0
const MYSTERY_PETAL_SPEED_MAX: = 234.0

const MYSTERY_PETAL_GRAVITY: = 60.0




const MYSTERY_PETAL_SPIN_MIN: = 90.0
const MYSTERY_PETAL_SPIN_MAX: = 180.0

const MYSTERY_PETAL_LIFETIME: = 1.0
const MYSTERY_PETAL_LIFETIME_RAND: = 0.3


const MYSTERY_PETAL_FADE_FROM: = 0.5




const MYSTERY_GLOW_TEX: Texture2D = preload("res://assets/effect/texture/glow/ef_ring_001.png")

const MYSTERY_GLOW_TOTAL_DUR: = 1.0
const MYSTERY_GLOW_FADE_IN_DUR: = 0.2

const MYSTERY_GLOW_ROT_SPEED_DEG: = 22.5

const MYSTERY_GLOW_SIZE_RATIO: = 1.5
const MYSTERY_GLOW_ALPHA_MAX: = 0.6


const MYSTERY_GLOW_YELLOW_REF: = Color("#FDDB2D")


const MYSTERY_GLOW_YELLOW_DARKEN: = 0.75




const MYSTERY_FLASH_TEX: Texture2D = preload("res://assets/effect/texture/glow/ef_glow_002.png")


const MYSTERY_FLASH_DUR: = 0.2
const MYSTERY_FLASH_HOLD_DUR: = 0.1

const MYSTERY_FLASH_SIZE_RATIO: = 2.0
const MYSTERY_FLASH_ALPHA_MAX: = 1.0




const MYSTERY_STAR_TEX: Texture2D = preload("res://assets/effect/texture/point/ef_point_004.png")


const MYSTERY_STAR_DUR: = 0.3


const MYSTERY_STAR_SIZE_RATIO: = 2.0
const MYSTERY_STAR_ALPHA_MAX: = 1.0


var _mystery_petal_ramp: GradientTexture1D = null
var _mystery_petal_pool: Array[GPUParticles2D] = []
var _mystery_petal_shader_mat: ShaderMaterial = null
var _mystery_glow_pool: Array[Sprite2D] = []
var _mystery_flash_pool: Array[Sprite2D] = []
var _mystery_flash_add_mat: CanvasItemMaterial = null
var _mystery_star_pool: Array[Sprite2D] = []
var _mystery_star_add_mat: CanvasItemMaterial = null

func _spawn_mystery_reveal_petals(pos: Vector2, tint: Color, coin_debris: bool = false, 
		skin_particle: Texture2D = null) -> void :
	var total: int = randi_range(MYSTERY_PETAL_COUNT_MIN, MYSTERY_PETAL_COUNT_MAX)
	var half: int = total / 2
	_fire_mystery_petals(pos, tint, half, MYSTERY_PETAL_SPIN_MIN, MYSTERY_PETAL_SPIN_MAX, coin_debris, skin_particle)
	_fire_mystery_petals(pos, tint, total - half, - MYSTERY_PETAL_SPIN_MAX, - MYSTERY_PETAL_SPIN_MIN, coin_debris, skin_particle)




func _fire_mystery_petals(pos: Vector2, tint: Color, amount: int, 
		spin_min: float, spin_max: float, coin_debris: bool = false, skin_particle: Texture2D = null) -> void :
	if amount <= 0:
		return
	var p: GPUParticles2D = _acquire_mystery_petal_emitter()
	if p == null:
		return
	var pm: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial


	p.texture = skin_particle if skin_particle != null else (bonus_coin_texture if coin_debris else effect_texture(&"mystery_petal", MYSTERY_PETAL_TEX))
	p.material = null if coin_debris or skin_particle != null else _ensure_mystery_petal_shader_mat()
	p.global_position = pos
	p.amount = amount
	p.lifetime = MYSTERY_PETAL_LIFETIME
	pm.lifetime_randomness = MYSTERY_PETAL_LIFETIME_RAND
	p.one_shot = true
	p.explosiveness = 1.0

	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = fruit_d * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO * 0.5
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = MYSTERY_PETAL_SPEED_MIN
	pm.initial_velocity_max = MYSTERY_PETAL_SPEED_MAX


	pm.gravity = Vector3(0.0, MYSTERY_PETAL_GRAVITY, 0.0)




	pm.angular_velocity_min = spin_min
	pm.angular_velocity_max = spin_max







	var cell_px: float = maxf(1.0, float(effect_texture(&"mystery_petal", MYSTERY_PETAL_TEX).get_width()) / MYSTERY_PETAL_SIZE_REF_GRID)
	if skin_particle != null:
		cell_px = float(skin_particle.get_width())
	var s: float = _petal_size / cell_px
	if skin_particle != null and skin_resources != null:
		s *= skin_resources.mystery_particle_size_correction(skin_particle)
	if coin_debris:

		pm.scale_min = 40.0 / float(bonus_coin_texture.get_width())
		pm.scale_max = 58.0 / float(bonus_coin_texture.get_width())
	else:
		pm.scale_min = s * _petal_min_ratio
		pm.scale_max = s * _petal_max_ratio







	pm.anim_speed_min = 0.0 if skin_particle != null else 0.15
	pm.anim_speed_max = 0.0 if skin_particle != null else 0.15
	pm.anim_offset_min = 0.0
	pm.anim_offset_max = 1.0
	pm.color_ramp = _ensure_mystery_petal_ramp()

	p.modulate = Color.WHITE if coin_debris or skin_particle != null else tint
	(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).play()



func _ensure_mystery_petal_shader_mat() -> ShaderMaterial:
	if _mystery_petal_shader_mat == null:
		_mystery_petal_shader_mat = ShaderMaterial.new()
		_mystery_petal_shader_mat.shader = preload(
			"res://assets/effect/shader/particle_atlas_cell.gdshader")
		_mystery_petal_shader_mat.set_shader_parameter("h_frames", MYSTERY_PETAL_GRID)
		_mystery_petal_shader_mat.set_shader_parameter("v_frames", MYSTERY_PETAL_GRID)
	return _mystery_petal_shader_mat





func _acquire_mystery_petal_emitter() -> GPUParticles2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var p: GPUParticles2D
	if not _mystery_petal_pool.is_empty():
		p = _mystery_petal_pool.pop_back()
	else:
		p = GPUParticles2D.new()
		p.visible = false
		p.emitting = false
		p.visibility_rect = Rect2(-1400, -1400, 2800, 2800)
		p.texture = effect_texture(&"mystery_petal", MYSTERY_PETAL_TEX)
		p.material = _ensure_mystery_petal_shader_mat()
		var pm: = ParticleProcessMaterial.new()
		pm.particle_flag_disable_z = true
		p.process_material = pm


		p.z_index = _flower_z - 1
		p.local_coords = false
		p.finished.connect(_release_mystery_petal_emitter.bind(p))
	if not p.has_meta(&"skin_lifecycle"):
		var lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
		lifecycle.prepare([p], 2, _render_ready)
		p.set_meta(&"skin_lifecycle", lifecycle)
		emitters.append(p)
	else:
		(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
	if p.get_parent() != layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		layer.add_child(p)
	_track_warm_effect(p, _release_mystery_petal_emitter.bind(p))
	return p


func _release_mystery_petal_emitter(p: GPUParticles2D) -> void :
	_active_nodes.erase(p)
	if p == null or not is_instance_valid(p) or _mystery_petal_pool.has(p):
		return
	(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
	_mystery_petal_pool.append(p)




func _ensure_mystery_petal_ramp() -> GradientTexture1D:
	if _mystery_petal_ramp == null:
		var g: = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, MYSTERY_PETAL_FADE_FROM, 1.0])
		g.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), 
		])
		_mystery_petal_ramp = GradientTexture1D.new()
		_mystery_petal_ramp.gradient = g
	return _mystery_petal_ramp




func _spawn_mystery_reveal_glow(pos: Vector2, tint: Color) -> void :
	var g: Sprite2D = _acquire_mystery_glow()
	if g == null:
		return
	g.global_position = pos
	g.rotation = 0.0

	var glow_color: Color = tint
	if tint.is_equal_approx(MYSTERY_GLOW_YELLOW_REF):
		glow_color = Color(tint.r * MYSTERY_GLOW_YELLOW_DARKEN, tint.g * MYSTERY_GLOW_YELLOW_DARKEN, 
			tint.b * MYSTERY_GLOW_YELLOW_DARKEN, tint.a)
	g.modulate = Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
	var diameter: float = fruit_d * MYSTERY_GLOW_SIZE_RATIO
	var tex_w: float = maxf(1.0, float(effect_texture(&"mystery_glow", MYSTERY_GLOW_TEX).get_width()))
	g.scale = Vector2.ONE * (diameter / tex_w)
	g.visible = true

	var tw: = _create_warm_effect_tween(g)
	tw.tween_property(g, "modulate:a", MYSTERY_GLOW_ALPHA_MAX, MYSTERY_GLOW_FADE_IN_DUR)
	tw.tween_property(g, "modulate:a", 0.0, MYSTERY_GLOW_TOTAL_DUR - MYSTERY_GLOW_FADE_IN_DUR)
	tw.tween_callback(_release_mystery_glow.bind(g))



	var spin_tw: = _create_warm_effect_tween(g)
	spin_tw.tween_property(g, "rotation", 
		deg_to_rad(MYSTERY_GLOW_ROT_SPEED_DEG) * MYSTERY_GLOW_TOTAL_DUR, 
		MYSTERY_GLOW_TOTAL_DUR).set_trans(Tween.TRANS_LINEAR)



func _acquire_mystery_glow() -> Sprite2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var g: Sprite2D
	if not _mystery_glow_pool.is_empty():
		g = _mystery_glow_pool.pop_back()
	else:
		g = Sprite2D.new()
		g.texture = effect_texture(&"mystery_glow", MYSTERY_GLOW_TEX)






	if g.get_parent() != layer:
		if g.get_parent() != null:
			g.get_parent().remove_child(g)
		layer.add_child(g)
	layer.move_child(g, 0)
	_track_warm_effect(g, _release_mystery_glow.bind(g))
	return g


func _release_mystery_glow(g: Sprite2D) -> void :
	_active_nodes.erase(g)
	if g == null or not is_instance_valid(g) or _mystery_glow_pool.has(g):
		return
	g.visible = false
	_mystery_glow_pool.append(g)





func _spawn_mystery_reveal_flash(pos: Vector2, tint: Color) -> void :
	var g: Sprite2D = _acquire_mystery_flash()
	if g == null:
		return
	g.global_position = pos
	g.modulate = Color(tint.r, tint.g, tint.b, MYSTERY_FLASH_ALPHA_MAX)
	var diameter: float = fruit_d * MYSTERY_FLASH_SIZE_RATIO
	var tex_w: float = maxf(1.0, float(effect_texture(&"mystery_flash", MYSTERY_FLASH_TEX).get_width()))
	g.scale = Vector2.ONE * (diameter / tex_w)
	g.visible = true

	var tw: = _create_warm_effect_tween(g)
	tw.tween_interval(MYSTERY_FLASH_HOLD_DUR)
	tw.tween_property(g, "modulate:a", 0.0, MYSTERY_FLASH_DUR - MYSTERY_FLASH_HOLD_DUR)
	tw.tween_callback(_release_mystery_flash.bind(g))










func _acquire_mystery_flash() -> Sprite2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var g: Sprite2D
	if not _mystery_flash_pool.is_empty():
		g = _mystery_flash_pool.pop_back()
	else:
		g = Sprite2D.new()
		g.texture = effect_texture(&"mystery_flash", MYSTERY_FLASH_TEX)
		g.material = _ensure_mystery_flash_add_mat()
	if g.get_parent() != layer:
		if g.get_parent() != null:
			g.get_parent().remove_child(g)
		layer.add_child(g)
	layer.move_child(g, layer.get_child_count() - 1)
	_track_warm_effect(g, _release_mystery_flash.bind(g))
	return g


func _release_mystery_flash(g: Sprite2D) -> void :
	_active_nodes.erase(g)
	if g == null or not is_instance_valid(g) or _mystery_flash_pool.has(g):
		return
	g.visible = false
	_mystery_flash_pool.append(g)



func _ensure_mystery_flash_add_mat() -> CanvasItemMaterial:
	if _mystery_flash_add_mat == null:
		_mystery_flash_add_mat = CanvasItemMaterial.new()
		_mystery_flash_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _mystery_flash_add_mat





func _spawn_mystery_reveal_star(pos: Vector2, tint: Color) -> void :
	var g: Sprite2D = _acquire_mystery_star()
	if g == null:
		return
	g.global_position = pos
	g.rotation = 0.0
	g.modulate = Color(tint.r, tint.g, tint.b, MYSTERY_STAR_ALPHA_MAX)
	var diameter: float = fruit_d * MYSTERY_STAR_SIZE_RATIO
	var tex_w: float = maxf(1.0, float(effect_texture(&"mystery_star", MYSTERY_STAR_TEX).get_width()))
	g.scale = Vector2.ONE * (diameter / tex_w)
	g.visible = true

	var tw: = _create_warm_effect_tween(g)
	tw.tween_property(g, "modulate:a", 0.0, MYSTERY_STAR_DUR)
	tw.tween_callback(_release_mystery_star.bind(g))





func _acquire_mystery_star() -> Sprite2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var g: Sprite2D
	if not _mystery_star_pool.is_empty():
		g = _mystery_star_pool.pop_back()
	else:
		g = Sprite2D.new()
		g.texture = effect_texture(&"mystery_star", MYSTERY_STAR_TEX)
		g.material = _ensure_mystery_star_add_mat()
	if g.get_parent() != layer:
		if g.get_parent() != null:
			g.get_parent().remove_child(g)
		layer.add_child(g)
	layer.move_child(g, layer.get_child_count() - 1)
	_track_warm_effect(g, _release_mystery_star.bind(g))
	return g


func _release_mystery_star(g: Sprite2D) -> void :
	_active_nodes.erase(g)
	if g == null or not is_instance_valid(g) or _mystery_star_pool.has(g):
		return
	g.visible = false
	_mystery_star_pool.append(g)



func _ensure_mystery_star_add_mat() -> CanvasItemMaterial:
	if _mystery_star_add_mat == null:
		_mystery_star_add_mat = CanvasItemMaterial.new()
		_mystery_star_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _mystery_star_add_mat
