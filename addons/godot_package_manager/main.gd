@tool
extends PanelContainer

var plugin

var gpm = preload("res://addons/godot_package_manager/godot_package_manager.gd").new()

var package_list: ScrollContainer
var _pkg_list_container: VBoxContainer
var _selected_pkg_row: Control = null
var _blocker: Panel = null

var _detail_placeholder: Label
var _detail_content: Control
var _detail_name_label: Label
var _detail_fullname_label: Label
var _detail_version_label: Label
var _detail_update_btn: Button
var _detail_delete_btn: Button
var _detail_latest_version: String = ""
var _detail_registry_label: Label
var _detail_readme_view: TextEdit
var _detail_version_page: VBoxContainer
var _current_detail_pkg: String = ""

var _current_filter: String = "all"
var _upgradable_packages: Array = []
var _all_rows: Dictionary = {}
var _btn_all_packages: Button
var _btn_upgradable: Button
var _sidebar_normal_style: StyleBoxEmpty
var _sidebar_active_style: StyleBoxFlat

var _self_update_label: Label = null
var _self_update_btn: Button = null
var _self_latest_version: String = ""
var _is_updating: = false


func _ready() -> void :
	package_list = $BoxContainer / PanelsWrapper / OuterSplit / InnerSplit / PackagePanel / PackageList
	_pkg_list_container = VBoxContainer.new()
	_pkg_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pkg_list_container.add_theme_constant_override("separation", 0)
	package_list.add_child(_pkg_list_container)

	_sidebar_normal_style = StyleBoxEmpty.new()
	_sidebar_active_style = StyleBoxFlat.new()
	_sidebar_active_style.bg_color = Color(0.3059, 0.3059, 0.3059, 1)
	var sidebar_hover: = StyleBoxFlat.new()
	sidebar_hover.bg_color = Color(0.3059, 0.3059, 0.3059, 1)

	_btn_all_packages = $BoxContainer / PanelsWrapper / OuterSplit / SidebarPanel / SidebarButtons / AllPackages
	_btn_upgradable = $BoxContainer / PanelsWrapper / OuterSplit / SidebarPanel / SidebarButtons / Upgradable

	for btn: Button in [_btn_all_packages, _btn_upgradable]:
		btn.add_theme_stylebox_override("hover", sidebar_hover)
		btn.add_theme_stylebox_override("pressed", sidebar_hover)
		btn.add_theme_stylebox_override("focus", _sidebar_normal_style)

	_btn_all_packages.pressed.connect( func():
		_current_filter = "all"
		_apply_filter()
	)
	_btn_upgradable.pressed.connect( func():
		_current_filter = "upgradable"
		_apply_filter()
	)
	_apply_filter()

	var outer_split: = $BoxContainer / PanelsWrapper / OuterSplit as SplitContainer
	outer_split.add_theme_constant_override("separation", 2)
	var inner_split: = $BoxContainer / PanelsWrapper / OuterSplit / InnerSplit as SplitContainer
	inner_split.add_theme_constant_override("separation", 2)

	gpm.operation_started.connect(_on_operation_started)
	gpm.message_logged.connect(_on_message_logged)
	gpm.operation_checkpoint_reached.connect(_on_operation_checkpoint_reached)
	gpm.operation_finished.connect(_on_update_finished)

	var edit_package_button: = $BoxContainer / BoxContainer2 / EditPackage as Button
	edit_package_button.tooltip_text = "编辑learnings_gpm_manifest.json"
	edit_package_button.pressed.connect(_on_edit_package)

	var version_label: = $BoxContainer / BoxContainer2 / VersionLabel as Label
	var cfg: = ConfigFile.new()
	if cfg.load("res://addons/godot_package_manager/plugin.cfg") == OK:
		version_label.text = "v%s" % cfg.get_value("plugin", "version", "")

	_self_update_label = Label.new()
	_self_update_label.modulate = Color(0.4, 0.85, 0.4, 1)
	_self_update_label.hide()
	$BoxContainer / BoxContainer2.add_child(_self_update_label)

	_self_update_btn = Button.new()
	_self_update_btn.text = "↑"
	_self_update_btn.tooltip_text = "更新 Godot Package Manager"
	_self_update_btn.hide()
	_self_update_btn.pressed.connect(_on_self_update_requested)
	$BoxContainer / BoxContainer2.add_child(_self_update_btn)

	_build_detail_panel($BoxContainer / PanelsWrapper / OuterSplit / InnerSplit / DetailPanel)

	_init_manifest()


func _build_detail_panel(parent: Control) -> void :
	_detail_placeholder = Label.new()
	_detail_placeholder.text = "← 选择左侧的包查看详情"
	_detail_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_placeholder.modulate = Color(0.6, 0.6, 0.6)
	parent.add_child(_detail_placeholder)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.hide()

	var root_vbox: = VBoxContainer.new()
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 6)

	_detail_name_label = Label.new()
	_detail_name_label.add_theme_font_size_override("font_size", 32)
	_detail_name_label.clip_text = true
	_detail_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_detail_update_btn = Button.new()
	_detail_update_btn.text = "更新到最新版"
	_detail_update_btn.pressed.connect( func():
		_on_install_requested(_current_detail_pkg, _detail_latest_version)
	)

	_detail_delete_btn = Button.new()
	_detail_delete_btn.text = "删除"
	_detail_delete_btn.pressed.connect( func():
		_on_delete_requested(_current_detail_pkg)
	)

	var name_row: = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.add_child(_detail_name_label)
	name_row.add_child(_detail_update_btn)
	name_row.add_child(_detail_delete_btn)

	_detail_fullname_label = Label.new()
	_detail_fullname_label.add_theme_font_size_override("font_size", 30)
	_detail_fullname_label.modulate = Color(0.7, 0.7, 0.7)
	_detail_fullname_label.clip_text = true

	_detail_version_label = Label.new()

	_detail_registry_label = Label.new()
	_detail_registry_label.modulate = Color(0.7, 0.7, 0.7)

	var separator: = HSeparator.new()

	_detail_readme_view = TextEdit.new()
	_detail_readme_view.editable = false
	_detail_readme_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_detail_readme_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_readme_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var details_tab: = VBoxContainer.new()
	details_tab.name = "详情"
	details_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_tab.add_child(_detail_readme_view)

	_detail_version_page = VBoxContainer.new()
	_detail_version_page.add_theme_constant_override("separation", 4)
	_detail_version_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var loading_label: = Label.new()
	loading_label.text = "正在加载版本历史..."
	_detail_version_page.add_child(loading_label)

	var version_scroll: = ScrollContainer.new()
	version_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	version_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	version_scroll.add_child(_detail_version_page)

	var version_tab: = VBoxContainer.new()
	version_tab.name = "版本历史"
	version_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	version_tab.add_child(version_scroll)

	var tabs: = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(details_tab)
	tabs.add_child(version_tab)

	for node in [name_row, _detail_fullname_label, _detail_version_label, _detail_registry_label, separator, tabs]:
		root_vbox.add_child(node)

	margin.add_child(root_vbox)
	parent.add_child(margin)
	_detail_content = margin


func _show_detail(package_name: String, version: String) -> void :
	_current_detail_pkg = package_name
	_detail_placeholder.hide()
	_detail_content.show()

	_detail_name_label.text = _read_display_name(package_name)
	_detail_fullname_label.text = package_name
	_detail_version_label.text = version
	_detail_registry_label.text = "正在加载..."
	_detail_update_btn.hide()
	_detail_readme_view.text = ""

	for child in _detail_version_page.get_children():
		child.queue_free()
	var loading_lbl: = Label.new()
	loading_lbl.text = "正在加载版本历史..."
	_detail_version_page.add_child(loading_lbl)

	var res = await gpm._request_npm_manifest(package_name, version)
	if _current_detail_pkg != package_name:
		return
	_detail_apply_manifest(res)

	var doc_res = await gpm._request_package_document(package_name)
	if _current_detail_pkg != package_name:
		return
	_detail_apply_version_history(doc_res, version)


func _detail_apply_manifest(res: Object) -> void :
	if res.is_err():
		_detail_registry_label.text = ""
		_detail_readme_view.text = "加载失败：\n%s" % res.unwrap_err().to_string()
		return
	var manifest: Dictionary = res.unwrap()
	var author = manifest.get("author", "")
	var author_str: String = ""
	if author is Dictionary:
		author_str = author.get("name", "")
	elif author is String:
		author_str = author
	_detail_registry_label.text = "by %s" % author_str if not author_str.is_empty() else ""
	_detail_readme_view.text = manifest.get("readme", "（无 README）")


func _detail_apply_version_history(res: Object, installed_version: String) -> void :
	for child in _detail_version_page.get_children():
		child.queue_free()

	if res.is_err():
		var lbl: = Label.new()
		lbl.text = "加载失败：%s" % res.unwrap_err().to_string()
		_detail_version_page.add_child(lbl)
		return

	var doc: Dictionary = res.unwrap()
	var latest_version: String = doc.get("dist-tags", {}).get("latest", "")
	_detail_latest_version = latest_version
	if not latest_version.is_empty() and latest_version != installed_version:
		_detail_update_btn.text = "更新到 %s" % latest_version
		_detail_update_btn.show()

	var versions_dict: Dictionary = doc.get("versions", {})
	var version_list: Array = versions_dict.keys()
	version_list.sort()
	version_list.reverse()

	var pkg_name: = _current_detail_pkg
	for ver in version_list:
		_detail_version_page.add_child(_make_version_row(pkg_name, ver, latest_version, installed_version))
		_detail_version_page.add_child(HSeparator.new())


func _make_version_row(pkg_name: String, ver: String, latest: String, installed: String) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var ver_label: = Label.new()
	ver_label.text = ver
	ver_label.custom_minimum_size = Vector2(100, 0)

	var status_lbl: = Label.new()
	status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_lbl.modulate = Color(0.7, 0.7, 0.7)
	if ver == latest and ver == installed:
		status_lbl.text = "已安装 · 最新版本"
	elif ver == latest:
		status_lbl.text = "最新版本"
	elif ver == installed:
		status_lbl.text = "已安装"

	var btn: = Button.new()
	btn.text = "已安装" if ver == installed else "安装"
	btn.disabled = ver == installed
	if ver != installed:
		btn.pressed.connect( func(): _on_install_requested(pkg_name, ver))

	row.add_child(ver_label)
	row.add_child(status_lbl)
	row.add_child(btn)
	return row


static func _display_name(pkg_name: String) -> String:
	var dot_pos: = pkg_name.rfind(".")
	return pkg_name.substr(dot_pos + 1) if dot_pos != -1 else pkg_name


static func _read_display_name(pkg_name: String) -> String:
	var folder: = _display_name(pkg_name).replace("-", "_")
	var file: = FileAccess.open("res://addons/%s/package.json" % folder, FileAccess.READ)
	if file != null:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			var dn: String = data.get("displayName", "")
			if not dn.is_empty():
				return dn
	return folder


func _init_manifest() -> void :
	if FileAccess.file_exists(gpm.PACKAGE_FILE):
		return
	var lock_data: = {}
	var lock_res = gpm.read_config(gpm.LOCK_FILE)
	if lock_res.is_ok():
		lock_data = lock_res.unwrap()
	var recovered: = gpm._try_recover_manifest(lock_data)
	var pkg_count: int = recovered.get(gpm.PackageKeys.PACKAGES, {}).size()
	if not lock_data.is_empty():
		_log("插件已启用：manifest.json 不存在，已从 lock 文件恢复 %d 个包" % pkg_count)
	elif pkg_count > 0:
		_log("插件已启用：manifest.json 不存在，已从 addons 目录扫描到 %d 个包并恢复" % pkg_count)
	else:
		_log("插件已启用：未找到任何已安装的包记录，已创建空 manifest")



func _check_self_update() -> void :
	if not _self_latest_version.is_empty():
		if is_instance_valid(_self_update_label):
			_self_update_label.text = "↑ 新版本可用: v%s" % _self_latest_version
			_self_update_label.show()
		if is_instance_valid(_self_update_btn):
			_self_update_btn.show()
		return

	const SELF_PKG: = "com.learnings.godot.godot-package-manager"
	var cfg: = ConfigFile.new()
	if cfg.load("res://addons/godot_package_manager/plugin.cfg") != OK:
		return
	var current_version: String = cfg.get_value("plugin", "version", "")
	if current_version.is_empty():
		return

	if is_instance_valid(_self_update_label):
		_self_update_label.hide()
	if is_instance_valid(_self_update_btn):
		_self_update_btn.hide()

	var res = await gpm._request_package_document(SELF_PKG)
	if not is_instance_valid(_self_update_label):
		return
	if res.is_err():
		return

	var latest: String = res.unwrap().get("dist-tags", {}).get("latest", "")
	if latest.is_empty() or latest == current_version:
		return

	_self_latest_version = latest
	_self_update_label.text = "↑ 新版本可用: v%s" % latest
	_self_update_label.show()
	if is_instance_valid(_self_update_btn):
		_self_update_btn.show()


func _on_self_update_requested() -> void :
	var updater_scene = load("res://addons/godot_package_manager/updater/updater.tscn")
	var updater = updater_scene.instantiate()
	updater.plugin = plugin
	updater.gpm = gpm
	updater.target_version = _self_latest_version
	plugin.get_editor_interface().get_base_control().add_child(updater)
	updater.start()


func _get_installed_version(package_name: String) -> String:
	var folder: String = gpm._addon_folder_name(package_name)
	var file: = FileAccess.open("res://addons/%s/package.json" % folder, FileAccess.READ)
	if file != null:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary and data.get("name", "") == package_name:
			var ver: String = data.get("version", "")
			if not ver.is_empty():
				return ver
	return ""


func _refresh_package_list() -> void :
	for child in _pkg_list_container.get_children():
		child.queue_free()
	_selected_pkg_row = null
	_upgradable_packages.clear()
	_all_rows.clear()

	var manifest_res = gpm.read_config(gpm.PACKAGE_FILE)
	if manifest_res.is_err():
		return
	var manifest_packages: Dictionary = manifest_res.unwrap().get(gpm.PackageKeys.PACKAGES, {})
	if manifest_packages.is_empty():
		return

	for package_name in manifest_packages.keys():
		if package_name == "com.learnings.godot.godot-package-manager":
			continue
		var installed_version: = _get_installed_version(package_name)
		if installed_version.is_empty():
			continue
		var row: = _make_package_row(package_name, installed_version)
		_pkg_list_container.add_child(row)
		_all_rows[package_name] = row
		if _current_filter == "upgradable":
			row.hide()
		_check_package_update(package_name, installed_version, row.get_meta("update_indicator"))


func _make_package_row(package_name: String, version: String) -> Control:
	var row: = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)

	var hbox: = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl: = Label.new()
	name_lbl.text = _read_display_name(package_name)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true

	var ver_lbl: = Label.new()
	ver_lbl.text = version
	ver_lbl.modulate = Color(1.0, 1.0, 1.0, 0.6)

	var update_indicator: = Label.new()
	update_indicator.text = " ↑"
	update_indicator.modulate = Color(0.4, 0.85, 0.4, 1)
	update_indicator.hide()

	hbox.add_child(name_lbl)
	hbox.add_child(ver_lbl)
	hbox.add_child(update_indicator)
	margin.add_child(hbox)
	row.add_child(margin)

	row.set_meta("update_indicator", update_indicator)
	var is_first: = _pkg_list_container.get_child_count() == 0
	row.add_theme_stylebox_override("panel", _row_style(false, is_first))
	row.gui_input.connect( func(event: InputEvent) -> void :
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_package_row(row, package_name, version)
	)
	return row


func _apply_filter() -> void :
	var is_all: = _current_filter == "all"
	_btn_all_packages.add_theme_stylebox_override("normal", _sidebar_active_style if is_all else _sidebar_normal_style)
	_btn_upgradable.add_theme_stylebox_override("normal", _sidebar_active_style if not is_all else _sidebar_normal_style)

	for package_name in _all_rows:
		var row = _all_rows[package_name]
		if is_instance_valid(row):
			row.visible = is_all or package_name in _upgradable_packages

	if is_instance_valid(_selected_pkg_row) and not _selected_pkg_row.visible:
		_selected_pkg_row = null
		_detail_content.hide()
		_detail_placeholder.show()


func _check_package_update(package_name: String, installed_version: String, indicator: Label) -> void :
	var res = await gpm._request_package_document(package_name)
	if not is_instance_valid(indicator):
		return
	if res.is_err():
		return
	var latest: String = res.unwrap().get("dist-tags", {}).get("latest", "")
	if latest.is_empty() or latest == installed_version:
		return
	indicator.show()
	_upgradable_packages.append(package_name)
	if _current_filter == "upgradable":
		var row = _all_rows.get(package_name)
		if is_instance_valid(row):
			row.show()


func _row_style(selected: bool, top_border: bool) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.1725, 0.3686, 0.5255, 1) if selected else Color(0, 0, 0, 0)
	style.border_color = Color(0.45, 0.45, 0.45, 1.0)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_width_top = 1 if top_border else 0
	return style


func _select_package_row(row: Control, package_name: String, version: String) -> void :
	if is_instance_valid(_selected_pkg_row):
		var was_first: = _selected_pkg_row.get_index() == 0
		_selected_pkg_row.add_theme_stylebox_override("panel", _row_style(false, was_first))
	_selected_pkg_row = row
	row.add_theme_stylebox_override("panel", _row_style(true, row.get_index() == 0))
	_show_detail(package_name, version)


func _make_button(label: String, callback: Callable) -> Button:
	var button: = Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button


func _ensure_config_dir() -> bool:
	var abs_path: = ProjectSettings.globalize_path(gpm.CONFIG_DIR)
	if not DirAccess.dir_exists_absolute(abs_path):
		var err: = DirAccess.make_dir_recursive_absolute(abs_path)
		if err != OK:
			_log("无法创建目录 %s（错误码 %d）" % [gpm.CONFIG_DIR, err])
			return false
		_log("已创建文件夹 %s" % gpm.CONFIG_DIR)
	return true


func _on_edit_package() -> void :
	if not _ensure_config_dir():
		return

	if not FileAccess.file_exists(gpm.PACKAGE_FILE):
		var lock_data: = {}
		var lock_res: = gpm.read_config(gpm.LOCK_FILE)
		if lock_res.is_ok():
			lock_data = lock_res.unwrap()
		var recovered: = gpm._try_recover_manifest(lock_data)
		var pkg_count: int = recovered.get(gpm.PackageKeys.PACKAGES, {}).size()
		if not lock_data.is_empty():
			_log("已从 lock 文件恢复 %d 个包，重建了 manifest" % pkg_count)
		elif pkg_count > 0:
			_log("已从 addons 目录扫描到 %d 个包，重建了 manifest 和 lock" % pkg_count)
		else:
			_log("未找到 lock 文件或任何 package.json，已创建空 manifest 和 lock")

	var text_edit: = TextEdit.new()
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var status_bar: = Label.new()

	var popup: = Window.new()
	popup.title = "Editing %s" % gpm.PACKAGE_FILE
	popup.close_requested.connect(popup.queue_free)

	var _saved: = [false]

	var do_write: = func() -> bool:
		var json: = JSON.new()
		if json.parse(text_edit.text) != OK:
			status_bar.text = "第 %d 行语法错误：%s" % [json.get_error_line(), json.get_error_message()]
			_log(status_bar.text)
			return false
		if not json.data is Dictionary:
			status_bar.text = "%s 的根节点必须是一个 JSON 对象" % gpm.PACKAGE_FILE
			_log(status_bar.text)
			return false
		if not json.data.get(gpm.PackageKeys.PACKAGES, null) is Dictionary:
			status_bar.text = "缺少或无效的 '%s' 字段" % gpm.PackageKeys.PACKAGES
			_log(status_bar.text)
			return false
		if not _ensure_config_dir():
			return false
		var file: = FileAccess.open(gpm.PACKAGE_FILE, FileAccess.WRITE)
		if file == null:
			status_bar.text = "无法打开 %s 进行写入" % gpm.PACKAGE_FILE
			_log(status_bar.text)
			return false
		file.store_string(text_edit.text)
		file = null
		_saved[0] = true
		status_bar.text = "已保存"
		_log("%s 保存成功" % gpm.PACKAGE_FILE)
		return true

	popup.tree_exited.connect( func() -> void :
		if _saved[0]:
			_log("开始更新...")
			_on_update(false)
	)

	var save_bar: = HBoxContainer.new()
	save_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	save_bar.add_child(_make_button("Save", func():
		if do_write.call():
			popup.queue_free()
	))


	var search_bar: = HBoxContainer.new()
	search_bar.add_theme_constant_override("separation", 4)
	search_bar.hide()

	var search_field: = LineEdit.new()
	search_field.placeholder_text = "Find…"
	search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var search_prev: = Button.new()
	search_prev.text = "◀"
	var search_next: = Button.new()
	search_next.text = "▶"
	var search_close: = Button.new()
	search_close.text = "✕"

	for w in [search_field, search_prev, search_next, search_close]:
		search_bar.add_child(w)

	var _open_search: = func() -> void :
		search_bar.show()
		search_field.grab_focus()
		search_field.select_all()

	var _close_search: = func() -> void :
		search_bar.hide()
		text_edit.set_search_text("")
		text_edit.grab_focus()

	var _jump: = func(backward: bool) -> void :
		var term: = search_field.text
		if term.is_empty():
			return
		var flags: = TextEdit.SEARCH_BACKWARDS if backward else 0
		var col: = text_edit.get_caret_column()
		var line: = text_edit.get_caret_line()
		if not backward:
			col += 1
		var hit: = text_edit.search(term, flags, line, col)
		if hit.x == -1:
			if backward:
				var last: = text_edit.get_line_count() - 1
				hit = text_edit.search(term, flags, last, text_edit.get_line(last).length())
			else:
				hit = text_edit.search(term, 0, 0, 0)
		if hit.x != -1:
			text_edit.set_caret_line(hit.y)
			text_edit.set_caret_column(hit.x)

			text_edit.select(hit.y, hit.x, hit.y, hit.x + term.length())

	search_field.text_changed.connect( func(val: String) -> void :
		text_edit.set_search_text(val)
		text_edit.set_search_flags(0)
		if not val.is_empty():
			var hit: = text_edit.search(val, 0, 0, 0)
			if hit.x != -1:
				text_edit.set_caret_line(hit.y)
				text_edit.set_caret_column(hit.x)

				text_edit.select(hit.y, hit.x, hit.y, hit.x + val.length())
	)
	search_field.gui_input.connect( func(event: InputEvent) -> void :
		if not (event is InputEventKey and event.pressed and not event.echo):
			return
		if event.keycode == KEY_ESCAPE:
			_close_search.call()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_jump.call(event.shift_pressed)
		elif event.keycode == KEY_F and event.is_command_or_control_pressed():
			search_field.select_all()
	)
	search_prev.pressed.connect( func(): _jump.call(true))
	search_next.pressed.connect( func(): _jump.call(false))
	search_close.pressed.connect( func(): _close_search.call())

	text_edit.gui_input.connect( func(event: InputEvent) -> void :
		if not (event is InputEventKey and event.pressed and not event.echo\
		and event.is_command_or_control_pressed()):
			return
		if event.keycode == KEY_F:
			_open_search.call()
		elif event.keycode == KEY_S:
			do_write.call()
	)


	var vbox: = VBoxContainer.new()
	vbox.anchor_bottom = 1.0
	vbox.anchor_right = 1.0
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10
	for child in [text_edit, search_bar, status_bar, save_bar]:
		vbox.add_child(child)

	popup.add_child(vbox)
	plugin.get_editor_interface().get_base_control().add_child(popup)
	popup.popup_centered_ratio(0.5)

	var file: = FileAccess.open(gpm.PACKAGE_FILE, FileAccess.READ)
	if file == null:
		_log("无法打开 %s" % gpm.PACKAGE_FILE)
		return
	text_edit.text = file.get_as_text()


func _save_edit_package(node: Node, status_bar: Label, text_edit: TextEdit) -> void :
	var report: = func(msg: String) -> void :
		status_bar.text = msg
		_log(msg)

	var json: = JSON.new()
	if json.parse(text_edit.text) != OK:
		report.call("第 %d 行语法错误：%s" % [json.get_error_line(), json.get_error_message()])
		return

	if not json.data is Dictionary:
		report.call("%s 的根节点必须是一个 JSON 对象" % gpm.PACKAGE_FILE)
		return

	if not json.data.get(gpm.PackageKeys.PACKAGES, null) is Dictionary:
		report.call("缺少或无效的 '%s' 字段" % gpm.PackageKeys.PACKAGES)
		return

	if not _ensure_config_dir():
		return

	var file: = FileAccess.open(gpm.PACKAGE_FILE, FileAccess.WRITE)
	if file == null:
		_log("无法打开 %s 进行写入（FileAccess 错误码 %d）" % [gpm.PACKAGE_FILE, FileAccess.get_open_error()])
		return

	file.store_string(text_edit.text)
	file = null
	_log("%s 保存成功，开始更新..." % gpm.PACKAGE_FILE)
	node.queue_free()
	_on_update(false)


func _block_editor() -> void :
	_blocker = Panel.new()
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.modulate = Color(0.0, 0.0, 0.0, 0.0)
	plugin.get_editor_interface().get_base_control().add_child(_blocker)


func _unblock_editor() -> void :
	if is_instance_valid(_blocker):
		_blocker.queue_free()
	_blocker = null


func _on_update(force: bool) -> void :
	if _is_updating:
		return
	_is_updating = true
	_block_editor()
	var res = await gpm.update(force)
	_unblock_editor()
	_is_updating = false
	if res.is_err():
		_log(res.unwrap_err().to_string())
	_refresh_package_list()
	if not _current_detail_pkg.is_empty() and is_visible_in_tree():
		var new_version: = _get_installed_version(_current_detail_pkg)
		if new_version.is_empty():
			_detail_content.hide()
			_detail_placeholder.show()
			_current_detail_pkg = ""
		else:
			_show_detail(_current_detail_pkg, new_version)


func _on_message_logged(text: String) -> void :
	_log(text)


func _on_operation_started(operation: String, num_packages: int) -> void :
	_log("正在执行 %s，共 %d 个包" % [operation, num_packages])


func _on_operation_checkpoint_reached(package_name: String) -> void :
	_log("正在处理 %s" % package_name)


func _on_update_finished() -> void :
	plugin.get_editor_interface().get_resource_filesystem().scan()
	_log("完成")


func _on_delete_requested(pkg_name: String) -> void :
	var dialog: = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除 %s 吗？\n此操作将移除 manifest 记录并删除 addons 目录下的对应文件夹。" % pkg_name
	dialog.confirmed.connect( func():
		dialog.queue_free()
		var res: = gpm.read_config(gpm.PACKAGE_FILE)
		var manifest: Dictionary = res.unwrap() if res.is_ok() else {}
		var packages: Dictionary = manifest.get(gpm.PackageKeys.PACKAGES, {})
		if not packages.has(pkg_name):
			_log("manifest 中未找到包 %s" % pkg_name)
			return
		packages.erase(pkg_name)
		var file: = FileAccess.open(gpm.PACKAGE_FILE, FileAccess.WRITE)
		if file == null:
			_log("无法写入 %s" % gpm.PACKAGE_FILE)
			return
		file.store_string(JSON.stringify(manifest, "\t"))
		file = null
		_log("已从 manifest 移除 %s，开始删除..." % pkg_name)
		_detail_content.hide()
		_detail_placeholder.show()
		_on_update(false)
	)
	dialog.canceled.connect(dialog.queue_free)
	plugin.get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()


func _on_install_requested(pkg_name: String, version: String) -> void :
	var res: = gpm.read_config(gpm.PACKAGE_FILE)
	var manifest: Dictionary = res.unwrap() if res.is_ok() else {}
	if not manifest.has(gpm.PackageKeys.PACKAGES):
		manifest[gpm.PackageKeys.PACKAGES] = {}
	manifest[gpm.PackageKeys.PACKAGES][pkg_name] = version
	var file: = FileAccess.open(gpm.PACKAGE_FILE, FileAccess.WRITE)
	if file == null:
		_log("无法写入 %s" % gpm.PACKAGE_FILE)
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file = null
	_log("已将 %s 切换为版本 %s，开始安装..." % [pkg_name, version])
	await _on_update(false)


func _log(text: String) -> void :
	print("[GPM] ", text)
