class_name RankRewardTooltip
extends Control


signal closed

const SCREEN_MARGIN: float = 16.0

const OPEN_SCALE_SEC: float = 0.3
const OPEN_FADE_SEC: float = 0.15
const CLOSE_SCALE_SEC: float = 0.3
const CLOSE_FADE_SEC: float = 0.3

const _COUNT_BASE_FONT_SIZE: int = 56
const _COUNT_MIN_FONT_SIZE: int = 32
const _COUNT_BOX_W: float = 80.0
const _COUNT_BASE_OFFSET_LEFT: float = 50.0
const _COUNT_SAFE_LEFT: float = 37.0
const _COUNT_SAFE_RIGHT: float = 425.0
const _COUNT_LEFT_X_HINT: float = 110.0
const _COUNT_LEFT_X_COIN: float = 300.0

@onready var _bubble: Control = $Bubble
@onready var _hint_count: Label = $Bubble / ContentArea / Row / HintGroup / Count
@onready var _coin_count: Label = $Bubble / ContentArea / Row / CoinGroup / Count

var _tween: Tween = null


func _ready() -> void :
	visible = false


func show_at(global_rect: Rect2, reward: Dictionary) -> void :
	_hint_count.text = "x%d" % int(reward.get("hint", 0))
	_coin_count.text = "x%d" % int(reward.get("coin", 0))
	_layout_count(_hint_count, _COUNT_LEFT_X_HINT)
	_layout_count(_coin_count, _COUNT_LEFT_X_COIN)

	var bubble_size: Vector2 = _bubble.size
	var tail_tip: Vector2 = Vector2(
		global_rect.position.x + global_rect.size.x * 0.5, 
		global_rect.position.y
	)
	var pos: Vector2 = Vector2(tail_tip.x - bubble_size.x * 0.5, tail_tip.y - bubble_size.y)
	pos.x = clampf(pos.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, size.x - bubble_size.x - SCREEN_MARGIN))
	pos.y = clampf(pos.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, size.y - bubble_size.y - SCREEN_MARGIN))
	_bubble.position = pos
	_bubble.pivot_offset = Vector2(bubble_size.x * 0.5, bubble_size.y)

	_kill_tween()
	_bubble.scale = Vector2.ZERO
	_bubble.modulate.a = 0.0
	visible = true
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_bubble, "scale", Vector2.ONE, OPEN_SCALE_SEC)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_bubble, "modulate:a", 1.0, OPEN_FADE_SEC)


func hide_tooltip() -> void :
	_kill_tween()
	visible = false


func _layout_count(label: Label, left_x: float) -> void :
	var font: Font = label.get_theme_font("font")
	if font == null or label.text.is_empty():
		return
	var outline: float = float(label.get_theme_constant("outline_size"))
	var avail_max: float = _COUNT_SAFE_RIGHT - _COUNT_SAFE_LEFT - outline * 2.0
	var font_size: int = _COUNT_BASE_FONT_SIZE
	while font_size > _COUNT_MIN_FONT_SIZE:
		if font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x <= avail_max:
			break
		font_size -= 2
	label.add_theme_font_size_override("font_size", font_size)
	var w: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
	var rect_w: float = maxf(_COUNT_BOX_W, w)
	var ink_right: float = left_x + (rect_w + w) * 0.5 + outline
	var shift: float = maxf(ink_right - _COUNT_SAFE_RIGHT, 0.0)
	var ink_left: float = left_x + (rect_w - w) * 0.5 - outline
	shift = minf(shift, maxf(ink_left - _COUNT_SAFE_LEFT, 0.0))
	label.offset_left = _COUNT_BASE_OFFSET_LEFT - shift
	label.offset_right = label.offset_left + _COUNT_BOX_W


func _on_catcher_pressed() -> void :
	closed.emit()
	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_bubble, "scale", Vector2.ZERO, CLOSE_SCALE_SEC)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_bubble, "modulate:a", 0.0, CLOSE_FADE_SEC)
	_tween.chain().tween_callback( func() -> void : visible = false)


func _kill_tween() -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
