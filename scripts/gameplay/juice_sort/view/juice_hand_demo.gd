class_name JuiceHandDemo
extends Node2D














































const DEMO_TRAVEL: = 1.25
const DEMO_GAP: = 0.45





const HAND_OFFSET: = Vector2(56.0, 16.0)

const HAND_ANIM_INTO: = "guide_hand01_into"
const HAND_ANIM_LOOP: = "guide_hand01_loop"
const HAND_ANIM_OUT: = "guide_hand01_out"

enum Phase{PRESS, TRAVEL, VANISH, GAP}

@onready var _hand: Node2D = $Hand


var _demo: Dictionary = {}

var _phase: int = -1

var _press_dur: float = 0.533
var _vanish_dur: float = 0.5


func _ready() -> void :
	_resolve_hand_durations()
	stop()




func _resolve_hand_durations() -> void :
	var data: Variant = _hand.get("skeleton_data_res")
	if data == null:
		return
	for a: Variant in (data as Object).call("get_animations"):
		var obj: Object = a as Object
		if obj == null:
			continue
		var nm: String = str(obj.call("get_name"))
		var du: float = float(obj.call("get_duration"))
		if nm == HAND_ANIM_INTO:
			_press_dur = du
		elif nm == HAND_ANIM_OUT:
			_vanish_dur = du












func play(from: Vector2, to: Vector2) -> void :
	stop()
	_demo = {"from": from, "to": to, "t": 0.0, "head": from}
	_phase = -1
	set_process(true)


func stop() -> void :
	_demo = {}
	_phase = -1
	set_process(false)
	_hand.visible = false
	_clear_hand_tracks()


func is_playing() -> bool:
	return not _demo.is_empty()



func is_hand_visible() -> bool:
	return is_instance_valid(_hand) and _hand.is_visible_in_tree()



func head() -> Vector2:
	if _demo.is_empty():
		return Vector2.INF
	return _demo["head"] as Vector2




func _process(delta: float) -> void :
	if _demo.is_empty():
		set_process(false)
		return
	_advance(delta)



func _cycle() -> float:
	return _press_dur + DEMO_TRAVEL + _vanish_dur + DEMO_GAP


func _advance(delta: float) -> void :
	var t: float = float(_demo["t"]) + delta
	if t >= _cycle():

		t = fmod(t, _cycle())
		_phase = -1
	_demo["t"] = t

	var from: Vector2 = _demo["from"]
	var to: Vector2 = _demo["to"]
	var head_pos: Vector2 = from
	var phase: int = Phase.PRESS
	if t < _press_dur:
		phase = Phase.PRESS
		head_pos = from
	elif t < _press_dur + DEMO_TRAVEL:
		phase = Phase.TRAVEL
		var u: float = (t - _press_dur) / DEMO_TRAVEL
		var eased: float = 2.0 * u * u if u < 0.5 else 1.0 - pow(-2.0 * u + 2.0, 2.0) * 0.5
		head_pos = from.lerp(to, eased)
	elif t < _press_dur + DEMO_TRAVEL + _vanish_dur:
		phase = Phase.VANISH
		head_pos = to
	else:
		phase = Phase.GAP
		head_pos = to

	_demo["head"] = head_pos
	if head_pos != Vector2.INF:
		_hand.position = head_pos + HAND_OFFSET
	if phase != _phase:
		_phase = phase
		_enter_phase(phase)



func _enter_phase(phase: int) -> void :
	match phase:
		Phase.PRESS:
			_hand.visible = true
			_play_hand(HAND_ANIM_INTO, false)
		Phase.TRAVEL:
			_hand.visible = true
			_play_hand(HAND_ANIM_LOOP, true)
		Phase.VANISH:
			_hand.visible = true
			_play_hand(HAND_ANIM_OUT, false)
		Phase.GAP:

			_hand.visible = false
			_clear_hand_tracks()



func _play_hand(anim: String, loop: bool) -> void :
	var st: Object = _hand.call("get_animation_state")
	if st != null:
		st.call("set_animation", anim, loop, 0)


func _clear_hand_tracks() -> void :
	var st: Object = _hand.call("get_animation_state")
	if st != null:
		st.call("clear_tracks")
