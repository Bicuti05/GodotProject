class_name RewardLayer
extends Control

const RAINBOW_EMISSION_POINTS_PATH: String = "res://assets/sprites/finish/rainbow_emission_points.tres"




























const TITLE_OUTLINE_SIZE: int = 32

const TITLE_SHADOW_BLUR: int = 24
const TITLE_SHADOW_OFFSET: = Vector2i(0, 4)




const TITLE_FILL_NORMAL: Array[Color] = [
	Color(1.0, 1.0, 1.0), 
	Color(0.769, 0.871, 0.933), 
	Color(0.008, 0.314, 0.82), 
]
const TITLE_OUTLINE_NORMAL: Array[Color] = [
	Color(0, 0, 0, 0), 
	Color(0.212, 0.51, 1.0), 
	Color(0.008, 0.314, 0.82), 
]
const TITLE_SHADOW: = Color(0.0, 0.0, 0.0, 0.6)
const TITLE_FILL_HARD: Array[Color] = [
	Color(1.0, 0.957, 0.475), 
	Color(0.996, 0.643, 0.38), 
	Color(0.765, 0.278, 0.278), 
]
const TITLE_OUTLINE_HARD: Array[Color] = [
	Color(0, 0, 0, 0), 
	Color(0.957, 0.337, 0.337), 
	Color(0.765, 0.278, 0.278), 
]



const TITLE_FILL_SUPER_HARD: Array[Color] = [
	Color(0.957, 0.867, 1.0), 
	Color(0.769, 0.537, 0.953), 
	Color(0.416, 0.2, 0.69), 
]
const TITLE_OUTLINE_SUPER_HARD: Array[Color] = [
	Color(0, 0, 0, 0), 
	Color(0.553, 0.318, 0.894), 
	Color(0.416, 0.2, 0.69), 
]


const FLOWER_CENTER_Y: float = 1153.0

const RAYS_SPIN_PERIOD: float = 24.0

const RAYS_FADE_IN_DUR: float = 0.3

const CORE_BREATH_MIN: float = 0.94
const CORE_BREATH_MAX: float = 1.06
const CORE_BREATH_DUR: float = 1.3





const TITLE_PRAISE_KEYS: Array[String] = [
	"FINISH_PRAISE_EXCELLENT", "FINISH_PRAISE_AMAZING", "FINISH_PRAISE_FANTASTIC", 
	"FINISH_PRAISE_BRILLIANT", "FINISH_PRAISE_PERFECT", "FINISH_PRAISE_FLAWLESS", 
	"FINISH_PRAISE_OUTSTANDING", "FINISH_PRAISE_SUPERB", "FINISH_PRAISE_AWESOME", 
	"FINISH_PRAISE_IMPRESSIVE", "FINISH_PRAISE_UNSTOPPABLE", "FINISH_PRAISE_ON_FIRE", 
]

const TITLE_POP_FROM: float = 0.62
const TITLE_POP_DUR: float = 0.44

const BASKET_ANIM_INTO: String = "Appear"
const BASKET_ANIM_LOOP: String = "Loop"

const BASKET_SCALE: float = 0.684096

const BASKET_BASE_Y: float = 1052.02

const BASKET_INTO_DUR: float = 2.6667
const FADE_IN_DUR: float = 0.28

const APPEAR_DUR: float = BASKET_INTO_DUR
const BASKET_ANIM_OUT: String = "Disappear"
const DISAPPEAR_DUR: float = 1.6333
const TITLE_APPEAR_DELAY: float = 0.2
const RAINBOW_APPEAR_DELAY: float = 0.1
const RAINBOW_APPEAR_DUR: float = 0.35
const RAINBOW_SWEEP_DUR: float = 0.85
const RAINBOW_SWEEP_GAP: float = 4.0
const TITLE_EXIT_DELAY: float = 0.1
const TITLE_EXIT_DUR: float = 0.2













const PARTICLE_Y_OFFSET: float = -100.0




const BUTTERFLY_BBOX_W_ORANGE: float = 560.9912
const BUTTERFLY_BBOX_W_RED: float = 583.082
const BUTTERFLY_BBOX_W_GREEN: float = 597.55

const BUTTERFLY_TARGET_W: float = 65.0

const BUTTERFLY_ANIM: String = "animation"

const BUTTERFLY_ARRIVE_DUR: float = 0.85
const BUTTERFLY_FADE_DUR: float = 0.25
const BUTTERFLY_HOVER_RISE: float = 24.0
const PARTICLE_EXIT_FADE_DUR: float = 0.35
const RAINBOW_TITLE_WIDTH_RATIO: float = 1.344
const RAINBOW_HEIGHT_RATIO: float = 0.48

const RAINBOW_BAND_CENTER_Y: float = 368.17

@onready var _fx: Node2D = $Fx
@onready var _rays: Sprite2D = $Fx / GlowRays
@onready var _core: Sprite2D = $Fx / GlowCore
@onready var _basket: SpineSprite = $Fx / Basket
var _wheel_trails: Array[GPUParticles2D] = []
@onready var _rainbow: Sprite2D = $Fx / Rainbow
@onready var _rainbow_material: ShaderMaterial = $Fx / Rainbow.material as ShaderMaterial
var _rainbow_sparkles: GPUParticles2D
var _rear_wheels: Array[SpineBone] = []
var _flower_bones: Array[SpineBone] = []
var _rainbow_source_points: = PackedVector2Array()
var _rainbow_points_ready: bool = false
var _rainbow_point_image: Image
var _rainbow_point_texture: ImageTexture
var _flower_point_image: Image
var _flower_point_texture: ImageTexture
var _presentation_generation: int = 0

var _pot_drop_haptic: int = 0

var haptic_style: int = 0

var cart_appear_sound_id: StringName = &"finish_cart_appear"
var _active_cart_appear_sound_id: StringName = &"finish_cart_appear"
var _cart_phase: int = 0
var _wheel_previous: PackedVector2Array = PackedVector2Array()

const CART_SCREEN_MARGIN: float = 110.0
const CART_ENTRY_TRAVEL: float = 1316.97
const CART_EXIT_TRAVEL: float = 1388.85
var _entry_bone: SpineBone
var _exit_bone: SpineBone
var _entry_base_x: float = 0.0
var _exit_base_x: float = 0.0
var _pot_staging: Array[Dictionary] = []



@onready var _butterfly_orange: SpineSprite = $Fx / ButterflyOrange
@onready var _butterfly_red: SpineSprite = $Fx / ButterflyRed
@onready var _butterfly_green: SpineSprite = $Fx / ButterflyGreen
@onready var _title_layers: Array[CurveLabel] = [
	$TitleTop, $TitleMid, $TitleBottom, 
]

var _particles: Array[GPUParticles2D] = []


var _core_base_scale: Vector2 = Vector2.ONE


var _active_tweens: Array[Tween] = []



var _butterflies: Array[Dictionary] = []


func _ready() -> void :
	visible = false
	_core_base_scale = _core.scale
	_build_particles()
	_build_cart_emitters()
	_build_cart_staging()
	_apply_skin(false)
	get_viewport().size_changed.connect(_layout)
	_layout()
	process_priority = 10
	set_process(true)



func _process(delta: float) -> void :
	_update_cart_emitters(delta)
	if _cart_phase not in [2, 3]:
		return
	for butterfly: Dictionary in _butterflies:
		var node: SpineSprite = butterfly["node"]
		if not is_instance_valid(node):
			continue
		if _cart_phase == 3:

			node.position = _bone_in_fx(butterfly["bone"] as SpineBone) + (butterfly["carry_offset"] as Vector2)
			continue
		butterfly["age"] = float(butterfly["age"]) + delta
		var elapsed: float = float(butterfly["age"])
		var progress: float = clampf(elapsed / BUTTERFLY_ARRIVE_DUR, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - progress, 3.0)
		var target: Vector2 = _butterfly_flower_position(butterfly)
		var hover: float = sin(elapsed * 2.4 + float(butterfly["phase"])) * 3.0
		node.position = (butterfly["start"] as Vector2).lerp(target, eased) + Vector2(0.0, hover * eased)


var _particle_lifecycles: Dictionary = {}
var _particle_dependencies_injected: bool = false


func prepare_cached_dependencies() -> void :
	if _particle_dependencies_injected:
		return
	var names: Array[String] = ["WheelTrailLeft", "WheelTrailRight"]
	names.append_array(["RainbowSparkles", "FlowerSparkle", "FlowerDot"])
	FinishParticleCache.inject("reward", get_node("Fx"), names)
	_particle_dependencies_injected = true


func _build_particles() -> void :
	prepare_cached_dependencies()
	_wheel_trails.assign([$Fx / WheelTrailLeft, $Fx / WheelTrailRight])
	_rainbow_sparkles = $Fx / RainbowSparkles
	_particles.assign([$Fx / FlowerSparkle, $Fx / FlowerDot])
	var all: Array[GPUParticles2D] = []
	all.append_array(_wheel_trails)
	all.append_array(_particles)
	if _rainbow_sparkles != null:
		all.append(_rainbow_sparkles)
	for emitter: GPUParticles2D in all:
		var lifecycle: = GpuParticleLifecycle.new()
		lifecycle.prepare([emitter], 2, func() -> bool:
			return is_visible_in_tree() and _cart_phase != 0)
		lifecycle.reset_immediate()
		_particle_lifecycles[emitter] = lifecycle


func _particle_lifecycle(emitter: GPUParticles2D) -> GpuParticleLifecycle:
	return _particle_lifecycles[emitter] as GpuParticleLifecycle



func _layout() -> void :
	_fx.position = Vector2(UiMetrics.center_x(), 0.0)
	_layout_rainbow()
	if _cart_phase != 2:
		for particle: GPUParticles2D in _particles:
			particle.position = Vector2(0.0, FLOWER_CENTER_Y + PARTICLE_Y_OFFSET)


func _layout_rainbow() -> void :
	var title: CurveLabel = _title_layers[0]
	var texture_size: Vector2 = _rainbow.texture.get_size()
	_rainbow.scale = Vector2(title.size.x * RAINBOW_TITLE_WIDTH_RATIO / texture_size.x, RAINBOW_HEIGHT_RATIO)
	var middle_baseline: float = title.position.y + title.size.y * 0.5 - title.amplitude
	var glyph_center: float = middle_baseline - float(title.get_theme_font_size("font_size")) * 0.4
	_rainbow.position = Vector2(title.position.x + title.size.x * 0.5 - _fx.position.x, 
		glyph_center + (texture_size.y * 0.5 - RAINBOW_BAND_CENTER_Y) * _rainbow.scale.y + 16.0)
	if _rainbow_point_image != null:
		for i: int in _rainbow_source_points.size():
			var point: Vector2 = _rainbow_source_points[i] * _rainbow.scale + _rainbow.position
			_rainbow_point_image.set_pixel(i, 0, Color(point.x, point.y, 0.0))
		_rainbow_point_texture.update(_rainbow_point_image)
	if _rainbow_sparkles != null:
		_rainbow_sparkles.position = Vector2.ZERO



func _apply_skin(is_hard: bool, is_super_hard: bool = false) -> void :
	var fills: Array[Color] = TITLE_FILL_NORMAL
	var outlines: Array[Color] = TITLE_OUTLINE_NORMAL
	if is_super_hard:
		fills = TITLE_FILL_SUPER_HARD
		outlines = TITLE_OUTLINE_SUPER_HARD
	elif is_hard:
		fills = TITLE_FILL_HARD
		outlines = TITLE_OUTLINE_HARD
	for i: int in _title_layers.size():
		var lb: CurveLabel = _title_layers[i]
		lb.add_theme_color_override(&"font_color", fills[i])
		lb.add_theme_color_override(&"font_outline_color", outlines[i])
		lb.add_theme_constant_override(&"outline_size", 
			0 if outlines[i].a <= 0.0 else TITLE_OUTLINE_SIZE)

		var is_bottom: bool = i == _title_layers.size() - 1
		lb.add_theme_color_override(&"font_shadow_color", 
			TITLE_SHADOW if is_bottom else Color(0, 0, 0, 0))
		lb.add_theme_constant_override(&"shadow_outline_size", 
			TITLE_SHADOW_BLUR if is_bottom else 0)
		lb.add_theme_constant_override(&"shadow_offset_x", TITLE_SHADOW_OFFSET.x)
		lb.add_theme_constant_override(&"shadow_offset_y", TITLE_SHADOW_OFFSET.y)




func play_appear(is_hard: bool, is_super_hard: bool = false) -> void :
	reset()
	_cart_phase = 1
	_active_cart_appear_sound_id = cart_appear_sound_id
	AudioManager.play_sfx(_active_cart_appear_sound_id)
	_apply_skin(is_hard, is_super_hard)
	var title_key: String = TITLE_PRAISE_KEYS.pick_random()
	for lb: CurveLabel in _title_layers:
		lb.text = title_key
	_layout()

	modulate.a = 0.0
	var tw_self: = create_tween()
	_track_tween(tw_self)
	tw_self.tween_property(self, "modulate:a", 1.0, FADE_IN_DUR)

	for lb: CurveLabel in _title_layers:
		lb.pivot_offset = lb.size * 0.5
		lb.modulate.a = 0.0
		lb.scale = Vector2.ONE * TITLE_POP_FROM
		var tw: = lb.create_tween()
		_track_tween(tw)
		tw.tween_interval(TITLE_APPEAR_DELAY)
		tw.tween_property(lb, "modulate:a", 1.0, TITLE_POP_DUR)
		tw.parallel().tween_property(lb, "scale", Vector2.ONE, TITLE_POP_DUR)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)




	var skeleton: SpineSkeleton = _basket.get_skeleton()
	var anim: SpineAnimationState = _basket.get_animation_state()
	if anim != null:
		anim.clear_tracks()
		if skeleton != null:
			skeleton.set_to_setup_pose()
		var entry: SpineTrackEntry = anim.set_animation(BASKET_ANIM_INTO, false, 0)

		if entry != null and haptic_style > 0:
			_pot_drop_haptic = HapticManager.play_event(HapticProfiles.shake_event_for(HapticProfiles.Event.FINISH_POT_DROP, haptic_style))
		anim.add_animation(BASKET_ANIM_LOOP, 0, true, 0)

		if skeleton != null:
			anim.update(0.0)
			anim.apply(skeleton)
			_adapt_cart_staging(_basket)
			skeleton.update_world_transform(SpineConstant.Physics_Update)
	_disable_cart_clipping()
	visible = true

	_basket.update_skeleton(0.0)
	_start_cart_appear_effects()




	_reset_butterflies()


	_rays.modulate.a = 0.0
	_rays.rotation = 0.0
	_core.modulate.a = 0.0


	var idle: Tween = create_tween()
	_track_tween(idle)
	idle.tween_interval(APPEAR_DUR)
	idle.tween_callback(_start_cart_idle)




func warm_render_pipeline() -> void :

	await prepare_render_points()

	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:reward_title")
	reset()
	visible = true
	modulate.a = 1.0
	_fx.visible = false
	for lb: CurveLabel in _title_layers:
		lb.visible = true
	await RenderingServer.frame_post_draw

	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:reward_title")

	for lb: CurveLabel in _title_layers:
		lb.visible = false


	_rays.visible = false
	_core.visible = false
	_basket.visible = false
	for p: GPUParticles2D in _particles:
		p.visible = false
	_fx.visible = true
	_prepare_cart_warm_pose()
	_rays.modulate.a = 1.0


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:reward_rays_core")
	_rays.visible = true
	_core.visible = true
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:reward_rays_core")


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:reward_cart")
	_basket.visible = true
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:reward_cart")


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:reward_rainbow")
	_rainbow.visible = true
	_rainbow.modulate.a = 1.0
	_rainbow_material.set_shader_parameter("sweep_progress", 0.5)
	await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:reward_rainbow")

	var all: Array[GPUParticles2D] = []
	all.append_array(_particles)
	all.append_array(_wheel_trails)
	if _rainbow_sparkles != null:
		all.append(_rainbow_sparkles)
	for emitter: GPUParticles2D in all:
		await _particle_lifecycle(emitter).pre_render( func() -> bool: return is_inside_tree())
	reset()


func _prepare_cart_warm_pose() -> void :
	var skeleton: SpineSkeleton = _basket.get_skeleton()
	var animation: SpineAnimationState = _basket.get_animation_state()
	animation.clear_tracks()
	skeleton.set_to_setup_pose()
	animation.set_animation(BASKET_ANIM_LOOP, true, 0)
	animation.update(0.0)
	animation.apply(skeleton)
	_disable_cart_clipping()
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	_cart_phase = 2
	_update_cart_emitters(0.0)
	_start_butterflies(false)



func _start_butterflies(animate: bool = true) -> void :
	_reset_butterflies()
	var skeleton: SpineSkeleton = _basket.get_skeleton()
	var specs: Array[Dictionary] = [
		{"node": _butterfly_orange, "slot": "1_flower_1", "bbox_w": BUTTERFLY_BBOX_W_ORANGE, "side": -1.0}, 
		{"node": _butterfly_red, "slot": "4_flower_5", "bbox_w": BUTTERFLY_BBOX_W_RED, "side": -1.0}, 
		{"node": _butterfly_green, "slot": "1_flower_6", "bbox_w": BUTTERFLY_BBOX_W_GREEN, "side": 1.0}, 
	]
	for i: int in specs.size():
		var spec: Dictionary = specs[i]
		var node: SpineSprite = spec["node"]
		var slot: SpineSlot = skeleton.find_slot(str(spec["slot"]))
		if slot == null:
			SortLogger.error("Finish cart butterfly flower attachment missing: " + str(spec["slot"]))
			continue
		var side: float = float(spec["side"])
		var base_scale: float = BUTTERFLY_TARGET_W / float(spec["bbox_w"])
		node.scale = Vector2(base_scale * (-1.0 if side > 0.0 else 1.0), base_scale)
		var animation: SpineAnimationState = node.get_animation_state()
		var butterfly_skeleton: SpineSkeleton = node.get_skeleton()
		animation.clear_tracks()
		butterfly_skeleton.set_to_setup_pose()
		animation.set_animation(BUTTERFLY_ANIM, true, 0)
		animation.update(0.0)
		animation.apply(butterfly_skeleton)
		butterfly_skeleton.update_world_transform(SpineConstant.Physics_Update)
		var bounds: Rect2 = butterfly_skeleton.get_bounds()
		var entry: Dictionary = {"node": node, "bone": slot.get_bone(), "side": side, 
			"center_offset": bounds.get_center() * node.scale, "phase": float(i) * 1.6, "age": 0.0}
		var target: Vector2 = _butterfly_flower_position(entry)
		entry["start"] = target + Vector2(side * 120.0, -85.0)
		node.position = entry["start"]
		node.modulate.a = 0.0
		node.visible = true
		_butterflies.append(entry)
		if not animate:
			entry["age"] = BUTTERFLY_ARRIVE_DUR
			node.position = target
			node.modulate.a = 1.0
			continue
		var fade: Tween = node.create_tween()
		_track_tween(fade)
		fade.tween_property(node, "modulate:a", 1.0, BUTTERFLY_FADE_DUR)


func _butterfly_flower_position(entry: Dictionary) -> Vector2:
	return _bone_in_fx(entry["bone"] as SpineBone) - (entry["center_offset"] as Vector2) + Vector2(float(entry["side"]) * 8.0, - BUTTERFLY_HOVER_RISE)



func _carry_butterflies_with_cart() -> void :
	for butterfly: Dictionary in _butterflies:
		var node: SpineSprite = butterfly["node"]
		butterfly["carry_offset"] = node.position - _bone_in_fx(butterfly["bone"] as SpineBone)

		if node.modulate.a < 1.0:
			var finish_fade: Tween = node.create_tween()
			_track_tween(finish_fade)
			finish_fade.tween_property(node, "modulate:a", 1.0, 0.15)


func _fade_particles(particle: GPUParticles2D, duration: float) -> void :
	_particle_lifecycle(particle).stop_with_tail()
	var fade: Tween = particle.create_tween()
	_track_tween(fade)
	fade.tween_property(particle, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func _reset_butterflies() -> void :
	_butterflies.clear()
	for node: SpineSprite in [_butterfly_orange, _butterfly_red, _butterfly_green]:
		if not is_instance_valid(node):
			continue
		node.visible = false
		node.modulate.a = 0.0
		var anim: = node.get_animation_state()
		if anim != null:
			anim.clear_tracks()


func _track_tween(tween: Tween) -> void :
	_active_tweens.append(tween)


func _kill_active_tweens() -> void :
	for tween: Tween in _active_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_active_tweens.clear()



func fade_out(dur: float) -> void :
	_cancel_pot_drop_haptic()
	AudioManager.stop_sfx(_active_cart_appear_sound_id)
	AudioManager.stop_sfx(&"finish_cart_exit")
	if not visible:
		return
	for p: GPUParticles2D in _particles:
		_particle_lifecycle(p).stop_with_tail()
	var tw: = create_tween()
	_track_tween(tw)
	tw.tween_property(self, "modulate:a", 0.0, dur)
	tw.tween_callback( func() -> void : visible = false)



func _cancel_pot_drop_haptic() -> void :
	HapticManager.cancel_event(_pot_drop_haptic)
	_pot_drop_haptic = 0


func _exit_tree() -> void :
	_cancel_pot_drop_haptic()
	AudioManager.stop_sfx(_active_cart_appear_sound_id)
	AudioManager.stop_sfx(&"finish_cart_exit")


func reset() -> void :
	_cancel_pot_drop_haptic()
	AudioManager.stop_sfx(_active_cart_appear_sound_id)
	AudioManager.stop_sfx(&"finish_cart_exit")
	_presentation_generation += 1
	_cart_phase = 0
	_kill_active_tweens()
	_rainbow.visible = false
	_rainbow.modulate.a = 0.0
	_rainbow_material.set_shader_parameter("sweep_progress", -1.0)
	for emitter: GPUParticles2D in _particle_lifecycles:
		_particle_lifecycle(emitter).reset_immediate()
		_particle_lifecycle(emitter).set_opacity(1.0)
		emitter.modulate.a = 1.0
	_wheel_previous.clear()
	modulate.a = 1.0
	for lb: CurveLabel in _title_layers:
		lb.visible = true
		lb.modulate.a = 1.0
		lb.scale = Vector2.ONE
	_fx.visible = true


	var anim: = _basket.get_animation_state()
	if anim != null:
		anim.clear_tracks()
	_basket.position.y = BASKET_BASE_Y
	_reset_butterflies()
	_core.scale = _core_base_scale
	_core.modulate.a = 1.0
	_rays.rotation = 0.0
	_rays.modulate.a = 1.0
	visible = false




static func _emission_point_format() -> Image.Format:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return Image.FORMAT_RGBH
	return Image.FORMAT_RGBF



func _build_cart_emitters() -> void :
	_rear_wheels.clear()
	_flower_bones.clear()
	var skeleton: SpineSkeleton = _basket.get_skeleton()
	if skeleton != null:
		for name: String in ["car2", "car6"]:
			var bone: SpineBone = skeleton.find_bone(name)
			if bone != null:
				_rear_wheels.append(bone)

		for slot: SpineSlot in skeleton.get_slots():
			if str(slot.get_data().get_name()).contains("flower_"):
				var bone: SpineBone = slot.get_bone()
				if bone != null and str(slot.get_data().get_name()) != "4_flower_1":
					_flower_bones.append(bone)
	if not _flower_bones.is_empty():
		if _flower_point_image == null or _flower_point_image.get_width() != _flower_bones.size():
			_flower_point_image = Image.create(_flower_bones.size(), 1, false, _emission_point_format())
			_flower_point_texture = ImageTexture.create_from_image(_flower_point_image)
		for particle: GPUParticles2D in _particles:
			var pm: ParticleProcessMaterial = particle.process_material as ParticleProcessMaterial
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
			pm.emission_point_count = _flower_bones.size()
			pm.emission_point_texture = _flower_point_texture



func prepare_render_points() -> void :
	if _rainbow_points_ready:
		return
	_rainbow_source_points = (load(RAINBOW_EMISSION_POINTS_PATH) as Resource).get_meta("points")
	_rainbow_point_image = Image.create(_rainbow_source_points.size(), 1, false, _emission_point_format())
	_rainbow_point_texture = ImageTexture.create_from_image(_rainbow_point_image)
	var pm: ParticleProcessMaterial = _rainbow_sparkles.process_material as ParticleProcessMaterial
	pm.emission_point_count = _rainbow_source_points.size()
	pm.emission_point_texture = _rainbow_point_texture
	_layout_rainbow()
	_rainbow_points_ready = true


func _start_cart_appear_effects() -> void :
	_update_cart_emitters(0.0)
	_start_cart_particles(_wheel_trails)
	_rainbow.visible = true
	_rainbow.modulate.a = 0.0
	var reveal: Tween = create_tween()
	_track_tween(reveal)
	reveal.tween_interval(RAINBOW_APPEAR_DELAY)
	reveal.tween_property(_rainbow, "modulate:a", 1.0, RAINBOW_APPEAR_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reveal.tween_callback(_start_rainbow_sparkles)
	var sweep: Tween = create_tween()
	_track_tween(sweep)
	sweep.set_loops()
	sweep.tween_interval(RAINBOW_APPEAR_DELAY + RAINBOW_APPEAR_DUR)
	sweep.tween_method(_set_rainbow_sweep, 0.0, 1.0, RAINBOW_SWEEP_DUR)
	sweep.tween_callback(_set_rainbow_sweep.bind(-1.0))
	sweep.tween_interval(RAINBOW_SWEEP_GAP)


func _set_rainbow_sweep(value: float) -> void :
	_rainbow_material.set_shader_parameter("sweep_progress", value)


func _start_rainbow_sparkles() -> void :
	var generation: int = _presentation_generation
	await prepare_render_points()
	if generation != _presentation_generation or _cart_phase not in [1, 2]:
		return
	_start_cart_particles([_rainbow_sparkles])


func _start_cart_idle() -> void :
	_cart_phase = 2
	_start_idle_background_light()
	_start_butterflies()
	for trail: GPUParticles2D in _wheel_trails:
		_particle_lifecycle(trail).stop_with_tail()
	_update_cart_emitters(0.0)
	_start_flower_particles()



func _start_flower_particles() -> void :
	_start_cart_particles(_particles)



func _start_cart_particles(particles: Array[GPUParticles2D]) -> void :
	for emitter: GPUParticles2D in particles:
		_particle_lifecycle(emitter).set_opacity(1.0)
		_particle_lifecycle(emitter).play()


func _bone_in_fx(bone: SpineBone) -> Vector2:
	return _fx.to_local(_basket.to_global(Vector2(bone.get_world_x(), bone.get_world_y())))


func _update_cart_emitters(delta: float) -> void :
	if _cart_phase == 0:
		return
	for i: int in _rear_wheels.size():
		var point: Vector2 = _bone_in_fx(_rear_wheels[i])
		var trail: GPUParticles2D = _wheel_trails[i]
		trail.position = point + Vector2(0.0, 118.0 * BASKET_SCALE)
		if delta > 0.0 and _wheel_previous.size() == _rear_wheels.size():
			var motion: Vector2 = point - _wheel_previous[i]
			if motion.length_squared() > 0.01:
				var direction: Vector2 = ( - motion).normalized()
				(trail.process_material as ParticleProcessMaterial).direction = Vector3(direction.x, direction.y, 0.0)
		if _wheel_previous.size() != _rear_wheels.size():
			_wheel_previous.resize(_rear_wheels.size())
		_wheel_previous[i] = point
	if _cart_phase == 2 and _flower_point_image != null:

		for i: int in _flower_bones.size():
			var point: Vector2 = _bone_in_fx(_flower_bones[i])
			_flower_point_image.set_pixel(i, 0, Color(point.x, point.y, 0.0))
		_flower_point_texture.update(_flower_point_image)
		for particle: GPUParticles2D in _particles:
			particle.position = Vector2.ZERO



func play_disappear() -> void :
	_cancel_pot_drop_haptic()
	AudioManager.stop_sfx(_active_cart_appear_sound_id)
	AudioManager.play_sfx(&"finish_cart_exit")
	_kill_active_tweens()
	_cart_phase = 3
	_carry_butterflies_with_cart()
	for trail: GPUParticles2D in _wheel_trails:
		_fade_particles(trail, PARTICLE_EXIT_FADE_DUR)
	for particle: GPUParticles2D in _particles:
		_fade_particles(particle, PARTICLE_EXIT_FADE_DUR)
	if _rainbow_sparkles != null:
		_fade_particles(_rainbow_sparkles, TITLE_EXIT_DELAY + TITLE_EXIT_DUR)
	_set_rainbow_sweep(-1.0)
	var animation: SpineAnimationState = _basket.get_animation_state()
	if animation != null:
		animation.clear_tracks()
		animation.set_animation(BASKET_ANIM_OUT, false, 0)
	_disable_cart_clipping()
	var title_fade: Tween = create_tween()
	_track_tween(title_fade)
	title_fade.tween_interval(TITLE_EXIT_DELAY)
	title_fade.tween_property(_rainbow, "modulate:a", 0.0, TITLE_EXIT_DUR)
	for label: CurveLabel in _title_layers:
		title_fade.parallel().tween_property(label, "modulate:a", 0.0, TITLE_EXIT_DUR)
	var glow_fade: Tween = create_tween()
	_track_tween(glow_fade)
	glow_fade.tween_property(_rays, "modulate:a", 0.0, 0.3)
	glow_fade.parallel().tween_property(_core, "modulate:a", 0.0, 0.3)



func _start_idle_background_light() -> void :
	var fade: Tween = create_tween()
	_track_tween(fade)
	fade.tween_property(_rays, "modulate:a", 1.0, RAYS_FADE_IN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.parallel().tween_property(_core, "modulate:a", 1.0, RAYS_FADE_IN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var rotate: Tween = _rays.create_tween()
	_track_tween(rotate)
	rotate.set_loops()
	rotate.tween_property(_rays, "rotation", TAU, RAYS_SPIN_PERIOD).from(0.0).set_trans(Tween.TRANS_LINEAR)
	var breathe: Tween = _core.create_tween()
	_track_tween(breathe)
	breathe.set_loops()
	breathe.tween_property(_core, "scale", _core_base_scale * CORE_BREATH_MAX, CORE_BREATH_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(_core, "scale", _core_base_scale * CORE_BREATH_MIN, CORE_BREATH_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)





func _disable_cart_clipping() -> void :
	var skeleton: SpineSkeleton = _basket.get_skeleton()
	if skeleton == null:
		SortLogger.error("Finish cart skeleton missing when disabling clipping")
		return
	var clip_slot: SpineSlot = skeleton.find_slot("root")
	if clip_slot == null:
		SortLogger.error("Finish cart clipping slot missing: root")
		return
	clip_slot.set_attachment(null)



func _build_cart_staging() -> void :
	_pot_staging.clear()
	var skeleton: SpineSkeleton = _basket.get_skeleton()
	_entry_bone = skeleton.find_bone("bone2")
	_exit_bone = skeleton.find_bone("bone")

	_entry_base_x = _entry_bone.get_data().get_x()
	_exit_base_x = _exit_bone.get_data().get_x()
	var starts: Dictionary = {"bone3": 1129.71, "bone49": 1129.71, "bone88": 1455.2, 
		"bone127": 1450.41, "bone166": 1737.61, "bone205": 1731.77, "h_d": 1450.02}
	for name: String in starts:
		var bone: SpineBone = skeleton.find_bone(name)
		_pot_staging.append({"bone": bone, "base_y": bone.get_data().get_y(), "initial_offset": float(starts[name])})
	_basket.before_world_transforms_change.connect(_adapt_cart_staging)


func _adapt_cart_staging(_sprite: SpineSprite) -> void :
	var animation: SpineAnimationState = _basket.get_animation_state()
	var track: SpineTrackEntry = animation.get_current(0)
	if track == null:
		return

	var name: String = track.get_animation().get_name()
	var scale_x: float = absf(_basket.global_scale.x)
	var scale_y: float = absf(_basket.global_scale.y)
	if scale_x <= 0.0 or scale_y <= 0.0:
		return
	var viewport: Vector2 = UiMetrics.viewport_size()
	var center_x: float = _basket.global_position.x
	var radius: float = 720.0 * scale_x + CART_SCREEN_MARGIN
	if name == BASKET_ANIM_INTO:
		var gain: float = maxf(1.0, (viewport.x - center_x + radius) / (CART_ENTRY_TRAVEL * scale_x))
		_entry_bone.set_x(_entry_base_x + (_entry_bone.get_x() - _entry_base_x) * gain)

		for stage: Dictionary in _pot_staging:
			var bone: SpineBone = stage["bone"]
			var base_y: float = float(stage["base_y"])

			var rest_world: Vector2 = bone.get_parent().local_to_world(Vector2(bone.get_x(), base_y))
			var rest_global: Vector2 = _basket.to_global(rest_world)
			var axis_world: Vector2 = bone.get_parent().local_to_world(Vector2(bone.get_x(), base_y + 1.0))
			var axis_y: float = _basket.to_global(axis_world).y - rest_global.y
			if axis_y >= -0.001:
				continue
			var margin: float = 260.0 * scale_y + 32.0
			var pot_gain: float = maxf(1.0, (rest_global.y + margin) / ( - axis_y * float(stage["initial_offset"])))
			bone.set_y(base_y + (bone.get_y() - base_y) * pot_gain)
	elif name == BASKET_ANIM_OUT:
		var gain: float = maxf(1.0, (center_x + radius) / (CART_EXIT_TRAVEL * scale_x))
		var offset_x: float = _exit_bone.get_x() - _exit_base_x

		if offset_x < 0.0:
			_exit_bone.set_x(_exit_base_x + offset_x * gain)
