class_name CelebrationLayer
extends Control















const LOGO_POP_FROM: float = 0.62
const LOGO_POP_DUR: float = 0.46
const LOGO_FADE_DUR: float = 0.18

@onready var _logo: TextureRect = $Logo


func _ready() -> void :
	visible = false
	get_viewport().size_changed.connect(_layout)
	_layout()



func _layout() -> void :
	_logo.pivot_offset = _logo.size * 0.5



func play() -> void :
	visible = true
	modulate.a = 1.0
	_layout()

	_logo.modulate.a = 0.0
	_logo.scale = Vector2.ONE * LOGO_POP_FROM
	var tw: = _logo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(_logo, "modulate:a", 1.0, LOGO_FADE_DUR)
	tw.tween_property(_logo, "scale", Vector2.ONE, LOGO_POP_DUR)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



func fade_out(dur: float) -> void :
	if not visible:
		return
	var tw: = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, dur)
	tw.tween_callback( func() -> void : visible = false)


func reset() -> void :
	modulate.a = 1.0
	_logo.modulate.a = 1.0
	_logo.scale = Vector2.ONE
	_layout()
	visible = false
