class_name JuiceLegacyTutorialLayer
extends Control
































const BAR_W: = 900.0

const TEXT_PAD: = 48.0



const CARD_PAD_L: = 41.0
const CARD_PAD_T: = 16.0
const CARD_PAD_R: = 40.0
const CARD_PAD_B: = 64.0


const BAR_MIN_H: = 192.0

@onready var _hand: JuiceHandDemo = $Root / HandDemo
@onready var _bar: NinePatchRect = $Root / TextBar
@onready var _label: Label = $Root / TextBar / Label



var _demo_from: Vector2 = Vector2.INF
var _demo_dst: Vector2 = Vector2.INF


const DEMO_SAME_EPS: = 0.5


var _bar_center_x: float = 0.0


var _bar_card_bottom_y: float = 0.0
var _bar_safe_top_y: float = 0.0
var _bar_base_font_size: int = 0


func _ready() -> void :
	_bar_base_font_size = _label.get_theme_font_size(&"font_size")
	clear_all()





func set_text(text: String, error: bool = false) -> void :
	_label.text = text
	_bar.visible = text != ""
	if _bar.visible:
		_apply_bar_rect()


	_bar.modulate = Color(1.0, 0.92, 0.92) if error else Color.WHITE


func hide_text() -> void :
	_bar.visible = false










func layout_text_bar_bottom(center_x: float, card_bottom_y: float, safe_top_y: float) -> void :
	_bar_center_x = center_x
	_bar_card_bottom_y = card_bottom_y
	_bar_safe_top_y = safe_top_y
	_apply_bar_rect()
















func _apply_bar_rect() -> void :

	var font_size: int = _bar_base_font_size
	_label.add_theme_font_size_override(&"font_size", font_size)
	var text_h: float = _label.get_minimum_size().y
	var h: float = maxf(CARD_PAD_T + TEXT_PAD + text_h + TEXT_PAD + CARD_PAD_B, BAR_MIN_H)
	while font_size > 1 and _bar_card_bottom_y + CARD_PAD_B - h + CARD_PAD_T < _bar_safe_top_y:
		font_size -= 1
		_label.add_theme_font_size_override(&"font_size", font_size)
		text_h = _label.get_minimum_size().y
		h = maxf(CARD_PAD_T + TEXT_PAD + text_h + TEXT_PAD + CARD_PAD_B, BAR_MIN_H)
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




func demo_head_global() -> Vector2:
	var head: Vector2 = _hand.head()
	if head == Vector2.INF:
		return Vector2.INF
	return get_global_transform() * head


func clear_all() -> void :
	stop_drag_demo()
	hide_text()






func _to_layer(p: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * p
