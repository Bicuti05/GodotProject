class_name ProgressBling
extends Control

signal effect_started
signal effect_stopped


const SOURCE_WIDTH: = 1008.0
const SOURCE_COLOR_SIZE: = 1264.0
const COLOR_SLOT_COUNT: = 12
const DURATION: = 2.0
const IMPACT_RIPPLE_DURATION: = 1.25
const OUTER_RIPPLE_PADDING: = 64.0
const OUTER_RIPPLE_EXPANSION: = 18.0
const TOTAL_DURATION: = DURATION
const PREVIEW_GAP: = 0.5
const RANDOM_SEED: = 2312

const FLOW_MASK_SIDE_INSET: = 5.0
const FLOW_MASK_TOP_INSET: = 0.0
const FLOW_MASK_CORNER_SCALE: = 1.1
const PARTICLE_FRAME_GAP: = 3.0
const LARGE_PARTICLE_MAX_DIAMETER: = 62.0 * 0.45
const SMALL_PARTICLE_MAX_DIAMETER: = 35.0 * 0.45
const STAR_SOURCE_WIDTH: = 1005.0 * 494.0 / 512.0
const LARGE_PARTICLE_COUNT: = 12
const SMALL_PARTICLE_COUNT: = 6
const TOP_PARTICLE_HEIGHTS: = [2.0, 7.0, 0.0, 6.0, 1.0, 8.0]
const EMIT_FLAGS: = GPUParticles2D.EMIT_FLAG_POSITION | GPUParticles2D.EMIT_FLAG_VELOCITY

@export var normal_textures: Array[Texture2D] = []
@export var excellent_texture: Texture2D
@export var particle_match_material: ShaderMaterial

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _flow_root: Control = $Root
@onready var _impact_ripples: ColorRect = $ImpactRipples
@onready var _masks: Array[NinePatchRect] = [$Root / Glow, $Root / Soft, $Root / Border]
@onready var _preview_timer: Timer = $PreviewTimer
@onready var _particle_root: Node2D = $ParticleRoot
@onready var _stars: Node2D = $ParticleRoot / Stars
@onready var _small_stars: Node2D = $ParticleRoot / SmallStars
@onready var _large_particles: Array[GPUParticles2D] = [$ParticleRoot / Stars / Dot, $ParticleRoot / Stars / Star, $ParticleRoot / Stars / Flower]
@onready var _small_particles: Array[GPUParticles2D] = [$ParticleRoot / SmallStars / Dot, $ParticleRoot / SmallStars / Star, $ParticleRoot / SmallStars / Flower]

var _particle_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _skin_resources: JuiceSkinResolver
var _ripple_palette: PackedColorArray = JuiceSkin.bead().colors
var _impact_tween: Tween
var _playing: bool = false
var _additions_playing: bool = false
var _preview_looping: bool = false
var _preview_cycle_colors: bool = false
var _preview_slot: int = -1
var _preview_additions: bool = true
var _large_emitted: int = 0
var _small_emitted: int = 0
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void :

	_ripple_palette[9] = Color("#E3ADDA")

	_ripple_palette.append(Color("#674CE9"))
	_ripple_palette.append(Color("#8DE325"))
	for emitter: GPUParticles2D in _large_particles + _small_particles:
		emitter.process_material = emitter.process_material.duplicate()
	_particle_lifecycle.prepare(_large_particles + _small_particles, 2, func() -> bool: return visible and _particle_root.visible)
	resized.connect(_layout_effect)
	_layout_effect()
	hide_now()


func play_normal(color_slot: int, ripple_color: Color = Color.TRANSPARENT) -> bool:
	if _playing:
		return false
	if color_slot < 0 or color_slot >= normal_textures.size():
		SortLogger.error("ProgressBling: invalid color slot %d" % color_slot)
		return false
	var matched_color: Color = ripple_color if ripple_color.a > 0.0 else normal_ripple_color(color_slot)
	if color_slot == 9 and ripple_color.a > 0.0:
		matched_color = Color.from_hsv(normal_ripple_color(9).h, ripple_color.s, ripple_color.v, ripple_color.a)
	return _play(normal_textures[color_slot], true, matched_color)


func play_excellent(ripple_color: Color = Color.TRANSPARENT) -> bool:
	return _play(excellent_texture, true, ripple_color if ripple_color.a > 0.0 else normal_ripple_color(0))



func normal_ripple_color(color_slot: int) -> Color:
	if color_slot < 0 or color_slot >= _ripple_palette.size():
		return _ripple_palette[0]
	return _ripple_palette[color_slot]


func is_playing() -> bool:
	return _playing



func preview(mode: String, selector: String = "excellent", layers: String = "all") -> bool:
	if mode not in ["once", "on", "off"] or layers not in ["all", "base"]:
		SortLogger.warn("ProgressBling: use progress_bling_motion on/once/off [0~11/excellent/all] [all/base]")
		return false
	var slot: int = -1
	if mode != "off" and selector not in ["excellent", "all"]:
		if not selector.is_valid_int() or selector.to_int() < 0 or selector.to_int() >= normal_textures.size():
			SortLogger.warn("ProgressBling: preview color must be 0~11, excellent or all")
			return false
		slot = selector.to_int()
	hide_now()
	if mode == "off":
		return true
	_preview_looping = mode == "on"
	_preview_cycle_colors = selector == "all"
	_preview_slot = 0 if _preview_cycle_colors else slot
	_preview_additions = layers == "all"
	return _play_preview_color()


func hide_now() -> void :
	_preview_timer.stop()
	_preview_looping = false
	_preview_cycle_colors = false
	_animation_player.stop()
	_finish_effect()


func _play(texture: Texture2D, additions: bool = true, ripple_color: Color = Color.TRANSPARENT) -> bool:
	if _playing:
		return false
	if texture == null:
		SortLogger.error("ProgressBling: missing color texture")
		return false
	var effect_color: Color = ripple_color if ripple_color.a > 0.0 else normal_ripple_color(0)
	var colorful: bool = texture == excellent_texture
	for mask: NinePatchRect in _masks:
		(mask.material as ShaderMaterial).set_shader_parameter("color_texture", texture)
	particle_match_material.set_shader_parameter("color_texture", texture)
	particle_match_material.set_shader_parameter("effect_color", effect_color)
	particle_match_material.set_shader_parameter("use_color_texture", colorful)
	_update_color_geometry()
	_clear_stars()
	_random.seed = RANDOM_SEED
	_large_emitted = 0
	_small_emitted = 0
	_additions_playing = additions
	_playing = true
	_particle_root.hide()
	_flow_root.hide()
	_animation_player.stop()
	show()
	if additions:
		var ripple_material: ShaderMaterial = _impact_ripples.material as ShaderMaterial
		ripple_material.set_shader_parameter("ripple_color", effect_color)
		ripple_material.set_shader_parameter("use_color_texture", colorful)
		ripple_material.set_shader_parameter("color_texture", texture)
		ripple_material.set_shader_parameter("color_center", _flow_mask_rect().get_center())
		ripple_material.set_shader_parameter("color_size", size.x * SOURCE_COLOR_SIZE / SOURCE_WIDTH)
		_layout_impact_ripples()
		_set_impact_progress(0.0)
		_impact_ripples.show()
		effect_started.emit()
		_impact_tween = create_tween()
		_impact_tween.tween_method(_set_impact_progress, 0.0, 1.0, IMPACT_RIPPLE_DURATION).set_trans(Tween.TRANS_LINEAR)
		_impact_tween.tween_callback(_hide_impact_ripples)
	_start_rotation()
	return true


func _set_impact_progress(progress: float) -> void :
	var ripple_material: ShaderMaterial = _impact_ripples.material as ShaderMaterial
	ripple_material.set_shader_parameter("progress", progress)
	ripple_material.set_shader_parameter("angle", (_masks[0].material as ShaderMaterial).get_shader_parameter("angle"))


func _hide_impact_ripples() -> void :
	_impact_ripples.hide()



func _start_rotation() -> void :
	if not _playing:
		return
	_flow_root.show()
	_particle_root.visible = _additions_playing
	if _additions_playing:
		_particle_lifecycle.play(true)
	_update_color_geometry()
	_animation_player.play(&"bling")
	_animation_player.advance(0.0)


func _play_preview_color() -> bool:
	var texture: Texture2D = excellent_texture if _preview_slot < 0 or _preview_slot >= normal_textures.size() else normal_textures[_preview_slot]
	return _play(texture, _preview_additions, normal_ripple_color(_preview_slot if _preview_slot >= 0 and _preview_slot < COLOR_SLOT_COUNT else 0))


func _finish_effect() -> void :
	if _impact_tween != null and _impact_tween.is_valid():
		_impact_tween.kill()
	_impact_tween = null
	_impact_ripples.hide()
	_flow_root.hide()
	if _playing:
		effect_stopped.emit()
	_playing = false
	_additions_playing = false
	_clear_stars()
	_particle_root.hide()
	hide()


func _clear_stars() -> void :
	_particle_lifecycle.reset_immediate()


func _emit_small_star() -> void :
	if not _playing or not _additions_playing:
		return
	var index: int = _small_emitted
	var right_side: bool = index % 2 == 1
	var point: Vector2 = _small_particle_birth(index)
	var width_scale: float = size.x / STAR_SOURCE_WIDTH
	var transform: = Transform2D(0.0, point / width_scale)
	var speed: float = _random.randf_range(3.0, 7.0)
	var velocity: = Vector2(speed if right_side else - speed, _random.randf_range(-4.0, 4.0))
	var particles: GPUParticles2D = _small_particles[index % _small_particles.size()]
	_small_emitted += 1
	_particle_lifecycle.emit_manual(particles, transform, velocity, Color.WHITE, Color(), EMIT_FLAGS)


func _emit_large_star() -> void :
	if not _playing or not _additions_playing:
		return
	var index: int = _large_emitted
	var point: Vector2 = _large_particle_birth(index)
	var width_scale: float = size.x / STAR_SOURCE_WIDTH
	var transform: = Transform2D(0.0, point / width_scale)
	var right_side: bool = index % 2 == 1
	var speed: float = _random.randf_range(4.0, 9.0)
	var velocity: = Vector2( - speed if right_side else speed, _random.randf_range(-4.0, -2.0))
	var particles: GPUParticles2D = _large_particles[index % _large_particles.size()]
	_large_emitted += 1
	_particle_lifecycle.emit_manual(particles, transform, velocity, Color.WHITE, Color(), EMIT_FLAGS)


func _small_particle_birth(index: int) -> Vector2:
	var right_side: bool = index % 2 == 1
	var row: int = index / 2
	var clearance: float = _particle_frame_clearance(SMALL_PARTICLE_MAX_DIAMETER)
	return Vector2(size.x + clearance if right_side else - clearance, 
		48.0 + float(row) * 34.0 + _random.randf_range(-3.0, 3.0))


func _large_particle_birth(index: int) -> Vector2:
	var half: int = LARGE_PARTICLE_COUNT / 2
	var right_side: bool = index % 2 == 1
	var column: int = index / 2
	var center_clear: float = minf(145.0, size.x * 0.18)
	var corner_clear: float = minf(64.0, size.x * 0.2)
	var side_start: float = size.x * 0.5 + center_clear if right_side else corner_clear
	var side_end: float = size.x - corner_clear if right_side else size.x * 0.5 - center_clear

	var height_index: int = (column + (3 if right_side else 0)) % half
	var height_jitter: float = _random.randf_range(-0.5, 0.5) * minf(1.0, size.x / STAR_SOURCE_WIDTH)
	var height_offset: float = clampf(float(TOP_PARTICLE_HEIGHTS[height_index]) + height_jitter, 0.0, 8.0)
	return Vector2(lerpf(side_start, side_end, (float(column) + 0.5) / float(half))
		+ _random.randf_range(-1.0, 1.0) * minf(2.0, size.x / STAR_SOURCE_WIDTH * 2.0), - _particle_frame_clearance(LARGE_PARTICLE_MAX_DIAMETER) - height_offset)



func _particle_frame_clearance(max_diameter: float) -> float:
	return PARTICLE_FRAME_GAP + max_diameter * sqrt(2.0) * 0.5 * size.x / STAR_SOURCE_WIDTH


func _on_animation_finished(animation_name: StringName) -> void :
	if animation_name != &"bling":
		return
	_finish_effect()
	if _preview_looping:
		_preview_timer.start(PREVIEW_GAP)


func _on_preview_timeout() -> void :
	if not _preview_looping:
		return
	if _preview_cycle_colors:
		_preview_slot = (_preview_slot + 1) % (normal_textures.size() + 1)
	_play_preview_color()


func _flow_mask_rect() -> Rect2:
	var width: float = maxf(2.0, size.x - FLOW_MASK_SIDE_INSET * 2.0)
	var top: float = JuiceQuotaBar.PANEL_Y + FLOW_MASK_TOP_INSET

	var height: float = JuiceQuotaBar.BOARD_Y + 2.0 - top
	return Rect2(Vector2(FLOW_MASK_SIDE_INSET, top), Vector2(width, height))


func _update_color_geometry() -> void :
	var color_size: float = size.x * SOURCE_COLOR_SIZE / SOURCE_WIDTH
	var rect: Rect2 = _flow_mask_rect()
	for mask: NinePatchRect in _masks:
		var shader_material: ShaderMaterial = mask.material as ShaderMaterial
		shader_material.set_shader_parameter("color_center", mask.size * 0.5)
		shader_material.set_shader_parameter("color_size", color_size / FLOW_MASK_CORNER_SCALE)
	sync_global_color_transform()
	particle_match_material.set_shader_parameter("color_center", rect.get_center())
	particle_match_material.set_shader_parameter("color_size", color_size)



func sync_global_color_transform() -> void :
	particle_match_material.set_shader_parameter("effect_origin", global_position)
	particle_match_material.set_shader_parameter("effect_scale", get_global_transform().get_scale())



func _layout_impact_ripples() -> void :
	var body_size: = Vector2(maxf(2.0, size.x - FLOW_MASK_SIDE_INSET * 2.0), JuiceQuotaBar.PANEL_H)
	_impact_ripples.position = Vector2(FLOW_MASK_SIDE_INSET - OUTER_RIPPLE_PADDING, JuiceQuotaBar.PANEL_Y - OUTER_RIPPLE_PADDING)
	_impact_ripples.size = body_size + Vector2.ONE * OUTER_RIPPLE_PADDING * 2.0
	var ripple_material: ShaderMaterial = _impact_ripples.material as ShaderMaterial
	ripple_material.set_shader_parameter("body_size", body_size)
	ripple_material.set_shader_parameter("body_origin", Vector2(FLOW_MASK_SIDE_INSET, JuiceQuotaBar.PANEL_Y))
	ripple_material.set_shader_parameter("padding", OUTER_RIPPLE_PADDING)
	ripple_material.set_shader_parameter("expansion_pixels", OUTER_RIPPLE_EXPANSION)


func _layout_effect() -> void :
	_layout_impact_ripples()
	var rect: Rect2 = _flow_mask_rect()
	for mask: NinePatchRect in _masks:
		mask.position = rect.position
		mask.scale = Vector2.ONE * FLOW_MASK_CORNER_SCALE
		mask.size = rect.size / FLOW_MASK_CORNER_SCALE
	_update_color_geometry()

	_particle_root.position = Vector2(0.0, JuiceQuotaBar.PANEL_Y)
	var width_scale: float = size.x / STAR_SOURCE_WIDTH
	_stars.scale = Vector2.ONE * width_scale
	_small_stars.scale = Vector2.ONE * width_scale
	_stars.position = Vector2.ZERO
	_small_stars.position = Vector2.ZERO


func apply_skin(resources: JuiceSkinResolver) -> void :
	hide_now()
	_skin_resources = resources
	for slot: int in normal_textures.size():
		normal_textures[slot] = resources.progress_texture(slot, normal_textures[slot])
	excellent_texture = resources.effect_texture(&"progress_excellent", excellent_texture)
	var fields: Array[StringName] = [&"progress_dot", &"progress_star", &"progress_flower"]
	_particle_lifecycle.reconfigure( func() -> void :
		for index: int in 3:
			for emitter: GPUParticles2D in [_large_particles[index], _small_particles[index]]:
				var texture: Texture2D = resources.effect_texture(fields[index], emitter.texture)
				var ratio: float = float(emitter.texture.get_width()) / maxf(1.0, texture.get_width())
				var particle_material: ParticleProcessMaterial = emitter.process_material as ParticleProcessMaterial
				particle_material.scale_min *= ratio
				particle_material.scale_max *= ratio
				emitter.texture = texture
	)
