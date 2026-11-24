class_name CheatPanel
extends Control

@onready var _tab_container: TabContainer = $PanelContainer / Margin / VBox / TabContainer
@onready var _cmd_input: LineEdit = $PanelContainer / Margin / VBox / InputRow / CmdInput
@onready var _run_btn: Button = $PanelContainer / Margin / VBox / InputRow / RunBtn
@onready var _close_btn: Button = $PanelContainer / Margin / VBox / TitleRow / CloseBtn
@onready var _version_label: Label = $PanelContainer / Margin / VBox / VersionMargin / VersionLabel
@onready var _input_row: Control = $PanelContainer / Margin / VBox / InputRow
@onready var _desc_bar: PanelContainer = $DescBar
@onready var _desc_label: Label = $DescBar / Margin / DescLabel


const DEFAULT_CATEGORY: String = "其他"

const MAX_BTN_SIDE_PAD: float = 60.0

const SECTION_TITLE_FONT_SIZE: int = 44
const SECTION_TITLE_COLOR: Color = Color(1.0, 0.85, 0.4)

const DESC_BAR_GAP: float = 16.0

const SEARCH_PLACEHOLDER: String = "搜索名称 / 命令 / 版本…"


var _category_tabs: Array[Control] = []

func _ready() -> void :
	visible = false
	_run_btn.pressed.connect(_on_run_pressed)
	_close_btn.pressed.connect(hide)
	_version_label.text = _build_version_text()

	_tab_container.tab_clicked.connect(_on_tab_clicked)

	_tab_container.tab_changed.connect( func(_idx: int) -> void : _hide_desc())


func _build_version_text() -> String:
	var version_name: String = ProjectSettings.get_setting("application/config/version", "") as String
	var version_code: int = int(ProjectSettings.get_setting("application/config/version_code", 0))
	if version_code > 0:
		return "for v%s(%d)" % [version_name, version_code]
	return "for v%s" % version_name



func open_panel() -> void :
	_hide_desc()
	_refresh_commands()
	if _tab_container.get_tab_count() > 0:
		_tab_container.current_tab = 0
	visible = true

func close_panel() -> void :
	visible = false

func toggle() -> void :
	if visible:
		close_panel()
	else:
		open_panel()



func _refresh_commands() -> void :

	for tab in _category_tabs:
		_tab_container.remove_child(tab)
		tab.queue_free()
	_category_tabs.clear()


	var ordered_cats: Array[String] = []
	var grouped: Dictionary = {}
	for cmd in CheatBus.get_commands():
		var cat: String = cmd.category if cmd.category != "" else DEFAULT_CATEGORY
		if not grouped.has(cat):
			grouped[cat] = []
			ordered_cats.append(cat)
		(grouped[cat] as Array).append(cmd)



	var max_btn_width: float = maxf(get_viewport_rect().size.x - MAX_BTN_SIDE_PAD, 1.0)
	for cat in ordered_cats:
		var cmds: Array = grouped[cat]

		var sectioned: bool = cmds.any( func(c: CheatCommand) -> bool: return c.section != "")
		var groups: Array[Dictionary] = []
		var content: = _create_category_tab(cat, sectioned, groups)


		var section_order: Array[String] = []
		var by_section: Dictionary = {}
		for cmd: CheatCommand in cmds:
			if not by_section.has(cmd.section):
				by_section[cmd.section] = []
				section_order.append(cmd.section)
			(by_section[cmd.section] as Array).append(cmd)

		for section in section_order:
			var group: = _create_section_group(content, section, not groups.is_empty())
			groups.append(group)
			for cmd: CheatCommand in by_section[section]:
				var btn: = _build_command_button(cmd)
				(group["flow"] as HFlowContainer).add_child(btn)
				(group["buttons"] as Array).append(btn)

				var natural_w: float = btn.get_minimum_size().x
				if natural_w > max_btn_width:
					btn.clip_text = true
					btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
					btn.custom_minimum_size = Vector2(max_btn_width, 100)
				else:
					btn.custom_minimum_size = Vector2(natural_w + 30, 100)



func _create_category_tab(category: String, searchable: bool, groups: Array[Dictionary]) -> VBoxContainer:
	var tab: = Control.new()
	tab.name = category

	var column: = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 16)
	tab.add_child(column)

	if searchable:
		var search: = LineEdit.new()
		search.placeholder_text = SEARCH_PLACEHOLDER
		search.clear_button_enabled = true
		search.custom_minimum_size = Vector2(0, 100)
		search.add_theme_font_size_override("font_size", 48)
		search.text_changed.connect( func(text: String) -> void : _apply_filter(groups, text))
		column.add_child(search)

		column.add_child(HSeparator.new())

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	_tab_container.add_child(tab)
	_category_tabs.append(tab)
	return content



func _create_section_group(content: VBoxContainer, section: String, with_separator: bool) -> Dictionary:
	var root: = VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	content.add_child(root)

	var sep: HSeparator = null
	if with_separator:
		sep = HSeparator.new()
		root.add_child(sep)

	if section != "":
		var title: = Label.new()
		title.text = "【%s】" % section
		title.add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)
		title.add_theme_color_override("font_color", SECTION_TITLE_COLOR)
		root.add_child(title)

	var flow: = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 16)
	root.add_child(flow)

	var buttons: Array[Button] = []
	return {"root": root, "sep": sep, "flow": flow, "buttons": buttons}



func _apply_filter(groups: Array[Dictionary], keyword: String) -> void :
	var kw: String = keyword.strip_edges().to_lower()
	var seen_visible: bool = false
	for group: Dictionary in groups:
		var visible_count: int = 0
		for btn: Button in group["buttons"]:
			var hit: bool = kw.is_empty()\
			or btn.text.to_lower().contains(kw)\
			or String(btn.get_meta("cheat_name", "")).to_lower().contains(kw)\
			or String(btn.get_meta("cheat_version", "")).to_lower().contains(kw)
			btn.visible = hit
			if hit:
				visible_count += 1
		(group["root"] as Control).visible = visible_count > 0
		if group["sep"] != null:
			(group["sep"] as Control).visible = seen_visible
		if visible_count > 0:
			seen_visible = true


func _build_command_button(cmd: CheatCommand) -> Button:
	var btn: = Button.new()

	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.text = cmd.label if cmd.label != "" else cmd.name
	btn.custom_minimum_size = Vector2(0, 100)
	btn.add_theme_font_size_override("font_size", 48)

	btn.set_meta("cheat_name", cmd.name)
	btn.set_meta("cheat_version", cmd.version)

	var captured_cmd: CheatCommand = cmd
	btn.pressed.connect( func() -> void :
		var raw: String = captured_cmd.name
		var args: String = _resolve_default_args(captured_cmd)
		if args != "":
			raw += " " + args
		_cmd_input.text = raw
		_show_desc(captured_cmd)
	)
	return btn



func _resolve_default_args(cmd: CheatCommand) -> String:
	if cmd.default_args_provider.is_valid():
		return str(cmd.default_args_provider.call())
	return cmd.default_args


func _show_desc(cmd: CheatCommand) -> void :
	if cmd.desc == "":
		_hide_desc()
		return
	_desc_label.text = cmd.desc
	_desc_bar.visible = true

	_desc_bar.size = Vector2(_input_row.size.x, 0.0)
	_desc_bar.position.x = _input_row.global_position.x - global_position.x

	await get_tree().process_frame
	_place_desc_bar()


func _place_desc_bar() -> void :
	if not _desc_bar.visible:
		return
	_desc_bar.size.y = 0.0
	var input_top: float = _input_row.global_position.y - global_position.y
	_desc_bar.position.y = input_top - DESC_BAR_GAP - _desc_bar.size.y

func _hide_desc() -> void :
	_desc_bar.visible = false









func _on_tab_clicked(tab_index: int) -> void :
	var tab: Node = _tab_container.get_tab_control(tab_index)
	if tab == null:
		return
	var only: CheatCommand = _sole_command_of(String(tab.name))
	if only == null:
		return
	var raw: String = only.name
	var args: String = _resolve_default_args(only)
	if args != "":
		raw += " " + args
	CheatBus.issue(raw)
	close_panel()




func _sole_command_of(category: String) -> CheatCommand:
	var found: CheatCommand = null
	for cmd: CheatCommand in CheatBus.get_commands():
		var cat: String = cmd.category if cmd.category != "" else DEFAULT_CATEGORY
		if cat != category:
			continue
		if found != null:
			return null
		found = cmd
	return found




func _on_run_pressed() -> void :
	var raw: = _cmd_input.text.strip_edges()
	if raw.is_empty():
		return
	CheatBus.issue(raw)
	close_panel()
