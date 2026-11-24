class_name HapticDebugPanel
extends CanvasLayer













const _COLOR_SELECTED: Color = Color("73ddc4")
const _COLOR_UNSELECTED: Color = Color("929eaf")
const _AHAP_DIR: String = "res://assets/haptic/"
const _PLATFORM_ANDROID: String = "android"
const _PLATFORM_IOS: String = "ios"
const _FONT_SIZE: int = 36

@export var thumbnail_scene: PackedScene


const _TYPES: Dictionary = {
	"android": [
		{"type": "oneshot", "label": "单次震动"}, 
		{"type": "waveform", "label": "波形震动"}, 
		{"type": "composition", "label": "Composition 原语"}, 
	], 
	"ios": [
		{"type": "impact", "label": "Impact 冲击"}, 
		{"type": "notification", "label": "Notification 通知"}, 
		{"type": "selection", "label": "Selection 选择"}, 
		{"type": "transient", "label": "Transient 瞬态"}, 
		{"type": "continuous", "label": "Continuous 持续"}, 
		{"type": "ahap", "label": "AHAP 文件"}, 
		{"type": "ahap_free", "label": "自由 AHAP"}, 
		{"type": "ahap_json", "label": "内联 AHAP"}, 
		{"type": "waveform", "label": "分段波形"}, 
	], 
}


const _TYPE_HINTS: Dictionary = {
	"oneshot": "所有 Android 版本。振幅 0~255，Android 8.0 以下忽略振幅，只按时长震动。", 
	"waveform": "Android 8.0+。每段独立设置时长与振幅，振幅 0 为静默段（常见写法：第一段是起始静默）。低版本由原生层降级为单次。", 
	"composition": "Android 12+（API 31）。Scale 是力度（1.0 最强），Delay 是与上一原语的间隔（第一个填 0）。设备不支持任一原语时不会震动（面板不配降级）。", 
	"ahap": "iOS 13+（Taptic Engine）。从 assets/haptic 选 AHAP 文件，可整体缩放强度/锐度。设备不支持 Core Haptics 时走降级方案。", 
	"impact": "iOS 10+。Soft / Rigid 需要 iOS 13+。", 
	"notification": "iOS 10+。有明确的结果感，适合成功/警告/错误。", 
	"selection": "iOS 10+。极轻的滴答感，固定触感，没有可调参数。", 
	"transient": "Core Haptics 瞬态：强度 intensity、锐度 sharpness 均为 0~1。", 
	"continuous": "Core Haptics 持续：时长（秒）、强度、锐度（均 0~1）。", 
	"ahap_free": "iOS 13+。不依赖文件，按下面的参数在运行时拼出 AHAP 并直接播放：可加多个事件（瞬态/持续），持续事件可调 Attack/Decay/Release/Sustained，还可叠加参数曲线。设备不支持 Core Haptics 时不会震动。", 
}


const _FREE_EVENT_KINDS: Array[Dictionary] = [
	{"id": 0, "label": "Transient 瞬态"}, 
	{"id": 1, "label": "Continuous 持续"}, 
]

const _FREE_SUSTAINED: Array[Dictionary] = [
	{"id": 0, "label": "否"}, 
	{"id": 1, "label": "是"}, 
]


const _FREE_CURVE_PARAMS: Array[Dictionary] = [
	{"id": 0, "label": "强度 HapticIntensityControl", "name": "HapticIntensityControl"}, 
	{"id": 1, "label": "锐度 HapticSharpnessControl", "name": "HapticSharpnessControl"}, 
	{"id": 2, "label": "起音 HapticAttackTimeControl", "name": "HapticAttackTimeControl"}, 
	{"id": 3, "label": "衰减 HapticDecayTimeControl", "name": "HapticDecayTimeControl"}, 
	{"id": 4, "label": "释放 HapticReleaseTimeControl", "name": "HapticReleaseTimeControl"}, 
]


const _UPLOAD_CONNECTION_PATH: String = "user://haptic_upload_connection.cfg"
const _UploadDefaults = preload("res://scripts/capability/haptic/haptic_upload_defaults.gd")
const _SCENE_LABELS: Array[String] = ["按钮", "拿起花串", "成功放置", "非法落点", "种满一盆", "首页揭图", "通关", "Combo Nice", "Combo Great", "Combo Excellent", "Combo Amazing", "Combo Incredible", "Combo Unstoppable", "Combo Legendary", "飞金币", "完成页落盆"]


const _SCENE_GROUPS: Array[Dictionary] = [
	{"label": "基础反馈", "events": [HapticProfiles.Event.BUTTON, HapticProfiles.Event.MOVE_REJECTED, HapticProfiles.Event.HEX_BREAK]}, 
	{"label": "玩法反馈", "events": [HapticProfiles.Event.PICK_UP, HapticProfiles.Event.MOVE_OK, HapticProfiles.Event.FLOWER_MERGE, HapticProfiles.Event.CUP_DONE]}, 
	{"label": "Combo", "events": [HapticProfiles.Event.COMBO_NICE, HapticProfiles.Event.COMBO_GREAT, HapticProfiles.Event.COMBO_EXCELLENT, HapticProfiles.Event.COMBO_AMAZING, HapticProfiles.Event.COMBO_INCREDIBLE, HapticProfiles.Event.COMBO_UNSTOPPABLE, HapticProfiles.Event.COMBO_LEGENDARY]}, 
	{"label": "游戏入场", "events": [HapticProfiles.Event.GAME_ENTER]}, 
	{"label": "完局与奖励", "events": [HapticProfiles.Event.LEVEL_WIN, HapticProfiles.Event.IQ_SCORE_POP, HapticProfiles.Event.COIN_FLY, HapticProfiles.Event.FINISH_POT_DROP]}, 
]


const _STYLE_ONLY_EVENTS: Array[int] = [HapticProfiles.Event.FLOWER_MERGE, HapticProfiles.Event.IQ_SCORE_POP]



const _PRIMITIVES: Array[Dictionary] = [
	{"id": 1, "label": "Click 清脆点击"}, 
	{"id": 2, "label": "Tick 轻短滴答"}, 
	{"id": 3, "label": "Spin 旋转持续"}, 
	{"id": 4, "label": "Thud 沉重撞击"}, 
	{"id": 5, "label": "SlowRise 渐强上升"}, 
	{"id": 6, "label": "QuickRise 快速上升"}, 
	{"id": 7, "label": "QuickFall 快速下落"}, 
	{"id": 8, "label": "LowTick 低频轻滴答"}, 
]

const _IMPACT_STYLES: Array[Dictionary] = [
	{"id": 0, "label": "Light 轻微"}, 
	{"id": 1, "label": "Medium 中等"}, 
	{"id": 2, "label": "Heavy 强烈"}, 
	{"id": 3, "label": "Soft 柔和"}, 
	{"id": 4, "label": "Rigid 刚性"}, 
]

const _NOTIFICATION_KINDS: Array[Dictionary] = [
	{"id": 0, "label": "Success 成功"}, 
	{"id": 1, "label": "Warning 警告"}, 
	{"id": 2, "label": "Error 错误"}, 
]

@onready var _info_label: Label = $Bg / CenterPanel / Margin / VBox / InfoLabel
@onready var _android_btn: Button = $Bg / CenterPanel / Margin / VBox / SceneRow / PlatformRow / AndroidBtn
@onready var _ios_btn: Button = $Bg / CenterPanel / Margin / VBox / SceneRow / PlatformRow / IosBtn
@onready var _type_flow: HFlowContainer = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll / Content / TypeFlow
@onready var _params_box: VBoxContainer = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll / Content / ParamsBox
@onready var _jigsaw_box: VBoxContainer = $Bg / CenterPanel / Margin / VBox / LibraryScroll / Content / JigsawBox
@onready var _status_label: Label = $Bg / CenterPanel / Margin / VBox / StatusLabel

var _native: HapticNative = HapticNative.new()

var _platform: String = _PLATFORM_ANDROID

var _cur_type: Dictionary = {"android": "oneshot", "ios": "impact"}

var _cfgs: Dictionary = {}

var _inited: bool = false
var _event: int = HapticProfiles.Event.PICK_UP
var _loading: bool = false
var _collapsed: bool = false
var _effects_expanded: bool = true
var _config_expanded: bool = false
var _sending: bool = false
var _pending_upload_id: String = ""
var _connection_loaded: bool = false
var _request: HTTPRequest
@onready var _category_selector: OptionButton = $Bg / CenterPanel / Margin / VBox / SceneRow / CategorySelector
@onready var _json_input: TextEdit = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / ConfigBox / JsonInput
@onready var _collapse_btn: Button = $Bg / CenterPanel / Margin / VBox / TitleRow / CollapseBtn
@onready var _send_btn: Button = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / SyncActions / SyncBtn
@onready var _upload_address: LineEdit = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / ConnectionBox / UploadAddress
@onready var _upload_token: LineEdit = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / ConnectionBox / UploadToken
@onready var _preview: HapticPreview = $Bg / CenterPanel / Margin / VBox / PreviewCard / HapticPreview
var _active_tab: int = 0
@export var record_item_scene: PackedScene
@onready var _history_section: VBoxContainer = $Bg / CenterPanel / Margin / VBox / HistorySection
@onready var _history_scroll: ScrollContainer = $Bg / CenterPanel / Margin / VBox / HistorySection / HistoryScroll
@onready var _history_content: VBoxContainer = $Bg / CenterPanel / Margin / VBox / HistorySection / HistoryScroll / Content
@onready var _history_box: VBoxContainer = $Bg / CenterPanel / Margin / VBox / HistorySection / HistoryScroll / Content / Records
@onready var _history_empty: Label = $Bg / CenterPanel / Margin / VBox / HistorySection / HistoryScroll / Content / EmptyLabel
@onready var _history_count: Label = $Bg / CenterPanel / Margin / VBox / HistorySection / Actions / Count
var _history_rows: Array[Dictionary] = []
var _history_snapshot: Array[Dictionary] = []
var _history_dirty: bool = true
var _history_render_index: int = 0
var _library_built: bool = false
var _preview_request: int = 0
@onready var _scene_selector: OptionButton = $Bg / CenterPanel / Margin / VBox / SceneSelection / SceneSelector
@onready var _style_row: HBoxContainer = $Bg / CenterPanel / Margin / VBox / SceneSelection / StyleRow
@onready var _style_selector: OptionButton = $Bg / CenterPanel / Margin / VBox / SceneSelection / StyleRow / StyleSelector
var _selected_category: int = 1
var _selected_scene_style: int = 0
var _category_last_events: Dictionary = {}
@onready var _effects_card: PanelContainer = $Bg / CenterPanel / Margin / VBox / EffectsCard
@onready var _effects_scroll: ScrollContainer = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll
@onready var _library_scroll: ScrollContainer = $Bg / CenterPanel / Margin / VBox / LibraryScroll
@onready var _effects_toggle: Button = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / TitleRow / EffectsToggle
@onready var _config_card: PanelContainer = $Bg / CenterPanel / Margin / VBox / ConfigCard
@onready var _config_scroll: ScrollContainer = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll
@onready var _config_toggle: Button = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / TitleRow / ConfigToggle
@onready var _reset_confirm: ColorRect = $ResetConfirm
@onready var _reset_cancel_btn: Button = $ResetConfirm / Margin / Column / Card / Body / Actions / CancelBtn
@onready var _convert_confirm: ColorRect = $ConvertConfirm
@onready var _convert_message: Label = $ConvertConfirm / Margin / Column / Card / Body / Message
@onready var _convert_cancel_btn: Button = $ConvertConfirm / Margin / Column / Card / Body / Actions / CancelBtn
@onready var _sync_confirm: ColorRect = $SyncConfirm
@onready var _sync_confirm_message: Label = $SyncConfirm / Margin / Column / Card / Body / Message
@onready var _sync_cancel_btn: Button = $SyncConfirm / Margin / Column / Card / Body / Actions / CancelBtn
@onready var _effect_apply_confirm: ColorRect = $EffectApplyConfirm
@onready var _effect_apply_message: Label = $EffectApplyConfirm / Margin / Column / Card / Body / Message
@onready var _effect_apply_cancel_btn: Button = $EffectApplyConfirm / Margin / Column / Card / Body / Actions / CancelBtn
var _pending_effect_apply: Dictionary = {}
@onready var _ios_to_android_btn: Button = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll / Content / ConversionRow / IosToAndroidBtn
@onready var _android_to_ios_btn: Button = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll / Content / ConversionRow / AndroidToIosBtn
@onready var _copy_effect_btn: Button = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll / Content / ConversionRow / CopyEffectBtn
@onready var _apply_copied_effect_btn: Button = $Bg / CenterPanel / Margin / VBox / EffectsCard / Body / Scroll / Content / ConversionRow / ApplyCopiedEffectBtn

var _copied_effect: Dictionary = {}
var _copied_effect_platform: String = ""
var _copied_effect_source: String = ""
var _conversion_generation: int = 0
var _conversion_task: int = -1
var _pending_conversion: Dictionary = {}
var _scroll_touch_active: bool = false
var _scroll_touch_replaying: bool = false
var _scroll_touch_start: Vector2 = Vector2.ZERO
var _scroll_touch_dragged: bool = false
var _scroll_touch_filters: Array[Dictionary] = []
var _scroll_touch_generation: int = 0
var _scroll_touch_ending: bool = false
var _scroll_touch_end: Vector2 = Vector2.ZERO
var _scroll_touch_container: ScrollContainer


func _ready() -> void :
	layer = SceneManager.Layer.DEBUG + 1
	for scroll: ScrollContainer in [_effects_scroll, _library_scroll, _config_scroll, _history_scroll]:
		scroll.scroll_deadzone = 24
		scroll.visibility_changed.connect(_on_touch_scroll_visibility_changed.bind(scroll))
	_claim_buttons(self)
	_build_selection_selectors()
	_refresh_effect_copy_actions()
	_request = HTTPRequest.new()
	_request.timeout = 15.0
	add_child(_request)
	_load_upload_connection()
	HapticManager.get_tune_config().loaded.connect(_on_config_loaded)
	HapticManager.get_tune_config().saved.connect(_on_config_saved)
	HapticManager.dispatched.connect(_on_haptic_dispatched)
	HapticManager.cancelled.connect(_on_haptic_cancelled)
	HapticManager.debug_log_changed.connect(_on_history_changed)
	get_viewport().size_changed.connect(_update_layout)
	hide()
	set_process(false)



func _process(_delta: float) -> void :
	if not visible or _collapsed or _active_tab != 2:
		set_process(false)
		return
	if _scroll_touch_active:
		return
	if _history_dirty:
		_history_snapshot = HapticManager.get_debug_log()
		_history_dirty = false
		_history_render_index = 0
		_history_count.text = "%d条记录" % _history_snapshot.size()
		_history_empty.visible = _history_snapshot.is_empty()
	for step: int in 4:
		if _history_render_index >= _history_snapshot.size():
			break
		_render_history_row(_history_render_index, _history_snapshot[_history_snapshot.size() - 1 - _history_render_index])
		_history_render_index += 1
	if _history_render_index == _history_snapshot.size():
		for index: int in range(_history_render_index, _history_rows.size()):
			(_history_rows[index].root as Control).hide()
		set_process(false)





func _input(event: InputEvent) -> void :
	if _scroll_touch_replaying:
		return

	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:

			if _scroll_touch_active and _scroll_touch_ending:
				_finish_scroll_touch(_scroll_touch_end)
			var scroll: ScrollContainer = _library_scroll if _active_tab == 1 else _effects_scroll
			if _active_tab == 2:
				scroll = _history_scroll
			if _active_tab == 0 and _config_expanded:
				scroll = _config_scroll
			if _scroll_touch_active or not scroll.is_visible_in_tree() or _reset_confirm.visible or _convert_confirm.visible or _sync_confirm.visible or _effect_apply_confirm.visible:
				return
			var point: Vector2 = scroll.get_global_transform_with_canvas().affine_inverse() * event.position
			if not Rect2(Vector2.ZERO, scroll.size).has_point(point):
				return
			_scroll_touch_container = scroll
			_scroll_touch_active = true
			_scroll_touch_start = event.position
			_scroll_touch_dragged = false
			_scroll_touch_generation += 1
			var content: Control = _type_flow.get_parent()
			if scroll == _library_scroll:
				content = _jigsaw_box.get_parent()
			elif scroll == _config_scroll:
				content = _json_input.get_parent().get_parent()
			elif scroll == _history_scroll:
				content = _history_content
			_pass_scroll_touch(content, event.position)

			_scroll_touch_active = not _scroll_touch_filters.is_empty()
		elif _scroll_touch_active:
			_scroll_touch_dragged = _scroll_touch_dragged or event.position.distance_to(_scroll_touch_start) > _scroll_touch_container.scroll_deadzone
			_scroll_touch_end = event.position
			_scroll_touch_ending = true

			_finish_scroll_touch.call_deferred(event.position, _scroll_touch_generation)
	elif event is InputEventMouseMotion and event.device == InputEvent.DEVICE_ID_EMULATION and _scroll_touch_active:
		_scroll_touch_dragged = _scroll_touch_dragged or event.position.distance_to(_scroll_touch_start) > _scroll_touch_container.scroll_deadzone
	elif event is InputEventScreenTouch and event.canceled and _scroll_touch_active:
		_scroll_touch_dragged = true


func _pass_scroll_touch(node: Control, position: Vector2) -> void :
	if not node.is_visible_in_tree():
		return
	var point: Vector2 = node.get_global_transform_with_canvas().affine_inverse() * position
	if not Rect2(Vector2.ZERO, node.size).has_point(point):
		return
	_scroll_touch_filters.append({"control": node, "filter": node.mouse_filter})
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child: Node in node.get_children(true):
		if child is Control:
			_pass_scroll_touch(child, position)


func _finish_scroll_touch(position: Vector2, generation: int = -1) -> void :
	if not _scroll_touch_active or (generation >= 0 and generation != _scroll_touch_generation):
		return
	var tapped: bool = not _scroll_touch_dragged and is_instance_valid(_scroll_touch_container) and _scroll_touch_container.is_visible_in_tree()
	for saved: Dictionary in _scroll_touch_filters:
		if is_instance_valid(saved.control):
			saved.control.mouse_filter = saved.filter
	_scroll_touch_filters.clear()
	_scroll_touch_active = false
	_scroll_touch_ending = false
	_scroll_touch_generation += 1
	_scroll_touch_container = null
	if not tapped:
		return
	_scroll_touch_replaying = true
	for pressed: bool in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.device = InputEvent.DEVICE_ID_EMULATION
		click.button_index = MOUSE_BUTTON_LEFT
		click.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		click.position = position
		click.global_position = position
		click.pressed = pressed

		get_viewport().push_input(click, true)
	_scroll_touch_replaying = false


func _cancel_scroll_touch() -> void :
	_scroll_touch_dragged = true
	_finish_scroll_touch(_scroll_touch_start)


func _on_touch_scroll_visibility_changed(scroll: ScrollContainer) -> void :
	if scroll == _scroll_touch_container and not scroll.is_visible_in_tree():
		_cancel_scroll_touch()


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_cancel_scroll_touch()


func _load_upload_connection() -> void :
	var initial_address: String = _upload_address.text
	var initial_token: String = _upload_token.text
	var job: Dictionary = {}
	var task: int = WorkerThreadPool.add_task(_read_upload_connection.bind(job))
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	if not is_inside_tree():
		return
	var connection: Dictionary = job.connection

	if _upload_address.text == initial_address:
		_upload_address.text = connection.address
	if _upload_token.text == initial_token:
		_upload_token.text = connection.token
	if not _sending:
		_pending_upload_id = connection.pending_id
	_connection_loaded = true


static func _read_upload_connection(job: Dictionary) -> void :
	var saved: ConfigFile = ConfigFile.new()
	if not OS.has_feature("rel"):
		saved.load(_UPLOAD_CONNECTION_PATH)
	job.connection = _UploadDefaults.resolve_connection(saved, _UploadDefaults.load_defaults())




func open() -> void :
	_on_sync_cancelled()
	_close_selection_popups()
	if not _inited:
		_init_state()
		_inited = true
	show()
	_collapsed = false
	_active_tab = 0
	_update_layout()
	_load_event()
	_status_label.text = ""



func _init_state() -> void :
	_platform = _PLATFORM_IOS if OS.get_name() == "iOS" else _PLATFORM_ANDROID
	for p: String in _TYPES:
		var by_type: Dictionary = {}
		for t: Dictionary in _TYPES[p]:
			by_type[String(t["type"])] = _default_cfg(String(t["type"]))
		_cfgs[p] = by_type


func _on_config_loaded() -> void :
	if _inited:
		_load_event()


func _on_config_saved(error: String) -> void :
	if not error.is_empty():
		_set_status("参数已在本次运行生效，但保存失败：" + error)


func _load_event() -> void :
	_on_sync_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_loading = true
	_event = _editable_scene_event(_event)
	_load_profile(HapticManager.get_tune_config().get_profile(_event))
	_refresh_scene_selection()
	_loading = false
	_refresh_effect_copy_actions()
	_update_layout()


func _on_scene_event_selected(event: int) -> void :
	_close_selection_popups()
	if not HapticProfiles.PROFILES.has(event):
		return
	_commit_input()
	_event = event
	_load_event()
	_set_status("当前场景：" + _scene_label(_event))


func _apply_current_platform() -> void :
	if _loading or not _inited:
		return
	var error: String = HapticManager.get_tune_config().set_platform(_event, _platform, _to_native_cfg(_current_cfg(_platform)))
	_set_status("已即时应用：%s / %s；收起后操作游戏，本机自动保存" % [_scene_label(_event), _platform_label(_platform)] if error.is_empty() else "未应用：" + error)
	_refresh_info()
	_refresh_preview()
	_refresh_scene_selection()


func _commit_input() -> void :
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()


func _refresh_effect_copy_actions() -> void :
	var unavailable: bool = not _inited or _loading or OS.has_feature("rel")
	_copy_effect_btn.disabled = unavailable
	_apply_copied_effect_btn.disabled = unavailable or _copied_effect.is_empty()\
	or _copied_effect_platform != _platform
	_apply_copied_effect_btn.modulate.a = 0.45 if _apply_copied_effect_btn.disabled else 1.0
	if _copied_effect.is_empty():
		_apply_copied_effect_btn.tooltip_text = "请先复制效果参数"
	elif _copied_effect_platform != _platform:
		_apply_copied_effect_btn.tooltip_text = "已复制%s参数，请切换到同平台应用" % _platform_label(_copied_effect_platform)
	else:
		_apply_copied_effect_btn.tooltip_text = "应用来自%s的完整效果参数" % _copied_effect_source


func _on_copy_effect_pressed() -> void :
	if not _inited or _loading or OS.has_feature("rel"):
		return
	_commit_input()
	_on_effect_apply_cancelled()
	var effect: Dictionary = _to_native_cfg(_current_cfg(_platform))
	var error: String = HapticTuneConfig._validate_effect(effect, _platform)
	if not error.is_empty():
		_set_status("未复制效果参数：" + error)
		return
	_copied_effect = effect.duplicate(true)
	_copied_effect_platform = _platform
	_copied_effect_source = "%s / %s" % [_scene_label(_event), _platform_label(_platform)]
	_refresh_effect_copy_actions()
	_set_status("已复制效果参数：" + _copied_effect_source)


func _on_apply_copied_effect_pressed() -> void :
	if not _inited or _loading or OS.has_feature("rel") or _copied_effect.is_empty()\
	or _copied_effect_platform != _platform:
		return
	_commit_input()
	_on_sync_cancelled()
	_on_reset_all_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	var effect: Dictionary = _copied_effect.duplicate(true)
	var error: String = HapticTuneConfig._validate_effect(effect, _platform)
	if not error.is_empty():
		_set_status("未应用复制参数：" + error)
		return
	var before: Dictionary = HapticManager.get_tune_config().get_profile(_event).get(_platform, {}).duplicate(true)
	var snapshot: Dictionary = {"event": _event, "platform": _platform, "before": before, 
		"effect": effect, "source": _copied_effect_source}
	var defaults: Dictionary = HapticProfiles.PROFILES[_event].get(_platform, {})
	if not before.is_empty() and before != defaults:
		_pending_effect_apply = snapshot
		_effect_apply_message.text = "「%s / %s」已有非默认配置，应用复制的效果参数将覆盖之前的配置，是否继续？" % [
			_scene_label(_event), _platform_label(_platform)]
		_effect_apply_confirm.show()
		_effect_apply_cancel_btn.grab_focus()
		return
	_apply_copied_effect(snapshot)


func _effect_apply_matches(snapshot: Dictionary) -> bool:
	return visible and not _collapsed and _active_tab == 0 and _event == int(snapshot.event)\
	and _platform == snapshot.platform and _copied_effect_platform == snapshot.platform\
	and _copied_effect == snapshot.effect\
	and HapticManager.get_tune_config().get_profile(_event).get(_platform, {}) == snapshot.before


func _apply_copied_effect(snapshot: Dictionary) -> void :
	if not _effect_apply_matches(snapshot):
		_set_status("配置或复制参数已变化，本次应用已取消，请重新应用")
		return
	var error: String = HapticManager.get_tune_config().set_platform(snapshot.event, snapshot.platform, snapshot.effect)
	if not error.is_empty():
		_set_status("未应用复制参数：" + error)
		return
	_load_event()
	_set_status("已应用复制参数：%s → %s / %s；本机自动保存" % [
		snapshot.source, _scene_label(_event), _platform_label(_platform)])


func _on_effect_apply_cancelled() -> void :
	_pending_effect_apply = {}
	_effect_apply_confirm.hide()


func _on_effect_apply_confirmed() -> void :
	if not _effect_apply_confirm.visible or _pending_effect_apply.is_empty() or OS.has_feature("rel"):
		return
	var snapshot: Dictionary = _pending_effect_apply
	_on_effect_apply_cancelled()
	_apply_copied_effect(snapshot)


func _on_collapse_pressed() -> void :
	_commit_input()
	_on_sync_cancelled()
	_on_reset_all_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	_preview.stop_playhead()
	_collapsed = not _collapsed
	_update_layout()


func _update_layout() -> void :
	var bg: ColorRect = $Bg
	var panel: PanelContainer = $Bg / CenterPanel
	var insets: Vector2 = UiMetrics.safe_insets()
	for child: Node in $Bg / CenterPanel / Margin / VBox.get_children():
		if child.name != "TitleRow":
			(child as CanvasItem).visible = not _collapsed
	bg.color.a = 0.0 if _collapsed else 0.78
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE if _collapsed else Control.MOUSE_FILTER_STOP
	panel.set_anchor(SIDE_TOP, 1.0 if _collapsed else 0.0)
	panel.offset_top = -160.0 - insets.y if _collapsed else 24.0 + insets.x
	panel.offset_bottom = -16.0 - insets.y
	_collapse_btn.text = "展开" if _collapsed else "收起"
	$Bg / CenterPanel / Margin / VBox / TitleRow / Title.text = "震动 · " + _scene_label(_event) if _collapsed else "震动调试"
	_apply_tab_visibility()


func _on_tune_tab_pressed() -> void :
	_set_tab(0)


func _on_jigsaw_tab_pressed() -> void :
	if not _library_built:
		_build_jigsaw_catalog()
		_library_built = true
	_set_tab(1)


func _on_records_tab_pressed() -> void :
	_set_tab(2)


func _set_tab(tab: int) -> void :
	_commit_input()
	_on_sync_cancelled()
	_on_reset_all_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	_preview.stop_playhead()
	_active_tab = tab
	_apply_tab_visibility()


func _apply_tab_visibility() -> void :
	var tune_visible: bool = not _collapsed and _active_tab == 0
	for name: String in ["SceneRow", "SceneSelection", "InfoLabel", "PreviewCard", "EffectsCard", "ConfigCard", "ActionRow"]:
		($Bg / CenterPanel / Margin / VBox.get_node(name) as CanvasItem).visible = tune_visible
	_apply_section_visibility()
	$Bg / CenterPanel / Margin / VBox / LibraryScroll.visible = not _collapsed and _active_tab == 1
	_history_section.visible = not _collapsed and _active_tab == 2
	_status_label.visible = not _collapsed and _active_tab != 2
	for index: int in 3:
		var button: Button = $Bg / CenterPanel / Margin / VBox / TabRow.get_child(index)
		_select_button(button, _active_tab == index)
	if not _collapsed and _active_tab == 2:
		_on_history_refresh_pressed()
	else:
		set_process(false)
	if not _collapsed and _active_tab == 1:
		for child: Node in _jigsaw_box.get_children():
			if child is VBoxContainer and child.visible:
				_populate_jigsaw_group(child)


func _select_button(button: Button, selected: bool) -> void :
	button.modulate = Color.WHITE
	button.add_theme_stylebox_override("normal", button.get_theme_stylebox("pressed" if selected else "hover", "Button"))
	button.add_theme_color_override("font_color", _COLOR_SELECTED if selected else _COLOR_UNSELECTED)


func _on_connection_toggle_pressed() -> void :
	_commit_input()
	var box: VBoxContainer = $Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / ConnectionBox
	box.visible = not box.visible
	$Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / SyncActions / ConnectionToggle.text = "收起连接设置" if box.visible else "连接设置"


func _on_config_toggle_pressed() -> void :
	_commit_input()
	_config_expanded = not _config_expanded
	_effects_expanded = not _config_expanded
	_apply_section_visibility()


func _on_effects_toggle_pressed() -> void :
	_commit_input()
	_effects_expanded = not _effects_expanded
	if _effects_expanded:
		_config_expanded = false
	_apply_section_visibility()


func _apply_section_visibility() -> void :
	_effects_scroll.visible = _effects_expanded
	_config_scroll.visible = _config_expanded
	_effects_card.size_flags_vertical = Control.SIZE_EXPAND_FILL if _effects_expanded else Control.SIZE_FILL
	_config_card.size_flags_vertical = Control.SIZE_EXPAND_FILL if _config_expanded else Control.SIZE_FILL
	_effects_toggle.text = "收起" if _effects_expanded else "展开"
	_config_toggle.text = "收起" if _config_expanded else "展开"


func _refresh_preview() -> void :
	if _inited:
		_preview_request = 0
		_preview.set_effect(_to_native_cfg(_current_cfg(_platform)), _platform)


func _on_haptic_dispatched(event: int, request: int, profile: Dictionary) -> void :
	if not visible or _collapsed or _active_tab != 0 or _running_platform() != _platform:
		return
	if event == _event:
		_preview.set_effect(profile.get(_platform, {}), _platform)
		_preview_request = request
		_preview.start_playhead("派发估算")
	elif _running_platform() == _PLATFORM_ANDROID:
		_preview.stop_playhead()


func _on_haptic_cancelled(request: int) -> void :
	if request == 0 or request == _preview_request:
		_preview.stop_playhead()
		_preview_request = 0


func _on_history_changed() -> void :
	_history_dirty = true
	if visible and not _collapsed and _active_tab == 2:
		set_process(true)


func _on_history_refresh_pressed() -> void :
	_on_history_changed()


func _on_history_clear_pressed() -> void :
	HapticManager.clear_debug_log()
	_history_scroll.scroll_vertical = 0


func _render_history_row(index: int, record: Dictionary) -> void :
	if index == _history_rows.size():
		var new_item: PanelContainer = record_item_scene.instantiate() as PanelContainer
		_claim_buttons(new_item)
		var details: Button = new_item.get_node("Body/DetailsButton")
		details.pressed.connect(_on_record_details_pressed.bind(index))
		_history_rows.append({"root": new_item, "title": new_item.get_node("Body/Title"), "event": new_item.get_node("Body/Event"), 
			"facts": new_item.get_node("Body/Facts"), "result": new_item.get_node("Body/Result")})
		_history_box.add_child(new_item)
	var row: Dictionary = _history_rows[index]
	var item: PanelContainer = row.root
	item.set_meta("record", record)
	(row.title as Label).text = _scene_label(int(record.event))
	(row.event as Label).text = String(record.event_name)
	var time: int = int(record.time_msec)
	(row.facts as Label).text = "%02d:%02d.%03d · Frame %d · %s · 优先级%d\n请求%d · %s · %s" % [
		time / 60000, (time / 1000) % 60, time % 1000, int(record.frame), String(record.platform), int(record.priority), 
		int(record.request), "本机覆盖" if bool(record.overridden) else "包内参数", String(record.type) if not String(record.type).is_empty() else "无派发参数"]
	var result: Label = row.result
	result.text = "%s · %s" % [_history_result_label(String(record.result)), String(record.reason)]
	result.add_theme_color_override("font_color", Color("73ddc4") if record.result == "dispatched" else Color("ecc28b"))
	item.show()


func _history_result_label(result: String) -> String:
	match result:
		"queued": return "等待派发"
		"dispatched": return "已派发"
		"unconfigured": return "未配置"
		"blocked": return "条件不满足"
		"suppressed": return "优先级抑制"
		"cancelled": return "已取消"
	return result


func _on_record_details_pressed(index: int) -> void :
	var item: Control = _history_rows[index].root
	var record: Dictionary = item.get_meta("record")
	if record.platform in ["Android", "iOS"]:
		_platform = _PLATFORM_ANDROID if record.platform == "Android" else _PLATFORM_IOS
	_set_tab(0)
	_on_scene_event_selected(int(record.event))
	_set_status("已跳转：%s / %s；显示当前有效参数" % [_scene_label(_event), _platform_label(_platform)])



func _claim_buttons(node: Node) -> void :
	if node is BaseButton:
		HapticManager.claim_button_haptic(node)
	for child: Node in node.get_children():
		_claim_buttons(child)



func _default_cfg(type: String) -> Dictionary:
	match type:
		"oneshot":
			return {"type": type, "duration_msec": 25, "amplitude": 100}
		"waveform":
			return {"type": type, "timings_msec": [0, 100, 80, 100], "amplitudes": [0, 50, 0, 50]}
		"composition":
			return {"type": type, "primitives": [1], "scales_percent": [80], "delays_msec": [0]}
		"ahap":
			var files: PackedStringArray = _ahap_files()
			var file: String = files[0] if not files.is_empty() else ""
			return {"type": type, "file": _AHAP_DIR + file, "intensity_scale": 1.0, "sharpness_scale": 1.0}
		"ahap_free":
			return {"type": type, "events": [_default_free_event()], "curves": []}
		"ahap_json":
			return {"type": type, "json": JSON.stringify(_build_ahap_dict({"events": [_default_free_event()], "curves": []}))}
		"impact":
			return {"type": type, "style": 1}
		"notification":
			return {"type": type, "kind": 0}
		"transient":
			return {"type": type, "intensity": 0.5, "sharpness": 0.5}
		"continuous":
			return {"type": type, "duration": 0.1, "intensity": 0.5, "sharpness": 0.5}
	return {"type": type}



func _default_free_event() -> Dictionary:
	return {"kind": 1, "time": 0.0, "duration": 0.1, "intensity": 0.5, "sharpness": 0.5, 
		"attack": 0.0, "decay": 0.0, "release": 0.0, "sustained": 1}



func _default_free_curve() -> Dictionary:
	return {"param": 0, "time": 0.0, 
		"points": [{"time": 0.0, "value": 1.0}, {"time": 0.1, "value": 0.0}]}



func _ahap_files() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for f: String in DirAccess.get_files_at(_AHAP_DIR):
		if f.ends_with(".json"):
			out.append(f)
	out.sort()
	return out



func _current_cfg(platform: String) -> Dictionary:
	return (_cfgs[platform] as Dictionary)[_cur_type[platform]]



func _running_platform() -> String:
	match OS.get_name():
		"Android":
			return _PLATFORM_ANDROID
		"iOS":
			return _PLATFORM_IOS
	return ""




func _refresh_all() -> void :
	_cancel_scroll_touch()
	_refresh_info()
	_select_button(_android_btn, _platform == _PLATFORM_ANDROID)
	_select_button(_ios_btn, _platform == _PLATFORM_IOS)
	_ios_to_android_btn.visible = _platform == _PLATFORM_IOS
	_android_to_ios_btn.visible = _platform == _PLATFORM_ANDROID
	_refresh_effect_copy_actions()
	_build_type_buttons()
	_build_params()
	_refresh_preview()


func _refresh_info() -> void :
	var plugin_ok: bool = Engine.has_singleton("VibratePlugin")
	var plugin_text: String = "已加载" if plugin_ok else "未加载"
	var overridden: bool = HapticManager.get_tune_config().is_overridden(_event)
	var cfg: Dictionary = HapticManager.get_tune_config().get_profile(_event).get(_platform, {})
	var source: String = "TODO: " + HapticProfiles.Event.keys()[_event] if cfg.is_empty() else ("本机覆盖" if overridden else "包内默认")
	_info_label.text = "%s · 插件%s · 自动保存" % ["未配置" if cfg.is_empty() else source, plugin_text]
	_info_label.tooltip_text = "%s · 插件%s%s · %s\n修改实时生效，自动保存；场景和样式选择不改变AB分组" % [OS.get_name(), plugin_text, "，试播使用降级" if not plugin_ok else "", source]


func _build_type_buttons() -> void :
	_clear_children(_type_flow)
	var options: Array[Dictionary] = []
	var selected: int = 0
	var types: Array = _TYPES[_platform]
	for index: int in types.size():
		options.append({"id": index, "label": types[index].label})
		if types[index].type == _cur_type[_platform]:
			selected = index
	_type_flow.add_child(_make_label("效果类型", 200))
	var picker: OptionButton = _make_option(options, selected, func(index: int) -> void :
		_cur_type[_platform] = types[index].type
		_refresh_all.call_deferred())
	picker.name = "EffectType"
	_type_flow.add_child(picker)



func _build_params() -> void :
	_cancel_scroll_touch()
	_clear_children(_params_box)
	var cfg: Dictionary = _current_cfg(_platform)
	var type: String = String(cfg["type"])
	_params_box.add_child(_make_caption(String(_TYPE_HINTS.get(type, ""))))
	match type:
		"oneshot":
			_add_spin_row("时长 (ms)", cfg, "duration_msec", 1, 10000, 5, true)
			_add_spin_row("振幅 (0~255)", cfg, "amplitude", 0, 255, 5, true)
		"waveform":
			_build_waveform(cfg)
		"composition":
			_build_composition(cfg)
		"ahap":
			_build_ahap(cfg)
		"ahap_free":
			_build_ahap_free(cfg)
		"ahap_json":
			_build_inline_ahap(cfg)
		"impact":
			_add_option_row("冲击强度", _IMPACT_STYLES, cfg, "style")
		"notification":
			_add_option_row("通知类型", _NOTIFICATION_KINDS, cfg, "kind")
		"transient":
			_add_spin_row("强度 intensity", cfg, "intensity", 0.0, 1.0, 0.05, false)
			_add_spin_row("锐度 sharpness", cfg, "sharpness", 0.0, 1.0, 0.05, false)
		"continuous":
			_add_spin_row("时长 (秒)", cfg, "duration", 0.01, 5.0, 0.01, false)
			_add_spin_row("强度 intensity", cfg, "intensity", 0.0, 1.0, 0.05, false)
			_add_spin_row("锐度 sharpness", cfg, "sharpness", 0.0, 1.0, 0.05, false)

	if cfg.has("fallback"):
		_params_box.add_child(_make_caption("降级方案（沿用载入的配置，不可编辑）：%s" % _literal(cfg["fallback"])))



func _build_waveform(cfg: Dictionary) -> void :
	var timings: Array = cfg["timings_msec"]
	var amps: Array = cfg["amplitudes"]
	_params_box.add_child(_make_caption("段号对应时间轨道，振幅0为静默"))
	for i: int in timings.size():
		var box: VBoxContainer = _add_group()
		var head: HBoxContainer = HBoxContainer.new()
		var title: Label = _make_label("%02d · %s" % [i + 1, "静默段" if int(amps[i]) == 0 else "振动段"], 0)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color", Color("73ddc4"))
		head.add_child(title)
		var remove: Button = _make_button("删除", func() -> void :
			timings.remove_at(i)
			amps.remove_at(i)
			_apply_current_platform()
			_build_params.call_deferred())
		remove.theme_type_variation = &"HapticQuietButton"
		remove.disabled = timings.size() <= 1
		head.add_child(remove)
		box.add_child(head)
		var fields: GridContainer = GridContainer.new()
		fields.columns = 2
		fields.add_theme_constant_override("h_separation", 16)
		for field: int in 2:
			var column: VBoxContainer = VBoxContainer.new()
			column.add_theme_constant_override("separation", 8)
			column.add_child(_make_caption("时长 (ms)" if field == 0 else "振幅 (0~255)"))
			if field == 0:
				column.add_child(_make_spin(timings[i], 0, 10000, 10, func(v: float) -> void : timings[i] = int(v)))
			else:
				column.add_child(_make_spin(amps[i], 0, 255, 5, func(v: float) -> void :
					amps[i] = int(v)
					title.text = "%02d · %s" % [i + 1, "静默段" if int(v) == 0 else "振动段"]))
			fields.add_child(column)
		box.add_child(fields)
	_params_box.add_child(_make_button("+ 添加分段", func() -> void :
		timings.append(100)
		amps.append(50)
		_apply_current_platform()
		_build_params.call_deferred()))



func _build_composition(cfg: Dictionary) -> void :
	var prims: Array = cfg["primitives"]
	var scales: Array = cfg["scales_percent"]
	var delays: Array = cfg["delays_msec"]
	for i: int in prims.size():
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		var head: HBoxContainer = HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		head.add_child(_make_label("原语%d" % (i + 1), 160))
		head.add_child(_make_option(_PRIMITIVES, int(prims[i]), func(id: int) -> void : prims[i] = id))
		var del_btn: Button = _make_button("删", func() -> void :
			prims.remove_at(i)
			scales.remove_at(i)
			delays.remove_at(i)
			_apply_current_platform()
			_build_params.call_deferred()
		)
		del_btn.disabled = prims.size() <= 1
		head.add_child(del_btn)
		box.add_child(head)
		var tail: VBoxContainer = VBoxContainer.new()
		tail.add_theme_constant_override("separation", 8)
		var scale_row: HBoxContainer = HBoxContainer.new()
		scale_row.add_child(_make_label("力度 Scale", 300))

		scale_row.add_child(_make_spin(float(scales[i]) / 100.0, 0.0, 1.0, 0.05, func(v: float) -> void : scales[i] = roundi(v * 100.0)))
		tail.add_child(scale_row)
		var delay_row: HBoxContainer = HBoxContainer.new()
		delay_row.add_child(_make_label("停顿 Delay (ms)", 300))
		delay_row.add_child(_make_spin(delays[i], 0, 2000, 10, func(v: float) -> void : delays[i] = int(v)))
		tail.add_child(delay_row)
		box.add_child(tail)
		_params_box.add_child(box)
	_params_box.add_child(_make_button("+ 添加原语", func() -> void :
		prims.append(1)
		scales.append(80)
		delays.append(60)
		_apply_current_platform()
		_build_params.call_deferred()
	))



func _build_ahap(cfg: Dictionary) -> void :
	var files: PackedStringArray = _ahap_files()
	var options: Array[Dictionary] = []
	for i: int in files.size():
		options.append({"id": i, "label": files[i]})
	var cur_idx: int = files.find(String(cfg["file"]).trim_prefix(_AHAP_DIR))
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_label("AHAP 文件", 0))
	var picker: OptionButton = _make_option(options, cur_idx, func(id: int) -> void : cfg["file"] = _AHAP_DIR + files[id])

	picker.custom_minimum_size.x = 0
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.fit_to_longest_item = false
	picker.clip_text = true
	picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(picker)
	_params_box.add_child(row)
	_add_spin_row("强度缩放", cfg, "intensity_scale", 0.0, 2.0, 0.05, false)
	_add_spin_row("锐度缩放", cfg, "sharpness_scale", 0.0, 2.0, 0.05, false)




func _build_ahap_free(cfg: Dictionary) -> void :
	var events: Array = cfg["events"]
	for i: int in events.size():
		var ev: Dictionary = events[i]
		var box: VBoxContainer = _add_group()
		var head: HBoxContainer = HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		head.add_child(_make_label("事件%d" % (i + 1), 160))
		head.add_child(_make_option(_FREE_EVENT_KINDS, int(ev["kind"]), func(id: int) -> void :
			ev["kind"] = id
			_apply_current_platform()
			_build_params.call_deferred()
		))
		var del_btn: Button = _make_button("删", func() -> void :
			events.remove_at(i)
			_apply_current_platform()
			_build_params.call_deferred()
		)
		del_btn.disabled = events.size() <= 1
		head.add_child(del_btn)
		box.add_child(head)
		_add_spin_row("起始时间 Time (秒)", ev, "time", 0.0, 5.0, 0.01, false, box)
		_add_spin_row("强度 HapticIntensity", ev, "intensity", 0.0, 1.0, 0.05, false, box)
		_add_spin_row("锐度 HapticSharpness", ev, "sharpness", 0.0, 1.0, 0.05, false, box)

		if int(ev["kind"]) == 1:
			_add_spin_row("时长 EventDuration (秒)", ev, "duration", 0.01, 5.0, 0.01, false, box)
			_add_spin_row("AttackTime", ev, "attack", 0.0, 1.0, 0.01, false, box)
			_add_spin_row("DecayTime", ev, "decay", 0.0, 1.0, 0.01, false, box)
			_add_spin_row("ReleaseTime", ev, "release", 0.0, 1.0, 0.01, false, box)
			_add_option_row("Sustained 保持", _FREE_SUSTAINED, ev, "sustained", box)
	_params_box.add_child(_make_button("+ 添加事件", func() -> void :
		events.append(_default_free_event())
		_apply_current_platform()
		_build_params.call_deferred()
	))

	_params_box.add_child(_make_caption("参数曲线（可选）：对事件随时间调节强度/锐度/包络。控制点时间相对曲线起始时间，每条至少 2 个点；取值范围见 Apple Core Haptics 文档。"))
	var curves: Array = cfg["curves"]
	for i: int in curves.size():
		var curve: Dictionary = curves[i]
		var box: VBoxContainer = _add_group()
		var head: HBoxContainer = HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		head.add_child(_make_label("曲线%d" % (i + 1), 160))
		head.add_child(_make_option(_FREE_CURVE_PARAMS, int(curve["param"]), func(id: int) -> void : curve["param"] = id))
		head.add_child(_make_button("删", func() -> void :
			curves.remove_at(i)
			_apply_current_platform()
			_build_params.call_deferred()
		))
		box.add_child(head)
		_add_spin_row("起始时间 Time (秒)", curve, "time", 0.0, 5.0, 0.01, false, box)
		var points: Array = curve["points"]
		for j: int in points.size():
			var pt: Dictionary = points[j]
			var group: VBoxContainer = VBoxContainer.new()
			group.add_theme_constant_override("separation", 8)
			var head_row: HBoxContainer = HBoxContainer.new()
			var point_label: Label = _make_label("控制点%d" % (j + 1), 120)
			point_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			head_row.add_child(point_label)
			var pt_del: Button = _make_button("删除", func() -> void :
				points.remove_at(j)
				_apply_current_platform()
				_build_params.call_deferred())
			pt_del.disabled = points.size() <= 2
			head_row.add_child(pt_del)
			group.add_child(head_row)
			box.add_child(group)
			_add_spin_row("时间 (秒)", pt, "time", 0, 5, 0.01, false, group)
			_add_spin_row("控制值", pt, "value", -1, 1, 0.05, false, group)
		box.add_child(_make_button("+ 添加控制点", func() -> void :
			var last_time: float = float((points[points.size() - 1] as Dictionary)["time"])
			points.append({"time": last_time + 0.1, "value": 0.0})
			_apply_current_platform()
			_build_params.call_deferred()
		))
	_params_box.add_child(_make_button("+ 添加参数曲线", func() -> void :
		curves.append(_default_free_curve())
		_apply_current_platform()
		_build_params.call_deferred()
	))



func _add_group() -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"HapticSegmentCard"
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	panel.add_child(margin)
	_params_box.add_child(panel)
	return box



func _build_ahap_dict(cfg: Dictionary) -> Dictionary:
	var pattern: Array = []
	for ev: Dictionary in cfg["events"]:
		var params: Array = [
			{"ParameterID": "HapticIntensity", "ParameterValue": ev["intensity"]}, 
			{"ParameterID": "HapticSharpness", "ParameterValue": ev["sharpness"]}, 
		]
		var event: Dictionary = {"Time": ev["time"], "EventType": "HapticTransient", "EventParameters": params}
		if int(ev["kind"]) == 1:
			event["EventType"] = "HapticContinuous"
			event["EventDuration"] = ev["duration"]
			params.append({"ParameterID": "AttackTime", "ParameterValue": ev["attack"]})
			params.append({"ParameterID": "DecayTime", "ParameterValue": ev["decay"]})
			params.append({"ParameterID": "ReleaseTime", "ParameterValue": ev["release"]})
			params.append({"ParameterID": "Sustained", "ParameterValue": ev["sustained"]})
		pattern.append({"Event": event})
	for curve: Dictionary in cfg["curves"]:
		var points: Array = []
		for pt: Dictionary in curve["points"]:
			points.append({"Time": pt["time"], "ParameterValue": pt["value"]})
		pattern.append({"ParameterCurve": {
			"ParameterID": String(_FREE_CURVE_PARAMS[int(curve["param"])]["name"]), 
			"Time": curve["time"], 
			"ParameterCurveControlPoints": points, 
		}})
	return {"Version": 1, "Pattern": pattern}



func _to_native_cfg(cfg: Dictionary) -> Dictionary:
	var result: Dictionary = cfg.duplicate(true)
	if cfg.get("type") == "ahap_free":
		result = {"type": "ahap_json", "json": JSON.stringify(_build_ahap_dict(cfg))}
		if cfg.has("fallback"):
			result.fallback = cfg.fallback.duplicate(true)
	elif cfg.get("type") == "ahap_json" and cfg.has("_ahap"):
		result.json = JSON.stringify(cfg._ahap)
		result.erase("_ahap")
	return result



func _build_inline_ahap(cfg: Dictionary) -> void :
	if not cfg.has("_ahap"):
		cfg["_ahap"] = JSON.parse_string(cfg.json)
	var ahap: Dictionary = cfg._ahap
	for entry: Dictionary in ahap.Pattern:
		if not entry.has("Event"):
			_params_box.add_child(_make_caption("参数曲线保留；可通过配置 JSON 编辑"))
			continue
		var event: Dictionary = entry.Event
		var box: VBoxContainer = _add_group()
		box.add_child(_make_caption(String(event.EventType)))
		_add_spin_row("起始时间 (秒)", event, "Time", 0, 60, 0.01, false, box)
		if event.EventType == "HapticContinuous":
			_add_spin_row("时长 (秒)", event, "EventDuration", 0.001, 60, 0.01, false, box)
		for parameter: Dictionary in event.EventParameters:
			_add_spin_row(String(parameter.ParameterID), parameter, "ParameterValue", 0, 1, 0.01, false, box)



func _describe(cfg: Dictionary) -> String:
	if String(cfg.get("type", "")) == "ahap_free":
		return "自由 AHAP（%d 个事件，%d 条曲线）" % [(cfg["events"] as Array).size(), (cfg["curves"] as Array).size()]
	return _literal(cfg)






func _add_spin_row(label: String, cfg: Dictionary, key: String, lo: float, hi: float, step: float, as_int: bool, 
		parent: Container = null) -> void :
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_label(label, 300))
	row.add_child(_make_spin(float(cfg.get(key, lo)), lo, hi, step, func(v: float) -> void :
		cfg[key] = int(v) if as_int else v
	))
	(parent if parent != null else _params_box).add_child(row)



func _add_option_row(label: String, options: Array[Dictionary], cfg: Dictionary, key: String, 
		parent: Container = null) -> void :
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_label(label, 300))
	row.add_child(_make_option(options, int(cfg.get(key, 0)), func(id: int) -> void : cfg[key] = id))
	(parent if parent != null else _params_box).add_child(row)




func _make_spin(value: float, lo: float, hi: float, step: float, on_change: Callable) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var spin: SpinBox = SpinBox.new()
	spin.min_value = lo
	spin.max_value = hi

	spin.step = 1.0 if step >= 1.0 else 1e-06
	spin.value = value
	spin.update_on_text_changed = true
	spin.custom_minimum_size = Vector2(160, 112)
	spin.get_line_edit().add_theme_font_size_override("font_size", _FONT_SIZE)
	spin.value_changed.connect( func(v: float) -> void :
		on_change.call(v)
		_apply_current_platform()
	)
	var minus_btn: Button = _make_button("-", func() -> void : spin.value -= step)
	minus_btn.custom_minimum_size = Vector2(112, 112)
	var plus_btn: Button = _make_button("+", func() -> void : spin.value += step)
	plus_btn.custom_minimum_size = Vector2(112, 112)
	box.add_child(minus_btn)
	box.add_child(spin)
	box.add_child(plus_btn)
	return box



func _make_option(options: Array[Dictionary], current_id: int, on_pick: Callable) -> OptionButton:
	var opt: OptionButton = OptionButton.new()
	opt.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	HapticManager.claim_button_haptic(opt)
	opt.custom_minimum_size = Vector2(420, 144)
	_configure_option(opt)
	for o: Dictionary in options:
		opt.add_item(String(o["label"]), int(o["id"]))
	opt.select(opt.get_item_index(current_id))
	opt.item_selected.connect( func(idx: int) -> void :
		on_pick.call(opt.get_item_id(idx))
		_apply_current_platform()
	)
	return opt



func _configure_option(option: OptionButton) -> void :
	option.custom_minimum_size.y = maxf(option.custom_minimum_size.y, 144)
	option.add_theme_font_size_override("font_size", 44)
	var popup: PopupMenu = option.get_popup()
	popup.add_theme_font_size_override("font_size", 44)
	popup.add_theme_constant_override("v_separation", 104)


func _make_button(text: String, on_pressed: Callable) -> Button:
	var btn: Button = Button.new()
	HapticManager.claim_button_haptic(btn)
	btn.text = text
	btn.add_theme_font_size_override("font_size", _FONT_SIZE)
	btn.custom_minimum_size = Vector2(0, 112)
	btn.pressed.connect(on_pressed)
	return btn


func _make_label(text: String, min_width: float) -> Label:
	var label: Label = Label.new()
	label.text = text.replace("（", "(").replace("）", ")")
	label.custom_minimum_size = Vector2(min_width, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _FONT_SIZE)
	return label



func _make_caption(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text.replace("（", "(").replace("）", ")")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("929eaf"))
	return label



func _clear_children(node: Node) -> void :
	for c: Node in node.get_children():
		node.remove_child(c)
		c.queue_free()





func _load_profile(profile: Dictionary) -> void :
	for p: String in _TYPES:
		var cfg: Dictionary = (profile.get(p, {}) as Dictionary).duplicate(true)
		var type: String = String(cfg.get("type", ""))
		if type.is_empty():

			for draft_type: String in (_cfgs[p] as Dictionary):
				(_cfgs[p] as Dictionary)[draft_type] = _default_cfg(draft_type)
			type = "oneshot" if p == "android" else "transient"
			_cur_type[p] = type
			continue
		if not (_cfgs[p] as Dictionary).has(type):
			continue
		(_cfgs[p] as Dictionary)[type] = _default_cfg(type).merged(cfg, true)
		_cur_type[p] = type
	_refresh_all()





func _build_jigsaw_catalog() -> void :
	var groups: Array[String] = []
	var by_group: Dictionary = {}
	for entry: Dictionary in JigsawHapticCatalog.ENTRIES:
		var g: String = String(entry["group"])
		if not by_group.has(g):
			by_group[g] = []
			groups.append(g)
		(by_group[g] as Array).append(entry)
	for g: String in groups:
		var items: Array = by_group[g]
		var body: VBoxContainer = VBoxContainer.new()
		body.add_theme_constant_override("separation", 14)
		body.visible = false
		body.set_meta("entries", items)
		body.set_meta("building", false)
		var title: String = "%s (%d)" % [g.replace("（", "(").replace("）", ")"), items.size()]
		var head: Button = Button.new()
		HapticManager.claim_button_haptic(head)
		head.text = "▶ " + title
		head.alignment = HORIZONTAL_ALIGNMENT_LEFT
		head.add_theme_font_size_override("font_size", _FONT_SIZE)
		head.custom_minimum_size = Vector2(0, 112)

		head.pressed.connect( func() -> void :
			body.visible = not body.visible
			head.text = ("▼ " if body.visible else "▶ ") + title
			if body.visible:
				_populate_jigsaw_group(body)
		)
		_jigsaw_box.add_child(head)
		_jigsaw_box.add_child(body)



func _populate_jigsaw_group(body: VBoxContainer) -> void :
	if bool(body.get_meta("building", false)):
		return
	var entries: Array = body.get_meta("entries", [])
	body.set_meta("building", true)
	while body.get_child_count() < entries.size():
		if not visible or _collapsed or _active_tab != 1 or not body.visible:
			break
		body.add_child(_build_jigsaw_row(entries[body.get_child_count()]))
		await get_tree().process_frame
		if not is_instance_valid(body) or not is_inside_tree():
			return
	body.set_meta("building", false)



func _build_jigsaw_row(entry: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"HapticSegmentCard"
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	card.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var full_name: String = String(entry["name"]).replace("（", "(").replace("）", ")")
	var label: Label = _make_label(full_name.get_slice("(", 0).strip_edges(), 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_make_button("播放", func() -> void : _play_jigsaw(entry)))
	var load_button: Button = _make_button("载入", func() -> void : _load_jigsaw(entry))
	load_button.theme_type_variation = &"HapticQuietButton"
	load_button.tooltip_text = "将Android和iOS参数应用到当前选中场景，并保存到本机"
	row.add_child(load_button)
	box.add_child(row)
	var thumbnail: HapticThumbnail = thumbnail_scene.instantiate()
	thumbnail.set_profile(JigsawHapticCatalog.profile_of(entry))
	box.add_child(thumbnail)
	var detail: String = _jigsaw_caption(entry)
	if full_name.contains("("):
		detail = full_name.get_slice("(", 1).trim_suffix(")") + "\n" + detail
	box.add_child(_make_caption(detail))
	return card



func _jigsaw_caption(entry: Dictionary) -> String:
	var file: String = String(entry.get("file", ""))
	var android: Dictionary = entry.get("android", {})
	var android_text: String = _describe_android(android)
	if bool(entry.get("android_default", false)):
		android_text += "（Unity 无专属参数，落到旧版等级一）"
	return "场景：%s\niOS：%s ｜ Android：%s ｜ 优先级 %d" % [
		entry["scene"], file if not file.is_empty() else "无 AHAP（单发）", android_text, int(entry["priority"])]



func _describe_android(cfg: Dictionary) -> String:
	match String(cfg.get("type", "")):
		"oneshot":
			return "单发 %dms/%d" % [int(cfg["duration_msec"]), int(cfg["amplitude"])]
		"waveform":
			var segs: PackedStringArray = PackedStringArray()
			var timings: Array = cfg["timings_msec"]
			var amps: Array = cfg["amplitudes"]
			for i: int in timings.size():
				segs.append("%d/%d" % [int(timings[i]), int(amps[i])])
			return "波形 " + " ".join(segs)
	return "无"



func _play_jigsaw(entry: Dictionary) -> void :
	if _running_platform().is_empty():
		_set_status("当前设备不是 Android / iOS，不会震动")
		return
	_native.play(JigsawHapticCatalog.profile_of(entry))
	_set_status("已播放：%s%s" % [entry["name"], _plugin_missing_hint()])



func _load_jigsaw(entry: Dictionary) -> void :
	_commit_input()
	if OS.has_feature("rel") or not HapticProfiles.PROFILES.has(_event):
		_set_status("当前场景不支持载入调试配置")
		return
	var profile: Dictionary = JigsawHapticCatalog.profile_of(entry).duplicate(true)
	for platform: String in [_PLATFORM_ANDROID, _PLATFORM_IOS]:
		var error: String = HapticTuneConfig._validate_effect(profile.get(platform, {}), platform)
		if not error.is_empty():
			_set_status("未载入：" + platform + " / " + error)
			return
	for platform: String in [_PLATFORM_ANDROID, _PLATFORM_IOS]:
		HapticManager.get_tune_config().set_platform(_event, platform, profile[platform])
	_load_event()
	_set_tab(0)
	_set_status("已载入双端参数到：%s · 自动保存到本机" % _scene_label(_event))





func _on_close_pressed() -> void :
	_commit_input()
	_on_sync_cancelled()
	_on_reset_all_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	_preview.stop_playhead()
	hide()



func _on_android_pressed() -> void :
	_commit_input()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_platform = _PLATFORM_ANDROID
	_refresh_all()



func _on_ios_pressed() -> void :
	_commit_input()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_platform = _PLATFORM_IOS
	_refresh_all()




func _on_test_pressed() -> void :
	_commit_input()
	var running: String = _running_platform()
	if running.is_empty() or running != _platform or not HapticManager._has_vibrator_hardware():
		_preview_request = 0
		_preview.start_playhead("演示")
		_set_status("当前设备无法试播，仅演示配置节奏；系统反馈或未知原语时长不显示时间进度")
		return
	var error: String = HapticTuneConfig._validate_effect(_to_native_cfg(_current_cfg(_platform)), _platform)
	if not error.is_empty():
		_set_status("未试播：" + error)
		return
	_native.play({
		_PLATFORM_ANDROID: _to_native_cfg(_current_cfg(_PLATFORM_ANDROID)), 
		_PLATFORM_IOS: _to_native_cfg(_current_cfg(_PLATFORM_IOS)), 
	})
	_preview.start_playhead("试播估算")
	_set_status("已播放：%s%s" % [_describe(_current_cfg(_platform)), _plugin_missing_hint()])


func _on_ios_to_android_pressed() -> void :
	_begin_conversion(_PLATFORM_IOS, _PLATFORM_ANDROID)


func _on_android_to_ios_pressed() -> void :
	_begin_conversion(_PLATFORM_ANDROID, _PLATFORM_IOS)



func _begin_conversion(source: String, target: String) -> void :
	if OS.has_feature("rel") or not _inited:
		return
	if _conversion_task >= 0:
		_set_status("转换配置正在准备，请稍后再试")
		return
	_commit_input()
	_on_sync_cancelled()
	_on_reset_all_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	var profile: Dictionary = HapticManager.get_tune_config().get_profile(_event)
	if (profile.get(source, {}) as Dictionary).is_empty():
		_set_status("来源平台尚未配置，请先编辑或载入配置")
		return
	var snapshot: Dictionary = {"event": _event, "source": source, "target": target, 
		"source_cfg": _to_native_cfg(_current_cfg(source)), "before": profile.get(target, {}).duplicate(true)}
	var generation: int = _conversion_generation
	var job: Dictionary = {}
	_conversion_task = WorkerThreadPool.add_task(HapticConfigConverter.prepare.bind(snapshot.source_cfg.duplicate(true), source, target, job))
	_set_status("正在准备 %s 转 %s..." % [_platform_label(source), _platform_label(target)])
	while not WorkerThreadPool.is_task_completed(_conversion_task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(_conversion_task)
	if not is_inside_tree():
		return
	_conversion_task = -1
	if generation != _conversion_generation:
		return
	if not _conversion_matches(snapshot):
		_set_status("配置已变化，本次转换已取消，请重新转换")
		return
	if not job.result.ok:
		_set_status("未转换：%s；目标端原值保留" % job.result.error)
		return
	snapshot.converted = job.result.cfg
	_pending_conversion = snapshot
	_convert_message.text = "将把「%s」的 %s 配置转换到 %s，并覆盖 %s 端已经修改的值。\n\n转换仅按参数直接换算，实际震动效果双端不会一致，请分别在真机上试播确认。\n\n是否继续？" % [
		_scene_label(_event), _platform_label(source), _platform_label(target), _platform_label(target)]
	_convert_confirm.show()
	_convert_cancel_btn.grab_focus()


func _conversion_matches(snapshot: Dictionary) -> bool:
	return visible and not _collapsed and _active_tab == 0 and _event == int(snapshot.event)\
	and _to_native_cfg(_current_cfg(snapshot.source)) == snapshot.source_cfg\
	and HapticManager.get_tune_config().get_profile(_event).get(snapshot.target, {}) == snapshot.before


static func _platform_label(platform: String) -> String:
	return "Android" if platform == _PLATFORM_ANDROID else "iOS"


func _on_conversion_cancelled() -> void :
	_conversion_generation += 1
	_pending_conversion = {}
	_convert_confirm.hide()


func _on_conversion_confirmed() -> void :
	if not _convert_confirm.visible or _pending_conversion.is_empty() or OS.has_feature("rel"):
		return
	var snapshot: Dictionary = _pending_conversion
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	if not _conversion_matches(snapshot):
		_set_status("配置已变化，本次转换已取消，请重新转换")
		return
	var error: String = HapticManager.get_tune_config().set_platform(snapshot.event, snapshot.target, snapshot.converted)
	if not error.is_empty():
		_set_status("未转换：%s；目标端原值保留" % error)
		return
	_platform = snapshot.target
	_load_event()
	_set_status("已转换当前场景到 %s，目标端已覆盖并自动保存；请双端分别试播" % _platform_label(_platform))


func _exit_tree() -> void :
	_cancel_scroll_touch()
	_pending_effect_apply = {}
	_conversion_generation += 1
	if _conversion_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_conversion_task)




func _on_copy_pressed() -> void :
	_commit_input()
	var source: String = HapticManager.get_tune_config().export_json()
	DisplayServer.clipboard_set(source)
	_json_input.text = source
	_set_status("已复制全部场景配置，可导入另一台调试设备或交给开发应用")


func _on_reset_pressed() -> void :
	_commit_input()
	HapticManager.get_tune_config().reset_event(_event)
	_load_event()
	_set_status("当前场景已恢复包内默认")


func _on_reset_all_pressed() -> void :
	if OS.has_feature("rel"):
		return
	_commit_input()
	_on_sync_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	_reset_confirm.show()
	_reset_cancel_btn.grab_focus()


func _on_reset_all_cancelled() -> void :
	_reset_confirm.hide()


func _on_reset_all_confirmed() -> void :
	if not _reset_confirm.visible or OS.has_feature("rel"):
		return
	_reset_confirm.hide()
	_commit_input()
	HapticManager.get_tune_config().reset_all()
	_load_event()
	_set_status("全部场景已恢复包内默认")


func _on_import_pressed() -> void :
	_commit_input()
	_on_sync_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	var source: String = _json_input.text.strip_edges()
	var error: String = HapticManager.get_tune_config().import_json(source)
	if error.is_empty():
		_load_event()
	_set_status("配置已导入，即时生效并保存到本机" if error.is_empty() else "导入失败：" + error)


func _unhandled_input(event: InputEvent) -> void :
	if _effect_apply_confirm.visible and event.is_action_pressed("ui_cancel"):
		_on_effect_apply_cancelled()
		get_viewport().set_input_as_handled()
		return
	if _sync_confirm.visible and event.is_action_pressed("ui_cancel"):
		_on_sync_cancelled()
		get_viewport().set_input_as_handled()
		return
	if _convert_confirm.visible and event.is_action_pressed("ui_cancel"):
		_on_conversion_cancelled()
		_on_effect_apply_cancelled()
		get_viewport().set_input_as_handled()
		return
	if _reset_confirm.visible and event.is_action_pressed("ui_cancel"):
		_on_reset_all_cancelled()
		get_viewport().set_input_as_handled()



func _on_sync_pressed() -> void :
	_commit_input()
	if not _sync_connection_ready():
		return
	_on_reset_all_cancelled()
	_on_conversion_cancelled()
	_on_effect_apply_cancelled()
	_close_selection_popups()
	_sync_confirm_message.text = "将保存全部场景的 Android 和 iOS 当前配置，并发送一条飞书通知。" if _pending_upload_id.is_empty() else "将查询上次同步结果，不重复上传配置或发送通知。"
	_sync_confirm.show()
	_sync_cancel_btn.grab_focus()


func _on_sync_cancelled() -> void :
	_sync_confirm.hide()


func _on_sync_confirmed() -> void :
	if not _sync_confirm.visible or _sending or OS.has_feature("rel"):
		return
	_sync_confirm.hide()
	if not _sync_connection_ready():
		return
	_perform_sync()


func _sync_connection_ready() -> bool:
	if _sending or OS.has_feature("rel"):
		return false
	if not _connection_loaded:
		_set_status("连接设置正在读取，请稍后再同步")
		return false
	var address: String = _upload_address.text.strip_edges().trim_suffix("/")
	var token: String = _upload_token.text.strip_edges()
	if not (address.begins_with("http://") or address.begins_with("https://")) or token.is_empty():
		_config_expanded = true
		_effects_expanded = false
		_apply_section_visibility()
		$Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / ConnectionBox.show()
		$Bg / CenterPanel / Margin / VBox / ConfigCard / Body / Scroll / Content / SyncActions / ConnectionToggle.text = "收起连接设置"
		_set_status("请先在连接设置中填写中转地址和上传凭证")
		return false
	return true



func _perform_sync() -> void :
	if not _sync_connection_ready():
		return
	var address: String = _upload_address.text.strip_edges().trim_suffix("/")
	var token: String = _upload_token.text.strip_edges()
	_commit_input()
	_sending = true
	_send_btn.disabled = true
	var labels: Dictionary = {}
	for event: int in HapticProfiles.PROFILES:
		labels[HapticProfiles.Event.keys()[event]] = _scene_label(event)
	var metadata: Dictionary = {
		"version": String(ProjectSettings.get_setting("application/config/version", "")), 
		"build": str(ProjectSettings.get_setting("application/config/version_code", 0)), 
		"mode": "rel" if OS.has_feature("rel") else ("debug" if OS.is_debug_build() else "preRelease"), 
		"platform": OS.get_name(), "device": OS.get_model_name(), "labels": labels, 
	}
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json; charset=utf-8", "Authorization: Bearer " + token])
	var result: Dictionary = {}
	var error: Error
	var querying: bool = not _pending_upload_id.is_empty()
	if _pending_upload_id.is_empty():
		var job: Dictionary = {}
		var snapshot: Dictionary = HapticManager.get_tune_config().export_upload_snapshot()
		var task: int = WorkerThreadPool.add_task(_prepare_upload.bind(snapshot, metadata, address, token, job))
		while not WorkerThreadPool.is_task_completed(task):
			await get_tree().process_frame
		WorkerThreadPool.wait_for_task_completion(task)
		_pending_upload_id = String(job.request_id)
		error = _request.request(address + "/api/uploads", headers, HTTPClient.METHOD_POST, job.body)
	else:

		error = _request.request(address + "/api/uploads/" + _pending_upload_id, headers)
	if error != OK:
		_set_status("同步请求未发出：" + error_string(error) + " · " + _pending_upload_id)
		if not querying:
			_pending_upload_id = ""
	else:
		var response: Array = await _request.request_completed
		result = _upload_response(response)
		if not result.get("ok", false):
			_set_status("同步未确认：" + String(result.get("error", "")) + " · 原请求 " + _pending_upload_id)
			if response[1] == 404:
				_pending_upload_id = ""
				_set_status("原请求未找到；请核对中转，再次点击将同步新的快照")
		else:
			var request_id: String = String(result.request_id)
			for attempt: int in 121:
				var state: String = String(result.get("notification_status", ""))
				if state == "sent":
					_set_status("配置表已更新，测试飞书已确认 · " + String(result.get("url", "")))
					_pending_upload_id = ""
					break
				if state in ["failed", "unknown"]:
					var stored: String = "配置表已保存；" if result.get("sheet_status", "") == "written" else "配置表未完整确认；"
					_set_status(stored + String(result.get("error", "")) + " · " + String(result.get("url", "")))
					_pending_upload_id = ""
					break
				if attempt == 120:
					_set_status("通知结果未确认，请查看原记录：" + String(result.get("url", request_id)))
					break
				_set_status("配置同步处理中 · " + String(result.get("url", "")))
				await get_tree().create_timer(1.0).timeout
				error = _request.request(address + "/api/uploads/" + request_id, headers)
				if error != OK:
					_set_status("发送失败：" + error_string(error) + " · " + request_id)
					break
				response = await _request.request_completed
				result = _upload_response(response)
				if not result.get("ok", false):
					_set_status("发送失败：" + String(result.get("error", "")) + " · " + request_id)
					break
	var connection: ConfigFile = ConfigFile.new()
	if connection.load(_UPLOAD_CONNECTION_PATH) == OK:
		connection.set_value("upload", "pending_id", _pending_upload_id)
		connection.save(_UPLOAD_CONNECTION_PATH)
	_sending = false
	_send_btn.disabled = false


static func _upload_response(response: Array) -> Dictionary:
	var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if response[0] != HTTPRequest.RESULT_SUCCESS or not parsed is Dictionary:
		return {"ok": false, "error": "网络结果%s / HTTP%s" % [response[0], response[1]]}
	if response[1] < 200 or response[1] >= 300:
		return {"ok": false, "error": String(parsed.get("error", "HTTP" + str(response[1])))}
	if not parsed.get("ok", false) or not parsed.get("request_id") is String:
		return {"ok": false, "error": String(parsed.get("error", "HTTP" + str(response[1])))}
	return parsed


static func _prepare_upload(snapshot: Dictionary, metadata: Dictionary, address: String, token: String, job: Dictionary) -> void :
	var request_id: String = Crypto.new().generate_random_bytes(16).hex_encode()
	job.request_id = request_id
	job.body = JSON.stringify({"format": "pocketsort_haptic_upload_v1", "request_id": request_id, 
		"config": snapshot.config, "baseline": snapshot.baseline, "metadata": metadata})
	var connection: ConfigFile = ConfigFile.new()
	connection.set_value("upload", "address", address)
	connection.set_value("upload", "token", token)
	connection.set_value("upload", "pending_id", request_id)
	connection.save(_UPLOAD_CONNECTION_PATH)


func _set_status(text: String) -> void :
	_status_label.text = text.replace("（", "(").replace("）", ")")



func _plugin_missing_hint() -> String:
	return "" if Engine.has_singleton("VibratePlugin") else "（原生插件未加载，已降级为 Input.vibrate_handheld）"



func _literal(v: Variant) -> String:
	match typeof(v):
		TYPE_STRING:
			var s: String = v
			if s.begins_with(_AHAP_DIR):
				return "_AHAP_DIR + \"%s\"" % s.trim_prefix(_AHAP_DIR)
			return "\"%s\"" % s
		TYPE_FLOAT:

			var f: String = "%.3f" % float(v)
			while f.ends_with("0") and not f.ends_with(".0"):
				f = f.left(-1)
			return f
		TYPE_ARRAY:
			var items: PackedStringArray = PackedStringArray()
			for item: Variant in v:
				items.append(_literal(item))
			return "[%s]" % ", ".join(items)
		TYPE_DICTIONARY:
			var d: Dictionary = v
			var pairs: PackedStringArray = PackedStringArray()
			for k: Variant in d:
				pairs.append("\"%s\": %s" % [str(k), _literal(d[k])])
			return "{%s}" % ", ".join(pairs)
	return str(v)



func _scene_label(event: int) -> String:
	for style: int in [1, 2]:
		var events: Array[int] = HapticProfiles._SHAKE_FIRST_EVENTS if style == 1 else HapticProfiles._SHAKE_SECOND_EVENTS
		var index: int = events.find(event)
		if index >= 0:
			var base: int = HapticProfiles._SHAKE_BASE_EVENTS[index]
			var label: String = "拖到可放置列" if base == HapticProfiles.Event.MOVE_OK else _scene_label(base)
			return "%s / style%d_v2" % [label, style]
	match event:
		HapticProfiles.Event.GAME_ENTER:
			return "游戏入场"
		HapticProfiles.Event.FLOWER_MERGE:
			return "同色合并"
		HapticProfiles.Event.IQ_SCORE_POP:
			return "评分卡弹出"
	return _SCENE_LABELS[event] if event < _SCENE_LABELS.size() else HapticProfiles.Event.keys()[event]



func _build_selection_selectors() -> void :
	_category_selector.clear()
	for group: Dictionary in _SCENE_GROUPS:
		_category_selector.add_item(String(group.label))
	for selector: OptionButton in [_category_selector, _scene_selector, _style_selector]:
		var popup: PopupMenu = selector.get_popup()
		popup.add_theme_font_size_override("font_size", 40)
		popup.add_theme_constant_override("v_separation", 68)
		_connect_selector_toggle(selector)
		selector.add_theme_color_override("font_color", _COLOR_SELECTED)
	_category_selector.tooltip_text = "仅选择编辑对象，不改变AB分组"


func _base_scene_event(event: int) -> int:
	for events: Array[int] in [HapticProfiles._SHAKE_FIRST_EVENTS, HapticProfiles._SHAKE_SECOND_EVENTS]:
		var index: int = events.find(event)
		if index >= 0:
			return HapticProfiles._SHAKE_BASE_EVENTS[index]
	return event


func _scene_configured(event: int) -> bool:
	var profile: Dictionary = HapticManager.get_tune_config().get_profile(event)
	return not (profile.get("android", {}) as Dictionary).is_empty() or not (profile.get("ios", {}) as Dictionary).is_empty()


func _editable_scene_event(event: int) -> int:
	return HapticProfiles.shake_event_for(event, 1) if event in _STYLE_ONLY_EVENTS else event


func _refresh_scene_selection() -> void :
	var base: int = _base_scene_event(_event)
	_selected_scene_style = 1 if _event in HapticProfiles._SHAKE_FIRST_EVENTS else (2 if _event in HapticProfiles._SHAKE_SECOND_EVENTS else 0)
	for index: int in _SCENE_GROUPS.size():
		if base in _SCENE_GROUPS[index].events:
			_selected_category = index
			break
	_category_last_events[_selected_category] = _event
	_category_selector.select(_selected_category)
	var group: Dictionary = _SCENE_GROUPS[_selected_category]
	_scene_selector.clear()
	for index: int in group.events.size():
		var scene: int = group.events[index]
		var scene_event: int = _editable_scene_event(HapticProfiles.shake_event_for(scene, _selected_scene_style))
		var title: String = _scene_label(scene)
		if scene == HapticProfiles.Event.MOVE_OK and _selected_scene_style > 0:
			title = "拖到可放置列"
		if _selected_category == 2:
			title = title.trim_prefix("Combo ")
		_scene_selector.add_item(_scene_choice_text(title, scene_event), scene_event)
		if base == scene:
			_scene_selector.select(index)
	_scene_selector.tooltip_text = _scene_label(_event) + " / " + HapticProfiles.Event.keys()[_event] + "\n仅选择编辑对象，不改变AB分组"
	_style_row.visible = base in HapticProfiles._SHAKE_BASE_EVENTS
	_style_selector.clear()
	for style: int in 3:
		if style == 0 and base in _STYLE_ONLY_EVENTS:
			continue
		var event: int = HapticProfiles.shake_event_for(base, style)
		var title: String = ["原版", "样式1", "样式2"][style]
		_style_selector.add_item(_scene_choice_text(title, event), style)
	_style_selector.select(_style_selector.get_item_index(_selected_scene_style))
	_style_selector.tooltip_text = _scene_label(_event) + " / " + HapticProfiles.Event.keys()[_event] + "\n未配置样式仍可选择编辑"


func _scene_choice_text(title: String, event: int) -> String:
	return title + " · " + ("已配" if _scene_configured(event) else "未配")


func _on_scene_category_selected(category: int) -> void :
	var event: int = int(_category_last_events.get(category, _SCENE_GROUPS[category].events[0]))
	_on_scene_event_selected(event)


func _on_scene_selected(index: int) -> void :
	if index >= 0 and index < _scene_selector.item_count:
		_on_scene_event_selected(_scene_selector.get_item_id(index))


func _on_scene_style_selected(index: int) -> void :
	if index >= 0 and index < _style_selector.item_count:
		_on_scene_event_selected(HapticProfiles.shake_event_for(_base_scene_event(_event), _style_selector.get_item_id(index)))


func _close_selection_popups() -> void :
	for selector: OptionButton in [_category_selector, _scene_selector, _style_selector]:
		selector.get_popup().hide()



func _connect_selector_toggle(selector: OptionButton) -> void :
	var popup: PopupMenu = selector.get_popup()
	var dismissed: Dictionary = {"frame": -1}
	var pointer: Dictionary = {"armed": false, "inside_menu": false}
	var tree: SceneTree = get_tree()
	var watch_pointer: Callable = func() -> void :
		if not popup.visible:
			return
		if not selector.is_visible_in_tree():
			popup.hide()
			return
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			pointer.armed = true
			pointer.inside_menu = false
		elif pointer.armed and not pointer.inside_menu:
			var local_pointer: Vector2 = selector.get_screen_transform().affine_inverse() * Vector2(DisplayServer.mouse_get_position())
			if Rect2(Vector2.ZERO, selector.size).has_point(local_pointer):
				dismissed.frame = Engine.get_process_frames()
				popup.hide()
	var stop_watch: Callable = func() -> void :
		if tree.process_frame.is_connected(watch_pointer):
			tree.process_frame.disconnect(watch_pointer)
	popup.about_to_popup.connect( func() -> void :
		for other: OptionButton in [_category_selector, _scene_selector, _style_selector]:
			if other != selector:
				other.get_popup().hide()
		pointer.armed = not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		pointer.inside_menu = false
		if not tree.process_frame.is_connected(watch_pointer):
			tree.process_frame.connect(watch_pointer))
	popup.window_input.connect( func(event: InputEvent) -> void :
		if event is InputEventMouseButton and event.pressed and popup.get_visible_rect().has_point(event.position):
			pointer.inside_menu = true
		elif event is InputEventScreenTouch and event.pressed and popup.get_visible_rect().has_point(event.position):
			pointer.inside_menu = true)
	popup.tree_exiting.connect(stop_watch)
	popup.popup_hide.connect( func() -> void :
		if selector.get_global_rect().has_point(selector.get_global_mouse_position()):
			dismissed.frame = Engine.get_process_frames()
		stop_watch.call())
	selector.gui_input.connect( func(event: InputEvent) -> void :
		var pressed: bool = false
		if event is InputEventMouseButton:
			if event.button_index != MOUSE_BUTTON_LEFT:
				return
			pressed = event.pressed
		elif event is InputEventScreenTouch:
			pressed = event.pressed
		else:
			return
		if dismissed.frame == Engine.get_process_frames():
			selector.accept_event()
		elif pressed and popup.visible:
			dismissed.frame = Engine.get_process_frames()
			popup.hide()
			selector.accept_event())
