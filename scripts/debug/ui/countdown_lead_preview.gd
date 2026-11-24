extends CanvasLayer

const BAR: PackedScene = preload("res://scripts/main/pages/game/iq_progress_bar.tscn")
const SETTINGS = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_settings.gd")

const FROM_FRACTION: float = 0.12
const TO_FRACTION: float = FROM_FRACTION + float(SETTINGS.CUP_TIME_MS) / float(SETTINGS.INITIAL_TIME_MS)

var _bar: IqProgressBar
var _opened: bool = false
var _paused_before: bool = false


func _ready() -> void :
	layer = 210
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root: = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade: = ColorRect.new()
	shade.color = Color(0.04, 0.05, 0.08, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var buttons: = HBoxContainer.new()
	buttons.position = Vector2(24, 80)
	buttons.add_theme_constant_override("separation", 16)
	root.add_child(buttons)
	for spec: Array in [["再播一次", _play], ["关闭", close]]:
		var button: = Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(180, 70)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(spec[1])
		buttons.add_child(button)
	var label: = Label.new()
	label.position = Vector2(24, 170)
	label.text = "红条停住，只在尽头多长出一小段白色，白色消失后红条变长"
	label.add_theme_font_size_override("font_size", 28)
	root.add_child(label)
	_bar = BAR.instantiate()
	root.add_child(_bar)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void :
	var view: Vector2 = UiMetrics.viewport_size()
	_bar.position = Vector2((view.x - IqProgressBar.DESIGN_WIDTH) * 0.5, view.y * 0.42)
	_bar.size = Vector2(IqProgressBar.DESIGN_WIDTH, IqProgressBar.DESIGN_HEIGHT)


func open() -> void :
	if not _opened:
		_paused_before = get_tree().paused
		_opened = true
	get_tree().paused = true
	_bar.show()
	_play()


func _play() -> void :
	_bar.set_iq(40.0, false)
	_bar.set_countdown_progress(FROM_FRACTION)
	_bar.begin_countdown_lead()
	_bar.set_countdown_progress(TO_FRACTION)


func _unhandled_key_input(event: InputEvent) -> void :
	if _opened and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _opened:
		close()


func close() -> void :
	_opened = false
	if is_instance_valid(_bar):
		_bar.hide()
	get_tree().paused = _paused_before
	queue_free()
