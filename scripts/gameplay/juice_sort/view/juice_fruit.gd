class_name JuiceFruit
extends Node2D



const FLOWER_VISUAL_RECTS: Dictionary[String, Rect2] = {
	"flower_red.png": Rect2(0.165, 0.135, 0.67, 0.685), 
	"flower_purple.png": Rect2(0.14, 0.13, 0.72, 0.685), 
	"flower_pink.png": Rect2(0.14, 0.135, 0.72, 0.685), 
	"flower_cyan.png": Rect2(0.155, 0.155, 0.685, 0.685), 
	"flower_yellow.png": Rect2(0.155, 0.135, 0.69, 0.68), 
	"flower_green.png": Rect2(0.155, 0.135, 0.685, 0.685), 
	"flower_blue.png": Rect2(0.145, 0.135, 0.71, 0.685), 
	"flower_teal.png": Rect2(0.14, 0.135, 0.72, 0.685), 
	"flower_orange.png": Rect2(0.135, 0.135, 0.725, 0.685), 
	"flower_lavender.png": Rect2(0.145, 0.13, 0.71, 0.69), 
	"gp_flower_question.png": Rect2(0.15, 0.15, 0.695, 0.67), 
	"bonus_coin.png": Rect2(0.14, 0.145, 0.71, 0.715), 
}

const HINT_SCALE: = 1.0
const HINT_REFERENCE_CANVAS_SIZE: float = 200.0
const TUTORIAL_GLOW_STRENGTH: = 1.35
const REVEAL_DURATION: = 0.55


const REVEAL_CRACK_DURATION: = 0.16
const SUNLIGHT_REVEAL_FADE_DURATION: float = 0.22
const REVEAL_INNER_SHARDS: = [0, 2, 4, 6]
const REVEAL_OUTER_SHARDS: = [1, 3, 5, 8, 10, 12]


const SHADOW_ENABLED: = false


@export var question_texture: Texture2D = null
@export var sunlight_texture: Texture2D
const SUNLIGHT_CANVAS_SIZE: float = 200.0
const SUNLIGHT_RENDER_SIZE: float = 190.0
const ICE_SOURCE_REGION: Rect2 = Rect2(157.9845, 211.90698, 635.7209, 627.4108)













@onready var _body: Sprite2D = $Body


@onready var _shadow: Sprite2D = $Shadow
@onready var _ice_back: Sprite2D = $IceBack
@onready var _ice_body: Sprite2D = $IceBody
@onready var _ice_frost: Sprite2D = $IceFrost
@onready var _ice_body_material: ShaderMaterial = $IceBody.material as ShaderMaterial
@onready var _ice_back_material: ShaderMaterial = $IceBack.material as ShaderMaterial
@onready var _ice_frost_material: ShaderMaterial = $IceFrost.material as ShaderMaterial
@onready var _sunlight_ambient: JuiceSunlightAmbient = $SunlightAmbient
@onready var _hint_material: ShaderMaterial = ($Body.material as ShaderMaterial).duplicate() as ShaderMaterial
var _tutorial_hint_material: ShaderMaterial = null
@onready var _group_highlight_halo: Sprite2D = $GroupHighlightHalo
@onready var _group_highlight_halo_material: ShaderMaterial = $GroupHighlightHalo.material as ShaderMaterial
@onready var _group_highlight_landing_particles: JuiceGroupHighlightLandingParticles = $GroupHighlightLandingParticles


var fruit_type: int = -1

var col: int = -1
var idx: int = -1

var _diameter: float = 0.0
var _frozen: bool = false
var _sunlight: bool = false
var _melt_progress: float = 0.0
var _back_melt_progress: float = 0.0
var _frost_visible: bool = true

var _tex_w: float = 256.0
var _body_scale: float = 1.0
var _skin_visual: JuiceSkinVisual
var _real_skin_visual: JuiceSkinVisual
var _default_question_texture: Texture2D
var _hint_active: = false
var _reveal_time: float = -1.0
var _reveal_texture: Texture2D = null
var _reveal_color: Color = Color.WHITE
var _reveal_sunlight: bool = false
var _pop_tween: Tween = null
var _connection_tween: Tween = null
var _connection_scale: float = 1.0
var _color_reject_scale: float = 1.0
var _color_reject_tween: Tween = null
var _color_reject_material: ShaderMaterial = null
var _color_reject_previous_material: Material = null
var _group_highlight_scale: float = 1.0
var _group_highlight_active: bool = false
var _landing_group_highlight_tween: Tween = null
var _breathing_group_highlight_active: bool = false
var _breathing_group_highlight_releasing: bool = false
var _breathing_group_highlight_particle_age: float = -1.0

var _breathing_group_highlight_last_time: float = -1.0

var _breathing_group_highlight_phase_offset: float = 0.0

var _breathing_group_highlight_first_cycle: bool = true

var _group_highlight_halo_texture: Texture2D = null

var _group_highlight_halo_canvas_ratio: float = 1.0
const BREATHING_GROUP_HIGHLIGHT_SCALE: float = 0.055
const BREATHING_GROUP_HIGHLIGHT_RELEASE_SEC: float = 0.2

const BREATHING_GROUP_HIGHLIGHT_HALO_STRENGTH: float = 1.0

const BREATHING_GROUP_HIGHLIGHT_RISE_RATIO: float = 0.7


const GROUP_HALO_BAKE_RANGE: float = 0.28
const GROUP_HALO_BAKE_EXPANSION: float = 1.1
const GROUP_HALO_RANGE_PADDING: float = 0.18
var _landing_group_highlight_origin_position: Vector2 = Vector2.ZERO
var _landing_group_highlight_origin_rotation: float = 0.0
var _landing_group_highlight_origin_halo_transform: Transform2D = Transform2D.IDENTITY
var _landing_group_highlight_center: Vector2 = Vector2.ZERO
var _flower_shown_emitted: bool = false




signal flower_shown()



static var debug_darkness_percent: float = 0.0
static var debug_flower_brightness_percent: float = 100.0


static func get_debug_flower_brightness() -> float:
	return debug_flower_brightness_percent / 100.0


func apply_debug_brightness() -> void :
	var brightness: float = get_debug_flower_brightness()
	self_modulate = Color(brightness, brightness, brightness, self_modulate.a)
	_body.self_modulate = Color(brightness, brightness, brightness, _body.self_modulate.a)


func _ready() -> void :
	add_to_group("juice_flower_debug_brightness")
	apply_debug_brightness()

	_body.material = null

	_shadow.visible = SHADOW_ENABLED
	set_process(false)


func _exit_tree() -> void :
	if is_node_ready():
		clear_group_highlight()
		_sunlight_ambient.stop()


func setup(tex: Texture2D, type_id: int, diameter: float, tex_size: Vector2, 
		hidden: bool = false, frozen: bool = false, visual: JuiceSkinVisual = null, mystery: JuiceSkinVisual = null, landing_texture: Texture2D = null, 
		halo_texture: Texture2D = null, halo_canvas_ratio: float = 0.0) -> void :
	set_frozen(false)
	set_sunlight(false)
	_stop_color_reject()
	clear_group_highlight()
	set_hint_highlight(false)
	_stop_connection_pop()
	_stop_reveal()
	apply_debug_brightness()
	fruit_type = type_id
	if _default_question_texture == null:
		_default_question_texture = question_texture
	question_texture = mystery.texture if mystery != null else _default_question_texture
	_group_highlight_landing_particles.star_texture = landing_texture
	_group_highlight_halo_texture = halo_texture
	_group_highlight_halo_canvas_ratio = halo_canvas_ratio if halo_canvas_ratio > 0.0 else 1.0
	_real_skin_visual = visual
	_skin_visual = mystery if hidden else visual
	var shown: Texture2D = question_texture if hidden else tex
	_body.texture = shown
	_shadow.texture = shown
	_body.visible = true
	_shadow.visible = SHADOW_ENABLED
	_tex_w = maxf(1.0, shown.get_width() if _skin_visual != null else tex_size.x)
	set_diameter(diameter)
	set_frozen(frozen)


func is_frozen() -> bool:
	return _frozen


func reveal(tex: Texture2D, type_id: int, color: Color, sunlight: bool = false) -> void :
	_skin_visual = _real_skin_visual
	if _skin_visual != null:
		_tex_w = maxf(1.0, tex.get_width())
		set_diameter(_diameter)
	clear_group_highlight()
	fruit_type = type_id
	_body.texture = tex
	_shadow.texture = tex
	_apply_flower_offset()
	_reveal_texture = tex
	_reveal_color = color
	_reveal_sunlight = sunlight
	_reveal_time = 0.0
	_flower_shown_emitted = false
	_body.visible = false
	_shadow.visible = false
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void :
	if _reveal_time < 0.0:
		return
	_reveal_time += delta
	if not _flower_shown_emitted and _reveal_time >= REVEAL_CRACK_DURATION:
		_flower_shown_emitted = true
		flower_shown.emit()
	if _reveal_sunlight and _flower_shown_emitted:

		_body.visible = true
		_body.modulate.a = smoothstep(REVEAL_CRACK_DURATION, 
			REVEAL_CRACK_DURATION + SUNLIGHT_REVEAL_FADE_DURATION, _reveal_time)
	if _reveal_time >= REVEAL_DURATION:
		_stop_reveal()
		_body.visible = true
		_shadow.visible = SHADOW_ENABLED
	else:
		queue_redraw()


func _draw() -> void :
	if _reveal_time < 0.0 or _reveal_texture == null or question_texture == null:
		return
	var t: float = _reveal_time
	if _reveal_sunlight:
		if t < REVEAL_CRACK_DURATION:
			_draw_reveal_texture(question_texture, 1.0, 
				1.0 - smoothstep(0.0, REVEAL_CRACK_DURATION, t))
		return
	var glow_in: float = clampf((t - 0.04) / 0.12, 0.0, 1.0)
	var glow_out: float = 1.0 - clampf((t - 0.3) / 0.22, 0.0, 1.0)
	for ring in 7:
		var glow: Color = _reveal_color
		glow.a = 0.016 * glow_in * glow_out
		draw_circle(Vector2.ZERO, _diameter * (0.5 - float(ring) * 0.045), glow)

	if t < REVEAL_CRACK_DURATION:
		var shake_x: float = sin(t * 120.0) * _diameter * 0.008 if t > 0.1 else 0.0
		_draw_reveal_texture(question_texture, 1.0, 1.0, Vector2(shake_x, 0.0))
		if t > 0.065:
			_draw_reveal_cracks(clampf((t - 0.065) / 0.095, 0.0, 1.0))
	else:
		var flower_p: float = clampf((t - REVEAL_CRACK_DURATION) / 0.22, 0.0, 1.0)
		var flower_scale: float = 0.82 + 0.18 * _ease_out(flower_p)
		_draw_reveal_texture(_reveal_texture, flower_scale, 0.25 + 0.75 * flower_p)
		_draw_reveal_shards(clampf((t - REVEAL_CRACK_DURATION) / 0.24, 0.0, 1.0))
	_draw_reveal_light(t)


func _draw_reveal_texture(tex: Texture2D, scale_factor: float, alpha: float, 
		offset: Vector2 = Vector2.ZERO) -> void :
	var tint: = Color(1.0, 1.0, 1.0, alpha)
	draw_texture_rect(tex, _reveal_texture_rect(tex, scale_factor, offset), false, tint)


func _reveal_texture_rect(tex: Texture2D, scale_factor: float, 
		offset: Vector2 = Vector2.ZERO) -> Rect2:
	var texture_scale: float = _diameter * scale_factor / _tex_w
	var dst_size: Vector2 = tex.get_size() * texture_scale
	if tex == _reveal_texture:
		offset += _body.offset * texture_scale
	return Rect2(offset - dst_size * 0.5, dst_size)


func _draw_reveal_cracks(alpha: float) -> void :
	var d: float = _diameter
	var outer: Color = _reveal_color
	outer.a = alpha * 0.38
	var inner: Color = _reveal_color.lightened(0.65)
	inner.a = alpha * 0.9
	for stroke in 2:
		var tint: Color = outer if stroke == 0 else inner
		var width: float = d * (0.038 if stroke == 0 else 0.011)
		draw_line(Vector2(-0.22, -0.3) * d, Vector2(-0.08, -0.1) * d, 
			tint, width, true)
		draw_line(Vector2(-0.08, -0.1) * d, Vector2(-0.17, 0.12) * d, 
			tint, width, true)
		draw_line(Vector2(0.2, -0.29) * d, Vector2(0.05, -0.05) * d, 
			tint, width, true)
		draw_line(Vector2(0.05, -0.05) * d, Vector2(0.18, 0.22) * d, 
			tint, width, true)


func _draw_reveal_shards(progress: float) -> void :
	for i in REVEAL_INNER_SHARDS:
		_draw_reveal_shard(0, 8, i, progress)
	for i in REVEAL_OUTER_SHARDS:
		_draw_reveal_shard(1, 14, i, progress)


func _draw_reveal_shard(ring: int, count: int, index: int, progress: float) -> void :
	var left: float = float(index) * TAU / float(count) - PI * 0.5
	var right: float = float(index + 1) * TAU / float(count) - PI * 0.5
	var inner: float = _diameter * (0.0 if ring == 0 else 0.24)
	var outer: float = _diameter * (0.24 if ring == 0 else 0.5)
	var vertices: Array[Vector2] = []
	if ring == 0:
		vertices = [Vector2.ZERO, Vector2.from_angle(left) * outer, 
			Vector2.from_angle(right) * outer]
	else:
		vertices = [Vector2.from_angle(left) * inner, Vector2.from_angle(left) * outer, 
			Vector2.from_angle(right) * outer, Vector2.from_angle(right) * inner]
	var center: = Vector2.ZERO
	for vertex in vertices:
		center += vertex
	center /= float(vertices.size())
	var angle: float = (float(index) + 0.5) * TAU / float(count) - PI * 0.5
	var spread: float = _diameter * 0.23 * _ease_out(progress)
	spread *= 0.65 if ring == 0 else (1.1 if index % 3 == 0 else 0.85)
	var offset: Vector2 = Vector2.from_angle(angle) * spread
	var turn: float = progress * 0.16 * (1.0 if index % 2 == 0 else -1.0)
	var tex_size: Vector2 = _reveal_texture.get_size()
	var dst_size: Vector2 = tex_size * (_diameter / _tex_w)
	var points: = PackedVector2Array()
	var uvs: = PackedVector2Array()
	var colors: = PackedColorArray()
	var tint: = Color(1.0, 1.0, 1.0, 1.0 - progress)

	for vertex in vertices:
		points.append(vertex - center)
		uvs.append(Vector2(0.5 + vertex.x / dst_size.x, 
			0.5 + vertex.y / dst_size.y))
		colors.append(tint)
	draw_set_transform(center + offset, turn, Vector2.ONE)
	draw_polygon(points, colors, uvs, _reveal_texture)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_reveal_light(t: float) -> void :
	_draw_radial_light(t, _reveal_color)


func _draw_radial_light(time: float, light_color: Color) -> void :
	var lifetime: float = 0.3
	var particle_count: int = 8
	var glow_radius_ratio: float = 0.03
	var core_radius_ratio: float = 0.013
	var glow_opacity: float = 0.17
	var core_opacity: float = 0.85
	for particle_index: int in particle_count:
		var stagger: float = float(particle_index % 3) * 0.018
		var age: float = time - 0.15 - stagger
		if age < 0.0 or age >= lifetime:
			continue
		var progress: float = age / lifetime
		var eased_progress: float = _ease_out(progress)
		var opacity: float = 1.0 - progress
		var angle: float = float(particle_index) * TAU / float(particle_count) + 0.2
		var distance: float = _diameter * (0.03 + 0.35 * eased_progress)\
		* (0.7 + float(particle_index % 3) * 0.13)
		var particle_position: Vector2 = Vector2(cos(angle), sin(angle)) * distance
		particle_position.y += _diameter * (0.06 * progress * progress - 0.05 * progress)
		var halo: Color = light_color
		halo.a = opacity * glow_opacity
		draw_circle(particle_position, _diameter * glow_radius_ratio, halo)
		var core: Color = light_color.lightened(0.55)
		core.a = opacity * core_opacity
		draw_circle(particle_position, _diameter * core_radius_ratio * (1.0 - 0.4 * progress), core)


func _ease_out(progress: float) -> float:
	return 1.0 - pow(1.0 - progress, 3.0)


func _stop_reveal() -> void :
	if _reveal_sunlight:
		_body.modulate.a = 1.0
	_reveal_sunlight = false
	_reveal_time = -1.0
	_reveal_texture = null
	set_process(false)
	queue_redraw()






func play_reveal_pop(peak: float, dip: float, up_dur: float, dip_dur: float, 
		settle_dur: float) -> void :
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", Vector2.ONE * peak, up_dur)
	_pop_tween.tween_property(self, "scale", Vector2.ONE * dip, dip_dur)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, settle_dur)


func set_diameter(d: float) -> void :
	_diameter = d
	_body_scale = d / _tex_w * (_skin_visual.size_correction if _skin_visual != null else 1.0)
	_apply_flower_offset()
	_apply_body_scale()
	_update_ice()
	_sunlight_ambient.set_diameter(d)


func set_sunlight(enabled: bool) -> void :
	if _sunlight == enabled:
		return
	_sunlight = enabled
	if enabled:
		_body.texture = sunlight_texture
		_shadow.texture = sunlight_texture

		if _reveal_time >= 0.0:
			_reveal_texture = sunlight_texture
		_tex_w = SUNLIGHT_CANVAS_SIZE * sunlight_texture.get_width() / SUNLIGHT_RENDER_SIZE
		_body_scale = _diameter / _tex_w
		_apply_flower_offset()
		_apply_body_scale()
	_sunlight_ambient.set_sunlight(enabled)
	queue_redraw()


func set_frozen(enabled: bool) -> void :
	_frozen = enabled
	_melt_progress = 0.0
	_back_melt_progress = 0.0
	_frost_visible = true
	_update_ice()
	_sunlight_ambient.set_frozen(enabled)


func set_frost_visible(enabled: bool) -> void :
	_frost_visible = enabled
	_update_ice()


func set_melt_progress(progress: float, back_progress: float = -1.0) -> void :
	_melt_progress = clampf(progress, 0.0, 1.0)
	_back_melt_progress = clampf(back_progress, 0.0, 1.0) if back_progress >= 0.0 else _melt_progress
	_update_ice()
	_sunlight_ambient.set_melt_progress(_melt_progress)


func set_ambient_settings(options: SunlightFxSettings) -> void :
	_sunlight_ambient.configure(options)


func set_ambient_playback(speed: float, paused: bool) -> void :
	_sunlight_ambient.set_playback(speed, paused)


func stop_ambient_motion() -> void :
	_sunlight_ambient.stop_motion()


func ice_surface_transform() -> Transform2D:
	var ice_rect: Rect2 = _ice_body.get_rect()
	return _ice_body.get_global_transform_with_canvas() * Transform2D(
		Vector2(ice_rect.size.x, 0.0), Vector2(0.0, ice_rect.size.y), ice_rect.position)


func _update_ice() -> void :
	if not is_node_ready():
		return
	var progress: float = _melt_progress
	_ice_back.visible = _frozen and _back_melt_progress < 1.0
	_ice_body.visible = _frozen and progress < 1.0
	_ice_frost.visible = _ice_body.visible and _frost_visible and progress < 0.3
	_ice_body_material.set_shader_parameter("melt_progress", progress)
	_ice_back_material.set_shader_parameter("melt_progress", _back_melt_progress)
	_ice_frost_material.set_shader_parameter("melt_progress", progress)
	var flower_rect: Rect2 = skin_visual_rect()
	var cover_scale: float = maxf(1.0, maxf(
		(flower_rect.size.x * SUNLIGHT_CANVAS_SIZE + 16.0) / 137.0, 
		(flower_rect.size.y * SUNLIGHT_CANVAS_SIZE + 16.0) / 135.0))
	var unit_scale: float = _diameter / SUNLIGHT_CANVAS_SIZE * cover_scale
	var flower_center: Vector2 = (flower_rect.get_center() * _body.texture.get_width()
		- _body.texture.get_size() * 0.5 + _body.offset) * _body_scale\
		if _body.texture != null else Vector2.ZERO
	_ice_body.scale = Vector2(137.0 / ICE_SOURCE_REGION.size.x, 
		135.0 / ICE_SOURCE_REGION.size.y) * unit_scale
	_ice_body.position = flower_center + Vector2(-0.5, -0.5) * unit_scale
	_ice_body.modulate = Color(1.0, 1.0, 1.0, 0.35)
	_ice_back.scale = _ice_body.scale
	_ice_back.position = _ice_body.position
	_ice_back.modulate = Color(0.9, 0.9, 0.9, 0.25)
	_ice_frost.scale = Vector2(142.0 / _ice_frost.texture.get_width(), 
		50.0 / _ice_frost.texture.get_height()) * unit_scale
	_ice_frost.position = flower_center + Vector2(0.0, -62.0) * unit_scale
	_ice_frost.modulate = Color(1.0, 1.0, 1.0, 0.2)
	_sunlight_ambient.set_ice_geometry(
		flower_center * SUNLIGHT_CANVAS_SIZE / maxf(1.0, _diameter), cover_scale)


static func flower_visual_rect(texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2(0.0, 0.0, 1.0, 1.0)
	return FLOWER_VISUAL_RECTS.get(texture.resource_path.get_file(), Rect2(0.0, 0.0, 1.0, 1.0))


func _apply_flower_offset() -> void :
	var offset: Vector2 = _skin_visual.offset if _skin_visual != null else Vector2.ZERO
	if _sunlight and _body.texture != null:
		offset = Vector2(0.0, 3.0 * _body.texture.get_width() / SUNLIGHT_RENDER_SIZE)
	_body.offset = offset
	_shadow.offset = offset + Vector2(6.0, 10.0)

	_group_highlight_halo.offset = offset / maxf(_group_highlight_halo_canvas_ratio, 0.001)
	_update_ice()


func diameter() -> float:
	return _diameter


func visual_diameter() -> float:
	var visible_size: Vector2 = skin_visual_rect().size * _body.texture.get_size() * _body_scale
	return maxf(visible_size.x, visible_size.y)



func tutorial_visual_center_global() -> Vector2:
	var local_center: Vector2 = _body.get_rect().position + _body.texture.get_size() * 0.5
	return _body.global_transform * local_center



func play_connection_pop(peak: float, up_dur: float, down_dur: float, 
		ease: Tween.EaseType = Tween.EASE_IN_OUT) -> void :
	_stop_connection_pop()
	_connection_tween = create_tween()
	_connection_tween.tween_method(_set_connection_scale, 1.0, peak, up_dur)\
	.set_trans(Tween.TRANS_SINE).set_ease(ease)
	_connection_tween.tween_method(_set_connection_scale, peak, 1.0, down_dur)\
	.set_trans(Tween.TRANS_SINE).set_ease(ease)


func _set_connection_scale(value: float) -> void :
	_connection_scale = value
	_apply_body_scale()


func _stop_connection_pop() -> void :
	if _connection_tween != null and _connection_tween.is_valid():
		_connection_tween.kill()
	_connection_tween = null
	_connection_scale = 1.0
	if is_instance_valid(_body):
		_apply_body_scale()



func set_hint_highlight(on: bool, tutorial_strong: bool = false, tutorial_color: Color = Color(1.0, 0.78, 0.05, 0.9)) -> void :
	if on:
		clear_group_highlight()
	_hint_active = on
	if on and tutorial_strong:
		if _tutorial_hint_material == null:
			_tutorial_hint_material = _hint_material.duplicate() as ShaderMaterial
		_tutorial_hint_material.set_shader_parameter("outline_color", Color.WHITE)
		_tutorial_hint_material.set_shader_parameter("glow_strength", TUTORIAL_GLOW_STRENGTH)
		_tutorial_hint_material.set_shader_parameter("glow_color", Color(tutorial_color, 0.9))
		_body.material = _tutorial_hint_material
	else:
		_body.material = _hint_material if on else null
	set_process(_reveal_time >= 0.0)
	_apply_body_scale()


func _apply_body_scale() -> void :
	var factor: = HINT_SCALE if _hint_active else 1.0
	_body.scale = Vector2.ONE * _body_scale * factor * _connection_scale * _group_highlight_scale * _color_reject_scale
	_shadow.scale = _body.scale
	_group_highlight_halo.scale = _body.scale
	if _hint_active and (_body.material == _hint_material or _body.material == _tutorial_hint_material):

		var width_scale: float = _diameter / (HINT_REFERENCE_CANVAS_SIZE * maxf(_body_scale, 0.0001))
		var material: ShaderMaterial = _body.material as ShaderMaterial
		material.set_shader_parameter("outline_width", 6.0 * width_scale)
		material.set_shader_parameter("glow_width", 14.0 * width_scale)


func _set_landing_group_highlight_backlight(halo_strength: float, halo_range: float, 
		halo_expansion: float) -> void :
	if not _group_highlight_active or _hint_active or _reveal_time >= 0.0:
		return

	if _group_highlight_halo_texture == null or halo_range <= 0.0:
		_group_highlight_halo.hide()
		return
	if _group_highlight_halo.texture != _group_highlight_halo_texture:
		_group_highlight_halo.texture = _group_highlight_halo_texture
	_group_highlight_halo.visible = halo_strength > 0.0
	_group_highlight_halo_material.set_shader_parameter("halo_strength", halo_strength)
	_sync_group_highlight_halo(halo_range, halo_expansion)



func _sync_group_highlight_halo(halo_range: float, halo_expansion: float) -> void :
	_group_highlight_halo.transform = _body.transform
	var factor: float = _group_highlight_halo_canvas_ratio
	factor *= (halo_range + GROUP_HALO_RANGE_PADDING)\
	/ (GROUP_HALO_BAKE_RANGE + GROUP_HALO_RANGE_PADDING)
	factor *= halo_expansion / GROUP_HALO_BAKE_EXPANSION
	_group_highlight_halo.scale *= factor





func play_breathing_group_highlight(duration: float) -> bool:
	if _breathing_group_highlight_active:
		if not _breathing_group_highlight_releasing:
			return false
		_resume_breathing_from_release(duration)
		return true
	clear_group_highlight()
	if _hint_active or _reveal_time >= 0.0 or _body.texture == null or not _body.visible:
		return false
	if _color_reject_tween != null and _color_reject_tween.is_valid():
		return false
	_landing_group_highlight_origin_position = _body.position
	_landing_group_highlight_origin_rotation = _body.rotation
	_landing_group_highlight_origin_halo_transform = _group_highlight_halo.transform
	_landing_group_highlight_center = _body.get_rect().get_center()
	_group_highlight_active = true
	_breathing_group_highlight_active = true
	_breathing_group_highlight_last_time = -1.0
	_breathing_group_highlight_phase_offset = 0.0
	_breathing_group_highlight_first_cycle = true
	_reseed_breathing_particles()
	_set_breathing_group_highlight_time(0.0, duration)
	_start_breathing_tween(duration)
	return true




func _resume_breathing_from_release(duration: float) -> void :
	if _landing_group_highlight_tween != null and _landing_group_highlight_tween.is_valid():
		_landing_group_highlight_tween.kill()
	_breathing_group_highlight_releasing = false
	_breathing_group_highlight_first_cycle = false
	_breathing_group_highlight_last_time = -1.0
	var pulse: float = clampf((_group_highlight_scale - 1.0)\
	/ BREATHING_GROUP_HIGHLIGHT_SCALE, 0.0, 1.0)

	_breathing_group_highlight_phase_offset = acos(1.0 - 2.0 * pulse) / TAU * duration
	_reseed_breathing_particles()
	_set_breathing_group_highlight_time(0.0, duration)
	_start_breathing_tween(duration)



func _start_breathing_tween(duration: float) -> void :
	_landing_group_highlight_tween = create_tween()
	_landing_group_highlight_tween.set_loops()
	_landing_group_highlight_tween.tween_method(
		_set_breathing_group_highlight_time.bind(duration), 0.0, duration, duration)




func _reseed_breathing_particles() -> void :
	_group_highlight_landing_particles.prepare(4, _diameter, 
		_body.position + (_landing_group_highlight_center * _body.scale).rotated(_body.rotation), 
		0.8, 0.6)
	_group_highlight_landing_particles.modulate.a = 1.0


func _set_breathing_group_highlight_time(time: float, duration: float) -> void :
	if not _breathing_group_highlight_active:
		return

	var phase: float = time
	if _breathing_group_highlight_phase_offset > 0.0:
		phase = fposmod(time + _breathing_group_highlight_phase_offset, duration)

	if phase < _breathing_group_highlight_last_time:
		_reseed_breathing_particles()
		_breathing_group_highlight_first_cycle = false
	_breathing_group_highlight_last_time = phase
	_breathing_group_highlight_particle_age = phase - duration * 0.4
	var progress: float = clampf(phase / duration, 0.0, 1.0)
	var pulse: float
	if _breathing_group_highlight_first_cycle:

		if progress <= BREATHING_GROUP_HIGHLIGHT_RISE_RATIO:

			var rise: float = progress / BREATHING_GROUP_HIGHLIGHT_RISE_RATIO
			pulse = rise * rise
		else:

			var fall: float = (progress - BREATHING_GROUP_HIGHLIGHT_RISE_RATIO)\
			/ (1.0 - BREATHING_GROUP_HIGHLIGHT_RISE_RATIO)
			pulse = 1.0 - fall * fall
	else:

		pulse = 0.5 - 0.5 * cos(TAU * progress)
	_group_highlight_scale = 1.0 + BREATHING_GROUP_HIGHLIGHT_SCALE * pulse
	_apply_body_scale()

	_set_landing_group_highlight_backlight(BREATHING_GROUP_HIGHLIGHT_HALO_STRENGTH * pulse, 
		0.28, 1.06 + 0.04 * pulse)
	_group_highlight_landing_particles.set_age(_breathing_group_highlight_particle_age)


func is_breathing_group_highlight_active() -> bool:
	return _breathing_group_highlight_active



func stop_breathing_group_highlight(immediate: bool = false) -> void :
	if not _breathing_group_highlight_active:
		return
	if immediate:
		clear_group_highlight()
		return
	if _breathing_group_highlight_releasing:
		return
	_breathing_group_highlight_releasing = true
	if _landing_group_highlight_tween != null and _landing_group_highlight_tween.is_valid():
		_landing_group_highlight_tween.kill()
	var pulse: float = (_group_highlight_scale - 1.0) / BREATHING_GROUP_HIGHLIGHT_SCALE
	var particle_age: float = _breathing_group_highlight_particle_age
	_landing_group_highlight_tween = create_tween()
	_landing_group_highlight_tween.tween_method(
		_set_breathing_group_highlight_release.bind(pulse, particle_age), 
		0.0, 1.0, BREATHING_GROUP_HIGHLIGHT_RELEASE_SEC).set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	_landing_group_highlight_tween.tween_callback(clear_group_highlight)


func _set_breathing_group_highlight_release(progress: float, pulse: float, 
		particle_age: float) -> void :
	if not _breathing_group_highlight_active:
		return
	var remaining: float = 1.0 - progress
	_group_highlight_scale = 1.0 + BREATHING_GROUP_HIGHLIGHT_SCALE * pulse * remaining
	_apply_body_scale()
	_set_landing_group_highlight_backlight(BREATHING_GROUP_HIGHLIGHT_HALO_STRENGTH * pulse * remaining, 
		0.28, 1.06 + 0.04 * pulse * remaining)

	_group_highlight_landing_particles.modulate.a = remaining
	_group_highlight_landing_particles.set_age(
		particle_age + progress * BREATHING_GROUP_HIGHLIGHT_RELEASE_SEC)


func clear_group_highlight() -> void :
	if _landing_group_highlight_tween != null and _landing_group_highlight_tween.is_valid():
		_landing_group_highlight_tween.kill()
	_landing_group_highlight_tween = null
	if _breathing_group_highlight_active:
		_breathing_group_highlight_active = false
		_breathing_group_highlight_releasing = false
		_breathing_group_highlight_particle_age = -1.0
		_breathing_group_highlight_last_time = -1.0
		_breathing_group_highlight_phase_offset = 0.0
		_body.position = _landing_group_highlight_origin_position
		_body.rotation = _landing_group_highlight_origin_rotation
		_group_highlight_halo.transform = _landing_group_highlight_origin_halo_transform
	if is_instance_valid(_group_highlight_landing_particles):
		_group_highlight_landing_particles.stop()
		_group_highlight_landing_particles.modulate.a = 1.0
	if not _group_highlight_active:
		return
	_group_highlight_active = false
	_group_highlight_scale = 1.0
	_group_highlight_halo.hide()
	_group_highlight_halo.texture = null
	_group_highlight_halo_material.set_shader_parameter("halo_strength", 0.0)
	_apply_body_scale()




func reset_for_pool() -> void :
	set_frozen(false)
	set_sunlight(false)
	_sunlight_ambient.stop()
	_stop_color_reject()
	clear_group_highlight()
	set_hint_highlight(false)
	_stop_connection_pop()
	_stop_reveal()
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = null
	_skin_visual = null
	_real_skin_visual = null
	if _default_question_texture != null:
		question_texture = _default_question_texture
	fruit_type = -1
	col = -1
	idx = -1
	top_level = false
	z_index = 0
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	_hint_active = false
	_body.modulate = Color.WHITE
	_body.visible = true
	_body.scale = Vector2.ONE
	_body.material = null
	_body.texture = null
	_shadow.scale = Vector2.ONE
	_shadow.texture = null
	_shadow.visible = SHADOW_ENABLED
	_group_highlight_halo.scale = Vector2.ONE
	_group_highlight_halo_texture = null
	_group_highlight_halo_canvas_ratio = 1.0
	_apply_flower_offset()



func play_color_reject() -> void :
	if _breathing_group_highlight_active:
		clear_group_highlight()
	_stop_color_reject()
	if _color_reject_material == null:
		_color_reject_material = _hint_material.duplicate() as ShaderMaterial
		_color_reject_material.set_shader_parameter("outline_color", Color("ff4242"))
		_color_reject_material.set_shader_parameter("outline_width", 7.0)
		_color_reject_material.set_shader_parameter("glow_width", 0.0)
		_color_reject_material.set_shader_parameter("glow_strength", 0.0)
	_color_reject_previous_material = _body.material
	_body.material = _color_reject_material
	_color_reject_tween = create_tween()
	_color_reject_tween.tween_method(_sample_color_reject, 0.0, 0.4, 0.4)
	_color_reject_tween.tween_callback(_stop_color_reject)


func _sample_color_reject(age: float) -> void :
	var u: float = clampf(age / 0.4, 0.0, 1.0)
	_color_reject_scale = 1.0 + 0.2 * pow(sin(PI * u), 2.0)
	_body.rotation = sin(age * 26.0) * 0.12 * (1.0 - u)
	_apply_body_scale()


func _stop_color_reject() -> void :
	if _color_reject_tween != null and _color_reject_tween.is_valid():
		_color_reject_tween.kill()
	_color_reject_tween = null
	_color_reject_scale = 1.0
	if is_instance_valid(_body):
		_body.rotation = 0.0
		if _color_reject_material != null and _body.material == _color_reject_material:
			_body.material = _color_reject_previous_material
		_apply_body_scale()
	_color_reject_previous_material = null


func cancel_color_reject() -> void :
	_stop_color_reject()


func skin_visual_rect() -> Rect2:
	if _skin_visual != null and _skin_visual.content_rect != Rect2():
		var texture_size: Vector2 = _skin_visual.texture.get_size()
		return Rect2(_skin_visual.content_rect.position / texture_size, _skin_visual.content_rect.size / texture_size)
	return flower_visual_rect(_body.texture)
