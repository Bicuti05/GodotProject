extends CanvasLayer


@onready var _banner: GameStartBanner = $Banner

var _generation: int = 0
var _opened: bool = false
var _paused_before: bool = false


func open(super_hard: bool = false, flower_style: bool = false) -> void :
	if not _opened:
		_paused_before = get_tree().paused
	_opened = true
	_generation += 1
	var generation: int = _generation
	get_tree().paused = true
	visible = true
	var style: GameStartBanner.HardStyle = GameStartBanner.HardStyle.FLOWER_CHARACTER if flower_style else\
	GameStartBanner.HardStyle.NEW
	await _banner.show_hard(3, super_hard, style)
	if generation == _generation:
		close()


func close() -> void :
	_generation += 1
	_banner.hide_now()
	visible = false
	_restore_pause()


func _unhandled_key_input(event: InputEvent) -> void :
	if _opened and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void :
	_generation += 1
	_restore_pause()


func _restore_pause() -> void :
	if _opened:
		get_tree().paused = _paused_before
	_opened = false
