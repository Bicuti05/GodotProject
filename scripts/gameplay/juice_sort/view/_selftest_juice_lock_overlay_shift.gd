extends SceneTree


















const LOCK_SCENE: = "res://scripts/gameplay/juice_sort/view/juice_lock_overlay.gd"

var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :

	var board_scene: PackedScene = load(
		"res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var lock_script: GDScript = load(LOCK_SCENE) as GDScript


	var hitch: Variant = _new_board(board_scene)
	var slot_before: int = int((hitch.get("_slot_of") as Dictionary)[2])
	_check(hitch.try_move(1, 0, 0), "卡顿组:c1 的红能接到 c0")
	_check(int((hitch.get("_state") as Dictionary)["done"]) == 1, "卡顿组:恰好收了 1 盆")
	_check(int((hitch.get("_slot_of") as Dictionary)[2]) == slot_before - 1, "卡顿组:锁列左移了一格")
	hitch._process(10.0)
	for _i in 5:
		hitch._process(1.0 / 60.0)
	_check_overlay(hitch, lock_script, "卡顿组(一帧 10s)")
	_free_board(hitch)


	var smooth: Variant = _new_board(board_scene)
	_check(smooth.try_move(1, 0, 0), "逐帧组:c1 的红能接到 c0")
	var guard: int = 0
	while (smooth.is_busy() or not (smooth.get("_shift_queue") as Array).is_empty())\
	and guard < 60 * 20:
		smooth._process(1.0 / 60.0)
		guard += 1
	_check(guard < 60 * 20, "逐帧组:动画 20s 内播完")
	for _i in 5:
		smooth._process(1.0 / 60.0)
	_check_overlay(smooth, lock_script, "逐帧组(60fps)")
	_free_board(smooth)



	var dead_board: Variant = _new_board(board_scene)
	var o: Control = (dead_board.get("_lock_overlay_live") as Array)[0] as Control
	o.position.x += float(dead_board.get("_lay").col_w)
	_check( not (dead_board.render_mismatches() as Array).is_empty(), "兜底组:错位能被核对出来")
	var fixed: Array = dead_board._reconcile_render_before_dead("stuck")
	_check( not fixed.is_empty(), "兜底组:判死时报告了错位")
	_check((dead_board.render_mismatches() as Array).is_empty(), "兜底组:判死后渲染已与状态一致")
	_check_overlay(dead_board, lock_script, "兜底组")

	_free_board(dead_board)
	var clean: Variant = _new_board(board_scene)
	_check((clean.render_mismatches() as Array).is_empty(), 
		"静止盘面核对无误报: %s" % str(clean.render_mismatches()))
	_free_board(clean)

	if _failures.is_empty():
		print("PASS")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: ", f)
		quit(1)


func _new_board(board_scene: PackedScene) -> Variant:
	var level: JuiceLevel = JuiceLevel.from_dict({
		"id": 98101, "capacity": 2, "targetCups": 3, 
		"initial": [
			"0|0", 
			"-|0", 
			{"column": "1|1,1", "columnType": "unlock", 
				"columnInfo": {"condition": "collect_count", "count": 3}}, 
		], 
		"incoming": ["2|2", "x", "x"], 
	})
	var board: Variant = board_scene.instantiate()
	board.size = Vector2(1080, 2340)
	root.add_child(board)
	board.setup(level)
	return board


func _free_board(board: Variant) -> void :
	board._cancel_closed_check()
	board.queue_free()


func _check_overlay(board: Variant, lock_script: GDScript, tag: String) -> void :
	var live: Array = board.get("_lock_overlay_live") as Array
	_check(live.size() == 1, "%s:应恰有 1 条锁遮罩,实际 %d" % [tag, live.size()])
	if live.size() != 1:
		return
	var o: Control = live[0] as Control
	var ci: int = int(o.get("col"))
	_check(ci == 2, "%s:遮罩应盖 c2,实际 c%d" % [tag, ci])
	var consts: Dictionary = lock_script.get_script_constant_map()
	var lay: Variant = board.get("_lay")
	var s: float = float(lay.fruit_d) / float(consts["DESIGN_FRUIT_D"])
	var want_x: float = float(board._base_x(2)) - float(consts["FRAME_W"]) * 0.5 * s
	_check(absf(o.position.x - want_x) < 0.5, 
		"%s:遮罩 x=%.1f,锁列 c2 当前格位应为 %.1f(差 %.1f,列步长 %.1f)"
		%[tag, o.position.x, want_x, o.position.x - want_x, float(lay.col_w)])


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)
