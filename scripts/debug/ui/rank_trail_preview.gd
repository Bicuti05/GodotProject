extends CanvasLayer


const ITEM: Texture2D = preload("res://assets/sprites/common_rank_collect_item.png")
var _fly: RankCollectFlyLayer
var _root: Control
var _label: Label
var _destination_base_position: Vector2
var _destination_punch: Tween
var _destination: Sprite2D
var _mode: int = 0
var _arrivals: int = 0
var _speed: float = 1.0
var _opened: bool = false
var _paused_before: bool
var _generation: int = 0

func _ready() -> void :
	layer = 210
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade: = ColorRect.new()
	shade.color = Color(0.035, 0.06, 0.1, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var bar: = HBoxContainer.new()
	bar.position = Vector2(20, 80)
	_root.add_child(bar)
	for spec: Array in [["完局收集", _round], ["结算收集", _settlement], ["重播", _replay], ["正常/慢放", _slow], ["关闭", close]]:
		var button: = Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(185, 76)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(spec[1])
		bar.add_child(button)
	_label = Label.new()
	_label.position = Vector2(40, 195)
	_label.add_theme_font_size_override("font_size", 34)
	_root.add_child(_label)
	_destination = Sprite2D.new()
	_destination.texture = ITEM
	_destination.scale = Vector2.ONE * 110.0 / ITEM.get_width()
	_destination.position = _destination_base_position
	_root.add_child(_destination)
	_fly = RankCollectFlyLayer.new()
	_root.add_child(_fly)
	_fly.item_arrived.connect(_arrived)

func open() -> void :
	if not _opened:
		_paused_before = get_tree().paused
		_opened = true
	get_tree().paused = true
	show()
	_replay()

func _round() -> void :
	_mode = 0
	_replay()

func _settlement() -> void :
	_mode = 1
	_replay()

func _slow() -> void :
	_speed = 0.35 if _speed == 1.0 else 1.0
	_replay()

func _replay() -> void :
	_generation += 1
	_fly.cancel_all()
	_reset_punch()
	_arrivals = 0
	_fly.playback_speed = _speed
	var view: Vector2 = UiMetrics.viewport_size()
	_destination.position = Vector2(view.x * (0.78 if _mode == 0 else 0.7), view.y * (0.24 if _mode == 0 else 0.42))
	_destination_base_position = _destination.position
	_refresh_label()
	var generation: int = _generation
	if _mode == 0:
		_fly.play_from_sources(8, ITEM, func(index: int) -> Vector2:
			return Vector2(view.x * 0.2 + float(index % 4) * view.x * 0.18, view.y * 0.72 + (index / 4) * 100), 
			func() -> Vector2: return _root.get_global_transform() * _destination_base_position, 
			func() -> bool: return generation == _generation and _opened)
	else:
		_fly.play(Vector2(view.x * 0.35, view.y * 0.7), 8, ITEM, 
			func() -> Vector2: return _root.get_global_transform() * _destination_base_position, 
			RankCollectFlyLayer.EXPLODE_RADIUS, RankCollectFlyLayer.ExplodeShape.RADIAL)

func _arrived(_index: int) -> void :
	_arrivals += 1
	_destination_punch = RankCollectImpact.play(self, _destination, 
		_destination_base_position, Vector2.ONE * 110.0 / ITEM.get_width(), _destination_punch, _speed)
	_refresh_label()

func _refresh_label() -> void :
	_label.text = "%s · %s · 到达 %d / 8\n仅预览，不修改积分或奖励" % [
		"完局花盆→收集栏" if _mode == 0 else "结算元素→玩家行", "正常" if _speed == 1.0 else "0.35倍慢放", _arrivals]

func _reset_punch() -> void :
	if is_instance_valid(_destination_punch):
		_destination_punch.kill()
	_destination_punch = null
	_destination.scale = Vector2.ONE * 110.0 / ITEM.get_width()
	_destination.position = _destination_base_position

func close() -> void :
	_reset_punch()
	_generation += 1
	_fly.cancel_all()
	if _opened:
		get_tree().paused = _paused_before
		_opened = false
	queue_free()
