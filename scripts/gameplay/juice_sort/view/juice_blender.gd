class_name JuiceBlender
extends Node2D
















const NEW_EMPTY_POT_SCALE: float = 1.08
const POT_ICE_AMBIENT: = preload("res://scripts/gameplay/juice_sort/view/juice_pot_ice_ambient.gd")
const COLLECTOR_BODY_TEXTURE: = preload("res://assets/sprites/juice_sort/sunlight_collector_empty_figma.png")
const COLLECTOR_SUN_TEXTURE: = preload("res://assets/sprites/juice_sort/sunlight_sun_body_top_figma.png")
const COLLECTOR_REFERENCE_SIZE: = Vector2(199.0, 198.0)
const COLLECTOR_REFERENCE_CONTENT: = Rect2(28.0, 21.0, 142.0, 142.0)
const COLLECTOR_BODY_CONTENT: = Rect2(129.0, 111.0, 766.0, 760.0)
const SUN_HALO_TEXTURE: = preload("res://assets/sprites/juice_sort/sunlight_collector_glow_back_figma.png")
const COLLECTOR_SUN_GLOW_TEXTURE: = preload("res://assets/sprites/juice_sort/sunlight_collector_sun_glow.png")
const COLLECTOR_HALO_SHADER: = preload("res://scripts/gameplay/juice_sort/view/sunlight_collector_halo.gdshader")

@onready var _body: Sprite2D = $Body
@onready var _sun_icon: Sprite2D = $SunIcon
@onready var _collector_shadow: Sprite2D = $CollectorShadow
var _sunlight: bool = false
var _sunlight_charge: float = 0.0
var _sunlight_clock: float = 0.0
var _sunlight_settings: SunlightFxSettings = SunlightFxSettings.new()
var _sun_halo: Sprite2D = null
var _sun_effect: Sprite2D = null
@onready var _hint_material: ShaderMaterial = $Body.material as ShaderMaterial
var _hint_top_clip: Control = null
var _hint_top_overlay: Control = null
var _hint_top_body: Sprite2D = null
var _shelf: Sprite2D = null
var _second_shelf: Sprite2D = null



var want_type: int = -1
var col: int = -1

var _rect: = Rect2()
var _empty_content_rect: Rect2 = Rect2()
var _empty_source_bottom: float = 0.0
var _empty_bottom_y: float = NAN
var _empty_max_ratio: float = INF
var _target_texture: Texture2D = null
var _empty_skin_visual: JuiceSkinVisual
var _filled_skin_visual: JuiceSkinVisual
var _filled_texture: Texture2D = null
var _hint_active: = false
const POT_ICE_TEXTURE: = preload("res://assets/sprites/juice_sort/sunlight_pot_ice.png")
const POT_ICE_REGION: Rect2 = Rect2(18.0, 16.0, 164.0, 162.0)
const POT_ICE_VISIBLE_BOTTOM: float = 155.0
const POT_ICE_SHADER: = preload("res://scripts/gameplay/juice_sort/view/sunlight_ice_melt.gdshader")
var _ice_layers: Array[Sprite2D] = []
var _pot_frozen: bool = false
var _pot_frost_visible: bool = true
var _pot_melt: float = 0.0
var _pot_back_melt: float = 0.0
var _pot_ice_max_width: float = INF
var _ice_behind_shelves: bool = false
var _pot_snow: Node2D = null


func apply_debug_brightness() -> void :
	var brightness: float = JuiceFruit.get_debug_flower_brightness()
	_body.self_modulate = Color(brightness, brightness, brightness, _body.self_modulate.a)


func _ready() -> void :
	set_notify_transform(true)
	visibility_changed.connect(_update_hint_top_overlay)
	_create_sunlight_halo()
	_create_ice_layers()
	add_to_group("juice_flower_debug_brightness")
	_update_processing()
	apply_debug_brightness()

	_body.material = null


func _process(delta: float) -> void :
	if _hint_active:
		_update_hint_top_overlay()
	if _sunlight and is_visible_in_tree():
		_sunlight_clock = fposmod(_sunlight_clock + delta, maxf(0.1, _sunlight_settings.halo_period))
		_sample_sunlight_halo()


func _update_processing() -> void :
	set_process(_sunlight or _hint_active)


func _notification(notification: int) -> void :
	if notification == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		_update_pot_ice()
		_update_hint_top_overlay()

func set_target(tex: Texture2D, filled_tex: Texture2D, type_id: int, 
		empty_content_rect: Rect2 = Rect2(), empty_source_bottom: float = 0.0) -> void :
	apply_debug_brightness()
	want_type = type_id
	_target_texture = tex
	_filled_texture = filled_tex
	_empty_content_rect = empty_content_rect
	_empty_source_bottom = empty_source_bottom
	_empty_bottom_y = NAN
	_empty_max_ratio = INF
	_body.texture = _target_texture
	_update_hint_top_overlay()



func set_filled(on: bool) -> void :
	if _sunlight:
		set_sunlight(true, 1.0 if on else _sunlight_charge)
	var show_filled: bool = on and _filled_texture != null
	if _sunlight:
		_body.texture = COLLECTOR_BODY_TEXTURE
	else:
		_body.texture = _filled_texture if show_filled else _target_texture
	_apply_body_scale()



func place(rect: Rect2, skin: JuiceSkin, empty_bottom_y: float = NAN, 
		empty_max_ratio: float = INF) -> void :
	_rect = rect
	_empty_bottom_y = empty_bottom_y
	_empty_max_ratio = empty_max_ratio
	position = rect.position + rect.size * 0.5
	_apply_body_scale(skin.blender_tex_size)
	set_sunlight(_sunlight, _sunlight_charge)
	_update_pot_ice()
func _apply_body_scale(fallback_size: Vector2 = Vector2.ZERO) -> void :
	if _body.texture == null:
		return
	var tex_size: Vector2 = _body.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		tex_size = fallback_size
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	if _body.texture == COLLECTOR_BODY_TEXTURE:
		var reference_scale: Vector2 = _rect.size / COLLECTOR_REFERENCE_SIZE
		_body.scale = COLLECTOR_REFERENCE_CONTENT.size * reference_scale / COLLECTOR_BODY_CONTENT.size
		_body.position = (COLLECTOR_REFERENCE_CONTENT.get_center() - COLLECTOR_REFERENCE_SIZE * 0.5)\
		* reference_scale - (COLLECTOR_BODY_CONTENT.get_center() - tex_size * 0.5) * _body.scale
	elif _body.texture == _target_texture and _empty_content_rect.has_area():
		var texture_transform: Transform2D = _texture_transform(_body.texture, tex_size)
		_body.scale = texture_transform.get_scale()
		_body.position = texture_transform.origin
	else:
		_body.scale = _rect.size / tex_size
		_body.position = Vector2.ZERO
	var visual: JuiceSkinVisual = _filled_skin_visual if _body.texture == _filled_texture else _empty_skin_visual
	_body.offset = visual.offset if visual != null else Vector2.ZERO
	if visual != null:
		_body.scale *= visual.size_correction
	_update_pot_ice()
	_update_hint_top_overlay()



func _texture_transform(texture: Texture2D, texture_size: Vector2) -> Transform2D:
	if texture == _target_texture and _empty_content_rect.has_area():
		var ratio: float = minf(minf(_rect.size.x / _empty_content_rect.size.x, 
			_rect.size.y / _empty_content_rect.size.y) * NEW_EMPTY_POT_SCALE, _empty_max_ratio)
		var offset: Vector2 = (texture_size * 0.5 - _empty_content_rect.get_center()) * ratio
		if is_finite(_empty_bottom_y) and _empty_source_bottom > 0.0:
			offset.y = _empty_bottom_y - _rect.get_center().y\
			- (_empty_source_bottom - texture_size.y * 0.5) * ratio
		return Transform2D(0.0, Vector2.ONE * ratio, 0.0, offset)
	return Transform2D(0.0, _rect.size / texture_size, 0.0, Vector2.ZERO)



func _pot_ice_display_width(max_width: float) -> float:
	return minf(_rect.size.x * 1.16, max_width) * 0.97



func set_ready(on: bool) -> void :
	var tint: Color = Color(1.25, 1.22, 1.05) if on else Color.WHITE
	_body.modulate = Color(tint.r, tint.g, tint.b, _body.modulate.a)


func set_hint_highlight(on: bool) -> void :
	_hint_active = on
	_body.material = _hint_material if on else null
	if on and _hint_top_overlay == null:
		_create_hint_top_overlay()
	_update_hint_top_overlay()
	_update_processing()




func _create_hint_top_overlay() -> void :
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is Control and (ancestor as Control).clip_contents:
			_hint_top_clip = ancestor as Control
			break
		if ancestor is CanvasItem and (ancestor as CanvasItem).top_level:
			return
		ancestor = ancestor.get_parent()
	if _hint_top_clip == null:
		return
	_hint_top_overlay = Control.new()
	_hint_top_overlay.name = "HintTopOverlay"
	_hint_top_overlay.visible = false
	_hint_top_overlay.top_level = true
	_hint_top_overlay.clip_contents = true
	_hint_top_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_top_overlay.z_as_relative = false
	add_child(_hint_top_overlay)
	_hint_top_body = Sprite2D.new()
	_hint_top_body.name = "Body"
	_hint_top_body.material = _hint_material
	_hint_top_overlay.add_child(_hint_top_body)


func _hint_effect_padding() -> float:

	var outline_width: Variant = _hint_material.get_shader_parameter("outline_width")
	var glow_width: Variant = _hint_material.get_shader_parameter("glow_width")
	return (6.0 if outline_width == null else float(outline_width))\
	+ (14.0 if glow_width == null else float(glow_width)) + 2.0


func _update_hint_top_overlay() -> void :
	if _hint_top_overlay == null:
		return
	if not _hint_active or not _body.is_visible_in_tree() or _body.texture == null\
	or not is_instance_valid(_hint_top_clip):
		_hint_top_overlay.hide()
		return

	var padding: float = _hint_effect_padding()
	var clip_transform: Transform2D = _hint_top_clip.get_global_transform()
	var to_clip: Transform2D = clip_transform.affine_inverse() * _body.global_transform
	var expanded_rect: Rect2 = to_clip * _body.get_rect().grow(padding)
	var top: float = minf(expanded_rect.position.y, 0.0)
	_hint_top_overlay.size = Vector2(_hint_top_clip.size.x, - top)
	var overlay_transform: Transform2D = clip_transform * Transform2D(0.0, Vector2(0.0, top))
	_hint_top_overlay.global_position = overlay_transform.origin
	_hint_top_overlay.rotation = overlay_transform.get_rotation()
	_hint_top_overlay.scale = overlay_transform.get_scale()
	_hint_top_body.texture = _body.texture
	_hint_top_body.global_transform = _body.global_transform

	var tint: Color = _body.self_modulate
	var effective_z: int = 0
	var inherit_z: bool = true
	var item: CanvasItem = _body
	while item != null:
		tint *= item.modulate
		if inherit_z:
			effective_z += item.z_index
			inherit_z = item.z_as_relative
		item = null if item.top_level else item.get_parent() as CanvasItem
	_hint_top_body.self_modulate = tint
	_hint_top_overlay.z_index = clampi(effective_z, RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)
	_hint_top_overlay.visible = top < 0.0




func set_shelves(first: Sprite2D, second: Sprite2D) -> void :
	_shelf = first
	_second_shelf = second
func reset_for_pool() -> void :
	set_hint_highlight(false)
	if _hint_top_body != null:
		_hint_top_body.texture = null
	_ice_behind_shelves = false
	_empty_content_rect = Rect2()
	_empty_source_bottom = 0.0
	_empty_bottom_y = NAN
	_empty_max_ratio = INF
	_pot_ice_max_width = INF
	_pot_frost_visible = true
	set_frozen(false)
	set_sunlight(false)
	want_type = -1
	col = -1
	position = Vector2.ZERO
	scale = Vector2.ONE
	modulate = Color.WHITE
	_body.position = Vector2.ZERO
	_body.modulate = Color.WHITE
	_body.material = null
	_body.texture = null
	_target_texture = null
	_filled_texture = null
	_empty_skin_visual = null
	_filled_skin_visual = null
	_body.offset = Vector2.ZERO
	_shelf = null
	_second_shelf = null


func _create_ice_layers() -> void :
	for index in 3:
		var layer: Sprite2D = Sprite2D.new()
		layer.name = ["IceBack", "IceBody", "IceFrost"][index]
		layer.visible = false
		layer.show_behind_parent = index == 0
		layer.texture = POT_ICE_TEXTURE
		if index != 2:
			layer.region_enabled = true
			layer.region_rect = POT_ICE_REGION
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = POT_ICE_SHADER
		material.set_shader_parameter("frost_layer", index == 2)
		material.set_shader_parameter("opaque_surface", index != 2)
		if index != 2:
			material.set_shader_parameter("uv_region", Vector4(POT_ICE_REGION.position.x / POT_ICE_TEXTURE.get_width(), 
				POT_ICE_REGION.position.y / POT_ICE_TEXTURE.get_height(), POT_ICE_REGION.size.x / POT_ICE_TEXTURE.get_width(), 
				POT_ICE_REGION.size.y / POT_ICE_TEXTURE.get_height()))
		layer.material = material
		add_child(layer)
		layer.top_level = true
		_ice_layers.append(layer)
	_pot_snow = POT_ICE_AMBIENT.new()
	_pot_snow.name = "PotSnowflakes"
	_pot_snow.visible = false
	add_child(_pot_snow)
	_pot_snow.top_level = true
	_update_pot_ice()


func set_frozen(enabled: bool) -> void :
	_pot_frozen = enabled
	_pot_melt = 0.0
	_pot_back_melt = 0.0
	_update_pot_ice()


func is_frozen() -> bool:
	return _pot_frozen


func set_ice_max_width(width: float) -> void :
	_pot_ice_max_width = maxf(width, 0.0)
	_update_pot_ice()


func set_ice_behind_shelves(enabled: bool) -> void :
	_ice_behind_shelves = enabled
	_update_ice_shelf_occlusion()


func _update_ice_shelf_occlusion() -> void :
	for layer: Sprite2D in _ice_layers:
		var material: ShaderMaterial = layer.material as ShaderMaterial
		material.set_shader_parameter("shelf_occlusion_enabled", _ice_behind_shelves)
	if not _ice_behind_shelves:
		return
	for index: int in 2:
		var shelf: Sprite2D = _shelf if index == 0 else _second_shelf
		var prefix: String = "shelf_" if index == 0 else "second_shelf_"
		var alpha: float = 0.0
		var axis_x: Vector3 = Vector3.ZERO
		var axis_y: Vector3 = Vector3.ZERO
		if is_instance_valid(shelf) and shelf.is_visible_in_tree() and shelf.texture != null:
			var inverse: Transform2D = shelf.global_transform.affine_inverse()
			var texture_size: Vector2 = shelf.texture.get_size()
			var offset: Vector2 = texture_size * 0.5 if shelf.centered else Vector2.ZERO
			axis_x = Vector3(inverse.x.x, inverse.y.x, inverse.origin.x + offset.x) / texture_size.x
			axis_y = Vector3(inverse.x.y, inverse.y.y, inverse.origin.y + offset.y) / texture_size.y
			alpha = shelf.modulate.a * shelf.self_modulate.a
		for layer: Sprite2D in _ice_layers:
			var material: ShaderMaterial = layer.material as ShaderMaterial
			material.set_shader_parameter(prefix + "alpha", alpha)
			material.set_shader_parameter(prefix + "uv_x", axis_x)
			material.set_shader_parameter(prefix + "uv_y", axis_y)
			if index == 0 and is_instance_valid(shelf):
				material.set_shader_parameter("shelf_texture", shelf.texture)


func set_frost_visible(enabled: bool) -> void :
	_pot_frost_visible = enabled
	_update_pot_ice()


func set_melt_progress(front: float, back: float = -1.0) -> void :
	_pot_melt = clampf(front, 0.0, 1.0)
	_pot_back_melt = clampf(front if back < 0.0 else back, 0.0, 1.0)
	_update_pot_ice()


func ice_surface_transform() -> Transform2D:
	var layer: Sprite2D = _ice_layers[1]
	var rectangle: Rect2 = layer.get_rect()
	return layer.get_global_transform_with_canvas() * Transform2D(
		Vector2(rectangle.size.x, 0.0), Vector2(0.0, rectangle.size.y), rectangle.position)


func ice_shatter_snapshot() -> Dictionary:
	var layer: Sprite2D = _ice_layers[1]
	return {"texture": layer.texture, "rect": layer.get_rect(), "region": layer.region_rect, 
		"transform": layer.global_transform}


func _update_pot_ice() -> void :

	_body.visible = not _pot_frozen
	_update_ice_shelf_occlusion()
	var display_shift: Vector2 = Vector2.ZERO
	if _body.texture == _target_texture and _empty_content_rect.has_area():
		var compensation: Vector2 = (_body.texture.get_size() * 0.5\
		- _empty_content_rect.get_center()) * _body.scale
		display_shift = _body.position - compensation
	var ice_width: float = _pot_ice_display_width(_pot_ice_max_width)
	var ice_size: Vector2 = POT_ICE_REGION.size * ice_width / POT_ICE_REGION.size.x
	if is_finite(_empty_bottom_y):
		display_shift.y = _empty_bottom_y - _rect.get_center().y\
		- (POT_ICE_VISIBLE_BOTTOM - POT_ICE_REGION.get_center().y) * ice_width / POT_ICE_REGION.size.x
	for index in _ice_layers.size():
		var layer: Sprite2D = _ice_layers[index]
		var progress: float = _pot_back_melt if index == 0 else _pot_melt
		layer.visible = _pot_frozen and progress < 1.0 and index != 2
		(layer.material as ShaderMaterial).set_shader_parameter("melt_progress", progress)
		var source_size: Vector2 = POT_ICE_TEXTURE.get_size() if index == 2 else POT_ICE_REGION.size
		layer.global_transform = global_transform * Transform2D(0.0, ice_size / source_size, 
			0.0, display_shift)
		layer.modulate = Color(0.9, 0.9, 0.9, 1.0) if index == 0 else Color.WHITE
	if is_instance_valid(_pot_snow):
		var surface: Sprite2D = _ice_layers[1]
		_pot_snow.call("set_surface", surface.global_transform, surface.get_rect())
		_pot_snow.call("set_emitting", _pot_frozen and _pot_melt == 0.0)


func _create_sunlight_halo() -> void :
	_sun_icon.texture = COLLECTOR_SUN_TEXTURE
	var halo_material: ShaderMaterial = ShaderMaterial.new()
	halo_material.shader = COLLECTOR_HALO_SHADER
	_sun_halo = Sprite2D.new()
	_sun_halo.name = "CollectorSunHalo"
	_sun_halo.visible = false
	_sun_halo.texture = SUN_HALO_TEXTURE
	_sun_halo.material = halo_material
	_sun_halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sun_halo)
	move_child(_sun_halo, _sun_icon.get_index())
	_sun_effect = Sprite2D.new()
	_sun_effect.name = "CollectorSunEffect"
	_sun_effect.visible = false
	_sun_effect.texture = COLLECTOR_SUN_GLOW_TEXTURE
	_sun_effect.material = halo_material
	_sun_effect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sun_effect)
	move_child(_sun_effect, _sun_icon.get_index())


func _sample_sunlight_halo() -> void :
	var pulse: float = _sunlight_settings.halo_pulse(_sunlight_clock)
	var bottle_width: float = COLLECTOR_BODY_TEXTURE.get_width() * _body.scale.x
	var halo_width: float = bottle_width * 171.6 / 191.0
	var radius_limit: float = _sunlight_halo_radius_limit(_sun_icon.position)
	if is_finite(radius_limit):
		halo_width = minf(halo_width, radius_limit * 2.0 / (1.0 + _sunlight_settings.halo_amplitude))
	_sun_halo.position = _sun_icon.position
	_sun_halo.scale = Vector2.ONE * halo_width / SUN_HALO_TEXTURE.get_width()\
	* (1.0 + _sunlight_settings.halo_amplitude * pulse)
	_sun_halo.modulate.a = lerpf(0.5, 1.0, pulse)
	var effect_width: float = COLLECTOR_SUN_GLOW_TEXTURE.get_width() * _sun_icon.scale.x
	var effect_amplitude: float = _sunlight_settings.halo_amplitude * 0.5
	if is_finite(radius_limit):
		effect_width = minf(effect_width, radius_limit * 2.0 / (1.0 + effect_amplitude))
	_sun_effect.position = _sun_icon.position
	_sun_effect.scale = Vector2.ONE * effect_width / COLLECTOR_SUN_GLOW_TEXTURE.get_width()\
	* (1.0 + effect_amplitude * pulse)
	_sun_effect.modulate.a = lerpf(0.65, 1.0, pulse)
	_sun_halo.visible = _sunlight and _sunlight_settings.halo_enabled
	_sun_effect.visible = _sun_halo.visible


func _sunlight_halo_radius_limit(center_position: Vector2) -> float:
	if top_level:
		return INF
	var radius_limit: float = INF
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is CanvasLayer:
			break
		if ancestor is Control and (ancestor as Control).clip_contents:
			var clip_control: Control = ancestor as Control
			var to_control: Transform2D = clip_control.get_global_transform().affine_inverse() * global_transform
			var center: Vector2 = to_control * center_position
			var scale_x: float = Vector2(to_control.x.x, to_control.y.x).length()
			var scale_y: float = Vector2(to_control.x.y, to_control.y.y).length()
			if scale_x <= 0.0001 or scale_y <= 0.0001:
				return 0.0
			var margin_x: float = maxf(0.0, minf(center.x, clip_control.size.x - center.x) - 2.0)
			var margin_y: float = maxf(0.0, minf(center.y, clip_control.size.y - center.y) - 2.0)
			radius_limit = minf(radius_limit, minf(margin_x / scale_x, margin_y / scale_y))
		if ancestor is CanvasItem and (ancestor as CanvasItem).top_level:
			break
		ancestor = ancestor.get_parent()
	return radius_limit


func set_sunlight(enabled: bool, charge: float = 0.0, options: SunlightFxSettings = null) -> void :
	if _sunlight != enabled:
		_sunlight_clock = 0.0
	if options != null:
		_sunlight_settings = options
	_sunlight = enabled
	_sunlight_charge = clampf(charge, 0.0, 1.0)
	if not is_node_ready():
		return
	if enabled:
		_body.texture = COLLECTOR_BODY_TEXTURE
		_apply_body_scale()
	elif _body.texture == COLLECTOR_BODY_TEXTURE:
		_body.texture = _target_texture
		_apply_body_scale()
	_sun_icon.visible = enabled
	_collector_shadow.visible = enabled
	var bottle_size: Vector2 = COLLECTOR_BODY_TEXTURE.get_size() * _body.scale
	_sun_icon.scale = Vector2.ONE * bottle_size.x * 81.225 / 191.0 / _sun_icon.texture.get_width()
	_sun_icon.position = _body.position + bottle_size * Vector2(-0.75, 5.25) / 191.0
	_collector_shadow.scale = _rect.size / _collector_shadow.texture.get_size()
	_collector_shadow.position = Vector2(0.0, _rect.size.y * 0.42)
	_collector_shadow.modulate.a = 0.4
	_sample_sunlight_halo()
	_update_processing()
	queue_redraw()


func sample_sunlight_flight(from_rect: Rect2, dst_rect: Rect2, progress: float) -> void :
	var amount: float = smoothstep(0.0, 1.0, clampf(progress, 0.0, 1.0))
	var center: Vector2 = from_rect.get_center().lerp(dst_rect.get_center(), amount)
	center.x += sin(amount * PI) * from_rect.size.x * 0.4
	center.y -= sin(amount * PI) * from_rect.size.y * 0.7
	_rect.size = from_rect.size.lerp(dst_rect.size, amount)
	_rect.position = center - _rect.size * 0.5
	position = center
	_apply_body_scale()
	set_sunlight(true, 1.0)


func set_skin_visuals(empty_visual: JuiceSkinVisual, filled_visual: JuiceSkinVisual) -> void :
	_empty_skin_visual = empty_visual
	_filled_skin_visual = filled_visual
