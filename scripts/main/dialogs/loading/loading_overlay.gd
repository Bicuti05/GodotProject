class_name LoadingOverlay
extends PageScene





const _SPIN_SPEED: = 4.2


const _REVEAL_DELAY_SEC: = 0.15

@onready var _spinner: TextureRect = $Card / Spinner
@onready var _dim: ColorRect = $Dim
@onready var _card: Panel = $Card

var _angle: float = 0.0
var _show_seq: int = 0


func _ready() -> void :
	set_process(false)


func _on_show(_params: Dictionary = {}) -> void :
	_show_seq += 1
	visible = true
	_angle = 0.0
	_dim.visible = false
	_card.visible = false
	if _spinner != null:
		_spinner.rotation = 0.0
	set_process(false)
	_reveal_visual_after_delay(_show_seq)


func _on_hide() -> void :
	_show_seq += 1
	set_process(false)
	visible = false


func _reveal_visual_after_delay(seq: int) -> void :
	await get_tree().create_timer(_REVEAL_DELAY_SEC).timeout
	if seq != _show_seq or not visible:
		return
	_dim.visible = true
	_card.visible = true
	set_process(true)


func _process(delta: float) -> void :
	_angle = wrapf(_angle + _SPIN_SPEED * delta, 0.0, TAU)
	if _spinner != null:
		_spinner.rotation = _angle
