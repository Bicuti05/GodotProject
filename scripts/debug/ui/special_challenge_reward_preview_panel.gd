extends CanvasLayer


const COIN_SCENE: PackedScene = preload("res://assets/spine/effect_coin_clover/effect_coin_clover.tscn")

const REWARD_PRESETS: Array[Dictionary] = [
	{"rope": 1}, 
	{"undo": 2, "hint": 1}, 
	{"coins": 300, "undo": 1, "hint": 1}, 
]

var _opened: bool = false
var _paused_before: bool = false
var _count: int = 3
var _showing_collection: bool = false
var _counts: Dictionary = {"coins": 1000, "undo": 0, "hint": 0, "rope": 0}
var _props: Dictionary = {}
var _coin_punch: Tween = null
var _coin_icon_scale: Vector2 = Vector2.ONE
@onready var _view: SpecialChallengeRewardDialog = $Root / Reward
@onready var _card: PanelContainer = $Root / Card
@onready var _status: Label = $Root / Card / Body / Status
@onready var _choices: HBoxContainer = $Root / Card / Body / Actions / Choices
@onready var _coin_hud: Control = $Root / PreviewHud / CoinHud
@onready var _coin_icon: TextureRect = $Root / PreviewHud / CoinHud / CoinIcon
@onready var _coin_label: Label = $Root / PreviewHud / CoinHud / CoinLabel
@onready var _collect_button: Button = $Root / Card / Body / Collection / Claim
@onready var _double_button: Button = $Root / Card / Body / Collection / Double

func _ready() -> void :
	layer = SceneManager.Layer.DEBUG + 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_layout)
	for index: int in _choices.get_child_count():
		(_choices.get_child(index) as Button).pressed.connect(_select_count.bind(index + 1))
	var types: Dictionary = {"undo": PropBtn.PropType.UNDO, "hint": PropBtn.PropType.HINT, "rope": PropBtn.PropType.ROPE}
	for kind: String in types:
		var button: PropBtn = $Root / PreviewHud.get_node(kind)
		button.configure(types[kind])
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		_props[kind] = button
	refresh_economy_ui()
	hide()

func open(count: int = 3) -> void :
	if not _opened:
		_paused_before = get_tree().paused
	_opened = true
	get_tree().paused = true
	show()
	_layout()
	_select_count(count)

func _layout() -> void :
	var viewport: Vector2 = UiMetrics.viewport_size()
	var width: float = minf(viewport.x - 48.0, 1000.0)
	_card.custom_minimum_size.x = width
	_card.reset_size()
	_card.position = Vector2(UiMetrics.center_left(width), 
		UiMetrics.safe_insets().x + 250.0 if _showing_collection\
		else viewport.y - UiMetrics.safe_insets().y - _card.size.y - 24.0)
	_layout_preview_hud()

func _layout_preview_hud() -> void :
	var viewport: Vector2 = UiMetrics.viewport_size()
	_coin_hud.position = Vector2(viewport.x - 318.0, UiMetrics.safe_insets().x + 38.0)
	var index: int = 0
	for kind: String in _props:
		var button: PropBtn = _props[kind]
		button.global_position = Vector2(UiMetrics.center_left(708.0) + float(index) * 252.0, 
			viewport.y - UiMetrics.safe_insets().y - 260.0)
		index += 1
	var page: Node = SceneManager.get_page("game")
	if is_instance_valid(page) and page.is_visible_in_tree() and page.has_method("get_special_reward_hud_controls"):
		var hud: Dictionary = page.get_special_reward_hud_controls()
		var coins: Control = hud.coins
		_coin_hud.size = coins.size
		_copy_control_transform(_coin_hud, coins)
		for child_name: String in ["Pill", "CoinLabel", "CoinIcon"]:
			var original: Control = coins.get_node(child_name)
			var copy: Control = _coin_hud.get_node(child_name)
			copy.size = original.size
			copy.position = original.position
			copy.pivot_offset = original.pivot_offset
			copy.scale = original.scale
		for original: Control in hud.props:
			if original is PropBtn and _props.has((original as PropBtn).get_prop_id()):
				var copy: PropBtn = _props[(original as PropBtn).get_prop_id()]
				copy.size = original.size
				_copy_control_transform(copy, original)
	_coin_icon_scale = _coin_icon.scale

func _copy_control_transform(copy: Control, original: Control) -> void :
	var parent: CanvasItem = copy.get_parent() as CanvasItem
	var local: Transform2D = parent.get_global_transform().affine_inverse() * original.get_global_transform()
	copy.pivot_offset = original.pivot_offset
	copy.rotation = local.get_rotation()
	copy.scale = local.get_scale()
	copy.position = local.origin - copy.pivot_offset + local.basis_xform(copy.pivot_offset)

func _process(_delta: float) -> void :
	var ready_to_collect: bool = _opened and _view.can_collect_visual_preview()
	_collect_button.disabled = not ready_to_collect
	_double_button.disabled = not ready_to_collect

func _select_count(count: int) -> void :
	_clear_coin_punch()
	_showing_collection = false
	_counts = {"coins": 1000, "undo": 0, "hint": 0, "rope": 0}
	_count = clampi(count, 1, REWARD_PRESETS.size())
	for index: int in _choices.get_child_count():
		(_choices.get_child(index) as Button).set_pressed_no_signal(index + 1 == _count)
	_status.text = "预览 %d 项奖励 · 不发奖、不播放广告、不写存档" % _count
	_view.play_visual_preview(REWARD_PRESETS[_count - 1], self)
	refresh_economy_ui()
	_layout()

func _on_preview_claim() -> void :
	_collect(1)

func _on_preview_double() -> void :
	_collect(2)

func _collect(multiplier: int) -> void :
	if not _view.can_collect_visual_preview():
		return
	var before: Dictionary = _counts.duplicate(true)
	for kind: String in REWARD_PRESETS[_count - 1]:
		_counts[kind] = int(_counts.get(kind, 0)) + int(REWARD_PRESETS[_count - 1][kind]) * multiplier
	_showing_collection = true
	_status.text = "模拟领取×%d · 金币和道具只进入预览栏位" % multiplier
	_layout()
	await _view.play_visual_preview_collection(before, multiplier)

func get_special_reward_hud_controls() -> Dictionary:
	var props: Array[Control] = []
	for button: PropBtn in _props.values():
		props.append(button)
	return {"coins": _coin_hud, "props": props}

func get_special_reward_target(kind: String) -> Vector2:
	if kind == "coins":
		return _coin_icon.get_global_rect().get_center()
	return (_props[kind] as PropBtn).get_reward_collect_global_rect().get_center()

func refresh_economy_ui() -> void :
	_coin_label.text = str(_counts.coins)
	for kind: String in _props:
		(_props[kind] as PropBtn).set_reward_count_display(int(_counts[kind]))

func append_special_challenge_coin_reward(tween: Tween, start: Vector2, before: int, after: int, 
		parent: Node, sprites: Array[SpineSprite], trails: Array[CPUParticles2D]) -> void :
	_coin_label.text = str(before)
	var count: int = clampi((after - before) / JuiceGamePage.COIN_PER_TARGET, 1, JuiceGamePage.WIN_COIN_FLY_COUNT)
	var last_delay: float = float(count - 1) * JuiceGamePage.WIN_COIN_FLY_STAGGER
	var min_duration: float = JuiceGamePage.WIN_COIN_POP_DUR + JuiceGamePage.WIN_COIN_FLY_DUR * (1.0 - JuiceGamePage.WIN_COIN_FLY_SPEED_RAND)
	var max_duration: float = JuiceGamePage.WIN_COIN_POP_DUR + JuiceGamePage.WIN_COIN_FLY_DUR * (1.0 + JuiceGamePage.WIN_COIN_FLY_SPEED_RAND)
	for index: int in count:
		_append_preview_coin(tween, start, index, count, parent, sprites, trails)
	tween.tween_method(_display_coins, float(before), float(after), 
		maxf(JuiceGamePage.WIN_COIN_FLY_STAGGER, last_delay + max_duration - min_duration))\
		.set_delay(min_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tail: float = JuiceGamePage.WIN_COIN_TRAIL_LIFETIME * (1.0 + JuiceGamePage.WIN_COIN_TRAIL_LIFETIME_RANDOMNESS)
	tween.tween_interval(last_delay + max_duration + maxf(JuiceGamePage.WIN_COIN_PUNCH_DUR, tail))

func _append_preview_coin(tween: Tween, start: Vector2, index: int, count: int, 
		parent: Node, sprites: Array[SpineSprite], trails: Array[CPUParticles2D]) -> void :
	var coin: SpineSprite = COIN_SCENE.instantiate() as SpineSprite
	var base_scale: float = JuiceGamePage.WIN_COIN_FLY_SIZE / JuiceGamePage.WIN_COIN_BBOX_W
	coin.scale = Vector2.ONE * base_scale
	coin.z_index = 80
	parent.add_child(coin)
	coin.global_position = start
	sprites.append(coin)
	var trail: CPUParticles2D = JuiceGamePage.create_win_coin_trail()
	parent.add_child(trail)
	trail.global_position = start
	trails.append(trail)
	var track: SpineTrackEntry = coin.get_animation_state().set_animation(JuiceGamePage.WIN_COIN_ANIM, true, 0)
	track.set_track_time(randf() * JuiceGamePage.WIN_COIN_ANIM_DUR * JuiceGamePage.WIN_COIN_SPIN_DESYNC_RATIO)
	var delay: float = float(index) * JuiceGamePage.WIN_COIN_FLY_STAGGER
	var settled: Vector2 = start + Vector2.from_angle(randf() * TAU)\
	* randf_range(JuiceGamePage.WIN_COIN_POP_DIST_MIN, JuiceGamePage.WIN_COIN_POP_DIST_MAX)
	tween.tween_method(_coin_pop.bind(coin, start, settled), 0.0, 1.0, JuiceGamePage.WIN_COIN_POP_DUR)\
	.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target: Vector2 = get_special_reward_target("coins")
	var control: Vector2 = (settled + target) * 0.5 + Vector2((float(index) - float(count - 1) * 0.5) * 25.0, 
		JuiceGamePage.WIN_COIN_ARC_HEIGHT * randf_range(1.0 - JuiceGamePage.WIN_COIN_ARC_RAND, 1.0 + JuiceGamePage.WIN_COIN_ARC_RAND))
	var duration: float = JuiceGamePage.WIN_COIN_FLY_DUR\
	* randf_range(1.0 - JuiceGamePage.WIN_COIN_FLY_SPEED_RAND, 1.0 + JuiceGamePage.WIN_COIN_FLY_SPEED_RAND)
	tween.tween_callback(_start_coin_trail.bind(trail)).set_delay(delay + JuiceGamePage.WIN_COIN_POP_DUR)
	tween.tween_method(_coin_flight.bind(coin, trail, settled, control, target, base_scale), 0.0, 1.0, duration)\
	.set_delay(delay + JuiceGamePage.WIN_COIN_POP_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_coin_arrived.bind(coin, trail)).set_delay(delay + JuiceGamePage.WIN_COIN_POP_DUR + duration)

func _coin_pop(amount: float, coin: SpineSprite, start: Vector2, settled: Vector2) -> void :
	if is_instance_valid(coin):
		coin.global_position = start.lerp(settled, 1.0 - pow(1.0 - amount, 3.0))

func _start_coin_trail(trail: CPUParticles2D) -> void :
	if is_instance_valid(trail):
		trail.emitting = true

func _coin_flight(amount: float, coin: SpineSprite, trail: CPUParticles2D, start: Vector2, 
		control: Vector2, target: Vector2, base_scale: float) -> void :
	if not is_instance_valid(coin):
		return
	coin.global_position = start.lerp(control, amount).lerp(control.lerp(target, amount), amount)
	coin.scale = Vector2.ONE * base_scale * lerpf(1.25, 0.85, amount)
	if is_instance_valid(trail):
		trail.global_position = coin.global_position

func _coin_arrived(coin: SpineSprite, trail: CPUParticles2D) -> void :
	if is_instance_valid(coin):
		coin.hide()
		coin.set_time_scale(0.0)
	if is_instance_valid(trail):
		trail.emitting = false
	AudioManager.play_sfx(&"coin_fly")
	_clear_coin_punch()
	_coin_icon.scale = _coin_icon_scale * JuiceGamePage.WIN_COIN_PUNCH_SCALE
	_coin_punch = create_tween()
	_coin_punch.tween_property(_coin_icon, "scale", _coin_icon_scale, JuiceGamePage.WIN_COIN_PUNCH_DUR)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _display_coins(value: float) -> void :
	_coin_label.text = str(roundi(value))

func _clear_coin_punch() -> void :
	if _coin_punch != null and _coin_punch.is_valid():
		_coin_punch.kill()
	_coin_punch = null
	if is_instance_valid(_coin_icon):
		_coin_icon.scale = _coin_icon_scale

func _replay() -> void :
	if _opened:
		_select_count(_count)

func close() -> void :
	_clear_coin_punch()
	_view.stop_visual_preview()
	_restore_pause()
	hide()
	queue_free()

func _restore_pause() -> void :
	if _opened:
		get_tree().paused = _paused_before
	_opened = false

func _exit_tree() -> void :
	_clear_coin_punch()
	_restore_pause()

func _unhandled_input(event: InputEvent) -> void :
	if _opened and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _opened:
		close()
