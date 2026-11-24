extends CanvasLayer


@onready var _view: StreakCelebration = $Celebration
var _loop: bool = false
var _generation: int = 0
var _opened: bool = false
var _paused_before: bool = false
var _count: int = 10

func open(count: int = 10, loop: bool = false, slow: bool = false) -> void :
	if not _opened:
		_paused_before = get_tree().paused
	_opened = true
	get_tree().paused = true
	_count = maxi(2, count)
	_loop = loop
	$Toolbar / Loop.text = "循环：开" if loop else "循环：关"
	$Toolbar / Slow.text = "速度：0.35×" if slow else "速度：1×"
	_view.playback_speed = 0.35 if slow else 1.0
	_generation += 1
	_run(_generation)

func _ready() -> void :
	layer = 211
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Toolbar.position.y = UiMetrics.safe_insets().x + 24.0

func _run(generation: int) -> void :
	while _opened and generation == _generation:
		await _view.play(_count)
		if not _loop or generation != _generation:
			break
		await get_tree().create_timer(0.5, true).timeout

func close() -> void :
	_generation += 1
	_view.hide_now()
	if _opened:
		get_tree().paused = _paused_before
	_opened = false
	queue_free()


func _on_replay_pressed() -> void :
	open(_count, _loop, _view.playback_speed < 1.0)

func _on_loop_pressed() -> void :
	open(_count, not _loop, _view.playback_speed < 1.0)

func _on_slow_pressed() -> void :
	open(_count, _loop, _view.playback_speed >= 1.0)

func _on_close_pressed() -> void :
	close()
