class_name AbDebugPage
extends PageScene



















signal closed(group_id_set: bool)


const SKIP_TOKEN: String = "-1"

const NO_EXPERIMENT_TEXT: String = "（无）"

const _RANDOM_COUNTRIES: Array[String] = ["US", "GB", "DE", "FR", "JP", "KR", "BR", "IN", "ID", "RU", "TR", "MX", "CA", "AU", "CN"]
const SELECTED_COLOR: Color = Color(0.45, 1.0, 0.5)
const UNSELECTED_COLOR: Color = Color(0.75, 0.75, 0.75)

const VERSION_TITLE_COLOR: Color = Color(1.0, 0.85, 0.4)


@onready var _margin: MarginContainer = $Panel / Margin
@onready var _experiments_value: Label = $Panel / Margin / VBox / ExperimentsRow / ExperimentsValue
@onready var _experiment_search: LineEdit = $Panel / Margin / VBox / ExperimentSearch
@onready var _group_id_input: LineEdit = $Panel / Margin / VBox / GroupIdRow / GroupIdInput
@onready var _country_input: LineEdit = $Panel / Margin / VBox / CountryRow / CountryInput


@onready var _experiment_section: Array[Control] = [
	$Panel / Margin / VBox / Sep, 
	$Panel / Margin / VBox / ExperimentSectionTitle, 
	$Panel / Margin / VBox / ExperimentSearch, 
	$Panel / Margin / VBox / ExperimentsRow, 
]
@onready var _startup_spacer: Control = $Panel / Margin / VBox / StartupSpacer
@onready var _experiments_area: Control = $Panel / Margin / VBox / ExperimentsArea
@onready var _fixed_experiments: ScrollContainer = $Panel / Margin / VBox / ExperimentsArea / FixedExperiments
@onready var _rows_vbox: VBoxContainer = $Panel / Margin / VBox / ExperimentsArea / FixedExperiments / RowsVBox

@onready var _sticky_version: Label = $Panel / Margin / VBox / ExperimentsArea / StickyVersion


var _startup_mode: bool = false
var _rows: Array[Dictionary] = []
var _rows_built: bool = false

var _version_groups: Array[Dictionary] = []




func _ready() -> void :
	_fixed_experiments.get_v_scroll_bar().value_changed.connect(_on_experiments_scrolled)
	_fixed_experiments.resized.connect(_update_sticky_version)


func _on_show(params: Dictionary) -> void :
	_startup_mode = bool(params.get("startup_mode", false))
	var safe_insets: Vector2 = UiMetrics.safe_insets()
	_margin.add_theme_constant_override("margin_top", 36 + roundi(safe_insets.x))
	_margin.add_theme_constant_override("margin_bottom", 36 + roundi(safe_insets.y))
	_startup_spacer.visible = _startup_mode
	_experiments_area.visible = not _startup_mode
	for c: Control in _experiment_section:
		c.visible = not _startup_mode
	_experiments_value.text = _experiments_text()

	_group_id_input.text = SKIP_TOKEN if _startup_mode else ABManager.get_ab_group_id()
	_country_input.text = "" if _startup_mode else ABManager.get_ab_country()
	if not _startup_mode:
		if not _rows_built:
			_build_rows()
			_rows_built = true
		_experiment_search.text = ""
		_apply_experiment_filter("")
		for row: Dictionary in _rows:
			if row.get("parameter", false):
				(row["input"] as LineEdit).text = String((row["config"] as AbConfigBase).call("get_debug_input_value_str"))
			_refresh_row(row)




func _on_back_request() -> void :
	_on_close_pressed()





func _experiments_text() -> String:

	if not ABManager.is_ab_init_done():
		return NO_EXPERIMENT_TEXT
	var all_keys: Array = ABManager.get_all_ab_experiments().keys()
	var hits: Array[Dictionary] = ContentLevelExperimentResolver.collect_keys(all_keys)
	if hits.is_empty():
		return NO_EXPERIMENT_TEXT
	var items: PackedStringArray = PackedStringArray()
	for h: Dictionary in hits:
		items.append("ch%d_%d = \"%s\"" % [int(h.start), int(h.end), 
			ABManager.get_ab_string(str(h.key), "")])
	return "，".join(items)




func _build_rows() -> void :
	var configs: Array[AbConfigBase] = ABManager.get_all_configs()
	configs.sort_custom( func(a: AbConfigBase, b: AbConfigBase) -> bool:
		if a.version != b.version:
			return a.version.naturalnocasecmp_to(b.version) > 0
		return a.key.nocasecmp_to(b.key) < 0)
	if configs.is_empty():
		var empty_label: = Label.new()
		empty_label.text = "当前没有固定 key AB 实验"
		empty_label.add_theme_font_size_override("font_size", 30)
		_rows_vbox.add_child(empty_label)
		return
	var current_version: String = ""
	var first_version: bool = true
	var cur_group: Dictionary = {}
	for cfg: AbConfigBase in configs:
		if first_version or cfg.version != current_version:
			first_version = false
			current_version = cfg.version
			var version_title: = Label.new()
			version_title.text = "版本 %s" % (current_version if not current_version.is_empty() else "未知")
			version_title.add_theme_font_size_override("font_size", 34)
			version_title.add_theme_color_override("font_color", VERSION_TITLE_COLOR)
			_rows_vbox.add_child(version_title)
			cur_group = {"title": version_title, "rows": [] as Array, "text": version_title.text}
			_version_groups.append(cur_group)

		var row_box: = VBoxContainer.new()
		row_box.add_theme_constant_override("separation", 16)
		_rows_vbox.add_child(row_box)


		var label_parts: Dictionary = _split_cheat_label(cfg.cheat_label())
		var title: = Label.new()
		title.text = "%s · %s" % [cfg.key, label_parts["name"]]
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color(1, 1, 1))
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_box.add_child(title)
		if not String(label_parts["desc"]).is_empty():
			var desc: = Label.new()
			desc.text = label_parts["desc"]
			desc.add_theme_font_size_override("font_size", 34)
			desc.add_theme_color_override("font_color", Color(0.68, 0.7, 0.74))
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row_box.add_child(desc)
		var buttons: = HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 20)
		row_box.add_child(buttons)
		var row: Dictionary = {"config": cfg, "buttons": [] as Array, 
			"box": row_box}

		var reset_button: = Button.new()
		reset_button.text = "SDK"
		row["reset_btn"] = reset_button
		reset_button.custom_minimum_size = Vector2(240, 104)
		reset_button.add_theme_font_size_override("font_size", 36)
		reset_button.pressed.connect( func() -> void : _on_reset_pressed(row))
		buttons.add_child(reset_button)
		(row["buttons"] as Array).append({"button": reset_button, "value": -1})
		if cfg is InterUnlockLevelConfig or cfg is BannerUnlockLevelConfig\
		or cfg is InterCdByDayConfig or cfg is InterProtectByDayConfig:
			row["parameter"] = true
			_build_parameter_controls(row, buttons)
		else:
			for group: int in cfg.group_count:
				var group_button: = Button.new()
				group_button.text = str(group)
				group_button.custom_minimum_size = Vector2(150, 104)
				group_button.add_theme_font_size_override("font_size", 36)
				group_button.pressed.connect( func() -> void : _on_group_pressed(row, group))
				buttons.add_child(group_button)
				(row["buttons"] as Array).append({"button": group_button, "value": group})
		_rows.append(row)
		(cur_group["rows"] as Array).append(row)



func _build_parameter_controls(row: Dictionary, buttons: HBoxContainer) -> void :
	var cfg: AbConfigBase = row["config"] as AbConfigBase
	var input: = LineEdit.new()
	input.text = String(cfg.call("get_debug_input_value_str"))
	input.custom_minimum_size = Vector2(360, 104)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size", 30)
	row["input"] = input
	buttons.add_child(input)
	var apply_button: = Button.new()
	apply_button.text = "应用"
	apply_button.custom_minimum_size = Vector2(160, 104)
	apply_button.add_theme_font_size_override("font_size", 36)
	apply_button.pressed.connect( func() -> void : _on_parameter_apply(row))
	input.text_submitted.connect( func(_text: String) -> void : _on_parameter_apply(row))
	buttons.add_child(apply_button)
	var effective: = Label.new()
	effective.add_theme_font_size_override("font_size", 30)
	effective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row["effective"] = effective
	(row["box"] as VBoxContainer).add_child(effective)


func _on_parameter_apply(row: Dictionary) -> void :
	var cfg: AbConfigBase = row["config"] as AbConfigBase
	if not bool(cfg.call("set_debug_override_str", (row["input"] as LineEdit).text)):
		SceneManager.show_toast("格式无效：解锁填非负整数，分段填 [day1_day2:n]")
		return
	_refresh_row(row)


func _on_group_pressed(row: Dictionary, group: int) -> void :
	(row["config"] as AbConfigBase).set_debug_override(group)
	_refresh_row(row)


func _on_reset_pressed(row: Dictionary) -> void :
	var cfg: AbConfigBase = row["config"] as AbConfigBase
	cfg.clear_debug_override()
	if row.get("parameter", false):
		(row["input"] as LineEdit).text = String(cfg.call("get_debug_input_value_str"))
	_refresh_row(row)




static func _split_cheat_label(label: String) -> Dictionary:
	var idx: int = label.find(" (")
	if idx < 0:
		return {"name": label, "desc": ""}
	var desc: String = label.substr(idx + 2)
	if desc.ends_with(")"):
		desc = desc.substr(0, desc.length() - 1)
	return {"name": label.substr(0, idx), "desc": desc}


func _refresh_row(row: Dictionary) -> void :
	var cfg: AbConfigBase = row["config"] as AbConfigBase
	if row.get("parameter", false):
		(row["reset_btn"] as Button).text = "重置"
		(row["reset_btn"] as Button).modulate = UNSELECTED_COLOR if cfg.is_debug_overridden() else SELECTED_COLOR
		(row["effective"] as Label).text = "当前生效：%s" % cfg.cheat_value_str()
		return
	var override_value: int = cfg.get_debug_override()

	var sdk_text: String = str(cfg.peek_sdk_value()) if cfg.is_sdk_hit() else "未命中"
	(row["reset_btn"] as Button).text = "SDK：%s" % sdk_text


	for entry: Dictionary in row["buttons"] as Array:
		(entry["button"] as Button).modulate = SELECTED_COLOR\
		if int(entry["value"]) == override_value else UNSELECTED_COLOR




func _on_experiments_scrolled(_value: float) -> void :
	_update_sticky_version()





func _update_sticky_version() -> void :
	if _version_groups.is_empty() or not _experiments_area.visible:
		_sticky_version.visible = false
		return
	var area_top: float = _fixed_experiments.global_position.y
	var sticky_h: float = _sticky_version.size.y
	var current: Dictionary = {}
	var next_top: float = INF
	for group: Dictionary in _version_groups:
		var title: Control = group["title"] as Control
		if not title.is_visible_in_tree():
			continue
		var top: float = title.global_position.y - area_top
		if top <= 0.0:
			current = group
		elif next_top == INF:
			next_top = top
	if current.is_empty():
		_sticky_version.visible = false
		return
	_sticky_version.text = String(current["text"])
	_sticky_version.visible = true

	var push: float = minf(next_top - sticky_h, 0.0) if next_top != INF else 0.0
	_sticky_version.position.y = push




func _on_experiment_search_changed(text: String) -> void :
	_apply_experiment_filter(text)




func _apply_experiment_filter(keyword: String) -> void :
	var kw: String = keyword.strip_edges().to_lower()
	for group: Dictionary in _version_groups:
		var visible_count: int = 0
		for row: Dictionary in group["rows"] as Array:
			var cfg: AbConfigBase = row["config"] as AbConfigBase
			var hit: bool = kw.is_empty()\
			or cfg.key.to_lower().contains(kw)\
			or cfg.cheat_label().to_lower().contains(kw)\
			or cfg.version.to_lower().contains(kw)
			(row["box"] as Control).visible = hit
			if hit:
				visible_count += 1
		(group["title"] as Control).visible = visible_count > 0

	_update_sticky_version.call_deferred()





func _on_increment_pressed() -> void :
	var base_str: String = _group_id_input.text.strip_edges()
	var base_int: int = base_str.to_int() if base_str.is_valid_int() else 0
	_group_id_input.text = str(base_int + 1)



func _on_random_pressed() -> void :
	_group_id_input.text = str(randi() % 1000)




func _on_country_random_pressed() -> void :
	_country_input.text = _RANDOM_COUNTRIES[randi() % _RANDOM_COUNTRIES.size()]






func _on_confirm_pressed() -> void :
	var group_id_str: String = _group_id_input.text.strip_edges()
	var country_str: String = _country_input.text.strip_edges().to_upper()

	if _startup_mode and (group_id_str.is_empty() or group_id_str == SKIP_TOKEN
			or not group_id_str.is_valid_int()):
		SortLogger.info("[AbDebugPage] 启动模式跳过(group_id=%s)，继续走正常启动序列" % group_id_str)
		SceneManager.hide_page("ab_debug")
		closed.emit(false)
		return

	var changed_group: bool = false
	if not group_id_str.is_empty() and group_id_str.is_valid_int():
		ABManager.set_ab_group_id(group_id_str)
		changed_group = true

	var changed_country: bool = false
	if country_str.length() == 2:
		ABManager.set_ab_country(country_str)
		changed_country = true

	SortLogger.info("[AbDebugPage] 确认 group_id=%s(changed=%s) country=%s(changed=%s)，即将退出"
		%[group_id_str, changed_group, country_str, changed_country])

	SceneManager.hide_page("ab_debug")
	closed.emit(true)

	await get_tree().create_timer(0.2).timeout
	get_tree().quit()



func _on_close_pressed() -> void :
	SceneManager.hide_page("ab_debug")
	closed.emit(false)
