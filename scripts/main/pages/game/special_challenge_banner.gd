class_name SpecialChallengeBanner
extends Control

const IN_DURATION: float = 0.35
const CHEST_POSITION: Vector2 = Vector2(275.0, 943.0)
const STAR_POSITIONS: Array[Vector2] = [Vector2(242, 1000), Vector2(843, 1058), Vector2(324, 889), Vector2(780, 905), Vector2(190, 1258), Vector2(875, 1280)]
const HOLD_DURATION: float = 1.5
const OUT_DURATION: float = 0.65
const TEXT_WIDTH: float = 900.0
const DESCRIPTION_HEIGHT: float = 170.0
const TITLE_FONT_SIZE: int = 115
const TITLE_CENTER_Y: float = 686.115
const TITLE_TEXTURE_PADDING: float = 64.0
const DESCRIPTION_FONT_SIZE: int = 60
var _title_locale: String = ""
var _generation: int = 0
var _tween: Tween = null
var _dst_chest: Control = null
var _dst_was_visible: bool = false
var _chest_flight_source: Rect2
@onready var _content: Control = $Content
@onready var _card: Control = $Content / Card
@onready var _chest: TextureRect = $Content / Chest
@onready var _backdrop: ColorRect = $Backdrop
@onready var _sparkles: Node2D = $Content / Sparkles
@onready var _title: CurveLabel = $TitleViewport / GlowViewport / MaskViewport / Title
@onready var _title_viewport: SubViewport = $TitleViewport
@onready var _title_mask_viewport: SubViewport = $TitleViewport / GlowViewport / MaskViewport
@onready var _title_glow_viewport: SubViewport = $TitleViewport / GlowViewport
@onready var _title_blur_surface: TextureRect = $TitleViewport / GlowViewport / Surface
@onready var _title_texture: TextureRect = $Content / Card / TitleComposite / Title
@onready var _title_surface: TextureRect = $TitleViewport / Surface
@onready var _description: Label = $Content / Card / Description


func _ready() -> void :
	_title_surface.texture = _title_mask_viewport.get_texture()
	(_title_surface.material as ShaderMaterial).set_shader_parameter(&"title_mask", _title_surface.texture)
	(_title_surface.material as ShaderMaterial).set_shader_parameter(&"horizontal_blur", _title_glow_viewport.get_texture())
	_title_blur_surface.texture = _title_surface.texture
	(_title_blur_surface.material as ShaderMaterial).set_shader_parameter(&"title_mask", _title_surface.texture)
	_title_texture.texture = _title_viewport.get_texture()
	_fit_text()



func play(dst_chest: Control = null) -> bool:
	cancel()
	var generation: int = _generation
	_dst_chest = dst_chest
	_dst_was_visible = is_instance_valid(_dst_chest) and _dst_chest.visible
	if is_instance_valid(_dst_chest):
		_dst_chest.visible = false
	_layout_content()
	_fit_text()
	_chest.position = CHEST_POSITION
	_card.pivot_offset = Vector2(540.0, 1160.0)
	_chest.pivot_offset = Vector2(267.0, 460.0)
	_sample_intro_motion(0.0)
	_chest.size = Vector2(534.0, 485.0)
	visible = true
	AudioManager.play_sfx(&"special_challenge_banner_appear", 1.4)
	_backdrop.modulate.a = 0.0
	_set_card_opacity(0.0)
	_chest.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_backdrop, "modulate:a", 1.0, IN_DURATION)
	_tween.tween_method(_set_card_opacity, 0.0, 1.0, IN_DURATION)
	_tween.tween_property(_chest, "modulate:a", 1.0, IN_DURATION)
	_tween.tween_method(_sample_intro_motion, 0.0, IN_DURATION, IN_DURATION)
	_tween.chain()
	_tween.tween_method(_sample_intro_motion, IN_DURATION, IN_DURATION + HOLD_DURATION, HOLD_DURATION)
	_tween.chain().tween_callback(_prepare_chest_flight)
	_tween.chain()
	_tween.tween_property(_backdrop, "modulate:a", 0.0, OUT_DURATION)
	_tween.parallel().tween_method(_set_card_opacity, 1.0, 0.0, OUT_DURATION)
	if is_instance_valid(_dst_chest):
		_tween.parallel().tween_method(_fly_chest, 0.0, 1.0, OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		_tween.parallel().tween_property(_chest, "modulate:a", 0.0, OUT_DURATION)
	while generation == _generation and _tween != null and _tween.is_running():
		await get_tree().process_frame
	if generation == _generation:
		_restore_dst_chest()
		visible = false
		_tween = null
		return true
	return false


func _set_card_opacity(alpha: float) -> void :

	for child: CanvasItem in _card.get_children():
		if child is CanvasGroup:
			child.self_modulate.a = alpha
		else:
			child.modulate.a = alpha


func _sample_intro_motion(age: float) -> void :
	var progress: float = clampf(age / IN_DURATION, 0.0, 1.0)
	var pop: float = sin(progress * PI) * (1.0 - progress)
	_card.scale = Vector2.ONE * (lerpf(0.95, 1.0, smoothstep(0.0, 1.0, progress)) + pop * 0.06)
	var chest_pop: float = sin(progress * PI) * 0.07
	_chest.scale = Vector2.ONE * (lerpf(0.84, 1.0, 1.0 - pow(1.0 - progress, 3.0)) + chest_pop)
	var idle: float = smoothstep(IN_DURATION, IN_DURATION + 0.25, age) * smoothstep(0.0, 0.25, IN_DURATION + HOLD_DURATION - age)
	_chest.position = CHEST_POSITION + Vector2(0.0, (1.0 - progress) * 28.0 + sin((age - IN_DURATION) * TAU / 1.6) * 3.0 * idle)
	_chest.rotation = deg_to_rad(sin((age - IN_DURATION) * TAU / 1.8) * 0.6 * idle)
	for i: int in _sparkles.get_child_count():
		var star: Sprite2D = _sparkles.get_child(i)
		var life: float = age - (0.35 + float(i) * 0.23)
		var phase: float = clampf(life / 0.65, 0.0, 1.0)
		var pulse: float = sin(phase * PI)
		star.modulate.a = pulse * 0.9
		star.scale = Vector2.ONE * (42.0 + float(i % 3) * 9.0) / float(star.texture.get_width()) * pulse
		star.rotation = phase * 0.5 * (-1.0 if i % 2 == 0 else 1.0)
		star.position = STAR_POSITIONS[i] + Vector2(0.0, - phase * 18.0)

func _reset_intro_motion() -> void :
	if not is_node_ready():
		return
	_card.scale = Vector2.ONE
	_chest.scale = Vector2.ONE
	_chest.rotation = 0.0
	_chest.position = CHEST_POSITION
	for star: Sprite2D in _sparkles.get_children():
		star.modulate.a = 0.0


func _prepare_chest_flight() -> void :
	_chest_flight_source = _chest.get_global_rect()

func _fly_chest(progress: float) -> void :
	var src_rect: Rect2 = _chest_flight_source
	if not is_instance_valid(_dst_chest):
		return
	var dst_rect: Rect2 = _dst_chest.get_global_rect()
	var chest_size: Vector2 = src_rect.size.lerp(dst_rect.size, progress)
	var center: Vector2 = src_rect.get_center().lerp(dst_rect.get_center(), progress)
	center.x -= sin(progress * PI) * 140.0
	_chest.size = chest_size
	_chest.global_position = center - chest_size * 0.5


func _layout_content() -> void :
	var insets: Vector2 = UiMetrics.safe_insets()
	_content.position = Vector2(UiMetrics.center_left(UiMetrics.DESIGN.x), 
		insets.x + (UiMetrics.viewport_size().y - insets.x - insets.y - UiMetrics.DESIGN.y) * 0.5)


func _fit_text() -> void :
	_fit_title()
	var description_font: Font = _description.get_theme_font(&"font")
	var description_text: String = tr(_description.text)
	var description_size: int = DESCRIPTION_FONT_SIZE
	while description_size > 1:
		var paragraph: TextParagraph = TextParagraph.new()
		paragraph.width = TEXT_WIDTH
		paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND\
		| TextServer.BREAK_ADAPTIVE | TextServer.BREAK_TRIM_EDGE_SPACES
		paragraph.add_string(description_text, description_font, description_size, TranslationServer.get_locale())
		var line_count: int = paragraph.get_line_count()
		var height: float = float(maxi(0, line_count - 1)) * float(_description.get_theme_constant(&"line_spacing"))
		for line_index: int in line_count:
			height += maxf(description_font.get_height(description_size), paragraph.get_line_size(line_index).y)
		if height <= DESCRIPTION_HEIGHT:
			break
		description_size -= 1
	_description.add_theme_font_size_override(&"font_size", description_size)
	_description.size = Vector2(TEXT_WIDTH, DESCRIPTION_HEIGHT)


func _fit_title() -> void :
	var locale: String = TranslationServer.get_locale()
	var title_text: String = tr("SPECIAL_CHALLENGE_BUTTON").to_upper()
	if _title_locale == locale and _title.text == title_text:
		return
	_title_locale = locale
	var title_font: Font = _title.get_theme_font(&"font")
	_title.text = title_text
	_title.language = locale
	var layout: Dictionary = _title._fit_spaced_line(_title.text, title_font, 
		TITLE_FONT_SIZE, TextServerManager.get_primary_interface())
	if not layout.is_empty():
		var bounds: Rect2 = layout.bounds
		_title_texture.position.y = TITLE_CENTER_Y - bounds.get_center().y - TITLE_TEXTURE_PADDING
		var material: ShaderMaterial = _title_surface.material as ShaderMaterial
		material.set_shader_parameter(&"glyph_bounds", Vector4(bounds.position.x + TITLE_TEXTURE_PADDING, 
			bounds.position.y + TITLE_TEXTURE_PADDING, bounds.size.x, bounds.size.y))
	_title_mask_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_title_glow_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_title_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _restore_dst_chest() -> void :
	if is_instance_valid(_dst_chest):
		_dst_chest.visible = _dst_was_visible
	_dst_chest = null


func is_presenting_chest() -> bool:
	return is_instance_valid(_dst_chest)


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_content()
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit_text.call_deferred()

func cancel() -> void :
	AudioManager.stop_sfx(&"special_challenge_banner_appear")
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_restore_dst_chest()
	_reset_intro_motion()
	visible = false

func _exit_tree() -> void :
	AudioManager.stop_sfx(&"special_challenge_banner_appear")
