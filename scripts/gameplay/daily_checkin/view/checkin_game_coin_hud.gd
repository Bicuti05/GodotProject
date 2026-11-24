extends Control


const COIN_HUD_WIDTH: = 270.0
const COIN_ICON_SIZE: = 88.0
const COIN_ICON_VISIBLE_INSET_LEFT: = 7.0
const COIN_ICON_VISIBLE_WIDTH: = 74.0
const COIN_ICON_TEXT_GAP: = 8.0
const COIN_TEXT_MAX_W: = 160.0
const COIN_FONT_MAX: = 64
const COIN_FONT_MIN: = 36
const PUNCH_SCALE: = 1.2
const PUNCH_SECONDS: = 0.18
@onready var label: Label = $CoinLabel
@onready var icon: TextureRect = $CoinIcon
var punch_tween: Tween
var layout_value: = 0

func set_display(value: int, reserved_value: int = -1) -> void :
	label.text = str(value)
	layout_value = value if reserved_value < 0 else reserved_value
	var font = label.get_theme_font("font")
	var font_size = COIN_FONT_MAX
	var text_width: = 0.0
	while true:
		text_width = font.get_string_size(str(layout_value), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		if text_width <= COIN_TEXT_MAX_W or font_size <= COIN_FONT_MIN: break
		font_size -= 2
	text_width = minf(text_width, COIN_TEXT_MAX_W)
	label.add_theme_font_size_override("font_size", font_size)

	var group_width = COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP + text_width
	var group_left = (COIN_HUD_WIDTH - group_width) * 0.5
	icon.offset_left = group_left - COIN_ICON_VISIBLE_INSET_LEFT
	icon.offset_right = icon.offset_left + COIN_ICON_SIZE
	var center = group_left + COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP + text_width * 0.5
	label.offset_left = center - COIN_TEXT_MAX_W * 0.5
	label.offset_right = center + COIN_TEXT_MAX_W * 0.5

func icon_target_rect() -> Rect2:
	var used = icon.texture.get_image().get_used_rect()
	var source_size = icon.texture.get_size()
	var ratio = minf(icon.size.x / source_size.x, icon.size.y / source_size.y)
	var pad = (icon.size - source_size * ratio) * 0.5
	return icon.get_global_transform() * Rect2(pad + Vector2(used.position) * ratio, Vector2(used.size) * ratio)

func icon_design_width() -> float:
	return icon.texture.get_image().get_used_rect().size.x * icon.size.x / icon.texture.get_width()

func punch(motion: Node) -> void :
	if punch_tween != null and punch_tween.is_valid(): punch_tween.kill()
	icon.scale = Vector2.ONE * PUNCH_SCALE

	punch_tween = motion.animate()
	punch_tween.tween_property(icon, "scale", Vector2.ONE, PUNCH_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func reset() -> void :
	if punch_tween != null and punch_tween.is_valid(): punch_tween.kill()
	punch_tween = null
	icon.scale = Vector2.ONE
