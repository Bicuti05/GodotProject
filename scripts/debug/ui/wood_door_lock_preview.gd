extends CanvasLayer

@export var flower_texture: Texture2D
@export var collection_pot_texture: Texture2D
@export var collection_filled_texture: Texture2D

const COLLECT_START_TIME: float = 0.65

@onready var _root: Control = $Root
@onready var _stage: Control = $Root / Stage
@onready var _flowers: Control = $Root / Stage / Flowers
@onready var _collection: Control = $Root / Stage / Collection
@onready var _collection_flowers: Control = $Root / Stage / Collection / Flowers
@onready var _collection_caption: Label = $Root / Stage / Collection / Caption
@onready var _collection_pot: TextureRect = $Root / Stage / Collection / Pot
@onready var _door_caption: Label = $Root / Stage / DoorCaption
@onready var _overlay: JuiceLockOverlay = $Root / Stage / Overlay
@onready var _effects: WoodDoorLock = $Root / Stage / Effects
@onready var _toolbar: PanelContainer = $Root / Toolbar
@onready var _default_button: Button = $Root / Toolbar / Rows / Buttons / DefaultWood
@onready var _original_button: Button = $Root / Toolbar / Rows / Buttons / Original
@onready var _shatter_button: Button = $Root / Toolbar / Rows / Buttons / Shatter
@onready var _status: Label = $Root / Toolbar / Rows / Status

var _opened: bool = false
var _paused_before: bool = false
var _version: int = 3
var _fruit_d: float = 230.0
var _elapsed: float = 0.0
var _running: bool = false
var _launched: bool = false
var _launch_time: float = 0.0
var _collection_homes: Array[Vector2] = []
var _collection_mouth: Vector2 = Vector2.ZERO
var _collection_pot_bottom: float = 0.0
var _collection_pot_scale: float = 1.0


func _ready() -> void :
	layer = SceneManager.Layer.DEBUG + 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	_effects.stop()
	_effects.finished.connect(_on_effect_finished)
	get_viewport().size_changed.connect(_on_resize)
	_layout()
	hide()
	set_process(false)
	call_deferred("_open_standalone")


func _open_standalone() -> void :
	if get_tree().current_scene == self:
		open()


func open(version: int = -1) -> void :
	if not _opened:
		_paused_before = get_tree().paused
	_opened = true
	get_tree().paused = true
	show()
	if version >= 0:
		_select_version(version)
	else:
		_version = _resolved_preview_version()
		_replay()


func _select_version(version: int) -> void :
	JuiceBoardView.set_lock_visual_version(version)
	_version = _resolved_preview_version()
	_replay()



func _resolved_preview_version() -> int:
	var selected: int = JuiceBoardView.get_lock_visual_version()
	return selected if selected > 0 else 3


func _selection_text() -> String:
	var active: int = JuiceBoardView.get_lock_visual_version()
	var selected_name: String = "破碎木门" if _version == 3 else "原版藤蔓"
	return "默认木门 · 预览：%s" % selected_name if active == 0 else "调试覆盖：%d＝%s · 返回游戏继续本关" % [active, selected_name]


func _layout() -> void :
	var viewport_size: Vector2 = UiMetrics.viewport_size()
	var insets: Vector2 = UiMetrics.safe_insets()
	_root.size = viewport_size
	_toolbar.position = Vector2(24.0, insets.x + 24.0)
	_toolbar.size = Vector2(maxf(220.0, viewport_size.x - 48.0), 224.0)
	_stage.position = Vector2(0.0, insets.x + 272.0)
	_stage.size = Vector2(viewport_size.x, maxf(220.0, viewport_size.y - _stage.position.y - insets.y - 32.0))
	_fruit_d = minf(230.0, minf(_stage.size.x * 0.25, _stage.size.y / 5.6))
	var height: float = _fruit_d * 5.25
	var top: float = (_stage.size.y - height) * 0.5
	var door_x: float = _stage.size.x * (0.72 if _version == 3 else 0.5)
	_overlay.set_geometry(door_x, top, height, _fruit_d)
	_overlay.set_lean(0.0, 0.0)
	var index: int = 0
	for child: Node in _flowers.get_children():
		var flower: TextureRect = child as TextureRect
		flower.position = Vector2(door_x - _fruit_d * 0.5, top + float(index) * height / 5.0)
		flower.size = Vector2.ONE * _fruit_d
		index += 1
	_collection.visible = _version == 3
	_door_caption.visible = _version == 3
	if _version != 3:
		return
	var collection_x: float = _stage.size.x * 0.27
	var pot_size: Vector2 = collection_pot_texture.get_size() * (_fruit_d * 1.15 / collection_pot_texture.get_width())
	_collection_pot_scale = pot_size.x / collection_pot_texture.get_width()
	_collection_pot_bottom = top + pot_size.y
	_collection_mouth = Vector2(collection_x, top + pot_size.y * JuiceBoardView.SLAM_MOUTH_RATIO)
	_place_collection_pot(collection_pot_texture, collection_x)
	_collection_caption.position = Vector2(collection_x - _fruit_d, maxf(0.0, top - 64.0))
	_collection_caption.size = Vector2(_fruit_d * 2.0, 48.0)
	_door_caption.position = Vector2(door_x - _fruit_d, maxf(0.0, top - 64.0))
	_door_caption.size = Vector2(_fruit_d * 2.0, 48.0)
	_collection_homes.clear()
	index = 0
	for child: Node in _collection_flowers.get_children():
		var flower: TextureRect = child as TextureRect
		var diameter: float = _fruit_d * 0.83
		var center: Vector2 = Vector2(collection_x, top + pot_size.y + _fruit_d * (0.64 + float(index) * 0.9))
		flower.texture = flower_texture
		flower.size = Vector2.ONE * diameter
		flower.pivot_offset = flower.size * 0.5
		flower.position = center - flower.size * 0.5
		flower.scale = Vector2.ONE
		flower.show()
		_collection_homes.append(center)
		index += 1


func _place_collection_pot(texture: Texture2D, center_x: float) -> void :
	_collection_pot.texture = texture
	_collection_pot.size = texture.get_size() * _collection_pot_scale
	_collection_pot.position = Vector2(center_x - _collection_pot.size.x * 0.5, _collection_pot_bottom - _collection_pot.size.y)
	_collection_pot.pivot_offset = Vector2(_collection_pot.size.x * 0.5, _collection_pot.size.y)
	_collection_pot.scale = Vector2.ONE


func _replay() -> void :
	_effects.stop()
	_elapsed = 0.0
	_launched = false
	_launch_time = 0.0
	_running = _version == 3
	_layout()
	_overlay.set_lock_visual_version(_version)
	_overlay.show_flower(flower_texture)
	_overlay.show()
	var selection: int = JuiceBoardView.get_lock_visual_version()
	_default_button.button_pressed = selection == 0
	_original_button.button_pressed = selection == 1
	_shatter_button.button_pressed = selection == 3
	_status.text = _selection_text() + ("\n下方为木门效果示意 · 空格重播 · Esc返回游戏"
		if _version == 3 else "\n下方为原版锁面 · 原版解锁动效可返回真实关卡查看")
	set_process(_running)


func _launch() -> void :
	_launched = true
	_launch_time = _elapsed
	var source: WoodDoorLock = _overlay.wood_door_view()
	_effects.configure(source.size, source.condition_texture(), source.remaining_count())
	_effects.position = _overlay.position + source.position
	_effects.play_shatter()
	_overlay.hide()
	_status.text = _selection_text() + "\n示意：对应花色收集完成 → 锁摆动弹开 → 门板轻抖 → 下落途中迸裂"


func _process(delta: float) -> void :
	if not _opened or not _running:
		return
	_elapsed += delta
	if not _launched and _advance_collection():
		_place_collection_pot(collection_filled_texture, _collection_mouth.x)
		_launch()
	if _launched:
		var bounce: float = clampf((_elapsed - _launch_time) / 0.3, 0.0, 1.0)
		_collection_pot.scale = Vector2.ONE * (1.0 + 0.09 * sin(bounce * PI))


func _on_effect_finished() -> void :
	if not _opened or not _launched:
		return
	_running = false
	_status.text = _selection_text() + "\n示意：木门、门框与锁扣全部退场 · 空格重播"
	set_process(false)


func _advance_collection() -> bool:
	var age: float = _elapsed - COLLECT_START_TIME
	if age < 0.0:
		return false
	if age < JuiceBoardView.BURST_DUR:
		var pulse: float = 1.0 + 0.12 * sin(age / JuiceBoardView.BURST_DUR * PI)
		for child: Node in _collection_flowers.get_children():
			(child as TextureRect).scale = Vector2.ONE * pulse
		return false
	var scale_factor: float = _fruit_d / 230.0
	var collected: bool = true
	var index: int = 0
	for child: Node in _collection_flowers.get_children():
		var flower: TextureRect = child as TextureRect
		var motion: Dictionary = JuiceBoardView.sample_collection_motion(_collection_homes[index] / scale_factor, 
			_collection_mouth / scale_factor, index, age - JuiceBoardView.BURST_DUR)
		var center: Vector2 = motion["center"]
		flower.position = center * scale_factor - flower.size * 0.5
		flower.scale = Vector2.ONE * float(motion["scale"])
		flower.visible = not bool(motion["done"])
		collected = collected and bool(motion["done"])
		index += 1
	return collected


func _on_default_pressed() -> void :
	_select_version(0)


func _on_original_pressed() -> void :
	_select_version(1)


func _on_shatter_pressed() -> void :
	_select_version(3)


func _on_replay_pressed() -> void :
	_replay()


func _on_close_pressed() -> void :
	close()


func _on_resize() -> void :
	_layout()
	if _opened:
		_replay()


func _input(event: InputEvent) -> void :
	if not _opened or not event is InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_0, KEY_KP_0:
			_on_default_pressed()
		KEY_1, KEY_KP_1:
			_on_original_pressed()
		KEY_3, KEY_KP_3:
			_on_shatter_pressed()
		KEY_SPACE:
			_on_replay_pressed()
		KEY_ESCAPE:
			close()
		_:
			return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _opened:
		close()


func close() -> void :
	_running = false
	_effects.stop()
	if _opened:
		get_tree().paused = _paused_before
	_opened = false
	queue_free()


func _exit_tree() -> void :
	if is_instance_valid(_effects):
		_effects.stop()
	if _opened:
		get_tree().paused = _paused_before
	_opened = false
