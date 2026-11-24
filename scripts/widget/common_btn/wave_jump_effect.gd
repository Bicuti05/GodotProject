class_name WaveJumpEffect
extends RichTextEffect










var bbcode: String = "wave_jump"


const DURATION: float = 0.8

const START_INTERVAL: float = 0.05

const HEIGHT: float = 30.0

const MAIN_RATIO: float = 0.5

const TAIL_COUNT: int = 2

const TAIL_DECAY: float = 0.1

const UNDERSHOOT_RATIO: float = 0.3

const UPWARD_END: float = 0.58

const LOOP_INTERVAL: float = 1.0


var _visible_index: PackedInt32Array = PackedInt32Array()
var _visible_count: int = 0

var _start_msec: int = -1
var _source_text: String = ""



func set_source_text(text: String) -> bool:
	if text == _source_text:
		return false
	_source_text = text
	_visible_index = PackedInt32Array()
	_visible_count = 0
	for i: int in text.length():
		var ch: String = text.substr(i, 1)
		if ch.strip_edges().is_empty():
			_visible_index.append(-1)
		else:
			_visible_index.append(_visible_count)
			_visible_count += 1
	return true



func restart() -> void :
	_start_msec = Time.get_ticks_msec()


func _process_custom_fx(char_fx: CharFXTransform) -> bool:

	if _start_msec < 0:
		return true
	var idx: int = char_fx.relative_index
	if idx < 0 or idx >= _visible_index.size():
		return true
	var visible_order: int = _visible_index[idx]
	if visible_order < 0 or _visible_count <= 0:
		return true
	var cycle: float = cycle_duration(_visible_count)
	var time_in_cycle: float = fposmod(float(Time.get_ticks_msec() - _start_msec) / 1000.0, cycle)
	var t: float = (time_in_cycle - float(visible_order) * START_INTERVAL) / DURATION
	if t <= 0.0:
		return true

	char_fx.offset.y = - wave_jump_y(clampf(t, 0.0, 1.0))
	return true



static func cycle_duration(visible_count: int) -> float:
	return float(maxi(visible_count - 1, 0)) * START_INTERVAL + DURATION + LOOP_INTERVAL



static func wave_jump_y(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	if TAIL_COUNT == 0:
		return _oscillation(t, HEIGHT)
	if t <= MAIN_RATIO:
		return _oscillation(t / MAIN_RATIO, HEIGHT)
	var tail_progress: float = (t - MAIN_RATIO) / (1.0 - MAIN_RATIO)
	var tail_pos: float = tail_progress * float(TAIL_COUNT)
	var tail_index: int = mini(int(floor(tail_pos)), TAIL_COUNT - 1)
	var local_t: float = tail_pos - float(tail_index)
	var tail_height: float = HEIGHT * pow(TAIL_DECAY, tail_index + 1)
	return _oscillation(local_t, tail_height)



static func _oscillation(t: float, height: float) -> float:
	t = clampf(t, 0.0, 1.0)
	if t < UPWARD_END:
		var up_wave: float = sin(PI * (t / UPWARD_END))
		return height * up_wave * up_wave
	var progress: float = (t - UPWARD_END) / (1.0 - UPWARD_END)
	var down_wave: float = sin(PI * progress)
	return - height * UNDERSHOOT_RATIO * down_wave * down_wave
