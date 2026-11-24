class_name BonusMotionPreview
extends CanvasLayer


const BANNER: PackedScene = preload("res://scripts/main/pages/game/bonus_level_banner.tscn")
const FILL: PackedScene = preload("res://scripts/main/pages/game/bonus_pig_fill.tscn")
const HUD: PackedScene = preload("res://scripts/main/pages/game/bonus_pig_hud.tscn")
const SMASH: PackedScene = preload("res://scripts/main/pages/game/bonus_pig_smash.tscn")
const COIN: PackedScene = preload("res://scripts/main/pages/game/bonus_spine_coin.tscn")
const COIN_HUD: Texture2D = preload("res://assets/sprites/game_coin_icon.png")
@export var font: Font
@onready var _root: Control = $Root
var _banner: BonusLevelBanner
var _fill: BonusPigFill
var _hud: BonusPigHud
var _smash: BonusPigSmash
var _label: Label
var _balance: Label
var _status: Label
var _toolbar: VBoxContainer
var _stage_choice: OptionButton
var _speed_choice: OptionButton
var _loop: CheckButton
var _coin_icon: TextureRect
var _coins: Array[BonusSpineCoin] = []
var _borrowed_board: JuiceBoardView = null
var _coin_trails: Array[CPUParticles2D] = []
var _flight_specs: Array[Dictionary] = []
var _burst_center: Vector2
var _anchors: Dictionary = {}
var _anchor_page: Node = null
var _coin_tween: Tween
var _generation: int = 0
var _active: bool = false
var _running: bool = false
var _was_paused: bool = false
var _speed: float = 1.0
var _base_balance: int = 0
var _reward_started: bool = false
var _align_x: SpinBox
var _align_y: SpinBox
var _hammer_size: SpinBox
var completed_runs: int = 0
var stages_seen: Array[String] = []

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = SceneManager.Layer.DEBUG + 2
	_banner = BANNER.instantiate() as BonusLevelBanner
	_fill = FILL.instantiate() as BonusPigFill
	_hud = HUD.instantiate() as BonusPigHud
	_smash = SMASH.instantiate() as BonusPigSmash
	_label = _make_label("Bonus Level", 42)
	_balance = _make_label("", 38)
	_coin_icon = _make_coin(COIN_HUD)
	_root.add_child(_label)
	_root.add_child(_balance)
	_root.add_child(_coin_icon)
	_label.hide()
	_balance.hide()
	_coin_icon.hide()
	for node: Control in [_fill, _hud, _smash, _banner]:
		_root.add_child(node)
		_ignore_input(node)
	_smash.smashed.connect(_on_smashed)
	for i: int in range(8):
		var coin: BonusSpineCoin = COIN.instantiate() as BonusSpineCoin
		coin.z_index = 6
		coin.hide()
		_root.add_child(coin)
		_coins.append(coin)
		var trail: CPUParticles2D = JuiceGamePage.create_win_coin_trail()
		trail.z_index = 5
		_root.add_child(trail)
		_coin_trails.append(trail)
	_build_toolbar()
	get_viewport().size_changed.connect(_on_resize)
	hide()
	set_process(false)

func _make_label(text: String, font_size: int) -> Label:
	var label: = Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_coin(texture: Texture2D) -> TextureRect:
	var coin: = TextureRect.new()
	coin.texture = texture
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return coin

func _ignore_input(node: Node) -> void :
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_ignore_input(child)

func _build_toolbar() -> void :
	_toolbar = VBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 14)
	_root.add_child(_toolbar)
	_status = _make_label("纯动效预览 · 不发金币／不改存档", 28)
	_toolbar.add_child(_status)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_toolbar.add_child(row)
	_stage_choice = OptionButton.new()
	for text: String in ["完整流程", "开局横幅", "金币入罐", "金猪飞入顶栏", "飞出砸猪＋金币"]:
		_stage_choice.add_item(text)
	row.add_child(_stage_choice)
	_speed_choice = OptionButton.new()
	for text: String in ["0.5× 慢放", "1× 正常", "2× 快放"]:
		_speed_choice.add_item(text)
	_speed_choice.select(1)
	_speed_choice.item_selected.connect(_on_speed_selected)
	row.add_child(_speed_choice)
	_loop = CheckButton.new()
	_loop.text = "循环"
	row.add_child(_loop)
	var buttons: = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	_toolbar.add_child(buttons)
	_add_button(buttons, "播放／重播", _play_selected)
	_add_button(buttons, "停止", stop)
	_add_button(buttons, "关闭预览", close)
	var alignment: = HBoxContainer.new()
	alignment.add_theme_constant_override("separation", 10)
	_toolbar.add_child(alignment)
	_align_x = _add_alignment_value(alignment, "命中X", -160.0, 160.0, 0.0, 1.0)
	_align_y = _add_alignment_value(alignment, "命中Y", -160.0, 160.0, 0.0, 1.0)
	_hammer_size = _add_alignment_value(alignment, "锤子尺寸", 0.35, 1.3, BonusPigSmash.DEFAULT_HAMMER_SCALE, 0.01)
	_add_button(alignment, "复位", _reset_alignment)
	_align_x.value_changed.connect(_update_alignment)
	_align_y.value_changed.connect(_update_alignment)
	_hammer_size.value_changed.connect(_update_alignment)
	_apply_ui_font(_toolbar)

func _add_alignment_value(parent: Control, text: String, low: float, high: float, value: float, step: float) -> SpinBox:
	parent.add_child(_make_label(text, 26))
	var input: = SpinBox.new()
	input.min_value = low
	input.max_value = high
	input.step = step
	input.value = value
	input.custom_minimum_size.x = 135.0
	parent.add_child(input)
	return input

func _update_alignment(_value: float = 0.0) -> void :
	_smash.hit_offset = Vector2(_align_x.value / BonusPigSmash.BIG_PIG_SIZE, 
		_align_y.value / BonusPigSmash.BIG_PIG_SIZE)
	_smash.hammer_scale = _hammer_size.value

func _reset_alignment() -> void :
	_align_x.value = 0.0
	_align_y.value = 0.0
	_hammer_size.value = BonusPigSmash.DEFAULT_HAMMER_SCALE
	_update_alignment()

func _apply_ui_font(node: Node) -> void :
	if node is Control:
		(node as Control).add_theme_font_override("font", font)
		(node as Control).add_theme_font_size_override("font_size", 28)
	for child: Node in node.get_children():
		_apply_ui_font(child)

func _add_button(parent: Control, text: String, action: Callable) -> void :
	var button: = Button.new()
	button.text = text
	button.custom_minimum_size.y = 64.0
	button.pressed.connect(action)
	parent.add_child(button)

func open(auto_play: bool = true, test_anchors: Dictionary = {}) -> void :
	if _active:
		stop()
	var anchors: Dictionary = test_anchors
	if anchors.is_empty():
		_anchor_page = SceneManager.get_page("game")
		if is_instance_valid(_anchor_page) and _anchor_page.has_method("get_bonus_motion_preview_anchors"):
			anchors = _anchor_page.get_bonus_motion_preview_anchors()
	if anchors.is_empty():
		SceneManager.show_toast("请进入游戏，等盘面入场和收盆结束后再预览 Bonus")
		return
	_anchors = anchors.duplicate(true)
	if _active:
		stop()
	else:
		_was_paused = get_tree().paused
		_base_balance = UserState.get_coins()
		_active = true
		get_tree().paused = true
	show()
	set_process(true)
	_layout()
	_reset_visuals()
	if auto_play:
		_play_selected()

func close() -> void :
	if not _active:
		return
	stop()
	_active = false
	hide()
	set_process(false)
	get_tree().paused = _was_paused

func _exit_tree() -> void :
	if is_instance_valid(_borrowed_board):
		_borrowed_board.end_bonus_collection_preview()
	if _active:
		get_tree().paused = _was_paused

func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready():
			close()

func _unhandled_key_input(event: InputEvent) -> void :
	if _active and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_resize() -> void :
	if _active:
		stop()
		if is_instance_valid(_anchor_page):
			var fresh: Dictionary = _anchor_page.get_bonus_motion_preview_anchors()
			if fresh.is_empty():
				close()
				return
			_anchors = fresh
		_layout()

func _layout() -> void :
	var viewport: Vector2 = UiMetrics.viewport_size()
	var inset: float = minf(48.0, viewport.x * 0.05)
	var safe: Vector2 = UiMetrics.safe_insets()
	_toolbar.position = Vector2(inset, viewport.y - safe.y - 360.0)
	_toolbar.size = Vector2(viewport.x - inset * 2.0, 320.0)
	_hud.place_left_of_label(_anchors["level_rect"], float(_anchors["level_text_width"]))

func _reset_visuals() -> void :
	if is_instance_valid(_borrowed_board):
		_borrowed_board.end_bonus_collection_preview()
	_borrowed_board = null
	_banner.cancel()
	_fill.cancel()
	_hud.hide_now()
	_smash.hide_now()
	if _coin_tween != null and _coin_tween.is_valid():
		_coin_tween.kill()
	_coin_tween = null
	for coin: BonusSpineCoin in _coins:
		coin.reset()
	for trail: CPUParticles2D in _coin_trails:
		trail.emitting = false
		trail.amount = trail.amount
	_balance.text = str(_base_balance)
	_reward_started = false

func stop() -> void :
	_generation += 1
	_running = false
	_reset_visuals()
	_status.text = "已停止 · 纯动效预览，不发金币／不改存档"

func is_running() -> bool:
	return _running

func _on_speed_selected(index: int) -> void :
	_speed = [0.5, 1.0, 2.0][index]

func _process(_delta: float) -> void :
	if is_instance_valid(_borrowed_board) and _borrowed_board.get("_bonus_preview_state").is_empty():
		close()
		return
	if is_instance_valid(_anchor_page) and not (_anchor_page as Control).is_visible_in_tree():
		close()
		return
	for trail: CPUParticles2D in _coin_trails:
		trail.speed_scale = _speed
	_banner.set_playback_speed(_speed)
	_fill.set_coin_playback_speed(_speed)
	for coin: BonusSpineCoin in _coins:
		coin.playback_speed = _speed
	for pair: Array in [[_banner, "_tween"], [_fill, "_tween"], [_hud, "_fly_tween"], 
			[_hud, "_punch_tween"], [_smash, "_tween"]]:
		var tw: Tween = pair[0].get(pair[1]) as Tween
		if tw != null and tw.is_valid():
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.set_speed_scale(_speed)
	if _coin_tween != null and _coin_tween.is_valid():
		_coin_tween.set_speed_scale(_speed)

func _play_selected() -> void :
	play_stage(_stage_choice.selected)

func play_stage(stage: int = 0) -> void :
	if not _active or stage < 0 or stage > 4:
		return
	stop()
	var generation: int = _generation
	_running = true
	stages_seen.clear()
	while _active and generation == _generation:
		_layout()
		_reset_visuals()
		if stage == 0 or stage == 1:
			_set_stage("横幅")
			_banner.play()
			await _wait_node(_banner, generation)
		if generation != _generation:
			return
		var viewport: Vector2 = UiMetrics.viewport_size()
		var rect: Rect2 = _anchors["pot_rect"]
		if stage == 0 or stage == 2:
			_set_stage("金币入罐")
			if is_instance_valid(_anchor_page):
				_borrowed_board = _anchor_page.get("_board") as JuiceBoardView
				if not _borrowed_board.begin_bonus_collection_preview(_fill._pig, int(_anchors["preview_col"])):
					stop()
					return
			var sources: Array[Vector2] = []
			for point: Vector2 in _anchors["coin_origins"]:
				sources.append(point)
			_fill.play(rect, sources, float(_anchors["coin_diameter"]), _speed)
			await _wait_node(_fill, generation)
		if generation != _generation:
			return
		if stage == 0 or stage == 3:
			_set_stage("金猪飞入顶栏")
			_fill.cancel()
			_hud.fly_in_from(rect)
			await _wait_node(_hud, generation)
		if generation != _generation:
			return
		if stage == 0 or stage == 4:
			_set_stage("飞出砸猪＋金币")

			if not _hud.is_docked():
				_hud.dock_instantly()
			var from_rect: Rect2 = _hud.dock_global_rect()
			_hud.hide_now()
			_smash.play(from_rect, viewport * Vector2(0.5, 0.5))
			await _wait_node(_smash, generation)
			while generation == _generation and _coin_tween != null and _coin_tween.is_valid() and _coin_tween.is_running():
				await get_tree().process_frame
		if generation != _generation:
			return
		completed_runs += 1
		_status.text = "播放完成 · 演示奖励＋100，不写真实余额"
		if not _loop.button_pressed:
			break
		var gap: float = 0.0
		while generation == _generation and gap < 0.8:
			await get_tree().process_frame
			gap += get_process_delta_time() * _speed
	if generation == _generation:
		_running = false

func _set_stage(text: String) -> void :
	stages_seen.append(text)
	_status.text = text + " · 纯动效预览"

func _wait_node(node: Node, generation: int) -> void :
	while generation == _generation:
		var busy: bool = false
		if node == _banner:
			busy = _banner.visible
		elif node == _hud:
			var punch: Tween = _hud.get("_punch_tween") as Tween
			busy = _hud.is_flying() or (punch != null and punch.is_valid() and punch.is_running())
		else:
			busy = bool(node.call("is_running"))
		if not busy:
			return
		await get_tree().process_frame

func _on_smashed(center: Vector2) -> void :
	if not _running or _reward_started:
		return
	_reward_started = true
	var generation: int = _generation
	_coin_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_coin_tween.set_speed_scale(_speed)
	_coin_tween.set_parallel(true)
	var dst: Vector2 = (_anchors["coin_rect"] as Rect2).get_center()
	_burst_center = center
	_flight_specs.clear()

	var delays: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.55, 0.65, 0.75, 0.85]
	for i: int in range(_coins.size()):
		var coin: BonusSpineCoin = _coins[i]
		var width: float = 135.0 + float(i % 3) * 15.0
		coin.size = Vector2.ONE * width
		coin.pivot_offset = coin.size * 0.5
		coin.scale = Vector2.ONE
		coin.modulate.a = 1.0
		coin.global_position = center - coin.size * 0.5

		var angle: float = float(i) * TAU / float(_coins.size()) + randf_range(-0.18, 0.18)
		var radius: float = randf_range(JuiceGamePage.WIN_COIN_POP_DIST_MIN, JuiceGamePage.WIN_COIN_POP_DIST_MAX)
		var start: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		var arc: float = JuiceGamePage.WIN_COIN_ARC_HEIGHT * randf_range(1.0 - JuiceGamePage.WIN_COIN_ARC_RAND, 1.0 + JuiceGamePage.WIN_COIN_ARC_RAND)
		var bend: Vector2 = Vector2((float(i) - 3.5) * 25.0, arc)
		var duration: float = JuiceGamePage.WIN_COIN_FLY_DUR * randf_range(1.0 - JuiceGamePage.WIN_COIN_FLY_SPEED_RAND, 1.0 + JuiceGamePage.WIN_COIN_FLY_SPEED_RAND)
		var flight_delay: float = delays[i] + JuiceGamePage.WIN_COIN_POP_DUR
		_flight_specs.append({"delay": delays[i], "start": start, "bend": bend, "duration": duration})
		_coin_tween.tween_callback(coin.start_rotation.bind(float(i) * 0.137, _speed)).set_delay(delays[i])
		_coin_tween.tween_method(_pop_coin.bind(coin, center, start, generation), 0.0, 1.0, JuiceGamePage.WIN_COIN_POP_DUR).set_delay(delays[i]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var trail: CPUParticles2D = _coin_trails[i]
		trail.global_position = center
		trail.speed_scale = _speed
		_coin_tween.tween_callback(_begin_coin_trail.bind(trail, coin)).set_delay(flight_delay)
		_coin_tween.tween_method(_fly_coin.bind(coin, start, dst, generation, bend), 0.0, 1.0, duration).set_delay(flight_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		_coin_tween.tween_callback(coin.reset).set_delay(flight_delay + duration)
		_coin_tween.tween_callback(trail.set_emitting.bind(false)).set_delay(flight_delay + duration)

	_coin_tween.tween_interval(delays[-1] + JuiceGamePage.WIN_COIN_POP_DUR + JuiceGamePage.WIN_COIN_FLY_DUR * 1.3 + JuiceGamePage.WIN_COIN_TRAIL_LIFETIME * 1.2)
	_coin_tween.tween_method(_roll_balance.bind(generation), float(_base_balance), float(_base_balance + 100), 1.2).set_delay(0.65)

func _begin_coin_trail(trail: CPUParticles2D, coin: BonusSpineCoin) -> void :
	trail.global_position = coin.visual_global_rect().get_center()
	trail.emitting = true

func _pop_coin(t: float, coin: BonusSpineCoin, center: Vector2, settle: Vector2, generation: int) -> void :
	if generation == _generation:
		coin.place_visual_center(center.lerp(settle, 1.0 - pow(1.0 - t, 3.0)))

func _fly_coin(t: float, coin: BonusSpineCoin, start: Vector2, dst: Vector2, generation: int, 
		bend: Vector2 = Vector2(100.0, 180.0)) -> void :
	if generation != _generation:
		return
	var ctrl: Vector2 = (start + dst) * 0.5 + bend
	var center: Vector2 = start.lerp(ctrl, t).lerp(ctrl.lerp(dst, t), t)
	var settle: float = clampf((t - 0.65) / 0.35, 0.0, 1.0)
	if t >= 0.65:
		coin.settle_rotation(settle)
	coin.fit_destination(_anchors["coin_rect"], settle)
	coin.place_visual_center(center)
	var index: int = _coins.find(coin)
	if index >= 0:
		_coin_trails[index].global_position = center

func _roll_balance(value: float, generation: int) -> void :
	if generation == _generation:
		_balance.text = str(roundi(value))
