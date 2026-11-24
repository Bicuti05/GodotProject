class_name PageScene
extends Control


func _on_show(params: Dictionary) -> void :
	pass



func _on_hide() -> void :
	visible = false








func _on_back_request() -> void :
	pass

func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _is_topmost_visible_page():
		_on_back_request()

func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel") and _is_topmost_visible_page():
		_on_back_request()
		accept_event()






func _is_topmost_visible_page() -> bool:
	return SceneManager.is_topmost(self)
