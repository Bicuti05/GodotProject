class_name ScrollDragHelper
extends Node


const _DRAG_THRESHOLD: float = 12.0

const _FLING_DECAY_PER_SEC: float = 0.05
const _FLING_MIN_SPEED: float = 20.0
const _FLING_MAX_SPEED: float = 6000.0
const _VELOCITY_SMOOTH: float = 0.5

var _scroll: ScrollContainer
var _is_pressing: bool = false
var _drag_active: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _last_pos: Vector2 = Vector2.ZERO
var _active_pointer_index: int = -1
var _velocity: Vector2 = Vector2.ZERO
var _fling: Vector2 = Vector2.ZERO
var _fling_accum: Vector2 = Vector2.ZERO
var _last_motion_msec: int = 0
var _press_stopped_fling: bool = false

static func attach(scroll: ScrollContainer) -> ScrollDragHelper:
	if scroll == null:
		SortLogger.error("ScrollDragHelper.attach: scroll is null")
		return null
	for child in scroll.get_children():
		if child is ScrollDragHelper:
			return child as ScrollDragHelper
	var helper: = ScrollDragHelper.new()
	helper.name = "_ScrollDragHelper"
	helper._scroll = scroll
	scroll.add_child(helper)
	return helper


func _ready() -> void :
	set_process(false)

func _input(event: InputEvent) -> void :
	if _scroll == null or not _scroll.is_visible_in_tree() or not _host_is_topmost():
		_reset()
		return

	if event is InputEventScreenTouch:
		_handle_press(event.position, event.pressed, event.index)
	elif event is InputEventScreenDrag:
		if _active_pointer_index == event.index:
			_handle_motion(event.position)
	elif event is InputEventMouseButton:
		var mb: = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_press(mb.position, mb.pressed, -2)
	elif event is InputEventMouseMotion:
		if _active_pointer_index != -2:
			return
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_reset()
		elif _is_pressing:
			_handle_motion(event.position)

func _handle_press(pos: Vector2, pressed: bool, pointer_index: int) -> void :
	if pressed:
		var rect: Rect2 = _scroll.get_global_rect()
		if not rect.has_point(pos):
			return
		_press_stopped_fling = _fling != Vector2.ZERO
		_stop_fling()
		_is_pressing = true
		_drag_active = false
		_press_pos = pos
		_last_pos = pos
		_active_pointer_index = pointer_index
		_velocity = Vector2.ZERO
		_last_motion_msec = Time.get_ticks_msec()
	else:
		if _active_pointer_index != pointer_index:
			return
		var was_dragging: bool = _drag_active
		var stopped_fling: bool = _press_stopped_fling
		if was_dragging:
			_start_fling()
		_reset()
		if was_dragging or stopped_fling:
			get_viewport().set_input_as_handled()

func _handle_motion(pos: Vector2) -> void :
	if not _is_pressing:
		return
	var delta: Vector2 = pos - _last_pos
	if not _drag_active:
		if (pos - _press_pos).length() > _DRAG_THRESHOLD:
			_drag_active = true
			_cancel_pressed_buttons(_scroll)
	if _drag_active:
		if _v_enabled():
			_scroll.scroll_vertical = int(_scroll.scroll_vertical - delta.y)
		if _h_enabled():
			_scroll.scroll_horizontal = int(_scroll.scroll_horizontal - delta.x)
		var dt: float = float(Time.get_ticks_msec() - _last_motion_msec) / 1000.0
		if dt > 0.0005 and dt < 0.1:
			_velocity = _velocity.lerp( - delta / dt, _VELOCITY_SMOOTH)
		get_viewport().set_input_as_handled()
	_last_motion_msec = Time.get_ticks_msec()
	_last_pos = pos


func _start_fling() -> void :
	_fling = _velocity.limit_length(_FLING_MAX_SPEED)
	if not _v_enabled():
		_fling.y = 0.0
	if not _h_enabled():
		_fling.x = 0.0
	if _fling.length() < _FLING_MIN_SPEED:
		_stop_fling()
		return
	_fling_accum = Vector2.ZERO
	set_process(true)

func _stop_fling() -> void :
	_fling = Vector2.ZERO
	_fling_accum = Vector2.ZERO
	set_process(false)

func _process(delta: float) -> void :
	if _scroll == null or not _scroll.is_visible_in_tree() or _fling == Vector2.ZERO:
		_stop_fling()
		return
	_fling_accum += _fling * delta
	var step: = Vector2(float(int(_fling_accum.x)), float(int(_fling_accum.y)))
	_fling_accum -= step
	if step.y != 0.0:
		var before_y: int = _scroll.scroll_vertical
		_scroll.scroll_vertical = before_y + int(step.y)
		if _scroll.scroll_vertical == before_y:
			_fling.y = 0.0
	if step.x != 0.0:
		var before_x: int = _scroll.scroll_horizontal
		_scroll.scroll_horizontal = before_x + int(step.x)
		if _scroll.scroll_horizontal == before_x:
			_fling.x = 0.0
	_fling *= pow(_FLING_DECAY_PER_SEC, delta)
	if _fling.length() < _FLING_MIN_SPEED:
		_stop_fling()

func _v_enabled() -> bool:
	return _scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED

func _h_enabled() -> bool:
	return _scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED

func _reset() -> void :
	_is_pressing = false
	_drag_active = false
	_active_pointer_index = -1
	_press_stopped_fling = false
	_velocity = Vector2.ZERO

func _cancel_pressed_buttons(node: Node) -> void :
	if node is BaseButton:
		var btn: = node as BaseButton
		if btn.button_pressed and not btn.toggle_mode:
			btn.button_pressed = false
	for child in node.get_children():
		_cancel_pressed_buttons(child)

func _host_is_topmost() -> bool:
	var node: Node = _scroll
	while node != null:
		if node is PageScene:
			return SceneManager.is_topmost(node)
		node = node.get_parent()
	return false
