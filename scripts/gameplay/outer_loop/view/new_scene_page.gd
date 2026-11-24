class_name NewScenePage
extends PageScene


















signal cover_opaque
signal closed


const SCRIM_ALPHA: float = 0.88
const CIRCLE_START_D: float = 40.0
const CIRCLE_GROW_SEC: float = 0.55
const SCRIM_FADE_SEC: float = 0.3
const MORPH_SEC: float = 0.7
const TITLE_FADE_SEC: float = 0.2
const BTN_POP_DELAY_SEC: float = 0.1
const BTN_POP_SEC: float = 0.28
const FRAME_CORNER_RADIUS: int = 36
const MORPH_BLACK_START: float = 0.6
const MORPH_BLACK_FADE_SEC: float = CIRCLE_GROW_SEC + MORPH_SEC


const OUTRO_FADE_SEC: float = 0.12
const ZOOM_SEC: float = 0.5
const ZOOM_MARGIN: float = 1.02
const FLASH_IN_SEC: float = 0.12
const FLASH_OUT_SEC: float = 0.3

@onready var _scrim: ColorRect = $Scrim
@onready var _morph: TextureRect = $MorphShape
@onready var _content: Control = $Content
@onready var _title: Label = $Content / Title
@onready var _picture: Control = $Content / Picture
@onready var _image: TextureRect = $Content / Picture / Image
@onready var _claim_btn: CommonBtn = $Content / ClaimBtn
@onready var _flash: ColorRect = $Flash


var _picture_base_pos: Vector2 = Vector2.ZERO
var _title_font_size: int = 0




var _tween: Tween = null
var _title_tween: Tween = null
var _black_tween: Tween = null


var _morph_material: ShaderMaterial = null
var _cover_is_opaque: bool = false
var _closed: bool = false
var _can_claim: bool = false

var _hex_aspect: float = 1.0


func _ready() -> void :



	_picture_base_pos = _picture.position
	_title_font_size = _title.get_theme_font_size("font_size")
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_morph_material = _morph.material as ShaderMaterial
	if _morph_material == null:
		SortLogger.error("NewScenePage: MorphShape 缺少 ShaderMaterial(chapter_reveal_mask)")


func _on_show(params: Dictionary = {}) -> void :
	_cover_is_opaque = false
	_closed = false
	set_title(String(params.get("title", "")))
	_kill_tweens()
	_can_claim = false
	var chapter_image: Texture2D = params.get("image", null) as Texture2D
	_image.texture = chapter_image
	_morph.texture = chapter_image
	if chapter_image != null and _morph_material != null:
		_morph_material.set_shader_parameter("tex_size_px", chapter_image.get_size())
	_set_morph_black_alpha(MORPH_BLACK_START)
	var vp: Vector2 = UiMetrics.viewport_size()
	var origin: Vector2 = params.get("origin", vp * 0.5)

	var origin_d: float = maxf(float(params.get("origin_diameter", vp.x * 0.88)), CIRCLE_START_D + 1.0)
	_hex_aspect = maxf(float(params.get("shape_aspect", 1.0)), 0.1)
	_set_morph_hex_amount(1.0)

	visible = true
	modulate.a = 1.0

	_scrim.color.a = 0.0
	_flash.color.a = 0.0
	_content.visible = true
	_title.modulate.a = 0.0
	_picture.visible = false
	_picture.position = _picture_base_pos
	_picture.scale = Vector2.ONE
	_claim_btn.modulate.a = 1.0
	_claim_btn.scale = Vector2.ZERO
	_morph.visible = true
	_step_circle(CIRCLE_START_D, origin)
	_play_intro(origin, origin_d)





func _play_intro(origin: Vector2, origin_d: float) -> void :
	AudioManager.play_sfx(&"outerloop_chapter_bg_unlock")
	_tween = create_tween()
	_tween.tween_method(_step_circle.bind(origin), CIRCLE_START_D, origin_d, CIRCLE_GROW_SEC)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_scrim, "color:a", SCRIM_ALPHA, SCRIM_FADE_SEC)\
	.set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_method(_step_morph.bind(origin, origin_d), 0.0, 1.0, MORPH_SEC)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_reveal_picture)
	_tween.tween_interval(BTN_POP_DELAY_SEC)
	_tween.tween_property(_claim_btn, "scale", Vector2.ONE, BTN_POP_SEC)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback( func() -> void : _can_claim = true)

	_black_tween = create_tween()
	_black_tween.tween_method(_set_morph_black_alpha, MORPH_BLACK_START, 0.0, MORPH_BLACK_FADE_SEC)\
	.set_trans(Tween.TRANS_SINE)




func _step_circle(d: float, origin: Vector2) -> void :
	var sz: Vector2 = _shape_size(d)
	_morph.size = sz
	_morph.global_position = origin - sz * 0.5
	_set_morph_corner(int(round(sz.y * 0.5)))
	_sync_morph_rect_size()



func _shape_size(d: float) -> Vector2:
	return Vector2(d, d / _hex_aspect)




func _step_morph(t: float, origin: Vector2, d0: float) -> void :
	var from_size: Vector2 = _shape_size(d0)
	var from_pos: Vector2 = origin - from_size * 0.5
	var to_rect: Rect2 = _picture.get_global_rect()
	_morph.global_position = from_pos.lerp(to_rect.position, t)
	_morph.size = from_size.lerp(to_rect.size, t)
	_set_morph_corner(int(round(lerpf(from_size.y * 0.5, float(FRAME_CORNER_RADIUS), t))))

	_set_morph_hex_amount(1.0 - t)
	_sync_morph_rect_size()


func _set_morph_corner(r: int) -> void :
	if _morph_material == null:
		return
	_morph_material.set_shader_parameter("radius_px", float(r))



func _sync_morph_rect_size() -> void :
	if _morph_material == null:
		return
	_morph_material.set_shader_parameter("rect_size_px", _morph.size)


func _set_morph_hex_amount(v: float) -> void :
	if _morph_material == null:
		return
	_morph_material.set_shader_parameter("hex_amount", v)


func _set_morph_black_alpha(a: float) -> void :
	if _morph_material == null:
		return
	_morph_material.set_shader_parameter("black_alpha", a)



func _reveal_picture() -> void :
	_morph.visible = false
	_picture.visible = true
	if _title_tween != null and _title_tween.is_valid():
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "modulate:a", 1.0, TITLE_FADE_SEC)\
	.set_trans(Tween.TRANS_SINE)


func _kill_tweens() -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _title_tween != null and _title_tween.is_valid():
		_title_tween.kill()
	_title_tween = null
	if _black_tween != null and _black_tween.is_valid():
		_black_tween.kill()
	_black_tween = null


func _on_hide() -> void :
	_kill_tweens()
	_can_claim = false
	visible = false


func _on_claim_pressed() -> void :
	if not _can_claim:
		return
	_can_claim = false
	AudioManager.play_sfx(&"outerloop_chapter_bg_claim")
	_play_outro()





func _play_outro() -> void :
	_kill_tweens()
	var vp: Vector2 = UiMetrics.viewport_size()
	var zoom: float = maxf(vp.x / _picture.size.x, vp.y / _picture.size.y) * ZOOM_MARGIN





	var center_in_parent: Vector2 = vp * 0.5 - _content.global_position
	var centered: Vector2 = center_in_parent - _picture.pivot_offset
	_tween = create_tween()
	_tween.tween_property(_title, "modulate:a", 0.0, OUTRO_FADE_SEC).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(_claim_btn, "modulate:a", 0.0, OUTRO_FADE_SEC)\
	.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_picture, "scale", Vector2.ONE * zoom, ZOOM_SEC)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(_picture, "position", centered, ZOOM_SEC)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_flash, "color:a", 1.0, FLASH_IN_SEC).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(_on_cover_opaque)
	_tween.tween_property(_flash, "color:a", 0.0, FLASH_OUT_SEC).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback( func() -> void : _finish_outro())




func _on_cover_opaque() -> void :
	_content.visible = false
	_scrim.color.a = 0.0
	_cover_is_opaque = true
	cover_opaque.emit()


func _finish_outro() -> void :
	_closed = true
	closed.emit()


func is_cover_opaque() -> bool:
	return _cover_is_opaque


func is_closed() -> bool:
	return _closed



func set_title(title: String) -> void :
	_title.text = title

	var outline: float = float(_title.get_theme_constant("outline_size"))
	var text_area: = Vector2(_content.size.x + _title.offset_right - _title.offset_left, 
		_title.offset_bottom - _title.offset_top) - Vector2.ONE * outline * 2.0
	var paragraph: = TextParagraph.new()
	paragraph.width = text_area.x
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var font: Font = _title.get_theme_font("font")
	var font_size: int = _title_font_size
	while font_size > 1:
		paragraph.clear()
		paragraph.add_string(title, font, font_size)
		var line_spacing: float = float(_title.get_theme_constant("line_spacing"))\
		* maxi(paragraph.get_line_count() - 1, 0)
		if paragraph.get_size().y + line_spacing <= text_area.y:
			break
		font_size -= 1
	_title.add_theme_font_size_override("font_size", font_size)
