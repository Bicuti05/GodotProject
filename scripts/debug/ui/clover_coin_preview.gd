extends CanvasLayer


const OLD: PackedScene = preload("res://assets/spine/effect_coin/effect_coin.tscn")
const NEW: PackedScene = preload("res://assets/spine/effect_coin_clover/effect_coin_clover.tscn")
var _coins: Array[SpineSprite] = []
var _flights: Array[SpineSprite] = []
var _flight_tween: Tween
var _slow: bool = false
var _stepping: bool = false
var _frame_index: int = 0
var _frame_label: Label
var _paused_before: bool = false
var _opened: bool = false
var _axis_guides: Array[ColorRect] = []
var _root: Control

func _ready() -> void :
	layer = 210
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade: = ColorRect.new()
	shade.color = Color(0.025, 0.07, 0.12, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var bar: = HBoxContainer.new()
	bar.position = Vector2(24, 90)
	_root.add_child(bar)
	for spec: Array in [["正常/慢放", _toggle_slow], ["中心线", _toggle_axis], ["暂停/播放", _toggle_play], ["下一帧", _step_frame], ["飞币演示", _fly], ["关闭", close]]:
		var button: = Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(150, 80)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(spec[1])
		bar.add_child(button)
	_frame_label = Label.new()
	_frame_label.text = "12帧自转 · 下一帧可逐帧核对"
	_frame_label.add_theme_font_size_override("font_size", 28)
	_frame_label.position = Vector2(24, 190)
	_root.add_child(_frame_label)
	for i: int in 2:
		var label: = Label.new()
		label.text = "旧版皇冠" if i == 0 else "新版四叶草"
		label.add_theme_font_size_override("font_size", 38)
		label.position = Vector2(90 + i * 500, 310)
		_root.add_child(label)
		var coin: SpineSprite = (OLD if i == 0 else NEW).instantiate()
		_root.add_child(coin)
		_coins.append(coin)
		coin.get_animation_state().set_animation("animation", true, 0)
	for i: int in 2:
		for vertical: bool in [true, false]:
			var guide: = ColorRect.new()
			guide.color = Color(0.3, 0.95, 1.0, 0.7)
			guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
			guide.size = Vector2(2, 400) if vertical else Vector2(400, 2)
			guide.hide()
			_root.add_child(guide)
			_axis_guides.append(guide)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void :
	var size: Vector2 = UiMetrics.viewport_size()
	for i: int in _coins.size():
		_coins[i].position = Vector2(size.x * (0.27 if i == 0 else 0.73), size.y * 0.36)
		_coins[i].scale = Vector2.ONE * minf(size.x * 0.3, 330.0) / 597.1333

	for i: int in _axis_guides.size():
		var coin: SpineSprite = _coins[i / 2]
		_axis_guides[i].position = coin.position - _axis_guides[i].size * 0.5

func _toggle_axis() -> void :
	for guide: ColorRect in _axis_guides:
		guide.visible = not guide.visible

func open() -> void :
	if not _opened:
		_paused_before = get_tree().paused
		_opened = true
	get_tree().paused = true
	show()

func _toggle_slow() -> void :
	_slow = not _slow
	for coin: SpineSprite in _coins + _flights:
		coin.get_animation_state().set_time_scale(0.0 if _stepping else (0.25 if _slow else 1.0))
	if is_instance_valid(_flight_tween):
		_flight_tween.set_speed_scale(0.25 if _slow else 1.0)

func _current_frame() -> int:
	var time: float = _coins[0].get_animation_state().get_current(0).get_track_time()
	return clampi(int(fposmod(time, 0.3667) * 30.0), 0, 11)

func _toggle_play() -> void :
	if not _stepping:
		_frame_index = _current_frame()
	_stepping = not _stepping
	_frame_label.text = "已暂停 · 下一帧逐帧核对" if _stepping else "12帧自转 · 下一帧可逐帧核对"
	for coin: SpineSprite in _coins:
		coin.get_animation_state().set_time_scale(0.0 if _stepping else (0.25 if _slow else 1.0))

func _step_frame() -> void :
	_clear_flights()
	if not _stepping:
		_frame_index = _current_frame()
	_stepping = true
	_frame_index = (_frame_index + 1) % 12
	_frame_label.text = "当前帧：%02d / 11 · 中心线可开关" % _frame_index
	for coin: SpineSprite in _coins:
		var state: SpineAnimationState = coin.get_animation_state()
		state.set_time_scale(0.0)
		state.get_current(0).set_track_time(float(_frame_index) / 30.0 + 0.001)
		state.apply(coin.get_skeleton())
		coin.get_skeleton().update_world_transform(SpineConstant.Physics_Update)

func _clear_flights() -> void :
	if is_instance_valid(_flight_tween):
		_flight_tween.kill()
	for coin: SpineSprite in _flights:
		if is_instance_valid(coin):
			coin.queue_free()
	_flights.clear()

func _fly() -> void :
	_clear_flights()
	var size: Vector2 = UiMetrics.viewport_size()
	_flight_tween = create_tween().set_parallel(true)
	_flight_tween.set_speed_scale(0.25 if _slow else 1.0)
	for i: int in 8:
		var coin: SpineSprite = NEW.instantiate()
		_root.add_child(coin)
		coin.scale = Vector2.ONE * 70.4 / 597.1333
		var start: = Vector2(size.x * 0.4 + (i % 4) * 65, size.y * 0.72 + (i / 4) * 55)
		var end: = Vector2(size.x - 140, 240)
		coin.position = start
		_flights.append(coin)
		var state: SpineAnimationState = coin.get_animation_state()
		state.set_animation("animation", true, 0)
		state.update(float(i) * 0.04)
		state.set_time_scale(0.25 if _slow else 1.0)
		_flight_tween.tween_method(_flight_position.bind(coin, start, end), 0.0, 1.0, 1.1).set_delay(i * 0.09)
		_flight_tween.tween_property(coin, "modulate:a", 0.0, 0.12).set_delay(i * 0.09 + 1.05)

func _flight_position(t: float, coin: SpineSprite, start: Vector2, end: Vector2) -> void :
	var control: = Vector2(start.x - 180, end.y + 220)
	coin.position = (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * control + t * t * end

func close() -> void :
	_clear_flights()
	if _opened:
		get_tree().paused = _paused_before
		_opened = false
	queue_free()
