class_name JuiceTutorialLayer
extends Control

































@export var focus_enabled: bool = false


var text_card_min_height: float = 0.0


const FOCUS_DIM_ALPHA: = 0.65

const BAR_W: = 900.0

const TEXT_PAD: = 48.0



const CARD_PAD_L: = 41.0
const CARD_PAD_T: = 16.0
const CARD_PAD_R: = 40.0
const CARD_PAD_B: = 64.0


const BAR_MIN_H: = 192.0

@onready var _focus_mask: ColorRect = $Root / FocusMask
@onready var _focus_art: Node2D = $Root / FocusArt
@onready var _focus_template: Sprite2D = $Root / FocusArt / Template
@onready var _hand: JuiceHandDemo = $Root / HandDemo
@onready var _summary: JuiceTutorialSummary = $Root / RuleSummary
var _summary_mode: bool = false
@onready var _bar: NinePatchRect = $Root / TextBar
@onready var _label: Label = $Root / TextBar / Label



var _demo_from: Vector2 = Vector2.INF
var _demo_dst: Vector2 = Vector2.INF


const DEMO_SAME_EPS: = 0.5


var _bar_center_x: float = 0.0


var _bar_card_bottom_y: float = 0.0
var _bar_safe_top_y: float = 0.0
var _bar_base_font_size: int = 0
var _focus_sprites: Array[Sprite2D] = []
var _focus_rope_art: Node2D
var _focus_rope_sprites: Array[Sprite2D] = []


func _ready() -> void :
	_focus_rope_art = Node2D.new()
	_focus_rope_art.name = "FocusRopes"
	_focus_art.add_child(_focus_rope_art)
	_focus_art.move_child(_focus_rope_art, 0)
	_bar_base_font_size = _label.get_theme_font_size(&"font_size")
	clear_all()





func set_text(text: String, error: bool = false) -> void :
	var bar_visible: bool = text != "" and ( not _summary_mode or error)
	var summary_visible: bool = _summary_mode and not error
	var tint: Color = Color(1.0, 0.92, 0.92) if error else Color.WHITE
	if _label.text == text and _bar.visible == bar_visible and _summary.visible == summary_visible and _bar.modulate == tint:
		return
	_label.text = text
	_bar.visible = bar_visible
	_summary.visible = summary_visible
	if _bar.visible:
		_apply_bar_rect()


	_bar.modulate = tint


func set_rule_summary(index: int) -> void :
	_summary_mode = true
	_summary.set_active_rule(index)
	_summary.show()
	_bar.hide()
	_layout_summary()


func _layout_summary() -> void :
	_summary.size = Vector2(BAR_W, 180)
	_summary.position = Vector2(_bar_center_x - BAR_W * 0.5, _bar_card_bottom_y - 180)


func hide_text() -> void :
	_bar.visible = false
	_summary.hide()










func layout_text_bar_bottom(center_x: float, card_bottom_y: float, safe_top_y: float) -> void :
	_bar_center_x = center_x
	_bar_card_bottom_y = card_bottom_y
	_bar_safe_top_y = safe_top_y
	_apply_bar_rect()
	_layout_summary()
















func _apply_bar_rect() -> void :

	var font_size: int = _bar_base_font_size
	_label.add_theme_font_size_override(&"font_size", font_size)
	var text_h: float = _label.get_minimum_size().y
	var min_h: float = maxf(BAR_MIN_H, minf(text_card_min_height, maxf(0.0, _bar_card_bottom_y - _bar_safe_top_y)) + CARD_PAD_T + CARD_PAD_B)
	var h: float = maxf(CARD_PAD_T + TEXT_PAD + text_h + TEXT_PAD + CARD_PAD_B, min_h)
	while font_size > 1 and _bar_card_bottom_y + CARD_PAD_B - h + CARD_PAD_T < _bar_safe_top_y:
		font_size -= 1
		_label.add_theme_font_size_override(&"font_size", font_size)
		text_h = _label.get_minimum_size().y
		h = maxf(CARD_PAD_T + TEXT_PAD + text_h + TEXT_PAD + CARD_PAD_B, min_h)
	_bar.size = Vector2(BAR_W, h)
	_bar.position = Vector2(_bar_center_x - BAR_W * 0.5, 
		_bar_card_bottom_y + CARD_PAD_B - h)












func play_drag_demo(from_global: Vector2, to_global_pos: Vector2, 
		clamp_bottom_y: float) -> void :
	var dst: Vector2 = Vector2(to_global_pos.x, minf(to_global_pos.y, clamp_bottom_y))
	var from_local: Vector2 = _to_layer(from_global)
	var dst_local: Vector2 = _to_layer(dst)
	if _hand.is_playing() and _demo_from.distance_to(from_local) <= DEMO_SAME_EPS\
	and _demo_dst.distance_to(dst_local) <= DEMO_SAME_EPS:
		return
	_demo_from = from_local
	_demo_dst = dst_local
	_hand.play(from_local, dst_local)


func stop_drag_demo() -> void :
	_hand.stop()


func is_demo_playing() -> bool:
	return _hand.is_playing()



func is_demo_visible() -> bool:
	return is_instance_valid(_hand) and _hand.is_hand_visible()




func demo_head_global() -> Vector2:
	var head: Vector2 = _hand.head()
	if head == Vector2.INF:
		return Vector2.INF
	return get_global_transform() * head


func clear_all() -> void :
	_summary_mode = false
	stop_drag_demo()
	hide_text()
	clear_focus()






func _to_layer(p: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * p



func set_focus_visuals(visuals: Dictionary) -> void :
	if not focus_enabled or visuals.is_empty():
		clear_focus()
		return
	var inverse: Transform2D = get_global_transform().affine_inverse()
	var bounds: Rect2 = inverse * Rect2(Vector2.ZERO, UiMetrics.viewport_size())
	_focus_mask.position = bounds.position
	_focus_mask.size = bounds.size
	var mask_inverse: Transform2D = _focus_mask.get_global_transform().affine_inverse()
	var pot: Dictionary = visuals["pot"]
	var pot_rect: Rect2 = pot["rect"]
	var texture: Texture2D = pot["texture"]
	if texture == null or not pot_rect.has_area():
		clear_focus()
		return
	var normalize: = Transform2D(Vector2(1.0 / pot_rect.size.x, 0.0), 
		Vector2(0.0, 1.0 / pot_rect.size.y), - pot_rect.position / pot_rect.size)
	var uv_transform: Transform2D = normalize * (pot["transform"] as Transform2D).affine_inverse() * _focus_mask.get_global_transform()
	var capsule: Rect2 = mask_inverse * (visuals["capsule_rect"] as Rect2)
	var source_capsule: Rect2 = mask_inverse * (visuals.get("source_capsule_rect", Rect2()) as Rect2)
	var region: Rect2 = Rect2(Vector2.ZERO, texture.get_size())
	if bool(pot["region_enabled"]):
		region = pot["region_rect"]
	var hframes: int = int(pot["hframes"])
	var vframes: int = int(pot["vframes"])
	var frame: int = int(pot["frame"])
	var frame_size: Vector2 = region.size / Vector2(hframes, vframes)
	region.position += Vector2(frame % hframes, frame / hframes) * frame_size
	region.size = frame_size
	var material: ShaderMaterial = _focus_mask.material as ShaderMaterial
	material.set_shader_parameter("pot_texture", texture)
	material.set_shader_parameter("pot_enabled", bool(visuals.get("focus_pot", true)))
	material.set_shader_parameter("pot_uv_x", Vector3(uv_transform.x.x, uv_transform.y.x, uv_transform.origin.x))
	material.set_shader_parameter("pot_uv_y", Vector3(uv_transform.x.y, uv_transform.y.y, uv_transform.origin.y))
	material.set_shader_parameter("pot_region", Vector4(region.position.x, region.position.y, region.size.x, region.size.y) / Vector4(texture.get_width(), texture.get_height(), texture.get_width(), texture.get_height()))
	material.set_shader_parameter("pot_flip_h", bool(pot["flip_h"]))
	material.set_shader_parameter("pot_flip_v", bool(pot["flip_v"]))
	material.set_shader_parameter("capsule_rect", Vector4(capsule.position.x, capsule.position.y, capsule.size.x, capsule.size.y))
	material.set_shader_parameter("source_capsule_rect", Vector4(source_capsule.position.x, source_capsule.position.y, source_capsule.size.x, source_capsule.size.y))
	material.set_shader_parameter("mask_size", _focus_mask.size)
	material.set_shader_parameter("dim_alpha", FOCUS_DIM_ALPHA)
	var flowers: Array[Dictionary] = []
	flowers.append_array(visuals["sources"])
	flowers.append_array(visuals["demos"])
	var ropes: Array[Dictionary] = []
	ropes.append_array(visuals.get("demo_ropes", []))
	ropes.append_array(visuals.get("drag_ropes", []))
	_sync_focus_sprites(ropes, _focus_rope_sprites, _focus_rope_art)
	_sync_focus_sprites(flowers, _focus_sprites, _focus_art)
	_focus_mask.show()



func _sync_focus_sprites(visuals: Array[Dictionary], sprites: Array[Sprite2D], host: Node2D) -> void :
	while sprites.size() < visuals.size():
		var sprite: Sprite2D = _focus_template.duplicate(0) as Sprite2D
		sprite.name = "FocusFlower%d" % sprites.size()
		host.add_child(sprite)
		sprites.append(sprite)
	var inverse: Transform2D = host.get_global_transform().affine_inverse()
	for index: int in sprites.size():
		var sprite: Sprite2D = sprites[index]
		if index >= visuals.size():
			_clear_focus_sprite(sprite)
			continue
		var visual: Dictionary = visuals[index]
		sprite.texture = visual["texture"]
		sprite.centered = bool(visual["centered"])
		sprite.offset = visual["offset"]
		sprite.region_enabled = bool(visual["region_enabled"])
		sprite.region_rect = visual["region_rect"]
		sprite.hframes = int(visual["hframes"])
		sprite.vframes = int(visual["vframes"])
		sprite.frame = int(visual["frame"])
		sprite.flip_h = bool(visual["flip_h"])
		sprite.flip_v = bool(visual["flip_v"])
		sprite.transform = inverse * (visual["transform"] as Transform2D)
		sprite.modulate = visual["modulate"]
		sprite.material = visual["material"]
		sprite.show()


func _clear_focus_sprite(sprite: Sprite2D) -> void :
	sprite.hide()
	sprite.texture = null
	sprite.material = null



func dim_page() -> void :
	clear_focus()
	if not focus_enabled:
		return
	var inverse: Transform2D = get_global_transform().affine_inverse()
	var bounds: Rect2 = inverse * Rect2(Vector2.ZERO, UiMetrics.viewport_size())
	_focus_mask.position = bounds.position
	_focus_mask.size = bounds.size
	var material: ShaderMaterial = _focus_mask.material as ShaderMaterial
	material.set_shader_parameter("mask_size", bounds.size)
	material.set_shader_parameter("dim_alpha", FOCUS_DIM_ALPHA)
	_focus_mask.show()


func clear_focus() -> void :
	_focus_mask.hide()
	var material: ShaderMaterial = _focus_mask.material as ShaderMaterial
	material.set_shader_parameter("pot_enabled", false)
	material.set_shader_parameter("pot_texture", null)
	material.set_shader_parameter("source_capsule_rect", Vector4.ZERO)
	material.set_shader_parameter("capsule_rect", Vector4.ZERO)
	for sprite: Sprite2D in _focus_sprites:
		_clear_focus_sprite(sprite)
	for sprite: Sprite2D in _focus_rope_sprites:
		_clear_focus_sprite(sprite)
