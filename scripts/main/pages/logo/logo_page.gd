class_name LogoPage
extends PageScene



const _PHONE_LOGO_WIDTH_RATIO: float = 2.0 / 3.0
const _TABLET_LOGO_WIDTH_RATIO: float = 1.0 / 2.0

const _LOGO_VISIBLE_WIDTH_RATIO: float = 770.0 / 800.0

@onready var _logo: TextureRect = $Logo

var _fade_tween: Tween = null


func _ready() -> void :
	get_viewport().size_changed.connect(_layout_logo)
	_layout_logo()


func _on_show(_params: Dictionary) -> void :
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	modulate.a = 1.0
	_layout_logo()


func _on_hide() -> void :
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	visible = false



func fade_out(duration_seconds: float) -> void :
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, duration_seconds)\
	.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await _fade_tween.finished
	_fade_tween = null


func _layout_logo() -> void :
	if _logo == null or not is_instance_valid(_logo):
		return
	var viewport_size: Vector2 = UiMetrics.viewport_size()
	var shortest_side: float = minf(viewport_size.x, viewport_size.y)
	var width_ratio: float = (_TABLET_LOGO_WIDTH_RATIO
		if UiMetrics.is_tablet() else _PHONE_LOGO_WIDTH_RATIO)
	var logo_width: float = shortest_side * width_ratio / _LOGO_VISIBLE_WIDTH_RATIO
	var texture_size: Vector2 = _logo.texture.get_size()
	var logo_height: float = logo_width * texture_size.y / texture_size.x
	_logo.size = Vector2(logo_width, logo_height)
	_logo.position = (viewport_size - _logo.size) * 0.5
