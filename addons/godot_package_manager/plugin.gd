@tool
extends EditorPlugin

const Main: = preload("res://addons/godot_package_manager/main.tscn")
const GPM: = preload("res://addons/godot_package_manager/godot_package_manager.gd")

const MENU_ITEM_TEXT: = "Package Manager"
const MENU_ITEM_ID: = 9901

var main
var _window: Window
var _window_menu: PopupMenu


func _enter_tree():
	main = Main.instantiate()
	main.plugin = self
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_window = Window.new()
	_window.title = "Package Manager"
	_window.size = Vector2i(900, 600)
	_window.hide()
	_window.close_requested.connect(_window.hide)
	_window.add_child(main)
	get_editor_interface().get_base_control().add_child(_window)
	call_deferred("_setup_window_menu")


func _setup_window_menu() -> void :
	_window_menu = _search_for_menu(get_tree().root, "Project")
	if _window_menu:
		_window_menu.add_separator()
		_window_menu.add_item(MENU_ITEM_TEXT, MENU_ITEM_ID)
		_window_menu.id_pressed.connect(_on_window_menu_id_pressed)
	else:
		push_warning("[GodotPackageManager] 未找到 Project 菜单")


func _exit_tree():
	if is_instance_valid(_window_menu):
		var idx: = _window_menu.get_item_index(MENU_ITEM_ID)
		if idx != -1:
			_window_menu.remove_item(idx)
			if idx > 0 and _window_menu.is_item_separator(idx - 1):
				_window_menu.remove_item(idx - 1)
		if _window_menu.id_pressed.is_connected(_on_window_menu_id_pressed):
			_window_menu.id_pressed.disconnect(_on_window_menu_id_pressed)
	if is_instance_valid(_window):
		_window.free()


func _search_for_menu(node: Node, menu_title: String) -> PopupMenu:
	if node is MenuBar:
		for i in node.get_menu_count():
			if node.get_menu_title(i) == menu_title:
				return node.get_menu_popup(i)
	for child in node.get_children():
		var result: = _search_for_menu(child, menu_title)
		if result:
			return result
	return null


func _on_window_menu_id_pressed(id: int) -> void :
	if id != MENU_ITEM_ID:
		return
	if _window.visible:
		_window.grab_focus()
	else:
		main._refresh_package_list()
		main._check_self_update()
		_window.popup_centered_ratio(0.6)


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if is_instance_valid(main):
			main._on_update(false)
