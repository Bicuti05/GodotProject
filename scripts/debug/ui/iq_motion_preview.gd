extends CanvasLayer

const BAR: PackedScene = preload("res://scripts/main/pages/game/iq_progress_bar.tscn")
var _genius: Control
var _genius_mode: bool = false
var _root: Control
var _bar: IqProgressBar
var _value: float = 40
var _opened: bool = false
var _paused_before: bool
var _generation: int = 0
var _compare_new: bool = true
var _buttons: HFlowContainer
var _label: Label

func _ready() -> void :
	layer = 210
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root: = Control.new()
	_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade: = ColorRect.new()
	shade.color = Color(0.025, 0.07, 0.12, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var buttons: = HFlowContainer.new()
	_buttons = buttons
	buttons.position = Vector2(20, 90)
	root.add_child(buttons)
	for spec: Array in [["重播", _replay], ["Genius入场", _show_genius], ["小幅+5", _small], ["连续加分", _continuous], ["跨节点", _cross], ["140达标", _threshold], ["到满格", _full], ["原版/新版", _toggle], ["取消重播", _cancel_replay], ["关闭", close]]:
		var button: = Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(180, 70)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(spec[1])
		buttons.add_child(button)
	_label = Label.new()
	_label.position = Vector2(40, 220)
	_label.add_theme_font_size_override("font_size", 32)
	root.add_child(_label)
	_bar = BAR.instantiate()
	root.add_child(_bar)
	_bar.show()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void :
	var view: Vector2 = UiMetrics.viewport_size()
	var width: float = minf(600.0, view.x - 80.0)
	_bar.position = Vector2((view.x - width) * 0.5, view.y * 0.4)
	_bar.size = Vector2(width, IqProgressBar.DESIGN_HEIGHT)
	_buttons.size.x = view.x - 40.0
	_label.position.y = 270.0

func open(genius: bool = false) -> void :
	if not _opened:
		_paused_before = get_tree().paused
		_opened = true
	get_tree().paused = true
	_genius_mode = genius
	_replay()

func _display(value: float, animate: bool = true) -> void :
	_genius_mode = false
	if is_instance_valid(_genius):
		_genius.hide_now()
	_bar.show()
	_value = value
	_bar.set_iq(value, animate)
	_label.text = "%s · IQ %.0f · 仅预览，不改积分或存档\n停止后观察前端呼吸；增长时发射" % ["新版" if _compare_new else "原版", value]

func _replay() -> void :
	if _genius_mode:
		_show_genius()
		return
	_generation += 1
	var generation: int = _generation
	_display(40, false)

	await get_tree().create_timer(0.25).timeout
	for value: float in [90.0, 140.0, 180.0]:
		if generation != _generation or not _opened:
			return
		_display(value)
		await get_tree().create_timer(0.9).timeout

func _threshold() -> void :
	_generation += 1
	_display(125, false)
	_display(145)

func _small() -> void :
	_generation += 1
	if _value >= 180:
		_display(40, false)
	_display(_value + 5)

func _full() -> void :
	_generation += 1
	_display(40, false)
	_display(180)

func _cross() -> void :
	_generation += 1
	_display(85, false)
	_display(145)

func _toggle() -> void :
	_genius_mode = false
	_generation += 1
	_compare_new = not _compare_new
	_bar.set_motion_enabled(_compare_new)
	_replay()

func _cancel_replay() -> void :
	if _genius_mode:
		_show_genius()
		var genius_generation: int = _generation
		await get_tree().create_timer(0.12).timeout
		if genius_generation != _generation or not _opened:
			return
		_genius.hide_now()
		_show_genius()
		return
	_generation += 1
	var generation: int = _generation
	_display(40, false)
	_display(180)
	await get_tree().create_timer(0.12).timeout
	if generation != _generation or not _opened:
		return
	_bar.hide()
	await get_tree().process_frame
	if generation != _generation or not _opened:
		return
	_bar.show()
	_replay()

func _continuous() -> void :
	_generation += 1
	var generation: int = _generation
	_display(40, false)
	for i: int in 10:
		if generation != _generation or not _opened:
			return
		_display(_value + 12)
		await get_tree().create_timer(0.15).timeout

func _show_genius() -> void :
	_generation += 1
	_genius_mode = true
	_bar.hide()
	if not is_instance_valid(_genius):
		var scene: PackedScene = load("res://scripts/main/pages/game/iq_genius_feedback.tscn")
		_genius = scene.instantiate()
		_root.add_child(_genius)

		_root.move_child(_buttons, -1)
		_root.move_child(_label, -1)
	_label.text = "IQ Genius · 原速enter · 2.0秒整体淡出 / 2.2秒结束\n正式多语言标题 · 仅预览，不改IQ、奖励或存档"
	_genius.present()

func _unhandled_key_input(event: InputEvent) -> void :
	if _opened and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _opened:
		close()

func _exit_tree() -> void :
	_generation += 1
	if is_instance_valid(_genius):
		_genius.hide_now()
	if _opened:
		_opened = false
		get_tree().paused = _paused_before

func close() -> void :
	_generation += 1
	_opened = false
	if is_instance_valid(_genius):
		_genius.hide_now()
	_bar.hide()
	get_tree().paused = _paused_before
	queue_free()
