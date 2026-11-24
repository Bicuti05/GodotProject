class_name GamePropUnlockOverlay
extends DialogScene


















signal closed(used_prop: bool)



const TITLE_FILL_TOP: = Color(1.0, 0.729, 0.11)
const TITLE_FILL_BOTTOM: = Color(0.929, 0.518, 0.133)


const TITLE_LAYER_OFFSET_Y: = 4.0



const TITLE_BASELINE_Y: = 586.6

const TITLE_RECT_H: = 268.0

const TITLE_RECT_W: = 824.0

const TITLE_AMPLITUDE: = 8.0


const MAIN_CENTER_Y: = 1103.6

const ICON_BOX: = 640.0




const DESC_TOP_Y: = 1564.6
const DESC_W: = 824.0
const DESC_H: = 72.0








const HAND_OFFSET: = Vector2(132.0, 98.0)
const HAND_ANIMATION: = &"guide_hand01_animation"


const STARS_CENTER_DESIGN_X: = 459.5
const STARS_CENTER_Y: = 1062.1
const STARS_EXTENTS: = Vector2(328.5, 259.5)


const FADE_IN_TIME: = 0.25
const FADE_OUT_TIME: = 0.18

const RAYS_SPIN_TIME: = 16.0

const CORE_BREATH_SCALE: = 1.06
const CORE_BREATH_TIME: = 1.1
@export var hint_icon: Texture2D
@export var undo_icon: Texture2D
@export var rope_icon: Texture2D
@export var fill_pot_icon: Texture2D

@onready var _content: Control = $Content
@onready var _rays: TextureRect = $Content / GlowRays
@onready var _core: TextureRect = $Content / GlowCore
@onready var _icon: TextureRect = $Content / Icon
@onready var _stars: CPUParticles2D = $Content / Stars
@onready var _title_top: CurveLabel = $Content / TitleTop
@onready var _title_bottom: CurveLabel = $Content / TitleBottom
@onready var _desc: Label = $Content / Desc
@onready var _hand: Node2D = $Content / Hand


var _btn: PropBtn = null
var _btn_parent: Node = null
var _btn_index: int = -1
var _btn_z_index: int = 0

var _show_hand: bool = false

var _interactive: bool = false
var _used_prop: bool = false
var _tweens: Array[Tween] = []


func _ready() -> void :
	visible = false
	_content.modulate.a = 0.0
	_title_top.add_theme_color_override(&"font_color", TITLE_FILL_TOP)
	_title_bottom.add_theme_color_override(&"font_color", TITLE_FILL_BOTTOM)



func _visual_of(prop_key: String) -> Dictionary:
	match prop_key:
		"hint":
			return {"title": "JUICE_UNLOCK_HINT_TITLE", "desc": "JUICE_UNLOCK_HINT_DESC", 
				"icon": hint_icon}
		"undo":
			return {"title": "JUICE_UNLOCK_UNDO_TITLE", "desc": "JUICE_UNLOCK_UNDO_DESC", 
				"icon": undo_icon}
		"rope":
			return {"title": "JUICE_UNLOCK_ROPE_TITLE", "desc": "JUICE_UNLOCK_ROPE_DESC", 
				"icon": rope_icon}
		"fill_pot":
			return {"title": "JUICE_UNLOCK_FILL_POT_TITLE", 
				"desc": "JUICE_UNLOCK_FILL_POT_DESC", "icon": fill_pot_icon}
	return {}


func is_open() -> bool:
	return visible



func _on_show(params: Dictionary = {}) -> void :
	await super._on_show(params)
	var start_context = params.get("start_context")
	if start_context != null and start_context.aborted:
		return
	if not visible:
		return
	if _bg != null and not _bg.gui_input.is_connected(_on_bg_gui_input):
		_bg.gui_input.connect(_on_bg_gui_input)
	var prop_key: String = String(params.get("prop_key", ""))
	var btn: PropBtn = params.get("button", null) as PropBtn
	var vis: Dictionary = _visual_of(prop_key)
	if vis.is_empty() or btn == null or not is_instance_valid(btn):
		SortLogger.error("GamePropUnlockOverlay: 未知道具位 '%s'" % prop_key)
		close(false, true)
		return
	_attach_btn(btn)

	_show_hand = prop_key == "hint" or prop_key == "fill_pot"
	_used_prop = false
	_interactive = false
	_title_top.text = vis["title"] as String
	_title_bottom.text = vis["title"] as String
	_desc.text = vis["desc"] as String
	_icon.texture = vis["icon"] as Texture2D
	_layout()
	_content.modulate.a = 0.0
	_btn.modulate.a = 0.0
	_stars.restart()
	_stars.emitting = true
	var tw: = _new_tween()
	tw.tween_property(_content, "modulate:a", 1.0, FADE_IN_TIME)
	tw.parallel().tween_property(_btn, "modulate:a", 1.0, FADE_IN_TIME)
	tw.tween_callback( func() -> void : _interactive = true)
	_play_ambient()







func close(used_prop: bool = false, immediate: bool = false) -> void :
	if not visible:
		return
	_interactive = false
	_used_prop = used_prop
	_kill_tweens()
	_stars.emitting = false
	if immediate:
		if _bg_tween != null and _bg_tween.is_valid():
			_bg_tween.kill()
		if _bg != null:
			_bg.visible = false
		_content.modulate.a = 0.0
		_restore_btn()
		visible = false
		_show_hand = false
		closed.emit(_used_prop)
		return
	_hide_bg()
	var tw: = _new_tween()
	tw.tween_property(_content, "modulate:a", 0.0, FADE_OUT_TIME)
	if _btn != null and is_instance_valid(_btn):
		tw.parallel().tween_property(_btn, "modulate:a", 0.0, FADE_OUT_TIME)
	tw.tween_callback( func() -> void :
		_restore_btn()
		visible = false
		_show_hand = false
		closed.emit(_used_prop))



func _on_hide() -> void :
	close(false, true)


func _attach_btn(btn: PropBtn) -> void :
	_btn = btn
	_btn_parent = btn.get_parent()
	_btn_index = btn.get_index()
	_btn_z_index = btn.z_index
	SceneManager.set_button_feedback_enabled(btn, false)
	btn.reparent(self, true)
	btn.z_index = 1
	btn.play_unlock_highlight()


func _restore_btn() -> void :
	var btn: PropBtn = _btn
	_btn = null
	if btn == null or not is_instance_valid(btn):
		_btn_parent = null
		_btn_index = -1
		return
	btn.modulate.a = 1.0
	btn.stop_unlock_highlight()
	btn.z_index = _btn_z_index
	if _btn_parent != null and is_instance_valid(_btn_parent):
		btn.reparent(_btn_parent, true)
		if _btn_index >= 0:
			_btn_parent.move_child(btn, mini(_btn_index, _btn_parent.get_child_count() - 1))
	SceneManager.set_button_feedback_enabled(btn, true)
	_btn_parent = null
	_btn_index = -1



func _layout() -> void :
	var vp: Vector2 = UiMetrics.viewport_size()
	var cx: float = vp.x * 0.5

	_rays.size = _rays.texture.get_size() if _rays.texture != null else Vector2.ZERO
	_rays.position = Vector2(cx, MAIN_CENTER_Y) - _rays.size * 0.5
	_rays.pivot_offset = _rays.size * 0.5

	_core.size = _core.texture.get_size() if _core.texture != null else Vector2.ZERO
	_core.position = Vector2(cx, MAIN_CENTER_Y) - _core.size * 0.5
	_core.pivot_offset = _core.size * 0.5


	_icon.size = _icon.texture.get_size() if _icon.texture != null else Vector2(ICON_BOX, ICON_BOX)
	_icon.position = Vector2(cx, MAIN_CENTER_Y) - _icon.size * 0.5
	_icon.pivot_offset = _icon.size * 0.5
	_icon.scale = Vector2.ONE * ICON_BOX / maxf(_icon.size.x, _icon.size.y)

	_stars.position = Vector2(cx + (STARS_CENTER_DESIGN_X - 540.0), STARS_CENTER_Y)
	_stars.emission_rect_extents = STARS_EXTENTS


	var title_y: float = TITLE_BASELINE_Y + TITLE_AMPLITUDE - TITLE_RECT_H * 0.5
	var title_x: float = UiMetrics.center_left(TITLE_RECT_W)
	_title_top.position = Vector2(title_x, title_y)
	_title_top.size = Vector2(TITLE_RECT_W, TITLE_RECT_H)
	_title_bottom.position = Vector2(title_x, title_y + TITLE_LAYER_OFFSET_Y)
	_title_bottom.size = Vector2(TITLE_RECT_W, TITLE_RECT_H)

	_desc.position = Vector2(UiMetrics.center_left(DESC_W), DESC_TOP_Y)
	_desc.size = Vector2(DESC_W, DESC_H)

	if _show_hand and _btn != null and is_instance_valid(_btn):
		_hand.visible = true

		_hand.position = _btn.position + HAND_OFFSET
	else:
		_hand.visible = false



func _play_ambient() -> void :
	var spin: = _new_tween().set_loops()
	spin.tween_property(_rays, "rotation", TAU, RAYS_SPIN_TIME).from(0.0)

	var breath: = _new_tween().set_loops()
	breath.tween_property(_core, "scale", Vector2.ONE * CORE_BREATH_SCALE, 
		CORE_BREATH_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath.tween_property(_core, "scale", Vector2.ONE, 
		CORE_BREATH_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _hand.visible:
		var animation_state: Object = _hand.call("get_animation_state")
		if animation_state != null:
			animation_state.call("set_animation", HAND_ANIMATION, true, 0)


func _new_tween() -> Tween:
	var tw: = create_tween()
	_tweens.append(tw)
	return tw


func _kill_tweens() -> void :
	for tw: Tween in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()
	var animation_state: Object = _hand.call("get_animation_state")
	if animation_state != null:
		animation_state.call("clear_tracks")



func _on_bg_gui_input(event: InputEvent) -> void :
	if not _interactive:
		return
	var released: bool = (event is InputEventMouseButton
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
		and not (event as InputEventMouseButton).pressed)
	if released or (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed):
		_bg.accept_event()
		close(false)
