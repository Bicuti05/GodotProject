class_name DailyFirstWinCheckinDialog
extends DialogScene

var _closed: bool = true
var _generation: int = 0
var _resetting: bool = false
@onready var _view: Control = $Presentation

func _on_show(params: Dictionary) -> void :

	_generation += 1
	_closed = false

	var preparing_generation: int = _generation
	var prepared: bool = await _view.wait_for_preparation()
	if not visible or preparing_generation != _generation:
		return
	if not prepared:
		_closed = true
		visible = false
		return
	var entrance_params: Dictionary = params.duplicate()
	var original_handoff: Callable = params.get("background_handoff", Callable())


	entrance_params["background_handoff"] = func() -> void :
		if original_handoff.is_valid():
			original_handoff.call()
		_view.play_settlement(params["settlement"])
	await super._on_show(entrance_params)

	Tracker.track_dlg_show(TrackingEvents.DLG_DAILY_CHECKIN)

func reset_content() -> void :
	_generation += 1
	_closed = false
	if is_instance_valid(_view):
		_resetting = true
		_view.close_presentation(true)
		_view.prepare_hidden_entrance()
		_resetting = false

func _on_hide() -> void :
	reset_content()
	_closed = true
	await super._on_hide()
	Tracker.clear_current_dlg(TrackingEvents.DLG_DAILY_CHECKIN)

func _on_presentation_closed() -> void :
	if not _resetting:
		_closed = true



func _on_continue_pressed() -> void :
	Tracker.track_btn_click(TrackingEvents.BTN_CONFIRM)

func is_closed() -> bool:
	return _closed or not visible

func _on_back_request() -> void :
	if _view.can_close():
		_view.close_presentation()
