extends Node

class FeedbackBoard extends JuiceBoardView:
	func _tracking_move_info(_st: Dictionary, _src: int, _j: int, _dst: int) -> Dictionary:
		return {"before_empty_rope_num": 0, "before_possible_moves": 0}

class CapacityBoard extends JuiceBoardView:
	var hint_count: int = 0
	func show_capacity_error_hint(duration: float) -> void :
		assert (is_equal_approx(duration, 0.9))
		hint_count += 1

class ToastPage extends JuiceGamePage:
	var toast_count: int = 0
	func _show_error_toast(text_key: String, values: Dictionary = {}) -> void :
		assert (text_key == "JUICE_TUTOR_WHY_FULL")
		assert (values.is_empty() or values == {"x": 5})
		toast_count += 1

func _ready() -> void :
	call_deferred("_run")

func _run() -> void :
	var cfg: ErrorAnimationConfig = ABManager.error_animation
	assert (ABManager.find_config("error_animation") == cfg)
	assert (cfg.default_value == 0 and cfg.version == "1.0.7")
	cfg.clear_debug_override()
	ABManager.set("sdk_value", "new")
	ABManager.set("_is_init_done", false)
	assert ( not cfg.is_new_error_animation_enabled())
	ABManager.set("_is_init_done", true)
	var page: = JuiceGamePage.new()
	var board: = JuiceBoardView.new()
	page.set("_board", board)
	var events: Array = ABManager.get("events")
	for raw: String in ["old", "new", "", "unexpected"]:
		ABManager.set("sdk_value", raw)
		for reason: int in [JuiceRules.Reject.COLOR, JuiceRules.Reject.FULL, JuiceRules.Reject.MYSTERY]:
			events.clear()
			page._on_error_feedback_requested(reason)
			assert (events == ["get", "dye"])
			assert (board.get("_new_error_animation_enabled") == (raw == "new"))
	for reason: int in [JuiceRules.Reject.LOCKED, JuiceRules.Reject.INVALID]:
		events.clear()
		page._on_error_feedback_requested(reason)
		assert (events.is_empty())
	board.set("_state", {"caps": [6, 5], "cols": [[1], [2, 2, 2, 2, 2]]})
	board.set("_last_rejected_target", 0)
	assert (board.rejected_target_space() == 5)
	board.set("_last_rejected_target", 1)
	assert (board.rejected_target_space() == 0)
	assert (ABManager.get("int_reads") == 0)
	_test_repeated_capacity_feedback()
	_test_mystery_feedback(page, events)
	page.free()
	board.free()
	print("ERROR_ANIMATION_SELFTEST PASS")
	get_tree().quit()


func _test_mystery_feedback(page: JuiceGamePage, events: Array) -> void :
	var board: = FeedbackBoard.new()
	page.set("_board", board)
	board.error_feedback_requested.connect(page._on_error_feedback_requested)
	var hidden: int = JuiceLevel.hide_type(1)
	var cols: Array = [([hidden] as Array[int]), ([2] as Array[int])]
	var state: Dictionary = {"cols": cols, "caps": ([6, 6] as Array[int])}
	board.set("_state", state)
	assert (JuiceRules.reject_reason(state, 0, 0, 1) == JuiceRules.Reject.MYSTERY)
	var scene: = preload("res://scripts/gameplay/juice_sort/view/juice_fruit.tscn")
	var head: JuiceFruit = scene.instantiate()
	var tail: JuiceFruit = scene.instantiate()
	add_child(head)
	add_child(tail)
	head.setup(head.question_texture, 1, 100.0, Vector2(100.0, 100.0), true)
	tail.setup(head.question_texture, 2, 100.0, Vector2(100.0, 100.0))
	var body: Sprite2D = head.get("_body")
	var question_texture: Texture2D = body.texture
	var original_material: Material = body.material
	board.set("_fruit_nodes", {0: ([head] as Array[JuiceFruit]), 1: ([tail] as Array[JuiceFruit])})
	var before: Dictionary = state.duplicate(true)
	for raw: String in ["old", "new"]:
		ABManager.set("sdk_value", raw)
		events.clear()
		board._handle_rejected_drop(0, 0, 1, JuiceRules.Reject.MYSTERY)
		assert (events == ["get", "dye", "play"])
		assert (state == before)
		var hold: Dictionary = board.get("_color_reject_hold")
		var shake: Dictionary = board.get("_shake")
		if raw == "old":
			assert (hold.is_empty() and shake.has(1))
		else:
			assert ( not hold.is_empty() and not shake.has(1))
			board.set("_t", float(hold["start"]) + 0.11)
			board._advance_color_reject_hold()
			assert (body.material != original_material)
			assert ((tail.get("_body") as Sprite2D).material == tail.get("_color_reject_material"))
			assert (body.texture == question_texture and state == before)
			board._cancel_color_reject_hold()
			assert (body.material == original_material and body.texture == question_texture)
	head.free()
	tail.free()
	board.free()


func _test_repeated_capacity_feedback() -> void :
	var page: = ToastPage.new()
	var board: = CapacityBoard.new()
	page.set("_board", board)
	board.set("_state", {"caps": [6], "cols": [[1]]})
	board.set("_last_rejected_target", 0)
	for raw: String in ["old", "new"]:
		ABManager.set("sdk_value", raw)
		page._on_error_feedback_requested(JuiceRules.Reject.FULL)
		board.hint_count = 0
		page.toast_count = 0
		for hit in 3:
			page._on_move_rejected(JuiceRules.Reject.FULL)
		assert (page.toast_count == 3)
		assert (board.hint_count == (3 if raw == "new" else 0))
	page.free()
	board.free()
