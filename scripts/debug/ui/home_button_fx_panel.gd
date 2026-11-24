class_name HomeButtonFxPanel
extends CanvasLayer

@export var font: Font
@export var bonus_icon: Texture2D
@export var special_icon: Texture2D
@export var fire_white: Texture2D
@export var fire_yellow: Texture2D

@onready var _panel: PanelContainer = $Root / Panel
@onready var _body: VBoxContainer = $Root / Panel / Margin / VBox / Body
@onready var _collapse: Button = $Root / Panel / Margin / VBox / Header / Collapse
@onready var _preview_stage: Control = $Root / Panel / Margin / VBox / Body / PreviewStage
@onready var _preview_button: CommonBtn = $Root / Panel / Margin / VBox / Body / PreviewStage / PlayButton
@onready var _effect: HomeButtonFx = $Root / Panel / Margin / VBox / Body / PreviewStage / PlayButton / HomeButtonFx
@onready var _status: Label = $Root / Panel / Margin / VBox / Body / Status
@onready var _parameters: VBoxContainer = $Root / Panel / Margin / VBox / Body / Scroll / Parameters
@onready var _variant: OptionButton = $Root / Panel / Margin / VBox / Body / Options / Variant
@onready var _sweep_toggle: CheckButton = $Root / Panel / Margin / VBox / Body / Toggles / Sweep
@onready var _stars_toggle: CheckButton = $Root / Panel / Margin / VBox / Body / Toggles / Stars
@onready var _live_toggle: CheckButton = $Root / Panel / Margin / VBox / Body / Live

var _settings: Dictionary = HomeButtonFx.DEFAULT_SETTINGS.duplicate()
var _mode: int = 1
var _inputs: Dictionary = {}
var _syncing: bool = false
var _previous_paused: bool = false
var _owns_pause: bool = false
var _home_preview_active: bool = false


func _ready() -> void :
	layer = SceneManager.Layer.DEBUG + 1
	_variant.add_item("普通关 · 蓝色")
	_variant.add_item("困难关 · 红色")
	_variant.add_item("超级困难 · 紫色")
	_variant.add_item("Bonus · 橙色")
	_variant.add_item("特殊挑战 · 橙色")
	_build_parameters()
	_apply_fonts($Root)
	get_viewport().size_changed.connect(_layout)
	hide()


func open() -> void :
	if not visible:
		_previous_paused = get_tree().paused
		_owns_pause = true
		get_tree().paused = true
	_body.show()
	_collapse.text = "收起"
	show()
	_sync_inputs()
	_apply()
	_layout()


func close() -> void :
	_effect.set_effect_enabled(false)
	_restore_home_preview()
	hide()
	_restore_pause()


func _exit_tree() -> void :
	_restore_home_preview()
	_restore_pause()


func _restore_pause() -> void :
	if _owns_pause:
		_owns_pause = false
		get_tree().paused = _previous_paused


func _apply_fonts(node: Node) -> void :
	if node == _preview_button:
		return
	if node is Control:
		var control: Control = node as Control
		control.add_theme_font_override("font", font)
		if not control.has_theme_font_size_override("font_size"):
			control.add_theme_font_size_override("font_size", 38)
		if control is BaseButton:
			control.custom_minimum_size.y = 64.0
	for child: Node in node.get_children():
		_apply_fonts(child)


func _build_parameters() -> void :
	for definition: Dictionary in HomeButtonFx.PARAMETER_DEFINITIONS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		_parameters.add_child(row)
		var label: Label = Label.new()
		label.text = definition["label"]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var input: SpinBox = SpinBox.new()
		input.min_value = float(definition["min"])
		input.max_value = float(definition["max"])
		input.step = float(definition["step"])
		input.value = float(_settings[definition["key"]])
		input.custom_minimum_size = Vector2(240.0, 64.0)
		row.add_child(input)
		_inputs[definition["key"]] = input
		input.value_changed.connect(_on_value_changed.bind(String(definition["key"])))


func _sync_inputs() -> void :
	_syncing = true
	for key: String in _inputs:
		(_inputs[key] as SpinBox).value = float(_settings[key])
	_sweep_toggle.set_pressed_no_signal(bool(_settings["sweep_enabled"]))
	_stars_toggle.set_pressed_no_signal(bool(_settings["stars_enabled"]))
	_syncing = false


func _on_value_changed(value: float, key: String) -> void :
	if _syncing:
		return
	_settings[key] = value
	_apply()


func _apply() -> void :
	_effect.set_settings(_settings)
	_settings = _effect.get_settings()
	var enabled: bool = _mode == 1 if _mode >= 0\
	else ABManager.main_btn.peek_value() == MainBtnConfig.VALUE_NEW_EFFECT
	_effect.set_effect_enabled(enabled and visible)
	_apply_variant(_variant.selected)
	_status.text = "预览：%s%s · 仅模拟，不改 AB／关卡／奖励／存档" % [
		"new 扫光＋星光" if enabled else "old 原版", 
		"（读取当前分组）" if _mode < 0 else "（临时预览）", 
	]
	if _live_toggle.button_pressed:
		var home: HomePage = SceneManager.get_page("home") as HomePage
		if is_instance_valid(home) and home.is_visible_in_tree():
			home.preview_home_button_fx(_mode, _settings)
			_home_preview_active = true
	else:
		_restore_home_preview()


func _restore_home_preview() -> void :
	if not _home_preview_active:
		return
	_home_preview_active = false
	if not is_instance_valid(SceneManager):
		return
	var home: HomePage = SceneManager.get_page("home") as HomePage
	if is_instance_valid(home):
		home.preview_home_button_fx(-1, HomeButtonFx.DEFAULT_SETTINGS, false)


func _apply_variant(index: int) -> void :
	var variants: Array[int] = [
		CommonBtn.Variant.SECONDARY, CommonBtn.Variant.HARD, CommonBtn.Variant.SUPER_HARD, 
		CommonBtn.Variant.TERTIARY, CommonBtn.Variant.TERTIARY, 
	]
	_preview_button.variant = variants[clampi(index, 0, variants.size() - 1)]
	_preview_button.btn_icon = bonus_icon if index == 3 else special_icon if index == 4 else null
	var level_text: String = tr("LEVEL_NUM")
	_preview_button.btn_text = level_text % 20 if "%d" in level_text else "Level 20"
	if index == 3:
		_preview_button.btn_text = "BONUS_LEVEL_TITLE"
	elif index == 4:
		_preview_button.btn_text = "SPECIAL_CHALLENGE_BUTTON"
	_preview_button.base_font_size = 90 if index == 4 else 102
	_preview_button.btn_sub_text = "HOME_HARD_BADGE" if index == 1\
	else "HOME_SUPER_HARD_BADGE" if index == 2 else ""
	_preview_button.btn_sub_icon = fire_white if index == 1 else fire_yellow if index == 2 else null
	_preview_button.sub_font_color = Color("ffe100") if index == 2 else Color.WHITE


func _layout() -> void :
	if not is_node_ready():
		return
	var viewport: Vector2 = UiMetrics.viewport_size()
	var inset: Vector2 = UiMetrics.safe_insets()
	var margin: MarginContainer = $Root / Panel / Margin
	margin.add_theme_constant_override("margin_top", 24 + ceili(inset.x))
	margin.add_theme_constant_override("margin_bottom", 24 + ceili(inset.y))
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(viewport.x, viewport.y * 0.88) if _body.visible\
	else Vector2(viewport.x, 140.0 + inset.x + inset.y)
	var button_size: Vector2 = Vector2(792.0, 216.0)
	var factor: float = minf(1.0, maxf(0.1, (_preview_stage.size.x - 80.0) / button_size.x))
	_preview_button.size = button_size
	_preview_button.scale = Vector2.ONE * factor
	_preview_button.position = (_preview_stage.size - button_size * factor) * 0.5


func _on_old() -> void :
	_mode = 0
	_apply()


func _on_new() -> void :
	_mode = 1
	_apply()


func _on_sdk() -> void :
	_mode = -1
	_apply()


func _on_variant_selected(index: int) -> void :
	_apply_variant(index)
	_effect.replay()


func _on_sweep_toggled(enabled: bool) -> void :
	_settings["sweep_enabled"] = enabled
	_apply()


func _on_stars_toggled(enabled: bool) -> void :
	_settings["stars_enabled"] = enabled
	_apply()


func _on_live_toggled(_enabled: bool) -> void :
	_apply()


func _on_replay() -> void :
	_effect.replay()


func _on_defaults() -> void :
	_settings = HomeButtonFx.DEFAULT_SETTINGS.duplicate()
	_sync_inputs()
	_apply()


func _on_collapse() -> void :
	_body.visible = not _body.visible
	_collapse.text = "收起" if _body.visible else "展开"
	_layout()
	_effect.set_effect_enabled(_body.visible and (_mode == 1 or \
	(_mode < 0 and ABManager.main_btn.peek_value() == MainBtnConfig.VALUE_NEW_EFFECT)))
