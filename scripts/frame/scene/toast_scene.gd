class_name Toast
extends Control







@onready var _bg: NinePatchRect = $Bg
@onready var _label: Label = $Bg / Label

const _MIN_W: float = 320.0


const _MIN_H: float = 216.0
const _PAD_H: float = 56.0
const _PAD_V: float = 40.0
const _SAFE_MARGIN: float = 60.0
const _BASE_Y: float = 720.0
const _FLOAT_DIST: float = 80.0
const DEFAULT_HOLD: float = 1.6

static var _current: Toast = null




static func popup(msg: String, parent: Node, hold: float = DEFAULT_HOLD) -> void :
	if _current != null and is_instance_valid(_current):
		_current.queue_free()
	var scene: PackedScene = load("res://scripts/frame/scene/toast_scene.tscn")
	var toast: = scene.instantiate() as Toast
	_current = toast
	parent.add_child(toast)
	toast._play(msg, hold)

func _play(msg: String, hold: float) -> void :

	_bg.modulate.a = 0.0

	_label.text = tr(msg)


	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	await get_tree().process_frame
	var vp_w: float = get_viewport().get_visible_rect().size.x
	var max_w: float = vp_w - _SAFE_MARGIN * 2.0
	var text_size: Vector2 = _label.get_minimum_size()
	var want_w: float = text_size.x + _PAD_H * 2.0
	var text_h: float = text_size.y

	var w: float
	if want_w > max_w:

		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w = max_w
		_bg.size = Vector2(w, _MIN_H)
		await get_tree().process_frame
		text_h = _label.get_minimum_size().y
	else:
		w = clampf(want_w, _MIN_W, max_w)


	var h: float = maxf(text_h + _PAD_V * 2.0, _MIN_H)
	_bg.size = Vector2(w, h)
	_bg.position = Vector2((vp_w - w) / 2.0, _BASE_Y)

	var start_y: float = _bg.position.y


	var tw: = _bg.create_tween()
	tw.tween_property(_bg, "modulate:a", 1.0, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(_bg, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


	var tw_pos: = _bg.create_tween()
	tw_pos.tween_property(_bg, "position:y", 
		start_y - _FLOAT_DIST, hold + 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
