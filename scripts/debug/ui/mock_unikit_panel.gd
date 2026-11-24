class_name MockUnikitPanel
extends CanvasLayer








































const _FONT_SIZE: int = 36

const _ROW_TITLE_FONT_SIZE: int = 44


const _STATE_BTN_MIN_WIDTH: float = 200.0
const _RESET_BTN_MIN_WIDTH: float = 140.0

const _BTN_HEIGHT: float = 84.0
const _COLOR_SELECTED: Color = Color(0.45, 1.0, 0.5)
const _COLOR_UNSELECTED: Color = Color(0.75, 0.75, 0.75)

const _SECTION_TITLE_FONT_SIZE: int = 52
const _SECTION_TITLE_COLOR: Color = Color(1.0, 0.85, 0.4)

@onready var _rows_vbox: VBoxContainer = $Bg / CenterPanel / Margin / VBox / Scroll / RowsVBox
@onready var _enable_label: Label = $Bg / CenterPanel / Margin / VBox / EnableRow / EnableLabel
@onready var _enable_off_btn: Button = $Bg / CenterPanel / Margin / VBox / EnableRow / OffBtn
@onready var _enable_on_btn: Button = $Bg / CenterPanel / Margin / VBox / EnableRow / OnBtn

var _row_inter_ad_ready: Dictionary
var _row_reward_ad_ready: Dictionary
var _row_banner_ad_ready: Dictionary
var _row_reward_ad_result: Dictionary
var _row_privacy_required: Dictionary
var _row_cmp_required: Dictionary
var _row_att_status: Dictionary
var _row_push_state: Dictionary



var _rows_built: bool = false


func _ready() -> void :
	layer = SceneManager.Layer.DEBUG + 1
	hide()





func open() -> void :
	if not _rows_built:
		_build_rows()
		_rows_built = true
	show()
	_refresh_enable_highlight()




	_set_actual(_row_inter_ad_ready, _bool_label(
		await UniKit.ad_module.is_interstitial_valid(AdManager.AD_PLACEMENT_ID_INTERSTITIAL, ""), "未就绪", "已就绪"))
	_set_actual(_row_reward_ad_ready, _bool_label(
		await UniKit.ad_module.is_reward_valid(AdManager.AD_PLACEMENT_ID_REWARD, ""), "未就绪", "已就绪"))
	_set_actual(_row_banner_ad_ready, _bool_label(
		await UniKit.ad_module.is_banner_valid(AdManager.AD_PLACEMENT_ID_BANNER, ""), "未就绪", "已就绪"))


	_set_actual(_row_reward_ad_result, _bool_label(AdManager.peek_last_reward_result(), "否", "是"))
	_set_actual(_row_privacy_required, _bool_label( await AuthManager.peek_privacy_required(), "不需要", "需要"))
	_set_actual(_row_cmp_required, _bool_label( await AuthManager.peek_cmp_required(), "不需要", "需要"))
	_set_actual(_row_att_status, _att_label( await AuthManager.peek_att_status()))
	for row: Dictionary in [_row_inter_ad_ready, _row_reward_ad_ready, _row_banner_ad_ready, 
			_row_reward_ad_result, _row_privacy_required, _row_cmp_required, _row_att_status, _row_push_state]:
		_refresh_row_highlight(row)



static func _set_actual(row: Dictionary, actual: String) -> void :
	(row["title"] as Label).text = "%s（实际：%s）" % [row["dim_label"], actual]


static func _bool_label(v: bool, false_label: String, true_label: String) -> String:
	return true_label if v else false_label







static func _ad_mock_default() -> int:
	return EditorAds.AD_MOCK_DEFAULT if OS.has_feature("editor") else MockUnikitConfig.MockState.RESET


static func _att_label(v: int) -> String:
	match v:
		UniKit.ATT_STATUS_NOT_DETERMINED:
			return "未决定"
		UniKit.ATT_STATUS_AUTHORIZED:
			return "已授权"
		UniKit.ATT_STATUS_SYSTEM_DENIED:
			return "系统关闭"
		UniKit.ATT_STATUS_APP_DENIED:
			return "已拒绝"
		_:
			return "未知(%d)" % v



func _on_close_pressed() -> void :
	hide()



func _on_enable_off_pressed() -> void :
	MockUnikitConfig.set_mock_enabled(false)
	_refresh_enable_highlight()



func _on_enable_on_pressed() -> void :
	MockUnikitConfig.set_mock_enabled(true)
	_refresh_enable_highlight()







func _on_ad_debug_pressed() -> void :
	AdManager.open_ad_debug_view()


func _refresh_enable_highlight() -> void :
	var enabled: bool = MockUnikitConfig.is_mock_enabled(OS.has_feature("editor"))

	_enable_label.text = "启动Mock（%s）" % ("已启用" if enabled else "未启用")
	_enable_off_btn.modulate = _COLOR_UNSELECTED if enabled else _COLOR_SELECTED
	_enable_on_btn.modulate = _COLOR_SELECTED if enabled else _COLOR_UNSELECTED


func _build_rows() -> void :
	_add_section_title("广告", false)




	_row_inter_ad_ready = _build_row("插屏广告状态", 
		[{"value": MockUnikitConfig.MockState.FALSE, "label": "未就绪"}, {"value": MockUnikitConfig.MockState.TRUE, "label": "已就绪"}], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_inter_ad_ready(_ad_mock_default()), 
		func(v: int) -> void : MockUnikitConfig.set_mock_inter_ad_ready(v))
	_row_reward_ad_ready = _build_row("激励广告状态", 
		[{"value": MockUnikitConfig.MockState.FALSE, "label": "未就绪"}, {"value": MockUnikitConfig.MockState.TRUE, "label": "已就绪"}], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_reward_ad_ready(_ad_mock_default()), 
		func(v: int) -> void : _set_reward_ad_ready(v))

	_row_banner_ad_ready = _build_row("Banner广告状态", 
		[{"value": MockUnikitConfig.MockState.FALSE, "label": "未就绪"}, {"value": MockUnikitConfig.MockState.TRUE, "label": "已就绪"}], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_banner_ad_ready(_ad_mock_default()), 
		func(v: int) -> void : MockUnikitConfig.set_mock_banner_ad_ready(v))
	_row_reward_ad_result = _build_row("激励广告奖励已获得", 
		[{"value": MockUnikitConfig.MockState.FALSE, "label": "否"}, {"value": MockUnikitConfig.MockState.TRUE, "label": "是"}], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_reward_ad_result(_ad_mock_default()), 
		func(v: int) -> void : MockUnikitConfig.set_mock_reward_ad_result(v))

	_add_section_title("授权", true)
	_row_privacy_required = _build_row("隐私协议需展示", 
		[{"value": MockUnikitConfig.MockState.FALSE, "label": "不需要"}, {"value": MockUnikitConfig.MockState.TRUE, "label": "需要"}], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_privacy_required(), 
		func(v: int) -> void : MockUnikitConfig.set_mock_privacy_required(v))
	_row_cmp_required = _build_row("CMP需展示", 
		[{"value": MockUnikitConfig.MockState.FALSE, "label": "不需要"}, {"value": MockUnikitConfig.MockState.TRUE, "label": "需要"}], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_cmp_required(), 
		func(v: int) -> void : MockUnikitConfig.set_mock_cmp_required(v))
	_row_att_status = _build_row("ATT授权状态", 
		[
			{"value": UniKit.ATT_STATUS_NOT_DETERMINED, "label": "未决定"}, 
			{"value": UniKit.ATT_STATUS_AUTHORIZED, "label": "已授权"}, 
			{"value": UniKit.ATT_STATUS_SYSTEM_DENIED, "label": "系统关闭"}, 
			{"value": UniKit.ATT_STATUS_APP_DENIED, "label": "已拒绝"}, 
		], 
		-1, 
		func() -> int: return MockUnikitConfig.get_mock_att_status(), 
		func(v: int) -> void : MockUnikitConfig.set_mock_att_status(v))


	_row_push_state = _build_row("推送授权状态", 
		[
			{"value": MockUnikitConfig.PushState.UNDETERMINED, "label": "未决定"}, 
			{"value": MockUnikitConfig.PushState.AUTHORIZED, "label": "已授权"}, 
			{"value": MockUnikitConfig.PushState.DENIED, "label": "已拒绝"}, 
		], 
		MockUnikitConfig.MockState.RESET, 
		func() -> int: return MockUnikitConfig.get_mock_push_state(), 
		func(v: int) -> void : MockUnikitConfig.set_mock_push_state(v))



func _add_section_title(section: String, with_separator: bool) -> void :
	if with_separator:
		_rows_vbox.add_child(HSeparator.new())
	var title: Label = Label.new()
	title.text = "【%s】" % section
	title.add_theme_font_size_override("font_size", _SECTION_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", _SECTION_TITLE_COLOR)
	_rows_vbox.add_child(title)




func _build_row(dim_label: String, states: Array[Dictionary], reset_value: int, 
		getter: Callable, setter: Callable) -> Dictionary:
	var row_box: VBoxContainer = VBoxContainer.new()
	row_box.add_theme_constant_override("separation", 6)
	var title: Label = Label.new()
	title.text = dim_label
	title.add_theme_font_size_override("font_size", _ROW_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	row_box.add_child(title)

	var btn_row: HFlowContainer = HFlowContainer.new()
	btn_row.add_theme_constant_override("h_separation", 12)
	btn_row.add_theme_constant_override("v_separation", 12)
	row_box.add_child(btn_row)

	var row: Dictionary = {"getter": getter, "buttons": [] as Array, "title": title, "dim_label": dim_label}

	var reset_btn: Button = Button.new()
	reset_btn.text = "重置"
	reset_btn.custom_minimum_size = Vector2(_RESET_BTN_MIN_WIDTH, _BTN_HEIGHT)
	reset_btn.add_theme_font_size_override("font_size", _FONT_SIZE)
	reset_btn.pressed.connect( func() -> void : _on_state_pressed(row, setter, reset_value))
	btn_row.add_child(reset_btn)
	(row["buttons"] as Array).append({"btn": reset_btn, "value": reset_value})

	for s: Dictionary in states:
		var btn: Button = Button.new()
		btn.text = String(s["label"])
		btn.custom_minimum_size = Vector2(_STATE_BTN_MIN_WIDTH, _BTN_HEIGHT)
		btn.add_theme_font_size_override("font_size", _FONT_SIZE)
		var v: int = int(s["value"])
		btn.pressed.connect( func() -> void : _on_state_pressed(row, setter, v))
		btn_row.add_child(btn)
		(row["buttons"] as Array).append({"btn": btn, "value": v})

	_rows_vbox.add_child(row_box)
	return row











func _set_reward_ad_ready(v: int) -> void :
	MockUnikitConfig.set_mock_reward_ad_ready(v)
	if v == MockUnikitConfig.MockState.FALSE:
		return
	AdManager.reward_ad_loaded.emit()


func _on_state_pressed(row: Dictionary, setter: Callable, value: int) -> void :
	setter.call(value)
	_refresh_row_highlight(row)


func _refresh_row_highlight(row: Dictionary) -> void :
	var cur: int = (row["getter"] as Callable).call()
	for entry: Dictionary in (row["buttons"] as Array):
		(entry["btn"] as Button).modulate = _COLOR_SELECTED if int(entry["value"]) == cur else _COLOR_UNSELECTED
