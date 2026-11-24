class_name RankFinishClock
extends Control


const TICK_ROTATE_DEG: float = 90.0
const TICK_ROTATE_SEC: float = 0.1

@onready var _time: Label = $TimeBg / Time
@onready var _point: TextureRect = $ClockBg / Point
@onready var _tick: Timer = $Tick

var _angle_deg: float = 0.0
var _rotate_tween: Tween = null


func _ready() -> void :
	_tick.timeout.connect(_on_tick)


func start() -> void :
	refresh_time()
	if _tick.is_stopped():
		_tick.start()


func stop() -> void :
	_tick.stop()
	_kill_rotate()


func _on_tick() -> void :
	refresh_time()
	_step_pointer()


func refresh_time() -> void :
	_time.text = RankManager.format_remaining(RankManager.get_remain_seconds())


func _step_pointer() -> void :
	_kill_rotate()
	_angle_deg += TICK_ROTATE_DEG
	_rotate_tween = create_tween()
	_rotate_tween.tween_property(_point, "rotation_degrees", _angle_deg, TICK_ROTATE_SEC)\
	.set_trans(Tween.TRANS_LINEAR)


func _kill_rotate() -> void :
	if _rotate_tween != null and _rotate_tween.is_valid():
		_rotate_tween.kill()
	_rotate_tween = null
