class_name JuiceRankGiftFlight
extends Node2D


var tween: Tween
var _body: Sprite2D
var _contents: Sprite2D
var _filled_texture: Texture2D
var _has_empty_base: bool = false
var _display_size: Vector2 = Vector2.ZERO

func prepare(texture: Texture2D, empty_texture: Texture2D = null) -> void :
	reset_now()
	_filled_texture = texture
	_has_empty_base = empty_texture != null
	if _body == null:
		_body = Sprite2D.new()
		_body.name = "Body"
		_body.texture = empty_texture if _has_empty_base else texture
		_body.modulate.a = 1.0 if _has_empty_base else 0.0
		add_child(_body)
	if _contents == null:
		_contents = Sprite2D.new()
		_contents.name = "FilledContents"
		_contents.texture = texture
		_contents.modulate.a = 0.0
		_contents.visible = _has_empty_base
		add_child(_contents)
	_body.texture = empty_texture if _has_empty_base else texture
	_body.modulate.a = 1.0 if _has_empty_base else 0.0
	_contents.texture = texture
	_contents.modulate.a = 0.0
	_contents.visible = _has_empty_base

func play(from_rect: Rect2, dst_provider: Callable, times: Vector4, rise: float, lead: float, 
		hold_rise_ratio: float = 0.08) -> Tween:
	var parent: Node2D = get_parent() as Node2D
	var from_center: Vector2 = parent.to_local(from_rect.get_center())
	var from_size: Vector2 = from_rect.size / parent.global_transform.get_scale()
	var hold_from: Vector2 = from_center - Vector2(0.0, rise * (1.0 - hold_rise_ratio))
	var lift_center: Vector2 = from_center - Vector2(0.0, rise)
	position = from_center

	_appear(0.0, from_size)
	if lead <= 0.0:
		show()
	tween = create_tween()
	tween.tween_interval(lead)
	tween.tween_callback(show)
	tween.tween_method(_appear.bind(from_size), 0.0, 1.0, times.x)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_appearance)
	tween.tween_property(self, "position", hold_from, times.y)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "position", lift_center, times.z)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_fly.bind(lift_center, from_size, dst_provider), 0.0, 1.0, times.w)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return tween

func _place(size: Vector2) -> void :
	_display_size = size
	_body.scale = size / _body.texture.get_size()
	_contents.scale = size / _filled_texture.get_size()

func _appear(u: float, size: Vector2) -> void :

	var squeeze: float = sin(u * PI) * 0.025
	_place(size * Vector2(1.0 + squeeze, 1.0 - squeeze))
	_body.modulate.a = 1.0 if _has_empty_base else u
	_contents.modulate.a = u

func _finish_appearance() -> void :

	_body.texture = _filled_texture
	_body.modulate.a = 1.0
	_place(_display_size)
	_contents.hide()

func _fly(u: float, from_center: Vector2, from_size: Vector2, dst_provider: Callable) -> void :
	var dst: Rect2 = dst_provider.call()
	var local_center: Vector2 = get_parent().to_local(dst.get_center())
	var local_size: Vector2 = dst.size / get_parent().global_transform.get_scale()
	position = from_center.lerp(local_center, u)
	_place(from_size.lerp(local_size, u))

func reset_now() -> void :
	hide()
	if tween != null and tween.is_valid():
		tween.kill()
	tween = null
	if _contents != null:
		_contents.modulate.a = 0.0
